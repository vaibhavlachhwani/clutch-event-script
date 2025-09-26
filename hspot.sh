#!/bin/bash
set -euo pipefail

# -----------------------
# Configure this password
# -----------------------
PASSWORD="12345678"
# -----------------------

usage() {
    cat <<EOF
Usage: $0 <NUMBER> [IFACE]
  <NUMBER> : hotspot number (will create SSID like 'sys<NUMBER>')
  [IFACE]  : optional wireless interface (e.g. wlp2s0). If omitted, script auto-detects.
Example:
  $0 87
  $0 42 wlp2s0
EOF
    exit 1
}

if [ $# -lt 1 ]; then
    usage
fi

SSID="sys$1"
IFACE="${2:-}"

# Check dependencies
for cmd in nmcli iw; do
    if ! command -v $cmd >/dev/null 2>&1; then
        echo "❌ Required command '$cmd' not found. Please install it first."
        exit 2
    fi
done

echo "=== Enabling Wi-Fi radio ==="
nmcli radio wifi on

# If interface given, try to bring it up
if [ -n "$IFACE" ]; then
    echo "Bringing interface $IFACE up..."
    sudo ip link set "$IFACE" up 2>/dev/null || true
fi

echo "=== Starting hotspot with SSID: '$SSID' ==="

if [ -n "$IFACE" ]; then
    sudo nmcli device wifi hotspot ifname "$IFACE" ssid "$SSID" password "$PASSWORD" || true
else
    nmcli device wifi hotspot ssid "$SSID" password "$PASSWORD" || true
fi

sleep 3

# --------- Detect hotspot connection name ---------
HOTSPOT_CONN=$(nmcli -t -f NAME connection show --active | while read NAME; do
    if nmcli -f 802-11-wireless.mode connection show "$NAME" 2>/dev/null | grep -q "ap"; then
        echo "$NAME"
    fi
done | head -n1)

if [ -n "$HOTSPOT_CONN" ]; then
    echo "=== Found hotspot connection profile: $HOTSPOT_CONN ==="
    nmcli connection modify "$HOTSPOT_CONN" 802-11-wireless-security.pmf 1
    echo "PMF set to '1' (optional)."
else
    echo "❌ Could not detect hotspot connection profile to apply PMF setting."
fi

# --------- Status Check ---------
echo "=== Checking hotspot status ==="

IFACE_TO_CHECK="${IFACE:-$(nmcli -t -f DEVICE,TYPE device | grep ':wifi' | cut -d: -f1 | head -n1)}"

if iw dev "$IFACE_TO_CHECK" info 2>/dev/null | grep -q "type AP"; then
    echo "✅ Hotspot '$SSID' is ACTIVE on $IFACE_TO_CHECK"
    echo "    SSID: $SSID"
    echo "    Password: $PASSWORD"
else
    echo "❌ Hotspot did not enter AP mode."
    echo "Check logs: sudo journalctl -u NetworkManager"
fi

