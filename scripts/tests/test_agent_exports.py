"""Agent integration exporter command line and the website's generated client catalog."""
import io
import json
from pathlib import Path
import sys
from unittest.mock import patch
import zipfile

from support import REPO, TempCase, load, run


class ExportCommandTests(TempCase):
    def setUp(self):
        super().setUp()
        self.exporter = load('scripts/agents/export_integrations.py', 'export_integrations')

    def main(self, *argv):
        err = io.StringIO()
        with patch('sys.argv', ['export_integrations.py', *map(str, argv)]), patch('sys.stderr', err):
            try:
                self.exporter.main()
            except SystemExit as error:
                return error.code, err.getvalue()
        return 0, err.getvalue()

    def test_customized_export_writes_a_new_directory_only(self):
        output = self.tmp / 'gemini'
        code, _ = self.main('--client', 'gemini', '--platform', 'linux', '--command', '/usr/bin/esemnbun-mcp',
                            '--root', '/home/me/Signing', '--broker-directory', '/run/user/1000/esemnbun',
                            '--output', output)
        self.assertEqual(code, 0)
        server = json.loads((output / '.gemini/settings.json').read_text())['mcpServers']['esemnbun']
        self.assertEqual(server['args'], ['--root', 'documents=/home/me/Signing',
                                          '--broker-directory', '/run/user/1000/esemnbun'])
        self.assertIs(server['trust'], False)
        self.assertIn('This is a configuration fragment, not an installer.', (output / 'SETUP.md').read_text())
        code, err = self.main('--client', 'gemini', '--platform', 'linux', '--command', '/usr/bin/x',
                              '--root', '/home/me', '--output', output)
        self.assertEqual(code, 2)
        self.assertIn('File exists', err)

    def test_invalid_combinations_and_paths_are_usage_errors(self):
        cases = [
            (['--archive', self.tmp / 'a.zip', '--client', 'cursor'], '--archive cannot be combined'),
            (['--client', 'cursor'], 'are required'),
            (['--client', 'cursor', '--platform', 'windows', '--command', 'esemnbun.exe', '--root', r'C:\Docs',
              '--output', self.tmp / 'out'], 'absolute local path'),
        ]
        for argv, message in cases:
            with self.subTest(message=message):
                code, err = self.main(*argv)
                self.assertEqual(code, 2)
                self.assertIn(message, err)
        self.assertFalse((self.tmp / 'out').exists())

    def test_archive_contains_every_client_and_platform(self):
        target = self.tmp / 'nested/examples.zip'
        self.assertEqual(self.main('--archive', target)[0], 0)
        with zipfile.ZipFile(target) as archive:
            names = archive.namelist()
            roo = json.loads(archive.read('roo/windows/.roo/mcp.json'))
        self.assertEqual(len({name.split('/', 2)[0] for name in names}), len(self.exporter.CLIENTS))
        self.assertIn('claude-code/macos/plugin/.claude-plugin/plugin.json', names)
        self.assertEqual(roo['mcpServers']['esemnbun']['args'][0], 'mcp')
        self.assertEqual(roo['mcpServers']['esemnbun']['alwaysAllow'], [])


class WebDataTests(TempCase):
    def test_committed_agent_catalog_matches_generator(self):
        written = {}

        def capture(path, text, *args, **kwargs):
            written[Path(path)] = text
        with patch.object(Path, 'write_text', capture):
            result = run('scripts/agents/generate-web-data.py')
        self.assertEqual(result.code, 0)
        target = REPO / 'website/src/data/agent-integrations.json'
        self.assertEqual(list(written), [target])
        self.assertEqual(written[target], target.read_text())
        catalog = json.loads(written[target])
        self.assertEqual(catalog['clients'][0]['id'], 'claude-code')
        self.assertTrue(catalog['skill'].startswith('---'))
        self.assertIn('export_integrations', sys.modules)
