#!/bin/sh
# This script brings up the HCI controller if it exists

HCIDEV=$(hciconfig | grep -o '^hci[0-9]\+')
if [ -n "$HCIDEV" ]; then
    for dev in $HCIDEV; do
        hciconfig $dev up
    done
fi

