
. /lib/functions/healib.sh

###################################
#Logger systemload of top to syslog
#
###################################
sysmonitor_log_systemload()
{
        echo "$(top -bn 1 | sed '12,$d' |sed '4d' | grep -v 'top -bn 1' | awk '{if(NR > 3){print $5" "$6" "$7" "$8""} else {print $0""}}')" |  while read -r line ;
        do
                logger -t systemload $line
        done

        return 0
}

systemload_log_stamp=$(date +%s)
periodical_log_systemload()
{
        cur_stamp=$(date +%s)
        if [ $cur_stamp -gt $systemload_log_stamp ];then
                systemload_log_stamp=$(( cur_stamp + 300 ))
                sysmonitor_log_systemload
        fi
}

sysmonitor_clean_coredumps()
{
        local coredumps=""

        coredumps=$(ls -t $HI_COREDUMP_PATH | grep '.*\.core\b' | sed '1,1d')

        for core in $coredumps; do
                healib_log "sysmonitor clean coredump  $HI_COREDUMP_PATH/$core"
                rm -f $HI_COREDUMP_PATH/$core
        done

        return 0
}

sysmonitor_log()
{
	local mesg=$1

	healib_log "sysmonitor $mesg"
}

sysmonitor_clean_subtmpspace()
{
	local clean_dir=$1
	local exit=0

	
	for dir in $clean_dir
	do 
		largefile=$(find $dir -type f | xargs du | sort -n -r | awk '{if(NR==1) print $2}')
		[ ! -e $largefile ] && return
		
		if [ $(du $largefile | awk '{print $1}') -gt 1024 ]; then
			exit=1
		else
			continue
		fi
		
		if [ $largefile = '.' ]; then
			echo "no more file can be removed."
			return
		else
			echo "$largefile too big, cleared by sysmonitor" > $largefile
			sysmonitor_log "$largefile too big, cleared by sysmonitor"
			sync
		fi
	done

	return $exit
}

sysmonitor_clean_tmpspace()
{
	local clean_dir="/tmp/log"
	
        [ $# -ne 1 ] && {
                echo "Please input the size of space need to be reserved."
                return 1
        }
        reservedspace=$1

        if [ -L $HIWIFI_DATA -o ! -e $HIWIFI_DATA ]; then 
                echo "$HIWIFI_DATA isn't a directory, none more space can be freed in /tmp/data."
	elif [ -d $HIWIFI_DATA ];then
		clean_dir=$clean_dir" $HIWIFI_DATA"
	fi

	freespace=$(free | grep '\-/+ buffers:' | awk '{print $4}')
        while [ $freespace -lt $reservedspace ]; do
		sysmonitor_clean_subtmpspace	$clean_dir
		[ $? -eq 0 ] && return 1	

		freespace=$(free | grep '\-/+ buffers:' | awk '{print $4}')
		
        done

        return 0

}


sysmonitor_main()
{
	sysmonitor_clean_coredumps

        sysmonitor_clean_tmpspace 2000 &>/dev/null
}

