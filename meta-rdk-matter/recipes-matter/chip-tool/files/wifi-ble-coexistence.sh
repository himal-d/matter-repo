#!/bin/bash
# Wi-Fi/BLE Coexistence Control Script
# Temporarily disables Wi-Fi during BLE commissioning to prevent antenna contention
# Production workaround for Raspberry Pi 4 BCM43455 shared antenna issue

WIFI_IF="wlan0"
STATE_FILE="/tmp/wifi-ble-state.json"
TIMEOUT_SEC=120  # Maximum time to keep Wi-Fi disabled

# Function to save Wi-Fi state
save_wifi_state() {
    local was_up=false
    local was_connected=false
    local ssid=""
    
    if ip link show "$WIFI_IF" 2>/dev/null | grep -q "state UP"; then
        was_up=true
    fi
    
    if [ -n "$(iwgetid -r "$WIFI_IF" 2>/dev/null)" ]; then
        was_connected=true
        ssid=$(iwgetid -r "$WIFI_IF" 2>/dev/null)
    fi
    
    cat > "$STATE_FILE" <<EOF
{
    "was_up": $was_up,
    "was_connected": $was_connected,
    "ssid": "$ssid",
    "timestamp": $(date +%s)
}
EOF
}

# Function to restore Wi-Fi state
restore_wifi_state() {
    if [ ! -f "$STATE_FILE" ]; then
        return 0
    fi
    
    local was_up=$(cat "$STATE_FILE" 2>/dev/null | grep -o '"was_up": [^,]*' | cut -d' ' -f2)
    local was_connected=$(cat "$STATE_FILE" 2>/dev/null | grep -o '"was_connected": [^,]*' | cut -d' ' -f2)
    local ssid=$(cat "$STATE_FILE" 2>/dev/null | grep -o '"ssid": "[^"]*"' | cut -d'"' -f4)
    
    if [ "$was_up" = "true" ]; then
        echo "Restoring Wi-Fi interface $WIFI_IF..."
        ip link set "$WIFI_IF" up 2>/dev/null || true
        
        if [ "$was_connected" = "true" ] && [ -n "$ssid" ]; then
            echo "Reconnecting to Wi-Fi network: $ssid"
            # Wait for wpa_supplicant to be ready
            sleep 2
            # Trigger reconnection (wpa_supplicant will auto-reconnect if configured)
            wpa_cli -i "$WIFI_IF" reconnect 2>/dev/null || true
        fi
    fi
    
    rm -f "$STATE_FILE"
}

# Function to disable Wi-Fi
disable_wifi() {
    echo "Disabling Wi-Fi interface $WIFI_IF for BLE commissioning..."
    
    # Save current state
    save_wifi_state
    
    # Bring interface down
    ip link set "$WIFI_IF" down 2>/dev/null || true
    
    # Wait for interface to fully go down
    sleep 1
    
    # Verify it's down
    if ip link show "$WIFI_IF" 2>/dev/null | grep -q "state DOWN"; then
        echo "✓ Wi-Fi disabled successfully"
        return 0
    else
        echo "✗ Failed to disable Wi-Fi"
        return 1
    fi
}

# Function to enable Wi-Fi (with timeout safety)
enable_wifi() {
    echo "Enabling Wi-Fi interface $WIFI_IF..."
    
    # Check if timeout exceeded
    if [ -f "$STATE_FILE" ]; then
        local saved_time=$(cat "$STATE_FILE" 2>/dev/null | grep -o '"timestamp": [^,}]*' | cut -d' ' -f2)
        if [ -n "$saved_time" ]; then
            local current_time=$(date +%s)
            local elapsed=$((current_time - saved_time))
            
            if [ $elapsed -gt $TIMEOUT_SEC ]; then
                echo "⚠️  Wi-Fi was disabled for ${elapsed}s (exceeded ${TIMEOUT_SEC}s timeout)"
            fi
        fi
    fi
    
    restore_wifi_state
}

# Main command handling
case "${1:-}" in
    disable)
        disable_wifi
        ;;
    enable)
        enable_wifi
        ;;
    *)
        echo "Usage: $0 {disable|enable}"
        exit 1
        ;;
esac

