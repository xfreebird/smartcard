// Node module hooks: transform website JSX/ESM .js sources with Babel and map Docusaurus aliases.
import {createRequire} from 'node:module';
import {readFile} from 'node:fs/promises';
import {existsSync} from 'node:fs';
import {fileURLToPath} from 'node:url';

const website = new URL('../../', import.meta.url);
const source = new URL('src/', website);
const support = new URL('./', import.meta.url);
const babel = createRequire(new URL('package.json', website))('@babel/core');

const stubs = {
  '@docusaurus/Link': 'Link', '@docusaurus/Head': 'Head', '@theme/Layout': 'Layout', '@theme/CodeBlock': 'CodeBlock',
  '@docusaurus/useBaseUrl': 'useBaseUrl', '@docusaurus/useDocusaurusContext': 'useDocusaurusContext',
};
const modules = {
  react: 'react.mjs', 'react/jsx-runtime': 'jsx-runtime.mjs', 'react/jsx-dev-runtime': 'jsx-runtime.mjs',
  '@docusaurus/theme-common': 'site.mjs', '@docusaurus/router': 'site.mjs',
};

// CSS modules and JSON data resolve to support URLs so coverage reports only real sources.
const cssModule = new URL('css-module.mjs', support).href;
const jsonModule = new URL('json-module.mjs', support).href;

export async function resolve(specifier, context, nextResolve) {
  if (modules[specifier]) return {url: new URL(modules[specifier], support).href, shortCircuit: true};
  if (specifier.endsWith('.module.css')) return {url: cssModule, shortCircuit: true};
  if (specifier.endsWith('.json') && context.importAttributes?.type !== 'json') {
    const target = specifier.startsWith('@site/') ? new URL(specifier.slice(6), website).href : new URL(specifier, context.parentURL).href;
    return {url: `${jsonModule}?file=${encodeURIComponent(target)}`, shortCircuit: true};
  }
  if (stubs[specifier]) return {url: `${new URL('site.mjs', support).href}?default=${stubs[specifier]}`, shortCircuit: true};
  if (specifier.startsWith('@site/')) return nextResolve(new URL(specifier.slice(6), website).href, context);
  const parent = context.parentURL || '';
  if (parent.startsWith(source.href) && specifier.startsWith('.') && !/\.[a-z]+$/i.test(specifier)) {
    for (const extension of ['.jsx', '.js', '.mjs']) {
      const candidate = new URL(specifier + extension, parent);
      if (existsSync(fileURLToPath(candidate))) return {url: candidate.href, shortCircuit: true};
    }
  }
  return nextResolve(specifier, context);
}

export async function load(url, context, nextLoad) {
  const [path, query] = url.split('?');
  if (query?.startsWith('default=')) {
    return {format: 'module', shortCircuit: true, source: `export {${query.slice(8)} as default} from ${JSON.stringify(path)};`};
  }
  if (url === cssModule) {
    return {format: 'module', shortCircuit: true, source: 'export default new Proxy({}, {get: (_, name) => String(name)});'};
  }
  if (url.startsWith(`${jsonModule}?file=`)) {
    const file = new URL(decodeURIComponent(query.slice(5)));
    return {format: 'module', shortCircuit: true, source: `export default ${await readFile(file, 'utf8')};`};
  }
  if (url.startsWith(source.href) && /\.(jsx|js)$/.test(path)) {
    const filename = fileURLToPath(url);
    const {code} = babel.transformSync(await readFile(filename, 'utf8'), {
      filename, babelrc: false, configFile: false, retainLines: true, sourceMaps: 'inline',
      presets: [[createRequire(new URL('package.json', website)).resolve('@babel/preset-react'), {runtime: 'automatic'}]],
    });
    return {format: 'module', shortCircuit: true, source: code};
  }
  return nextLoad(url, context);
}
