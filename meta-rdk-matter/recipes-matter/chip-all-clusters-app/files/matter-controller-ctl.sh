#!/bin/bash
# Matter Controller Management Script
# Usage: matter-controller-ctl <command> [args]

set -e

CONTROLLER_SERVICE="matter-controller"
CONTROLLER_PID_FILE="/run/matter-controller.pid"
STORAGE_DIR="/var/lib/matter-controller"

# Determine if running as root (for sudo usage)
if [ "$EUID" -eq 0 ]; then
    SUDO_CMD=""
else
    SUDO_CMD="sudo"
fi

case "$1" in
    start)
        echo "Starting Matter Controller..."
        systemctl start $CONTROLLER_SERVICE
        sleep 2
        systemctl status $CONTROLLER_SERVICE --no-pager -l
        ;;
    
    stop)
        echo "Stopping Matter Controller..."
        systemctl stop $CONTROLLER_SERVICE
        ;;
    
    restart)
        echo "Restarting Matter Controller..."
        systemctl restart $CONTROLLER_SERVICE
        sleep 2
        systemctl status $CONTROLLER_SERVICE --no-pager -l
        ;;
    
    status)
        systemctl status $CONTROLLER_SERVICE --no-pager -l
        echo ""
        echo "Service Status:"
        if systemctl is-active --quiet $CONTROLLER_SERVICE; then
            echo "  ✓ Controller is running"
        else
            echo "  ✗ Controller is not running"
        fi
        
        if [ -f "$CONTROLLER_PID_FILE" ]; then
            PID=$(cat $CONTROLLER_PID_FILE)
            if ps -p $PID > /dev/null 2>&1; then
                echo "  ✓ PID file exists and process is running (PID: $PID)"
            else
                echo "  ✗ PID file exists but process is not running"
            fi
        else
            echo "  ⚠ PID file does not exist"
        fi
        
        echo ""
        echo "Storage:"
        if [ -d "$STORAGE_DIR" ]; then
            echo "  ✓ Storage directory exists: $STORAGE_DIR"
            echo "  Files:"
            ls -lh $STORAGE_DIR/ 2>/dev/null | tail -n +2 | sed 's/^/    /'
        else
            echo "  ✗ Storage directory missing: $STORAGE_DIR"
        fi
        
        echo ""
        echo "BLE Status:"
        if hciconfig hci0 2>/dev/null | grep -q "UP RUNNING"; then
            echo "  ✓ BLE adapter is up and running"
        else
            echo "  ✗ BLE adapter is not ready"
        fi
        
        echo ""
        echo "Thread Status:"
        if ip link show wpan0 >/dev/null 2>&1; then
            echo "  ✓ Thread interface (wpan0) exists"
            THREAD_STATE=$(ot-ctl state 2>/dev/null | grep -v "Done" | head -n 1 | tr -d '\r\n')
            if [ -n "$THREAD_STATE" ]; then
                echo "  Thread state: $THREAD_STATE"
            fi
        else
            echo "  ✗ Thread interface (wpan0) missing"
        fi
        ;;
    
    logs)
        if [ -n "$2" ]; then
            journalctl -u $CONTROLLER_SERVICE -n "$2" --no-pager
        else
            journalctl -u $CONTROLLER_SERVICE -f
        fi
        ;;
    
    open-window)
        echo "Opening commissioning window..."
        echo "⚠️  Note: Commissioning window management requires controller D-Bus API"
        echo "   For now, the commissioning window should open automatically on startup"
        echo "   Check logs for commissioning window status:"
        echo "   matter-controller-ctl logs 50"
        ;;
    
    close-window)
        echo "Closing commissioning window..."
        echo "⚠️  Note: Commissioning window management requires controller D-Bus API"
        ;;
    
    list-fabrics)
        echo "Listing commissioned fabrics..."
        if [ -d "$STORAGE_DIR" ]; then
            echo "Storage directory: $STORAGE_DIR"
            echo ""
            if [ -f "$STORAGE_DIR/chip_kvs" ]; then
                echo "✓ Fabric storage file exists"
                FILE_SIZE=$(stat -c%s "$STORAGE_DIR/chip_kvs" 2>/dev/null || echo "0")
                if [ "$FILE_SIZE" -gt 0 ]; then
                    echo "  File size: $FILE_SIZE bytes (contains fabric data)"
                    echo ""
                    echo "To verify commissioned devices, try:"
                    echo "  - Read device attributes: chip-tool onoff read on-off 1 1"
                    echo "  - Read basic info: chip-tool basicinformation read vendor-name 1 1"
                    echo "  - Check storage files: ls -lh $STORAGE_DIR/"
                    echo ""
                    echo "Note: chip-tool is a temporary commissioner - it creates its own controller"
                    echo "      instance for each command and shuts down after completion."
                else
                    echo "  File is empty (no devices commissioned yet)"
                fi
            else
                echo "✗ No fabric storage found"
                echo "  No devices have been commissioned yet"
            fi
        else
            echo "✗ Storage directory not found: $STORAGE_DIR"
            echo "  Run: matter-controller-ctl setup-storage"
        fi
        ;;
    
    enable)
        echo "Enabling Matter Controller on boot..."
        systemctl enable $CONTROLLER_SERVICE
        echo "✓ Controller will start on boot"
        ;;
    
    disable)
        echo "Disabling Matter Controller on boot..."
        systemctl disable $CONTROLLER_SERVICE
        echo "✓ Controller will not start on boot"
        ;;
    
    setup-storage)
        echo "Setting up Matter Controller storage..."
        $SUDO_CMD mkdir -p "$STORAGE_DIR"
        $SUDO_CMD chown root:root "$STORAGE_DIR"
        $SUDO_CMD chmod 755 "$STORAGE_DIR"
        echo "✓ Storage directory created: $STORAGE_DIR"
        echo ""
        echo "Note: Storage permissions will be managed by systemd service"
        ;;
    
    health-check)
        echo "Matter Controller Health Check"
        echo "================================"
        echo ""
        
        HEALTHY=true
        
        # Check service
        if systemctl is-active --quiet $CONTROLLER_SERVICE; then
            echo "✓ Service is running"
        else
            echo "✗ Service is not running"
            HEALTHY=false
        fi
        
        # Check BLE
        if hciconfig hci0 2>/dev/null | grep -q "UP RUNNING"; then
            echo "✓ BLE adapter is ready"
        else
            echo "✗ BLE adapter is not ready"
            HEALTHY=false
        fi
        
        # Check Thread
        if ip link show wpan0 >/dev/null 2>&1; then
            echo "✓ Thread interface exists"
        else
            echo "✗ Thread interface missing"
            HEALTHY=false
        fi
        
        # Check storage
        if [ -d "$STORAGE_DIR" ]; then
            echo "✓ Storage directory exists"
        else
            echo "✗ Storage directory missing"
            HEALTHY=false
        fi
        
        # Check Avahi
        if systemctl is-active --quiet avahi-daemon; then
            echo "✓ Avahi (mDNS) is running"
        else
            echo "✗ Avahi (mDNS) is not running"
            HEALTHY=false
        fi
        
        echo ""
        if [ "$HEALTHY" = true ]; then
            echo "✓ All checks passed - Controller is healthy"
            exit 0
        else
            echo "✗ Some checks failed - Controller may not be fully operational"
            exit 1
        fi
        ;;
    
    *)
        echo "Matter Controller Management"
        echo ""
        echo "Usage: matter-controller-ctl <command> [args]"
        echo ""
        echo "Commands:"
        echo "  start          - Start the Matter Controller service"
        echo "  stop           - Stop the Matter Controller service"
        echo "  restart        - Restart the Matter Controller service"
        echo "  status         - Show detailed service status"
        echo "  logs [n]       - Show service logs (n lines, or follow if omitted)"
        echo "  open-window    - Open commissioning window (placeholder)"
        echo "  close-window   - Close commissioning window (placeholder)"
        echo "  list-fabrics   - List commissioned fabrics"
        echo "  enable         - Enable auto-start on boot"
        echo "  disable        - Disable auto-start on boot"
        echo "  setup-storage  - Create and configure storage directory"
        echo "  health-check   - Run health check on all components"
        echo ""
        echo "Examples:"
        echo "  matter-controller-ctl start"
        echo "  matter-controller-ctl status"
        echo "  matter-controller-ctl logs 100"
        echo "  matter-controller-ctl health-check"
        exit 1
        ;;
esac

