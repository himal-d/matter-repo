PN = "matter-controller-daemon"
SUMMARY = "Matter Controller Daemon - Persistent Controller with BLE Commissioning"
LICENSE = "Apache-2.0"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/Apache-2.0;md5=89aea4e17d99a7cacdbeed46a0096b10"

SRCBRANCH = "v1.4-branch-nxp_imx_2025_q1"
IMX_MATTER_SRC ?= "gitsm://github.com/NXP/matter.git;protocol=https"
SRC_URI = "${IMX_MATTER_SRC};branch=${SRCBRANCH}"
SRC_URI += "file://matter-controller-daemon.service"
SRC_URI += "file://0001-Add-matter-controller-daemon-to-examples-BUILD.gn.patch"
SRC_URI += "file://matter-controller-daemon/BUILD.gn"
SRC_URI += "file://matter-controller-daemon/main.cpp"
SRC_URI += "file://matter-controller-daemon/MatterController.h"
SRC_URI += "file://matter-controller-daemon/MatterController.cpp"

FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

MATTER_PY_PATH ?= "${STAGING_BINDIR_NATIVE}/python3-native/python3"

# Include SDK patches (BLE fixes, QR code commissioning, etc.)
require recipes-matter/matter-common/matter-common-sdk-patches.inc

inherit systemd

SYSTEMD_SERVICE:${PN} = "matter-controller-daemon.service"
SYSTEMD_AUTO_ENABLE:${PN} = "disable"

APP_PATH = "examples/matter-controller-daemon"
APP_BINARY = "matter-controller-daemon"

PATCHTOOL = "git"
SRCREV = "${AUTOREV}"

TARGET_CC_ARCH += "${LDFLAGS}"

DEPENDS += " gn-native ninja-native openssl avahi dbus-glib-native pkgconfig-native boost python3-native python3-pip-native python3-packaging-native python3-click "
RDEPENDS_${PN} += " libavahi-client boost boost-staticdev bash "
FILES:${PN} += "usr/share"

INSANE_SKIP:${PN} += "dev-so debug-deps strip"

MATTER_ADVANCED = "${@bb.utils.contains('MACHINE_FEATURES', 'matteradvanced', 'true', 'false', d)}"

def get_target_cpu(d):
    for arg in (d.getVar('TUNE_FEATURES') or '').split():
        if arg == "cortexa7":
            return 'arm'
        if arg == "armv8a":
            return 'arm64'
    return 'arm64'

def get_arm_arch(d):
    for arg in (d.getVar('TUNE_FEATURES') or '').split():
        if arg == "cortexa7":
            return 'armv7ve'
        if arg == "armv8a":
            return 'armv8-a'
    return 'armv8-a'

def get_arm_cpu(d):
    for arg in (d.getVar('TUNE_FEATURES') or '').split():
        if arg == "cortexa7":
            return 'cortex-a7'
        if arg == "armv8a":
            return 'cortex-a72'
    return 'cortex-a72'

TARGET_CPU = "${@get_target_cpu(d)}"
TARGET_ARM_ARCH = "${@get_arm_arch(d)}"
TARGET_ARM_CPU = "${@get_arm_cpu(d)}"

USE_ELE = "${@bb.utils.contains('MACHINE', 'raspberrypi4', 1, 0, d)}"

S = "${WORKDIR}/git"

common_configure() {
    PKG_CONFIG_SYSROOT_DIR=${PKG_CONFIG_SYSROOT_DIR} \
    PKG_CONFIG_LIBDIR=${PKG_CONFIG_PATH} \
    gn gen out/aarch64 --script-executable="${MATTER_PY_PATH}" --args='treat_warnings_as_errors=false target_os="linux" target_cpu="${TARGET_CPU}" arm_arch="${TARGET_ARM_ARCH}" arm_cpu="${TARGET_ARM_CPU}" build_without_pw=true chip_with_imx_ele=${USE_ELE} enable_exceptions=true chip_code_pre_generated_directory="${S}/zzz_pregencodes"
        import("//build_overrides/build.gni")
        target_cflags=[
                        "-DCHIP_DEVICE_CONFIG_WIFI_STATION_IF_NAME=\"wlan0\"",
                        "-DCHIP_DEVICE_CONFIG_LINUX_DHCPC_CMD=\"udhcpc -b -i %s \"",
                        "-DCHIP_DEVICE_CONFIG_THREAD_INTERFACE_NAME=\"wpan0\"",
                        "-DCHIP_DEVICE_CONFIG_ENABLE_WIFI=1",
                        "-DCHIP_DEVICE_CONFIG_ENABLE_THREAD=1",
                        "-DCHIP_DEVICE_CONFIG_ENABLE_BLE=1",
                       ]
        custom_toolchain="${build_root}/toolchain/custom"
        target_cc="${CC}"
        target_cxx="${CXX}"
        target_ar="${AR}"'
}

do_configure() {
    cd ${S}/
    if ${DEPLOY_TRUSTY}; then
        git submodule update --init
        ./scripts/checkout_submodules.py
    fi
    cd ${S}
    touch build_overrides/pigweed_environment.gni
    
    # Copy files from WORKDIR to SDK (matching chip-tool structure: examples/matter-controller-daemon/)
    # WORKDIR files come from SRC_URI, so they're always the latest version
    install -d ${S}/${APP_PATH}
    
    # Copy BUILD.gn
    if [ -f ${WORKDIR}/matter-controller-daemon/BUILD.gn ]; then
        install -m 644 ${WORKDIR}/matter-controller-daemon/BUILD.gn ${S}/${APP_PATH}/BUILD.gn
        echo "✓ BUILD.gn copied from WORKDIR to ${S}/${APP_PATH}/"
    else
        echo "ERROR: BUILD.gn not found in WORKDIR!"
        echo "Expected: ${WORKDIR}/matter-controller-daemon/BUILD.gn"
        exit 1
    fi
    
    # Copy source files
    if [ -f ${WORKDIR}/matter-controller-daemon/main.cpp ]; then
        install -m 644 ${WORKDIR}/matter-controller-daemon/main.cpp ${S}/${APP_PATH}/main.cpp
    else
        echo "ERROR: main.cpp not found in WORKDIR!"
        exit 1
    fi
    
    if [ -f ${WORKDIR}/matter-controller-daemon/MatterController.h ]; then
        install -m 644 ${WORKDIR}/matter-controller-daemon/MatterController.h ${S}/${APP_PATH}/MatterController.h
    else
        echo "ERROR: MatterController.h not found in WORKDIR!"
        exit 1
    fi
    
    if [ -f ${WORKDIR}/matter-controller-daemon/MatterController.cpp ]; then
        install -m 644 ${WORKDIR}/matter-controller-daemon/MatterController.cpp ${S}/${APP_PATH}/MatterController.cpp
    else
        echo "ERROR: MatterController.cpp not found in WORKDIR!"
        exit 1
    fi
    
    # Verify BUILD.gn has correct imports (not the old pigweed_environment.gni)
    if grep -q "pigweed_environment.gni" ${S}/${APP_PATH}/BUILD.gn; then
        echo "ERROR: BUILD.gn still has old imports! Expected build.gni and chip.gni"
        echo "BUILD.gn first 10 lines:"
        head -10 ${S}/${APP_PATH}/BUILD.gn
        echo ""
        echo "WORKDIR BUILD.gn (if exists):"
        if [ -f ${WORKDIR}/BUILD.gn ]; then
            head -10 ${WORKDIR}/BUILD.gn
        elif [ -f ${WORKDIR}/matter-controller-daemon/BUILD.gn ]; then
            head -10 ${WORKDIR}/matter-controller-daemon/BUILD.gn
        fi
        exit 1
    fi
    
    # Remove any leftover .gn file from previous builds (it causes GN to use wrong root)
    # This must be done BEFORE changing to the app directory
    if [ -f ${S}/${APP_PATH}/.gn ]; then
        echo "WARNING: Removing leftover .gn file from ${S}/${APP_PATH}/ (this causes GN to use wrong root)"
        rm -f ${S}/${APP_PATH}/.gn
    fi
    
    # Verify no .gn file exists in app directory
    if [ -f ${S}/${APP_PATH}/.gn ]; then
        echo "ERROR: .gn file still exists in ${S}/${APP_PATH}/ after removal attempt!"
        exit 1
    fi
    
    # Run gn gen from the app directory (like chip-tool does)
    # Structure: examples/matter-controller-daemon/ (no linux/ subdirectory)
    cd ${S}/${APP_PATH}
    
    # Double-check: ensure no .gn file exists in current directory
    if [ -f .gn ]; then
        echo "ERROR: .gn file found in current directory $(pwd)!"
        echo "This will cause GN to use wrong build root"
        exit 1
    fi
    
    # Verify BUILD.gn exists and has the executable target before running gn gen
    if [ ! -f BUILD.gn ]; then
        echo "ERROR: BUILD.gn not found at ${S}/${APP_PATH}/BUILD.gn"
        exit 1
    fi
    
    if ! grep -q "executable(\"${APP_BINARY}\")" BUILD.gn; then
        echo "ERROR: BUILD.gn does not contain executable(\"${APP_BINARY}\")"
        echo "BUILD.gn contents:"
        cat BUILD.gn
        exit 1
    fi
    
    # Verify BUILD.gn has correct imports (not the old pigweed_environment.gni)
    if grep -q "pigweed_environment.gni" BUILD.gn; then
        echo "ERROR: BUILD.gn still has old imports! Expected build.gni and chip.gni"
        echo "BUILD.gn first 10 lines:"
        head -10 BUILD.gn
        exit 1
    fi
    
    # Verify GN can find the SDK root (build_overrides directory should exist)
    if [ ! -d "${S}/build_overrides" ]; then
        echo "ERROR: SDK root not found! build_overrides directory missing at ${S}/build_overrides"
        exit 1
    fi
    
    # Show BUILD.gn imports for debugging
    echo "BUILD.gn imports:"
    grep "^import" BUILD.gn || echo "  (no imports found)"
    echo ""
    
    # Try to verify GN can see the BUILD.gn before running gn gen
    # This helps debug if GN can discover the BUILD.gn file
    if command -v ${STAGING_BINDIR_NATIVE}/gn-native/gn >/dev/null 2>&1; then
        echo "Checking if GN can discover BUILD.gn..."
        # Try to list targets (this will fail if BUILD.gn isn't discovered, but that's OK)
        ${STAGING_BINDIR_NATIVE}/gn-native/gn desc . ${APP_BINARY} 2>&1 | head -5 || echo "  (GN can't see target yet - this is expected before gn gen)"
    fi
    echo ""
    
    common_configure
    
    # Verify the target is in build.ninja after gn gen
    if [ -f "out/aarch64/build.ninja" ]; then
        # Check for the actual build rule, not just the name (which might appear in comments)
        if ! grep -q "^build.*${APP_BINARY}:" out/aarch64/build.ninja && ! grep -q "build ${APP_BINARY}:" out/aarch64/build.ninja; then
            echo "ERROR: ${APP_BINARY} target not found in build.ninja after gn gen"
            echo "This indicates BUILD.gn was not processed correctly"
            echo ""
            echo "Debugging information:"
            echo "  BUILD.gn location: ${S}/${APP_PATH}/BUILD.gn"
            echo "  BUILD.gn exists: $([ -f ${S}/${APP_PATH}/BUILD.gn ] && echo 'YES' || echo 'NO')"
            echo "  Current directory: $(pwd)"
            echo ""
            echo "Checking BUILD.gn syntax with GN..."
            if command -v ${STAGING_BINDIR_NATIVE}/gn-native/gn >/dev/null 2>&1; then
                echo "Running: gn check ."
                ${STAGING_BINDIR_NATIVE}/gn-native/gn check . 2>&1 | head -20 || true
                echo ""
                echo "Trying to list targets using GN desc:"
                ${STAGING_BINDIR_NATIVE}/gn-native/gn desc out/aarch64 ${APP_BINARY} 2>&1 | head -10 || echo "  Target not found"
                echo ""
                echo "Trying to list all targets in this directory:"
                ${STAGING_BINDIR_NATIVE}/gn-native/gn desc out/aarch64 // 2>&1 | grep -i "matter-controller" | head -5 || echo "  No matter-controller targets found"
            fi
            echo ""
            echo "Checking what targets ARE in build.ninja:"
            grep "^build " out/aarch64/build.ninja | head -10
            echo ""
            echo "Full BUILD.gn contents:"
            cat BUILD.gn
            echo ""
            echo "Files in current directory:"
            ls -la
            echo ""
            echo "NOTE: If BUILD.gn exists but target is not in build.ninja, GN may not be discovering it."
            echo "      This can happen if the directory is new and not referenced from the SDK's top-level BUILD.gn files."
            exit 1
        else
            echo "✓ ${APP_BINARY} target found in build.ninja"
        fi
    else
        echo "ERROR: build.ninja not generated!"
        exit 1
    fi
}

do_compile() {
    cd ${S}/${APP_PATH}
    
    # Build with retry logic for Python venv pip issue
    BUILD_LOG=$(mktemp)
    TARGET_NAME="${APP_BINARY}"
    
    # Try building the specific target first
    if ! ninja -C out/aarch64 "${TARGET_NAME}" 2>&1 | tee "$BUILD_LOG"; then
        # If specific target fails, try building all (might work if target is a dependency)
        echo "Specific target build failed, trying to build all targets..."
        if ! ninja -C out/aarch64 2>&1 | tee -a "$BUILD_LOG"; then
            # Check if failure is due to missing pip in venv
            if grep -q "No module named pip" "$BUILD_LOG" && [ -d "out/aarch64/python-venv" ]; then
                echo "Detected missing pip in Python venv, installing..."
                VENV_PYTHON="out/aarch64/python-venv/bin/python"
                if [ -f "$VENV_PYTHON" ]; then
                    # Try ensurepip first (standard way to install pip in venv)
                    $VENV_PYTHON -m ensurepip --default-pip 2>&1 || {
                        # If ensurepip fails, use system pip to install pip in venv
                        echo "ensurepip failed, using system pip to install pip in venv..."
                        PYTHON_VERSION=$($VENV_PYTHON -c "import sys; print('{}.{}'.format(sys.version_info.major, sys.version_info.minor))" 2>/dev/null || echo "3.11")
                        SITE_PACKAGES="out/aarch64/python-venv/lib/python${PYTHON_VERSION}/site-packages"
                        if [ -d "$SITE_PACKAGES" ]; then
                            ${MATTER_PY_PATH} -m pip install --target="$SITE_PACKAGES" --no-deps pip setuptools wheel 2>&1 || true
                        fi
                    }
                fi
                # Verify pip is now available and retry build
                if [ -f "out/aarch64/python-venv/bin/pip" ] || [ -f "out/aarch64/python-venv/bin/pip3" ]; then
                    echo "pip installed successfully, retrying build..."
                    if ! ninja -C out/aarch64 "${TARGET_NAME}" 2>&1; then
                        ninja -C out/aarch64 2>&1
                    fi
                else
                    echo "ERROR: Failed to install pip in venv"
                    rm -f "$BUILD_LOG"
                    exit 1
                fi
            else
                # Not a pip error - show the actual build error
                echo "ERROR: Build failed"
                echo "Last 50 lines of build log:"
                tail -50 "$BUILD_LOG"
                rm -f "$BUILD_LOG"
                exit 1
            fi
        fi
    fi
    
    # Verify the binary was actually built
    # GN builds binaries in obj/<target_dir>/bin/<binary_name>
    # For examples/matter-controller-daemon, the binary is at:
    # out/aarch64/obj/examples/matter-controller-daemon/bin/matter-controller-daemon
    BINARY_LOCATION="out/aarch64/obj/examples/matter-controller-daemon/bin/${TARGET_NAME}"
    if [ ! -f "$BINARY_LOCATION" ]; then
        echo "ERROR: Binary ${TARGET_NAME} not found after build!"
        echo "Expected location: $BINARY_LOCATION"
        echo "Searching for built executables in out/aarch64/:"
        find out/aarch64 -type f -executable -name "${TARGET_NAME}" 2>/dev/null | head -20
        echo ""
        echo "Checking if target is in build.ninja:"
        grep -i "${TARGET_NAME}" out/aarch64/build.ninja | head -5 || echo "  Target not found in build.ninja"
        rm -f "$BUILD_LOG"
        exit 1
    fi
    echo "✓ Binary found at: $BINARY_LOCATION"
    
    rm -f "$BUILD_LOG"
}

do_install() {
    install -d -m 755 ${D}${bindir}
    
    # Find the binary - GN builds binaries in obj/<target_dir>/bin/<binary_name>
    # For examples/matter-controller-daemon, the binary is at:
    # examples/matter-controller-daemon/out/aarch64/obj/examples/matter-controller-daemon/bin/matter-controller-daemon
    BINARY_PATH="${S}/${APP_PATH}/out/aarch64/obj/examples/matter-controller-daemon/bin/${APP_BINARY}"
    
    if [ ! -f "$BINARY_PATH" ]; then
        echo "ERROR: Binary ${APP_BINARY} not found at expected location: $BINARY_PATH"
        echo "Searching for binary in build directory:"
        find ${S}/${APP_PATH}/out/aarch64 -name "${APP_BINARY}" -type f 2>/dev/null || echo "  Not found"
        exit 1
    fi
    
    install -m 755 "$BINARY_PATH" ${D}${bindir}

    install -d ${D}/lib/systemd/system/
    install -m 644 ${WORKDIR}/matter-controller-daemon.service ${D}/lib/systemd/system/
}

INSANE_SKIP_${PN} = "ldflags"

