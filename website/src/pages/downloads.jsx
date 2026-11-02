import React, {useEffect, useRef} from 'react';
import Layout from '@theme/Layout';
import Link from '@docusaurus/Link';
import PlatformIcon from '../components/PlatformIcon';
import useText from '../i18n/useText';
import release from '../data/release.json';

const platforms = [
 {id: 'macos', assets: [/\.dmg$/], store: ['Mac App Store', 'https://apps.apple.com/app/id6829451042']},
 {id: 'windows', assets: [/\.msi$/], store: ['Microsoft Store', 'https://apps.microsoft.com/detail/9PDPR6RNT42S']},
 {id: 'ios', assets: [], store: ['App Store', 'https://apps.apple.com/app/id6826865290']},
 {id: 'android', assets: [/\.apk$/], store: ['Google Play', 'https://play.google.com/store/apps/details?id=md.esemnbun.app']},
 {id: 'linux', assets: [/^esemnbun_.*\.deb$/, /^esemnbun-[\d.]+-.*\.rpm$/, /\.flatpak$/]},
];

export default function DownloadsPage() {
 const t = useText();
 const page = useRef(null);
 const platformNav = useRef(null);
 useEffect(() => {
  const measure = () => page.current?.style.setProperty('--download-nav-height', `${platformNav.current.getBoundingClientRect().height}px`);
  measure();
  const observer = new ResizeObserver(measure);
  observer.observe(platformNav.current);
  return () => observer.disconnect();
 }, []);
 return <Layout title={t('downloadsTitle')} description={t('downloadsDescription')}>
  <main className="downloads-page" ref={page}>
   <header className="downloads-header"><span className="downloads-eyebrow">eSemnBun <span aria-hidden="true">/</span> {release.version}</span><h1>{t('downloadsTitle')}</h1><p>{t('downloadsDescription')}</p></header>
   <nav className="download-platform-nav" ref={platformNav} aria-label={t('choosePlatform')}>{platforms.map(({id}) => <a href={`#${id}`} key={id}><PlatformIcon name={id}/>{t(`platform_${id}`)}</a>)}</nav>
   <div className="download-platform-grid">
    {platforms.map(({id, assets, store}) => {
     const installers = release.assets.filter(asset => assets.some(pattern => pattern.test(asset.name)));
     return <section className={`download-platform-card download-platform-${id}`} id={id} key={id}>
      <div className="download-platform-heading"><span className="download-platform-symbol"><PlatformIcon name={id}/></span><div><h2>{t(`platform_${id}`)}</h2><p>{t(`downloadHint_${id}`)}</p></div></div>
      <p className="download-platform-description">{t(`downloadBody_${id}`)}</p>
      <div className="download-installers">{installers.map(asset => {
       const format = asset.name.split('.').pop().toUpperCase();
       return <a className="download-installer" href={asset.url} key={asset.name}><PlatformIcon name="download"/><span><b>{t('downloadFormat').replace('{format}', format)}</b><small>{id === 'linux' && format !== 'FLATPAK' ? 'x86_64 · ' : ''}{(asset.size / 1_000_000).toFixed(1)} MB</small></span><span className="download-file-type">.{format.toLowerCase()}</span></a>;
      })}</div>
      {store && <div className="download-store"><a href={store[1]}><PlatformIcon name={id}/><span>{t('viewStore').replace('{store}', store[0])}</span><PlatformIcon name="external"/></a><p>{t('storeAvailability')}</p></div>}
      <Link className="download-setup-link" to={`/docs/platforms/${id}`}>{t('setupGuide')}</Link>
     </section>;
    })}
    <section className="download-platform-card download-release-card"><span className="download-platform-symbol"><PlatformIcon name="github"/></span><h2>{t('releaseTitle')}</h2><p>{t('releaseBody')}</p><a className="download-release-link" href={release.url}>{t('releaseFiles')}<PlatformIcon name="external"/></a><div className="download-cli-links"><span>{t('cliGuides')}</span>{['macos', 'windows', 'linux'].map(id => <Link key={id} to={`/docs/platforms/${id}-cli`}>{t(`platform_${id}`)}</Link>)}</div></section>
   </div>
   <aside className="downloads-requirements"><h2>{t('beforeDownload')}</h2><p>{t('requirements')} {t('adapters')}</p><Link to="/docs/start">{t('guide')}</Link></aside>
  </main>
 </Layout>;
}
