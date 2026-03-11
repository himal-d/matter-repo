SUMMARY = "OpenThread Daemon (ot-daemon)"
LICENSE = "BSD-3-Clause"
LIC_FILES_CHKSUM = "file://LICENSE;md5=543b6fe90ec5901a683320a36390c65f"

SRC_URI = "git://github.com/openthread/openthread.git;branch=main;protocol=https \
           file://enable-ot-uptime.patch \
"
SRCREV = "a9a9d840612e05d0ed6149c980ab1075e823567e"

S = "${WORKDIR}/git"

DEPENDS = "ninja-native cmake dbus readline ncurses"

inherit cmake systemd

EXTRA_OECMAKE = "\
    -DOT_PLATFORM=posix \
    -DOT_DAEMON=ON \
    -DOT_POSIX_SETTINGS_OUTFILE=openthread-posix-config \
"

FILES:${PN} += " \
    ${sbindir}/ot-daemon \
    ${bindir}/ot-ctl \
"

