#!/bin/bash

# $1 - output filename

# user variables
video_filename="video"
record_area="1920x1080"

# user functions
check_tools() {
	tool_list=(xdpyinfo ffmpeg ffprobe)

	for tool in ${tool_list[@]}; do
		which $tool 2>&1
		if [ ! $? ]; then
			echo "Missing $tool. Exit!"
			exit 1
		fi
	done

	record_area="$(xdpyinfo | grep dimensions | sed -E 's/\s*dimensions:\s*([0-9]+x[0-9]+).*/\1/')"
}

record() {
	# $1 - output filename
	ffmpeg -video_size $record_area \
		-framerate 25 \
		-f x11grab \
		-i :0.0 \
		-f alsa -ac 2 -i hw:0 \
		~/Videos/${1}.mkv
}

get_resolution_info() {
	# $1 - video filename

	ffprobe -v error \
		-show_entries stream=width,height \
		-of default=noprint_wrappers=1 \
		~/Videos/${1}.mkv
}

# main stuff

check_tools

if [ $# -ne 0 ]; then
	video_filename="$1"
fi

record $video_filename
