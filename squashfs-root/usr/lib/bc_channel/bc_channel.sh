#!/bin/sh

INTERVAL=60    #minute
#TOTAL_TIMEOUT=200 #second

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

#set_timeout $TOTAL_TIMEOUT $$ &
SUBPROCESS=$!

CURRENT_PATH=`dirname $0`
MAC=`get_mac`
TIME=`date '+%s'`

RANDSTR=`head -20 /dev/urandom | md5sum`
SHORTRAND=`expr substr "${RANDSTR}" 1 12`

if [ ! $MAC ]; then
	MAC="000000$SHORTRAND"
fi

if [ ! $TIME ]; then
	TIME="0000000000"
fi

MAC_NUM=$(( `hex_to_num ${MAC}` % $INTERVAL ))
TIME_NUM=$(( $TIME / 60 % $INTERVAL))
SLEEP_RAND=`hex_to_num $SHORTRAND`

if [ $MAC_NUM = $TIME_NUM ]; then
	sleep $(( (`hex_to_num ${MAC}` / $INTERVAL + $SLEEP_RAND) % 60 ))
	/usr/lib/bc_channel/bc_channel
fi
