import React from 'react';
import Layout from '@theme/Layout';
import Link from '@docusaurus/Link';
import useBaseUrl from '@docusaurus/useBaseUrl';
import useDocusaurusContext from '@docusaurus/useDocusaurusContext';
import PlatformIcon from '../components/PlatformIcon';
import useText from '../i18n/useText';
import release from '../data/release.json';
import PackageDownloads from '../components/PackageDownloads';
import {isCLI, platformAssets} from '../components/downloadAssets.mjs';
import useDownloadNavigation from '../components/useDownloadNavigation';

const platforms = release.platforms.filter(platform => platform.id !== 'linux-cli');

function StoreBadge({store, locale}) {
 const src = useBaseUrl(store.badges?.[locale] || store.badges?.en || '/');
 return <a className="download-store-badge" href={store.url} aria-label={store.name}>
  {store.badges ? <img src={src} alt={store.name}/> : <span>{store.name} ↗</span>}
 </a>;
}

export default function DownloadsPage() {
 const t = useText();
 const {i18n: {currentLocale}} = useDocusaurusContext();
 const {navRef, selectedPlatform, selectCard, navigate} = useDownloadNavigation(platforms);
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
   <nav ref={navRef} className="download-platform-nav" aria-label={t('choosePlatform')}
    style={{'--download-platform-count': platforms.length}}>
    {platforms.map(platform => <a key={platform.id} href={`#${platform.id}`}
     aria-current={selectedPlatform === platform.id ? 'location' : undefined}
     onClick={event => navigate(event, platform.id)}>
     <PlatformIcon name={platform.icon}/><span>{text(platform.name)}</span>
    </a>)}
   </nav>
   <div className="download-platform-grid">
    {platforms.map(platform => <section className={`download-platform-card${selectedPlatform === platform.id ? ' download-platform-card-selected' : ''}`} id={platform.id} key={platform.id} aria-labelledby={`${platform.id}-title`}
     tabIndex={0}
     onClick={() => selectCard(platform.id)}
     onKeyDown={event => {
      if (event.target === event.currentTarget && (event.key === 'Enter' || event.key === ' ')) {
       event.preventDefault();
       selectCard(platform.id);
      }
     }}>
     <div className="download-platform-heading">
      <span className="download-platform-symbol"><PlatformIcon name={platform.icon}/></span>
      <div className="download-platform-title"><h2 id={`${platform.id}-title`}>{text(platform.name)}</h2><p>{platform.id === 'linux' ? text({en: 'Desktop app and command-line tools · x86-64', ro: 'Aplicație desktop și instrumente în linia de comandă · x86-64', ru: 'Настольное приложение и инструменты командной строки · x86-64'}) : text(platform.requirements)}</p></div>
      <div className="download-stores">{[platform.store, ...(platform.additionalStores || [])].filter(Boolean).map(store => <StoreBadge key={store.url} store={store} locale={currentLocale}/>)}</div>
     </div>
     <div className="download-installers">
      {platformAssets(release.assets, platform.id).map((asset, index, assets) => {const info=installerInfo(asset);return <React.Fragment key={asset.name}>
       {(index === 0 || isCLI(asset) !== isCLI(assets[index - 1])) && <h3 className="download-group-label">{isCLI(asset)
        ? text({en: 'Command-line tools', ro: 'Instrumente în linia de comandă', ru: 'Инструменты командной строки'})
        : text({en: 'Standalone app', ro: 'Aplicație independentă', ru: 'Отдельное приложение'})}</h3>}
       <a className="download-installer" href={asset.url} key={asset.name} title={asset.name}>
       <PlatformIcon name="download"/><span><b>{info.label}</b>
       {info.description && <small>{info.description}</small>}
       <small>{[asset.version, asset.architecture, `${(asset.size / 1_000_000).toFixed(1)} MB`].filter(Boolean).join(' · ')}</small></span>
       <PlatformIcon name="external"/>
      </a></React.Fragment>;})}
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
