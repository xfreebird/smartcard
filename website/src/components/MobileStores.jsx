import React from 'react';
import useDocusaurusContext from '@docusaurus/useDocusaurusContext';
import useBaseUrl from '@docusaurus/useBaseUrl';
import useText from '../i18n/useText';
import release from '../data/release.json';
export function StoreBadge({store, locale}) {
 const badge = useBaseUrl(store.badges?.[locale] || store.badges?.en || '/');
 return <a className="download-store-badge" href={store.url} aria-label={store.name}>
  {store.badges ? <img src={badge} alt={store.name}/> : <span>{store.name} ↗</span>}
 </a>;
}

export default function MobileStores({platform}){
 const {i18n:{currentLocale}}=useDocusaurusContext();const t=useText();
 const {store, additionalStores = []} = release.platforms.find(item => item.id === platform) || {};
 const badge = useBaseUrl(store ? (store.badges[currentLocale] || store.badges.en) : '/img/badges/app-store-en.svg');
 if (!store) return null;
 if (platform==='android') return <div className="platform-store platform-store-android">
  <div className="mobile-store-badges">
   {[store, ...additionalStores].map(item => <StoreBadge key={item.url} store={item} locale={currentLocale}/>)}
  </div>
  <p>{t('storeStatus_android')}</p>
 </div>;
 const appleStore=platform==='ios' || platform==='macos';
 return <div className={`platform-store platform-store-${platform}`}>
  <a href={store.url} aria-label={store.name}>
   <img className={appleStore ? 'apple-store-badge' : 'google-store-badge'} src={badge} alt={store.name} width={platform==='macos' ? 250 : appleStore ? 150 : 190} height={platform==='macos' ? 64 : appleStore ? 50 : 74}/>
  </a>
  {additionalStores.map(item => <StoreBadge key={item.url} store={item} locale={currentLocale}/>)}
  {platform!=='macos' && <p>{t(`storeStatus_${platform}`)}</p>}
  {platform==='macos' && <p className="store-version-limitations">{t('macAppStoreLimitations')}</p>}
 </div>;
}
