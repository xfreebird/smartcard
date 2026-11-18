"""Exercise the CI wrapper against simulated Gradle, repository and delay results."""
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[2]
PLUGIN = "- Plugin Repositories (could not resolve plugin artifact 'org.jetbrains.kotlin:kotlin-gradle-plugin:2.1.0')"
POM = 'https://repo.maven.apache.org/maven2/org/jetbrains/kotlin/kotlin-gradle-plugin/2.1.0/kotlin-gradle-plugin-2.1.0.pom'


class DependencyRetryTests(unittest.TestCase):
    def run_wrapper(self, first, http='200', succeeds=True, extra=()):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            android = root / 'android'
            scripts = root / 'scripts'
            android.mkdir()
            scripts.mkdir()
            shutil.copy(ROOT / 'scripts/gradle-ci.sh', scripts)
            (android / 'gradlew').write_text('''#!/bin/sh
echo "$*" >> "$RUNS"
if [ "$SUCCEEDS" = yes ] && [ "$(wc -l < "$RUNS")" -gt 1 ]; then exit 0; fi
echo "$FAILURE"
exit 17
''')
            (scripts / 'curl').write_text('''#!/bin/sh
echo "$*" >> "$PROBES"
printf '%s' "$HTTP"
''')
            (scripts / 'sleep').write_text('#!/bin/sh\nexit 0\n')
            for path in [android / 'gradlew', scripts / 'curl', scripts / 'sleep']:
                path.chmod(0o700)
            runs, probes = root / 'runs', root / 'probes'
            probes.touch()
            env = dict(os.environ, PATH=str(scripts) + os.pathsep + os.environ['PATH'], RUNS=str(runs),
                       PROBES=str(probes), HTTP=http, FAILURE=first, SUCCEEDS='yes' if succeeds else 'no')
            result = subprocess.run(['bash', str(scripts / 'gradle-ci.sh'), ':app:assembleDebug', *extra],
                                    env=env, text=True, capture_output=True, check=False)
            return result.returncode, runs.read_text().splitlines(), probes.read_text().splitlines()

    def test_published_plugin_refreshes_negative_cache(self):
        code, runs, probes = self.run_wrapper(PLUGIN)
        self.assertEqual(code, 0)
        self.assertEqual(runs, [':app:assembleDebug', ':app:assembleDebug --refresh-dependencies'])
        self.assertEqual(len(probes), 1)
        self.assertTrue(probes[0].endswith(POM))

    def test_missing_plugin_and_invalid_repo_auth_fail_immediately(self):
        for status in ['404', '401', '403']:
            with self.subTest(status=status):
                code, runs, probes = self.run_wrapper(PLUGIN, http=status)
                self.assertEqual((code, len(runs), len(probes)), (17, 1, 1))

    def test_retry_budget_applies_to_published_and_temporarily_unavailable_plugins(self):
        for status in ['200', '429', '503']:
            with self.subTest(status=status):
                code, runs, probes = self.run_wrapper(PLUGIN, http=status, succeeds=False)
                self.assertEqual((code, len(runs), len(probes)), (17, 3, 2))
                self.assertEqual(runs[-1].count('--refresh-dependencies'), 1)

    def test_offline_unknown_plugin_test_and_compiler_errors_do_not_probe_or_retry(self):
        for text, extra in [(PLUGIN, ['--offline']), (PLUGIN.replace('org.jetbrains.kotlin:', 'example:'), []),
                            (PLUGIN + '\nThere were failing tests', []), (PLUGIN + '\ne: broken Kotlin', []),
                            (PLUGIN + '\nReceived status code 401 from server', [])]:
            with self.subTest(text=text, extra=extra):
                code, runs, probes = self.run_wrapper(text, extra=extra)
                self.assertEqual((code, len(runs), probes), (17, 1, []))

    def test_regular_transient_download_retains_the_existing_retry(self):
        code, runs, probes = self.run_wrapper("Could not GET 'https://example.invalid/module'. Read timed out")
        self.assertEqual((code, len(runs), probes), (0, 2, []))
        self.assertNotIn('--refresh-dependencies', runs[1])
