LIC_FILES_CHKSUM = "file://hal/hal_com_c2h.h;md5=662fa96812921f188274143f6d501f27;endline=19"

SRCREV = "b7faffdd77767269770b79876f88dd1145b6a630"
LICENSE_kirkstone = "GPL-2.0-only"
LIC_FILES_CHKSUM_kirkstone = "file://${COMMON_LICENSE_DIR}/GPL-2.0-only;md5=801f80980d171dd6425610833a22dbe6"
SRC_URI_kirkstone = "git://github.com/Mange/rtl8192eu-linux-driver.git;protocol=https;branch=realtek-4.4.x"
SRCREV_kirkstone = "528ae31705764d78cc117abd604d9b799bd52543"

do_configure_prepend() {
	sed -i "s/CONFIG_PLATFORM_ARM_RPI = n/CONFIG_PLATFORM_ARM_RPI = y/g" ${WORKDIR}/git/Makefile
	sed -i "s/CONFIG_PLATFORM_I386_PC = y/CONFIG_PLATFORM_I386_PC = n/g" ${WORKDIR}/git/Makefile
}

do_compile() {
	unset CFLAGS CPPFLAGS CXXFLAGS LDFLAGS CC LD CPP
	oe_runmake 'M={D}${base_libdir}/modules/${KERNEL_VERSION}/kernel/drivers/net/wireless' \
	'KERNEL_SOURCE=${STAGING_KERNEL_DIR}' \
	'LINUX_SRC=${STAGING_KERNEL_DIR}' \
	'KDIR=${STAGING_KERNEL_DIR}' \
	'KERNDIR=${STAGING_KERNEL_DIR}' \
	'KSRC=${STAGING_KERNEL_DIR}' \
	'KERNEL_VERSION=${KERNEL_VERSION}' \
	'KVER=${KERNEL_VERSION}' \
	'CC=${KERNEL_CC}' \
	'AR=${KERNEL_AR}' \
	'LD=${KERNEL_LD}'
}
