#!/bin/sh

timeout_handler()
{
	pkill -9 -P $1
	kill -9 $1
}

run_cmd()
{
	nslookup $1 >/dev/null 2>&1
	timeout_handler $2
}

set_timeout()
{
	sleep $1
	timeout_handler $2
}

if [ ! $1 ]; then
	echo "no param"
	exit
fi

run_cmd $1 $$ &

set_timeout 30 $!
