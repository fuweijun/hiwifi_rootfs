
. /lib/functions/packtgz.sh
. /lib/functions/infogather.sh

##############################
#Generate diagnose tgz
#
#
##############################
diagnose_pack_tgz()
{
	local trigger_type="user"
	local cause="diagnose"
        local trigger_path=$INFOGATHER_BASE_PATH/$trigger_type

        source /lib/platform.sh

        #generate diagnose diagnose file
        pack_tgz $trigger_type
        [ $? -ne 0 ] && return 1

        #generate diagnose key
        mkdir -p /tmp/run
        echo "$(tw_get_mac)" > /tmp/run/diagnose_key

        #crypt diagnose file
        hwf_crypto_file /tmp/run/diagnose_key  $trigger_path/tgz/$INFOGATHER_VERSION-diagnose.tgz /tmp/diagnose &>/dev/null
	ln -s /tmp/diagnose  /www/diagnose
	chmod 644 /tmp/diagnose
        chmod 644 /www/diagnose

        #clean tmporary file
        [ -d $trigger_path ] && rm -rf $trigger_path/*

        rm -f /tmp/run/diagnose_key

        return 0
}

diagnose_main()
{
	infogather_main "user" "diagnose"

	diagnose_pack_tgz
}
