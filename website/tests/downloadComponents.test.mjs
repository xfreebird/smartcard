import './support/register.mjs';
import {afterEach, test} from 'node:test';
import assert from 'node:assert/strict';
import {readFile} from 'node:fs/promises';
import {jsx, render, textOf} from './support/react.mjs';
import {resetSite} from './support/site.mjs';
import {installBrowser} from './support/browser.mjs';

const catalog = JSON.parse(await readFile(new URL('../src/i18n/catalog.json', import.meta.url), 'utf8'));
const release = JSON.parse(await readFile(new URL('../src/data/release.json', import.meta.url), 'utf8'));
const {default: Downloads} = await import('../src/components/Downloads.jsx');
const {default: DownloadsPage} = await import('../src/pages/downloads.jsx');
let browser;
afterEach(() => {
  browser?.restore();
  browser = null;
  resetSite();
});

const placeControl = rect => (element, node) => {
  if (node.props.className === 'download-control') element.rect = rect;
};

test('primary download action follows the detected platform', () => {
  browser = installBrowser();
  const cases = {ios: ['/downloads#ios', 'downloadOptions'], android: ['/downloads#android', 'downloadOptions'],
    windows: ['/downloads#windows', 'downloadOptions'], macos: ['/downloads#macos', 'download'],
    linux: ['/downloads#linux', 'downloadLinux'], other: ['/downloads', 'download']};
  for (const [platform, [href, key]] of Object.entries(cases)) {
    const root = render(jsx(Downloads, {platform}));
    const link = root.find(node => node.type === 'a' && String(node.props.className).startsWith('download-button'));
    assert.equal(link.props.href, href, platform);
    assert.ok(textOf(link).endsWith(catalog[key].en), platform);
  }
  const direct = render(jsx(Downloads, {platform: 'macos', directOnly: true}));
  assert.equal(direct.findAll('button').length, 0);
  assert.equal(direct.find('a').props.className, 'download-button download-button-single');
  browser.media('(hover: hover) and (min-width: 761px)').matches = true;
  direct.fire(direct.find(node => node.props.className === 'download-control'), 'onMouseEnter');
  assert.equal(direct.findAll(node => node.props.id).length, 0);
});

test('the menu opens above when space below is short and closes on outside actions', () => {
  browser = installBrowser({height: 900});
  const root = render(jsx(Downloads, {platform: 'windows'}), {decorate: placeControl({top: 700, bottom: 740})});
  const toggle = root.find('button');
  assert.equal(toggle.props['aria-expanded'], false);
  root.fire(toggle, 'onClick');
  const menu = root.find(node => String(node.props.className).startsWith('download-options'));
  assert.equal(menu.props.className, 'download-options download-options-above');
  assert.equal(menu.props.style['--download-menu-space'], '604px');
  assert.equal(menu.props.id, root.find('button').props['aria-controls']);
  const entries = root.findAll(node => node.type === 'a' && String(node.props.href).startsWith('/downloads#'));
  assert.deepEqual(entries.map(node => node.props.href).slice(1),
    release.platforms.filter(item => item.icon !== 'cli').map(item => `/downloads#${item.id}`));
  const control = root.elementFor(root.find(node => node.props.className === 'download-control'));
  browser.document.dispatch('pointerdown', {target: control.querySelector('button')});
  assert.ok(root.findAll(node => node.props.id === menu.props.id).length);
  browser.document.dispatch('pointerdown', {target: {parentElement: null}});
  assert.equal(root.findAll(node => node.props.id === menu.props.id).length, 0);
  assert.equal(browser.document.count('pointerdown'), 0);

  root.fire(root.find('button'), 'onClick');
  root.fire(root.byText(catalog.allDownloads.en, 'a'), 'onClick');
  assert.equal(root.findAll('svg').length, 2);
  root.fire(root.find('button'), 'onClick');
  root.fire(root.find(node => node.props['aria-label'] === catalog.closeDownloads.en), 'onClick');
  root.fire(root.find('button'), 'onClick');
  root.fire(root.findAll(node => node.type === 'a' && node.props.href === '/downloads#linux')[0], 'onClick');
  assert.equal(root.find('button').props['aria-expanded'], false);
});

test('hover, focus loss and Escape control the menu', () => {
  browser = installBrowser({media: {'(hover: hover) and (min-width: 761px)': true}});
  const root = render(jsx(Downloads, {optionsOnly: true}), {decorate: placeControl({top: 10, bottom: 50})});
  const control = () => root.find(node => node.props.className === 'download-control');
  assert.equal(root.find('button').props.className, 'download-options-primary');
  root.fire(control(), 'onMouseEnter');
  const menu = root.find(node => String(node.props.className).startsWith('download-options '.trim()) && node.props.id);
  assert.equal(menu.props.className, 'download-options');
  assert.equal(menu.props.style['--download-menu-space'], '886px');
  const element = root.elementFor(control());
  root.fire(control(), 'onBlur', {relatedTarget: element.querySelector('button')});
  assert.equal(root.find('button').props['aria-expanded'], true);
  root.fire(control(), 'onBlur', {relatedTarget: null});
  assert.equal(root.find('button').props['aria-expanded'], false);
  root.fire(root.find('button'), 'onClick');
  root.fire(control(), 'onMouseLeave');
  assert.equal(root.find('button').props['aria-expanded'], false);
  root.fire(root.find('button'), 'onClick');
  element.dispatch('keydown', {key: 'Enter'});
  assert.equal(root.find('button').props['aria-expanded'], true);
  element.dispatch('keydown', {key: 'Escape'});
  assert.equal(root.find('button').props['aria-expanded'], false);
  assert.deepEqual(element.querySelector('button').calls.at(-1), ['focus', undefined]);
  root.unmount();
  assert.equal(element.listeners.get('keydown').size, 0);
});

function placeSections(rects) {
  return (element, node) => {
    if (node.type === 'nav') element.rect = {top: 0, bottom: 64, height: 64};
    if (rects[node.props.id]) element.rect = rects[node.props.id];
  };
}

test('download page follows the hash, scroll position and explicit selection', () => {
  browser = installBrowser({hash: '#cli', height: 800});
  const rects = {macos: {top: -700, bottom: -100}, windows: {top: 100, bottom: 700}, ios: {top: 700, bottom: 1300},
    android: {top: 1300, bottom: 1900}, linux: {top: 1900, bottom: 2900}};
  const root = render(jsx(DownloadsPage, {}), {decorate: placeSections(rects)});
  const selected = () => root.find(node => node.props['aria-current'] === 'location').props.href;
  assert.equal(selected(), '#macos');
  assert.deepEqual(browser.window.history.entries[0], ['replace', '#macos']);
  assert.deepEqual(root.elementFor(root.byId('macos')).calls[0], ['scrollIntoView', {block: 'start', behavior: 'instant'}]);
  assert.equal(root.elementFor(root.find('main')).style.properties['--download-platform-nav-height'], '64px');
  assert.equal(browser.runFrames(), 1);
  assert.equal(selected(), '#windows');
  assert.deepEqual(browser.window.history.entries.at(-1), ['replace', '#windows']);

  browser.window.location.hash = '#android';
  browser.window.dispatch('hashchange');
  assert.equal(selected(), '#android');
  browser.window.location.hash = '#nothing';
  browser.window.dispatch('hashchange');
  assert.equal(selected(), '#android');

  rects.windows.top = 5000;
  browser.window.dispatch('scroll');
  browser.window.dispatch('resize');
  assert.equal(browser.runFrames(), 1);
  assert.equal(selected(), '#ios');

  const linuxLink = root.find(node => node.type === 'a' && node.props.href === '#linux');
  const event = {button: 0, metaKey: false, ctrlKey: false, shiftKey: false, altKey: false};
  root.fire(linuxLink, 'onClick', {...event, metaKey: true});
  assert.equal(selected(), '#ios');
  const click = root.fire(linuxLink, 'onClick', event);
  assert.equal(click, undefined);
  assert.equal(selected(), '#linux');
  assert.deepEqual(browser.window.history.entries.at(-1), ['push', '#linux']);
  assert.deepEqual(root.elementFor(root.byId('linux')).calls.slice(-2).map(call => call[0]), ['focus', 'scrollIntoView']);
  root.fire(linuxLink, 'onClick', event);
  assert.equal(browser.window.history.entries.filter(entry => entry[0] === 'push').length, 1);

  root.fire(root.byId('android'), 'onClick');
  assert.equal(selected(), '#android');
  root.fire(root.find(node => node.type === 'button' && node.props['aria-pressed'] === false), 'onClick');
  assert.equal(selected(), '#macos');
  const observer = browser.ResizeObserver.instances.at(-1);
  assert.equal(observer.observed.size, 6);
  root.unmount();
  assert.equal(observer.disconnected, 1);
  assert.equal(browser.window.count('scroll') + browser.window.count('hashchange') + browser.window.visualViewport.count('resize'), 0);
});

test('download page groups standalone apps before command-line tools', () => {
  browser = installBrowser({height: 0});
  resetSite({locale: 'ro'});
  const root = render(jsx(DownloadsPage, {}), {decorate: placeSections({})});
  const linux = root.byId('linux');
  const labels = root.hosts(linux.children).filter(node => node.type === 'h3').map(textOf);
  assert.deepEqual(labels.slice(0, 2), ['Aplicație independentă', 'Instrumente în linia de comandă']);
  const installers = root.hosts(linux.children).filter(node => node.type === 'a' && node.props.className?.startsWith('download-installer'));
  assert.equal(installers[0].props.className, 'download-installer download-installer-primary');
  assert.ok(textOf(installers[0]).startsWith('Aplicație desktop · '));
  assert.ok(installers.some(node => textOf(node).startsWith('Instrumente CLI și MCP · ')));
  const mac = textOf(root.byId('macos'));
  assert.ok(mac.includes('Aplicație desktop · DMG') && mac.includes(catalog.macAppStoreLimitations.ro));
  const windows = textOf(root.byId('windows'));
  assert.ok(windows.includes('Program de instalare desktop · MSI'));
  assert.ok(windows.includes(release.platforms.find(item => item.id === 'windows').installerNote.ro));
  const android = root.byId('android');
  assert.equal(root.hosts(android.children).filter(node => node.type === 'h3' && node.props.className === 'download-group-label').length, 0);
  assert.ok(textOf(android).includes(catalog.downloadFormat.ro.replace('{format}', 'APK')));
  assert.ok(textOf(root.byId('ios')).includes(release.platforms.find(item => item.id === 'ios').alternatives[0].label.ro));
  assert.equal(root.findAll(node => node.type === 'section').length, release.platforms.length - 1);
  root.unmount();
  resetSite({locale: 'xx'});
  const fallback = render(jsx(DownloadsPage, {}), {decorate: placeSections({})});
  assert.ok(textOf(fallback.byId('linux')).includes('Desktop app and command-line tools · x86-64'));
  assert.equal(browser.runFrames(), 1);
});
