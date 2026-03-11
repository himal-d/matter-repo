FILESEXTRAPATHS_prepend := "${THISDIR}/files:"

SRC_URI = "git://github.com/gordboy/rtl8812au-5.6.4.2.git;protocol=https"
SRCREV = "3110ad65d0f03532bd97b1017cae67ca86dd34f6"
LICENSE_kirkstone = "GPL-2.0"
LIC_FILES_CHKSUM_kirkstone = "file://LICENSE;md5=b234ee4d69f5fce4486a80fdaf4a4263"
SRC_URI_kirkstone = " \
        git://github.com/svpcom/rtl8812au;protocol=https;branch=v5.2.20 \
        file://8812au_kirkstone_compilation_issues.patch \
"
SRCREV_kirkstone = "aebe190f4f75457302536c97273d833b580ebcee"

do_configure_prepend() {
	sed -i "s/CONFIG_PLATFORM_ARM_RPI = n/CONFIG_PLATFORM_ARM_RPI = y/g" ${WORKDIR}/git/Makefile
	sed -i "s/CONFIG_PLATFORM_I386_PC = y/CONFIG_PLATFORM_I386_PC = n/g" ${WORKDIR}/git/Makefile
	sed -i "/\$(CONFIG_PLATFORM_ARM_RPI)/a EXTRA_CFLAGS += -DCONFIG_CONCURRENT_MODE" ${WORKDIR}/git/Makefile
}

do_configure_append() {
	touch ${B}/rtl8812au.ko
}

do_install_append() {
	rm ${D}/lib/modules/${KERNEL_VERSION}/rtl8812au.ko
	rm ${B}/rtl8812au.ko
	install -m 0755 ${B}/8812au.ko ${D}/lib/modules/${KERNEL_VERSION}/8812au.ko
}
