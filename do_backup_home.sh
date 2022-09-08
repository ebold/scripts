#!/bin/bash

# back up the '/home' directory incrementally to an external disk

# credit:
# https://snapshooter.com/learn/linux/incremental-tar
# https://help.ubuntu.com/community/BackupYourSystem/TAR

host=$(hostname)
src_path="/home/$USER"
ext_disk="/media/$USER/backup_t500"
dst_file="${host}_${USER}_home.tar.gz"
dst_path="$ext_disk/$dst_file"

tar_opt="-cpvzf"
tar_list="-g${host}_home_folders.snar"   # to list or extract: '-g /dev/null'

tar_excl="--exclude-from=exclude.txt"

# check the availability of the source directory
if [ ! -e "$src_path" ]; then
  echo "'$src_path' is not found. Exit!"
  exit 1
fi

# check the mountpoint of the external disk
if [ ! -e "$ext_disk" ]; then
  echo "'$ext_disk' is not mounted. Exit!"
  exit 1
fi

# create a tarball
tar "$tar_excl" "$tar_list" "$tar_opt" "$dst_path" "$src_path"
