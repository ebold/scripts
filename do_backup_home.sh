#!/bin/bash

# back up the '/home' directory incrementally to an external disk

# credit: https://snapshooter.com/learn/linux/incremental-tar

host=$(hostname)
src_path="/home"
ext_disk="/media/$USER/backup_t500"
dst_file="${host}_home_folders.tar.gz"
dst_path="$ext_disk/$dst_file"

tar_opt="-cpvzf"
tar_list="-g ${host}_home_folders.snar"   # restore with '-g /dev/null'
tar_excl="--exclude=/home/*/{.cache,.gvfs,.local/share/Trash}"

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
tar "$tar_list" "$tar_opt" "$dst_path" "$tar_excl" "$src_path"
