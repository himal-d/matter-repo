#!/bin/sh

TOT_PHY_COUNT=`iw dev | grep phy | wc -l`
n_d_cc=0
for (( i = 0; i < $TOT_PHY_COUNT; i++ ));
do
	VALID_INTERFACE_COMBINATIONS_COUNT=`iw phy$i info | grep " managed, AP, mesh point " | cut -d '=' -f3 | cut -d ' ' -f2 | sed 's/,//g'`
	echo "valid phy$i : $VALID_INTERFACE_COMBINATIONS_COUNT"

if [ $VALID_INTERFACE_COMBINATIONS_COUNT == 3 ]; then
    NETGEAR_DONGLE=1
#Netgear dongle connected count
    n_d_cc=$((n_d_cc+1))  

else
    TP_LINK_OR_INBUILT=1
fi
done

if [ $NETGEAR_DONGLE == 1 ]; then
    echo "Netgear Dongle Scenario $n_d_cc"
    sh /usr/hostapd/hostapd_opensync.sh $n_d_cc
else
    echo "TP-link/In-built scenario"
    sh /usr/hostapd/hostapd_start.sh	
fi
