
. /lib/functions/prochk.sh
. /lib/functions/infogather.sh
. /lib/functions/upload.sh

HI_PROCHK_TGZ_PATH="$INFOGATHER_BASE_PATH/prochk/tgz"
processchk_infogather_stamp="$(date +%s)"
processchk_infogather()
{
        local cause_stamp=$1

        [ $# -ne 1 ] && return 1

        if [[ "$(date +%s)" -gt "$processchk_infogather_stamp" ]];then
		
		prochk_clean_tgz

                infogather_main "prochk" $cause_stamp

                processchk_infogather_stamp=$(( $(date +%s) + 300 ))

                return 0
        else
                healib_log  "prochk ignore infogather"

                return 1
        fi
}

processchk_restart()
{
        local process=""

        for process in $prochk_process_list;
        do
                if prochk_process $process; then
                        case "$process" in
                                "nginx")
                                rv=$(/etc/init.d/nginx restart 2>&1)
                                healib_log      "restart $process:$rv"
                                ;;
                                "netifd")
                                rv=$(/etc/init.d/network restart 2>&1)
                                healib_log      "restart $process:$rv"
                                ;;
                                "dnsmasq")
                                rv=$(/etc/init.d/dnsmasq restart 2>&1)
                                healib_log      "restart $process:$rv"
                                ;;
                                "fcgi-cgi")
                                rv=$(/etc/init.d/fcgi-cgi restart 2>&1)
                                healib_log      "restart $process:$rv"
                                ;;
                                "inet_chk.sh")
                                rv=$(/etc/init.d/inet_chk restart 2>&1)
                                healib_log      "restart $process:$rv"
                                ;;
                                "cmagent")
                                rv=$(/etc/init.d/cmagent restart 2>&1)
                                healib_log      "restart $process:$rv"
                                ;;
                                "ubusd")
                                rv=$(/etc/init.d/ubus restart 2>&1)
                                healib_log      "restart $process:$rv"
                                ;;
                                "hotplug2")
                                rv=$(/etc/init.d/boot restart 2>&1)
                                healib_log      "restart $process:$rv"
                                ;;
                        esac
                fi
        done
}

processchk_upload_tgz()
{
        local tgz_path=$HI_PROCHK_TGZ_PATH

        [ -d "$tgz_path" ] || {
                return 0
        }

        feibonacci_backoff_upload_tgz $tgz_path
        if [ $? -eq 1 ] ;then
                healib_log "processchk upload backoff."
                return 1
        elif [ $? -eq 2 ];then
                return 2
        fi

        return 0
}

processchk_main()
{
        local res=""
        local prochk_cause=""
        local cause_stamp=""
        local gathered="false"

        res=$(prochk_main)
        [ $? -eq 0 ] && {
                prochk_cause=$(prochk_get_cause $res)

                prochk_memory
                [ $? -eq 0 ] && {
                        cause_stamp=$HI_ROM_VERSION"-"$prochk_cause$(date +%Y%m%d%H%M%S)"-"$HI_LAN_MAC
                        processchk_infogather "$cause_stamp"
                        [ $? -eq 0 ] && gathered="true"

                }
        }

        ###Try recovery
        processchk_restart

        [ $gathered == "true" ] && {
		infogather_hidaemon_log "prochk" "$cause_stamp"

                prochk_pack_tgz
        }

        processchk_upload_tgz
        rv=$?

	#if [ ! -e $INFOGATHER_BASE_PATH/"prochk"/tgz/*.tgz ]; then
	#	return
	#fi

	#for file in $(ls -t $INFOGATHER_BASE_PATH/"prochk"/tgz | sed '1,1d')
        #do
        #        rm -f $INFOGATHER_BASE_PATH/"prochk"/tgz/$file
        #done

        if [ $rv -eq 0 ];then
		rm -f $HI_PROCHK_TGZ_PATH/*
                return
        fi

        #if [ -e $INFOGATHER_BASE_PATH/"prochk"/tgz/*.tgz ];then
        #        mkdir -p $INFOGATHER_BASE_PATH/"prochk"/oldtgz

        #        rm -f $INFOGATHER_BASE_PATH/"prochk"/oldtgz/*

        #        mv $INFOGATHER_BASE_PATH/"prochk"/tgz/* $INFOGATHER_BASE_PATH/"prochk"/oldtgz 2>/dev/null
        #fi
}
