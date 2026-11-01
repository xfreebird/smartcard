const config = {
  title: 'eSemnBun', tagline: 'Sign with your Moldovan electronic ID card.',
  favicon: 'img/icon.png', url: process.env.SITE_URL || 'https://xfreebird.github.io',
  baseUrl: process.env.BASE_URL || '/smartcard/', trailingSlash: true,
  organizationName: 'xfreebird', projectName: 'smartcard', onBrokenLinks: 'throw',
  i18n: {defaultLocale: 'en', locales: ['en','ro','ru'], localeConfigs: {en:{label:'English'},ro:{label:'Română'},ru:{label:'Русский'}}},
  presets: [['classic', {docs: {sidebarPath: './sidebars.js'}, blog: false,
    theme: {customCss: './src/css/custom.css'}}]],
  themeConfig: {
    colorMode: {defaultMode: 'light', disableSwitch: true},
    navbar: {title: 'eSemnBun', logo: {alt: 'eSemnBun', src: 'img/icon.png'}, items: [
      {type:'localeDropdown', position:'right'},
      {to: '/docs/start', label: 'How it works', position: 'right'},
      {to: '/support', label: 'Support', position: 'right'},
      {href: 'https://github.com/xfreebird/smartcard', label: 'Source', position: 'right'}]},
    footer: {style: 'dark', links: [
      {title: 'Get started', items: [{label: 'Documentation', to: '/docs/start'}, {label: 'Downloads', href: 'https://github.com/xfreebird/smartcard/releases/latest'}]},
      {title: 'Here to help', items: [{label: 'Support', to: '/support'}, {label: 'Privacy', to: '/privacy'}, {label: 'Usage & license', to: '/terms'}]},
      {title: 'Open source', items: [{label: 'GitHub', href: 'https://github.com/xfreebird/smartcard'}, {label: 'MIT license', href: 'https://github.com/xfreebird/smartcard/blob/main/LICENSE'}]}],
      copyright: '© 2026 Nicolae Ghimbovschi. Independent software, made in Moldova.'}
  }
};
export default config;
