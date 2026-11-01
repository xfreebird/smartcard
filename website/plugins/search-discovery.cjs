const fs = require('node:fs/promises');
const path = require('node:path');

// Build the discovery file from the deployment URL, including custom-domain builds.
module.exports = function searchDiscovery({i18n}) {
  return {
    name: 'search-discovery',
    async postBuild({outDir, siteConfig}) {
      if (i18n.currentLocale !== i18n.defaultLocale) return;
      const root = new URL(siteConfig.baseUrl, siteConfig.url);
      const maps = i18n.locales.map(locale => {
        const prefix = locale === i18n.defaultLocale ? '' : `${locale}/`;
        return `Sitemap: ${new URL(`${prefix}sitemap.xml`, root).href}`;
      });
      await fs.writeFile(path.join(outDir, 'robots.txt'), `User-agent: *\nAllow: /\n\n${maps.join('\n')}\n`);
    },
  };
};
