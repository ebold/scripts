#!/bin/bash

# Used in bel_projects/modules/a10vs/test/read_sensor.sh

test_conversion() {
    # hex to dec: value=ff; $((16#$value)); $((0x${value}))
    # dec to hex: value=42; printf "0x%x" $value
    for i in $(seq 0 15); do
        offset=$((i * 4))
        echo "hex->dec: " $i $offset $((16#$offset)) $((0x${offset})) # offset has hex value
        echo "dec->hex: " $i $offset $(printf "0x%x" $offset)         # offset has dec value
    done
}

