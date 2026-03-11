# Matter Application Base Class
# This class provides common configuration and SDK patches for all Matter applications
# 
# Usage in your recipe:
#   inherit matter-app-base
#
# This automatically includes:
# - SDK-level patches (BLE error 36 fixes)
# - Common Matter SDK configuration

inherit matter-common

# Include SDK patches
require matter-common-sdk-patches.inc

