#!/bin/sh
# Copyright (C) 2013-2014 www.hiwifi.com

STORAGE_PATH=/tmp/data
EXTRA_STORAGE_PATH=/tmp/bigdata
STORAGE_MOUNT_PREFIX=/tmp/storage
STORAGE_STATE_FILE=$STORAGE_MOUNT_PREFIX/storage_state
STORAGE_INFO_FILE=$STORAGE_MOUNT_PREFIX/storage_info.txt
STORAGE_FORCE_FORMAT=$STORAGE_MOUNT_PREFIX/storage_forceformat
CRYPT_MOUNT_POINT=/tmp/cryptdata
FORMAT_DATA_FLAG_FILE=$STORAGE_MOUNT_PREFIX/format_data_flag

hiwifi_storage_log() {
	logger -t storage "$@"
}

hiwifi_hotplug_cb() {
	local action=$1

	for restart_file in /etc/hotplug.d/block/restart.d/* ; do
		$restart_file restart
	done

	for action_file in /etc/hotplug.d/block/action.d/* ; do
		$action_file $action
	done
}

sd_ro_state() {
	ro_stat=$(cat /sys/dev/block/$MAJOR:$MINOR/ro)

	echo "$ro_stat"
}

hiwifi_storage_state_set() {
	echo $1 >$STORAGE_STATE_FILE
}

hiwifi_storage_get_state() {
	storage_state="removed"
	if [ -f $STORAGE_STATE_FILE ]; then
		storage_state=$(cat $STORAGE_STATE_FILE)
	fi
	echo "$storage_state"
}

hiwifi_get_storage_size() {
	local storage_size="size=0M"
	if [ -f $STORAGE_STATE_FILE -a -f $STORAGE_INFO_FILE ]; then
		storage_size=$(sed -n '1p' $STORAGE_INFO_FILE)
	fi
	echo ${storage_size##size=}
}

hiwifi_get_storage_fstype() {
	local storage_fstype="fstype=none"
	if [ -f $STORAGE_STATE_FILE -a -f $STORAGE_INFO_FILE ]; then
		storage_fstype=$(sed -n '2p' $STORAGE_INFO_FILE)
	fi
	echo ${storage_fstype##fstype=}
}

hiwifi_get_storage_status() {
	local storage_status="status=rw"
	if [ -f $STORAGE_STATE_FILE -a -f $STORAGE_INFO_FILE ]; then
		storage_status=$(sed -n '3p' $STORAGE_INFO_FILE)
	fi
	echo ${storage_status##status=}
}

hiwifi_get_storage_freesize() {
	local hwf_mount_point
	local storage_freesize="0M"

	if [ -L $STORAGE_PATH ]; then
		hwf_mount_point=$(ls -l /tmp/data | awk '{print $11}')
		storage_freesize="$(df -m | grep "$hwf_mount_point$" | awk '{print $4}')"M
	fi

	echo "$storage_freesize"
}

hiwifi_get_format_data_flag() {
	local format_data_flag="0"
	if [ -f $FORMAT_DATA_FLAG_FILE ]; then
		format_data_flag=$(cat $FORMAT_DATA_FLAG_FILE)
	fi
	echo "$format_data_flag"
}

hiwifi_set_format_data_flag() {
	echo $1 >$FORMAT_DATA_FLAG_FILE
}

# $1 filesystem type
# $2 status(ro or rw)
# $3 free size
hiwifi_storage_info() {
	local total_size=$(hiwifi_get_storage_size)
cat <<EOF >$STORAGE_INFO_FILE
size=$total_size
fstype=$1
status=$2
freesize=$3
EOF
}

# $1 MAJOR
# $2 MINOR
hiwifi_storage_total_size() {
	local total_size=0

	total_size=$(cat /sys/dev/block/$1:$2/size)
	total_size=${total_size:-0}
	total_size="$((total_size*512/1000000))M"

	hiwifi_storage_log "$1 $2 $total_size"
	echo "size=$total_size" >$STORAGE_INFO_FILE
}

# $1 dev_path
# $2 dev_mount_point
hiwifi_start_storage() {
	mount | grep "$1" | grep -qs "ro,"
	if [ $? -eq 0 ]; then
		return
	fi

	mkdir -p /tmp/data/log
	mkdir -p /tmp/data/opt

	[ ! -L $STORAGE_PATH ] && cp -rf $STORAGE_PATH/* $2
	rm -rf $STORAGE_PATH
	ln -ns $2 $STORAGE_PATH

	[ ! -e $STORAGE_PATH/var/lib ] && mkdir -p $STORAGE_PATH/var/lib

	hiwifi_hotplug_cb start
}

hiwifi_stop_storage() {
	hiwifi_storage_log "hiwifi_stop_storage $@"

	if [ -L $STORAGE_PATH ]; then
		hiwifi_storage_log "hiwifi_stop_storage remove $STORAGE_PATH"
		rm -rf $STORAGE_PATH
		mkdir -p $STORAGE_PATH
		hiwifi_hotplug_cb stop
	fi
}

hiwifi_sd_umount()
{
	local dev_mount=$(mount | grep mmcblk | awk '{print $3}')
	sync

	[ "X" != "X$dev_mount" ] && {
		hiwifi_stop_storage
		sleep 1
		if [ "$1" == "1" ]; then
			fuser -m -k $dev_mount
		fi
		local errstr
		errstr=$(umount -l $dev_mount 2>&1)
		[ $? -ne 0 ] && {
			hiwifi_storage_log "sd_umount $dev_mount failed:$errstr"
		}
	}

	if [ "$1" == "1" ]; then
		fuser -m -k /tmp/cryptdata
	fi
	umount -l /tmp/cryptdata &>/dev/null
	cryptsetup luksClose cryptdata &>/dev/null

	hiwifi_storage_state_set "umounted"
}

hiwifi_get_mount_option() {
	local mount_option=""
	local storage_type=$(uci get hiwifi.storage.type)

	case "$storage_type" in
	"SD")
		mount_option="noatime,nodiratime,nouser_xattr,data=writeback,discard"
		;;
	*)
		mount_option="noatime,nodiratime"
		;;
	esac

	echo "$mount_option"
}

hiwifi_get_mkfs_option() {
	local mkfs_option="-m 1"
	local storage_type=$(uci get hiwifi.storage.type)

	case "$storage_type" in
	"SD")
		mkfs_option="-O ^has_journal -b 2048 -m 1"
		;;
	esac

	echo "$mkfs_option"
}

hiwifi_partition() {
	hiwifi_storage_log "$1 start auto partition"
	local hiwifi_partition_cmd=/tmp/hiwifi-fdisk.cmd
	local storage_type=$(uci get hiwifi.storage.type)

	case "$storage_type" in
	"SD")
		hiwifi_sd_umount "0"
		local errstr
		errstr=$(dd if=/dev/zero of=$1 bs=32k count=4 2>&1)
		if [ $? -ne 0 ];then
			hiwifi_storage_log "p0 $errstr"
			return 1
		fi
		errstr=$(dd if=/dev/zero of=$1 bs=32k count=4 seek=256 2>&1)
		if [ $? -ne 0 ];then
			hiwifi_storage_log "p1 $errstr"
			return 1
		fi
		errstr=$(dd if=/dev/zero of=$1 bs=32k count=4 seek=33024 2>&1)
		if [ $? -ne 0 ];then
			hiwifi_storage_log "p2 $errstr"
			return 1
		fi

		hiwifi_set_format_data_flag "1"
cat <<EOF >$hiwifi_partition_cmd
p
o
n
p
1
16384
2113535
n
p
2
2113536

p
w
EOF
		fdisk -u $1 <$hiwifi_partition_cmd
		rm -f $hiwifi_partition_cmd
		sync
		return 0
		;;
	esac

	hiwifi_set_format_data_flag "1"
cat <<EOF >$hiwifi_partition_cmd
p
o
n
p
1
1
+1024M
n
p
2


p
w
EOF
	fdisk $1 <$hiwifi_partition_cmd
	rm -f $hiwifi_partition_cmd
	sync
	return 0
}

# $1 dev_path
# $2 ID_FS_TYPE(filesystem type)
# $3 dev_mount_point
hiwifi_mount_fs() {
	mkdir -p "$3" &>/dev/null

	umount -l "$3"

	if [ "$2" == "msdos" -o "$2" == "vfat" ] ; then
		mount -t vfat -o noatime,fmask=0000,dmask=0000,iocharset=utf8 "$1" "$3"
		if [ $? -eq "0" ]; then
			return 0
		fi
	elif [ "$2" == "ntfs" ] ; then
		ntfs-3g -o windows_names,big_writes,noatime,nls=utf8 "$1" "$3"
		if [ $? -eq "0" ]; then
			return 0
		fi
	elif [ "$2" == "exfat" ] ; then
		mount -t exfat -o noatime,fmask=0,dmask=0,iocharset=utf8 "$1" "$3"
		if [ $? -eq "0" ]; then
			return 0
		fi
	elif [ "$2" == "ext4" -o "$2" == "ext3" -o "$2" == "ext2" ] ; then
		e2fsck -y "$1"
		mount -t "$2" -o noatime "$1" "$3"
		if [ $? -eq "0" ]; then
			return 0
		fi
	fi

	return 1
}


# $1 dev_path
# $2 dev_mount_point
# $3 ID_FS_TYPE
# $4 FORCE
hiwifi_mount_with_ext4() {
	local format_flag=$(hiwifi_get_format_data_flag)
	local mount_option=$(hiwifi_get_mount_option)
	local mkfs_option=$(hiwifi_get_mkfs_option)

	umount -l "$2"

	if [ "$3" != "ext4" ]; then
		if [ "$4" -eq "1" ]; then
			mkfs.ext4 $mkfs_option "$1"
			hiwifi_set_format_data_flag "0"
		else
			hiwifi_storage_state_set "not-formated"
			return 1
		fi
	else
		if [ "$format_flag" -eq "1" ]; then
			mkfs.ext4 $mkfs_option "$1"
			hiwifi_set_format_data_flag "0"
		else
			e2fsck -y "$1"
		fi
	fi

	mkdir -p "$2" &>/dev/null
	mount -t ext4 -o $mount_option "$1" "$2"
	if [ "$?" -eq "0" ]; then
		size="$(df -m | grep "$1" | awk '{print $2}')M"
		freesize="$(df -m | grep "$1" | awk '{print $4}')M"
		fstype="ext4"
		mount | grep "$1" | grep -qs "ro,"
		if [ $? -eq 0 ]; then
			status="ro"
		else
			status="rw"
		fi
		hiwifi_storage_info "$fstype" "$status" "$freesize"
		hiwifi_storage_state_set "mounted"
		return 0
	else
		hiwifi_storage_log "mount with ext4 failed: $?"
		hiwifi_storage_state_set "mount-failed"
	fi

	return 1
}

hiwifi_sd_mount_cryptdata()
{
	local hwf_dm_passwd_file=/tmp/storage-dm-passwd
	local mount_option=$(hiwifi_get_mount_option)
	local mkfs_option=$(hiwifi_get_mkfs_option)

	hiwifi_storage_log "mount_cryptdata $ID_FS_TYPE $@"

	#Make sure the data partition exist.
	fdisk -l /dev/mmcblk0 | grep mmcblk0p2
	[ $? -ne 0 ] && return 1

	#Cleanup
	umount -l /tmp/cryptdata &>/dev/null
	cryptsetup luksClose cryptdata &>/dev/null

	#Get the passwd.
	echo $(/sbin/hi_crypto_key device-crypt-key) >$hwf_dm_passwd_file

	cryptsetup luksOpen /dev/mmcblk0p1 cryptdata -d $hwf_dm_passwd_file
	if [ $? -ne 0 -o "$ID_FS_TYPE" != "crypto_LUKS" ]; then
		#TODO: The size is not checked now.
		hiwifi_storage_log "mount_cryptdata luksFormat"
		yes YES | cryptsetup luksFormat /dev/mmcblk0p1 -c aes-cbc-plain -d $hwf_dm_passwd_file
		cryptsetup luksOpen /dev/mmcblk0p1 cryptdata -d $hwf_dm_passwd_file
	fi

	mkdir /tmp/cryptdata &>/dev/null
	mount -t ext4 -o $mount_option /dev/mapper/cryptdata /tmp/cryptdata
	[ $? -ne 0 ] && {
		hiwifi_storage_log "mount_cryptdata mkfs.ext4"
		mkfs.ext4 $mkfs_option /dev/mapper/cryptdata
		mount -t ext4 -o $mount_option /dev/mapper/cryptdata /tmp/cryptdata
	}

	return 0
}

# $1 dev_path
# $2 ID_FS_TYPE
# $3 FORCE
hiwifi_mount_cryptdata() {
	local hwf_dm_passwd_file=/tmp/storage-dm-passwd
	local mount_option=$(hiwifi_get_mount_option)
	local mkfs_option=$(hiwifi_get_mkfs_option)

	hiwifi_storage_log "$1 filesystem is $2(mount to cryptdata)"

	# get the passwd
	echo $(/sbin/hi_crypto_key device-crypt-key) >$hwf_dm_passwd_file

	if [ "$3" -eq "1" ]; then
		# cleanup
		umount -l $CRYPT_MOUNT_POINT &>/dev/null
		cryptsetup luksClose cryptdata &>/dev/null

		cryptsetup luksOpen "$1" cryptdata -d $hwf_dm_passwd_file

		if [ "$?" -ne "0" ]; then
			hiwifi_storage_log "cryptsetup"
			# TODO: The size is not checked now.
			yes YES | cryptsetup luksFormat $1 -c aes-cbc-plain -d $hwf_dm_passwd_file
			cryptsetup luksOpen $1 cryptdata -d $hwf_dm_passwd_file
		fi

		mkdir -p $CRYPT_MOUNT_POINT &>/dev/null
		mount -t ext4 -o $mount_option /dev/mapper/cryptdata $CRYPT_MOUNT_POINT
		[ $? -ne 0 ] && {
			hiwifi_storage_log "mkfs.ext4"
			mkfs.ext4 $mkfs_option /dev/mapper/cryptdata
			mount -t ext4 -o $mount_option /dev/mapper/cryptdata $CRYPT_MOUNT_POINT
		}
	else
		if [ "$2" != "crypto_LUKS" ]; then
			hiwifi_storage_state_set "not-formated"
		else
			hiwifi_storage_log "$1 filessytem is crypto_LUKS"
			# cleanup
			umount -l $CRYPT_MOUNT_POINT &>/dev/null
			cryptsetup luksClose cryptdata &>/dev/null

			cryptsetup luksOpen "$1" cryptdata -d $hwf_dm_passwd_file
			if [ "$?" -ne "0" ]; then
				hiwifi_storage_log "cryptsetup failed with $1"
				hiwifi_storage_log "restart cryptsetup"
				# TODO: The size is not checked now.
				yes YES | cryptsetup luksFormat $1 -c aes-cbc-plain -d $hwf_dm_passwd_file
				cryptsetup luksOpen $1 cryptdata -d $hwf_dm_passwd_file
			fi

			mkdir -p $CRYPT_MOUNT_POINT &>/dev/null
			mount -t ext4 -o $mount_option /dev/mapper/cryptdata $CRYPT_MOUNT_POINT
			[ "$?" -ne "0" ] && {
				hiwifi_storage_log "mount /dev/mapper/cryptdata to $CRYPT_MOUNT_POINT with ext4 failed"
				hiwifi_storage_log "mkfs.ext4"
				mkfs.ext4 $mkfs_option /dev/mapper/cryptdata
				mount -t ext4 -o $mount_option /dev/mapper/cryptdata $CRYPT_MOUNT_POINT
			}
		fi
	fi

	return 0
}

hiwifi_storage_force_format() {
	. /lib/platform.sh
	local board=$(tw_board_name)
	local power=/sys/devices/platform//hiwifi:power/ata/value
	local storage_type=$(uci get hiwifi.storage.type)

	case "$storage_type" in
	"SD")
		hiwifi_sd_umount "$1"
		hiwifi_partition "/dev/mmcblk0"
		;;
	"DISK")
		case "$board" in
		"HC5663")
			# power off
			echo  1 > $power
			sleep 20
			mkdir -p $STORAGE_MOUNT_PREFIX &>/dev/null
			touch $STORAGE_FORCE_FORMAT
			# power on to restart hotplug
			echo 0 > $power
			return 0
			;;
		"BL-H750AC" | "BL-T8100")
			mkdir -p $STORAGE_MOUNT_PREFIX &>/dev/null
			touch $STORAGE_FORCE_FORMAT
			usbdev=$(usbreset | grep -is ehci | awk -F 'Number ' '{print $2}' | awk '{print $1}')
			usbreset $usbdev
			usbdev=$(usbreset | grep -is ohci | awk -F 'Number ' '{print $2}' | awk '{print $1}')
			usbreset $usbdev
			return 0
			;;
		esac
		;;
	*)
		case "$board" in
		"tw150v1")
			touch /.forceformat
			usbdev=$(usbreset | grep -is ehci | awk -F 'Number ' '{print $2}' | awk '{print $1}')
			usbreset $usbdev
			usbdev=$(usbreset | grep -is ohci | awk -F 'Number ' '{print $2}' | awk '{print $1}')
			usbreset $usbdev
			return 0
			;;
		esac
		;;
	esac

	return 1
}

# $1 force
hiwifi_storage_format() {
	local storage_state=$(hiwifi_storage_get_state)

	if [ "$1" -ne 0 ]; then
		hiwifi_storage_log "force format"
		case "$storage_state" in
		"removed" | "lock")
			hiwifi_storage_log "$storage_state can not force format"
			return 1
			;;
		*)
			hiwifi_storage_log "force format"
			if [ "$1" == "2" ]; then
				hiwifi_storage_force_format "1"
			else
				hiwifi_storage_force_format "0"
			fi
			return $?
			;;
		esac
	else
		case "$storage_state" in
		"mounted" | "removed" | "lock")
			hiwifi_storage_log "$storage_state can not format"
			return 1
			;;
		*)
			hiwifi_storage_log "manual format"
			hiwifi_storage_force_format "0"
			return $?
			;;
		esac
	fi

	return 1
}

# $1 device
hiwifi_storage_handle_offline() {
	local storage_type=$(uci get hiwifi.storage.type)

	case "$storage_type" in
	"DISK")
		local part_num=$(echo "$1" | awk -F 'sd[a-z]' '{print $2}')
		if [ "$part_num" -eq "2" ]; then
			hiwifi_storage_log "$1 become ro, restart apps"
			hiwifi_stop_storage
		fi
		;;
	"SD")
		if [ "$1" == "mmcblk0p2" ]; then
			hiwifi_storage_log "$1 become ro, restart apps"
			hiwifi_stop_storage
		fi
		;;
	esac
}

# $1 dev_path
# $2 ACTION
# $3 device
# $4 ID_FS_TYPE(filesytem type)
hiwifi_storage_handle() {
	local storage_type=$(uci get hiwifi.storage.type)
	local dev_mount_point="$STORAGE_MOUNT_PREFIX/$3"
	local part_num=$(echo "$1" | awk -F 'sd[a-z]' '{print $2}')

	mkdir -p $STORAGE_MOUNT_PREFIX &>/dev/null

	case "$2" in
	add)
		case "$storage_type" in
		"DISK")
			if [ -z $part_num ]; then
				hiwifi_set_format_data_flag "0"
				hiwifi_storage_log "log start with $1 $2 $3 $4"
				hiwifi_storage_total_size "$MAJOR" "$MINOR"

				fdisk -l "$1" | grep -qs "doesn't contain a valid partition table"

				# no partition table
				if [ "$?" -eq 0 -a -z $4 ]; then
					hiwifi_storage_log "$1 no valid partition table"
					# no partitions just auto formated
					hiwifi_partition "$1"
					hiwifi_storage_state_set "auto-formated"
				else
					if [ -f "$STORAGE_FORCE_FORMAT" ]; then
						hiwifi_storage_log "force format storage $1"
						hiwifi_partition "$1"
						hiwifi_storage_state_set "auto-formated"
						rm -f "$STORAGE_FORCE_FORMAT"
						return 1
					fi

					# 3 or more partitions
					fdisk -l "$1" | grep -qs "$1"3
					if [ "$?" -eq 0 ]; then
						hiwifi_storage_log "$1 more than 2 partitions"
						hiwifi_storage_state_set "not-formated"
						return 1
					fi

					# only 1 partitions
					fdisk -l "$1" | grep -qs "$1"2
					if [ "$?" -ne 0 ]; then
						hiwifi_storage_log "$1 no the second partition"
						hiwifi_storage_state_set "not-formated"
						return 1
					fi

					hiwifi_storage_state_set "formated"
				fi
			else
				storage_state=$(cat $STORAGE_STATE_FILE)
				hiwifi_storage_log "$1 $2 $3 $4 $storage_state"

				case "$storage_state" in
				"auto-formated")
					# auto formated, need to create filesystem
					if [ "$part_num" -eq "1" ]; then
						hiwifi_storage_log "auto-formated mount with device $1 $4"
						hiwifi_mount_cryptdata "$1" "$4" "1"
					else
						[ -e /dev/mapper/cryptdata ] && {
							hiwifi_storage_log "auto-formated mount_ext4 with device $1 $4"
							hiwifi_mount_with_ext4 "$1" "$dev_mount_point" "$4" "1"
							[ $? -eq 0 ] && hiwifi_start_storage "$1" "$dev_mount_point"
						}
					fi
					;;
				"not-formated")
					return 1
					;;
				*)
					# only have two partitions, but the filesystem is unknown
					if [ "$part_num" -eq "1" ]; then
						# if not crypt partition, set to not-formated
						hiwifi_storage_log "formated mount with device $1 $4"
						hiwifi_mount_cryptdata "$1" "$4" "0"
					else
						[ -e /dev/mapper/cryptdata ] && {
							hiwifi_storage_log "formated mount_ext4 with device $1 $4"
							hiwifi_mount_with_ext4 "$1" "$dev_mount_point" "$4" "0"
							[ $? -eq 0 ] && hiwifi_start_storage "$1" "$dev_mount_point"
						}
					fi
					;;
				esac
			fi
			;;
		*)
			if [ -z "$part_num" ]; then
				sdx_count=$(fdisk -l "$1" | grep ^/dev/sd | wc -l)
				unknown_count=$(fdisk -l "$1" | grep -i unknown | wc -l)
				empty_count=$(fdisk -l "$1" | grep -i empty | wc -l)
				false_count=$(($unknown_count+$empty_count))
				if [ "$sdx_count" -eq "$false_count" ]; then
					hiwifi_mount_fs "$1" "$4" "$dev_mount_point"
				fi
			else
				hiwifi_mount_fs "$1" "$4" "$dev_mount_point"
			fi
			rm -rf $EXTRA_STORAGE_PATH &>/dev/null
			ln -s $dev_mount_point $EXTRA_STORAGE_PATH
			;;
		esac
		;;
	remove)
		case "$storage_type" in
		"DISK")
			hiwifi_storage_log "log end with $1 $2 $3"
			if [ "$part_num" -eq "1" ]; then
				sync
				umount -l $CRYPT_MOUNT_POINT &>/dev/null
				cryptsetup luksClose cryptdata &>/dev/null
			elif [ "$part_num" -eq "2" ]; then
				sync
				hiwifi_stop_storage
				# wait for process stop
				sleep 1
				umount -l $dev_mount_point &>/dev/null
				hiwifi_storage_state_set "removed"
			else
				sync
				umount -l $dev_mount_point &>/dev/null
				hiwifi_storage_state_set "removed"
			fi
			;;
		*)
			rm -rf $EXTRA_STORAGE_PATH &>/dev/null
			mkdir -p $EXTRA_STORAGE_PATH
			sync
			umount -l $dev_mount_point &>/dev/null
			;;
		esac
		;;
	esac

	return 0
}
