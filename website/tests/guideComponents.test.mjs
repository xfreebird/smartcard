import './support/register.mjs';
import {afterEach, test} from 'node:test';
import assert from 'node:assert/strict';
import {readFile} from 'node:fs/promises';
import {jsx, render, textOf} from './support/react.mjs';
import {resetSite} from './support/site.mjs';
import {installBrowser} from './support/browser.mjs';

const navigation = JSON.parse(await readFile(new URL('../src/data/guide-navigation.json', import.meta.url), 'utf8'));
const {revision} = JSON.parse(await readFile(new URL('../src/data/screenshotRevision.json', import.meta.url), 'utf8'));
const {default: GuideDirectory} = await import('../src/components/GuideDirectory.jsx');
const {default: GuideScreenshot} = await import('../src/components/GuideScreenshot.jsx');
let browser;
afterEach(() => {
  browser?.restore();
  browser = null;
  resetSite();
});

const topicCount = platforms => platforms.reduce((total, platform) => total + platform.topics.length, 0);

test('guide directory starts with device groups and shortcut tasks', () => {
  const root = render(jsx(GuideDirectory, {}));
  const sections = root.findAll('section');
  assert.equal(sections.length, navigation.groups.length);
  assert.deepEqual(sections.map(section => textOf(section.children[0])), navigation.groups.map(group => group.labels.en));
  const overview = root.findAll(node => node.props.className === 'guide-device-overview').map(node => node.props.href);
  assert.deepEqual(overview, navigation.groups.flatMap(group => group.platforms).map(id => `/docs/platforms/${id}/`));
  assert.ok(root.text().includes('Command line (CLI) →'));
  assert.ok(root.text().includes('App guides →'));
  assert.equal(root.findAll(node => node.props.role === 'status').length, 0);
  assert.deepEqual(root.findAll('option').map(node => node.props.value), ['', ...navigation.platforms.map(item => item.id)]);
});

test('search and device filters narrow the localized task list', () => {
  resetSite({locale: 'ro'});
  const root = render(jsx(GuideDirectory, {}));
  root.fire(root.find('select'), 'onChange', {target: {value: 'linux'}});
  const linux = navigation.platforms.find(item => item.id === 'linux');
  assert.equal(textOf(root.find(node => node.props.role === 'status')), `Rezultate: ${linux.topics.length}`);
  assert.ok(root.findAll('a').every(node => node.props.href.startsWith('/docs/platforms/linux/')));
  root.fire(root.find('select'), 'onChange', {target: {value: ''}});
  root.fire(root.find('input'), 'onChange', {target: {value: '  ȘTAMPILĂ   pdf '}});
  const cards = root.findAll(node => node.props.className === 'guide-task-card');
  assert.ok(cards.length > 0 && cards.length < topicCount(navigation.platforms));
  assert.ok(cards.every(card => card.children[0].type === 'small'));
  root.fire(root.find('input'), 'onChange', {target: {value: 'zzzz-no-such-task'}});
  assert.ok(root.text().includes('Nicio activitate găsită.'));
});

test('a platform directory searches only that platform, in Russian or English fallback', () => {
  resetSite({locale: 'ru'});
  const windows = navigation.platforms.find(item => item.id === 'windows-cli');
  const root = render(jsx(GuideDirectory, {platform: 'windows-cli'}));
  assert.equal(root.findAll('select').length, 0);
  assert.equal(textOf(root.find(node => node.props.role === 'status')), `Результаты: ${windows.topics.length}`);
  root.fire(root.find('input'), 'onChange', {target: {value: 'ПИН'}});
  const cards = root.findAll(node => node.props.className === 'guide-task-card');
  assert.ok(cards.every(card => card.props.href.startsWith('/docs/platforms/windows-cli/') && card.children[0].type === 'h2'));
  resetSite({locale: 'de'});
  assert.equal(render(jsx(GuideDirectory, {platform: 'linux'})).find('input').props.placeholder, 'Search PDF, PIN, browser or Siri…');
});

const steps = [{x: 10, y: 20, text: 'Open the menu'}, {x: 80, y: 60, text: 'Choose Sign'}, {text: 'Wait for the result'}];

function layout(element, node) {
  if (node.props.className === 'guide-annotated-frame') element.rect = {left: 0, top: 0, width: 400, height: 300};
  if (node.type === 'img') element.rect = {left: 50, top: 20, width: 300, height: 260};
}

test('screenshots place numbered callouts beside the measured image', () => {
  browser = installBrowser();
  const root = render(jsx(GuideScreenshot, {src: '/img/guide/x.png', alt: 'Signing', steps, caption: 'Fixture', start: 3}),
    {decorate: layout});
  const images = root.findAll('img');
  assert.equal(images.length, 2);
  assert.equal(images[0].props.src, `/img/guide/x.png?v=${revision}`);
  assert.deepEqual(root.findAll('li').map(textOf), steps.map(step => step.text));
  assert.equal(root.find('ol').props.start, 3);
  assert.equal(textOf(root.find('figcaption').children[0]), 'Fixture');
  const markers = root.findAll(node => node.props.className === 'guide-screenshot-marker');
  assert.deepEqual(markers.slice(0, 2).map(textOf), ['3', '4']);
  assert.equal(root.findAll(node => node.props.className === 'guide-screenshot-pointer').length, 4);
  assert.equal(root.find('svg').props.viewBox, '0 0 400 300');
  assert.equal(root.find(node => node.props.className === 'guide-annotated-frame').props.style.minHeight, '52px');
  const observer = browser.ResizeObserver.instances[0];
  assert.equal(observer.observed.size, 2);
  const image = root.elementFor(images[0]);
  const renders = root.renders;
  image.dispatch('load');
  assert.equal(root.renders, renders);
  image.rect = {left: 50, top: 20, width: 200, height: 160};
  observer.trigger();
  assert.equal(root.renders, renders + 1);
  root.unmount();
  assert.equal(observer.disconnected, 1);
  assert.equal(image.listeners.get('load').size, 0);
});

test('the enlarged dialog toggles actual size and closes from its controls or backdrop', () => {
  browser = installBrowser();
  resetSite({locale: 'ro'});
  const root = render(jsx(GuideScreenshot, {src: '/img/a.png', alt: 'A', steps: []}), {decorate: layout});
  const dialog = () => root.find('dialog');
  const dialogElement = root.elementFor(dialog());
  root.fire(root.find(node => node.type === 'button' && node.props['aria-haspopup'] === 'dialog'), 'onClick');
  assert.deepEqual(dialogElement.calls.at(-1), ['showModal']);
  const zoom = () => root.find(node => node.type === 'button' && node.props.className === undefined);
  assert.equal(textOf(zoom()), 'Mărime originală');
  root.fire(zoom(), 'onClick');
  assert.equal(dialog().props.className, 'guide-screenshot-dialog guide-screenshot-actual-size');
  assert.equal(textOf(zoom()), 'Încadrează pe ecran');
  root.fire(root.find(node => node.props['aria-label'] === 'Închide imaginea'), 'onClick');
  assert.deepEqual(dialogElement.calls.at(-1), ['close']);
  root.fire(dialog(), 'onClick', {target: {}});
  assert.equal(dialogElement.calls.length, 2);
  root.fire(dialog(), 'onClick', {target: dialogElement});
  assert.deepEqual(dialogElement.calls.at(-1), ['close']);
  assert.equal(root.findAll(node => node.props.className === 'guide-screenshot-pointer').length, 0);
  resetSite({locale: 'de'});
  const english = render(jsx(GuideScreenshot, {src: '/img/b.png', alt: 'B'}));
  assert.ok(english.findAll('button').some(node => node.props['aria-label'] === 'Close image'));
  assert.ok(english.text().includes('Actual size'));
});
