import {spawnSync} from 'node:child_process';
import {test} from 'node:test';
import assert from 'node:assert/strict';
import {mkdtemp, mkdir, readFile, rm, writeFile} from 'node:fs/promises';
import {createRequire} from 'node:module';
import {tmpdir} from 'node:os';
import path from 'node:path';
import {fileURLToPath} from 'node:url';

const website = fileURLToPath(new URL('../', import.meta.url));
const require = createRequire(import.meta.url);
const searchDiscovery = require('../plugins/search-discovery.cjs');
const discovery = JSON.parse(await readFile(new URL('../src/data/search-discovery.json', import.meta.url), 'utf8'));
const catalog = JSON.parse(await readFile(new URL('../src/i18n/catalog.json', import.meta.url), 'utf8'));
const site = 'https://esemnbun.md';
const locales = ['en', 'ro', 'ru'];
const prefix = locale => locale === 'en' ? '' : `${locale}/`;
const absolute = (locale, route = '') => new URL(`${prefix(locale)}${route}`, `${site}/`).href;
const routes = ['', 'docs/moldsign/', 'docs/platforms/windows/', 'docs/platforms/macos/', 'docs/platforms/linux/', 'docs/mcp-moldsign/'];
const i18n = locale => ({currentLocale: locale, defaultLocale: 'en', locales,
  localeConfigs: Object.fromEntries(locales.map(item => [item, {url: site, baseUrl: `/${prefix(item)}`}]))});

function docs(locale) {
  const ids = [...discovery.documents, ...discovery.englishDocuments, 'platforms/windows/setup', 'platforms/windows/draft'];
  return ids.map(id => ({id, title: `${locale} ${id}`, description: `${locale} ${id} description`,
    permalink: `/${prefix(locale)}docs/${id}`, draft: id.endsWith('/draft')}));
}

async function discover(outDir, locale, {trailingSlash = true, entries = docs(locale)} = {}) {
  const plugin = searchDiscovery({i18n: i18n(locale), siteDir: website});
  assert.equal(plugin.name, 'search-discovery');
  plugin.allContentLoaded({allContent: {'docusaurus-plugin-content-docs': {default: {loadedVersions: [
    {versionName: 'other', docs: []}, {versionName: 'current', docs: entries}]}}}});
  await plugin.postBuild({outDir, siteConfig: {url: site, baseUrl: `/${prefix(locale)}`, trailingSlash}});
}

function page(locale, route, {canonical = true} = {}) {
  const id = route.replace(/^docs\//, '').replace(/\/$/, '');
  const links = [
    canonical && `<link rel="canonical" href="${absolute(locale, route)}">`,
    ...locales.map(other => `<link rel="alternate" hreflang="${other}" href="${absolute(other, route)}">`),
    `<link rel="alternate" type="text/plain" href="${absolute(locale, 'llms.txt')}">`,
    `<link rel="describedby" type="application/json" href="${absolute(locale, 'discovery.json')}">`,
    route && `<link rel="alternate" type="text/markdown" href="${absolute(locale, `markdown/${id}.md`)}">`,
  ].filter(Boolean).join('');
  const body = route ? '' : routes.slice(1).map(item => `<a href="${absolute(locale, item)}">x</a>`).join('') +
    `<script type="application/ld+json">${JSON.stringify({'@type': 'SoftwareApplication', '@id': `${site}/#software`, name: 'eSemnBun',
      url: absolute(locale), image: `${site}/img/icon.png`, downloadUrl: absolute(locale, 'downloads/'), softwareVersion: '1.0.0'})}</script>` +
    `<script type="application/ld+json">${JSON.stringify({'@type': 'WebSite', name: 'eSemnBun', url: `${site}/`})}</script>` +
    (locale === 'ro' ? '<p>Semnătură electronică cu cartea de identitate</p>' : '');
  return `<html lang="${locale}"><head><title>${locale} ${route || 'home'} MoldSign</title>` +
    `<meta name="description" content="A sufficiently long and unique ${locale} description for ${route || 'the home page'}.">` +
    `<meta property="og:image" content="${site}/img/icon.png">${links}</head><body><h1>Heading</h1>${body}</body></html>`;
}

async function buildSite(root, options = {}) {
  for (const locale of locales) {
    const out = path.join(root, prefix(locale));
    await mkdir(out, {recursive: true});
    await discover(out, locale);
    const pages = new Set([...routes, ...JSON.parse(await readFile(path.join(out, 'discovery.json'), 'utf8')).documentation
      .map(doc => new URL(doc.url).pathname.slice(`/${prefix(locale)}`.length))]);
    for (const route of pages) {
      await mkdir(path.join(out, route), {recursive: true});
      await writeFile(path.join(out, route, 'index.html'), page(locale, route, options.page?.(locale, route)));
    }
    await writeFile(path.join(out, 'sitemap.xml'), routes.map(route => absolute(locale, route)).join('\n'));
  }
}

const verifier = fileURLToPath(new URL('../scripts/verify-seo.mjs', import.meta.url));

async function verify(root) {
  process.env.SEO_OUTPUT_DIR = root + path.sep;
  try {
    await import('../scripts/verify-seo.mjs');
  } finally {
    delete process.env.SEO_OUTPUT_DIR;
  }
}

// A rejected fixture runs in its own process, so the verifier module is evaluated once per process.
const verifyInChild = root => spawnSync(process.execPath, [verifier], {env: {...process.env, SEO_OUTPUT_DIR: root + path.sep}, encoding: 'utf8'});

test('the SEO verifier rejects a page without its canonical URL', async t => {
  const root = await mkdtemp(path.join(tmpdir(), 'esemnbun-seo-'));
  t.after(() => rm(root, {recursive: true, force: true}));
  await buildSite(root, {page: (locale, route) => ({canonical: !(locale === 'ru' && route === 'docs/mcp-moldsign/')})});
  const result = verifyInChild(root);
  assert.notEqual(result.status, 0);
  assert.match(result.stderr, /ru\/docs\/mcp-moldsign\/: expected one canonical/);
});

test('discovery files describe every localized document and pass the SEO verifier', async t => {
  const root = await mkdtemp(path.join(tmpdir(), 'esemnbun-seo-'));
  t.after(() => rm(root, {recursive: true, force: true}));
  await buildSite(root);
  const manifest = JSON.parse(await readFile(path.join(root, 'ro/discovery.json'), 'utf8'));
  assert.equal(manifest.description, catalog.seoDescription.ro);
  assert.deepEqual(manifest.documentation.map(doc => doc.id), discovery.documents);
  assert.equal(manifest.documentation[0].url, `${site}/ro/docs/moldsign/`);
  const platform = await readFile(path.join(root, 'markdown/platforms/windows.md'), 'utf8');
  assert.match(platform, /- \[en platforms\/windows\/setup\]\(https:\/\/esemnbun\.md\/docs\/platforms\/windows\/setup\/\)/);
  assert.doesNotMatch(platform, /draft/);
  const robots = await readFile(path.join(root, 'robots.txt'), 'utf8');
  assert.equal(robots, `User-agent: *\nAllow: /\n\n${locales.map(locale => `Sitemap: ${absolute(locale, 'sitemap.xml')}`).join('\n')}\n`);
  await assert.rejects(readFile(path.join(root, 'ro/robots.txt')));
  const log = [];
  const original = console.log;
  console.log = message => log.push(message);
  try {
    await verify(root);
  } finally {
    console.log = original;
  }
  assert.match(log.join('\n'), /^SEO checks passed/);
});

test('markdown keeps fenced comments and resolves relative links', async t => {
  const root = await mkdtemp(path.join(tmpdir(), 'esemnbun-seo-'));
  t.after(() => rm(root, {recursive: true, force: true}));
  await discover(root, 'en', {trailingSlash: false});
  const manifest = JSON.parse(await readFile(path.join(root, 'discovery.json'), 'utf8'));
  assert.equal(manifest.documentation[0].url, `${site}/docs/moldsign`);
  assert.equal(manifest.documentation.length, discovery.documents.length + discovery.englishDocuments.length);
  const full = await readFile(path.join(root, 'llms-full.txt'), 'utf8');
  assert.doesNotMatch(full, /^import /m);
  assert.doesNotMatch(full, /\]\(\.\.?\//);
  const index = await readFile(path.join(root, 'llms.txt'), 'utf8');
  assert.match(index, /\[Developer documentation \(English\)\]\(https:\/\/esemnbun\.md\/docs\/developers\/overview\/\)/);
  await assert.rejects(discover(root, 'en', {entries: docs('en').filter(doc => doc.id !== 'signing')}),
    /Missing public discovery doc: en\/signing/);
});

test('site configuration and sidebars expose every guide platform', async () => {
  const {default: config} = await import('../docusaurus.config.js');
  assert.equal(config.url, process.env.SITE_URL || 'https://esemnbun.md');
  assert.deepEqual(config.i18n.locales, ['en', 'ro', 'ru']);
  assert.deepEqual(config.plugins, ['./plugins/search-discovery.cjs']);
  assert.ok(config.themeConfig.navbar.items.some(item => item.to === '/downloads'));
  const {default: sidebars} = await import('../sidebars.js');
  const navigation = JSON.parse(await readFile(new URL('../src/data/guide-navigation.json', import.meta.url), 'utf8'));
  const platforms = JSON.stringify(sidebars.guide);
  for (const platform of navigation.platforms) {
    assert.ok(platforms.includes(`"platforms/${platform.id}"`), platform.id);
    for (const topic of platform.topics) assert.ok(platforms.includes(`platforms/${platform.id}/${topic.id}`), topic.id);
  }
  assert.equal(sidebars.developers[0], 'developers/overview');
});
