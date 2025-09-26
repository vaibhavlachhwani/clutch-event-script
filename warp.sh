#!/bin/bash
set -e

echo "=== Installing dependencies (curl, gpg, apt-transport-https) ==="
sudo apt update
sudo apt install -y curl gnupg apt-transport-https iw

echo "=== Adding Cloudflare GPG key ==="
curl -fsSL https://pkg.cloudflareclient.com/pubkey.gpg | sudo gpg --dearmor -o /usr/share/keyrings/cloudflare-warp.gpg

echo "=== Adding Cloudflare WARP repository ==="
echo "deb [arch=amd64 signed-by=/usr/share/keyrings/cloudflare-warp.gpg] https://pkg.cloudflareclient.com/ $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/cloudflare-warp.list

echo "=== Updating package list ==="
sudo apt update

echo "=== Installing Cloudflare WARP ==="
sudo apt install -y cloudflare-warp

echo "=== Installation complete! You can now run 'warp-cli --help' to get started. ==="

