#!/bin/bash
# Select external BLE adapter for Matter commissioning
# Disables onboard adapter if external adapter is present
# Production workaround for Raspberry Pi 4 BCM43455 BLE issues

ONBOARD_ADAPTER="hci0"
EXTERNAL_ADAPTER="hci1"

# Function to check if adapter exists and is external
is_external_adapter() {
    local adapter=$1
    if ! hciconfig "$adapter" &>/dev/null 2>/dev/null; then
        return 1
    fi
    
    # Check udev properties
    local udev_info=$(udevadm info --query=property --name="$adapter" 2>/dev/null)
    if echo "$udev_info" | grep -q "ID_BT_TYPE=external"; then
        return 0
    fi
    
    # Fallback: check if it's not Broadcom (onboard)
    local vendor=$(echo "$udev_info" | grep "ID_VENDOR_ID" | cut -d'=' -f2)
    if [ "$vendor" != "0a5c" ]; then  # 0a5c is Broadcom
        return 0
    fi
    
    return 1
}

# Check for external adapter
if is_external_adapter "$EXTERNAL_ADAPTER"; then
    echo "External BLE adapter found: $EXTERNAL_ADAPTER"
    
    # Disable onboard adapter
    if hciconfig "$ONBOARD_ADAPTER" &>/dev/null 2>/dev/null; then
        echo "Disabling onboard BLE adapter: $ONBOARD_ADAPTER"
        hciconfig "$ONBOARD_ADAPTER" down 2>/dev/null || true
        bluetoothctl -- adapter "$ONBOARD_ADAPTER" power off 2>/dev/null || true
    fi
    
    # Enable external adapter
    echo "Enabling external BLE adapter: $EXTERNAL_ADAPTER"
    hciconfig "$EXTERNAL_ADAPTER" up 2>/dev/null || true
    bluetoothctl -- adapter "$EXTERNAL_ADAPTER" power on 2>/dev/null || true
    hciconfig "$EXTERNAL_ADAPTER" piscan 2>/dev/null || true
    
    echo "✓ Using external BLE adapter: $EXTERNAL_ADAPTER"
    exit 0
else
    echo "No external BLE adapter found, using onboard: $ONBOARD_ADAPTER"
    exit 1
fi

