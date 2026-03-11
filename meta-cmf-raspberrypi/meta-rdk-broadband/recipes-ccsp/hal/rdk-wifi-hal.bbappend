FILESEXTRAPATHS_prepend := "${THISDIR}/files:"

CFLAGS_append = " -D_PLATFORM_RASPBERRYPI_  -DRASPBERRY_PI_PORT "
CFLAGS_append_kirkstone = " -fcommon"
EXTRA_OECONF_append = " ${@bb.utils.contains('DISTRO_FEATURES', 'OneWifi', ' ONE_WIFIBUILD=true ', '', d)}"
EXTRA_OECONF_append = " ${@bb.utils.contains('DISTRO_FEATURES', 'OneWifi', ' RASPBERRY_PI_PORT=true ', '', d)}"
