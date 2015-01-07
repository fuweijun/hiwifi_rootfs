INFOGATHER_VERSION="a2"
HI_LAN_MAC="$(source /lib/platform.sh;tw_get_mac)"
HI_ROM_VERSION=""

if [ -e "/etc/.build" ]; then
        HI_ROM_VERSION=$(awk '{if (NR == 1){print $1}}' /etc/.build)
        #The max len of string rom_veriosn is 32.
        HI_ROM_VERSION=${HI_ROM_VERSION:0:32}
fi

HI_COREDUMP_PATH="/tmp/coredump"
INFOGATHER_BASE_PATH="/tmp/infogather"
prochk_process_list="nginx dnsmasq fcgi-cgi netifd inet_chk.sh cmagent ubusd hotplug2 rsyslogd"
HI_HEALTH_LOG_FILE="/tmp/infogather/hidaemon.log"
mkdir -p $INFOGATHER_BASE_PATH

healib_rewind_log()
{
        local line=0

        [ $? -ne 1 ] && return 1

	line=$(cat $HI_HEALTH_LOG_FILE 2> /dev/null| wc -l)
	if [ "$line" -gt 1000 ];then
		sed -i '1,500d' $HI_HEALTH_LOG_FILE
		echo "$(date):Exceed 1000 lines" >> $HI_HEALTH_LOG_FILE
	fi

        return 0
}

healib_log()
{
        local mesg="$1"

        [ $# -ne 1 ] && return 1
	
	healib_rewind_log

        echo "$(date +%Y%m%d%H%M%S):$mesg" >> $HI_HEALTH_LOG_FILE
}
