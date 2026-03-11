PN = "matter"
SUMMARY = "Matter IoT connectivity on i.MX boards"
DESCRIPTION = "This layer loads the main Matter applications"
LICENSE = "Apache-2.0"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/Apache-2.0;md5=89aea4e17d99a7cacdbeed46a0096b10"

SRCBRANCH = "v1.4-branch-nxp_imx_2025_q1"
IMX_MATTER_SRC ?= "gitsm://github.com/NXP/matter.git;protocol=https"
SRC_URI = "${IMX_MATTER_SRC};branch=${SRCBRANCH}"
#SRC_URI += "file://0001-MATTER-1352-2-Add-se_version.h.patch;patchdir=third_party/imx-secure-enclave/repo/"
SRC_URI += "file://chip-tool.service"
SRC_URI += "file://chip-lighting-app.service"

PATCHTOOL = "git"
SRCREV = "${AUTOREV}"

inherit systemd

SYSTEMD_SERVICE:${PN} = "chip-tool.service chip-lighting-app.service"
SYSTEMD_AUTO_ENABLE:${PN} = "enable"

MATTER_PY_PATH ?= "${STAGING_BINDIR_NATIVE}/python3-native/python3"
TARGET_CC_ARCH += "${LDFLAGS}"

DEPENDS += " gn-native ninja-native pkgconfig-native openssl avahi boost python3-native python3-pip-native python3-packaging-native python3-click dbus-glib-native "
RDEPENDS_${PN} += " libavahi-client boost "
FILES:${PN} += "usr/share"

INSANE_SKIP:${PN} += "dev-so debug-deps strip"
INSANE_SKIP_${PN} = "ldflags"

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
                       ]
        custom_toolchain="${build_root}/toolchain/custom"
        target_cc="${CC}"
        target_cxx="${CXX}"
        target_ar="${AR}"'
}

do_configure() {
	cd ${S}
    touch build_overrides/pigweed_environment.gni
    
	cd ${S}/examples/lighting-app/linux
	common_configure

    cd ${S}/examples/chip-tool
	common_configure

    cd ${S}/examples/ota-provider-app/linux
	common_configure

    cd ${S}/examples/ota-requestor-app/linux
	common_configure

    #cd ${S}/examples/chip-tool-web
	#common_configure

	# Build chip-tool-web
    cd ${S}/examples/chip-tool
    PKG_CONFIG_SYSROOT_DIR=${PKG_CONFIG_SYSROOT_DIR} \
    PKG_CONFIG_LIBDIR=${PKG_CONFIG_PATH} \
    gn gen out/aarch64-web --script-executable="${MATTER_PY_PATH}" --args='treat_warnings_as_errors=false target_os="linux" target_cpu="${TARGET_CPU}" arm_arch="${TARGET_ARM_ARCH}" arm_cpu="${TARGET_ARM_CPU}" enable_rtti=true enable_exceptions=true chip_with_web=1 chip_with_web2=1 build_without_pw=true chip_code_pre_generated_directory="${S}/zzz_pregencodes"
        import("//build_overrides/build.gni")
        target_cflags=[
                        "-DCHIP_DEVICE_CONFIG_WIFI_STATION_IF_NAME=\"mlan0\"",
                        "-DCHIP_DEVICE_CONFIG_LINUX_DHCPC_CMD=\"udhcpc -b -i %s \"",
        ]
        custom_toolchain="${build_root}/toolchain/custom"
        target_cc="${CC}"
        target_cxx="${CXX}"
        target_ar="${AR}"'
}

do_compile() {
    cd ${S}/examples/lighting-app/linux
    ninja -C out/aarch64

    cd ${S}/examples/chip-tool
    ninja -C out/aarch64

    cd ${S}/examples/ota-provider-app/linux
    ninja -C out/aarch64

    cd ${S}/examples/ota-requestor-app/linux
    ninja -C out/aarch64

    cd ${S}/examples/chip-tool
    ninja -C out/aarch64-web
}

do_install() {
    install -d -m 755 ${D}${bindir}
    install ${S}/examples/lighting-app/linux/out/aarch64/chip-lighting-app ${D}${bindir}
    install ${S}/examples/chip-tool/out/aarch64/chip-tool ${D}${bindir}
    install ${S}/examples/ota-provider-app/linux/out/aarch64/chip-ota-provider-app ${D}${bindir}
    install ${S}/examples/ota-requestor-app/linux/out/aarch64/chip-ota-requestor-app ${D}${bindir}

    # Install chip-tool-web
    install ${S}/examples/chip-tool/out/aarch64-web/chip-tool-web ${D}${bindir}
    install -d -m 755 ${D}/usr/share/chip-tool-web/
    cp -r ${S}/examples/chip-tool/webui/frontend ${D}/usr/share/chip-tool-web/

    install -d ${D}/lib/systemd/system/
    install -m 644 ${WORKDIR}/chip-tool.service ${D}/lib/systemd/system/
    install -m 644 ${WORKDIR}/chip-lighting-app.service ${D}/lib/systemd/system/
}

