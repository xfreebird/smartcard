#!/usr/bin/env python3
"""Export reviewable MCP config fragments and instructions; never install or start a client."""
import argparse
import json
from pathlib import Path, PureWindowsPath
import zipfile

ROOT = Path(__file__).resolve().parents[2]
SKILL = ROOT / 'distribution/agents/skills/esemnbun-documents/SKILL.md'
CLIENTS = {
    'claude-code': ('Claude Code', '.mcp.json', '.claude/skills/esemnbun-documents/SKILL.md'),
    'claude-desktop': ('Claude Desktop', 'claude_desktop_config.json', 'esemnbun-instructions.md'),
    'codex': ('Codex (CLI, desktop and IDE)', 'config.toml', '.agents/skills/esemnbun-documents/SKILL.md'),
    'cursor': ('Cursor', '.cursor/mcp.json', '.cursor/skills/esemnbun-documents/SKILL.md'),
    'vscode': ('GitHub Copilot in VS Code', '.vscode/mcp.json', '.github/skills/esemnbun-documents/SKILL.md'),
    'gemini': ('Gemini CLI', '.gemini/settings.json', '.gemini/skills/esemnbun-documents/SKILL.md'),
    'windsurf': ('Windsurf / Cascade', 'mcp_config.json', '.windsurf/workflows/esemnbun-documents.md'),
    'cline': ('Cline', 'cline_mcp_settings.json', '.clinerules/esemnbun-documents.md'),
    'roo': ('Roo Code', '.roo/mcp.json', '.roo/rules/esemnbun-documents.md'),
    'opencode': ('OpenCode', 'opencode.json', '.opencode/skills/esemnbun-documents/SKILL.md'),
}


def absolute(value, platform):
    # PureWindowsPath allows cross-platform generation without rewriting drive paths.
    if platform == 'windows':
        p = PureWindowsPath(value)
        valid = p.is_absolute() and len(p.drive) == 2 and p.drive[1] == ':'
    else:
        valid = value.startswith('/')
    if not valid or any(ord(c) < 32 for c in value):
        raise ValueError('Use an absolute local path without control characters')
    return value


def render(client, platform, command, root, broker=None):
    command = absolute(command, platform)
    root = absolute(root, platform)
    args = ['mcp'] if platform == 'windows' else []
    args += ['--root', 'documents=' + root]
    if broker:
        args += ['--broker-directory', absolute(broker, platform)]
    server = {'command': command, 'args': args}
    if client == 'codex':
        # JSON's escaped basic strings/arrays are also valid TOML for these values.
        return '[mcp_servers.esemnbun]\ncommand = ' + json.dumps(command, ensure_ascii=False) + '\nargs = ' + json.dumps(args, ensure_ascii=False) + '\n'
    if client == 'opencode':
        config = {'mcp': {'servers': {'esemnbun': {'type': 'local', 'command': [command] + args, 'protocol': '2026-07-28'}}}}
    elif client == 'vscode':
        config = {'servers': {'esemnbun': {'type': 'stdio', **server}}}
    else:
        if client == 'cline':
            server.update(disabled=False, autoApprove=[])
        if client == 'roo':
            server.update(disabled=False, alwaysAllow=[])
        if client == 'gemini':
            server['trust'] = False
        config = {'mcpServers': {'esemnbun': server}}
    return json.dumps(config, indent=2, ensure_ascii=False) + '\n'


def files(client, platform, command, root, broker=None):
    name, config_path, instruction_path = CLIENTS[client]
    skill = SKILL.read_text()
    body = skill.split('---', 2)[2].lstrip()
    instructions = skill if instruction_path.endswith('SKILL.md') else body
    if client == 'windsurf':
        instructions = '---\ndescription: Verify signatures or request eSemnBun smartcard signing\n---\n\n' + body
    result = {
        config_path: render(client, platform, command, root, broker),
        instruction_path: instructions,
        'SETUP.md': f'''# {name}: eSemnBun

This is a configuration fragment, not an installer. Merge only the esemnbun server into
an existing configuration; preserve other servers and settings. Copy the instruction file
to the indicated workspace location. For Claude Desktop, paste the instruction body into
Project instructions (or attach it in the conversation); it is not an auto-loaded skill.
For Windsurf use Open MCP config file and merge there; the filename here is a fragment.
For Cline use MCP Servers > Configure MCP Servers. See the guide for global config locations.

The configured executable/root must already exist on the machine running the agent.
Exporting does not validate executable identity, directory permissions or symlink ancestry.
Check installed version, canonical physical paths and private broker permissions first.
No broker argument means offline verification only; signing needs separate setup.
The export never enables unattended signing, changes host permissions or stores PINs.

Restart/reload the client, trust the server configuration, list tools, and call capabilities.
Verify a fictional signed fixture before real use. Legacy clients must negotiate 2025-11-25;
modern clients must support 2026-07-28. Older revisions are rejected, not downgraded.
Configuration is based on official documentation; end-to-end client validation is pending.

Full guide: https://esemnbun.md/docs/integrations/mcp-agents/
Policy: https://esemnbun.md/packages/mcp.md
''',
    }
    if client == 'claude-code':
        # Local plugin can be loaded instead of the individual skill + .mcp.json.
        prefix = 'plugin/'
        result[prefix + '.claude-plugin/plugin.json'] = json.dumps({'name': 'esemnbun', 'version': '0.1.0', 'description': 'Local document signature verification and smartcard signing'}, indent=2) + '\n'
        result[prefix + 'skills/esemnbun-documents/SKILL.md'] = skill
        result[prefix + '.mcp.json'] = result[config_path]
    return result


def write_new(destination, content):
    # Require a new output directory. Never overwrite personal MCP/agent configuration.
    destination.mkdir(parents=True, exist_ok=False)
    for name, value in content.items():
        target = destination / name
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(value, encoding='utf-8')


def examples():
    result = {}
    defaults = {
        'macos': ('/opt/homebrew/bin/esemnbun-mcp', '/Users/me/Documents/Signing'),
        'linux': ('/usr/bin/esemnbun-mcp', '/home/me/Documents/Signing'),
        'windows': (r'C:\Program Files\eSemnBun\bin\esemnbun.exe', r'C:\Users\me\Documents\Signing'),
    }
    for client in CLIENTS:
        for platform, (command, root) in defaults.items():
            for name, value in files(client, platform, command, root).items():
                result[f'{client}/{platform}/{name}'] = value
    return result


def archive(destination):
    destination.parent.mkdir(parents=True, exist_ok=True)
    with zipfile.ZipFile(destination, 'w', zipfile.ZIP_DEFLATED) as output:
        for name, value in sorted(examples().items()):
            item = zipfile.ZipInfo(name, (2026, 11, 8, 0, 0, 0))
            item.compress_type = zipfile.ZIP_DEFLATED
            item.external_attr = 0o100644 << 16
            output.writestr(item, value.encode('utf-8'))


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--client', choices=CLIENTS)
    parser.add_argument('--platform', choices=['macos', 'linux', 'windows'])
    parser.add_argument('--command')
    parser.add_argument('--root')
    parser.add_argument('--broker-directory')
    parser.add_argument('--output', type=Path)
    parser.add_argument('--archive', type=Path, help='Build all-platform example ZIP instead of a customized export')
    args = parser.parse_args()
    if args.archive:
        if any([args.client, args.platform, args.command, args.root, args.broker_directory, args.output]):
            parser.error('--archive cannot be combined with export options')
        archive(args.archive)
    else:
        if not all([args.client, args.platform, args.command, args.root, args.output]):
            parser.error('--client, --platform, --command, --root and --output are required')
        try:
            write_new(args.output, files(args.client, args.platform, args.command, args.root, args.broker_directory))
        except (ValueError, FileExistsError) as error:
            parser.error(str(error))


if __name__ == '__main__':
    main()
