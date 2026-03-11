#!/bin/bash
set -e

# ==========================
# Configuration
# ==========================
# Option B2: Detect RCP device with preference for external RCP
# This eliminates Thread/BLE contention on Pi 4
detect_rcp_device() {
    # Priority 1: Check for /dev/ot-rcp symlink (created by udev rules for external RCP)
    if [ -e /dev/ot-rcp ]; then
        echo "/dev/ot-rcp"
        return 0
    fi
    
    # Priority 2: Check common external RCP devices
    # nRF52840, ESP32-H2, EFR32MG24 typically appear as ttyACM0 or ttyACM1
    for dev in /dev/ttyACM1 /dev/ttyACM0 /dev/ttyUSB0; do
        if [ -e "$dev" ] && [ -c "$dev" ]; then
            # Verify it's not onboard BLE (Broadcom)
            local vendor=$(udevadm info --query=property --name="$dev" 2>/dev/null | grep "ID_VENDOR_ID" | cut -d'=' -f2)
            if [ "$vendor" != "0a5c" ]; then  # 0a5c is Broadcom (Pi 4 onboard)
                echo "$dev"
                return 0
            fi
        fi
    done
    
    # Use environment variable if set
    if [ -n "$RCP_DEVICE" ]; then
        echo "$RCP_DEVICE"
        return 0
    fi
    
    # Fallback: Use default (may be onboard, but better than nothing)
    echo "/dev/ttyACM0"
}

# Detect bridge interface for Raspberry Pi 4 / RDK-B
detect_bridge_interface() {
    # Use environment variable if set (highest priority)
    if [ -n "$BRIDGE_IF" ]; then
        if ip link show "$BRIDGE_IF" &>/dev/null 2>&1; then
            echo "$BRIDGE_IF"
            return 0
        fi
    fi
    
    # Check for common bridge interfaces (RDK-B typically uses br0 or brlan0)
    # Priority: br0 > brlan0 > wlan0 > eth0
    for iface in br0 brlan0 wlan0 eth0; do
        if ip link show "$iface" &>/dev/null 2>&1; then
            echo "$iface"
            return 0
        fi
    done
    
    # If nothing found, return br0 as default (will fail later with better error)
    echo "br0"
}

RCP_DEVICE=${RCP_DEVICE:-$(detect_rcp_device)}
WPAN_IF="wpan0"
BR_IF=$(detect_bridge_interface)
OTBR_AGENT_BIN="/usr/sbin/otbr-agent"

# ==========================
# Helper Functions
# ==========================
log() {
    echo "[otbr-wrapper] $*"
}

wait_for_device() {
    local dev=$1
    local retries=${2:-30}
    for i in $(seq 1 "$retries"); do
        if [ -e "$dev" ]; then
            log "Found device: $dev"
            return 0
        fi
        sleep 1
    done
    log "Error: Device $dev not found after $retries seconds"
    exit 1
}

wait_for_interface() {
    local ifname=$1
    local retries=${2:-30}
    for i in $(seq 1 "$retries"); do
        if ip link show "$ifname" &>/dev/null 2>&1; then
            log "Interface $ifname found after $i seconds"
            return 0
        fi
        # Show progress every 10 seconds
        if [ $((i % 10)) -eq 0 ]; then
            log "Still waiting for $ifname... ($i/$retries seconds)"
        fi
        sleep 1
    done
    log "Error: Interface $ifname not found after $retries seconds"
    return 1
}

kill_stale_processes() {
    log "Cleaning up stale ot-daemon/otbr-agent..."
    pkill -9 -x ot-daemon || true
    pkill -9 -x otbr-agent || true
}

# ==========================
# Main Script
# ==========================
log "Waiting for RCP at $RCP_DEVICE..."
wait_for_device "$RCP_DEVICE"

# Check device permissions
if [ ! -r "$RCP_DEVICE" ] || [ ! -w "$RCP_DEVICE" ]; then
    log "Warning: RCP device $RCP_DEVICE may not have read/write permissions"
    log "Current permissions: $(ls -l $RCP_DEVICE)"
    log "Attempting to fix permissions..."
    chmod 666 "$RCP_DEVICE" 2>/dev/null || true
fi

# Verify kernel modules are loaded
log "Checking kernel modules..."
for mod in mac802154 ieee802154 tun; do
    if ! lsmod | grep -q "^$mod "; then
        log "Loading kernel module: $mod"
        modprobe "$mod" 2>/dev/null || log "Warning: Failed to load $mod"
    fi
done

kill_stale_processes

# Wait a moment for processes to fully terminate
sleep 1

# Verify otbr-agent exists and is executable
if [ ! -x "$OTBR_AGENT_BIN" ]; then
    log "Error: otbr-agent not found or not executable at $OTBR_AGENT_BIN"
    exit 1
fi

# Check if bridge interface exists (otbr-agent may fail if it doesn't)
if ! ip link show "$BR_IF" &>/dev/null 2>&1; then
    log "Error: Bridge interface $BR_IF not found!"
    log "Available interfaces:"
    ip link show | grep -E "^[0-9]+:" | awk '{print $2}' | sed 's/:$//' | while read iface; do
        log "  $iface"
    done
    log "Please set BRIDGE_IF environment variable or fix interface detection"
    exit 1
fi

log "Using bridge interface: $BR_IF"

log "Starting otbr-agent..."
log "Command: $OTBR_AGENT_BIN -I $WPAN_IF -B $BR_IF -d 7 spinel+hdlc+uart://$RCP_DEVICE"

# Create log file with proper permissions
LOG_FILE="/tmp/otbr-agent.log"
touch "$LOG_FILE"
chmod 644 "$LOG_FILE"

# Start otbr-agent in background and capture output
$OTBR_AGENT_BIN -I "$WPAN_IF" -B "$BR_IF" -d 7 spinel+hdlc+uart://"$RCP_DEVICE" > "$LOG_FILE" 2>&1 &
OTBR_PID=$!

# Give otbr-agent more time to initialize and connect to RCP
log "Waiting for otbr-agent to initialize (10 seconds)..."
sleep 10

# Check if process is still running
if ! kill -0 $OTBR_PID 2>/dev/null; then
    # Get exit code
    wait $OTBR_PID 2>/dev/null
    EXIT_CODE=$?
    
    log "Error: otbr-agent failed to start (PID: $OTBR_PID, Exit code: $EXIT_CODE)"
    log "Log file location: $LOG_FILE"
    
    # Check and display log file
    if [ -f "$LOG_FILE" ]; then
        if [ -s "$LOG_FILE" ]; then
            log "Log file contents:"
            cat "$LOG_FILE" | while read line; do
                log "  $line"
            done
        else
            log "Log file exists but is empty"
        fi
    else
        log "Log file does not exist"
    fi
    
    # Try to run otbr-agent directly to capture immediate error
    log "Attempting direct execution to capture error:"
    $OTBR_AGENT_BIN -I "$WPAN_IF" -B "$BR_IF" -d 7 spinel+hdlc+uart://"$RCP_DEVICE" 2>&1 | head -30 | while read line; do
        log "  $line"
    done || true
    
    exit 1
fi

log "otbr-agent started with PID: $OTBR_PID"

# Check if otbr-agent is still running
if ! kill -0 $OTBR_PID 2>/dev/null; then
    log "Error: otbr-agent process died after starting"
    if [ -f "$LOG_FILE" ] && [ -s "$LOG_FILE" ]; then
        log "Recent log entries:"
        tail -30 "$LOG_FILE" | while read line; do
            log "  $line"
        done
    fi
    exit 1
fi

# Wait for wpan0 to appear (created by otbr-agent)
# Give it more time - RCP connection can take 10-30 seconds
log "Waiting for $WPAN_IF interface (this may take 30 seconds)..."
if wait_for_interface "$WPAN_IF" 60; then
    log "Thread interface $WPAN_IF is ready"
    # Show interface details
    ip link show "$WPAN_IF" | head -5 | while read line; do
        log "  $line"
    done
else
    log "Error: Thread interface $WPAN_IF not created after 60 seconds"
    log "Checking otbr-agent status..."
    
    # Check if process is still running
    if kill -0 $OTBR_PID 2>/dev/null; then
        log "otbr-agent is still running (PID: $OTBR_PID)"
        log "This may indicate RCP communication issue"
    else
        log "otbr-agent process died"
        wait $OTBR_PID 2>/dev/null
        EXIT_CODE=$?
        log "Exit code: $EXIT_CODE"
    fi
    
    # Show recent logs
    if [ -f "$LOG_FILE" ] && [ -s "$LOG_FILE" ]; then
        log "Recent otbr-agent logs:"
        tail -50 "$LOG_FILE" | while read line; do
            log "  $line"
        done
    fi
    
    # Check kernel modules
    log "Checking kernel modules:"
    for mod in mac802154 ieee802154 tun; do
        if lsmod | grep -q "^$mod "; then
            log "  ✓ $mod loaded"
        else
            log "  ✗ $mod not loaded"
        fi
    done
    
    # Check RCP device
    log "Checking RCP device:"
    if [ -c "$RCP_DEVICE" ]; then
        log "  ✓ $RCP_DEVICE exists and is a character device"
        log "  Permissions: $(ls -l $RCP_DEVICE)"
    else
        log "  ✗ $RCP_DEVICE issue"
    fi
    
    kill $OTBR_PID 2>/dev/null || true
    exit 1
fi

log "OpenThread Border Router setup complete."
log "otbr-agent running with PID: $OTBR_PID"

# Wait for otbr-agent process (this keeps the service running)
wait $OTBR_PID
EXIT_CODE=$?

log "otbr-agent exited with code: $EXIT_CODE"
exit $EXIT_CODE

