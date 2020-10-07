#!/bin/bash
echo "Content-type: text/html"
echo ""
echo "<html><head><title>Reboot from web"
echo "</title></head><body>"

echo "<h1>Rebooting in a few seconds ...</h1>"
echo "Now is $(date)"
echo ""

sudo /usr/bin/systemctl reboot

echo "</body></html>"
