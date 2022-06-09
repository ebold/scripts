#!/bin/bash

# $1 - repository absolute path

unset repo_path duration
video_file="movie.mp4"

if [ -n "$1" ]; then
    repo_path="$1"
    video_file="${1%/}/$video_file"
fi

gource_opt="-s .03 \
    -1280x720 \
    --auto-skip-seconds .1 \
    --multi-sampling \
    --stop-at-end \
    --key \
    --highlight-users \
    --date-format \"%d.%m.%Y\" \
    --hide mouse,filenames \
    --file-idle-time 0 \
    --max-files 0  \
    --background-colour 000000 \
    --font-size 25 \
    --output-ppm-stream - \
    --output-framerate 30"

ffmpeg_opt="-y -r 30 -f image2pipe -vcodec ppm -i - -b 65536K"

ffprobe_opt="-v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1"

# Create visualization
gource $gource_opt $repo_path | ffmpeg $ffmpeg_opt $video_file

# Get the duration of the output video
duration=$(ffprobe $ffprobe_opt $video_file)

# Provide additional information to play video
echo
echo "Duration of $video_file (seconds): $duration"
echo "To play the video, invoke: ffplay -autoexit -t '$duration' $video_file"
echo

# Link:
# https://gist.github.com/Gnzlt/a2bd6551f0044a673e455b269646d487
