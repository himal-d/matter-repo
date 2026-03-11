FILESEXTRAPATHS_prepend := "${THISDIR}/files:"
SRC_URI += "file://rtl8822bu.bin \
	    file://ble.cfg "

do_install_append() {
    install -d ${D}${nonarch_base_libdir}/firmware
    install -m 0644 ${WORKDIR}/rtl8822bu.bin ${D}${nonarch_base_libdir}/firmware/rtl8822bu.bin
}

FILES_${PN} += "${nonarch_base_libdir}/firmware/rtl8822bu.bin"

