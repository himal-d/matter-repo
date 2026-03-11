FILESEXTRAPATHS_prepend := "${THISDIR}/files:"

SRC_URI_append = " file://Rpi_rdkwifilibhostap_changes.patch "

CFLAGS_append = " -D_PLATFORM_RASPBERRYPI_"
