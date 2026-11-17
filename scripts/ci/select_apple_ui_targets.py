#!/usr/bin/env python3
"""Select both simulator families without silently advancing beyond the active SDK."""
import json
import re
import sys


def version(value):
    if not re.fullmatch(r"\d+\.\d+(?:\.\d+)?", value):
        raise ValueError(f"Unrecognized Apple version: {value!r}")
    parts = tuple(map(int, value.split(".")))
    return parts + (0,) * (3 - len(parts))


def device_type(device):
    return device.get("deviceTypeIdentifier", "").rsplit(".", 1)[-1] or device["name"]


def select_targets(devices, runtimes, sdk_version):
    sdk = version(sdk_version)
    eligible = []
    for runtime in runtimes["runtimes"]:
        identifier = runtime["identifier"]
        if not identifier.startswith("com.apple.CoreSimulator.SimRuntime.iOS-") or not runtime.get("isAvailable"):
            continue
        release = version(runtime["version"])
        # Patch runtimes remain compatible with their major/minor SDK. Older major
        # releases must not silently replace the current platform's required coverage.
        if release[0] == sdk[0] and release[:2] <= sdk[:2]:
            eligible.append((release, identifier))
    eligible.sort(reverse=True)
    targets = []
    for family in ("iPhone", "iPad"):
        choices = [(release, device) for release, identifier in eligible
                   for device in devices["devices"].get(identifier, [])
                   if device.get("isAvailable") and device_type(device).startswith(family)]
        if not choices:
            raise ValueError(f"No available {family} runtime in SDK {sdk_version}'s release line; refusing to skip UI coverage")
        # Runtime coverage comes first. Within that runtime keep the foldable phone,
        # but prefer the smaller tablet framebuffer on the 7 GB hosted runner.
        # All 35 cases still run with regular-width tablet navigation and rotation.
        def preference(item):
            hardware = device_type(item[1]).replace("-", " ")
            preferred = hardware == "iPhone Duo" or hardware.startswith("iPad mini")
            return item[0], preferred
        choices.sort(key=preference, reverse=True)
        targets.append((family, choices[0][1]["udid"]))
    return targets


if __name__ == "__main__":
    if len(sys.argv) != 4:
        raise SystemExit("Usage: select_apple_ui_targets.py DEVICES_JSON RUNTIMES_JSON SDK_VERSION")
    try:
        with open(sys.argv[1]) as source:
            devices = json.load(source)
        with open(sys.argv[2]) as source:
            runtimes = json.load(source)
        targets = select_targets(devices, runtimes, sys.argv[3])
    except (ValueError, KeyError, OSError) as error:
        raise SystemExit(str(error))
    for family, identifier in targets:
        print(f"{family}\t{identifier}")
