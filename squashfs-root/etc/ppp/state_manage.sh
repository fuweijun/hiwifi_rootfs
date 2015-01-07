#!/bin/sh
#in pppd-manage.sh USR1 mean success, USR2 mean failed
#in autowantupe.sh USR1 mean dhcp result, USR2 mean pppoe result

file=/tmp/state/ppp_state
sniffer_server_failed()
{
	echo noserver >$file
	kill -USR2 $(pidof pppd-manage.sh)
	kill -USR2 $(pidof autowantype)
}

failed()
{
	echo authfail >$file
	kill -USR2 $(pidof pppd-manage.sh)
	kill -USR2 $(pidof autowantype)
}

success()
{
	echo success >$file
	kill -USR1 $(pidof pppd-manage.sh)
	kill -USR2 $(pidof autowantype)
}

$@
