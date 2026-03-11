do_install_append_extender() {
    sed -i '/ExecStart/ s/$/ 2.pool.ntp.org /' ${D}${systemd_unitdir}/system/ntpd.service
}
