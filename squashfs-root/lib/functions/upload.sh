#########################
#Upload data routine
#
#
########################

. /lib/functions/healib.sh

upload_data()
{
        source /lib/platform.sh
        source /usr/share/libubox/jshn.sh

        local FILE="$1"
        local answer=""
        local MAC=$(tw_get_mac)
        local KEY=$(getrouterid_infogather)
        local FILE_MD5=$(md5sum $FILE | awk '{print $1}')
        local VERSION=$(cat /etc/.build)
		local REALVERSION=$(cat /etc/.build | awk '{print $1}')
		local BOARD=$(cat /proc/cmdline | awk '{print $1}' | awk -F= '{print $2}')

		if [ $# == 3 ]; then
			echo $2 | grep -oE '[0-9]\.[0-9]{4,}\.[0-9]{4,}s' &> /dev/null
			if [ $? -eq 0 ]; then
				REALVERSION=$2
			fi
		fi
	
        answer=$(curl -m 300 -F action=upload -F MAC=$MAC -F KEY=$KEY -F TAG=$2 -F BOARD=$BOARD -F VERSION="$VERSION" -F file=@$FILE -F FILE_MD5=$FILE_MD5 -F REALVERSION=$REALVERSION "https://hwf-health-chk.hiwifi.com/index.php" -v -k 2>/dev/null)
        rv="$?"
        if [ "$rv" -eq 0 ]; then
                json_load "$answer" 2>/dev/null

                json_get_var code code
                case "$code" in
                        "200")
                                #Upload success.
                                healib_log "upload success, $File, code=$code,answer=$answer."
                                return 0
                                ;;
                        "201")
                                #File already existed in server.
                                healib_log "upload existed error, $File, code=$code,answer=$answer."
                                return 1
                                ;;
                        "202")
                                #Checksum MD5 failed.
                                healib_log "upload MD5 error, $File, code=$code,answer=$answer."
                                return 2
                                ;;
                        "203")
                                #Key authorized failed.
                                healib_log  "upload Kye auth error, $File, code=$code,answer=$answer."
                                return 3
                                ;;
                        *)
                                #Default
                                healib_log "upload default error, $File, code=$code,answer=$answer."
                                return 4
                                ;;
                esac
        else
                healib_log "upload failed, $File, code=$code,answer=$answer."
		#Connect timeout
                return 109
        fi

}

###########################################
# Do not use this function unless prochk
#
#Feibonacci backoff upload algorithm
#Parameters:
#Path of tgz to be uploaded
#Tips:  * Invoke from while loop
#       * To avoid conntuing gerneting tgz
###########################################
#Feibonacci previous
fp=2
#Fibonacci next
fn=3
#Fibonacci effective
fe=0
#Fibonacci time
ft="$(date +%s)"
feibonacci_backoff_upload_tgz()
{
        local rv=""
        local file=""
        local files=""
        local cur_time=$(date +%s)
        local tgz_path=$1

	[ $# -ne 1 ] && return 0

        ls $tgz_path | grep '.*.tgz\b' &> /dev/null
        if [ $? -eq 0 ]; then
                if [ $cur_time -gt $ft ];then
			#2, 3, 5, 8, 13, 21, 34, 55, 89, 144
			#Max interval time 60 minutes.
                        if [ $fe -ge 55 ]
                        then
                                fe=60
                        else
                                fe=$(( fp + fn ))
                                fp=$fn
                                fn=$fe
                        fi

                        ft=$(date +%s)
                        ft=$(( ft + fe * 60))
                        #logger -t "hu" "ft=$ft fe=$fe fp=$fp fn=$fn"

                        files=$(ls -t $tgz_path | grep ".*.tgz\b")
                        if [ $? -eq 0 ]; then
                                for file in $files
                                do
                                        #logger -t "hu" "$file"
                                        upload_data $tgz_path/$file
                                        if [ $? -eq 109 ]; then
                                                return 2
                                        fi
                                done
                        fi
                        return 0
                else
			#found tgz
                        return 1
                fi
        else
                #logger -t 'hu' "else"
                if [ $cur_time -gt $ft ];then
                        #logger -t "else $cur_time $ft"
                        ft=0
                        fe=0
                        fn=2
                        fp=3
                fi

                return 0
        fi
}
