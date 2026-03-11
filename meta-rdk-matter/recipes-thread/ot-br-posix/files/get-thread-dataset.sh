#!/bin/bash
# Get OpenThread operational dataset for Matter Thread commissioning
# Usage: get-thread-dataset.sh

set -e

echo "Getting OpenThread operational dataset..."
echo ""

# Check if ot-ctl is available
if ! command -v ot-ctl &> /dev/null; then
    echo "Error: ot-ctl not found. Is ot-daemon running?"
    exit 1
fi

# Get active operational dataset
DATASET=$(ot-ctl dataset active -x 2>/dev/null | grep -v "Done" | tr -d '\n' | tr -d ' ')

if [ -z "$DATASET" ]; then
    echo "Error: Could not get operational dataset. Is Thread network started?"
    echo "Try: ot-ctl thread start"
    exit 1
fi

echo "Operational Dataset (hex):"
echo "$DATASET"
echo ""
echo "Use this for BLE-Thread commissioning:"
echo "chip-tool pairing ble-thread <NODE_ID> hex:$DATASET <PIN_CODE> <DISCRIMINATOR>"
echo ""
echo "Or use the helper script:"
echo "matter-commission.sh thread-ble <NODE_ID> <PIN_CODE> <DISCRIMINATOR>"
echo ""

