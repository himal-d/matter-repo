SUMMARY = "OpenThread Border Router POSIX Daemon"
LICENSE = "BSD-3-Clause"
LIC_FILES_CHKSUM = "file://LICENSE;md5=87109e44b2fda96a8991f27684a7349c"

SRC_URI = "gitsm://github.com/openthread/ot-br-posix.git;branch=main;protocol=https \
           file://0001-disable-tests.patch \
	   file://ot-br-posix.service \
	   file://otbr-agent-wrapper.sh \
	   file://get-thread-dataset.sh \
	   file://otbr-diagnose.sh \
	   file://check-wpan0.sh \
	   file://99-ot-rcp.rules \
          "
SRCREV = "9537b07470dc1cd98ee6c5e3e4486c7ba2223966"

S = "${WORKDIR}/git"

DEPENDS = "boost dbus avahi ot-daemon"
RDEPENDS_${PN} += "bash ipset"

inherit cmake systemd

EXTRA_OECMAKE = "\
    -DOTBR_ENABLE_BORDER_ROUTING=ON \
    -DOTBR_ENABLE_DNSSD_DISCOVERY_PROXY=ON \
    -DOTBR_ENABLE_NCP=OFF \
    -DOTBR_ENABLE_CLI=OFF \
    -DOTBR_ENABLE_NAT64=OFF \
    -DOTBR_ENABLE_UMDNS=OFF \
    -DOTBR_ENABLE_BACKBONE_ROUTER=OFF \
    -DOTBR_ENABLE_VENDOR_EXTENSION=OFF \
    -DOTBR_ENABLE_TESTS=OFF \
"

SYSTEMD_SERVICE:${PN} = "ot-br-posix.service"
SYSTEMD_AUTO_ENABLE:${PN} = "enable"

FILES:${PN} += "${systemd_system_unitdir}/ot-br-posix.service ${sysconfdir}/default/otbr-agent /usr/local/bin/otbr-agent-wrapper.sh ${bindir}/get-thread-dataset ${bindir}/otbr-diagnose ${bindir}/check-wpan0 ${sysconfdir}/udev/rules.d/99-ot-rcp.rules"

do_install:append() {
    install -d ${D}/usr/local/bin
    install -m 0755 ${WORKDIR}/otbr-agent-wrapper.sh ${D}/usr/local/bin/otbr-agent-wrapper.sh

    install -d ${D}${systemd_system_unitdir}
    install -m 0644 ${THISDIR}/files/ot-br-posix.service ${D}${systemd_system_unitdir}/
    
    # Install Thread dataset helper script
    install -d -m 755 ${D}${bindir}
    install -m 755 ${WORKDIR}/get-thread-dataset.sh ${D}${bindir}/get-thread-dataset
    
    # Install diagnostic script
    install -m 755 ${WORKDIR}/otbr-diagnose.sh ${D}${bindir}/otbr-diagnose
    
    # Install wpan0 check script
    install -m 755 ${WORKDIR}/check-wpan0.sh ${D}${bindir}/check-wpan0
    
    # Install udev rules for external RCP (Option B2)
    install -d ${D}${sysconfdir}/udev/rules.d
    install -m 0644 ${WORKDIR}/99-ot-rcp.rules ${D}${sysconfdir}/udev/rules.d/
}
