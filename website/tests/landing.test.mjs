import './support/register.mjs';
import {afterEach, test} from 'node:test';
import assert from 'node:assert/strict';
import {readFile} from 'node:fs/promises';
import {jsx, render, textOf} from './support/react.mjs';
import {resetSite} from './support/site.mjs';
import {installBrowser} from './support/browser.mjs';

const catalog = JSON.parse(await readFile(new URL('../src/i18n/catalog.json', import.meta.url), 'utf8'));
const release = JSON.parse(await readFile(new URL('../src/data/release.json', import.meta.url), 'utf8'));
const {default: SigningStory} = await import('../src/components/SigningStory.jsx');
const {default: Home} = await import('../src/pages/index.jsx');
const {default: useScrollReveal} = await import('../src/components/useScrollReveal.js');
const REDUCED = '(prefers-reduced-motion: reduce)';
let browser;
afterEach(() => {
  browser?.restore();
  browser = null;
  resetSite();
});

const story = rect => (element, node) => {
  if (String(node.props.className).startsWith('signing-story')) element.rect = rect;
  if (String(node.props.className).startsWith('story-sticky')) element.rect = {height: 900};
};
const sticky = root => root.find(node => String(node.props.className).startsWith('story-sticky'));
const progress = root => Number(sticky(root).props['data-progress']);

test('signing story follows scroll with eased frames and marks the active section', () => {
  browser = installBrowser({userAgent: 'Mozilla/5.0 (Macintosh)'});
  const rect = {top: 0, bottom: 2900, height: 2900};
  const root = render(jsx(SigningStory, {}), {decorate: story(rect)});
  assert.equal(root.find('section').props['data-platform'], 'macos');
  assert.equal(root.find(node => node.type === 'svg' && node.props.role === 'img').props.viewBox, '0 0 1100 900');
  assert.equal(root.findAll(node => node.type === 'select').length, 0);
  assert.ok(browser.document.documentElement.classList.has('story-active'));
  rect.top = -1400;
  browser.window.dispatch('scroll');
  browser.window.dispatch('scroll');
  assert.equal(browser.frames.size, 1);
  let previous = progress(root);
  for (let time = 16; browser.frames.size && time < 16 * 400; time += 16) {
    browser.runFrames(time);
    assert.ok(progress(root) >= previous);
    previous = progress(root);
  }
  assert.equal(browser.frames.size, 0);
  assert.ok(previous > .5 && previous <= 1, String(previous));
  assert.match(textOf(root.find(node => node.props.className === 'stage-count')), /^Step \d of 4$/);
  rect.top = 5;
  browser.window.dispatch('resize');
  assert.ok(!browser.document.documentElement.classList.has('story-active'));
  const observer = browser.ResizeObserver.instances.at(-1);
  assert.equal(observer.observed.size, 1);
  root.unmount();
  assert.equal(observer.disconnected, 1);
  assert.equal(browser.window.count('scroll') + browser.window.count('resize') + browser.media(REDUCED).count('change'), 0);
});

test('reduced motion shows the completed story and reacts to preference changes', () => {
  browser = installBrowser({media: {[REDUCED]: true}, userAgent: 'Mozilla/5.0 (X11; Linux x86_64)'});
  const root = render(jsx(SigningStory, {}), {decorate: story({top: 300, bottom: 3000, height: 2700})});
  assert.equal(root.find('section').props.className, 'signing-story continuous-story reduced-story');
  assert.equal(root.find('section').props['data-platform'], 'linux');
  assert.equal(textOf(root.find('h2')), catalog.stage4.en);
  browser.window.dispatch('scroll');
  browser.runFrames(100);
  assert.equal(browser.frames.size, 0);
  browser.media(REDUCED).matches = false;
  browser.media(REDUCED).dispatch('change');
  assert.equal(root.find('section').props.className, 'signing-story continuous-story ');
  assert.equal(textOf(root.find('h2')), catalog.stage1.en);
});

test('mobile stories use the phone scene and its NFC chapter', () => {
  browser = installBrowser({userAgent: 'Mozilla/5.0 (Linux; Android 14)', width: 390, height: 844});
  const rect = {top: -1500, bottom: 1400, height: 2900};
  const root = render(jsx(SigningStory, {}), {decorate: story(rect)});
  assert.equal(root.find('section').props['data-platform'], 'android');
  assert.equal(root.find(node => node.type === 'svg' && node.props.role === 'img').props.viewBox, '0 0 650 940');
  for (let time = 0; browser.frames.size && time < 6400; time += 64) browser.runFrames(time);
  assert.match(textOf(root.find(node => node.props.className === 'stage-count')), /of 5$/);
  browser.restore();
  browser = installBrowser({userAgent: 'Mozilla/5.0 (iPhone)'});
  const phone = render(jsx(SigningStory, {}), {decorate: story({top: 0, bottom: 100, height: 100})});
  assert.equal(phone.find('section').props['data-platform'], 'iphone');
  assert.ok(phone.findAll('rect').some(node => node.props.width === '70'));
});

test('local preview selects and remembers a platform, tolerating blocked storage', () => {
  const storage = new Map([['esemnbun.previewPlatform', 'windows']]);
  browser = installBrowser({hostname: 'localhost', storage});
  const root = render(jsx(SigningStory, {}), {decorate: story({top: 0, bottom: 2900, height: 2900})});
  assert.equal(root.find('section').props['data-platform'], 'windows');
  root.fire(root.find('select'), 'onChange', {target: {value: 'android'}});
  assert.equal(storage.get('esemnbun.previewPlatform'), 'android');
  assert.equal(root.find('section').props['data-platform'], 'android');
  root.fire(root.find('select'), 'onChange', {target: {value: 'unknown'}});
  assert.equal(storage.get('esemnbun.previewPlatform'), 'auto');
  browser.values.sessionStorage.getItem = () => {
    throw new Error('blocked');
  };
  browser.values.sessionStorage.setItem = browser.values.sessionStorage.getItem;
  const blocked = render(jsx(SigningStory, {}), {decorate: story({top: 0, bottom: 2900, height: 2900})});
  blocked.fire(blocked.find('select'), 'onChange', {target: {value: 'linux'}});
  assert.equal(blocked.find('section').props['data-platform'], 'linux');
});

function reveal(options) {
  let container;
  const Probe = ({children}) => {
    const ref = useScrollReveal();
    return jsx('main', {ref, children});
  };
  const tree = jsx(Probe, {children: [
    jsx('section', {className: 'features', children: [jsx('h2', {children: 'Why'}), jsx('p', {className: 'feature-intro'}),
      jsx('div', {className: 'feature-grid', children: [jsx('article', {}), jsx('article', {children: jsx('a', {})})]})]}),
    jsx('section', {className: 'trust-section', children: jsx('p', {})}),
  ]});
  const root = render(tree, {decorate: (element, node) => {
    if (node.type === 'main') container = element;
  }, ...options});
  return {root, container};
}

test('scroll reveal animates entering content once and never delays focused content', () => {
  browser = installBrowser();
  const {root, container} = reveal();
  const observer = browser.IntersectionObserver.instances[0];
  assert.equal(observer.options.threshold, .08);
  const [heading, intro, first, second, trust] = container.querySelectorAll(
    '.features > h2, .feature-intro, .feature-grid article, .trust-section > *');
  assert.equal(observer.observed.size, 5);
  observer.trigger([{target: heading, isIntersecting: false}, {target: second, isIntersecting: true}, {target: second, isIntersecting: true}]);
  const animation = second.calls[0][1];
  assert.equal(animation.options.delay, 70);
  assert.equal(second.calls.length, 1);
  browser.document.activeElement = intro;
  observer.trigger([{target: intro, isIntersecting: true}, {target: first, isIntersecting: true}]);
  assert.equal(intro.calls.length, 0);
  assert.equal(first.calls[0][1].options.delay, 0);
  container.dispatch('focusin', {target: second.firstElementChild});
  assert.ok(animation.cancelled);
  first.calls[0][1].onfinish();
  browser.media(REDUCED).matches = true;
  browser.media(REDUCED).dispatch('change');
  assert.equal(observer.observed.size, 0);
  browser.media(REDUCED).matches = false;
  browser.media(REDUCED).dispatch('change');
  assert.deepEqual([...observer.observed], [heading, trust]);
  observer.trigger([{target: trust, isIntersecting: true}]);
  root.unmount();
  assert.ok(trust.calls[0][1].cancelled);
  assert.equal(container.listeners.get('focusin').size, 0);

  browser.media(REDUCED).matches = true;
  const reduced = reveal().root;
  browser.IntersectionObserver.instances.at(-1).trigger([{target: reduced.elementFor(reduced.find('h2')), isIntersecting: true}]);
  assert.equal(reduced.elementFor(reduced.find('h2')).calls.length, 0);
  delete browser.values.window.IntersectionObserver;
  const before = browser.IntersectionObserver.instances.length;
  reveal();
  assert.equal(browser.IntersectionObserver.instances.length, before);
});

test('home page publishes structured data and platform-specific download actions', () => {
  browser = installBrowser({userAgent: 'Mozilla/5.0 (Macintosh)'});
  resetSite({locale: 'ro'});
  const root = render(jsx(Home, {}), {decorate: story({top: 0, bottom: 2900, height: 2900})});
  assert.equal(root.find('layout').props.title, catalog.title.ro);
  const [software, website] = root.findAll('script').map(node => JSON.parse(node.children[0]));
  assert.equal(software['@id'], 'https://esemnbun.md/#software');
  assert.equal(software.url, 'https://esemnbun.md/ro/');
  assert.equal(software.softwareVersion, release.version);
  assert.equal(software.downloadUrl, 'https://esemnbun.md/ro/downloads/');
  assert.equal(website.publisher.name, 'Nicolae Ghimbovschi');
  const actions = root.findAll(node => node.props.className === 'hero-actions stacked-download-actions');
  assert.equal(actions.length, 2);
  assert.ok(root.findAll(node => node.props.className === 'download-options-primary').length === 2);
  assert.ok(root.findAll('a').some(node => node.props.href === '/docs/platforms/linux/'));
  root.unmount();
  browser.restore();
  browser = installBrowser({userAgent: 'Mozilla/5.0 (Linux; Android 14)'});
  resetSite();
  const android = render(jsx(Home, {}), {decorate: story({top: 0, bottom: 2900, height: 2900})});
  assert.equal(android.findAll(node => node.props.className === 'hero-actions').length, 2);
  assert.equal(android.findAll(node => node.props.className === 'download-options-primary').length, 0);
  assert.ok(android.text().includes(catalog.storeStatus_android.en));
  assert.ok(!JSON.stringify(android.findAll('script').map(node => node.children[0])).includes('<'));
});
