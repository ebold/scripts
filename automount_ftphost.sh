#!/bin/bash
#
# automount remote ftp folder as local folder
#
# An external USB drive plugged to Fritzbox can be used as NAS storage.
# This storage is now accessible like a remote ftp server: remote.host.ip.addr:/folder/in/USB/drive
# In order to simplify the user access to the NAS storage, one can mount
# a folder in remote host as a local folder: using curlftpfs and fuse.
# This script mounts NAS storage as local folder.
# - URL to NAS storage:        192.168.1.1:/Generic-FlashDisk-00
# - users with access rights:  kids

# https://askubuntu.com/questions/320746/how-to-mount-ftp-resources-with-fstab-when-connection-is-available

# install curlftpfs and fuse: sudo apt-get install curlftpfs fuse
# add this script to /etc/profile.d/
# change permission: sudo chmod +x /etc/profile.d/automount_ftphost.sh
# add fuse to usergroup: sudo /usr/sbin/groupadd fuse

MOUNT_POINT=~/f
HOST_IP=192.168.1.1
FTP_HOST=$HOST_IP:/Generic-FlashDisk-00/
FUSE_OPTIONS=no_verify_peer,utf8,allow_other,nonempty

# check local folder (create if it's missing)
if [ ! -d $MOUNT_POINT ]; then
	mkdir -p $MOUNT_POINT
fi

# check if local host is reachable
ping=$(ping -q -c 5 $HOST_IP)

if [ $? == 0 ]; then
	# mount folder only if it's not mounted
	mountpoint $MOUNT_POINT > /dev/null

	if [ $? != 0 ]; then
		curlftpfs -o $FUSE_OPTIONS kids@$FTP_HOST $MOUNT_POINT
	fi
else
	mountpoint $MOUNT_POINT > /dev/null
	# unmount folder if local host is not reachable
	if [ $? == 0 ]; then
		fusermount -u $MOUNT_POINT
	fi
fi
