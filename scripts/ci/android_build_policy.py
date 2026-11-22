#!/usr/bin/env python3
"""Check the Android build policy and, optionally, the actual optimized bundle.

This does not compile, sign, reserve a version or publish. Missing bundle metadata
is a failure: source configuration alone cannot establish Release optimization.
"""
import argparse
import hashlib
import json
import os
from pathlib import Path
import re
import subprocess
import zipfile

ROOT = Path(__file__).resolve().parents[2]


def properties(text):
    result = {}
    for line in text.splitlines():
        line = line.strip()
        if line and not line.startswith(("#", "!")) and "=" in line:
            key, value = line.split("=", 1)
            result[key.strip()] = value.strip()
    return result


def version(value):
    if not re.fullmatch(r"\d+\.\d+\.\d+", value):
        raise ValueError("A stable three-part toolchain version is required")
    return tuple(map(int, value.split(".")))


def source_policy(root):
    android = root / "android"
    catalog = (android / "gradle/libs.versions.toml").read_text()
    versions = dict(re.findall(r'^([a-zA-Z][\w-]*)\s*=\s*"([0-9.]+)"\s*$', catalog, re.M))
    wrapper = properties((android / "gradle/wrapper/gradle-wrapper.properties").read_text())
    match = re.search(r"/gradle-([0-9.]+)-bin\.zip$", wrapper.get("distributionUrl", ""))
    if not match or version(match[1]) < (9, 1, 0):
        raise ValueError("Android requires the checked Gradle 9.1+ binary wrapper")
    if not re.fullmatch(r"[a-f0-9]{64}", wrapper.get("distributionSha256Sum", "")):
        raise ValueError("The Gradle distribution SHA-256 must be pinned")
    if version(versions.get("agp", "")) < (9, 0, 0) or version(versions.get("kotlin", "")) < (2, 2, 10):
        raise ValueError("Android requires AGP 9+ and aligned Kotlin/Compose compiler 2.2.10+")
    flags = properties((android / "gradle.properties").read_text())
    if flags.get("android.r8.optimizedResourceShrinking") != "true":
        raise ValueError("Optimized resource shrinking must be explicitly enabled")
    if flags.get("android.enableR8.fullMode") == "false" or flags.get("android.builtInKotlin") == "false":
        raise ValueError("R8 full mode and built-in Android Kotlin must stay enabled")
    daemon = properties((android / "gradle/gradle-daemon-jvm.properties").read_text())
    if daemon.get("toolchainVersion") != "17":
        raise ValueError("The Android daemon must use the selected JDK 17 toolchain")
    return {"agp": versions["agp"], "kotlin": versions["kotlin"], "gradle": match[1], "jdk": 17}


def wrapper_runtime(root, expected):
    wrapper = root / "android/gradlew"
    output = subprocess.check_output([str(wrapper), "--version", "--console=plain"],
                                     cwd=root / "android", text=True, timeout=120)
    actual = re.search(r"^Gradle ([0-9.]+)$", output, re.M)
    launcher = re.search(r"^Launcher JVM:\s+(\d+)\b", output, re.M)
    daemon = re.search(r"^Daemon JVM:\s+Compatible with Java (\d+)\b", output, re.M)
    if not actual or actual[1] != expected["gradle"] or not launcher or not daemon or int(daemon[1]) != expected["jdk"]:
        raise ValueError("The executing wrapper/daemon selection differs from the selected Gradle/JDK toolchain")
    return {"gradle": actual[1], "launcher_jdk": int(launcher[1]), "selected_daemon_jdk": int(daemon[1])}


def read_metadata(archive, name):
    if archive.getinfo(name).file_size > 1024 * 1024:
        raise ValueError("Unexpectedly large build metadata")
    return archive.read(name)


def verify_bundle(bundle, expected):
    with zipfile.ZipFile(bundle) as archive:
        metadata = properties(read_metadata(archive, "BUNDLE-METADATA/com.android.tools.build.gradle/app-metadata.properties").decode())
        r8 = json.loads(read_metadata(archive, "BUNDLE-METADATA/com.android.tools/r8.json"))
    if metadata.get("androidGradlePluginVersion") != expected["agp"]:
        raise ValueError("The AAB was not produced by the selected Android Gradle plugin")
    if not isinstance(r8, dict) or not isinstance(r8.get("options"), dict) or not isinstance(r8.get("resourceOptimization"), dict):
        raise ValueError("The AAB is missing structured R8 optimization metadata")
    options = r8["options"]
    for flag in ("isObfuscationEnabled", "isOptimizationsEnabled", "isShrinkingEnabled"):
        if options.get(flag) is not True:
            raise ValueError("Release bundle is missing required R8 optimization: " + flag)
    if options.get("isDebugModeEnabled") is not False or options.get("isProGuardCompatibilityModeEnabled") is not False:
        raise ValueError("Release bundle must use non-Debug R8 full mode")
    if r8.get("resourceOptimization", {}).get("isOptimizedShrinkingEnabled") is not True:
        raise ValueError("The AAB does not record optimized resource shrinking")
    digest = hashlib.sha256()
    with bundle.open("rb") as stream:
        for chunk in iter(lambda: stream.read(1024 * 1024), b""):
            digest.update(chunk)
    return {"aab_sha256": digest.hexdigest(), "agp": metadata["androidGradlePluginVersion"],
            "r8": r8.get("version"), "optimized_resource_shrinking": True, "stats": r8.get("stats", {})}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--root", type=Path, default=ROOT)
    parser.add_argument("--verify-wrapper", action="store_true")
    parser.add_argument("--aab", type=Path)
    parser.add_argument("--report", type=Path)
    args = parser.parse_args()
    try:
        policy = source_policy(args.root)
        report = {"source_commit": os.environ.get("GITHUB_SHA"), "expected": policy}
        if args.verify_wrapper:
            report["executing_wrapper"] = wrapper_runtime(args.root, policy)
        if args.aab:
            report["bundle"] = verify_bundle(args.aab, policy)
        text = json.dumps(report, indent=2) + "\n"
        if args.report:
            args.report.parent.mkdir(parents=True, exist_ok=True)
            args.report.write_text(text)
        print(text, end="")
    except (ValueError, KeyError, OSError, zipfile.BadZipFile, subprocess.SubprocessError) as error:
        parser.exit(1, "Android build policy failed: " + str(error) + "\n")


if __name__ == "__main__":
    main()
