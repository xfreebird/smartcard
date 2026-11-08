"""Focused exporter checks: escaping, explicit authority and no config replacement."""
import hashlib
import json
from pathlib import Path
import tempfile
import unittest
import zipfile

from export_integrations import CLIENTS, archive, examples, files, render, write_new


class ExportTests(unittest.TestCase):
    def test_all_clients_preserve_windows_command_and_arguments(self):
        command = r'C:\Program Files\eSemnBun\bin\esemnbun.exe'
        root = 'C:\\Users\\Someone\\Signing & Contracts ș'
        for client in CLIENTS:
            with self.subTest(client=client):
                text = render(client, 'windows', command, root)
                if client == 'codex':
                    # Each value is a JSON/TOML basic-string or array; decode back exactly.
                    rows = text.splitlines()
                    self.assertEqual(json.loads(rows[1].split(' = ', 1)[1]), command)
                    args = json.loads(rows[2].split(' = ', 1)[1])
                else:
                    config = json.loads(text)
                    if client == 'opencode':
                        server = config['mcp']['servers']['esemnbun']
                        self.assertEqual(server['command'][0], command)
                        args = server['command'][1:]
                    else:
                        server = config['servers' if client == 'vscode' else 'mcpServers']['esemnbun']
                        self.assertEqual(server['command'], command)
                        args = server['args']
                self.assertEqual(args, ['mcp', '--root', 'documents=' + root])

    def test_posix_spaces_quotes_and_backslashes_round_trip(self):
        for client in CLIENTS:
            text = render(client, 'linux', '/opt/My App/esemnbun-mcp', '/home/me/a "quote" \\ and ș')
            if client != 'codex':
                self.assertIsInstance(json.loads(text), dict)
            else:
                self.assertEqual(json.loads(text.splitlines()[2].split(' = ', 1)[1]), ['--root', 'documents=/home/me/a "quote" \\ and ș'])

    def test_broker_is_explicit_and_no_unattended_defaults(self):
        for client in CLIENTS:
            basic = render(client, 'linux', '/usr/bin/esemnbun-mcp', '/home/me/Signing')
            configured = render(client, 'linux', '/usr/bin/esemnbun-mcp', '/home/me/Signing', '/home/me/Private Broker')
            self.assertNotIn('--broker-directory', basic)
            self.assertIn('--broker-directory', configured)
            for forbidden in ['--allow-unattended-signing', '--pin-source', 'MSIGN_PIN', 'ESEMNBUN_AUTOMATION_PIN']:
                self.assertNotIn(forbidden, configured)
        self.assertEqual(json.loads(render('cline', 'linux', '/bin/helper', '/data'))['mcpServers']['esemnbun']['autoApprove'], [])
        self.assertEqual(json.loads(render('roo', 'linux', '/bin/helper', '/data'))['mcpServers']['esemnbun']['alwaysAllow'], [])
        self.assertFalse(json.loads(render('gemini', 'linux', '/bin/helper', '/data'))['mcpServers']['esemnbun']['trust'])

    def test_non_absolute_or_control_character_paths_rejected(self):
        for platform, path in [('linux', '~/Signing'), ('linux', 'relative'), ('macos', '/line\nbreak'), ('windows', r'C:relative'), ('windows', r'\\server\share')]:
            with self.subTest(platform=platform, path=path), self.assertRaises(ValueError):
                render('cursor', platform, path, path)

    def test_never_replaces_existing_configuration(self):
        with tempfile.TemporaryDirectory() as temp:
            target = Path(temp) / 'existing'
            target.mkdir()
            config = target / 'config.toml'
            config.write_text('keep my other servers')
            with self.assertRaises(FileExistsError):
                write_new(target, files('codex', 'linux', '/bin/helper', '/data'))
            self.assertEqual(config.read_text(), 'keep my other servers')
            self.assertEqual(list(target.iterdir()), [config])

    def test_all_platform_packages_and_plugin_have_consistent_authority(self):
        content = examples()
        for client in CLIENTS:
            for platform in ['macos', 'linux', 'windows']:
                prefix = f'{client}/{platform}/'
                self.assertIn(prefix + CLIENTS[client][1], content)
                self.assertIn(prefix + CLIENTS[client][2], content)
                if client == 'claude-code':
                    self.assertEqual(content[prefix + '.mcp.json'], content[prefix + 'plugin/.mcp.json'])
                    self.assertEqual(json.loads(content[prefix + 'plugin/.claude-plugin/plugin.json'])['name'], 'esemnbun')

    def test_download_archive_is_deterministic_and_current(self):
        with tempfile.TemporaryDirectory() as temp:
            a, b = Path(temp) / 'a.zip', Path(temp) / 'b.zip'
            archive(a)
            archive(b)
            self.assertEqual(hashlib.sha256(a.read_bytes()).digest(), hashlib.sha256(b.read_bytes()).digest())
            published = Path(__file__).resolve().parents[2] / 'website/static/downloads/esemnbun-agent-integrations.zip'
            self.assertEqual(a.read_bytes(), published.read_bytes(), 'Regenerate the public pack after changes')
            with zipfile.ZipFile(a) as package:
                self.assertEqual(set(package.namelist()), set(examples()))
                for name, text in examples().items():
                    self.assertEqual(package.read(name).decode(), text)


if __name__ == '__main__':
    unittest.main()
