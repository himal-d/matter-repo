#! /bin/sh
wlan0_tx=`iwconfig wlan0 | grep "Tx-Power" | wc -l`
wlan1_tx=`iwconfig wlan1 | grep "Tx-Power" | wc -l`
wlan2_tx=`iwconfig wlan2 | grep "Tx-Power" | wc -l`

if [ $1 == 2 ]; then
	if [ $wlan0_tx == 1 ] && [ $wlan1_tx == 1 ]; then
		echo "wlan0 and wlan1 are Netgear interfaces"
		WLAN24G="wlan0"
		WLAN5G="wlan1"
	elif [ $wlan0_tx == 1 ] && [ $wlan2_tx == 1 ]; then
		echo "wlan0 and wlan2 are Netgear interfaces"
		WLAN24G="wlan0"
		WLAN5G="wlan2"
	elif [ $wlan1_tx == 1 ] && [ $wlan2_tx == 1 ]; then
		echo "wlan1 and wlan2 are Netgear interfaces"
		WLAN24G="wlan1"
		WLAN5G="wlan2"
	fi
else
	echo "we need 2 netgear dongle to validate opensync functionality"
fi

sleep 10
# Removing in-built wireless interface, it's not used in this scenario
rmmod brcmfmac 

WIFI24G_MAC=`cat "/sys/class/net/${WLAN24G}/address"`
WIFI5G_MAC=`cat "/sys/class/net/${WLAN5G}/address"`

echo "2.4GHz Radio MAC: ${WIFI24G_MAC}"
echo "5GHz   Radio MAC: ${WIFI5G_MAC}"

if [ ! -f /nvram/hostapd0.conf ]
then
	cp /usr/ccsp/wifi/hostapd-2G.conf /nvram/hostapd0.conf
	#Set bssid for wifi0
        NEW_MAC=$(echo 0x${WIFI24G_MAC}| awk -F: '{printf "%02x:%s:%s:%s:%s:%s", strtonum($1)+2, $2, $3, $4 ,$5, $6}')
	sed -i "/^bssid=/c\bssid=$NEW_MAC" /nvram/hostapd0.conf
        echo "wpa_psk_file=/tmp/hostapd0.psk" >> /nvram/hostapd0.conf
fi

if [ ! -f /nvram/hostapd1.conf ]
then
	cp /usr/ccsp/wifi/hostapd-5G.conf /nvram/hostapd1.conf
	#Set bssid for wifi1
        NEW_MAC=$(echo 0x${WIFI5G_MAC}| awk -F: '{printf "%02x:%s:%s:%s:%s:%s", strtonum($1)+2, $2, $3, $4 ,$5, $6}')
        sed -i "/^bssid=/c\bssid=$NEW_MAC" /nvram/hostapd1.conf
        echo "wpa_psk_file=/tmp/hostapd1.psk" >> /nvram/hostapd1.conf
fi

if [ ! -f /nvram/hostapd2.conf ]
then
	cp /usr/ccsp/wifi/hostapd-bhaul2G.conf /nvram/hostapd2.conf
	#Set bssid for wifi2
        NEW_MAC=$(echo 0x${WIFI24G_MAC}| awk -F: '{printf "%02x:%s:%s:%s:%s:%s", strtonum($1)+4, $2, $3, $4 ,$5, $6}')
        sed -i "/^bssid=/c\bssid=$NEW_MAC" /nvram/hostapd2.conf
        echo "wpa_psk_file=/tmp/hostapd2.psk" >> /nvram/hostapd2.conf
fi

if [ ! -f /nvram/hostapd3.conf ]
then
	cp /usr/ccsp/wifi/hostapd-bhaul5G.conf /nvram/hostapd3.conf
	#Set bssid for wifi3
        NEW_MAC=$(echo 0x${WIFI5G_MAC}| awk -F: '{printf "%02x:%s:%s:%s:%s:%s", strtonum($1)+4, $2, $3, $4 ,$5, $6}')
        sed -i "/^bssid=/c\bssid=$NEW_MAC" /nvram/hostapd3.conf
        echo "wpa_psk_file=/tmp/hostapd3.psk" >> /nvram/hostapd3.conf
fi

#Setting up VAP status file
echo -e "wifi0=1\nwifi1=1\nwifi2=0\nwifi3=0" >/tmp/vap-status

#Creating virtual interfaces wifi0 and wifi1 for Home APs
iw dev ${WLAN24G} interface add wifi0 type __ap
iw dev ${WLAN5G} interface add wifi1 type __ap

#2.4GHz Virtual Access Points for backhaul connection
iw dev ${WLAN24G} interface add wifi2 type __ap
ip addr add 169.254.0.1/25 dev wifi2
ifconfig wifi2 mtu 1600

#5GHz Virtual Access Points for backhaul connection
iw dev ${WLAN5G} interface add wifi3 type __ap
ip addr add 169.254.1.1/25 dev wifi3
ifconfig wifi3 mtu 1600

#Creating virtual interfaces wifi4 and wifi5 for Guest APs
#iw dev ${WLAN24G} interface add wifi4 type __ap
#iw dev ${WLAN5G} interface add wifi5 type __ap

#update mac from hostapd config
for (( i = 0; i < 4; i++ )); do
        ifconfig wifi$i hw ether $(cat /nvram/hostapd${i}.conf |grep bssid | cut -d = -f 2)
done

#Create empty acl list for hostapd
touch /tmp/hostapd-acl0
touch /tmp/hostapd-acl1
touch /tmp/hostapd-acl2
touch /tmp/hostapd-acl3

#create empty psk files
touch /tmp/hostapd0.psk
touch /tmp/hostapd1.psk
touch /tmp/hostapd2.psk
touch /tmp/hostapd3.psk


#Create wps pin request log file
touch /var/run/hostapd_wps_pin_requests.log

#To start hostapd in global mode
/usr/sbin/hostapd -g /var/run/hostapd/global -B -P /var/run/hostapd-global.pid

PHY_2G=`iw $WLAN24G info | grep phy | cut -d ' ' -f2`
PHY_5G=`iw $WLAN5G info | grep phy | cut -d ' ' -f2`

hostapd_cli -i global raw ADD bss_config=$PHY_2G:/nvram/hostapd0.conf
hostapd_cli -i global raw ADD bss_config=$PHY_5G:/nvram/hostapd1.conf


#knowning the current status of home AP's                                                                                       
if [ ! -f "/var/Get5gssidEnable.txt" ]; then                                                                                      
        echo "1" > /var/Get5gssidEnable.txt                                                                                                   
fi                                                                                                                                            
if [ ! -f "/var/Get2gssidEnable.txt" ]; then                                                                                                  
        echo "1" > /var/Get2gssidEnable.txt                                                                                       
fi                         
if [ ! -f "/var/Get2gRadioEnable.txt" ]; then                                                                                                 
        echo "1" > /var/Get2gRadioEnable.txt                                                                                      
fi                                                                                                                             
if [ ! -f "/var/Get5gRadioEnable.txt" ]; then                                                                                                 
        echo "1" > /var/Get5gRadioEnable.txt                                                                                    
fi

exit 0
