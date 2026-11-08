import React, {useEffect, useState} from 'react';
import Layout from '@theme/Layout';
import Link from '@docusaurus/Link';
import useBaseUrl from '@docusaurus/useBaseUrl';
import useDocusaurusContext from '@docusaurus/useDocusaurusContext';
import PlatformIcon from '../components/PlatformIcon';
import useText from '../i18n/useText';
import release from '../data/release.json';
import PackageDownloads from '../components/PackageDownloads';

function StoreBadge({store, locale}) {
 const src = useBaseUrl(store.badges[locale] || store.badges.en);
 return <a className="download-store-badge" href={store.url} aria-label={store.name}>
  <img src={src} alt={store.name}/>
 </a>;
}

export default function DownloadsPage() {
 const t = useText();
 const {i18n: {currentLocale}} = useDocusaurusContext();
 const [selectedPlatform, setSelectedPlatform] = useState(release.platforms[0].id);
 useEffect(() => {
  const selectFromHash = () => {
   const id = window.location.hash.slice(1);
   setSelectedPlatform((id === 'cli' || release.platforms.some(platform => platform.id === id)) ? id : release.platforms[0].id);
  };
  selectFromHash();
  window.addEventListener('hashchange', selectFromHash);
  return () => window.removeEventListener('hashchange', selectFromHash);
 }, []);
 const text = value => value[currentLocale] || value.en;
 return <Layout title={t('downloadsTitle')} description={t('downloadsDescription')}>
  <main className="downloads-page">
   <header className="downloads-header">
    <span className="downloads-eyebrow">eSemnBun <span aria-hidden="true">/</span> {release.version}</span>
    <h1>{t('downloadsTitle')}</h1><p>{t('downloadsDescription')}</p>
    <p><a href="#cli">{text({en: 'Install CLI with Homebrew, Scoop, Chocolatey, APT or DNF', ro: 'Instalează CLI cu Homebrew, Scoop, Chocolatey, APT sau DNF', ru: 'Установить CLI через Homebrew, Scoop, Chocolatey, APT или DNF'})}</a></p>
   </header>
   <nav className="download-platform-nav" aria-label={t('choosePlatform')}>
    {release.platforms.map(platform => <a key={platform.id} href={`#${platform.id}`}
     aria-current={selectedPlatform === platform.id ? 'location' : undefined}
     onClick={() => setSelectedPlatform(platform.id)}>
     <PlatformIcon name={platform.icon}/>{text(platform.name)}
    </a>)}
    <a href="#cli" aria-current={selectedPlatform === 'cli' ? 'location' : undefined} onClick={() => setSelectedPlatform('cli')}>CLI</a>
   </nav>
   <div className="download-platform-grid">
    {release.platforms.map(platform => <section className={`download-platform-card${selectedPlatform === platform.id ? ' download-platform-card-selected' : ''}`} id={platform.id} key={platform.id} aria-labelledby={`${platform.id}-title`}
     tabIndex={0}
     onClick={() => {
      setSelectedPlatform(platform.id);
      window.history.replaceState(null, '', `#${platform.id}`);
     }}
     onKeyDown={event => {
      if (event.target === event.currentTarget && (event.key === 'Enter' || event.key === ' ')) {
       event.preventDefault();
       setSelectedPlatform(platform.id);
       window.history.replaceState(null, '', `#${platform.id}`);
      }
     }}>
     <div className="download-platform-heading">
      <span className="download-platform-symbol"><PlatformIcon name={platform.icon}/></span>
      <div className="download-platform-title"><h2 id={`${platform.id}-title`}>{text(platform.name)}</h2><p>{text(platform.requirements)}</p></div>
      {platform.store && <StoreBadge store={platform.store} locale={currentLocale}/>}
     </div>
     <div className="download-installers">
      {release.assets.filter(asset => asset.platform === platform.id).map(asset => <a className="download-installer" href={asset.url} key={asset.name} title={asset.name}>
       <PlatformIcon name="download"/><span><b>{t('downloadFormat').replace('{format}', asset.format)}</b>
       <small>{[asset.version, asset.architecture, `${(asset.size / 1_000_000).toFixed(1)} MB`].filter(Boolean).join(' · ')}</small></span>
       <PlatformIcon name="external"/>
      </a>)}
      {platform.alternatives?.map(option => <a className="download-installer" href={option.url} key={option.url}>
       <PlatformIcon name="github"/><span><b>{text(option.label)}</b><small>{text(option.hint)}</small></span>
      </a>)}
     </div>
     <div className="download-card-footer">
      {platform.installerNote && <p>{text(platform.installerNote)}</p>}
      {platform.noteKey && <p>{t(platform.noteKey)}</p>}
      <Link className="download-setup-link" to={platform.guide}>{t('setupGuide')} <span aria-hidden="true">↗</span></Link>
     </div>
    </section>)}
   </div>
   <PackageDownloads/>
   <aside className="downloads-requirements">
    <p>{t('downloadRequirementsBrief')}</p>
    <Link to="/docs/start">{t('guide')}</Link> · <Link to="/devices">{t('recommendedDevices')}</Link>
    <small>{t('storeAvailability')}</small>
   </aside>
  </main>
 </Layout>;
}
