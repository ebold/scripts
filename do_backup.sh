#!/bin/bash



EXCLUDE_FILEPATH=$HOME/backup_exclude_list.txt
REMOTE_USER=my_accout
REMOTE_HOST=my_host.gsi.de
DESKTOP=my_desktop
DEST_PATH=/backups/$HOME

# rsync mandatory options:

# -a: archive mode, includes following options
#   -r: recursive into directories
#   -l: copy symlinks as symlinks
#   -p: preserve permissions
#   -t: preserve modification time
#   -g: preserve group
#   -o: preserve owner (root only)
#   -D: preserve device files, special files (root only)

# --numeric-ids:   don't map uid/gid values by user/group name (Ubuntu UIDs starts at 1000, other distros at 500)
# --delete-before: receiver deletes before transfer (default)
# --exclude-from:  read exclude patterns from a given file
# --progress:      show progress during transfer

# rsync useful options:
# -n: dry-run
# -u: skip files that are newer on the receiver
# -z: compress data during transfer
# -v: verbose mode

# copy actual work from laptop to desktop
rsync --numeric-ids -auv --progress $HOME/ ${REMOTE_USER}@${DESKTOP}:$DEST_PATH/

# do backup of home directory excluding some directories listed in "backup_exclude_list.txt"
rsync --numeric-ids -avz --delete-before --progress --exclude-from=$EXCLUDE_FILEPATH $HOME/ ${REMOTE_USER}@${REMOTE_HOST}:$DEST_PATH/
