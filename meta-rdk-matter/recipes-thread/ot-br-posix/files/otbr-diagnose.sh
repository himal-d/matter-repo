#!/bin/bash
# OpenThread Border Router Diagnostic Script

echo "=== OTBR Diagnostic Information ==="
echo ""

echo "1. RCP Device Check:"
if [ -e /dev/ttyACM0 ]; then
    echo "  ✓ /dev/ttyACM0 exists"
    ls -l /dev/ttyACM0
    echo "  Permissions: $(stat -c '%a' /dev/ttyACM0)"
else
    echo "  ✗ /dev/ttyACM0 not found"
fi
echo ""

echo "2. otbr-agent Binary:"
if [ -x /usr/sbin/otbr-agent ]; then
    echo "  ✓ otbr-agent exists and is executable"
    file /usr/sbin/otbr-agent
    ldd /usr/sbin/otbr-agent 2>/dev/null | head -5 || echo "  (ldd check failed)"
else
    echo "  ✗ otbr-agent not found or not executable"
fi
echo ""

echo "3. Network Interfaces:"
echo "  Available interfaces:"
ip link show | grep -E "^[0-9]+:" | awk '{print "    " $2}'
echo ""
echo "  Bridge interface check (eth0, wlan0, br0):"
for iface in eth0 wlan0 br0; do
    if ip link show "$iface" &>/dev/null 2>&1; then
        echo "    ✓ $iface exists"
    else
        echo "    ✗ $iface not found"
    fi
done
echo ""

echo "4. Kernel Modules:"
for mod in mac802154 ieee802154 tun; do
    if lsmod | grep -q "^$mod "; then
        echo "  ✓ $mod loaded"
    else
        echo "  ✗ $mod not loaded"
    fi
done
echo ""

echo "5. Services Status:"
systemctl is-active ot-daemon.service >/dev/null 2>&1 && echo "  ✓ ot-daemon active" || echo "  ✗ ot-daemon not active"
systemctl is-active ot-br-posix.service >/dev/null 2>&1 && echo "  ✓ ot-br-posix active" || echo "  ✗ ot-br-posix not active"
echo ""

echo "6. Test otbr-agent manually:"
echo "  Attempting to run otbr-agent with test arguments..."
timeout 2 /usr/sbin/otbr-agent --help 2>&1 | head -10 || echo "  ✗ otbr-agent failed to run"
echo ""

echo "7. Recent otbr-agent logs:"
if [ -f /tmp/otbr-agent.log ]; then
    echo "  Last 10 lines:"
    tail -10 /tmp/otbr-agent.log
else
    echo "  No log file found at /tmp/otbr-agent.log"
fi
echo ""

echo "8. Systemd service logs:"
journalctl -u ot-br-posix.service -n 5 --no-pager | tail -5
echo ""

echo "=== Diagnostic Complete ==="

