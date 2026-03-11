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

#Allowing backhaul connection to be established with GW
sleep 180

echo "After initial sleep" >> /tmp/make-home-ap-private.log
while true
do
hostapd_cli -i wifi0 status
if [ $? == 0 ];
then
  echo "Both VAPs are up." >> /tmp/make-home-ap-private.log
  hostapd_cli -i global raw REMOVE wifi2
  hostapd_cli -i global raw ADD bss_config=phy0:/nvram/hostapd0.conf
  hostapd_cli -i global raw ADD bss_config=phy0:/nvram/hostapd2.conf
  break;
fi
echo "Still both VAPs are not up." >> /tmp/make-home-ap-private.log
sleep 30
done
