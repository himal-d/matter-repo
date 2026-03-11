#!/bin/bash
# Verify BlueZ BLE Adapter Readiness Before Commissioning
# Usage: verify-ble-ready.sh

# Don't use set -e - we want to continue and fix issues

echo "=========================================="
echo "BlueZ BLE Adapter Readiness Check"
echo "=========================================="
echo ""

# Check 0: Verify /sys/class/bluetooth exists (required for service to start)
echo "[0/8] Checking /sys/class/bluetooth exists..."
if [ -d "/sys/class/bluetooth" ]; then
    echo "  ✓ /sys/class/bluetooth exists"
else
    echo "  ✗ /sys/class/bluetooth does NOT exist"
    echo "  → Loading Bluetooth kernel modules..."
    modprobe bluetooth 2>/dev/null || true
    modprobe hci_uart 2>/dev/null || true
    modprobe btbcm 2>/dev/null || true
    sleep 2
    if [ -d "/sys/class/bluetooth" ]; then
        echo "  ✓ Created after loading modules"
    else
        echo "  ✗ Still missing - hardware may not be initialized"
        echo "  → This will prevent BlueZ service from starting"
    fi
fi

# Check 1: BlueZ service status
echo ""
echo "[1/8] Checking BlueZ service status..."
if systemctl is-active --quiet bluetooth; then
    echo "  ✓ BlueZ service is running"
else
    echo "  ✗ BlueZ service is NOT running"
    echo "  → Checking if service is skipped..."
    SERVICE_STATUS=$(systemctl status bluetooth --no-pager 2>&1 | grep -i "skipped\|failed\|inactive" | head -1)
    if echo "$SERVICE_STATUS" | grep -qi "skipped"; then
        echo "  ⚠ Service is being skipped (likely /sys/class/bluetooth missing)"
        echo "  → Attempting to fix..."
        modprobe bluetooth hci_uart btbcm
        sleep 2
        systemctl start hciuart.service 2>/dev/null || true
    fi
    echo "  → Starting BlueZ service..."
    systemctl start bluetooth
    sleep 5
    if systemctl is-active --quiet bluetooth; then
        echo "  ✓ BlueZ service started"
    else
        echo "  ✗ Failed to start BlueZ service"
        echo "  → Service status:"
        systemctl status bluetooth --no-pager -l | head -10
        exit 1
    fi
fi

# Check 2: BlueZ adapter exists
echo ""
echo "[2/8] Checking BLE adapter exists..."
if hciconfig hci0 &>/dev/null; then
    echo "  ✓ BLE adapter hci0 found"
else
    echo "  ✗ BLE adapter hci0 NOT found"
    echo "  → Available adapters:"
    hciconfig | grep -E "^hci" || echo "    No adapters found"
    exit 1
fi

# Check 3: Adapter is up
echo ""
echo "[3/8] Checking adapter is up..."
ADAPTER_STATE=$(hciconfig hci0 | grep -E "UP|DOWN" | head -n 1)
if echo "$ADAPTER_STATE" | grep -q "UP"; then
    echo "  ✓ Adapter is UP"
else
    echo "  ✗ Adapter is DOWN"
    echo "  → Bringing adapter up..."
    hciconfig hci0 up
    sleep 2
    if hciconfig hci0 | grep -q "UP"; then
        echo "  ✓ Adapter is now UP"
    else
        echo "  ✗ Failed to bring adapter up"
        exit 1
    fi
fi

# Check 4: Adapter has page scan enabled
echo ""
echo "[4/8] Checking page scan is enabled..."
if hciconfig hci0 | grep -q "PSCAN"; then
    echo "  ✓ Page scan is enabled"
else
    echo "  ✗ Page scan is NOT enabled"
    echo "  → Enabling page scan..."
    hciconfig hci0 piscan
    sleep 1
    if hciconfig hci0 | grep -q "PSCAN"; then
        echo "  ✓ Page scan is now enabled"
    else
        echo "  ✗ Failed to enable page scan"
        exit 1
    fi
fi

# Check 5: Adapter is powered on
echo ""
echo "[5/8] Checking adapter is powered on..."
POWER_STATE=$(bluetoothctl show 2>/dev/null | grep "Powered" | awk '{print $2}')
if [ "$POWER_STATE" = "yes" ]; then
    echo "  ✓ Adapter is powered on"
else
    echo "  ✗ Adapter is NOT powered on"
    echo "  → Powering on adapter..."
    bluetoothctl power on
    sleep 3
    POWER_STATE=$(bluetoothctl show 2>/dev/null | grep "Powered" | awk '{print $2}')
    if [ "$POWER_STATE" = "yes" ]; then
        echo "  ✓ Adapter is now powered on"
    else
        echo "  ✗ Failed to power on adapter"
        exit 1
    fi
fi

# Check 6: Wait for full initialization
echo ""
echo "[6/8] Waiting for BlueZ to fully initialize..."
echo "  → Waiting 10 seconds for full initialization..."
sleep 10

# Verify adapter is still ready
POWER_STATE=$(bluetoothctl show 2>/dev/null | grep "Powered" | awk '{print $2}')
if [ "$POWER_STATE" = "yes" ]; then
    echo "  ✓ Adapter still powered after wait"
else
    echo "  ✗ Adapter lost power during wait"
    echo "  → Powering on again..."
    bluetoothctl power on
    sleep 3
fi

# Check 7: Final verification
echo ""
echo "[7/8] Final verification..."
ADAPTER_INFO=$(hciconfig hci0 2>/dev/null)
if echo "$ADAPTER_INFO" | grep -q "UP RUNNING PSCAN"; then
    echo "  ✓ Adapter is fully ready"
    echo ""
    echo "Adapter Status:"
    echo "$ADAPTER_INFO" | head -n 3
    echo ""
    echo "Bluetooth Controller Info:"
    bluetoothctl show 2>/dev/null | grep -E "Powered|Discoverable|Pairable" || true
    echo ""
    echo "=========================================="
    echo "✓ BlueZ BLE adapter is ready for commissioning"
    echo "=========================================="
    exit 0
else
    echo "  ✗ Adapter is NOT fully ready"
    echo ""
    echo "Current adapter state:"
    echo "$ADAPTER_INFO"
    echo ""
    echo "=========================================="
    echo "✗ BlueZ BLE adapter is NOT ready"
    echo "=========================================="
    exit 1
fi

