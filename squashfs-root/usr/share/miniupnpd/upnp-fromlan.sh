#!/bin/sh

# Copyright (c) 2013 Beijing HiWiFi Co., Ltd.
# Author: Jianying Liu <jianying.liu@hiwifi.tw>
# Description: This script is to fix UPNP port mapping from
#  WAN to LAN but accessed from LAN.
#

add()
{
	local proto="$1"
	local ext_port="$2"
	local int_addr="$3"
	local int_port="$4"

	. /lib/functions/network.sh
	network_get_subnet lan_subnet lan
	network_get_ipaddr wan_ipaddr wan

	# Use dedicated chains for each port number
	local chain_pre=upnplanfw_${proto}_${ext_port}_pre
	local chain_post=upnplanfw_${proto}_${ext_port}_post
	local chain_fwd=upnplanfw_${proto}_${ext_port}_fwd

	# Create dedicated chains for this port, and link from main chains
	iptables -t nat -N $chain_pre && iptables -t nat -A miniupnpd_fromlan -p $proto -j $chain_pre || iptables -t nat -F $chain_pre
	iptables -t nat -N $chain_post && iptables -t nat -A miniupnpd_tolan -p $proto -j $chain_post || iptables -t nat -F $chain_post
	iptables -N $chain_fwd && iptables -A miniupnpd_fwd -p $proto -j $chain_fwd || iptables -F $chain_fwd

	# Set rules in chains
	iptables -t nat -A $chain_pre -s $lan_subnet -d $wan_ipaddr -p $proto --dport $ext_port -j DNAT --to-destination $int_addr:$int_port
	iptables -t nat -A $chain_post -s $lan_subnet -d $int_addr -p $proto --dport $int_port -j MASQUERADE
	iptables -A $chain_fwd -d $int_addr -p $proto --dport $int_port -j ACCEPT
}

remove()
{
	local proto="$1"
	local ext_port="$2"

	local chain_pre=upnplanfw_${proto}_${ext_port}_pre
	local chain_post=upnplanfw_${proto}_${ext_port}_post
	local chain_fwd=upnplanfw_${proto}_${ext_port}_fwd

	while iptables -t nat -D miniupnpd_fromlan -p $proto -j $chain_pre 2>/dev/null; do :; done
	while iptables -t nat -D miniupnpd_tolan -p $proto -j $chain_post 2>/dev/null; do :; done
	while iptables -D miniupnpd_fwd -p $proto -j $chain_fwd 2>/dev/null; do :; done

	iptables -t nat -F $chain_pre; iptables -t nat -X $chain_pre
	iptables -t nat -F $chain_post; iptables -t nat -X $chain_post
	iptables -F $chain_fwd; iptables -X $chain_fwd
}

case "$1" in
	add) shift 1; add "$@";;
	remove) shift 1; remove "$@";;
	*) echo "Usage: $1 add|remove <proto> <ext_port> <int_addr> <int_port>";;
esac

