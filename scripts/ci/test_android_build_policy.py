"""Reject stale or incompletely optimized Android artifacts before signing/upload."""
import hashlib
import io
import json
from pathlib import Path
import subprocess
import tempfile
import unittest
from contextlib import redirect_stderr, redirect_stdout
from unittest.mock import patch
import zipfile

from android_build_policy import ROOT, main, source_policy, verify_bundle, wrapper_runtime


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

    def test_build_policy_checks_the_real_wrapper_selection_and_bundle_together(self):
        with tempfile.TemporaryDirectory() as folder:
            bundle = self.bundle(Path(folder), agp=source_policy(ROOT)["agp"])
            selected = source_policy(ROOT)
            status = f'Gradle {selected["gradle"]}\nLauncher JVM: 17\nDaemon JVM: Compatible with Java 17\n'
            output = io.StringIO()
            with patch('sys.argv', ['android_build_policy', '--verify-wrapper', '--aab', str(bundle)]), \
                    patch('subprocess.check_output', return_value=status) as wrapper, redirect_stdout(output):
                main()
            wrapper.assert_called_once_with([str(ROOT / 'android/gradlew'), '--version', '--console=plain'],
                                            cwd=ROOT / 'android', text=True, timeout=120)
            self.assertEqual(json.loads(output.getvalue())['bundle']['aab_sha256'],
                             hashlib.sha256(bundle.read_bytes()).hexdigest())
            self.assertEqual(json.loads(output.getvalue())['executing_wrapper']['selected_daemon_jdk'], 17)

    def test_cli_returns_nonzero_on_wrapper_failure_without_a_success_report(self):
        output, error = io.StringIO(), io.StringIO()
        with patch('sys.argv', ['android_build_policy', '--verify-wrapper']), \
                patch('subprocess.check_output', side_effect=subprocess.TimeoutExpired('gradlew', 120)), \
                redirect_stdout(output), redirect_stderr(error), self.assertRaises(SystemExit) as stopped:
            main()
        self.assertEqual(stopped.exception.code, 1)
        self.assertEqual(output.getvalue(), '')
        self.assertIn('Android build policy failed', error.getvalue())

    def test_wrong_executing_gradle_or_daemon_is_rejected(self):
        selected = source_policy(ROOT)
        for status in ('Gradle 8.0\nLauncher JVM: 17\nDaemon JVM: Compatible with Java 17',
                       f'Gradle {selected["gradle"]}\nLauncher JVM: 17\nDaemon JVM: Compatible with Java 21'):
            with self.subTest(status=status), patch('subprocess.check_output', return_value=status):
                with self.assertRaisesRegex(ValueError, 'wrapper/daemon'):
                    wrapper_runtime(ROOT, selected)

    def test_unapproved_source_toolchain_and_flags_are_rejected(self):
        with tempfile.TemporaryDirectory() as folder:
            root = Path(folder)
            android = root / "android"
            (android / "gradle/wrapper").mkdir(parents=True)
            (android / "gradle/libs.versions.toml").write_text('[versions]\nagp = "9.0.1"\nkotlin = "2.2.10"\n')
            (android / "gradle/wrapper/gradle-wrapper.properties").write_text(
                'distributionUrl=https\\://services.gradle.org/distributions/gradle-9.1.0-bin.zip\n'
                + 'distributionSha256Sum=' + 'a' * 64 + '\n')
            (android / "gradle/gradle-daemon-jvm.properties").write_text('toolchainVersion=17\n')
            flags = android / 'gradle.properties'
            required = 'android.r8.optimizedResourceShrinking=true\n'
            for value, error in [('', 'must be explicitly enabled'), (required + 'android.enableR8.fullMode=false',
                                    'full mode'), (required + 'android.builtInKotlin=false', 'built-in Android Kotlin')]:
                with self.subTest(value=value):
                    flags.write_text(value)
                    with self.assertRaisesRegex(ValueError, error):
                        source_policy(root)
            flags.write_text(required)
            (android / 'gradle/gradle-daemon-jvm.properties').write_text('toolchainVersion=21\n')
            with self.assertRaisesRegex(ValueError, 'JDK 17'):
                source_policy(root)


if __name__ == "__main__":
    unittest.main()
