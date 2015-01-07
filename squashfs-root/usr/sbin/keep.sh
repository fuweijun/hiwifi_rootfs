#!/bin/sh

backup_root="/tmp/data/backup"
hiwifi_backup_key_file=/tmp/hiwifi_backup_key

backup() {
  today=$(date "+%Y%m%d")
  todaybackup="${backup_root}/${today}"
  mkdir -p "$todaybackup" && 
  ( find $(sed -ne '/^[[:space:]]*$/d; /^#/d; p' /lib/upgrade/keep.d/* 2>/dev/null) -type f 2>/dev/null ) | sort -u | while read line; do 
	mkdir -p "${todaybackup}/$(dirname $line)"
	cp $line "${todaybackup}/${line}"
  done
  cd "$todaybackup"
  tar -C "$todaybackup" -zcf "${todaybackup}/back.tgz" *
  if [ $(echo $?) == 0 ]; then
    echo -n $(crypto_key) >$hiwifi_backup_key_file
    $(hwf_crypto_file $hiwifi_backup_key_file ${todaybackup}/back.tgz ${todaybackup}/back_crypto.tgz)
    $(hwf_crypto_file $hiwifi_backup_key_file ${todaybackup}/back_crypto.tgz ${todaybackup}/back_undo.tgz)
    # Test crypto file
    if [ $(md5sum "${todaybackup}/back.tgz" |awk '{printf $1}') == $(md5sum "${todaybackup}/back_undo.tgz" |awk '{printf $1}') ]; then
        mv ${todaybackup}/back_crypto.tgz /tmp/data/back_crypto.tgz
        rm -r ${todaybackup}/*
        rm $hiwifi_backup_key_file
        mv /tmp/data/back_crypto.tgz ${todaybackup}/back_crypto.tgz
        return 0
    fi
    return 5
  fi
  return 4
}

restore() {
  file=$(ls "${backup_root}"/*/back_crypto.tgz -t | head -n1)
  if [ -e "${file}" ]; then
    echo -n $(crypto_key) >$hiwifi_backup_key_file
    tmp_hwf_backup_file=/tmp/hwf_backup.tgz
    $(hwf_crypto_file $hiwifi_backup_key_file "$file" "$tmp_hwf_backup_file")
    tar -C "/" -zxf "$tmp_hwf_backup_file"
    RST=$(echo -n $?)
    rm "$tmp_hwf_backup_file"
    return $RST
  fi
  return 1
}

lastbackupfile() {
  file=$(ls "${backup_root}"/*/back_crypto.tgz -t | head -n1)
  [ -e "${file}" ] && echo -n "${file}"
}

crypto_key() {
  MACMODEL=$(lua -e '
   local tw = require "tw"
   print(tw.get_mac()..tw.get_model())
  ')
  echo -n "$MACMODEL"|md5sum|awk '{printf $1}'
}
