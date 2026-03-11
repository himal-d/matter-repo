#!/bin/sh
##########################################################################
# If not stated otherwise in this file or this component's Licenses.txt
# file the following copyright and licenses apply:
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

WIFI_DIR="/opt/secure/wifi"
WPA_SUP_CONF="${WIFI_DIR}/wpa_supplicant.conf"

if [ ! -d "${WIFI_DIR}"  ]; then
	echo "Creating '${WIFI_DIR}'..."
	mkdir -p ${WIFI_DIR}
fi

if [ ! -f "${WPA_SUP_CONF}"  ]; then
	echo "'${WPA_SUP_CONF}' not found; creating with deafult values..."
	echo "ctrl_interface=/var/run/wpa_supplicant" >> ${WPA_SUP_CONF}
	echo "ctrl_interface_group=0" >> ${WPA_SUP_CONF}
	echo "update_config=1" >> ${WPA_SUP_CONF}
	sync
fi
