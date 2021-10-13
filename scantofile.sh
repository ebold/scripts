#! /bin/bash
# scantofile
#

# location: /opt/brother/scanner/brscan-skey/script/scantofile.sh

# disable script option (+o) that prevents overwritting of files by redirection (noclobber)
set +o noclobber

# custom edition for PDF
resolution=300
range="-l 0 -t 0 -x 210.00 -y 295.00"
opt_dev="--device-name $1"
opt_res="--resolution $resolution"
opt_pnm="-imagewidth 8.26 -nocenter"
opt_gs="-q -dNOPAUSE -sDEVICE=pdfwrite -sOutputFile=-"
output_file=~/brscan/brscan_"$(date +%Y%m%d-%H%M%S)"

scantoimg() {
  #echo  "$SCANIMAGE $OPT"
  $SCANIMAGE $OPT

  if [ ! -e "$OUTPUT" ];then
    sleep 1
    $SCANIMAGE $OPT
  fi

  echo "$OUTPUT" is created.
}

scantopdf() {
  touch $output_file
  scanimage $opt_dev $opt_res $range \
  | pnmtops $opt_pnm | gs $opt_gs - > "$output_file".pdf
  rm $output_file

  if [ -e "$output_file".pdf ]; then
    echo "$output_file".pdf is created.
  fi
}

# main
mkdir -p ~/brscan
sleep 0.2

if [ -e ~/.brscan-skey/scantofile.config ];then
   source ~/.brscan-skey/scantofile.config
elif [ -e /etc//opt/brother/scanner/brscan-skey/scantofile.config ];then
   source /etc//opt/brother/scanner/brscan-skey/scantofile.config
fi



SCANIMAGE="/opt/brother/scanner/brscan-skey/skey-scanimage"
OUTPUT=~/brscan/brscan_"$(date +%Y-%m-%d-%H-%M-%S)".tif
OPT_OTHER=""



if [ "$resolution" != '' ];then
   OPT_RESO="--resolution $resolution"
else
   OPT_RESO="--resolution 100"
fi

if [ "$source" != '' ];then
   OPT_SRC="--source $source"
else
   OPT_SRC="--source FB"
fi

if [ "$size" != '' ];then
   OPT_SIZE="--size $size"
else
   OPT_SIZE="--size A4"
fi

if [ "$duplex" = 'ON' ];then
   OPT_DUP="--duplex"
   OPT_SRC="--source ADF_C"
else
   OPT_DUP=""
fi
OPT_FILE="--outputfile  $OUTPUT"

OPT_DEV="--device-name $1"

OPT="$OPT_DEV $OPT_RESO $OPT_SRC $OPT_SIZE $OPT_DUP $OPT_OTHER $OPT_FILE"

if [ "$(echo "$1" | grep net)" != '' ];then
    sleep 1
fi

# scan to pdf
scantopdf
