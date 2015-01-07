#!/bin/sh
#healthchk is derived form proteus.
#The principle of proteus is to make it as it.
#Hardware resource info
#	CPU	Mem	Net	Disk	Board
#System info
#

INFOGATHER_VERSION="a2"
source /lib/functions/healib.sh

########################################
#Infogather all infos
#
#
#######################################
infogather_net_info()
{
	#Net
	#Listening sockets
	netstat -lnatup
	#Established connections
	netstat -natup
	#statistics
	#netstat -s

	route -n

	ip neigh

	iptables-save

	ifconfig
}

infogather_processes_info()
{
	top -n 1
}

hi_diagnose()
{
	echo "Current time:`date`"

	echo "Checking for processes:"
	ps
	echo ""

	echo "Checking for CMA's context:"
	cat /tmp/cmagent.state
	echo ""

	echo "Checking for CMAs' connections:"
	netstat -apnt | grep cmagent
	echo ""

	echo "Checking for CMA's logs:"
	grep cmagent /var/log/syslog
	echo ""

	echo "Checking for DNS:"
	nslookup carrier.hiwifi.com
	echo ""

	echo "Checking if network is reachable:"
	ping -w 10 carrier.hiwifi.com
	ping -w 10 www.baidu.com
	echo ""

	echo "Checking if port is reachable:"
	curl -k --connect-timeout 10 https://carrier.hiwifi.com
	echo ""

	echo "Checking for NICs' configures:"
	ifconfig
	echo ""

	echo "Checking for route table:"
	route -n
	echo ""

	echo "Checking for iptables:"
	iptables -L
	echo ""

	echo "Checking for dmesg:"
	dmesg
	echo ""
}

infogather_cpu_info()
{
	#CPU
	cat /proc/cpuinfo
}

infogather_mem_info()
{
	#Mem info
	cat /proc/meminfo

	free

	cat /proc/ioports

	cat /proc/iomem
}

infogather_disk_info()
{
	#disk
	fdisk -l
	cat /proc/partitions
	cat /proc/mtd
	df -h
	mount
	du -d 1 / 2> /dev/null
	cat /proc/swaps
}

infogather_board_info()
{
	cat /proc/cmdline

	cat /etc/.build
}

infogather_host_info()
{
	id
	cat /proc/version
	uptime
	cat /proc/loadavg
	env
	#crontab -l
	lsmod
}

#user info
infogather_user_info()
{
	cat /etc/passwd
	cat /etc/group
}

#Collect hardware-independent system info
infogather_sys_info()
{
	local trigger_type="$1"	
	local stamp_dir="$2"
	local trigger_path=$INFOGATHER_BASE_PATH/$trigger_type
	local stamp_path=$trigger_path/db/$stamp_dir

	local sysinfo_path="$stamp_path/sysinfo"

	mkdir -p $stamp_path/sysinfo

	ps www | sed 's/[[:blank:]]\+user[[:blank:]]\+[^\ ]\+[[:blank:]]\+password[[:blank:]]\+[^\ ]\+/ user *** passwd *** /g' &> $sysinfo_path/ps.log

	dmesg &> $sysinfo_path/dmesg.log

	hi_host_info &> $sysinfo_path/host.info

	hi_user_info &> $sysinfo_path/user.info

	hi_net_info &> $sysinfo_path/net.info

	hi_disk_info &> $sysinfo_path/disk.info

	hi_board_info &> $sysinfo_path/board.info

	hi_cpu_info &> $sysinfo_path/cpu.info

	hi_mem_info &> $sysinfo_path/mem.info

	hi_processes_info &> $sysinfo_path/processes.info

	hi_diagnose &> $sysinfo_path/diagnose.info

	return 0
}

#snapshot /proc
infogather_proc()
{
	local trigger_type="$1"	
	local stamp_dir="$2"
	local trigger_path=$INFOGATHER_BASE_PATH/$trigger_type
	local stamp_path=$trigger_path/db/$stamp_dir


	local entry=""

	[[ -d "$stamp_path/proc" ]] || (mkdir -p "$stamp_path/proc" )

	e=$(ls /proc)
	for entry in $e
	do

		if [[ -d "/proc/$entry" ]];then

			if [[ "$entry" = "slef" ]];then
				continue
			fi

			echo $entry | grep   "^[0-9][0-9]*$" &> /dev/null

			if [[ $? -eq "0" ]]; then
				continue
			fi
				#cp -Lr "/proc/$entry"  $stamp_path/proc &> /dev/null
		else
			if [[ "$entry" = "kmsg" ]];then
				continue
			fi

			cp -Lr "/proc/$entry" $stamp_path/proc &> /dev/null
		fi
	done

	return 0
}

#date +%Y%m%d%H%M%S -d "@$unixdate"
infogather_coredump()
{	
	local trigger_type="$1"	
	local stamp_dir="$2"
	local trigger_path=$INFOGATHER_BASE_PATH/$trigger_type
	local stamp_path=$trigger_path/db/$stamp_dir

	local unixtime=""
	local timeofday=""
	local new_core_name=""
	#date -D '2010-01-01' '+%s'
	local base_unixtime="1405337253"
	local i="4"
	local max_field="7"
	local found="1"

	ls $HI_COREDUMP_PATH | grep '.*\.core\b' &> /dev/null
	if [[ $? -eq 0 ]]; then
		mkdir -p $stamp_path/cores
		[[ $? -ne 0 ]] && return 1
		
		for core in $(ls $HI_COREDUMP_PATH | grep '.*\.core\b')	
		do	
			found="1"
			max_filed="echo $core | awk -F '.' '{print NF}'"
			for i in $(seq 4 $max_field) 
			do
				unixtime=$(echo $core | awk -F '.' '{print $4}')
				if [ $unixtime -gt $base_unixtime ];then
					found="0"
					break
				fi
			done
		
			if [ $found -ne 0 ];then
				continue
			fi

			timeofday=$(date +%Y%m%d%H%M%S -d "@$unixtime")
			new_core_name=$(echo $core | sed "s/$unixtime/$timeofday/")
			mv $HI_COREDUMP_PATH/$core $HI_COREDUMP_PATH/$new_core_name
		done

		mv $HI_COREDUMP_PATH/*.core $stamp_path/cores
		[[ $? -ne 0 ]] && return 1
	fi

	return 0
}

infogather_syslog()
{
	local trigger_type="$1"	
	local stamp_dir="$2"
	local trigger_path=$INFOGATHER_BASE_PATH/$trigger_type
	local stamp_path=$trigger_path/db/$stamp_dir

	mkdir -p $stamp_path/syslog
	[[ $? -ne 0 ]] && return 1

	cp  /tmp/data/log/syslog* $stamp_path/syslog

	cp /var/log/syslog* $stamp_path/syslog

	return 0
} 

infogather_etc()
{
	local trigger_type="$1"	
	local stamp_dir="$2"
	local trigger_path=$INFOGATHER_BASE_PATH/$trigger_type
	local stamp_path=$trigger_path/db/$stamp_dir



	mkdir -p $stamp_path	
	[[ $? -ne 0 ]] && return 1

	tar -czf $stamp_path/etc.tgz -C / etc 2> /dev/null
	[[ $? -ne 0 ]] && return 2

	return 0
}

infogather_log()
{
	local trigger_type="$1"	
	local stamp_dir="$2"
	local trigger_path=$INFOGATHER_BASE_PATH/$trigger_type
	local stamp_path=$trigger_path/db/$stamp_dir


	mkdir -p $stamp_path/log

	cp -r /var/log $stamp_path/log/varlog

	cp -r /tmp/log $stamp_path/log/tmplog

	return 0
}

#Collect the log of restart some  processes
infogather_hidaemon_log()
{
        local trigger_type=$1
        local stamp_dir=$INFOGATHER_VERSION-$2
        local stamp_path=$INFOGATHER_BASE_PATH/$trigger_type/db/$stamp_dir

        mkdir -p $stamp_path/log

	[ -e $HI_HEALTH_LOG_FILE ] && {
		cp  $HI_HEALTH_LOG_FILE $stamp_path/log/
	}
}

infogather_setup_env()
{
	local trigger_type="$1"	
	local stamp_dir="$2"
	local trigger_path=$INFOGATHER_BASE_PATH/$trigger_type
	local stamp_path=$trigger_path/db/$stamp_dir

	[[ -d $trigger_path ]] || {
		[ -e $trigger_path ] && {
			rm -f $trigger_path
		}
		mkdir -p $trigger_path
		[[ $? -ne 0 ]] && return 1
	}

	mkdir -p $trigger_path/db
	
	rm -rf $trigger_path/db/*
	[[ $? -ne 0 ]] && return 1
	
	mkdir -p $stamp_path
	[[ $? -ne 0 ]] && return 1

	return 0
}

infogather_main()
{	
	local trigger_type="$1"	
	local stamp_dir="$INFOGATHER_VERSION-""$2"

	infogather_setup_env $trigger_type $stamp_dir
	[[ $? -ne 0 ]] && return 1

	infogather_syslog $trigger_type $stamp_dir	
	[[ $? -ne 0 ]] && return 1

	#infogather_etc	$trigger_type $stamp_dir
	#[[ $? -ne 0 ]] && return 1

	infogather_coredump $trigger_type $stamp_dir
	[[ $? -ne 0 ]] && return 1

	infogather_proc $trigger_type $stamp_dir

	infogather_sys_info $trigger_type $stamp_dir

	infogather_log $trigger_type $stamp_dir

	return 0
}
