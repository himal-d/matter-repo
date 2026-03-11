
# Note that RDK-B builds typically require hostapd and wpa-supplicant, which
# both contain hardcoded dependencies on MD4 support being enabled in openssl.
# RDK-B specific OEM layers may therefore require an additional .bbappend for
# openssl which sets:

EXTRA_OECONF_remove_class-target = "no-md4"

# Keep the complete over-ride for native builds. Temp solution, to be removed
# once meta-rdk-ext .bbappend for openssl is updated to append RDK specific
# config options to the target build only.
# Fix for building python-m2crypto-native.

EXTRA_OECONF_class-native = "-no-ssl3"

DEPENDS += "libtool"

inherit systemd

SYSLOG-NG_SERVICE_cobalt = "cobalt.service"
SYSTEMD_AUTO_ENABLE_${PN} = "enable"
SYSTEMD_SERVICE_${PN} = "cobalt.service"

FILES_${PN} += "${base_libdir}/rdk/*"
FILES_${PN} += "${systemd_unitdir}/system/cobalt.service"
