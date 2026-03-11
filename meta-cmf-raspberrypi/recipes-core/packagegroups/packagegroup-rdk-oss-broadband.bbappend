
# linux-firmware-ralink provides /lib/firmware/rt*.bin (which includes
# /lib/firmware/rt2870.bin, which is required by hostapd on RPi).

RDEPENDS_packagegroup-rdk-oss-broadband_append = " \
    iw \
    wireless-tools \
    ${@bb.utils.contains('DISTRO_FEATURES', 'OneWifi', ' ', ' hostapd', d)} \
    linux-firmware-ralink \
    crda \
    ebtables \
    rtl8812au \
    rtl8192eu \
    rtl88x2bu \
    linux-firmware \
    ethtool \
    ntpstat \
    chip-tool \
    chip-all-clusters-app \
    chip-bridge-app \
    chip-energy-management-app \
    chip-lighting-app \
    chip-ota-provider-app \
    chip-ota-requestor-app \
    chip-tool-web \
    matter-controller-daemon \
    imx-chip-bridge-app \
    nxp-thermostat-app \
    thermostat-app \
    ot-daemon \
    ot-br-posix \
    dbus \
    avahi-daemon \
    avahi-utils \
    bluez5 \
    bluez5-bluetoothd \
    ${@bb.utils.contains('DISTRO_FEATURES', 'dac', 'speedtest-cli', '', d)} \
"

RDEPENDS_packagegroup-rdk-oss-broadband_append = " mt76"
RDEPENDS_packagegroup-rdk-oss-broadband_remove_aarch64 = "alljoyn"
