#!/bin/sh

# This script turns off all on-board LEDs

# Installation in Linux raspbx 3.14.37-ti-r57 (as <root>@<raspbx>)
# scp leds.sh /opt/scripts/tools/
# cd /etc/rcS.d/
# ln -s /opt/scripts/tools/leds.sh S99leds

# Path to LED device
path_to_led="/sys/class/leds/beaglebone:green:usr"
def_trig_mode="none"
def_bright_mode="off"

# Check LED index
is_led_valid() {
  # $1 - LED index (valid range 0..3)
  # return zero value if index is valid, otherwise non-zero value
  if [ "$1" = "" ] || [ $1 -gt 3 ] || [ $1 -lt 0 ]; then
    return 1
  fi
  return 0
}

# Trigger mode control
led_trigger_ctl() {
  is_led_valid $1
  if [ $? -ne 0 ]; then
    exit
  fi
  if [ "$2" = "none" ] || [ "$2" = "heartbeat" ] || [ "$2" = "mmc0" ] || [ "$2" = "mmc1" ]; then
    echo "$2" > "${path_to_led}$1/trigger"
  fi
}

# Brightness mode control
led_brightness_ctl() {
  is_led_valid $1
  if [ $? -ne 0 ]; then
    exit
  fi
  if [ "$2" = "on" ] || [ "$2" = "off" ]; then
    value=1
    if [ "$2" = "off" ]; then
      value=0
    fi
    echo "$value" > "${path_to_led}$1/brightness"
  fi
}

# Turn off all on-board LEDs
for led in 0 1 2 3; do
  led_trigger_ctl $led $def_trig_mode
  led_brightness_ctl $led $def_bright_mode
done
