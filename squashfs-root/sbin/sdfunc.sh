#!/bin/sh

FDISK_CMD_FILE=/tmp/dm-fdisk.cmd
SD_STATE_FILE=/tmp/state/sd_state
STORAGE=/tmp/data

STORAGE_MOUNT_PREFIX=/tmp/storage
STORAGE_INFO_FILE=$STORAGE_MOUNT_PREFIX/storage_info.txt
STORAGE_STATE_FILE=$STORAGE_MOUNT_PREFIX/storage_state

sd_log()
{
	logger -t sdfunc.sh "$device $@"
}

sd_state_set()
{
	echo $1 >$SD_STATE_FILE
	echo $1 >$STORAGE_STATE_FILE
}

hotplug_cb() {
	sd_log "hotplug_cb $@"

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

# $1 storage size
# $2 filesystem type
# $3 status(ro or rw)
# $4 free size
sd_storage_info() {
cat <<EOF >$STORAGE_INFO_FILE
size=$1
fstype=$2
status=$3
freesize=$4
EOF
}

# $1 MAJOR
# $2 MINOR
sd_storage_total_size() {
	local total_size=0

	total_size=$(cat /sys/dev/block/$1:$2/size)
	total_size=${total_size:-0}
	total_size="$((total_size/2048))M"

	sd_log "$1 $2 $total_size"
	sd_storage_info "$total_size" "none" "rw" "$total_size"
}

# $1 device
# $2 force_ro
sd_storage_check() {
	size=$(fdisk -l /dev/mmcblk0 | grep "mmcblk0:" | awk '{print $5}')
	size=${size:-0}
	size="$((size/1000/1000))M"

	if [ "$2" -eq "1" ]; then
		freesize=0
		fstype="ext4"
		status="ro"
	else
		freesize="$(df -m | grep "$1" | awk '{print $4}')M"
		freesize=${freesize:-0}
		fstype="ext4"
		mount | grep "$1" | grep -qs "ro,"
		if [ $? -eq 0 ]; then
			status="ro"
		else
			status="rw"
		fi
	fi

	sd_storage_info "$size" "$fstype" "$status" "$freesize"
}

create_storage() {
	sd_log "create_storage $@"

	local dev_mount=$1

	mkdir -p $STORAGE_MOUNT_PREFIX
	mount | grep "$device" | grep -qs "ro,"
	if [ $? -eq 0 ]; then
		/sbin/sdtest.sh
		sd_storage_check "$device" "0"
		return
	fi

	###mkdir sd-card /tmp/data
	mkdir -p /tmp/data/log
	mkdir -p /tmp/data/opt

	[ ! -L $STORAGE ] && cp -rf $STORAGE/* $dev_mount
	rm -rf $STORAGE
	ln -ns $dev_mount $STORAGE

	[ ! -e $STORAGE/var/lib ] && mkdir -p $STORAGE/var/lib

	/sbin/sdtest.sh
	sd_storage_check "$device" "0"

	hotplug_cb start

	sd_state_set "mounted"
}

stop_storage() {
	sd_log "stop_storage $@"

	rm -rf $STORAGE
	mkdir -p $STORAGE

	hotplug_cb stop

	rm -f /tmp/sdinfo.txt

	sd_state_set "umounted"
}

sd_umount()
{
	sd_log "sd_umount"

	local dev_mount=$(mount | grep mmcblk | awk '{print $3}')
	[ "X" != "X$dev_mount" ] && {
		stop_storage
		local errstr
		errstr=$(umount $dev_mount 2>&1)
		[ $? -ne 0 ] && {
			sd_log "sd_umount $dev_mount failed:$errstr"
		}
	}

	umount /tmp/cryptdata &>/dev/null
	cryptsetup luksClose cryptdata &>/dev/null
}

sd_part()
{
	sd_log "sd_part $@"

	#a) If the size is less than 3G, ignore it.
	eval $(sh /sbin/sdcheck.sh)
	[ $sdsize -lt $minsize ] && {
		sd_log "SD size ${size}M is too small"
		return
	}

	#b) Clear the old partition table.
	#c) Create two partitions: 1G and Other
	#mkfs.ext4 /dev/mmcblk0

	local errstr
        errstr=$(dd if=/dev/zero of=/dev/mmcblk0 bs=32k count=4 2>&1)
        if [ $? -ne 0 ];then
                sd_log "p1 $errstr"
        fi
        errstr=$(dd if=/dev/zero of=/dev/mmcblk0 bs=32k count=4 seek=31250 2>&1)
        if [ $? -ne 0 ];then
                sd_log "p2 $errstr"
        fi

cat <<EOF >$FDISK_CMD_FILE
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
	fdisk /dev/mmcblk0 <$FDISK_CMD_FILE
	rm -rf $FDISK_CMD_FILE
	sync

	return 0
}

sd_force_part()
{
	sd_log "sd_force_part"

	device="[force]"

	sd_umount 

	sd_part "force"
}

sd_manual_part()
{
	sd_log "sd_manual_part"

	device="[manual]"

	sd_part "manual"
}

