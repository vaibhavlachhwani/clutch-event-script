#!/bin/bash

# Check if a number is provided
if [ -z "$1" ]; then
  echo "Usage: $0 <number>"
  exit 1
fi

# Generate SSID
SSID="sys$1"
PASSWORD="12345678"

echo "Creating hotspot with SSID: $SSID"

# Create hotspot
nmcli dev wifi hotspot ssid "$SSID" password "$PASSWORD"

# Get connection name
NAME=$(nmcli -g name,type c show --active | grep 802-11-wireless | cut -d: -f1)

if [ -z "$NAME" ]; then
  echo "Error: Could not find the created hotspot connection."
  exit 1
fi

echo "Modifying connection: $NAME"

# Modify connection
nmcli c modify "$NAME" 802-11-wireless-security.pmf 1

echo "Restarting hotspot"

# Turn hotspot off and on
nmcli c down "$NAME"
nmcli c up "$NAME"

echo "Hotspot setup complete."
echo "SSID: $SSID"
echo "Password: $PASSWORD"
