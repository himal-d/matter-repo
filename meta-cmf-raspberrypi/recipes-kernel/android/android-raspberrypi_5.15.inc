FILESEXTRAPATHS_prepend := "${THISDIR}/linux-raspberrypi:"
 
SRC_URI = " \
     git://github.com/android-rpi/kernel_arpi/;branch=arpi-5.15;name=machine;protocol=https \
	 "

require android-raspberrypi.inc

SRC_URI_remove = "file://rpi-kernel-misc.cfg"
