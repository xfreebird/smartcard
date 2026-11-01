import React from 'react';
import useDocusaurusContext from '@docusaurus/useDocusaurusContext';
import useBaseUrl from '@docusaurus/useBaseUrl';
import useText from '../i18n/useText';
export default function MobileStores(){
 const {i18n:{currentLocale}}=useDocusaurusContext();const t=useText();
 const apple=useBaseUrl('/img/badges/app-store.svg');
 const google=useBaseUrl(`/img/badges/google-play-${currentLocale}.png`);
 return <div className="mobile-stores">
  <div className="mobile-store-badges">
   <a href="https://apps.apple.com/app/id6826865290" aria-label="App Store"><img className="apple-store-badge" src={apple} alt="Download on the App Store" width="150" height="50"/></a>
   <a href="https://play.google.com/store/apps/details?id=md.esemnbun.app" aria-label="Google Play"><img className="google-store-badge" src={google} alt="Google Play" width="190" height="74"/></a>
  </div>
  <p>{t('mobileStoreStatus')}</p>
 </div>;
}
