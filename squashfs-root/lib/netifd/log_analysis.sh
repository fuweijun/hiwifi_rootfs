#!/bin/sh

DEFAULT_LOG_PATH=/var/log/syslog

error_msg() {
	[ -z "$1" ] && echo "Error: protocol should be specified" && return 1

	local __proto=$1
	local __dest=${2:-msg}
	local __idx=1
	local __key
	local __pre
	local __latest
	local __latest_len
	local __msg
	local __i

	# read all logs
	__log=$(logread 2>/dev/null)
	[ $? -ne 0 ] && __log=$(cat $DEFAULT_LOG_PATH)

	case $__proto in
	pppoe)	__key="pppd"	
		__pre="Plugin rp-pppoe\.so loaded"
		;;
	pptp)	__key="pppd"
		__pre="PPTP plugin version"
		;;
	l2tp)	__key="(pppd|xl2tpd)"
		__pre="Connecting to host"
		;;
	*)	return 0
		;;
	esac
	
	# filter daemon'log by key words
	__log=$(echo "$__log"|grep -wE "$__key"|sed -e '1!G;h;$!d')
	
	# just analysis 2 part of latest log
	for __i in $(seq 2)
	do
		# get latest log 
		__latest=$(echo "$__log"|sed -n "$__idx,/$__pre/p"|sed -e '1!G;h;$!d')
		__latest_len=$(echo -n "$__latest"|wc -l)
		__idx=$((__idx+__latest_len))
		
		# check whether the log is empty
		[ ${__latest_len:-0} -eq 0 ] && break

		# check error code first, return it if exsit
		__msg=$(echo "$__latest"|grep -E "E=[0-9]+"|cut -d" " -f5-|grep -vE "^rcvd \["|head -n1)
		[ "X$__msg" != "X" ] && break

		# check daemon error, return it if exsit
		__msg=$(echo "$__latest"|grep -E "daemon\.err"|cut -d" " -f5-|head -n1)
		[ "X$__msg" != "X" ] && break
		
		# check lcp state
		__msg=$(echo "$__latest"|grep -E "LCP terminated by peer"|cut -d" " -f5-|head -n1)
		[ "X$__msg" != "X" ] && break
	done
	
	eval "export -- $__dest=\"$__msg\""
	return 0
}
