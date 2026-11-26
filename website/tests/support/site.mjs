// Docusaurus stand-ins with a shared, test-controlled site context.
import {jsx} from './react.mjs';

const defaults = {locale: 'en', colorMode: 'light', pathname: '/', url: 'https://esemnbun.md', baseUrl: '/'};
export const site = {...defaults};
export const resetSite = (values = {}) => Object.assign(site, defaults, values);

const localeBase = locale => locale === 'en' ? '/' : `/${locale}/`;

export function useDocusaurusContext() {
  return {
    siteConfig: {url: site.url, baseUrl: site.baseUrl === '/' ? localeBase(site.locale) : site.baseUrl},
    i18n: {currentLocale: site.locale, defaultLocale: 'en',
      localeConfigs: Object.fromEntries(['en', 'ro', 'ru'].map(locale => [locale, {url: site.url, baseUrl: localeBase(locale)}]))},
  };
}

export const useBaseUrl = path => (site.baseUrl.replace(/\/$/, '') + (path.startsWith('/') ? path : `/${path}`)) || '/';
export const useColorMode = () => ({colorMode: site.colorMode});
export const useLocation = () => ({pathname: site.pathname});
export const Link = ({to, href, children, ...rest}) => jsx('a', {...rest, href: to ?? href, children});
export const Head = ({children}) => jsx('head', {children});
export const Layout = ({children, ...meta}) => jsx('layout', {...meta, children});
export const CodeBlock = ({children, language}) => jsx('pre', {'data-language': language, children});
