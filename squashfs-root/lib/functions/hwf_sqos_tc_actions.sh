#!/bin/sh

. /usr/share/libubox/jshn.sh

tc_dev_add_hwf_qdisc()
{
	local dev=$1

	tc qdisc add dev $dev root hwf
}

tc_dev_del_hwf_qdisc()
{
	local dev=$1
	
	tc qdisc del dev $dev root hwf
}

hwf_get_interface_name()
{
	local if_status
	local type=$1

	if_status=$(ubus call network.interface.$type status 2>/dev/null)	
	json_load "$if_status" &> /dev/null

	json_get_var device device &> /dev/null
		
	echo $device
}

tc_setup_dev_hwf_qdisc()
{

	local lan_dev
	local wan_dev

	wan_dev=$(hwf_get_interface_name "wan")
	lan_dev=$(hwf_get_interface_name "lan")

	tc_dev_add_hwf_qdisc $wan_dev
	tc_dev_add_hwf_qdisc $lan_dev
}

tc_clean_dev_hwf_qdisc()
{
	dev_list=$( tc qdisc | grep hwf | awk -F ':' '{print $2}' | awk '{print $2}')
	
	for dev in $dev_list
	do
		tc_dev_del_hwf_qdisc $dev
	done
}

hwf_sqos_setup_tc_qdisc()
{
	tc_clean_dev_hwf_qdisc

	tc_setup_dev_hwf_qdisc	
}

hwf_sqos_clean_tc_qdisc()
{
	tc_clean_dev_hwf_qdisc
}
