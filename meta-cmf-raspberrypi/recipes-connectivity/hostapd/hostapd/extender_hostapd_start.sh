#!/bin/sh
##########################################################################
# If not stated otherwise in this file or this component's LICENSE file the
# following copyright and licenses apply:
#
# Copyright 2023 RDK Management
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
##########################################################################

#waiting for the driver initialization
sleep 5

mkdir -p /nvram
cp /usr/ccsp/wifi/extender_hostapd0.conf /nvram/hostapd0.conf
cp /usr/ccsp/wifi/extender_hostapd1.conf /nvram/hostapd1.conf
cp /usr/ccsp/wifi/extender_hostapd2.conf /nvram/hostapd2.conf
cp /usr/ccsp/wifi/extender_hostapd3.conf /nvram/hostapd3.conf
cp /usr/opensync/lm_log_state.json /nvram/

wifi=`ifconfig -a | grep wlan -c`
if [ $wifi -lt 3 ];
then
#modprobe mac80211_hwsim radios=1
wifi=$((wifi+1))
fi
echo "No. of wireless radios: $wifi"

WIFI0_MAC=`cat /sys/class/net/wlan0/address`
WIFI1_MAC=`cat /sys/class/net/wlan1/address`
echo "2.4GHz Radio MAC: $WIFI0_MAC"
echo "5GHz   Radio MAC: $WIFI1_MAC"

#Set bssid for wifi0
sed -i "/^interface=/c\interface=wifi0" /nvram/hostapd0.conf
NEW_MAC=$(echo 0x$WIFI0_MAC| awk -F: '{printf "%02x:%s:%s:%s:%s:%s", strtonum($1)+6, $2, $3, $4 ,$5, $6}')
sed -i "/^bssid=/c\bssid=$NEW_MAC" /nvram/hostapd0.conf

#Set bssid for wifi1
sed -i "/^interface=/c\interface=wifi1" /nvram/hostapd1.conf
NEW_MAC=$(echo 0x$WIFI1_MAC| awk -F: '{printf "%02x:%s:%s:%s:%s:%s", strtonum($1)+6, $2, $3, $4 ,$5, $6}')
sed -i "/^bssid=/c\bssid=$NEW_MAC" /nvram/hostapd1.conf


#Set bssid for wifi2
sed -i "/^interface=/c\interface=wifi2" /nvram/hostapd2.conf
NEW_MAC=$(echo 0x$WIFI0_MAC| awk -F: '{printf "%02x:%s:%s:%s:%s:%s", strtonum($1)+8, $2, $3, $4 ,$5, $6}')
sed -i "/^bssid=/c\bssid=$NEW_MAC" /nvram/hostapd2.conf

#Set bssid for wifi3
sed -i "/^interface=/c\interface=wifi3" /nvram/hostapd3.conf
NEW_MAC=$(echo 0x$WIFI1_MAC| awk -F: '{printf "%02x:%s:%s:%s:%s:%s", strtonum($1)+8, $2, $3, $4 ,$5, $6}')
sed -i "/^bssid=/c\bssid=$NEW_MAC" /nvram/hostapd3.conf

/usr/sbin/hostapd -g /var/run/hostapd/global -B -P /var/run/hostapd-global.pid

#Workaround fix: following script is invoked as interim arrangement till hardware incapability is addressed
/usr/hostapd/make_homeap_primary.sh &
