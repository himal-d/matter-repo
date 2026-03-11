#!/bin/sh

#Below lines are removed once OVS is integrated in rpi
BridgeMode_status=`syscfg get bridge_mode`
if [ $BridgeMode_status == 2 ]; then
sleep 5
brctl delif brlan0 wlan0
brctl delif brlan0 wlan1
fi
exit 0
