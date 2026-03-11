require ccsp_common_rpi.inc
CFLAGS_append_kirkstone = " -fcommon -Wno-error=implicit-function-declaration"
LDFLAGS_append_aarch64 = " -lnanomsg "
FILES_${PN} += " /lib/systemd/system "
