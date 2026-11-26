#!/usr/bin/env python3
"""Hash a resolved wheel set after checking every file against primary PyPI metadata.

This reads wheels as ZIP archives; it never installs or executes their contents.
Resolve store-publish.in with CPython 3.12 for Ubuntu x86_64 before invoking it.
"""
import argparse
import email
import hashlib
import json
from pathlib import Path
import re
import urllib.request
import zipfile


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("wheels", type=Path)
    parser.add_argument("--output", type=Path, default=Path(__file__).resolve().parents[1] / "requirements/store-publish.txt")
    args = parser.parse_args()
    rows = {}
    for wheel in sorted(args.wheels.glob("*.whl")):
        with zipfile.ZipFile(wheel) as archive:
            entries = [name for name in archive.namelist() if name.endswith(".dist-info/METADATA")]
            if len(entries) != 1:
                raise ValueError(f"Ambiguous metadata: {wheel.name}")
            metadata = email.message_from_bytes(archive.read(entries[0]))
        name, version = metadata["Name"], metadata["Version"]
        if not name or not version or not re.fullmatch(r"[A-Za-z0-9_.-]+", name) or not re.fullmatch(r"[A-Za-z0-9_.+!-]+", version):
            raise ValueError("Invalid distribution identity")
        digest = hashlib.sha256(wheel.read_bytes()).hexdigest()
        with urllib.request.urlopen(f"https://pypi.org/pypi/{name}/{version}/json", timeout=30) as response:
            release = json.load(response)
        if not any(item["filename"] == wheel.name and item["digests"]["sha256"] == digest for item in release["urls"]):
            raise ValueError(f"Wheel does not match PyPI: {wheel.name}")
        key = re.sub(r"[-_.]+", "-", name).lower()
        if key in rows:
            raise ValueError(f"Multiple wheels for {name}; resolve a single platform into a clean directory")
        rows[key] = f"{name}=={version} --hash=sha256:{digest}"
    if not {"requests", "pyjwt", "cryptography"} <= rows.keys():
        raise ValueError("Incomplete publisher wheel set")
    content = "# Store uploader dependencies: CPython 3.12, Ubuntu 24.04 x86_64.\n"
    content += "# Wheel-only; hashes verified against PyPI release metadata. No source build hooks.\n"
    content += "\n".join(rows[name] for name in sorted(rows)) + "\n"
    args.output.write_text(content)


if __name__ == "__main__":
    main()
