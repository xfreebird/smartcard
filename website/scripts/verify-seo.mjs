import assert from 'node:assert/strict';
import {readFile} from 'node:fs/promises';
import {fileURLToPath} from 'node:url';
import path from 'node:path';

const root = process.env.SEO_OUTPUT_DIR || fileURLToPath(new URL('../pages/', import.meta.url));
const siteURL = process.env.SITE_URL || 'https://xfreebird.github.io';
const baseURL = process.env.BASE_URL || '/smartcard/';
const publicRoot = new URL(baseURL, siteURL);
const locales = ['en', 'ro', 'ru'];
const tags = (html, name) => [...html.matchAll(new RegExp(`<${name}\\b[^>]*>`, 'g'))].map(match => {
  const attrs = {};
  for (const attr of match[0].matchAll(/([\w:-]+)="([^"]*)"/g)) attrs[attr[1]] = attr[2];
  return attrs;
});

for (const locale of locales) {
  const prefix = locale === 'en' ? '' : `${locale}/`;
  const home = await readFile(path.join(root, prefix, 'index.html'), 'utf8');
  const guide = await readFile(path.join(root, prefix, 'docs/moldsign/index.html'), 'utf8');
  for (const [route, html] of [['', home], ['docs/moldsign/', guide]]) {
    assert.ok(/<title\b[^>]*>[^<]+<\/title>/.test(html), `${locale}/${route}: missing title`);
    assert.ok(tags(html, 'meta').some(t => t.name === 'description' && t.content?.length > 60), `${locale}/${route}: missing description`);
    assert.ok(tags(html, 'link').some(t => t.rel === 'canonical' && t.href === new URL(`${prefix}${route}`, publicRoot).href), `${locale}/${route}: canonical mismatch`);
    for (const alternate of locales) assert.ok(tags(html, 'link').some(t => t.rel === 'alternate' && t.hreflang === alternate), `${locale}/${route}: missing ${alternate} alternate`);
    assert.ok(!tags(html, 'meta').some(t => t.name === 'robots' && /noindex/.test(t.content)), `${locale}/${route}: noindex`);
    assert.match(html, /MoldSign/);
    assert.ok(tags(html, 'meta').some(t => t.property === 'og:image' && t.content?.startsWith(siteURL)), `${locale}/${route}: social image`);
  }
  const data = [...home.matchAll(/<script[^>]*type="application\/ld\+json"[^>]*>([\s\S]*?)<\/script>/g)].map(m => JSON.parse(m[1]));
  assert.ok(data.some(d => d['@type'] === 'SoftwareApplication' && d.name === 'eSemnBun' && d.url === new URL(prefix, publicRoot).href), `${locale}: software metadata`);
  const sitemap = await readFile(path.join(root, prefix, 'sitemap.xml'), 'utf8');
  assert.ok(sitemap.includes(new URL(`${prefix}docs/moldsign/`, publicRoot).href), `${locale}: guide missing from sitemap`);
}
const ro = await readFile(path.join(root, 'ro/index.html'), 'utf8');
assert.match(ro, /semnătură electronică/i);
assert.match(ro, /cartea de identitate/i);
const robots = await readFile(path.join(root, 'robots.txt'), 'utf8');
for (const locale of locales) assert.ok(robots.includes(new URL(`${locale === 'en' ? '' : `${locale}/`}sitemap.xml`, publicRoot).href));
console.log('SEO checks passed: localized titles, descriptions, canonical/hreflang, social images, software metadata, content, and sitemap discovery.');
