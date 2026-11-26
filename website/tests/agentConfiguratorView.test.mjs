import './support/register.mjs';
import {afterEach, test} from 'node:test';
import assert from 'node:assert/strict';
import {jsx, render, textOf} from './support/react.mjs';
import {installBrowser} from './support/browser.mjs';
import {configuration, initialSettings, skill} from '../src/components/agentConfiguration.mjs';

const {default: AgentConfigurator} = await import('../src/components/AgentConfigurator.jsx');
let browser;
afterEach(() => browser?.restore());

const field = (root, label) => root.find(node => node.type === 'label' && textOf(node).startsWith(label));
const input = (root, label) => root.hosts(field(root, label).children).find(node => node.type === 'input' || node.type === 'select');
const change = (root, label, value) => root.fire(input(root, label), 'onChange', {target: {value}});
const mode = (root, value) => root.fire(root.find(node => node.type === 'input' && node.props.value === value), 'onChange');

test('default setup renders the generated configuration and guide', () => {
  browser = installBrowser();
  const root = render(jsx(AgentConfigurator, {}));
  assert.equal(root.find('pre').children[0], configuration(initialSettings()));
  assert.equal(root.find('pre').props['data-language'], 'json');
  assert.ok(root.text().includes('Claude Code · macOS'));
  assert.ok(root.findAll('a').some(node => node.props.href === '/downloads/'));
  assert.equal(input(root, 'Installed MCP executable').props['aria-invalid'], false);
  assert.ok(textOf(field(root, 'Installed MCP executable')).includes('Apple Silicon Homebrew example'));
  assert.deepEqual(root.findAll(node => node.props.type === 'radio').map(node => node.props.checked), [true, false, false]);
  assert.ok(textOf(root.findAll('button').at(-1)).endsWith('skill'));
});

test('platform, client and mode choices update fields, notices and downloads', () => {
  browser = installBrowser();
  const root = render(jsx(AgentConfigurator, {}));
  change(root, 'AI agent', 'claude-desktop');
  change(root, 'Computer', 'linux');
  assert.ok(root.text().includes('Confirm that your Claude Desktop build supports Linux'));
  assert.equal(input(root, 'Installed MCP executable').props.value, '/usr/bin/esemnbun-mcp');
  assert.ok(textOf(root.findAll('button').at(-1)).endsWith('instructions'));
  mode(root, 'approval');
  assert.ok(root.text().includes('Private desktop approval directory'));
  change(root, 'AI agent', 'windsurf');
  assert.ok(textOf(root.findAll('button').at(-1)).endsWith('workflow'));
  change(root, 'AI agent', 'cline');
  assert.ok(textOf(root.findAll('button').at(-1)).endsWith('rule'));
  change(root, 'AI agent', 'codex');
  change(root, 'Computer', 'windows');
  assert.equal(input(root, 'Installed MCP executable').props.value, 'C:\\Program Files\\eSemnBun\\bin\\esemnbun.exe');
  assert.equal(root.find('pre').props['data-language'], 'toml');
  assert.ok(root.findAll(node => node.type === 'input' && node.props.value === 'approval')[0].props.checked);
  assert.ok(textOf(field(root, 'Installed MCP executable')).includes('Use the actual installed executable'));
});

test('unattended signing requires a certificate, provider reference and optional CLI path', () => {
  browser = installBrowser();
  const root = render(jsx(AgentConfigurator, {}));
  mode(root, 'unattended');
  assert.ok(root.text().includes('Unattended signing policy'));
  assert.equal(root.findAll('pre').length, 0);
  assert.ok(root.text().includes('Complete the highlighted fields'));
  const certificate = input(root, 'Signing certificate SHA-256');
  assert.equal(certificate.props['aria-invalid'], true);
  assert.equal(root.find(node => node.props.id === certificate.props['aria-describedby']).type, 'span');
  change(root, 'Signing certificate SHA-256', 'a'.repeat(64));
  change(root, 'Credential provider', 'onepassword');
  assert.equal(input(root, 'Credential reference').props.value, 'op://Vault/Item/field');
  assert.ok(textOf(field(root, 'Credential reference')).includes('Example: op://Vault/Item/field.'));
  assert.ok(root.text().includes('Installed 1Password CLI executable'));
  assert.equal(root.findAll('pre').length, 1);
  change(root, 'Credential reference', '1234');
  assert.equal(input(root, 'Credential reference').props['aria-invalid'], true);
  assert.deepEqual(root.findAll(node => node.type === 'option' && node.props.value === 'keychain').length, 1);
});

test('copy reports success or the manual fallback, and downloads create files', async () => {
  const writes = [];
  browser = installBrowser({clipboard: {writeText: async text => writes.push(text)}});
  const root = render(jsx(AgentConfigurator, {}));
  const button = label => root.find(node => node.type === 'button' && textOf(node).startsWith(label));
  await root.fire(button('Copy configuration'), 'onClick');
  assert.deepEqual(writes, [configuration(initialSettings())]);
  assert.equal(textOf(root.findAll(node => node.props['aria-live'] === 'polite')[0]), 'Configuration copied.');
  change(root, 'Folder the agent may read', '/Users/me/Other');
  assert.equal(textOf(root.find(node => node.props['aria-live'] === 'polite')), '');
  browser.values.navigator.clipboard.writeText = async () => {
    throw new Error('denied');
  };
  await root.fire(button('Copy configuration'), 'onClick');
  assert.match(textOf(root.find(node => node.props['aria-live'] === 'polite')), /^Copy is unavailable here/);

  const created = [];
  const original = URL.createObjectURL;
  URL.createObjectURL = blob => {
    created.push(blob);
    return `blob:fixture-${created.length}`;
  };
  try {
    root.fire(button('Download configuration'), 'onClick');
    root.fire(button('Download installation guide'), 'onClick');
    root.fire(button('Download document'), 'onClick');
  } finally {
    URL.createObjectURL = original;
  }
  assert.deepEqual(browser.created.map(anchor => [anchor.download, anchor.clicked]),
    [['.mcp.json', 1], ['esemnbun-claude-code-macos-setup.md', 1], ['SKILL.md', 1]]);
  assert.equal(await created[2].text(), skill);
  assert.equal(created[0].type, 'text/plain;charset=utf-8');
});
