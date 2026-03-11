IMAGE_GEN_DEBUGFS = "0"

# For 5.10 linux kernel
PREFERRED_VERSION_linux-raspberrypi_hybrid_dunfell = "5.10.%"
PREFERRED_VERSION_linux-libc-headers_hybrid_dunfell = "5.10.%"

PREFERRED_VERSION_linux-raspberrypi_client_dunfell = "5.10.%"
PREFERRED_VERSION_linux-libc-headers_client_dunfell = "5.10.%"

PREFERRED_VERSION_linux-raspberrypi_ipclient_dunfell = "5.10.%"
PREFERRED_VERSION_linux-libc-headers_ipclient_dunfell = "5.10.%"

PREFERRED_VERSION_android-raspberrypi ?= "5.15.%"

#preferred version for linux kirkstone build
PREFERRED_VERSION_libnl_kirkstone ?= "3.5.0"
PREFERRED_VERSION_jansson_kirkstone = "2.13.1"
PREFERRED_VERSION_googletest_kirkstone = "1.11.%"
PREFERRED_VERSION_net-snmp_kirkstone = "5.9.1"
PREFERRED_VERSION_icu_kirkstone ?= "70.1"
PREFERRED_VERSION_icu-native_kirkstone ?= "70.1"

#preferred version for meson
PREFERRED_VERSION_meson-native_kirkstone = "0.61.3"
PREFERRED_VERSION_meson_kirkstone = "0.61.3"

### preferred providers
PREFERRED_PROVIDER_libevent = "libevent"

PREFERRED_PROVIDER_virtual/iarmmgrs-hal = "iarmmgrs-hal-raspberrypi"
PREFERRED_PROVIDER_virtual/devicesettings-hal = "devicesettings-hal-raspberrypi"
PREFERRED_PROVIDER_virtual/gst-plugins-playersinkbin ?= "gst-plugins-playersinkbin-rpi"
PREFERRED_PROVIDER_virtual/wifi-hal ?= "wifi-hal-generic"
PREFERRED_PROVIDER_virtual/mfrlib ?= "mfrlibs-rpi"
PREFERRED_PROVIDER_virtual/mfrfwlib ?= "fwupgrade-lib"

VIRTUAL-RUNTIME_mfrlib = "mfrlibs-rpi"
VIRTUAL-RUNTIME_dtcpmgr = ""

DISTRO_FEATURES_append = " streamfs"

DISTRO_FEATURES_append = " cobalt-plugin"
DISTRO_FEATURES_remove_aarch64 = " cobalt-plugin"

# Comcast forcefully enabled the Cobalt + Evergreen build but it causing critical issue in youtube.
# So, we disabled the Evergreen by adding libcobalt distro.
# Once the youtube issue resolved will remove this fix.
DISTRO_FEATURES_append = " libcobalt"

DISTRO_FEATURES_append = " parodus"
DISTRO_FEATURES_append = " ledmgr"
DISTRO_FEATURES_append = " build_rne"
DISTRO_FEATURES_append = " rdk-oss-ssa"

# RDKShell distro is enabled for RDK services
DISTRO_FEATURES_append = " rdkshell"
DISTRO_FEATURES_append = " offline_apps"

# no more onscreen terminal required for RDK services
DISTRO_FEATURES_append = " systemd-disable-getty"

DISTRO_FEATURES_append = " ctrlm"
DISTRO_FEATURES_append = " vendor_class_id_feature"
DISTRO_FEATURES_append = " ctrlm_voice_sdk"

DISTRO_FEATURES_append = " wifi"
DISTRO_FEATURES_append = " bluetooth"
DISTRO_FEATURES_append = " bluez5"

DISTRO_FEATURES_NATIVE_append_kirkstone = " kirkstone"
DISTRO_FEATURES_NATIVESDK_append_kirkstone = " kirkstone"

# CMFSUPPORT-897 Rialto recipes in meta-cmf-video
# RDKCMF-8913 fix rialto recipes to fixed revision by default
DISTRO_FEATURES_append = " rialto"
DISTRO_FEATURES_append = " rialto_head"

# DISTRO FEATURES to allow building tip of rdkservices-lisa component
DISTRO_FEATURES_append = " rdkservice_lisa_head"

# Disable Thunder Security
DISTRO_FEATURES_append = " thunder_security_disable"

DISTRO_FEATURES_append = " enable_icrypto_openssl"
DISTRO_FEATURES_remove = "netflix_cryptanium"

# OCDM CAS support
DISTRO_FEATURES_append = " external-cas"

# FOG support
DISTRO_FEATURES_append = " enable-fog"

# Enable Storage Manager support for FOG
DISTRO_FEATURES_append = " storage_sdc"

HOSTTOOLS += " python"

# globally disables this feature (for all images supported)
IMAGE_FEATURES_remove = "read-only-rootfs"

# Upgrade wpe-webkit to 2.38
# The WEBBACKENDS will be migrated to meta-rdk when all other platforms have moved to a later version of wpe-webkit, e.g. 2.38
DISTRO_FEATURES_append = " wpe-2.38"
WEBBACKENDS := "${@bb.utils.contains('DISTRO_FEATURES', 'wpe-2.38', 'webkitbrowser-plugin', 'rdkbrowser2', d)}"

#Upgrade Gstreamer to 1.18
DISTRO_FEATURES_append = " gstreamer1_18"
GST_VERSIONS = "${@bb.utils.contains('DISTRO_FEATURES', 'gstreamer1_18', '1.18.5', '1.16.3', d)}"
PREFERRED_VERSION_gstreamer1.0 = "${GST_VERSIONS}"
PREFERRED_VERSION_gstreamer1.0-libav = "${GST_VERSIONS}"
PREFERRED_VERSION_gstreamer1.0-plugins-bad = "${GST_VERSIONS}"
PREFERRED_VERSION_gstreamer1.0-plugins-base = "${GST_VERSIONS}"
PREFERRED_VERSION_gstreamer1.0-plugins-good = "${GST_VERSIONS}"
PREFERRED_VERSION_gstreamer1.0-plugins-ugly = "${GST_VERSIONS}"

### others
ENABLE_UART = "1"

# RDKBDEV-298 : Add USP Agent support using OBUSPA
DISTRO_FEATURES_append_broadband = " usppa"

# REFPLTV-1137: DLNA support for xupnp
DISTRO_FEATURES_append_broadband = " dlna"

DISTRO_FEATURES_append_broadband = " referencepltfm "
DISTRO_FEATURES_append_extender = " referencepltfm "

DISTRO_FEATURES_append_broadband = " ipv6"
DISTRO_FEATURES_append_broadband = " webconfig_bin"

# RDKB-51565,RDKB-50795: [HAL] Cellular Hal Implementation
DISTRO_FEATURES_append_broadband = " rdkb_cellular_manager_mm"
DISTRO_FEATURES_append_broadband = " cellular_mgr_lite"
DISTRO_FEATURES_append_broadband = " cellular_libqmi_support"

DISTRO_FEATURES_append_broadband = " rdkb_power_manager"
DISTRO_FEATURES_append_broadband = " rdkb_gpon_manager"
DISTRO_FEATURES_append_broadband = " rdkb_wan_manager"
DISTRO_FEATURES_append_broadband = " rdkb_voice_manager_dmltr104_v2"
DISTRO_FEATURES_append_broadband = " rdkb_xdsl_ppp_manager"
DISTRO_FEATURES_append_broadband = " fwupgrade_manager"
DISTRO_FEATURES_append_broadband = " rdkb_inter_device_manager"

DISTRO_FEATURES_append_broadband = " rdk_ledmanager"
DISTRO_FEATURES_remove_aarch64 = " rdk_ledmanager"

# Platform manager and LanManager
#DISTRO_FEATURES_append_broadband = " pm_lan_mgr"

# Fix MeshAgent build errors
DISTRO_FEATURES_append_broadband = " WanFailOverSupportEnable"

# RDKBDEV-50: Adding DSLite Functionality and related TR-181 DataModel Parameters
DISTRO_FEATURES_append_broadband = " dslite"

# RDKBDEV-73 : Dynamic DNS : Standardization based on broadband-forum.
DISTRO_FEATURES_append_broadband = " ddns_broadband"

# RDKBDEV-83 : Device Gateway Association using Managed Device
DISTRO_FEATURES_append_broadband = " device_gateway_association"

# REFPLTB-1546 : WiFi HAL 3.0 support for RPI
DISTRO_FEATURES_append_broadband = " halVersion3"

# RDKBDEV-866: EasyMesh Controller support
DISTRO_FEATURES_append_broadband = " easymesh-controller"

# RDKB-40900: RDKB support extender/nonrouter profile
DISTRO_FEATURES_append_extender = " rdkb_extender"

# RDKB-44824: CoreNetLib move bb file location
DISTRO_FEATURES_append_broadband = " core-net-lib"

# DKBDEV-1455 : Support Broadband DAC
DISTRO_FEATURES_append_broadband = " dac"

# REFPLTB-1775: Sky team's fix for erouter0 IP issue
DISTRO_FEATURES_append_broadband = " RbusBuildFlagEnable"

#MeshAgent support for broadband
DISTRO_FEATURES_append_broadband = " meshwifi"

#rdk-wifi-libhostap support for broadband
DISTRO_FEATURES_append_broadband = " HOSTAPD_2_10"

# OneWifi feature
DISTRO_FEATURES_append_broadband = " OneWifi"
# MacFilter Feature
DISTRO_FEATURES_append_broadband = " acl_nl_support"

# RDKBDEV-942 RdkGponManager: Modify as per new WAN Manager Design
DISTRO_FEATURES_append_broadband = " WanManagerUnificationEnable"

# CpuPROCAnalyzer Support for broadband
DISTRO_FEATURES_append_broadband = " CPUPROCANALYZER_BROADBAND"

# RDKB-50999: WebConfig blob handler
DISTRO_FEATURES_append_broadband = " lld_support"

# RDKB-48800: Install DHCP Manager service file
DISTRO_FEATURES_append_broadband = " dhcp_manager"

# RDKBDEV-694: Adding Partner Default Ext
DISTRO_FEATURES_append_broadband = " partner_default_ext"

# RDKBDEV-755: Add Asterisk IP PBX voice HAL for TelcoVoiceManager
DISTRO_FEATURES_append_broadband = " Asterisk"

SESSIONMGR_WS_RPC_ENABLE = "1"

#Enable voice stack
DISTRO_FEATURES_append = " enable-rdkv-bt-voice"

#Enable ripple and firebolt
DISTRO_FEATURES_append_hybrid = " enable_firebolt_compliance_tdk"
DISTRO_FEATURES_append_client = " enable_firebolt_compliance_tdk"
DISTRO_FEATURES_remove_raspberrypi3 = " enable_firebolt_compliance_tdk"
DISTRO_FEATURES_remove_raspberrypi3 = " ripple2.0"

#REFPLTB-2784 : easymesh controller arch only supports with wifiagent
MACHINEOVERRIDES_append =. "${@bb.utils.contains('DISTRO_FEATURES', 'OneWifi', ':onewifi', '' ,d)}"
DISTRO_FEATURES_remove_onewifi = " easymesh-controller"
