#!/bin/bash

# back up the '/timeshift' directory to an external disk

# source: https://help.ubuntu.com/community/BackupYourSystem/TAR

today=$(date +%Y%m%d)
host=$(hostname)
ext_drive="/media/$USER/backup_t500"
dst_file="${host}_timeshift_${today}.tar.gz"
dst_path="$ext_drive/$dst_file"
src_path="/timeshift"

tar_opt="-cpvzf"

# check the availability of the source directory
if [ ! -e "$src_path" ]; then
  echo "'$src_path' is not found. Exit!"
  exit 1
fi

# check the mountpoint of the external disk
if [ -e "$ext_drive" ]; then
  echo "'$ext_drive' is not mounted. Exit!"
  exit 1
fi

# create a tarball
tar "$tar_opt" "$dst_path" "$src_path"
