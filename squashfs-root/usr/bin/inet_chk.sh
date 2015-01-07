#!/bin/sh

. /lib/functions/network.sh
. /lib/functions/net_update_actions.sh

static_domains="www.qq.com t.cn"
needup=""
log_cnt=""
PPPOE_STATE_FILE="/var/state/pppoe_state"
INETCHK_LOG_TAG="inetchk"
INETCHK_RUN_STAMP="/var/run/inetchk.stamp"
INETCHK_UPLOAD_STAMP="$(awk -F '.' '{print $1}' /proc/uptime)"

valid_gateway()
{
	local arp_entry
	local wan_type
	wan_type="$(uci get network.wan.proto)"
	if [[ "$wan_type" = "pppoe" ]];then
		return 0
	fi

	###:TODO
	network_get_gateway wan_gw wan
	if [[ "$?" -eq 0 ]];then
		arp_entry=$(cat /proc/net/arp | grep "^$wan_gw " 2> /dev/null)
		if [[ "$?" -eq "0" ]]; then
			echo $arp_entry | grep "00:00:00:00:00:00" &> /dev/null
			if [[ "$?" -ne "0" ]];then
				return 0
			fi
		fi
	fi

	return 1
}

get_wlan_relay_status()
{
	###FIXME:
	### 1, These codes what test wlan status should be move to /etc/hotplug.d.
	### Unfortunately, our system does't support reply wlan-relay-mode status in hotplug!
	### 2, In case of the unstable of wireless-rely mode, we do not use ping to test the network,
	### just let it go.

	wlan_st=$(uci get wireless.@wifi-iface[1].network 2>/dev/null)
	if [[ "${wlan_st:-?}" = "wan" ]]; then
		local wlan_iface=$(uci get network.wan.ifname)
		wan_link=$(lua -e "require 'hcwifi';print(hcwifi.get(\"$wlan_iface\",'status'))")
		return $wan_link
	fi

	return 0
}

chk_inet_state_by_curl()
{
	local rv=""

	curl -L -o /dev/null http://www.baidu.com/ &> /dev/null
	rv=$?

	if [ "$rv" -ne 0 ]; then
		curl -L -o /dev/null http://www.so.com/ &> /dev/null
		rv=$?
	fi

	return $rv
}

chk_inet_state_by_nslookup()
{
	local rv=0
	local results=""
	local dnsserver=""
	local server=""

	dnsserver=$(awk  '{if ($1== "nameserver") print $2}' /tmp/resolv.conf.auto)
	if [ -z "$dnsserver" ]; then
		#FIXME: if /tmp/resolv.conf.auto not exist
		rv=1
	else
		for  server in $dnsserver; do
			results=$(nslookup www.baidu.com $server 2>/dev/null)
			rv=$?
			if [ $rv -eq 0 ];then
				echo $results | grep "172.31.255.254" &>/dev/null
				if [ $? -eq 0 ];then
					rv=1
				else
					rv=0
					break
				fi
			fi
		done
	fi
	
	return $rv
}

collect_inetchk_state_log()
{
	[[ "$1" != "$2"	]] && {
		logger -t $INETCHK_LOG_TAG "$2:$3"
	}
}

chk_inet_state_by_sqos()
{
	local speed=0

	speed=$(awk '{if(match($0,/^=*$/)){target= NR +1} if(NR == target) print $5}' /proc/net/smartqos/stat 2>&-)
	[[ $? -eq 0 ]] && {
		if [[ "$speed" -gt 50 ]]; then
			return 0
		fi
	}

	return 1
}

inet_chk_upload_syslog()
{
	local curr
	local tarname

	curr="$(awk -F '.' '{print $1}' /proc/uptime)"
	if [ $((INETCHK_UPLOAD_STAMP + 1800)) -lt $curr ]; then
		if [ -d "/tmp/data/log" ]; then
			. /lib/platform.sh
			tarname=inetchk-$(date +%Y%m%d%H%M%S)-$(tw_get_mac).tgz
			tar -czf /tmp/data/$tarname -C /tmp/data log
			. /lib/functions/upload.sh
			upload_data /tmp/data/$tarname "delay-syslog"
			rm -f /tmp/data/$tarname
			INETCHK_UPLOAD_STAMP=$curr
		fi
	fi

	return 0
}

inet_chk_update_action()
{
	local net_state=$1
	local pppoe_mode=$2

	get_inet_chk_switch &> /dev/null
	if [ $? -ne 0 ];then
		if [[ "$net_state" = "inet_up" ]]; then
			netup_action
			needup="needup"
		else
			if [ "$pppoe_mode" = "pppoe_dialing" ];then
				needup=""
			fi

			netdown_action	"$needup"
			needup=""
		fi
	else
		netup_action
		if [[ "$net_state" = "inet_up" ]]; then
			needup_tmp="needup"
			net_internet_led_update "inet_up"
		else
			net_internet_led_update "inet_down"

			if [[ "$needup_tmp" = "needup" ]];then
				net_autostart_wan
			fi
			needup_tmp=""
		fi
	fi
}

#Init inet state
netdown_action
netup_action

net_get_agreement
if [[ $? -eq 0 ]];then
	while [[ true ]];
	do
		netdown_action
		sleep 1
		net_get_agreement
		if [[ "$?" -ne 0 ]];then
			break
		fi
	done
	netup_action
fi

do_while_func()
{
	local net_state="inet_down"
	local old_state=""
	local is_relay=""
	local is_up="inet_down"

	is_relay="$(lua -e 'local net=require "luci.controller.api.network"; print(net.is_bridge())')"

	old_state=$1

	chk_inet_state_by_sqos
	if [[ $? -eq 0 ]];then
		net_state="inet_up"
		is_up="$net_state"
		collect_inetchk_state_log "$old_state" "$net_state" "sqos"
	elif [[ "$is_relay" = "true" ]]; then
		get_wlan_relay_status
		if [[ $? -eq 1 ]]; then
			net_state="inet_up"
			is_up="$net_state"
		fi
		collect_inetchk_state_log "$old_state" "$net_state" "relay link"
	else
		valid_gateway
		if [[ "$?" -ne 0 ]]; then
			collect_inetchk_state_log "$old_state" "$net_state" "gateway"
		fi

		net_state="inet_down"
		chk_inet_state_by_nslookup
		if [[ "$?" -eq 0 ]]; then
			net_state="inet_up"
			is_up=$net_state
		fi
		collect_inetchk_state_log "$old_state" "$net_state" "nslookup"

		net_state="inet_down"
		for cur in $static_domains
		do
			ping $cur -c 1 -W 2 &>/dev/null
			if [[ $? -eq 0 ]]; then
				net_state="inet_up"
				is_up=$net_state
				break
			fi
		done
		collect_inetchk_state_log "$old_state" "$net_state" "ping"

		if [ $is_up != "inet_up" ]; then
			net_state="inet_down"
			chk_inet_state_by_curl
			if [[ "$?" -eq 0 ]]; then
				net_state="inet_up"
				is_up=$net_state
			fi
			collect_inetchk_state_log "$old_state" "$net_state" "curl"
		fi
	fi

	collect_inetchk_state_log "$old_state" "$is_up" "final"

	if [ "$old_state" != "inet_up" ]; then
		if [ "$is_up" = "inet_up" ]; then
			inet_chk_upload_syslog
		fi
	fi

	old_state="$is_up"

	if [ "$old_state" = "inet_up" ];then
		return 0
	else
		return 1
	fi
}

old_state="$(cat /tmp/state/inet_stat 2> /dev/null)"
needup_tmp="needup"
state=$old_state

while [[ true ]];
do
	local pppoe_mode=""

	awk -F '.' '{print $1}' /proc/uptime 2> /dev/null > $INETCHK_RUN_STAMP

	( do_while_func $state )

	if [ $? -eq 0 ]; then
		state="inet_up"
	else
		state="inet_down"
	fi

	[ -e  $PPPOE_STATE_FILE ] && {
		rm -f $PPPOE_STATE_FILE	
		logger -t $INETCHK_LOG_TAG "Found pppoe dialing file ignore this action."
		pppoe_mode="pppoe_dialing"
	}

	inet_chk_update_action $state  $pppoe_mode

	sleep 5
done
