const config = {
  title: 'eSemnBun', tagline: 'Sign with your Moldovan electronic ID card.',
  favicon: 'img/icon.png', url: process.env.SITE_URL || 'https://esemnbun.md',
  baseUrl: process.env.BASE_URL || '/', trailingSlash: true,
  organizationName: 'xfreebird', projectName: 'smartcard', onBrokenLinks: 'throw',
  plugins: ['./plugins/search-discovery.cjs'],
  i18n: {defaultLocale: 'en', locales: ['en','ro','ru'], localeConfigs: {en:{label:'English'},ro:{label:'Română'},ru:{label:'Русский'}}},
  presets: [['classic', {docs: {sidebarPath: './sidebars.js'}, blog: false,
    sitemap: {changefreq: 'monthly', ignorePatterns: ['/**/404']},
    theme: {customCss: './src/css/custom.css'}}]],
  themeConfig: {
    metadata: [{name: 'robots', content: 'max-image-preview:large'}],
    docs: {sidebar: {autoCollapseCategories: true}},
    image: 'img/icon.png',
    colorMode: {defaultMode: 'light', disableSwitch: false, respectPrefersColorScheme: true},
    navbar: {hideOnScroll: true, title: 'eSemnBun', logo: {alt: 'eSemnBun', src: 'img/icon.png'}, items: [
      {type:'localeDropdown', position:'right'},
      {to: '/downloads', label: 'Downloads', position: 'right'},
      {to: '/docs/platforms', label: 'Guides', position: 'right'},
      {type: 'docSidebar', sidebarId: 'developers', label: 'Developers', position: 'right'},
      {to: '/docs/mcp-moldsign', label: 'MCP', position: 'right'},
      {to: '/devices', label: 'Devices', position: 'right'},
      {to: '/support', label: 'Support', position: 'right'},
      {href: 'https://github.com/xfreebird/smartcard', label: 'Source', position: 'right'}]},
    footer: {style: 'dark', links: [
      {title: 'Get started', items: [{label: 'Documentation', to: '/docs/platforms'}, {label: 'MoldSign alternative', to: '/docs/moldsign'}, {label: 'MCP and AI agents', to: '/docs/mcp-moldsign'}, {label: 'Downloads', to: '/downloads'}, {label: 'Devices', to: '/devices'}]},
      {title: 'Here to help', items: [{label: 'Support', to: '/support'}, {label: 'Privacy', to: '/privacy'}, {label: 'Terms & conditions', to: '/terms'}]},
      {title: 'Open source', items: [{label: 'Developer documentation', to: '/docs/developers/overview'}, {label: 'Agent reference', to: '/docs/developers/agents'}, {label: 'GitHub', href: 'https://github.com/xfreebird/smartcard'}, {label: 'MIT license', href: 'https://github.com/xfreebird/smartcard/blob/main/LICENSE'}]}],
      copyright: '© 2026 Nicolae Ghimbovschi. Independent software, made in Moldova.'}
  }
};
export default config;
