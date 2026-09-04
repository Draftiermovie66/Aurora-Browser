#!/usr/bin/env python3
# Deprecated shim — canonical: scripts/checks/validate-yaml.py
import os, sys
ROOT = os.path.join(os.path.dirname(__file__), "checks", "validate-yaml.py")
os.execv(sys.executable, [sys.executable, ROOT] + sys.argv[1:])
