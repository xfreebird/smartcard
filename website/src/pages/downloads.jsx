import React, {useEffect, useState} from 'react';
import Layout from '@theme/Layout';
import Link from '@docusaurus/Link';
import useBaseUrl from '@docusaurus/useBaseUrl';
import useDocusaurusContext from '@docusaurus/useDocusaurusContext';
import PlatformIcon from '../components/PlatformIcon';
import useText from '../i18n/useText';
import release from '../data/release.json';
import PackageDownloads from '../components/PackageDownloads';

const platforms = release.platforms.filter(platform => platform.id !== 'linux-cli');

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
   const hash = window.location.hash.slice(1);
   const id = hash === 'linux-cli' ? 'linux' : hash === 'cli' ? 'macos' : hash;
   setSelectedPlatform(platforms.some(platform => platform.id === id) ? id : platforms[0].id);
   if (id !== hash) {
    window.history.replaceState(null, '', `#${id}`);
    document.getElementById(id)?.scrollIntoView();
   }
  };
  selectFromHash();
  window.addEventListener('hashchange', selectFromHash);
  return () => window.removeEventListener('hashchange', selectFromHash);
 }, []);
 const text = value => value[currentLocale] || value.en;
 const installerInfo = asset => {
  if ((asset.platform === 'macos' && asset.format === 'TAR.GZ') ||
      (asset.platform === 'windows' && asset.format === 'ZIP' && asset.name.startsWith('esemnbun-cli-')) || asset.platform === 'linux-cli') {
   return {
    label: text({en: `CLI & MCP tools · ${asset.format}`, ro: `Instrumente CLI și MCP · ${asset.format}`, ru: `Инструменты CLI и MCP · ${asset.format}`}),
    description: text({en: 'For terminal use and agent integrations. Contains command-line tools, not the desktop app.', ro: 'Pentru terminal și integrări cu agenți. Conține instrumente în linia de comandă, nu aplicația desktop.', ru: 'Для терминала и интеграции с агентами. Содержит инструменты командной строки, а не настольное приложение.'}),
   };
  }
  if (asset.platform === 'macos' && asset.format === 'DMG') return {
   label: text({en: 'Desktop app · DMG', ro: 'Aplicație desktop · DMG', ru: 'Настольное приложение · DMG'}),
   description: text({en: 'Open the disk image and drag eSemnBun to Applications.', ro: 'Deschide imaginea de disc și trage eSemnBun în dosarul Aplicații.', ru: 'Откройте образ диска и перетащите eSemnBun в папку «Программы».'}),
  };
  if (asset.platform === 'windows' && asset.format === 'MSI') return {
   label: text({en: 'Desktop app installer · MSI', ro: 'Program de instalare desktop · MSI', ru: 'Установщик настольного приложения · MSI'}),
   description: text({en: 'Run the installer to install the Windows desktop app.', ro: 'Rulează programul de instalare pentru a instala aplicația desktop Windows.', ru: 'Запустите установщик для установки настольного приложения Windows.'}),
  };
  if (asset.platform === 'linux') return {label: text({en: `Desktop app · ${asset.format}`, ro: `Aplicație desktop · ${asset.format}`, ru: `Настольное приложение · ${asset.format}`})};
  return {label: t('downloadFormat').replace('{format}', asset.format)};
 };
 return <Layout title={t('downloadsTitle')} description={t('downloadsDescription')}>
  <main className="downloads-page">
   <header className="downloads-header">
    <span className="downloads-eyebrow">eSemnBun <span aria-hidden="true">/</span> {release.version}</span>
    <h1>{t('downloadsTitle')}</h1><p>{t('downloadsDescription')}</p>
   </header>
   <nav className="download-platform-nav" aria-label={t('choosePlatform')}>
    {platforms.map(platform => <a key={platform.id} href={`#${platform.id}`}
     aria-current={selectedPlatform === platform.id ? 'location' : undefined}
     onClick={() => setSelectedPlatform(platform.id)}>
     <PlatformIcon name={platform.icon}/>{text(platform.name)}
    </a>)}
   </nav>
   <div className="download-platform-grid">
    {platforms.map(platform => <section className={`download-platform-card${selectedPlatform === platform.id ? ' download-platform-card-selected' : ''}`} id={platform.id} key={platform.id} aria-labelledby={`${platform.id}-title`}
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
      <div className="download-platform-title"><h2 id={`${platform.id}-title`}>{text(platform.name)}</h2><p>{platform.id === 'linux' ? text({en: 'Desktop app and command-line tools · x86-64', ro: 'Aplicație desktop și instrumente în linia de comandă · x86-64', ru: 'Настольное приложение и инструменты командной строки · x86-64'}) : text(platform.requirements)}</p></div>
      {platform.store && <StoreBadge store={platform.store} locale={currentLocale}/>}
     </div>
     <div className="download-installers">
      {release.assets.filter(asset => (asset.platform === 'linux-cli' ? 'linux' : asset.platform) === platform.id).map(asset => {const info=installerInfo(asset);return <a className="download-installer" href={asset.url} key={asset.name} title={asset.name}>
       <PlatformIcon name="download"/><span><b>{info.label}</b>
       {info.description && <small>{info.description}</small>}
       <small>{[asset.version, asset.architecture, `${(asset.size / 1_000_000).toFixed(1)} MB`].filter(Boolean).join(' · ')}</small></span>
       <PlatformIcon name="external"/>
      </a>;})}
      {platform.alternatives?.map(option => <a className="download-installer" href={option.url} key={option.url}>
       <PlatformIcon name="github"/><span><b>{text(option.label)}</b><small>{text(option.hint)}</small></span>
      </a>)}
     </div>
     <PackageDownloads platform={platform.id}/>
     <div className="download-card-footer">
      {platform.installerNote && <p>{text(platform.installerNote)}</p>}
      {platform.noteKey && <p>{t(platform.noteKey)}</p>}
      <Link className="download-setup-link" to={platform.guide}>{t('setupGuide')} <span aria-hidden="true">↗</span></Link>
     </div>
    </section>)}
   </div>
   <aside className="downloads-requirements">
    <p>{t('downloadRequirementsBrief')}</p>
    <Link to="/docs/start">{t('guide')}</Link> · <Link to="/devices">{t('recommendedDevices')}</Link>
    <small>{t('storeAvailability')}</small>
   </aside>
  </main>
 </Layout>;
}
