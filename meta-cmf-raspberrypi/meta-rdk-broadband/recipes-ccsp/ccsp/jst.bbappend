
LDFLAGS_aarch64 += " -Wl,--no-as-needed"

do_install_append_aarch64 () {
    sed -i '/return \$arr.pop()/i  \$arr.pop();' ${D}/usr/www2/includes/php.jst
}
