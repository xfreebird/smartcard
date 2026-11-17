"""Regression coverage for hosted images adding future or device-specific runtimes."""
import unittest

from select_apple_ui_targets import select_targets


class AppleUITargetTests(unittest.TestCase):
    def setUp(self):
        self.devices = {"devices": {}}
        self.runtimes = {"runtimes": []}

    def runtime(self, version, *names, available=True, suffix=""):
        identifier = "com.apple.CoreSimulator.SimRuntime.iOS-" + version.replace(".", "-") + suffix
        self.runtimes["runtimes"].append(dict(identifier=identifier, version=version, isAvailable=available))
        self.devices["devices"][identifier] = [dict(name=name, udid=f"{version}:{name}", isAvailable=True) for name in names]
        return identifier

    def select(self, sdk="27.1"):
        return dict(select_targets(self.devices, self.runtimes, sdk))

    def test_device_specific_release_keeps_both_families(self):
        self.runtime("27.0", "iPhone 18", "iPad Pro")
        self.runtime("27.1", "iPhone Duo")
        self.runtime("27.2", "iPhone Duo", "iPad mini")
        self.assertEqual(self.select(), {"iPhone": "27.1:iPhone Duo", "iPad": "27.0:iPad Pro"})

    def test_patch_runtime_and_foldable_are_preferred(self):
        self.runtime("27.1", "iPhone 18", "iPad Pro")
        self.runtime("27.1.1", "iPhone 18", "iPhone Duo", "iPad Pro")
        self.assertEqual(self.select(), {"iPhone": "27.1.1:iPhone Duo", "iPad": "27.1.1:iPad Pro"})

    def test_runtime_version_metadata_handles_hardware_suffixes(self):
        self.runtime("27.1", "iPhone Duo", suffix="-iPhone19-4")
        self.runtime("27.0", "iPad Pro")
        self.assertEqual(self.select()["iPhone"], "27.1:iPhone Duo")

    def test_custom_device_names_use_hardware_type(self):
        identifier = self.runtime("27.0", "Phone fixture", "Tablet fixture")
        phone, tablet = self.devices["devices"][identifier]
        phone["deviceTypeIdentifier"] = "com.apple.CoreSimulator.SimDeviceType.iPhone-Duo"
        tablet["deviceTypeIdentifier"] = "com.apple.CoreSimulator.SimDeviceType.iPad-mini-A17-Pro"
        self.assertEqual(self.select(), {"iPhone": "27.0:Phone fixture", "iPad": "27.0:Tablet fixture"})

    def test_newer_sdk_explicitly_admits_newer_runtime(self):
        self.runtime("27.1", "iPhone Duo", "iPad Pro")
        self.runtime("27.2", "iPhone Duo", "iPad mini")
        self.assertEqual(self.select("27.2")["iPad"], "27.2:iPad mini")

    def test_compact_tablet_preferred_within_same_runtime(self):
        self.runtime("27.0", "iPhone Duo", "iPad Pro 13-inch (M5)", "iPad mini (A17 Pro)")
        self.assertEqual(self.select()["iPad"], "27.0:iPad mini (A17 Pro)")

    def test_compact_tablet_does_not_downgrade_runtime_coverage(self):
        self.runtime("27.0", "iPhone Duo", "iPad mini (A17 Pro)")
        self.runtime("27.1", "iPad Pro 13-inch (M5)")
        self.assertEqual(self.select()["iPad"], "27.1:iPad Pro 13-inch (M5)")

    def test_compact_tablet_preference_uses_hardware_type(self):
        identifier = self.runtime("27.0", "iPhone Duo", "iPad Pro", "Tablet fixture")
        self.devices["devices"][identifier][-1]["deviceTypeIdentifier"] = "com.apple.CoreSimulator.SimDeviceType.iPad-mini-A17-Pro"
        self.assertEqual(self.select()["iPad"], "27.0:Tablet fixture")

    def test_missing_family_fails_instead_of_omitting_it(self):
        self.runtime("27.1", "iPhone Duo")
        with self.assertRaisesRegex(ValueError, "No available iPad"):
            self.select()

    def test_older_major_does_not_substitute_for_current_coverage(self):
        self.runtime("26.5", "iPhone 17", "iPad Pro")
        self.runtime("27.2", "iPhone Duo", "iPad mini")
        with self.assertRaisesRegex(ValueError, "No available iPhone"):
            self.select()

    def test_unavailable_runtime_or_device_cannot_be_selected(self):
        self.runtime("27.1", "iPhone Duo", available=False)
        identifier = self.runtime("27.0", "iPhone 18", "iPad Pro")
        self.devices["devices"][identifier][0]["isAvailable"] = False
        with self.assertRaisesRegex(ValueError, "No available iPhone"):
            self.select()

    def test_malformed_sdk_is_rejected(self):
        with self.assertRaisesRegex(ValueError, "Unrecognized Apple version"):
            self.select("latest")
