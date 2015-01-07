#!/bin/sh

type() {
    uci get hiwifi.storage.type
}

minsize() {
    uci get hiwifi.storage.minsize
}

state() {
   if [ -f /tmp/storage/storage_state ]; then
     cat /tmp/storage/storage_state
   else
     echo "removed"
   fi
}

info() {
    if [ -f /tmp/storage/storage_info.txt ]; then
        cat /tmp/storage/storage_info.txt
    else
        echo ""
    fi
}

sd_format() {
    (source /sbin/sdfunc.sh && sd_manual_part &)
}

disk_format() {
    (source /sbin/storage_format &)
}
