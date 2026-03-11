#!/bin/bash
# Matter Controller Setup Script
# Run this script to set up the Matter Controller on Raspberry Pi

set -e

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Matter Controller Setup for Raspberry Pi"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    echo "❌ Please run as root (use sudo)"
    exit 1
fi

# Step 1: Create storage directory
echo "Step 1: Creating storage directory..."
mkdir -p /var/lib/matter-controller
chown root:root /var/lib/matter-controller
chmod 755 /var/lib/matter-controller
echo "✓ Storage directory created: /var/lib/matter-controller"
echo ""

# Step 2: Install systemd service
echo "Step 2: Installing systemd service..."
if [ -f /lib/systemd/system/matter-controller.service ]; then
    echo "✓ Service file already exists"
else
    echo "⚠️  Service file not found. Please ensure chip-all-clusters-app package is installed."
    echo "   The service file should be at: /lib/systemd/system/matter-controller.service"
fi
echo ""

# Step 3: Install management script
echo "Step 3: Installing management script..."
if [ -f /usr/bin/matter-controller-ctl ]; then
    chmod +x /usr/bin/matter-controller-ctl
    echo "✓ Management script installed: /usr/bin/matter-controller-ctl"
else
    echo "⚠️  Management script not found. Please ensure chip-all-clusters-app package is installed."
    echo "   The script should be at: /usr/bin/matter-controller-ctl"
fi
echo ""

# Step 4: Reload systemd
echo "Step 4: Reloading systemd..."
systemctl daemon-reload
echo "✓ Systemd reloaded"
echo ""

# Step 5: Check prerequisites
echo "Step 5: Checking prerequisites..."
PREREQS_OK=true

# Check OTBR
if systemctl is-active --quiet ot-br-posix; then
    echo "✓ OTBR service is running"
else
    echo "✗ OTBR service is not running"
    PREREQS_OK=false
fi

# Check Thread interface
if ip link show wpan0 >/dev/null 2>&1; then
    echo "✓ Thread interface (wpan0) exists"
else
    echo "✗ Thread interface (wpan0) missing"
    PREREQS_OK=false
fi

# Check BlueZ
if systemctl is-active --quiet bluetooth; then
    echo "✓ BlueZ service is running"
else
    echo "✗ BlueZ service is not running"
    PREREQS_OK=false
fi

# Check BLE adapter
if hciconfig hci0 2>/dev/null | grep -q "UP RUNNING"; then
    echo "✓ BLE adapter is ready"
else
    echo "✗ BLE adapter is not ready"
    PREREQS_OK=false
fi

# Check Avahi
if systemctl is-active --quiet avahi-daemon; then
    echo "✓ Avahi (mDNS) is running"
else
    echo "✗ Avahi (mDNS) is not running"
    PREREQS_OK=false
fi

echo ""

if [ "$PREREQS_OK" = false ]; then
    echo "⚠️  Some prerequisites are missing. Please fix them before starting the controller."
    echo ""
    echo "Common fixes:"
    echo "  - Start OTBR: systemctl start ot-br-posix"
    echo "  - Start BlueZ: systemctl start bluetooth"
    echo "  - Start Avahi: systemctl start avahi-daemon"
    echo "  - Enable BLE: hciconfig hci0 up && bluetoothctl power on"
    echo ""
    read -p "Continue anyway? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# Step 6: Enable service
echo "Step 6: Enabling Matter Controller service..."
systemctl enable matter-controller
echo "✓ Service enabled (will start on boot)"
echo ""

# Step 7: Start service
echo "Step 7: Starting Matter Controller..."
read -p "Start the controller now? (Y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Nn]$ ]]; then
    systemctl start matter-controller
    sleep 3
    systemctl status matter-controller --no-pager -l || true
    echo ""
    echo "✓ Controller started"
else
    echo "⚠️  Controller not started. Start manually with: systemctl start matter-controller"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Setup Complete!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Next steps:"
echo "  1. Check status: matter-controller-ctl status"
echo "  2. View logs: matter-controller-ctl logs"
echo "  3. Run health check: matter-controller-ctl health-check"
echo "  4. Commission a device using chip-tool or mobile app"
echo ""
echo "Management commands:"
echo "  matter-controller-ctl start      - Start controller"
echo "  matter-controller-ctl stop       - Stop controller"
echo "  matter-controller-ctl restart    - Restart controller"
echo "  matter-controller-ctl status     - Show detailed status"
echo "  matter-controller-ctl logs       - View logs"
echo ""

