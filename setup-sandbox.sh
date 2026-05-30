#!/usr/bin/env bash
DIR="$(cd "$(dirname "$0")" && pwd)"
SANDBOX="$DIR/chrome-linux/chrome_sandbox"
echo "Setting up Aurora Browser sandbox (requires sudo)..."
sudo chown root:root "$SANDBOX"
sudo chmod 4755 "$SANDBOX"
echo "Done. Sandbox is now SUID root."
echo "You can now remove '--disable-setuid-sandbox' from launch-aurora.sh."
