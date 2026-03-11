PN = "chip-all-clusters-app"
SUMMARY = "Matter Chip All Clusters App CLI"
LICENSE = "Apache-2.0"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/Apache-2.0;md5=89aea4e17d99a7cacdbeed46a0096b10"

SRCBRANCH = "v1.4-branch-nxp_imx_2025_q1"
IMX_MATTER_SRC ?= "gitsm://github.com/NXP/matter.git;protocol=https"
SRC_URI = "${IMX_MATTER_SRC};branch=${SRCBRANCH}"
SRC_URI += "file://chip-all-clusters-app.service"
SRC_URI += "file://matter-controller.service"
SRC_URI += "file://matter-controller-ctl.sh"
SRC_URI += "file://verify-matter-controller.sh"
SRC_URI += "file://matter-controller.conf"

FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

MATTER_PY_PATH ?= "${STAGING_BINDIR_NATIVE}/python3-native/python3"

# Include SDK patches (BLE fixes, QR code commissioning, etc.)
require recipes-matter/matter-common/matter-common-sdk-patches.inc

inherit systemd

SYSTEMD_SERVICE:${PN} = "chip-all-clusters-app.service matter-controller.service"
SYSTEMD_AUTO_ENABLE:${PN} = "disable"

APP_PATH = "examples/all-clusters-app/linux"
APP_BINARY = "chip-all-clusters-app"

PATCHTOOL = "git"
SRCREV = "${AUTOREV}"

TARGET_CC_ARCH += "${LDFLAGS}"

DEPENDS += " gn-native ninja-native openssl avahi dbus-glib-native pkgconfig-native boost python3-native python3-pip-native python3-packaging-native python3-click "
RDEPENDS_${PN} += " libavahi-client boost boost-staticdev bash "
FILES:${PN} += "usr/share"

INSANE_SKIP:${PN} += "dev-so debug-deps strip"

MATTER_ADVANCED = "${@bb.utils.contains('MACHINE_FEATURES', 'matteradvanced', 'true', 'false', d)}"

def get_target_cpu(d):
    for arg in (d.getVar('TUNE_FEATURES') or '').split():
        if arg == "cortexa7":
            return 'arm'
        if arg == "armv8a":
            return 'arm64'
    return 'arm64'

def get_arm_arch(d):
    for arg in (d.getVar('TUNE_FEATURES') or '').split():
        if arg == "cortexa7":
            return 'armv7ve'
        if arg == "armv8a":
            return 'armv8-a'
    return 'armv8-a'

def get_arm_cpu(d):
    for arg in (d.getVar('TUNE_FEATURES') or '').split():
        if arg == "cortexa7":
            return 'cortex-a7'
        if arg == "armv8a":
            return 'cortex-a72'
    return 'cortex-a72'

TARGET_CPU = "${@get_target_cpu(d)}"
TARGET_ARM_ARCH = "${@get_arm_arch(d)}"
TARGET_ARM_CPU = "${@get_arm_cpu(d)}"

USE_ELE = "${@bb.utils.contains('MACHINE', 'raspberrypi4', 1, 0, d)}"

S = "${WORKDIR}/git"

common_configure() {
    PKG_CONFIG_SYSROOT_DIR=${PKG_CONFIG_SYSROOT_DIR} \
    PKG_CONFIG_LIBDIR=${PKG_CONFIG_PATH} \
    gn gen out/aarch64 --script-executable="${MATTER_PY_PATH}" --args='treat_warnings_as_errors=false target_os="linux" target_cpu="${TARGET_CPU}" arm_arch="${TARGET_ARM_ARCH}" arm_cpu="${TARGET_ARM_CPU}" build_without_pw=true chip_with_imx_ele=${USE_ELE} enable_exceptions=true chip_code_pre_generated_directory="${S}/zzz_pregencodes"
        import("//build_overrides/build.gni")
        target_cflags=[
                        "-DCHIP_DEVICE_CONFIG_WIFI_STATION_IF_NAME=\"wlan0\"",
                        "-DCHIP_DEVICE_CONFIG_LINUX_DHCPC_CMD=\"udhcpc -b -i %s \"",
                        "-DCHIP_DEVICE_CONFIG_THREAD_INTERFACE_NAME=\"wpan0\"",
                        "-DCHIP_DEVICE_CONFIG_ENABLE_WIFI=1",
                        "-DCHIP_DEVICE_CONFIG_ENABLE_THREAD=1",
                       ]
        custom_toolchain="${build_root}/toolchain/custom"
        target_cc="${CC}"
        target_cxx="${CXX}"
        target_ar="${AR}"'
}

do_configure() {
    cd ${S}/
    if ${DEPLOY_TRUSTY}; then
        git submodule update --init
        ./scripts/checkout_submodules.py
    fi
    cd ${S}
    touch build_overrides/pigweed_environment.gni
    cd ${S}/${APP_PATH}
    common_configure
}

do_compile() {
    cd ${S}/${APP_PATH}
    ninja -C out/aarch64
}

do_install() {
    install -d -m 755 ${D}${bindir}
    install ${S}/${APP_PATH}/out/aarch64/${APP_BINARY} ${D}${bindir}

    install -d ${D}/lib/systemd/system/
    install -m 644 ${WORKDIR}/chip-all-clusters-app.service ${D}/lib/systemd/system/
    
    # Install Matter Controller service and management script
    install -m 644 ${WORKDIR}/matter-controller.service ${D}/lib/systemd/system/
    install -d -m 755 ${D}${bindir}
    install -m 755 ${WORKDIR}/matter-controller-ctl.sh ${D}${bindir}/matter-controller-ctl
    install -m 755 ${WORKDIR}/verify-matter-controller.sh ${D}${bindir}/verify-matter-controller
    
    # Install tmpfiles.d configuration to ensure storage directory exists
    install -d ${D}${sysconfdir}/tmpfiles.d
    install -m 644 ${WORKDIR}/matter-controller.conf ${D}${sysconfdir}/tmpfiles.d/matter-controller.conf
}

INSANE_SKIP_${PN} = "ldflags"

