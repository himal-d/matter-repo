# meta-rdk-matter/recipes-connectivity/bluez5/bluez5_5.66.bbappend

FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

# Dependencies required for feature detection
DEPENDS += "json-c ell readline"
RDEPENDS:${PN} += "json-c bash"

inherit autotools pkgconfig systemd

# Enable desired BlueZ features
PACKAGECONFIG:append = " client mesh obex systemd udev tools experimental"

# Use only valid configure options — no legacy or Meson args
EXTRA_OECONF += " \
    --enable-datafiles \
    --enable-library \
    --enable-test \
    --enable-client \
    --enable-mesh \
    --enable-obex \
    --enable-tools \
    --enable-systemd \
    --enable-udev \
    --enable-experimental \
    --enable-shared \
    --libdir=${libdir} \
"

# Include your local configuration and service files
SRC_URI += " \
    file://default-bluetooth.conf \
    file://enable-hci.sh \
    file://bluetooth.service \
    file://configure-ble-params.sh \
    file://ble-params.service \
    file://99-ble-external.rules \
    file://select-ble-adapter.sh \
"

# Systemd integration
SYSTEMD_SERVICE:${PN} = "bluetooth.service ble-params.service"
SYSTEMD_AUTO_ENABLE = "enable"

do_install:append() {
    install -Dm644 ${WORKDIR}/default-bluetooth.conf ${D}${sysconfdir}/bluetooth/main.conf
    install -Dm755 ${WORKDIR}/enable-hci.sh ${D}${sbindir}/enable-hci.sh
    install -Dm644 ${WORKDIR}/bluetooth.service ${D}${systemd_system_unitdir}/bluetooth.service
    install -Dm755 ${WORKDIR}/configure-ble-params.sh ${D}${bindir}/configure-ble-params
    install -Dm644 ${WORKDIR}/ble-params.service ${D}${systemd_system_unitdir}/ble-params.service
    
    # Install external BLE adapter support (Option B3)
    install -d ${D}${sysconfdir}/udev/rules.d
    install -Dm644 ${WORKDIR}/99-ble-external.rules ${D}${sysconfdir}/udev/rules.d/
    install -Dm755 ${WORKDIR}/select-ble-adapter.sh ${D}${bindir}/select-ble-adapter
}

# Include plugin paths — plugins get built into ${libdir}/bluetooth/
FILES:${PN} += " \
    ${sysconfdir}/bluetooth/main.conf \
    ${sbindir}/enable-hci.sh \
    ${systemd_system_unitdir}/bluetooth.service \
    ${systemd_system_unitdir}/ble-params.service \
    ${bindir}/configure-ble-params \
    ${sysconfdir}/udev/rules.d/99-ble-external.rules \
    ${bindir}/select-ble-adapter \
    ${libdir}/bluetooth/ \
"

