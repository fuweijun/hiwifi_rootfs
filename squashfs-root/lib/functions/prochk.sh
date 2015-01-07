#!/bin/sh

################################
#Healthchk 
#memory, cordump, process
#
###############################
. /lib/functions/healib.sh
. /lib/functions/packtgz.sh

HI_PROCHK_DISK_PATH="/tmp/data/prochk"

prochk_clean_old_coredumps()
{
        local curr_version=$(awk '{print $1}' /etc/.build)

        ls $HI_COREDUMP_PATH | grep '.*\.core\b' &> /dev/null
        [[ $? -eq 0 ]] && {
                for core in $(ls $HI_COREDUMP_PATH |  grep '.*\.core\b'); do
                        version=$(echo $core | grep '.*\.core\b' | awk -F '.'  '{print $(NF-3)"."$(NF-2)"."$(NF-1)}')
                        if [ "$version" != "$curr_version" ]
                        then
                                rm -f $HI_COREDUMP_PATH/$core
                        fi
                done
        }
}

prochk_coredump()
{
	local prochk_cause=""
        prochk_clean_old_coredumps

        ls $HI_COREDUMP_PATH | grep '.*\.core\b' &> /dev/null
        [[ $? -eq 0 ]] && { 

		prochk_cause=$(ls -t $HI_COREDUMP_PATH | grep '.*\.core\b' | awk  -F "." 'BEGIN{num=1;str=""}{if (num <= 3 && !match(str, $1)){str=str$1"-";num++}} END{print str"core-"}')

		echo "HI_PROCHK_CAUSE=$prochk_cause"

		return 0
	}
	

        return 1
}

prochk_process_is_numb_routine()
{
        local chk_command="$1"

        if ! eval $chk_command; then
                return 0
        fi

        return 1
}

prochk_process_dnsmasq_is_numb()
{
        prochk_process_is_numb_routine  'nslookup hwftestdnsmasq.localhost localhost &> /dev/null'

        return $?
}

prochk_process_netifd_is_numb()
{
        prochk_process_is_numb_routine  'ubus call network.device status &> /dev/null'

        return $?
}

prochk_process_nginx_is_numb()
{
        prochk_process_is_numb_routine 'curl -o /dev/null  http://tw/ &> /dev/null'

        return $?
}

prochk_process_fcgi_cgi_is_numb()
{
        return 1
}

prochk_process_inet_chk_sh_is_numb()
{
        return 1
}

prochk_process_cmagent_is_numb()
{
        return 1
}

prochk_process_ubusd_is_numb()
{
        return 1
}

prochk_process_hotplug2_is_numb()
{
        return 1
}

prochk_process_is_numb()
{
        local process=$1

        process=${process//-/_}
        process=${process//./_}
        if prochk_process_"$process"_is_numb; then
                sleep 5
                if prochk_process_"$process"_is_numb; then
                        return 0
                fi
        fi

        return 1
}

prochk_process_is_die()
{
        local target_process=$1

        if ! pidof $target_process > /dev/null; then
                sleep 5
                if ! pidof $target_process > /dev/null; then
                        return 0
                fi
        fi

        return 1
}

prochk_process()
{
        local process=$1

        if prochk_process_is_die $process ; then
                echo "HI_PROCHK_CAUSE="$process"die-"
                return 0
        elif prochk_process_is_numb $process ; then
                echo "HI_PROCHK_CAUSE="$process"numb-"
                return 0
        fi

        return 1
}

prochk_summary()
{
	local prochk_cause= $1

        healib_log "prochk memory lower than 10M, $prochk_cause"
}

prochk_memory()
{
	local free=$(free  | grep '\-/+ buffers:' | awk '{print $4}')

	expr match	"$free" "[0-9][0-9]*$" &> /dev/null
	[ $? -ne 0 ] && return 1

        if [ $free -lt 10240 ]; then
		prochk_summary
                return 1
        fi

        return 0
}

prochk_backup_tgz()
{

	return 
	[ -e $INFOGATHER_BASE_PATH/prochk/tgz/*.tgz ] || return 1

        #Check SD is mounted?
        sd_mounted=$(cat /tmp/state/sd_state 2>/dev/null)
        if [ "$sd_mounted" == "mounted" ];then
                return 1
        fi

        #Check SD iw writable?
        mkdir -p $HI_PROCHK_DISK_PATH
        [ $? -ne 0 ] && {
                return 2
        }

        #Backup latest in Disk
        rm -f $HI_PROCHK_DISK_PATH/*
        cp $INFOGATHER_BASE_PATH/prochk/tgz/*.tgz $HI_PROCHK_DISK_PATH/
}

prochk_clean_tgz()
{
        local tgz_path=$INFOGATHER_BASE_PATH/prochk/tgz

        ls $tgz_path | grep '.*\.tgz\b' &> /dev/null
        if [ $? -eq 0 ];then
                healib_log "prochk clean tgz."
                rm -f $tgz_path/*
        fi

}

prochk_pack_tgz()
{
        local stamp_dir="$1"
        local tgz_path="$INFOGATHER_BASE_PATH/prochk/tgz"

        #clean tgz befor pack new tgz
	prochk_clean_tgz

        pack_tgz "prochk"

	prochk_backup_tgz

        rm -rf $INFOGATHER_BASE_PATH/prochk/db/*

        return 0
}

prochk_get_cause()
{
	local buf=$1
	
	echo $buf | awk -F "HI_PROCHK_CAUSE=" '{print $2}'
}
 
prochk_main() 
{ 
        local rv=1 
	local res=""
        local prochk_cause="" 
 
        res=$(prochk_coredump)
        if [ $? -eq 0 ];then 
		prochk_cause=$(prochk_get_cause $res)
                rv=0 
        fi 
	
 
        for process in $prochk_process_list; do 
                res=$(prochk_process $process)
                [[ $? -eq 0 ]] && { 
			prochk_cause=$prochk_cause$(prochk_get_cause $res)
                        rv=0 
                } 
        done 
	echo "HI_PROCHK_CAUSE=$prochk_cause" 

        return $rv 
} 
