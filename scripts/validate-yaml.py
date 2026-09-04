#!/usr/bin/env python3
import glob
import sys

try:
    import yaml
except ImportError:
    print("PyYAML is not installed (pip install pyyaml). Skipping validation.")
    sys.exit(0)

FILES = (
    glob.glob('.github/workflows/*.yml')
    + ['.github/release-drafter.yml', '.github/dependabot.yml']
)

failed = False
for f in FILES:
    try:
        with open(f) as fh:
            yaml.safe_load(fh)
        print(f"OK: {f}")
    except Exception as e:
        print(f"INVALID: {f}: {e}")
        failed = True

sys.exit(1 if failed else 0)
