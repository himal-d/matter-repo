SUMMARY = "A image for the RDK extender yocto build"

inherit rdk-image
require recipes-core/images/add-non-root-user-group.inc

IMAGE_FEATURES_remove = "read-only-rootfs"

IMAGE_ROOTFS_SIZE = "8192"

IMAGE_INSTALL += " \
   packagegroup-core-boot \
   devmem2 \
   ${@bb.utils.contains("DISTRO_FEATURES", "kirkstone", "", "lttng-tools",  d)} \
   pptp-linux \
   rp-pppoe  \
   iputils \
   btrfs-tools \
   util-linux-readprofile \
   wireless-tools \
   cryptsetup \
   coreutils \
   dosfstools \
   e2fsprogs \
   fftw \
   hostapd \
   wpa-supplicant \
   iproute2 \
   libpcap \
   nfs-utils \
   openssl \
   rpcbind \
   ${@bb.utils.contains("DISTRO_FEATURES", "kirkstone", "", "python-core",  d)} \
   sg3-utils \
   squashfs-tools \
   valgrind \
   testfloat \
   ${@bb.utils.contains("DISTRO_FEATURES", "kirkstone", "", "dhcp-server",  d)} \
   iptables \
   rdk-logger \
   ${SYSTEMD_TOOLS} \
   php \
   libmcrypt \
   bzip2 \
   ${@bb.utils.contains("DISTRO_FEATURES", "kirkstone", "", "nmap",  d)} \
   libpcap \
   tcpdump \
   ebtables \
   iw \
   bc \
   ieee1905 \
   opensync \
   openvswitch \
   libcap \
   bridge-utils \
   strace \
   wpa-supplicant \
   dropbear \
   mt76 \
   crda \
   dnsmasq \
   ntp \
"

SYSTEMD_TOOLS = "systemd-analyze systemd-bootchart"
# systemd-bootchart doesn't currently build with musl libc
SYSTEMD_TOOLS_remove_libc-musl = "systemd-bootchart"

do_rootfs[nostamp] = "1"

#Workaround to add device.properties
add_device_properties_file() {
    touch ${IMAGE_ROOTFS}/etc/device.properties
}

ROOTFS_POSTPROCESS_COMMAND_append = "add_device_properties_file; "
