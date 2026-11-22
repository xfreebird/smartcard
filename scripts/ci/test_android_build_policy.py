"""Reject stale or incompletely optimized Android artifacts before signing/upload."""
import hashlib
import json
from pathlib import Path
import tempfile
import unittest
import zipfile

from android_build_policy import source_policy, verify_bundle


class AndroidBuildPolicyTests(unittest.TestCase):
    def bundle(self, folder, *, agp="9.0.1", optimized=True, missing_r8=False):
        path = folder / "test.aab"
        with zipfile.ZipFile(path, "w") as archive:
            archive.writestr("BUNDLE-METADATA/com.android.tools.build.gradle/app-metadata.properties",
                             "appMetadataVersion=1.1\nandroidGradlePluginVersion=" + agp + "\n")
            if not missing_r8:
                archive.writestr("BUNDLE-METADATA/com.android.tools/r8.json", json.dumps({
                    "version": "9.0.32", "options": {
                        "isObfuscationEnabled": True, "isOptimizationsEnabled": True,
                        "isShrinkingEnabled": True, "isDebugModeEnabled": False,
                        "isProGuardCompatibilityModeEnabled": False},
                    "resourceOptimization": {"isOptimizedShrinkingEnabled": optimized}}))
        return path

    def test_optimized_bundle_records_its_own_exact_hash(self):
        with tempfile.TemporaryDirectory() as folder:
            bundle = self.bundle(Path(folder))
            result = verify_bundle(bundle, {"agp": "9.0.1"})
            self.assertEqual(result["aab_sha256"], hashlib.sha256(bundle.read_bytes()).hexdigest())
            self.assertTrue(result["optimized_resource_shrinking"])

    def test_a_previous_agp_or_disabled_resource_optimizer_is_rejected(self):
        with tempfile.TemporaryDirectory() as folder:
            for options in ({"agp": "8.10.1"}, {"optimized": False}):
                with self.subTest(options=options):
                    with self.assertRaises(ValueError):
                        verify_bundle(self.bundle(Path(folder), **options), {"agp": "9.0.1"})

    def test_missing_optimizer_evidence_is_not_a_successful_skip(self):
        with tempfile.TemporaryDirectory() as folder:
            with self.assertRaises(KeyError):
                verify_bundle(self.bundle(Path(folder), missing_r8=True), {"agp": "9.0.1"})

    def test_source_policy_cannot_silently_disable_resource_optimization(self):
        with tempfile.TemporaryDirectory() as folder:
            root = Path(folder)
            android = root / "android"
            (android / "gradle/wrapper").mkdir(parents=True)
            (android / "gradle/libs.versions.toml").write_text('[versions]\nagp = "9.0.1"\nkotlin = "2.2.10"\n')
            (android / "gradle/wrapper/gradle-wrapper.properties").write_text(
                'distributionUrl=https\\://services.gradle.org/distributions/gradle-9.1.0-bin.zip\n'
                + 'distributionSha256Sum=' + 'a' * 64 + '\n')
            (android / "gradle/gradle-daemon-jvm.properties").write_text('toolchainVersion=17\n')
            (android / "gradle.properties").write_text('android.r8.optimizedResourceShrinking=false\n')
            with self.assertRaises(ValueError):
                source_policy(root)


if __name__ == "__main__":
    unittest.main()
