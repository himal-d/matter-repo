#!/bin/bash
# Quick script to check wpan0 status and diagnose issues

echo "=== wpan0 Interface Diagnostic ==="
echo ""

echo "1. Interface Status:"
if ip link show wpan0 &>/dev/null 2>&1; then
    echo "  ✓ wpan0 exists"
    ip link show wpan0
    echo ""
    ip addr show wpan0
else
    echo "  ✗ wpan0 does not exist"
fi
echo ""

echo "2. otbr-agent Process:"
if pgrep -x otbr-agent >/dev/null; then
    echo "  ✓ otbr-agent is running"
    ps aux | grep "[o]tbr-agent" | head -1
else
    echo "  ✗ otbr-agent is not running"
fi
echo ""

echo "3. Kernel Modules:"
for mod in mac802154 ieee802154 tun; do
    if lsmod | grep -q "^$mod "; then
        echo "  ✓ $mod loaded"
    else
        echo "  ✗ $mod not loaded"
    fi
done
echo ""

echo "4. RCP Device:"
if [ -c /dev/ttyACM0 ]; then
    echo "  ✓ /dev/ttyACM0 exists"
    ls -l /dev/ttyACM0
else
    echo "  ✗ /dev/ttyACM0 not found"
fi
echo ""

echo "5. otbr-agent Log:"
if [ -f /tmp/otbr-agent.log ]; then
    echo "  Log file exists, last 20 lines:"
    tail -20 /tmp/otbr-agent.log | sed 's/^/    /'
else
    echo "  ✗ Log file not found"
fi
echo ""

echo "6. Service Status:"
systemctl status ot-br-posix.service --no-pager -l | head -15
echo ""

echo "=== Diagnostic Complete ==="
echo ""
echo "If wpan0 doesn't exist:"
echo "  1. Check otbr-agent is running: pgrep -x otbr-agent"
echo "  2. Check logs: journalctl -u ot-br-posix.service -f"
echo "  3. Check otbr-agent log: cat /tmp/otbr-agent.log"
echo "  4. Try manual start: /usr/local/bin/otbr-agent-wrapper.sh"

