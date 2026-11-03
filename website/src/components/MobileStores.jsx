import React from 'react';
import useDocusaurusContext from '@docusaurus/useDocusaurusContext';
import useBaseUrl from '@docusaurus/useBaseUrl';
import useText from '../i18n/useText';
import PlatformIcon from './PlatformIcon';
const links={
 ios:'https://apps.apple.com/app/id6826865290',
 android:'https://play.google.com/store/apps/details?id=md.esemnbun.app',
 macos:'https://apps.apple.com/app/id6829451042',
 windows:'https://apps.microsoft.com/detail/9pdpr6rnt42s?hl=en-US&gl=MD',
};

export default function MobileStores({platform}){
 const {i18n:{currentLocale}}=useDocusaurusContext();const t=useText();
 const apple=useBaseUrl('/img/badges/app-store.svg');
 const google=useBaseUrl(`/img/badges/google-play-${currentLocale}.png`);
 if (!links[platform]) return null;
 if (platform==='windows') return <div className="platform-store platform-store-windows">
  <a className="platform-store-link" href={links.windows}><PlatformIcon name="windows"/>{t('getMicrosoftStore')}</a>
  <p>{t('storeStatus_windows')}</p>
 </div>;
 const appleStore=platform==='ios' || platform==='macos';
 return <div className={`platform-store platform-store-${platform}`}>
  <a href={links[platform]} aria-label={appleStore ? 'App Store' : 'Google Play'}>
   <img className={appleStore ? 'apple-store-badge' : 'google-store-badge'} src={appleStore ? apple : google} alt={appleStore ? 'Download on the App Store' : 'Get it on Google Play'} width={appleStore ? 150 : 190} height={appleStore ? 50 : 74}/>
  </a>
  <p>{t(`storeStatus_${platform}`)}</p>
  {platform==='macos' && <p className="store-version-limitations">{t('macAppStoreLimitations')}</p>}
 </div>;
}
