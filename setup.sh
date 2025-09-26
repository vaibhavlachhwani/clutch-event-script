#!/bin/bash
set -euo pipefail

# ================================
# All-in-One Setup Script
# ================================
# 1. Install dependencies
# 2. Install Cloudflare WARP
# 3. Register & connect WARP
# 4. Start Wi-Fi hotspot (sys<number>)
#    - Detect UUID + connection name
#    - Apply PMF
#    - Restart hotspot

# -----------------------
# Configure hotspot password
# -----------------------
PASSWORD="12345678"

usage() {
    cat <<EOF
Usage: $0 <NUMBER> [IFACE]
  <NUMBER> : hotspot number (creates SSID 'sys<NUMBER>')
  [IFACE]  : optional wireless interface (e.g. wlp2s0)

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

# --------- STEP 0: Dependencies ---------
echo "=== Installing required dependencies ==="
sudo apt update
sudo apt install -y curl gnupg apt-transport-https network-manager wireless-tools

if ! command -v nmcli >/dev/null; then
    echo "❌ nmcli not found even after install. Please install NetworkManager manually."
    exit 1
fi
if ! command -v iw >/dev/null; then
    echo "❌ iw not found even after install. Please install wireless-tools manually."
    exit 1
fi
echo "✅ Dependencies installed."

# --------- STEP 1: Install WARP ---------
echo ""
echo "=== STEP 1: Installing Cloudflare WARP ==="

curl -fsSL https://pkg.cloudflareclient.com/pubkey.gpg | sudo gpg --dearmor -o /usr/share/keyrings/cloudflare-warp.gpg

echo "deb [arch=amd64 signed-by=/usr/share/keyrings/cloudflare-warp.gpg] https://pkg.cloudflareclient.com/ $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/cloudflare-warp.list

sudo apt update
sudo apt install -y cloudflare-warp

# --------- STEP 2: Register & connect WARP ---------
echo ""
echo "=== STEP 2: Registering & connecting WARP ==="

sudo warp-cli registration new || true
sudo warp-cli connect

sleep 3
if curl -s https://www.cloudflare.com/cdn-cgi/trace/ | grep -q "warp=on"; then
    echo "✅ WARP is connected!"
else
    echo "❌ WARP is NOT connected."
fi

# --------- STEP 3: Start Hotspot ---------
echo ""
echo "=== STEP 3: Starting Wi-Fi Hotspot '$SSID' ==="

nmcli radio wifi on

# Run hotspot and capture UUID
if [ -n "$IFACE" ]; then
    HOTSPOT_OUT=$(sudo nmcli device wifi hotspot ifname "$IFACE" ssid "$SSID" password "$PASSWORD" || true)
else
    HOTSPOT_OUT=$(nmcli device wifi hotspot ssid "$SSID" password "$PASSWORD" || true)
fi

# Extract UUID from output
UUID=$(echo "$HOTSPOT_OUT" | grep -oE '[0-9a-f-]{36}' | head -n1 || true)

if [ -z "$UUID" ]; then
    echo "❌ Could not extract UUID from hotspot creation output."
    exit 1
fi

# Get connection name from UUID
HOTSPOT_CONN=$(nmcli -t -f NAME,UUID connection show | grep "$UUID" | cut -d: -f1)

echo "=== Hotspot created: $HOTSPOT_CONN (UUID=$UUID) ==="

# Apply PMF
nmcli connection modify "$HOTSPOT_CONN" 802-11-wireless-security.pmf 1
echo "✅ PMF set to 1 for $HOTSPOT_CONN"

# Restart hotspot to apply PMF
nmcli connection down "$HOTSPOT_CONN" || true
nmcli connection up "$HOTSPOT_CONN"

# --------- Status check ---------
echo ""
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

echo ""
echo "=== All steps completed successfully ==="

