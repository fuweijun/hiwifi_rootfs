

###################################
#Infogather routine only for kpanic
#
#
###################################
. /lib/functions/healib.sh
. /lib/functions/upload.sh

HI_KPANIC_TGZ_PATH="$INFOGATHER_BASE_PATH/kpanic/tgz"
HI_KPANIC_DB_PATH="$INFOGATHER_BASE_PATH/kpanic/db"
HI_KPANIC_FILE="/tmp/log/kpanic.log"

gather_kpanic()
{
        local name=""
        local ktgzs=""
        local version=""
        local MAC="$(source /lib/platform.sh;tw_get_mac)"
        local timestamp="$(date +%Y%m%d%H%M%S)"
	local kpanic_path="$HI_KPANIC_TGZ_PATH"

        mkdir -p  $HI_KPANIC_TGZ_PATH
        [[ $? -ne 0 ]] && return 1

        #pack kpanic tgz
        [[ -e "$HI_KPANIC_FILE" ]] && {

                version=$(grep -i 'HiWiFi firmware version' $HI_KPANIC_FILE | sed '2,$d' | awk '{print $4}')
                timestamp=$(grep -i 'Panic Log Begin' $HI_KPANIC_FILE | sed '2,$d' | sed 's/[^0-9]//g')
                name="$INFOGATHER_VERSION-$version-kpanic-$timestamp-$MAC"

		mkdir -p $HI_KPANIC_DB_PATH/$name
                [[ $? -ne 0 ]] && return 2

                mv $HI_KPANIC_FILE $HI_KPANIC_DB_PATH/$name/$name.log
		mv /tmp/data/mtd_log_firmware-* $HI_KPANIC_DB_PATH/$name
		mv /tmp/data/sysupgrade_log-*  $HI_KPANIC_DB_PATH/$name

                tar -czf $HI_KPANIC_TGZ_PATH/$name.tgz -C $HI_KPANIC_DB_PATH $name
                [[ $? -ne 0 ]] && return 3

                rm -rf $HI_KPANIC_DB_PATH/$name

                return $?
        }

        return 0
}

backup_kpanic()
{
	local kpanic_path="$HI_KPANIC_TGZ_PATH"

        for file in $(ls -t $kpanic_path | sed '1,1d')
        do
                rm -f $path/$file
        done

	#backup old kpanic tgz
        if [ -e $kpanic_path/*.tgz ];then

                mkdir -p $INFOGATHER_BASE_PATH/kpanic/oldtgz

                rm -f $INFOGATHER_BASE_PATH/kpanic/oldtgz/*

                cp  $kpanic_path/* $INFOGATHER_BASE_PATH/kpanic/oldtgz/

		rm -f $kpanic_path/*
        fi


}

###################################
#Upload routine only for kpanic
#
#
###################################
upload_kpanic()
{
        local ktgz=""
        local ktgzs=""

        for tgz in $(ls -t $HI_KPANIC_TGZ_PATH/*.tgz 2> /dev/null);do
                upload_data $tgz
                if [ $? -eq 109 ];then
                        return 1
		else
			rm -f $tgz
                fi
        done

        return 0
}
