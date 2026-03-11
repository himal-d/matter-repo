#!/bin/bash
/sbin/ifconfig eth1 up
/usr/sbin/brctl addif brlan0 eth1
