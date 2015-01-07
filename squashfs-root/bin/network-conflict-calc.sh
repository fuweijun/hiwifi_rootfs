#!/bin/sh
# check conflict of wan/lan ip and emit out proper ip
# Usage: $0 lan_ip lan_netmask wan_ip wan_netmask
# Turbo Wireless
# LIKAI <9@kai.li>, 2012-02-16

awk -f - $* <<EOF
function ip2int(ip) {
	for (ret=0,n=split(ip,a,"\."),x=1;x<=n;x++) ret=or(lshift(ret,8),a[x]) 
	return ret
}

BEGIN {
	lan_ipaddr=ip2int(ARGV[1])
	lan_netmask=ip2int(ARGV[2])
	wan_ipaddr=ip2int(ARGV[3])
	wan_netmask=ip2int(ARGV[4])
	
	if (and(lan_ipaddr,lan_netmask) == and(wan_ipaddr,lan_netmask)) {
		conflict = 1
	} else if(and(lan_ipaddr,wan_netmask) == and(wan_ipaddr,wan_netmask)) {
		conflict = 1
	}
	
	if (conflict == 1) {
		if ( and(lan_ipaddr, 0xffff0000) == ip2int("192.168.0.0") ) {
			print "10.1.1.1"
		} else {
			print "192.168.1.1"
		}
	} else {
		print ARGV[1]
	}
}
EOF
