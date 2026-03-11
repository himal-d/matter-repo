SRCREV = "66aae0e630e9886acee2386c0623ca479130c8b8"

LICENSE_kirkstone = "GPL-2.0-only"
LIC_FILES_CHKSUM_kirkstone = "file://LICENSE;md5=b234ee4d69f5fce4486a80fdaf4a4263"
SRC_URI_kirkstone = "git://github.com/cilynx/rtl88x2bu;protocol=https;branch=5.8.7.1_35809.20191129_COEX20191120-7777"
SRCREV_kirkstone = "476ef38727cb539d7987d0cd1da3a8842df7bc58"

do_configure_prepend() {
	sed -i "s/CONFIG_PLATFORM_ARM_RPI = n/CONFIG_PLATFORM_ARM_RPI = y/g" ${WORKDIR}/git/Makefile
	sed -i "s/CONFIG_PLATFORM_I386_PC = y/CONFIG_PLATFORM_I386_PC = n/g" ${WORKDIR}/git/Makefile
	sed -i "/\$(CONFIG_PLATFORM_ARM_RPI)/a EXTRA_CFLAGS += -DCONFIG_CONCURRENT_MODE -DCONFIG_RTW_DFS_REGION_DOMAIN=1" ${WORKDIR}/git/Makefile
}
