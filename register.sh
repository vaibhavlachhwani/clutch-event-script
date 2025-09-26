#!/bin/bash
set -e

echo "=== Registering Cloudflare WARP client ==="
sudo warp-cli registration new || true

echo "=== Connecting to Cloudflare WARP ==="
sudo warp-cli connect

echo "=== Verifying WARP connection ==="
sleep 3  # wait a bit for connection

if curl -s https://www.cloudflare.com/cdn-cgi/trace/ | grep -q "warp=on"; then
    echo "✅ WARP is connected!"
else
    echo "❌ WARP is NOT connected."
fi

