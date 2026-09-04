#!/bin/sh
if [ -x /opt/aurora-browser/chrome-linux/chrome_sandbox ]; then
  chown root:root /opt/aurora-browser/chrome-linux/chrome_sandbox 2>/dev/null || true
  chmod 4755 /opt/aurora-browser/chrome-linux/chrome_sandbox 2>/dev/null || true
fi
