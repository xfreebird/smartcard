"""Exercise the CI package installer against simulated apt-get results, and the annotation patterns CI relies on."""
import json
import os
from pathlib import Path
import re
import shutil
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[2]


class AptInstallTests(unittest.TestCase):
    def run_installer(self, failures, *packages):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            shutil.copy(ROOT / 'scripts/ci/apt-install.sh', root)
            fake = root / 'bin'
            fake.mkdir()
            # Each call is logged; the first FAILURES update calls fail like an archive caught mid-sync.
            (fake / 'apt-get').write_text('''#!/bin/sh
echo "$*" >> "$CALLS"
if [ "$3" = update ] && [ "$(grep -c ' update ' "$CALLS")" -le "$FAILURES" ]; then exit 100; fi
exit 0
''')
            (fake / 'sleep').write_text('#!/bin/sh\necho "$1" >> "$SLEEPS"\n')
            for path in fake.iterdir():
                path.chmod(0o700)
            calls, sleeps = root / 'calls', root / 'sleeps'
            calls.touch()
            sleeps.touch()
            env = dict(os.environ, PATH=str(fake) + os.pathsep + os.environ['PATH'], CALLS=str(calls),
                       SLEEPS=str(sleeps), FAILURES=str(failures))
            result = subprocess.run(['bash', str(root / 'apt-install.sh'), *packages], env=env, text=True,
                                    capture_output=True, check=False)
            return result, calls.read_text().splitlines(), sleeps.read_text().split()

    def test_installs_the_packages_after_a_successful_update(self):
        result, calls, sleeps = self.run_installer(0, 'pkg-config', 'libgtk-4-dev')
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(calls, ['-o Acquire::Retries=3 update --error-on=any',
                                 '-o Acquire::Retries=3 install -y --no-install-recommends pkg-config libgtk-4-dev'])
        self.assertEqual(sleeps, [])

    def test_repeats_update_and_install_while_the_archive_settles(self):
        result, calls, sleeps = self.run_installer(2, 'xvfb')
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual([call.split()[2] for call in calls], ['update', 'update', 'update', 'install'])
        self.assertEqual(sleeps, ['30', '60'])
        self.assertIn('apt-get failed; retrying in 30 s (1/3).', result.stdout)

    def test_gives_up_with_apt_status_after_three_attempts(self):
        result, calls, sleeps = self.run_installer(3, 'xvfb')
        self.assertEqual(result.returncode, 100)
        self.assertEqual(len(calls), 3)
        self.assertEqual(sleeps, ['30', '60'])

    def test_requires_packages(self):
        result, calls, _ = self.run_installer(0)
        self.assertEqual((result.returncode, calls), (2, []))

    def test_apt_errors_and_retries_become_annotations(self):
        matchers = json.loads((ROOT / '.github/problem-matchers/test-failures.json').read_text())['problemMatcher']
        pattern = next(m for m in matchers if m['owner'] == 'esemnbun-apt')['pattern'][0]['regexp']
        for line in ['E: Failed to fetch http://archive.ubuntu.com/ubuntu/dists/noble/InRelease  Hash Sum mismatch',
                     'apt-get failed; retrying in 30 s (1/3).']:
            self.assertEqual(re.match(pattern, line).group(1), line)
        self.assertIsNone(re.match(pattern, 'e: file:///src/Main.kt:1:1 Unresolved reference'))


if __name__ == '__main__':
    unittest.main()
