SUMMARY = "Utility which shows ntp synchronisation status"

FILESEXTRAPATHS_prepend := "${THISDIR}/${PN}:"

SRC_URI = "\
            https://src.fedoraproject.org/lookaside/pkgs/ntp/ntpstat-0.2.tgz/6b2bedefe2e7c63ea52609b222022121/ntpstat-0.2.tgz; \
"

SRC_URI[md5sum] = "6b2bedefe2e7c63ea52609b222022121"
SRC_URI[sha256sum] = "6ad33fa317117074c44144f5c410ac765af1bc4bb33cc62ce39b637a985de52f"

LICENSE="GPLv2"
LIC_FILES_CHKSUM="file://COPYING;md5=479c9b73b1d47473ccace9559c370361"

do_compile() {
    ${CC} ${CFLAGS} ${LDFLAGS} ${S}/ntpstat.c -o ntpstat
}

do_install() {
    install -d ${D}${bindir}
    install -m 755 ${S}/ntpstat ${D}${bindir}
}

