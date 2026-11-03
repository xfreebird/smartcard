import React from 'react';
import Layout from '@theme/Layout';
import Link from '@docusaurus/Link';
import Downloads from '../components/Downloads';
import SigningStory from '../components/SigningStory';
import useText from '../i18n/useText';
import MobileStores from '../components/MobileStores';
import useBrowserPlatform from '../components/useBrowserPlatform';
import Head from '@docusaurus/Head';
import useDocusaurusContext from '@docusaurus/useDocusaurusContext';
export default function Home(){
 const t=useText();
 const platform=useBrowserPlatform();
 const {siteConfig,i18n:{currentLocale}}=useDocusaurusContext();
 const siteRoot=new URL(siteConfig.baseUrl,siteConfig.url).href;
 // Docusaurus already includes the current locale in siteConfig.baseUrl.
 const pageURL=siteRoot;
 const structuredData={
  '@context':'https://schema.org', '@type':'SoftwareApplication', name:'eSemnBun',
  url:pageURL, description:t('seoDescription'), applicationCategory:'UtilitiesApplication',
  operatingSystem:'macOS, Windows, Linux, iOS, iPadOS, Android', inLanguage:currentLocale,
  isAccessibleForFree:true, offers:{'@type':'Offer',price:'0',priceCurrency:'EUR'},
  author:{'@type':'Person',name:'Nicolae Ghimbovschi'},
  license:'https://opensource.org/license/mit',
  sameAs:'https://github.com/xfreebird/smartcard',
  image:new URL('img/icon.png',siteRoot).href
 };
 const actionClass=['macos','windows'].includes(platform) ? 'hero-actions stacked-download-actions' : 'hero-actions';
 return <Layout title={t('title')} description={t('seoDescription')}>
 <Head><script type="application/ld+json">{JSON.stringify(structuredData).replace(/</g,'\\u003c')}</script></Head>
 <main className="landing">
  <section className="hero-intro"><span className="project-label">{t('project')}</span><h1>{t('hero1')}<br/><span>{t('hero2')}<br className="mobile-break"/>{' '}{t('hero3')}</span></h1><p>{t('intro1')}<br/>{t('intro2')}<br/>{t('intro3')}</p><div className={actionClass}>{platform==='macos' ? <><Downloads platform={platform} directOnly/><MobileStores platform={platform}/><Downloads optionsOnly/></> : <><MobileStores platform={platform}/><Downloads platform={platform}/></>}<a className="source-link" href="https://github.com/xfreebird/smartcard">{t('source')}</a></div><small>macOS · Windows · Linux · iPhone & iPad · Android</small><a href="#story" className="scroll-cue">{t('how')}</a></section>
  <div id="story"><SigningStory/></div>
  <section className="features"><div className="section-label">{t('why')}</div><h2>{t('whyTitle')}</h2><p className="feature-intro">{t('whyBody')}</p><div className="feature-grid"><article><h3>{t('feature1')}</h3><p>{t('feature1Body')}</p></article><article><h3>{t('feature2')}</h3><p>{t('feature2Body')}</p></article><article><h3>{t('feature3')}</h3><p>{t('feature3Body')}</p></article></div></section>
  <section className="trust-section"><span className="section-label">{t('trustLabel')}</span><h2>{t('trustTitle')}</h2><p>{t('trustBody')}</p><Link to="/privacy">{t('privacyLink')}</Link></section>
  <section className="features signing-questions"><h2>{t('searchTitle')}</h2><p className="feature-intro">{t('searchBody')}</p><div className="feature-grid"><article><h3>{t('moldsignQuestion')}</h3><p>{t('moldsignAnswer')}</p></article><article><h3>{t('phoneQuestion')}</h3><p>{t('phoneAnswer')}</p></article><article><h3>{t('simQuestion')}</h3><p>{t('simAnswer')}</p></article></div><p><Link to="/docs/moldsign">{t('searchGuide')}</Link></p><p><Link to="/docs/signing">{t('verifyGuide')}</Link></p></section>
  <section id="downloads" className="final-cta"><h2>{t('cta')}</h2><p>{t('requirements')}<br/>{t('adapters')}</p><div className={actionClass}>{platform==='macos' ? <><Downloads platform={platform} directOnly/><MobileStores platform={platform}/><Downloads optionsOnly/></> : <><MobileStores platform={platform}/><Downloads platform={platform}/></>}</div><Link className="guide-link" to="/docs/start">{t('guide')}</Link></section>
 </main></Layout>}
