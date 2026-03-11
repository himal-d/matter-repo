require ccsp_common_rpi.inc

FILESEXTRAPATHS_prepend := "${THISDIR}/${PN}:"

SRC_URI_append = " file://bbhm_def_cfg_rpi.xml"
SRC_URI_lxcbrc += " file://bbhm_def_cfg_lxc.xml"

do_install_append() {
    # Config files and scripts
    install -d ${D}/usr/ccsp/config
    install -m 644 ${WORKDIR}/bbhm_def_cfg_rpi.xml ${D}/usr/ccsp/config/bbhm_def_cfg.xml
    install -m 755 ${S}/scripts/bbhm_patch.sh ${D}/usr/ccsp/psm/bbhm_patch.sh
}

do_install_append_lxcbrc () {
 install -m 644 ${WORKDIR}/bbhm_def_cfg_lxc.xml ${D}/usr/ccsp/config/bbhm_def_cfg.xml
}

