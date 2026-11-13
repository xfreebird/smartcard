const fs = require('node:fs/promises');
const path = require('node:path');
const discovery = require('../src/data/search-discovery.json');
const catalog = require('../src/i18n/catalog.json');

// Alternative representations of the same public docs, never a separate set of claims.
function markdownBody(source, documentId, root) {
  const sourceURL = new URL(`docs/${documentId}.md`, root);
  return source
    .replace(/^---\r?\n[\s\S]*?\r?\n---\r?\n/, '')
    .replace(/^import .+;?\r?\n/gm, '')
    .replace(/^<(?:GuideDirectory|GuideAnchorRedirect)\b[^\n]*\/>\s*$/gm, '')
    .replace(/^# [^\n]+\n/m, '')
    .replace(/\]\(([^\s)]+)\)/g, (match, href) => {
      if (/^(?:[a-z]+:|#|\/\/)/i.test(href)) return match;
      const url = href.startsWith('/') ? new URL(href.slice(1), root) : new URL(href, sourceURL);
      // Relative .md links refer to docs sources; root-relative links refer to routes.
      if (!href.startsWith('/')) url.pathname = url.pathname.replace(/\.md$/, '/');
      return `](${url.href})`;
    }).trim();
}

module.exports = function searchDiscovery({i18n, siteDir}) {
  let docs;
  return {
    name: 'search-discovery',
    allContentLoaded({allContent}) {
      const current = allContent['docusaurus-plugin-content-docs'].default.loadedVersions
        .find(version => version.versionName === 'current');
      docs = new Map(current.docs.map(doc => [doc.id, doc]));
    },
    async postBuild({outDir, siteConfig}) {
      const locale = i18n.currentLocale;
      const root = new URL(siteConfig.baseUrl, siteConfig.url);
      // Doc metadata omits the trailing slash applied to canonical HTML URLs.
      const documentURL = permalink => {
        const url = new URL(permalink, siteConfig.url);
        if (siteConfig.trailingSlash === true && !url.pathname.endsWith('/')) url.pathname += '/';
        if (siteConfig.trailingSlash === false && url.pathname !== '/') url.pathname = url.pathname.replace(/\/$/, '');
        return url.href;
      };
      const records = [];
      const markdown = [];
      for (const id of discovery.documents) {
        const doc = docs.get(id);
        if (!doc || doc.draft || doc.unlisted) throw new Error(`Missing public discovery doc: ${locale}/${id}`);
        // Require real translations; an English fallback is not a localized reference.
        const sourcePath = locale === i18n.defaultLocale
          ? path.join(siteDir, 'docs', `${id}.md`)
          : path.join(siteDir, 'i18n', locale, 'docusaurus-plugin-content-docs/current', `${id}.md`);
        const source = await fs.readFile(sourcePath, 'utf8');
        const url = documentURL(doc.permalink);
        const markdownPath = `markdown/${id}.md`;
        let body = markdownBody(source, id, root);
        if (id.startsWith('platforms/')) {
          const tasks = [...docs.values()].filter(item => item.id.startsWith(`${id}/`) && !item.draft && !item.unlisted);
          body += '\n\n' + tasks.map(item => `- [${item.title}](${documentURL(item.permalink)})`).join('\n');
        }
        const text = `# ${doc.title}\n\n${doc.description}\n\n[${doc.title}](${url})\n\n${body}\n`;
        await fs.mkdir(path.dirname(path.join(outDir, markdownPath)), {recursive: true});
        await fs.writeFile(path.join(outDir, markdownPath), text);
        records.push({id, title: doc.title, description: doc.description, url, markdown: new URL(markdownPath, root).href});
        markdown.push(text);
      }

      const languages = i18n.locales.map(language => {
        const config = i18n.localeConfigs[language];
        return {language, url: new URL('llms.txt', new URL(config.baseUrl, config.url)).href};
      });
      const labels = {
        en: ['Documentation', 'Languages', 'Optional references', 'Full documentation in plain text'],
        ro: ['Documentație', 'Limbi', 'Referințe suplimentare', 'Documentație completă în text simplu'],
        ru: ['Документация', 'Языки', 'Дополнительные материалы', 'Полная документация в текстовом формате'],
      }[locale];
      const introduction = `# eSemnBun\n\n> ${catalog.seoDescription[locale]}\n`;
      const index = `${introduction}\n## ${labels[0]}\n\n`
        + records.map(doc => `- [${doc.title}](${doc.markdown}): ${doc.description} [HTML](${doc.url})`).join('\n')
        + `\n\n## ${labels[1]}\n\n` + languages.map(item => `- [${item.language}](${item.url})`).join('\n')
        + `\n\n## ${labels[2]}\n\n- [${labels[3]}](${new URL('llms-full.txt', root).href})\n`
        + `- [JSON](${new URL('discovery.json', root).href})\n`;
      const manifest = {
        schemaVersion: 1, name: 'eSemnBun', language: locale, url: root.href,
        description: catalog.seoDescription[locale],
        downloads: new URL('downloads/', root).href,
        documentation: records, languages,
        mcp: {transport: 'stdio', remoteEndpoint: null, documentation: new URL('docs/mcp-moldsign/', root).href},
      };
      await fs.writeFile(path.join(outDir, 'llms.txt'), index);
      await fs.writeFile(path.join(outDir, 'llms-full.txt'), `${introduction}\n${markdown.join('\n---\n\n')}`);
      await fs.writeFile(path.join(outDir, 'discovery.json'), JSON.stringify(manifest, null, 2) + '\n');

      if (locale === i18n.defaultLocale) {
        const maps = i18n.locales.map(language => {
          const config = i18n.localeConfigs[language];
          return `Sitemap: ${new URL('sitemap.xml', new URL(config.baseUrl, config.url)).href}`;
        });
        // The wildcard also permits search and AI retrieval crawlers. No bot-specific content.
        await fs.writeFile(path.join(outDir, 'robots.txt'), `User-agent: *\nAllow: /\n\n${maps.join('\n')}\n`);
      }
    },
  };
};
