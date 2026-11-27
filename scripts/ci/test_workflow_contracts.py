"""Detect credential-documentation drift and CI privilege regressions without reading secret values."""
from pathlib import Path
import re
import unittest

ROOT=Path(__file__).resolve().parents[2]


class WorkflowContracts(unittest.TestCase):
    def test_all_referenced_distribution_secrets_are_documented(self):
        names=set()
        for path in (ROOT/'.github/workflows').glob('*.yml'):
            names.update(re.findall(r'secrets\.([A-Z][A-Z0-9_]*)',path.read_text()))
        guide=(ROOT/'docs/14-github-actions.md').read_text()
        self.assertGreater(len(names),15)
        for name in names:self.assertIn('`'+name+'`',guide,name)

    def test_validation_has_no_distribution_secrets_or_write_permission(self):
        ci=(ROOT/'.github/workflows/ci.yml').read_text()
        self.assertNotIn('secrets.',ci)
        self.assertNotIn('contents: write',ci)
        self.assertNotIn('pull_request_target',ci)
        self.assertIn('name: CI result',ci)

    def test_counter_callers_keep_shared_serialization(self):
        for name in ['android-build.yml','release.yml']:
            text=(ROOT/'.github/workflows'/name).read_text()
            self.assertIn('group: android-play-version-code',text)
            self.assertIn('bash scripts/ci/reserve-android-version.sh',text)
        publish=(ROOT/'.github/workflows/android-play-publish.yml').read_text()
        self.assertIn('group: android-play-version-code',publish)
        self.assertNotIn('cancel-in-progress: true',publish)

    def test_branch_pushes_only_validate_or_deploy_documentation(self):
        for path in (ROOT/'.github/workflows').glob('*.yml'):
            text = path.read_text()
            triggers = text.split('\non:\n', 1)[1].split('\npermissions:', 1)[0]
            if path.name not in ('ci.yml', 'website.yml', 'release.yml', 'sonar-coverage.yml'):
                self.assertNotRegex(triggers, r'(?m)^  push:', path.name)
            if path.name == 'sonar-coverage.yml':
                self.assertIn('branches: [main]', triggers)
                self.assertNotIn('pull_request_target:', triggers)
                self.assertNotRegex(text, r'(?m)^\s+\w+: write$')
                self.assertEqual(set(re.findall(r'secrets\.([A-Z][A-Z0-9_]*)', text)), {'SONAR_TOKEN'})
            if path.name == 'release.yml':
                push = triggers.split('  push:', 1)[1].split('  workflow_dispatch:', 1)[0]
                self.assertIn('tags: ["v*"]', push)
                self.assertNotIn('branches:', push)
            if '  workflow_run:' in triggers:
                self.assertIn('workflows: [', triggers)
                # Only explicit Release/feed completion can chain delivery workflows.
                sources = re.search(r'workflows: \[([^\]]+)\]', triggers).group(1)
                self.assertTrue(set(s.strip() for s in sources.split(',')) <=
                                {'Release', 'CLI package repositories'}, path.name)

    def test_android_jobs_take_robolectric_from_the_cache_before_gradle(self):
        # Maven Central rate-limits the 151 MB framework jar from CI addresses; Gradle must find it cached.
        for name, job in [('ci.yml', '\n  android:\n'), ('sonar-coverage.yml', '\n  android-web:\n')]:
            text = (ROOT/'.github/workflows'/name).read_text().split(job, 1)[1]
            order = [text.index(step) for step in ['robolectric-cache.sh outputs', 'ROBOLECTRIC_LOCAL_REPOSITORY=',
                                                   'actions/cache/restore@', 'robolectric-cache.sh seed',
                                                   'actions/cache/save@', 'gradle-ci.sh']]
            self.assertEqual(order, sorted(order), name)
            self.assertIn('>> "$GITHUB_ENV"', text.split('ROBOLECTRIC_LOCAL_REPOSITORY=', 1)[1].split('\n', 1)[0], name)
            # The seed step also checks a restored jar's SHA-256, so it runs on cache hits too.
            seed = text.split('robolectric-cache.sh seed', 1)[0].rsplit('- name:', 1)[1]
            self.assertNotIn('if:', seed, name)
        settings = (ROOT/'android/settings.gradle.kts').read_text()
        local = settings.split('environmentVariable("ROBOLECTRIC_LOCAL_REPOSITORY")', 1)[1].split('google()', 1)[0]
        self.assertIn('exclusiveContent', local)
        self.assertIn('includeModule("org.robolectric", "android-all-instrumented")', local)

    def test_android_jobs_read_maven_central_through_the_mirror_with_a_gradle_cache(self):
        # Maven Central answers CI's shared addresses with HTTP 429; every Android job uses the mirror and the cache.
        mirror = 'MAVEN_CENTRAL_MIRROR: https://maven-central.storage-download.googleapis.com/maven2'
        for name, job in [('ci.yml', 'android'), ('sonar-coverage.yml', 'android-web'),
                          ('android-runtime.yml', 'x86-64')]:
            body = (ROOT/'.github/workflows'/name).read_text().split(f'\n  {job}:\n', 1)[1]
            body = re.split(r'\n  [a-z][a-z0-9-]*:\n', body, maxsplit=1)[0]
            self.assertIn(mirror, body.split('steps:', 1)[0], name)
            self.assertIn('cache: gradle', body, name)
        settings = (ROOT/'android/settings.gradle.kts').read_text()
        plugins, dependencies = settings.split('dependencyResolutionManagement', 1)
        for block in (plugins, dependencies):
            self.assertLess(block.index('MAVEN_CENTRAL_MIRROR'), block.index('mavenCentral()'))

    def test_sonar_analyzes_only_shipped_runtime_code(self):
        settings = dict(line.split('=', 1) for line in (ROOT/'.sonarcloud.properties').read_text().splitlines()
                        if line.startswith('sonar.'))
        runtime = ('swift/MoldSignKit/Sources/', 'apple/Apps/', 'apple/Helpers/', 'apple/ShareExtension/',
                   'apple/WidgetExtension/', 'linux/Sources/', 'android/core/src/main/', 'android/transport-usb/src/main/',
                   'android/app/src/main/', 'android/app/src/release/', 'windows/src/', 'website/src/')
        inclusions = settings['sonar.inclusions'].split(',')
        self.assertEqual(sorted(entry.removesuffix('**') for entry in inclusions), sorted(runtime))
        for entry in inclusions:
            self.assertTrue((ROOT/entry.removesuffix('/**')).is_dir(), entry)
        self.assertEqual(settings['sonar.test.exclusions'], '**/*')
        self.assertNotIn('sonar.tests', settings)
        workflow = (ROOT/'.github/workflows/sonar-coverage.yml').read_text()
        self.assertIn("grep -E '^sonar\\.(inclusions|exclusions|test\\.exclusions|sourceEncoding)=' .sonarcloud.properties",
                      workflow)
        # Only runtime code is measured: no automation coverage report, website coverage of its pages only.
        self.assertNotIn('python.coverage', workflow)
        self.assertNotIn("--test-coverage-include='website/scripts", workflow)

    def test_every_native_job_runs_mock_ui_and_remains_required(self):
        ci = (ROOT/'.github/workflows/ci.yml').read_text()
        commands = {
            'apple-apps': 'test-apple-ui.sh macos',
            'ios-app': 'test-apple-ui.sh ios',
            'linux': 'linux/scripts/test-ui-journeys.py',
            'android': 'android/scripts/test-journeys.sh',
            'windows': 'windows/scripts/test-mock-workflows.ps1',
        }
        aggregate = ci.split('\n  result:', 1)[1]
        for job, command in commands.items():
            body = ci.split(f'\n  {job}:', 1)[1]
            body = re.split(r'\n  [a-z][a-z-]*:', body, maxsplit=1)[0]
            self.assertIn(command, body, job)
            self.assertNotIn('continue-on-error:', body, job)
            if job in ('apple-apps', 'ios-app'):
                # Apple UI journeys are paused unless the repository variable enables them.
                step = body.split(command, 1)[0].rsplit('\n      - ', 1)[1]
                self.assertIn("if: vars.APPLE_UI_TESTS == 'true'", step, job)
            self.assertIn('if: always()', body, job)
            self.assertIn(job, re.search(r'needs: \[([^\]]+)\]', aggregate).group(1))
        self.assertIn('windows/scripts/test-verification-journeys.ps1', ci)
        self.assertNotIn('reserve-android-version', ci)
        self.assertNotIn('fastlane', ci)
        self.assertNotIn('gh release', ci)

    def test_lifecycle_suites_remain_in_commit_ci(self):
        ci = (ROOT / '.github/workflows/ci.yml').read_text()
        for script in ('test-first-launch.ps1', 'test-demo-mode.ps1',
                       'test-card-page-scroll.ps1', 'test-insertion-helper.ps1'):
            self.assertIn(script, ci)
        apple = (ROOT / 'apple/scripts/run-mock-ui-tests.sh').read_text()
        for suite in ('CardCarouselUITests', 'DemoModeUITests', 'ProtectionFlowUITests', 'DocumentsUITests', 'FloatingActionUITests'):
            self.assertIn(suite, apple)

    def test_ios_runs_after_macos_without_requiring_macos_success(self):
        ci = (ROOT / '.github/workflows/ci.yml').read_text()
        ios = ci.split('\n  ios-app:', 1)[1].split('\n  linux:', 1)[0]
        self.assertIn('needs: [changes, apple-apps]', ios)
        self.assertIn("!cancelled() && needs.changes.result == 'success'", ios)
        self.assertNotIn("needs.apple-apps.result == 'success'", ios)

    def test_ios_budget_limits_preserve_failure_evidence(self):
        ci = (ROOT / '.github/workflows/ci.yml').read_text()
        ios = ci.split('\n  ios-app:', 1)[1].split('\n  linux:', 1)[0]
        self.assertIn('\n    timeout-minutes: 90\n', ios)
        self.assertIn('family: [iPhone, iPad]', ios)
        self.assertIn('max-parallel: 1', ios)
        self.assertIn('fail-fast: false', ios)
        self.assertIn('"${{ matrix.family }}"', ios)
        self.assertIn('name: ios-ui-${{ matrix.family }}-${{ github.sha }}', ios)
        limits = {'Require iPhone Duo SDK': 2, 'Build iOS and share extension': 5,
                  'Swift core and app policy unit tests on the simulator': 20,
                  'Prepare the UI test harness and fixtures': 5, 'Native iOS mock UI journeys': 60, 'iOS UI evidence': 3}
        for name, expected in limits.items():
            step = ios.split(f'- name: {name}\n', 1)[1].split('\n      - ', 1)[0]
            limit = int(re.search(r'timeout-minutes: (\d+)', step).group(1))
            self.assertEqual(limit, expected, name)
        build = ios.split('- name: Prepare the UI test harness and fixtures', 1)[1].split('- name: Native iOS mock UI journeys', 1)[0]
        self.assertIn('prepare-ios-ui-resources.sh', build)
        self.assertIn("if: vars.APPLE_UI_TESTS == 'true'", build)
        self.assertIn('MSIGN_UI_RESOURCES_DIR=', ios)
        # Unit tests run on both families even while the UI journeys are paused.
        unit = ios.split('- name: Swift core and app policy unit tests on the simulator\n', 1)[1].split('\n      - ', 1)[0]
        self.assertNotIn('if:', unit)
        self.assertIn('run-ios-unit-tests.sh "${{ matrix.family }}"', unit)
        evidence = ios.split('- name: iOS UI evidence', 1)[1]
        self.assertIn('if: always()\n', evidence)
        self.assertIn('ios-unit/*.xcresult', evidence)
        self.assertIn('actions/upload-artifact@', evidence)
