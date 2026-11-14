import React from 'react';
import useDocusaurusContext from '@docusaurus/useDocusaurusContext';
import useBaseUrl from '@docusaurus/useBaseUrl';
import useText from '../i18n/useText';
import release from '../data/release.json';
const links = Object.fromEntries(release.platforms.filter(platform => platform.store).map(platform => [platform.id, platform.store.url]));

function AdditionalStoreBadge({store, locale}) {
 const badge = useBaseUrl(store.badges?.[locale] || store.badges?.en || '/');
 return <a className="download-store-badge" href={store.url} aria-label={store.name}>
  {store.badges ? <img src={badge} alt={store.name} width={202} height={62}/> : <span>{store.name} ↗</span>}
 </a>;
}

export default function MobileStores({platform}){
 const {i18n:{currentLocale}}=useDocusaurusContext();const t=useText();
 const store = release.platforms.find(item => item.id === platform)?.store;
 const badge = useBaseUrl(store ? (store.badges[currentLocale] || store.badges.en) : '/img/badges/app-store-en.svg');
 if (!store) return null;
 const appleStore=platform==='ios' || platform==='macos';
 return <div className={`platform-store platform-store-${platform}`}>
  <a href={links[platform]} aria-label={store.name}>
   <img className={appleStore ? 'apple-store-badge' : 'google-store-badge'} src={badge} alt={store.name} width={appleStore ? 150 : 190} height={appleStore ? 50 : 74}/>
  </a>
  {release.platforms.find(item => item.id === platform)?.additionalStores?.map(item =>
   <AdditionalStoreBadge key={item.url} store={item} locale={currentLocale}/>)}
  <p>{t(`storeStatus_${platform}`)}</p>
  {platform==='macos' && <p className="store-version-limitations">{t('macAppStoreLimitations')}</p>}
 </div>;
}
