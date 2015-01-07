#!/bin/sh

logger -t system "guide_done.sh: version: $(cat /etc/.build)"

/etc/init.d/hcsh stop 2>/dev/null
/etc/init.d/hcsh disable 2>/dev/null

mkdir -p /lib/upgrade/keep.d/
echo /lib/upgrade/keep.d/stop_hcshd  >/lib/upgrade/keep.d/stop_hcshd
