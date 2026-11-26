import './support/register.mjs';
import {afterEach, test} from 'node:test';
import assert from 'node:assert/strict';
import {readFile} from 'node:fs/promises';
import {jsx, render, textOf} from './support/react.mjs';
import {resetSite, site} from './support/site.mjs';
import {installBrowser} from './support/browser.mjs';

const load = async path => (await import(`../src/${path}`));
const json = async path => JSON.parse(await readFile(new URL(`../src/${path}`, import.meta.url), 'utf8'));
const release = await json('data/release.json');
const navigation = await json('data/guide-navigation.json');
const catalog = await json('i18n/catalog.json');
const {revision} = await json('data/screenshotRevision.json');
let browser;
afterEach(() => {
  browser?.restore();
  browser = null;
  resetSite();
});

test('text lookup follows the current locale and falls back to English or the key', async () => {
  const {default: useText} = await load('i18n/useText.js');
  let lookup;
  const Probe = () => {
    lookup = useText();
    return null;
  };
  resetSite({locale: 'ro'});
  render(jsx(Probe, {}));
  assert.equal(lookup('download'), catalog.download.ro);
  assert.equal(lookup('missing-key'), 'missing-key');
  resetSite({locale: 'xx'});
  render(jsx(Probe, {}));
  assert.equal(lookup('download'), catalog.download.en);
});

test('platform icons use local vectors and the credited Tux image', async () => {
  const {default: PlatformIcon} = await load('components/PlatformIcon.jsx');
  resetSite({baseUrl: '/preview/'});
  const tux = render(jsx(PlatformIcon, {name: 'linux', className: 'big'})).find('img');
  assert.equal(tux.props.src, '/preview/img/platforms/tux.svg');
  assert.equal(tux.props.className, 'platform-icon platform-icon-tux big');
  for (const name of ['macos', 'windows', 'cli', 'ios', 'android', 'chevron', 'external', 'github']) {
    const root = render(jsx(PlatformIcon, {name}));
    assert.equal(root.find('svg').props['aria-hidden'], 'true', name);
    assert.ok(root.findAll(node => ['path', 'rect', 'g', 'circle'].includes(node.type)).length, name);
  }
  const fallback = render(jsx(PlatformIcon, {name: 'unknown'}));
  assert.match(fallback.find('path').props.d, /^M12 3v12/);
});

test('device visuals and documentation screenshots follow base URL and colour mode', async () => {
  const {default: DeviceVisual} = await load('components/DeviceVisual.jsx');
  const image = render(jsx(DeviceVisual, {image: '/img/devices/reader.png', alt: 'Reader'})).find('img');
  assert.deepEqual([image.props.src, image.props.className, image.props.loading], ['/img/devices/reader.png', 'device-visual ', 'lazy']);
  const {default: PlatformScreenshots} = await load('components/PlatformScreenshots.jsx');
  resetSite({colorMode: 'dark'});
  const dark = render(jsx(PlatformScreenshots, {platform: 'linux', alt: 'Linux', caption: 'Native GTK'}));
  assert.equal(dark.find('img').props.src, `/img/docs/v0.2.0/linux/ready-dark.png?v=${revision}`);
  assert.equal(dark.find('figcaption').children[0], 'Native GTK');
  resetSite();
  const light = render(jsx(PlatformScreenshots, {platform: 'macos', scenario: 'sign', alt: 'Mac'}));
  assert.match(light.find('img').props.src, /\/macos\/sign-light\.png/);
  assert.equal(light.findAll('figcaption').length, 0);
});

test('preview selector lists every platform and reports changes', async () => {
  const {default: PlatformPreview} = await load('components/PlatformPreview.jsx');
  const changes = [];
  const root = render(jsx(PlatformPreview, {value: 'android', onChange: value => changes.push(value)}));
  const select = root.find('select');
  assert.equal(root.find('label').props.htmlFor, select.props.id);
  assert.deepEqual(root.findAll('option').map(textOf), ['Automatic', 'macOS', 'Windows', 'Linux', 'iPhone', 'Android']);
  root.fire(select, 'onChange', {target: {value: 'linux'}});
  assert.deepEqual(changes, ['linux']);
});

test('story progress exposes the current stage and segment fill', async () => {
  const {default: StoryProgress} = await load('components/StoryProgress.jsx');
  const root = render(jsx(StoryProgress, {progress: .5, step: 1, stages: ['document', 'device', 'reader', 'signature'],
    boundaries: [0, .25, .5, .75, 1], t: key => key.toUpperCase(), label: 'How'}));
  const bar = root.find(node => node.props.role === 'progressbar');
  assert.deepEqual([bar.props['aria-valuenow'], bar.props['aria-valuetext']], [50, '2/4 DEVICE']);
  const fills = root.findAll('i').map(node => node.props.style.transform);
  assert.deepEqual(fills, ['scaleX(1)', 'scaleX(1)', 'scaleX(0)', 'scaleX(0)']);
  assert.equal(root.find('path').props.d, 'M5 4h14v12H5z M9 20h6 M12 16v4');
});

test('story screens change only to decoded captures', async () => {
  const failing = new Set();
  browser = installBrowser({images: source => failing.has(source.split('?')[0].split('/').pop()) ? Promise.reject(new Error('404')) : Promise.resolve()});
  const {default: StoryScreen} = await load('components/StoryScreen.jsx');
  const screen = {x: 1, y: 2, width: 3, height: 4};
  failing.add('card-dark.png');
  const props = {root: '/img/landing/', platform: 'iphone', appearance: 'dark', screen, clip: 'clip'};
  const root = render(jsx(StoryScreen, {...props, stage: 'card'}));
  assert.equal(root.find('g').props['data-screen-stage'], 0);
  await new Promise(resolve => setImmediate(resolve));
  assert.equal(root.find('g').props['data-screen-stage'], 2);
  assert.equal(root.find('rect').props.fill, '#202124');
  assert.equal(browser.Image.sources.length, 5);
  root.rerender(jsx(StoryScreen, {...props, stage: 'nfc'}));
  assert.equal(root.find('g').props['data-screen-stage'], 3);
  root.rerender(jsx(StoryScreen, {...props, platform: 'macos', appearance: 'light', stage: 'reader'}));
  assert.equal(root.find('g').props['data-screen-stage'], 0);
  assert.equal(root.find('rect').props.fill, '#f5f5f7');
  await new Promise(resolve => setImmediate(resolve));
  assert.equal(root.find('g').props['data-screen-stage'], 1);
  assert.match(root.find('image').props.href, /\/macos\/reader-light\.png\?v=/);
  root.unmount();
});

test('mobile and desktop store badges match release data', async () => {
  const {default: MobileStores, StoreBadge} = await load('components/MobileStores.jsx');
  resetSite({locale: 'ro'});
  const android = render(jsx(MobileStores, {platform: 'android'}));
  const stores = release.platforms.find(item => item.id === 'android');
  assert.deepEqual(android.findAll('a').map(node => node.props.href), [stores.store.url, ...stores.additionalStores.map(item => item.url)]);
  assert.equal(android.find('img').props.src, stores.store.badges.ro);
  assert.ok(android.text().includes(catalog.storeStatus_android.ro));
  const mac = render(jsx(MobileStores, {platform: 'macos'}));
  assert.deepEqual([mac.find('img').props.width, mac.find('img').props.className], [250, 'apple-store-badge']);
  assert.equal(mac.find('p').props.className, 'store-version-limitations');
  const ios = render(jsx(MobileStores, {platform: 'ios'}));
  assert.equal(ios.find('img').props.height, 50);
  assert.ok(ios.text().includes(catalog.storeStatus_ios.ro));
  assert.equal(render(jsx(MobileStores, {platform: 'linux'})).tree.length, 0);
  const text = render(jsx(StoreBadge, {store: {name: 'Store', url: 'https://store.example'}, locale: 'en'}));
  assert.equal(textOf(text.find('span')), 'Store ↗');
  const english = render(jsx(StoreBadge, {store: {name: 'S', url: 'u', badges: {en: '/en.svg'}}, locale: 'ru'}));
  assert.equal(english.find('img').props.src, '/en.svg');
});

test('package instructions are localized per platform', async () => {
  const {default: PackageDownloads} = await load('components/PackageDownloads.jsx');
  const packages = await json('data/package-release.json');
  const mac = render(jsx(PackageDownloads, {platform: 'macos'}));
  assert.equal(mac.find('pre').children[0], 'brew install xfreebird/utils/esemnbun-cli');
  resetSite({locale: 'ru'});
  const windows = render(jsx(PackageDownloads, {platform: 'windows'}));
  assert.equal(windows.byText('Скачать пакет Chocolatey', 'a').props.href, `/packages/downloads/v${packages.version}/esemnbun-cli.${packages.version}.nupkg`);
  resetSite({locale: 'xx'});
  const linux = render(jsx(PackageDownloads, {platform: 'linux'}));
  assert.equal(linux.findAll('details').length, 3);
  assert.ok(linux.text().includes('Verify the signing-key fingerprint'));
  assert.equal(render(jsx(PackageDownloads, {platform: 'ios'})).tree.length, 0);
});

test('root adds text, JSON and localized Markdown discovery links', async () => {
  const {default: Root} = await load('theme/Root/index.jsx');
  resetSite({pathname: '/docs/moldsign/'});
  const english = render(jsx(Root, {children: jsx('main', {})}));
  const links = english.findAll('link').map(node => [node.props.type, node.props.href]);
  assert.deepEqual(links, [['text/plain', 'https://esemnbun.md/llms.txt'], ['application/json', 'https://esemnbun.md/discovery.json'],
    ['text/markdown', 'https://esemnbun.md/markdown/moldsign.md']]);
  assert.equal(english.findAll('main').length, 1);
  resetSite({locale: 'ro', pathname: '/ro/docs/developers/overview/'});
  assert.equal(render(jsx(Root, {})).findAll('link').length, 2);
  resetSite({pathname: '/docs/developers/overview/'});
  assert.equal(render(jsx(Root, {})).findAll('link')[2].props.href, 'https://esemnbun.md/markdown/developers/overview.md');
  resetSite({pathname: '/downloads/'});
  assert.equal(render(jsx(Root, {})).findAll('link').length, 2);
});

test('legacy guide anchors redirect to the focused task page', async () => {
  const {default: GuideAnchorRedirect} = await load('components/GuideAnchorRedirect.jsx');
  const platform = navigation.platforms.find(item => Object.keys(item.anchors.en || {}).length);
  const [anchor, target] = Object.entries(platform.anchors.en)[0];
  browser = installBrowser({hash: `#${encodeURIComponent(anchor)}`});
  assert.equal(render(jsx(GuideAnchorRedirect, {platform: platform.id})).tree.length, 0);
  assert.deepEqual(browser.window.location.replaced, [`/docs/platforms/${platform.id}/${target}`]);
  browser.window.location.hash = '#unknown';
  render(jsx(GuideAnchorRedirect, {platform: platform.id}));
  browser.window.location.hash = '#%E0%A4%A';
  render(jsx(GuideAnchorRedirect, {platform: 'missing'}));
  assert.equal(browser.window.location.replaced.length, 1);
});

test('browser platform starts neutral and then follows the user agent', async () => {
  const {default: useBrowserPlatform} = await load('components/useBrowserPlatform.js');
  const seen = [];
  const Probe = () => {
    seen.push(useBrowserPlatform());
    return null;
  };
  browser = installBrowser({userAgent: 'Mozilla/5.0 (Macintosh)', maxTouchPoints: 5});
  render(jsx(Probe, {}));
  assert.deepEqual(seen, ['other', 'ios']);
  browser.restore();
  browser = installBrowser({userAgent: 'Mozilla/5.0 (Windows NT 10.0)', maxTouchPoints: undefined});
  seen.length = 0;
  render(jsx(Probe, {}));
  assert.deepEqual(seen, ['other', 'windows']);
  assert.equal(site.locale, 'en');
});
