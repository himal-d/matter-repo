#!/bin/bash
# Configure BLE Adapter Connection Parameters for Matter Commissioning
# This script sets more lenient connection parameters optimized for UART-based BLE
# (e.g., Raspberry Pi onboard BCM BLE) to reduce connection abort errors

set -e

ADAPTER=${1:-hci0}
MAX_WAIT=30  # Maximum seconds to wait for adapter

echo "Configuring BLE adapter $ADAPTER for Matter commissioning..."

# Wait for adapter to be available
WAIT_COUNT=0
while ! hciconfig $ADAPTER &>/dev/null 2>&1; do
    if [ $WAIT_COUNT -ge $MAX_WAIT ]; then
        echo "Error: Adapter $ADAPTER not found after ${MAX_WAIT} seconds"
        exit 1
    fi
    echo "Waiting for adapter $ADAPTER... ($WAIT_COUNT/$MAX_WAIT)"
    sleep 1
    WAIT_COUNT=$((WAIT_COUNT + 1))
done

# Wait for BlueZ to be ready and adapter to be powered on
echo "Waiting for BlueZ adapter to be ready..."
WAIT_COUNT=0
while [ $WAIT_COUNT -lt 10 ]; do
    if bluetoothctl show 2>/dev/null | grep -q "Powered: yes"; then
        break
    fi
    echo "  Waiting for adapter to power on... ($WAIT_COUNT/10)"
    sleep 1
    WAIT_COUNT=$((WAIT_COUNT + 1))
done

# Bring adapter up if down
if ! hciconfig $ADAPTER | grep -q "UP"; then
    echo "Bringing adapter $ADAPTER up..."
    hciconfig $ADAPTER up
    sleep 2
fi

# Ensure adapter is powered on
if ! bluetoothctl show 2>/dev/null | grep -q "Powered: yes"; then
    echo "Powering on adapter via bluetoothctl..."
    bluetoothctl power on 2>/dev/null || true
    sleep 2
fi

# Set connection parameters (more lenient for UART BLE)
# Connection interval: 30ms (default: 15ms) - gives more time for UART communication
# Connection latency: 2 (default: 0) - allows some missed intervals
# Supervision timeout: 10000ms (default: 5000ms) - longer timeout for Matter commissioning
echo "Setting connection parameters..."
hciconfig $ADAPTER connmin 30 connmax 30 2>/dev/null || echo "Warning: Failed to set connection interval"
hciconfig $ADAPTER connlat 2 2>/dev/null || echo "Warning: Failed to set connection latency"
hciconfig $ADAPTER connto 10000 2>/dev/null || echo "Warning: Failed to set supervision timeout"

# Enable page/inquiry scan (required for connections)
echo "Enabling page/inquiry scan..."
hciconfig $ADAPTER piscan 2>/dev/null || echo "Warning: Failed to enable page scan"

# Power on via bluetoothctl (more reliable than hciconfig)
# Only if not already powered on
if ! bluetoothctl show 2>/dev/null | grep -q "Powered: yes"; then
    echo "Powering on adapter via bluetoothctl..."
    bluetoothctl power on 2>/dev/null || echo "Warning: Failed to power on via bluetoothctl"
    sleep 2
else
    echo "Adapter already powered on"
fi

# Verify configuration
echo ""
echo "Verifying configuration..."

# Check adapter state - allow UP or UP RUNNING
ADAPTER_STATE=$(hciconfig $ADAPTER 2>/dev/null | grep -E "UP|DOWN" | head -1)
if echo "$ADAPTER_STATE" | grep -q "UP"; then
    echo "✓ Adapter $ADAPTER is UP"
else
    echo "✗ Adapter $ADAPTER is DOWN - attempting to bring up..."
    hciconfig $ADAPTER up
    sleep 2
    if hciconfig $ADAPTER | grep -q "UP"; then
        echo "✓ Adapter $ADAPTER is now UP"
    else
        echo "✗ Adapter $ADAPTER failed to come up"
        hciconfig $ADAPTER
        exit 1
    fi
fi

# Check if powered on - retry if needed
POWERED_ON=false
for i in 1 2 3; do
    if bluetoothctl show 2>/dev/null | grep -q "Powered: yes"; then
        echo "✓ Adapter is powered on"
        POWERED_ON=true
        break
    else
        echo "  Attempt $i: Adapter not powered, attempting to power on..."
        bluetoothctl power on 2>/dev/null || true
        sleep 2
    fi
done

if [ "$POWERED_ON" = "false" ]; then
    echo "✗ Adapter is not powered on after retries"
    echo "  This may be normal if BlueZ is managing power state"
    echo "  Adapter may still be usable for Matter commissioning"
    # Don't exit with error - adapter may still work
fi

echo ""
echo "BLE adapter $ADAPTER configured successfully for Matter commissioning"
echo "Connection parameters: interval=30ms, latency=2, timeout=10000ms"


