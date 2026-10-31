#!/usr/bin/env python3
"""Compatibility entry point. Translations live in localization/catalog.json."""
from pathlib import Path
import subprocess
import sys
if len(sys.argv) > 1:
    raise SystemExit("Use scripts/localize.py --platform windows; custom output directories are no longer supported.")
subprocess.run([sys.executable, str(Path(__file__).resolve().parents[2] / "scripts/localize.py"), "--platform", "windows"], check=True)
