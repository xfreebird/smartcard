import assert from 'node:assert/strict';
import {readFile} from 'node:fs/promises';
import {fileURLToPath} from 'node:url';
import path from 'node:path';

const root = process.env.SEO_OUTPUT_DIR || fileURLToPath(new URL('../pages/', import.meta.url));
const siteURL = process.env.SITE_URL || 'https://esemnbun.md';
const baseURL = process.env.BASE_URL || '/';
const publicRoot = new URL(baseURL, siteURL);
const locales = ['en', 'ro', 'ru'];
const discovery = JSON.parse(await readFile(new URL('../src/data/search-discovery.json', import.meta.url), 'utf8'));
const routes = ['', 'docs/moldsign/', 'docs/platforms/windows/', 'docs/platforms/macos/', 'docs/platforms/linux/', 'docs/mcp-moldsign/'];
const onPublicSite = value => {
  try {
    return new URL(value).origin === publicRoot.origin;
  } catch {
    return false;
  }
};
const absolute = (locale, route = '') => new URL(`${locale === 'en' ? '' : `${locale}/`}${route}`, publicRoot).href;
const readOutput = url => {
  const parsed = new URL(url);
  assert.equal(parsed.origin, publicRoot.origin, `Unexpected discovery host: ${url}`);
  assert.ok(parsed.pathname.startsWith(publicRoot.pathname), `Unexpected base path: ${url}`);
  const relative = parsed.pathname.slice(publicRoot.pathname.length);
  return readFile(path.join(root, relative, parsed.pathname.endsWith('/') ? 'index.html' : ''), 'utf8');
};
const tags = (html, name) => [...html.matchAll(new RegExp(`<${name}\\b[^>]*>`, 'g'))].map(match => {
  const attrs = {};
  for (const attr of match[0].matchAll(/\s([\w:-]+)="([^"]*)"/g)) attrs[attr[1]] = attr[2];
  return attrs;
});

for (const locale of locales) {
  const prefix = locale === 'en' ? '' : `${locale}/`;
  const home = await readFile(path.join(root, prefix, 'index.html'), 'utf8');
  const sitemap = await readFile(path.join(root, prefix, 'sitemap.xml'), 'utf8');
  const titles = new Set();
  const descriptions = new Set();
  for (const route of routes) {
    const html = await readOutput(absolute(locale, route));
    assert.ok(/<title\b[^>]*>[^<]+<\/title>/.test(html), `${locale}/${route}: missing title`);
    const title = html.match(/<title\b[^>]*>([^<]+)<\/title>/)[1];
    const description = tags(html, 'meta').find(t => t.name === 'description')?.content;
    assert.ok(description?.length > 60, `${locale}/${route}: missing description`);
    assert.ok(!titles.has(title), `${locale}/${route}: duplicate title`);
    assert.ok(!descriptions.has(description), `${locale}/${route}: duplicate description`);
    titles.add(title); descriptions.add(description);
    assert.equal(tags(html, 'h1').length, 1, `${locale}/${route}: expected one main heading`);
    assert.ok(tags(html, 'html').some(t => t.lang === locale), `${locale}/${route}: incorrect page language`);
    const links = tags(html, 'link');
    const canonical = links.filter(t => t.rel === 'canonical');
    assert.equal(canonical.length, 1, `${locale}/${route}: expected one canonical`);
    assert.equal(canonical[0].href, absolute(locale, route), `${locale}/${route}: canonical mismatch`);
    for (const alternate of locales) assert.ok(links.some(t => t.rel === 'alternate' && t.hreflang === alternate && t.href === absolute(alternate, route)), `${locale}/${route}: incorrect ${alternate} alternate`);
    assert.ok(!tags(html, 'meta').some(t => t.name === 'robots' && /noindex/.test(t.content)), `${locale}/${route}: noindex`);
    assert.match(html, /MoldSign/);
    assert.ok(tags(html, 'meta').some(t => t.property === 'og:image' && onPublicSite(t.content)), `${locale}/${route}: social image`);
    assert.ok(links.some(t => t.rel === 'alternate' && t.type === 'text/plain' && t.href === absolute(locale, 'llms.txt')), `${locale}/${route}: missing text discovery link`);
    assert.ok(links.some(t => t.rel === 'describedby' && t.href === absolute(locale, 'discovery.json')), `${locale}/${route}: missing JSON discovery link`);
    assert.ok(sitemap.includes(absolute(locale, route)), `${locale}/${route}: missing from sitemap`);
    if (route) {
      const id = route.replace(/^docs\//, '').replace(/\/$/, '');
      assert.ok(links.some(t => t.rel === 'alternate' && t.type === 'text/markdown' && t.href === absolute(locale, `markdown/${id}.md`)), `${locale}/${route}: missing Markdown alternative`);
      assert.ok(tags(home, 'a').some(t => new URL(t.href || '', absolute(locale)).href === absolute(locale, route)), `${locale}/${route}: not linked from homepage`);
    }
  }
  const data = [...home.matchAll(/<script[^>]*type="application\/ld\+json"[^>]*>([\s\S]*?)<\/script>/g)].map(m => JSON.parse(m[1]));
  assert.ok(data.some(d => d['@type'] === 'SoftwareApplication' && d.name === 'eSemnBun' && d.url === new URL(prefix, publicRoot).href), `${locale}: software metadata`);
  const app = data.find(d => d['@type'] === 'SoftwareApplication');
  assert.equal(app['@id'], `${publicRoot.href}#software`);
  assert.equal(app.image, new URL('img/icon.png', publicRoot).href);
  assert.equal(app.downloadUrl, absolute(locale, 'downloads/'));
  assert.ok(app.softwareVersion);
  assert.ok(data.some(d => d['@type'] === 'WebSite' && d.name === 'eSemnBun' && d.url === publicRoot.href), `${locale}: website identity`);

  const manifest = JSON.parse(await readOutput(absolute(locale, 'discovery.json')));
  const index = await readOutput(absolute(locale, 'llms.txt'));
  const full = await readOutput(absolute(locale, 'llms-full.txt'));
  assert.equal(manifest.schemaVersion, 1);
  assert.equal(manifest.language, locale);
  assert.equal(manifest.url, absolute(locale));
  assert.equal(manifest.mcp.transport, 'stdio');
  assert.equal(manifest.mcp.remoteEndpoint, null);
  assert.equal(manifest.mcp.documentation, absolute(locale, 'docs/mcp-moldsign/'));
  const expectedDocuments = [...discovery.documents, ...(locale === 'en' ? discovery.englishDocuments : [])];
  assert.deepEqual(manifest.documentation.map(doc => doc.id), expectedDocuments);
  for (const alternate of locales) assert.ok(manifest.languages.some(item => item.language === alternate && item.url === absolute(alternate, 'llms.txt')));
  for (const doc of manifest.documentation) {
    assert.equal(doc.url, absolute(locale, `docs/${doc.id}/`));
    assert.equal(doc.markdown, absolute(locale, `markdown/${doc.id}.md`));
    const html = await readOutput(doc.url);
    assert.ok(tags(html, 'link').some(t => t.rel === 'canonical' && t.href === doc.url), `Discovery canonical: ${doc.url}`);
    const markdown = await readOutput(doc.markdown);
    assert.ok(markdown.startsWith(`# ${doc.title}\n`));
    const prose = markdown.replace(/^```[^\n]*\n[\s\S]*?^```[ \t]*(?:\n|$)/gm, '');
    assert.equal((prose.match(/^# /gm) || []).length, 1, `Duplicate Markdown title: ${doc.id}`);
    assert.ok(markdown.includes(doc.url), `Missing source citation: ${doc.id}`);
    assert.doesNotMatch(markdown, /(?:^import )|(?:<Guide(?:Directory|AnchorRedirect))|(?:pathname:\/\/)/m);
    assert.ok(index.includes(doc.markdown) && index.includes(doc.url));
    assert.ok(full.includes(markdown), `Full text does not match: ${doc.id}`);
  }
  assert.match(full, /verify_document/);
  assert.match(full, /prepare_signing/);
}
const ro = await readFile(path.join(root, 'ro/index.html'), 'utf8');
assert.match(ro, /semnătură electronică/i);
assert.match(ro, /cartea de identitate/i);
const robots = await readFile(path.join(root, 'robots.txt'), 'utf8');
assert.match(robots, /User-agent: \*\nAllow: \/\n/);
assert.doesNotMatch(robots, /Disallow:\s*\//);
for (const locale of locales) assert.ok(robots.includes(new URL(`${locale === 'en' ? '' : `${locale}/`}sitemap.xml`, publicRoot).href));
console.log('SEO checks passed: localized entry pages, canonical/hreflang, homepage links, structured data, sitemaps and localized product plus English developer references with text/JSON discovery.');
