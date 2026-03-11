#!/bin/sh

##################### 5.2GHz support through 88x2bu driver for kirkstone #####################
wifi_driver_count=`lsmod | grep cfg80211 | grep -v rfkill  | xargs | cut -d ' ' -f3`
wifi_driver=`lsmod | grep cfg80211 | grep -v rfkill | xargs | cut -d ' ' -f4 | cut -d ',' -f3`
wifi_driver1=`lsmod | grep cfg80211 | grep -v rfkill | xargs | cut -d ' ' -f4 | cut -d ',' -f1`
if [ $wifi_driver_count == 3 ] && { [ "$wifi_driver" == "88x2bu" ] || [ "$wifi_driver1" == "88x2bu" ]; } then
rmmod 8812au
fi

##################### wlan0 for private 2.4GHz wifi ##################
echo "reloading wifi drivers"
wifi_driver_count=`lsmod | grep cfg80211 | grep -v rfkill  | xargs | cut -d ' ' -f3`
wifi_driver_name=`lsmod | grep cfg80211 | grep -v rfkill | xargs | cut -d ' ' -f4`
echo "loaded wifi drivers are $wifi_driver_name"

if [ $wifi_driver_count == 1 ] ; then
    echo "Nothing to do .."
    exit 0
fi
if [ $wifi_driver_count == 2 ]; then
wifi_driver=`lsmod | grep cfg80211 | grep -v rfkill | xargs | cut -d ' ' -f4 | cut -d ',' -f1`
if [ $wifi_driver != "brcmfmac" ] ; then
    wifi_driver_5g=$wifi_driver
else
    wifi_driver_5g=`lsmod | grep cfg80211 | grep -v rfkill | xargs | cut -d ' ' -f4 | cut -d ',' -f2`
fi
elif [ $wifi_driver_count == 3 ] || [ $wifi_driver_count == 5 ] ||  [ $wifi_driver_count == 6 ] ; then
wifi_driver_1=`lsmod | grep cfg80211 | grep -v rfkill | xargs | cut -d ' ' -f4 | cut -d ',' -f1`
wifi_driver_2=`lsmod | grep cfg80211 | grep -v rfkill | xargs | cut -d ' ' -f4 | cut -d ',' -f2`
wifi_driver_3=`lsmod | grep cfg80211 | grep -v rfkill | xargs | cut -d ' ' -f4 | cut -d ',' -f3`
if [ $wifi_driver_1 = "rt2x00lib" ] || [ $wifi_driver_2 = "rt2x00lib" ] || [ $wifi_driver_3 = "rt2x00lib" ] ; then
     wifi_driver_5g=rt2800usb
fi
if [ $wifi_driver_1 = "mt76" ] || [ $wifi_driver_2 = "mt76" ] || [ $wifi_driver_3 = "mt76" ] ; then
     wifi_driver_5g=mt76x2u
fi
fi

echo "removing wifi modules"
if [ $wifi_driver_5g = "rt2800usb" ] ; then
     rmmod  rt2800usb rt2800lib rt2x00usb rt2x00lib mac80211
elif [ $wifi_driver_5g = "mt76x2u" ] ; then
     rmmod  mt76x2u mt76x2_common mt76x02_usb mt76x02_lib mt76_usb mt76 mac80211
else
     rmmod $wifi_driver_5g
fi
rmmod brcmfmac cfg80211


echo "loading wifi modules"
if [ $wifi_driver_5g = "rt2800usb" ] ; then
    echo "tp-link N900 series"
    modprobe rt2800usb
    sleep 1
    modprobe brcmfmac
    sleep 2
else
    modprobe brcmfmac
    sleep 1
    modprobe $wifi_driver_5g
fi
