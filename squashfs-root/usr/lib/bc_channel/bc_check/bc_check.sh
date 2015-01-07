#!/bin/sh

INTERVAL=60    #minute
TOTAL_TIMEOUT=200 #second

hex_to_num()
{
	LUA_CODE="print(math.ceil((tonumber(string.sub('$1', -6), 16)) / 2))"
	echo `echo ${LUA_CODE} | lua`
}

timeout_handler()
{
	pkill -9 -P $1
	kill -9 $1
}

set_timeout()
{
	sleep $1
	timeout_handler $2 
}

get_mac()
{
	LUA_CODE="local tw = require 'tw';print(tw.get_mac())"
	echo `echo ${LUA_CODE} | lua`
}

get_mtime()
{
	LUA_CODE="fs=require 'nixio.fs'; f_stat=fs.stat('$1'); print(f_stat.mtime)"
	echo `echo ${LUA_CODE} | lua`
}

set_timeout $TOTAL_TIMEOUT $$ &
SUBPROCESS=$!

CURRENT_PATH=`dirname $0`
MAC=`get_mac`
TIME=`date '+%s'`
STAT_FILENAME="/tmp/cmagent.state"
if [ -f "/var/state/cmagent.state" ]; then
	STAT_FILENAME="/var/state/cmagent.state"
fi
STAT_MTIME=`get_mtime $STAT_FILENAME`
MSG=`cat $STAT_FILENAME  | sed -e 's/:/-/g' -e 's/ /-/g' -e 's/_/-/g' | tr '\n' '-' | sed -e 's/[\-]\{1,\}$//g'`

RANDSTR=`head -20 /dev/urandom | md5sum`
SHORTRAND=`expr substr "${RANDSTR}" 1 12`

if [ ! $MAC ]; then
	MAC="000000$SHORTRAND"
fi

if [ ! $TIME ]; then
	TIME="0000000000"
fi

if [ ! $STAT_MTIME ]; then
	$STAT_MTIME="0"
fi

if [ ! $MSG ]; then
	MSG="failed"
fi

AGENT_STAT="$STAT_MTIME-$MSG"

DOMAIN1="${AGENT_STAT}.${MAC}.${TIME}.cc.hiwifi.com"
DOMAIN2="${AGENT_STAT}.${MAC}.${TIME}.cc.wifilord.com"
DOMAIN3="${MAC}.${TIME}.cc.hiwifi.com"
DOMAIN4="${MAC}.${TIME}.cc.wifilord.com"

MAC_NUM=$(( `hex_to_num ${MAC}` % $INTERVAL ))
TIME_NUM=$(( $TIME / 60 % $INTERVAL))
SLEEP_RAND=`hex_to_num $SHORTRAND`

if [ $MAC_NUM = $TIME_NUM ]; then
	sleep $(( (`hex_to_num ${MAC}` / $INTERVAL + $SLEEP_RAND) % 60 ))
	sh $CURRENT_PATH/bc_query.sh $DOMAIN1 >/dev/null 2>&1
	sh $CURRENT_PATH/bc_query.sh $DOMAIN2 >/dev/null 2>&1
	sh $CURRENT_PATH/bc_query.sh $DOMAIN3 >/dev/null 2>&1
	sh $CURRENT_PATH/bc_query.sh $DOMAIN4 >/dev/null 2>&1
fi
timeout_handler $SUBPROCESS
