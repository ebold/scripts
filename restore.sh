#!/bin/bash
years=$(seq 2008 2008)

for year in $years; do
    prv_year=$((year - 1))
    file_list=/tmp/$year
    dst_folder=../restored/$year
    mkdir -p $dst_folder
    echo $year
    echo $prv_year
    echo "'${prv_year}-12-31'"
    find . -type f -newermt "${prv_year}-12-31" -not -newermt "${year}-12-31" > ${file_list}.txt
#    if [ -e ${file_list}.txt ]; then
#        items=$(cat ${file_list}.txt | wc -l )
#        if [ $items -ne 0 ]; then
#            rsync --remove-sent-files -avR --files-from=$file_list ./ ${dst_folder}/
#            find . -type f -newermt "'${prv_year}-12-31'" -not -newermt "'${year}-12-31'" > ${file_list}_post.txt
#        fi
#    fi
done
