FILESEXTRAPATHS_prepend := "${THISDIR}/udev-rules-rpi:"
SRC_URI += " file://bring-eth1-under-brlan0.sh \
	file://70-persistent-net.rules \
	"
RDEPENDS_${PN}_append = " bash"

do_install_append () {
    install -d ${D}${base_libdir}/rdk
    install -m 0777 ${WORKDIR}/bring-eth1-under-brlan0.sh ${D}${base_libdir}/rdk/
    install -m 0644 ${WORKDIR}/70-persistent-net.rules ${D}${sysconfdir}/udev/rules.d/
}

FILES_${PN} += " /lib/rdk/ "
