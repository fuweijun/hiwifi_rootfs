#!/bin/sh

grep -E 'pppd|inetchk' /var/log/syslog 2>/dev/null
