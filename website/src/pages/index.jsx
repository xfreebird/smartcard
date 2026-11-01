import React from 'react';
import Layout from '@theme/Layout';
import Link from '@docusaurus/Link';
import Downloads from '../components/Downloads';
import SigningStory from '../components/SigningStory';
import useText from '../i18n/useText';
export default function Home(){const t=useText();return <Layout title={t('title')} description={t('intro1')}>
 <main className="landing">
  <section className="hero-intro"><span className="project-label">{t('project')}</span><h1>{t('hero1')}<br/><span>{t('hero2')}<br className="mobile-break"/>{' '}{t('hero3')}</span></h1><p>{t('intro1')}<br/>{t('intro2')}<br/>{t('intro3')}</p><div className="hero-actions"><Downloads/><a className="source-link" href="https://github.com/xfreebird/smartcard">{t('source')}</a></div><small>macOS · Windows · Linux · iPhone & iPad · Android</small><a href="#story" className="scroll-cue">{t('how')}</a></section>
  <div id="story"><SigningStory/></div>
  <section className="features"><div className="section-label">{t('why')}</div><h2>{t('whyTitle')}</h2><div className="feature-grid"><article><h3>{t('feature1')}</h3><p>{t('feature1Body')}</p></article><article><h3>{t('feature2')}</h3><p>{t('feature2Body')}</p></article><article><h3>{t('feature3')}</h3><p>{t('feature3Body')}</p></article></div></section>
  <section className="trust-section"><span className="section-label">{t('trustLabel')}</span><h2>{t('trustTitle')}</h2><p>{t('trustBody')}</p><Link to="/privacy">{t('privacyLink')}</Link></section>
  <section id="downloads" className="final-cta"><h2>{t('cta')}</h2><p>{t('requirements')}<br/>{t('adapters')}</p><Downloads/><Link className="guide-link" to="/docs/start">{t('guide')}</Link></section>
 </main></Layout>}
