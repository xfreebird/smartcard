"""Rebase Windows coverage paths onto the same source checkout on the scanner host."""

import hashlib
from pathlib import Path, PureWindowsPath
import sys
import xml.etree.ElementTree as ET


def rebase(report, root_file, destination, checkout):
    root = PureWindowsPath(root_file.read_text(encoding="utf-8-sig").strip())
    if not root.is_absolute():
        raise ValueError("Expected the absolute Windows checkout path")

    tree = ET.parse(report)
    matched = 0
    for entry in tree.iter("source_file"):
        try:
            relative = PureWindowsPath(entry.attrib["path"]).relative_to(root)
        except ValueError:
            continue  # Toolchain and package sources are outside the checkout.
        source = checkout.joinpath(*relative.parts).resolve()
        if not source.is_relative_to(checkout):
            raise ValueError(f"Coverage path escapes the checkout: {relative}")
        if not source.is_file():
            continue  # Generated sources are absent from the clean scanner checkout.
        if entry.get("checksum_type") == "SHA256":
            contents = source.read_bytes()
            lf = contents.replace(b"\r\n", b"\n")
            expected = entry.attrib["checksum"].lower()
            if not any(hashlib.sha256(data).hexdigest() == expected
                       for data in (contents, lf, lf.replace(b"\n", b"\r\n"))):
                raise ValueError(f"Coverage source differs from the checkout: {relative}")
        entry.set("path", str(source))
        matched += 1
    if not matched:
        raise ValueError("No Windows coverage sources matched the checkout")
    tree.write(destination, encoding="utf-8", xml_declaration=True)
    print(f"Matched {matched} coverage source entries to this checkout")


if __name__ == "__main__":
    rebase(*map(Path, sys.argv[1:]), Path.cwd().resolve())
