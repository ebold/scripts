#!/bin/bash

# find all kind of graphic images (.jpg, .gif etc) in the specified path
# command to get CD-ROM mount point: lsblk | grep sr

# credit to: https://stackoverflow.com/questions/16758105/list-all-graphic-image-files-with-find

path='.'
output='/tmp/graphics.txt'

if [ $# -eq 1 ]; then
  path="$1"
fi

# remove old list
if [ -f "$output" ]; then
  rm -rf "$output"
fi

# find graphic image files
find "$path" -name '*' -exec file {} \; | grep -o -P '^.+: \w+ image' | tee "$output"
