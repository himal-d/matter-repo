#!/bin/bash
# Matter Controller Verification Script
# Run this script on Raspberry Pi after deployment to verify Matter Controller setup

set -e

echo "=========================================="
echo "Matter Controller Verification Script"
echo "=========================================="
echo ""

ERRORS=0
WARNINGS=0

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

check_pass() {
    echo -e "${GREEN}✓${NC} $1"
}

check_fail() {
    echo -e "${RED}✗${NC} $1"
    ERRORS=$((ERRORS + 1))
}

check_warn() {
    echo -e "${YELLOW}⚠${NC} $1"
    WARNINGS=$((WARNINGS + 1))
}

# 1. Check Matter Controller Service
echo "1. Checking Matter Controller Service..."
if systemctl is-active --quiet matter-controller; then
    check_pass "Matter Controller service is running"
else
    check_fail "Matter Controller service is not running"
    echo "   Run: sudo systemctl start matter-controller"
fi

if systemctl is-enabled --quiet matter-controller; then
    check_pass "Matter Controller service is enabled on boot"
else
    check_warn "Matter Controller service is not enabled on boot"
    echo "   Run: sudo systemctl enable matter-controller"
fi

# 2. Check Management Script
echo ""
echo "2. Checking Management Script..."
if [ -f "/usr/bin/matter-controller-ctl" ]; then
    check_pass "Management script exists"
    if [ -x "/usr/bin/matter-controller-ctl" ]; then
        check_pass "Management script is executable"
    else
        check_fail "Management script is not executable"
        echo "   Run: sudo chmod +x /usr/bin/matter-controller-ctl"
    fi
else
    check_fail "Management script not found"
fi

# 3. Check Storage Directory
echo ""
echo "3. Checking Storage Directory..."
STORAGE_DIR="/var/lib/matter-controller"
if [ -d "$STORAGE_DIR" ]; then
    check_pass "Storage directory exists: $STORAGE_DIR"
    if [ -w "$STORAGE_DIR" ]; then
        check_pass "Storage directory is writable"
    else
        check_fail "Storage directory is not writable"
        echo "   Run: sudo chmod 755 $STORAGE_DIR"
    fi
else
    check_fail "Storage directory missing: $STORAGE_DIR"
    echo "   Run: sudo matter-controller-ctl setup-storage"
fi

# 4. Check BLE
echo ""
echo "4. Checking BLE..."
if command -v hciconfig >/dev/null 2>&1; then
    if hciconfig hci0 2>/dev/null | grep -q "UP RUNNING"; then
        check_pass "BLE adapter (hci0) is up and running"
    else
        check_fail "BLE adapter (hci0) is not up and running"
        echo "   Run: sudo hciconfig hci0 up"
    fi
else
    check_warn "hciconfig not found (BLE tools may not be installed)"
fi

if systemctl is-active --quiet bluetooth; then
    check_pass "Bluetooth service is running"
else
    check_fail "Bluetooth service is not running"
    echo "   Run: sudo systemctl start bluetooth"
fi

# 5. Check Thread Interface
echo ""
echo "5. Checking Thread Interface..."
if ip link show wpan0 >/dev/null 2>&1; then
    check_pass "Thread interface (wpan0) exists"
    
    if command -v ot-ctl >/dev/null 2>&1; then
        THREAD_STATE=$(ot-ctl state 2>/dev/null | grep -v "Done" | head -n 1 | tr -d '\r\n')
        if [ -n "$THREAD_STATE" ]; then
            if [ "$THREAD_STATE" = "leader" ] || [ "$THREAD_STATE" = "router" ] || [ "$THREAD_STATE" = "child" ]; then
                check_pass "Thread network is active (state: $THREAD_STATE)"
            else
                check_warn "Thread network state: $THREAD_STATE"
            fi
        else
            check_warn "Could not determine Thread network state"
        fi
    else
        check_warn "ot-ctl not found (Thread tools may not be installed)"
    fi
else
    check_fail "Thread interface (wpan0) missing"
    echo "   Check OTBR: sudo systemctl status ot-br-posix"
fi

# 6. Check OTBR
echo ""
echo "6. Checking OTBR..."
if systemctl is-active --quiet ot-br-posix; then
    check_pass "OTBR service is running"
else
    check_fail "OTBR service is not running"
    echo "   Run: sudo systemctl start ot-br-posix"
fi

# 7. Check Avahi (mDNS)
echo ""
echo "7. Checking Avahi (mDNS)..."
if systemctl is-active --quiet avahi-daemon; then
    check_pass "Avahi (mDNS) service is running"
else
    check_fail "Avahi (mDNS) service is not running"
    echo "   Run: sudo systemctl start avahi-daemon"
fi

# 8. Check chip-all-clusters-app
echo ""
echo "8. Checking chip-all-clusters-app..."
if [ -f "/usr/bin/chip-all-clusters-app" ]; then
    check_pass "chip-all-clusters-app binary exists"
    if [ -x "/usr/bin/chip-all-clusters-app" ]; then
        check_pass "chip-all-clusters-app is executable"
    else
        check_fail "chip-all-clusters-app is not executable"
    fi
else
    check_fail "chip-all-clusters-app binary not found"
fi

# 9. Check chip-tool
echo ""
echo "9. Checking chip-tool..."
if [ -f "/usr/bin/chip-tool" ]; then
    check_pass "chip-tool binary exists"
else
    check_warn "chip-tool binary not found (may not be needed for controller)"
fi

# 10. Check Logs
echo ""
echo "10. Checking Recent Logs..."
if journalctl -u matter-controller -n 10 --no-pager 2>/dev/null | grep -qi "error\|fail"; then
    check_warn "Recent errors found in controller logs"
    echo "   Check: sudo journalctl -u matter-controller -n 50"
else
    check_pass "No recent errors in controller logs"
fi

# Summary
echo ""
echo "=========================================="
echo "Verification Summary"
echo "=========================================="
if [ $ERRORS -eq 0 ] && [ $WARNINGS -eq 0 ]; then
    echo -e "${GREEN}✓ All checks passed!${NC}"
    exit 0
elif [ $ERRORS -eq 0 ]; then
    echo -e "${YELLOW}⚠ $WARNINGS warning(s) found${NC}"
    exit 0
else
    echo -e "${RED}✗ $ERRORS error(s) found, $WARNINGS warning(s)${NC}"
    exit 1
fi

