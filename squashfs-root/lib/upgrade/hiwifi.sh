#!/bin/sh
#
# Copyright (C) 2013-2014 www.hiwifi.com
#

blink_led_with_num() {
	case $1 in
	1)
		setled timer green system 100 100
		;;
	2)
		setled timer green system 500 1500
		sleep 1
		setled timer green wlan-2p4 500 1500
		;;
	3)
		setled timer green system 500 2500
		sleep 1
		setled timer green internet 500 2500
		sleep 1
		setled timer green wlan-2p4 500 2500
		;;
	4)
		setled timer green system 500 3000
		sleep 1
		setled timer green internet 500 3000
		sleep 1
		setled timer green wlan-5p 500 3000
		sleep 1
		setled timer green wlan-2p4 500 3000
		;;
	esac
}

do_upgrade_bootloader() {
	local loop_min=1
	local loop_max=5

	while [[ $loop_min -le $loop_max ]];
	do
		get_image "$1" | dd bs=2k count=96 conv=sync 2>/dev/null | mtd -q -l write - "${BOOT_NAME:-image}"
		get_image "$1" | dd bs=2k count=96 conv=sync 2>/dev/null | mtd -q -l verify - "${BOOT_NAME:-image}" 2>&1 | grep -qs "Success"
		if [[ "$?" -eq 0 ]]; then
			break
		fi
		loop_min=`expr $loop_min + 1`
	done
}

platform_do_upgrade_hiwifi() {
	local board=$(tw_board_name)
	local upgrade_boot=0
	sync

	case "$board" in
	HC5761 | HC5861 | HB5881 | ZC-9526 | HC5762)
		blink_led_with_num 4
		;;
	HC5661 | HC5663 | BL-855R | ZC-9525)
		blink_led_with_num 3
		;;
	HB5981m | HC5641 | BL-H750AC | BL-T8100)
		blink_led_with_num 2
		;;
	HB5981s | HB5811 | ZC-9527)
		blink_led_with_num 1
		;;
	esac

	if [ -f /tmp/img_has_boot ]; then
		img_boot_version="$(get_boot_version "$1")"
		local_boot_version="$(tw_boot_version)"

		if [ "$img_boot_version" != "$local_boot_version" ]; then
			upgrade_boot=1
		fi
	fi

	sysupgrade_log "start write flash"
	sysupgrade_log "memory"

	if [ "$SAVE_CONFIG" -eq 1 -a -z "$USE_REFRESH" ]; then
		if [ -f /tmp/img_has_boot ]; then
			if [ $upgrade_boot -eq 1 ]; then
				do_upgrade_bootloader "$1"
			fi
			get_image "$1" | dd bs=2k skip=160 conv=sync 2>/dev/null | mtd -q -l -j "$CONF_TAR" write - "${PART_NAME:-image}"
		else
			get_image "$1" | mtd -q -l -j "$CONF_TAR" write - "${PART_NAME:-image}"
		fi
	else
		if [ -f /tmp/img_has_boot ]; then
			if [ $upgrade_boot -eq 1 ]; then
				do_upgrade_bootloader "$1"
			fi
			get_image "$1" | dd bs=2k skip=160 conv=sync 2>/dev/null | mtd -q -l write - "${PART_NAME:-image}"
		else
			get_image "$1" | mtd -q -l write - "${PART_NAME:-image}"
		fi
	fi
	sysupgrade_log "mtd return val $?"
	sysupgrade_log "end write flash"
}
