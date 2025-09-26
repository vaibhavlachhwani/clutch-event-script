#!/bin/bash

# Check if a number is provided
if [ -z "$1" ]; then
  echo "Usage: $0 <number>"
  exit 1
fi

# GitHub repository URL
REPO_URL="https://raw.githubusercontent.com/vaibhavlachhwani/clutch-event-script/master"

# Download and execute scripts
echo "Downloading and running warp.sh"
curl -s -o warp.sh "$REPO_URL/warp.sh"
bash warp.sh

echo "Downloading and running register.sh"
curl -s -o register.sh "$REPO_URL/register.sh"
bash register.sh

echo "Downloading and running hotspot.sh"
curl -s -o hotspot.sh "$REPO_URL/hotspot.sh"
bash hotspot.sh "$1"
