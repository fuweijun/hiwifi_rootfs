#!/bin/sh
# script called by udhcpc's default.script
# detect wan/lan ip conflict and resolve the problem
# Turbo Wireless
# LIKAI <9@kai.li>, 2012-02-16

if [ "$1" = "bound" ]; then
	lan_ip=$(uci get network.lan.ipaddr)
	lan_netmask=$(uci get network.lan.netmask)
	wan_netmask=${subnet:-255.255.255.0}

	lan_ip_new=$(/bin/network-conflict-calc.sh "$lan_ip" "$lan_netmask" "$ip" "$wan_netmask")
	if [ "$lan_ip" != "$lan_ip_new" ]; then
		while [ ! -f '/overlay/etc/config/network' ]
		do
			sleep 5
		done
		uci set network.lan.ipaddr="$lan_ip_new"
		uci set network.lan.netmask="255.255.255.0"
		uci commit
		logger -t system "00-ip-chk.sh: wan:$ip,$wan_netmask;lan:$lan_ip,$lan_netmask is conflicting, will be set lan:$lan_ip_new,255.255.255.0"
		reboot
	fi
fi
