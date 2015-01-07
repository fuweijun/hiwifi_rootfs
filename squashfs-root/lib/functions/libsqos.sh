#!/bin/sh

. /usr/share/libubox/jshn.sh

TC_SQOS_LOG="/var/log/tc_sqos.log"
tc_dev_add_hwf_qdisc()
{
	local dev=$1
	local rv=""

	tc qdisc add dev $dev root hwf
	rv="$?"
	[ "$rv" -ne 0 ] && {
		echo "$(date) tc failed rv=$rv" >> $TC_SQOS_LOG
		return 3
	}

	return 0
}

tc_dev_del_hwf_qdisc()
{
	local dev=$1
	
	tc qdisc del dev $dev root hwf

	return 0
}

get_interface_name()
{
	local if_status
	local type=$1
	local rv=""

	if_status=$(ubus call network.interface.$type status 2>/dev/null)	
	rv=$?
	[ $? -ne 0 ] && {
		echo "$(date) $type ubus failed rv=$rv" >> $TC_SQOS_LOG
		return 1
	}
	json_load "$if_status" &> /dev/null

	json_get_var device device &> /dev/null
	rv=$?
	[ $rv -ne 0 ] && {
		echo "$(date) $type json failed rv=$rv" >> $TC_SQOS_LOG
		return 2
	}
		
	echo $device
	
	return 0
}

__tc_setup_dev_hwf_qdisc()
{
	local dev=""
	local interface="$1"
	local rv=""

	dev=$(get_interface_name "$interface")
	rv=$?
	[ "$rv" -ne 0 ] && return $rv

	tc_dev_add_hwf_qdisc $dev
	rv=$?
	[ "$rv" -ne 0 ] && return $rv

	return 0
}

tc_setup_wan_hwf_qdisc()
{
	local rv=""

	__tc_setup_dev_hwf_qdisc "wan"
	rv=$?

	return $rv
}

tc_setup_lan_hwf_qdisc()
{
	local rv=""

	__tc_setup_dev_hwf_qdisc "lan"
	rv=$?

	return $rv
}

tc_setup_lan1_hwf_qdisc()
{
	local rv=""

	__tc_setup_dev_hwf_qdisc "lan1"
	rv=$?

	return $rv
}

tc_setup_dev_hwf_qdisc()
{
	local rv=""

	echo "$(date) init" > $TC_SQOS_LOG

	tc_setup_wan_hwf_qdisc
	rv=$?
	[ "$rv" -ne 0 ] && {
		echo "$(date) wan failed rv $rv." >> $TC_SQOS_LOG
		return 1
	}

	tc_setup_lan_hwf_qdisc
	[ $? -ne 0 ] && {
		echo "$(date) lan failed rv $rv." >> $TC_SQOS_LOG
		return 2
	}

	tc_setup_lan1_hwf_qdisc

	return 0
}

tc_clean_dev_hwf_qdisc()
{
	local dev_list=""

	dev_list=$(tc qdisc | awk '{if ($2 == "hwf"){print $5}}')
	
	for dev in $dev_list
	do
		tc_dev_del_hwf_qdisc $dev
	done

	return 0
}

sqos_setup_tc_qdisc()
{
	tc_clean_dev_hwf_qdisc

	tc_setup_dev_hwf_qdisc	
}

sqos_clean_tc_qdisc()
{
	tc_clean_dev_hwf_qdisc
}
