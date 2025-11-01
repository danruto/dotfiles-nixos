#!/usr/bin/env bash
# Script to force Thunderbolt display reconnection without physical replug

set -e

echo "🔌 Forcing Thunderbolt display reconnection..."

# Method 1: PCI rescan (triggers hardware re-detection)
echo "Step 1: Triggering PCI bus rescan..."
echo 1 | sudo tee /sys/bus/pci/rescan > /dev/null

sleep 2

# Method 2: Check if displays are detected
echo "Step 2: Checking for connected displays..."
DISPLAY_COUNT=$(ls /sys/class/drm/card*/card*-DP-*/status 2>/dev/null | xargs cat 2>/dev/null | grep -c "^connected" || echo "0")

if [ "$DISPLAY_COUNT" -gt "0" ]; then
    echo "✅ Success! $DISPLAY_COUNT external display(s) detected"
    boltctl list | grep -A 10 "DELL"
else
    echo "⚠️  No displays detected yet. Trying Thunderbolt device reset..."

    # Method 3: Reset Thunderbolt authorization
    MONITOR_UUID="af758780-0033-f9cc-ffff-ffffffffffff"

    # Forget and re-enroll the device
    boltctl forget "$MONITOR_UUID" 2>/dev/null || true
    sleep 1
    boltctl enroll "$MONITOR_UUID" 2>/dev/null || echo "Device already enrolled"

    sleep 2
    echo "Rechecking displays..."
    DISPLAY_COUNT=$(ls /sys/class/drm/card*/card*-DP-*/status 2>/dev/null | xargs cat 2>/dev/null | grep -c "^connected" || echo "0")

    if [ "$DISPLAY_COUNT" -gt "0" ]; then
        echo "✅ Success after reset! $DISPLAY_COUNT external display(s) detected"
    else
        echo "❌ Still no displays. You may need to physically replug the cable."
    fi
fi
