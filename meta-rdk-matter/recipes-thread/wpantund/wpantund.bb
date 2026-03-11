SUMMARY = "Userspace daemon for managing OpenThread interfaces"
DESCRIPTION = "wpantund is a user-space NCP (Network Co-Processor) driver/daemon that provides a native IPv6 network interface to a Thread network."
LICENSE = "Apache-2.0 & MIT & BSL-1.0 & BSD-3-Clause"
LIC_FILES_CHKSUM = "file://LICENSE;md5=e7820bc7f7d1638a6b54fc2e8d7fb103"

SRC_URI = "gitsm://github.com/openthread/wpantund.git;protocol=https;branch=master \
           file://wpantund.service \
	   file://wpantund.conf \
          "

SRCREV = "8b5ce64c2f5bbf106cabfd015bcb3bdb2e0248d3"

PV = "0.07.01+git"

S = "${WORKDIR}/git"

DEPENDS = "autoconf-archive dbus libdaemon avahi readline boost"

inherit autotools pkgconfig systemd perlnative

EXTRA_OECONF = "--enable-debug"

SYSTEMD_SERVICE:${PN} = "wpantund.service"
SYSTEMD_AUTO_ENABLE:${PN} = "disable"

do_install:append() {
    install -d ${D}${sysconfdir}/wpantund
    install -m 0644 ${THISDIR}/files/wpantund.conf ${D}${sysconfdir}/wpantund/wpantund.conf

    install -d ${D}${systemd_system_unitdir}
    install -m 0644 ${THISDIR}/files/wpantund.service ${D}${systemd_system_unitdir}/
}

FILES:${PN} += "${systemd_system_unitdir}/wpantund.service ${sysconfdir}/wpantund"

