import React,{useEffect} from 'react';
import useDocusaurusContext from '@docusaurus/useDocusaurusContext';
import {browserLocale} from '../../i18n/browserLocale.mjs';
export default function Root({children}){
 const {siteConfig,i18n}=useDocusaurusContext();
 useEffect(()=>{
  // Static Pages cannot negotiate Accept-Language. Detect once per tab, then respect
  // explicit language navigation for the rest of the session. Localized deep links win.
  try{
   if(sessionStorage.getItem('esemnbun.localeChosen'))return;
   sessionStorage.setItem('esemnbun.localeChosen','1');
   if(i18n.currentLocale!=='en')return;
   const language=browserLocale(navigator.languages||[navigator.language]);
   if(language==='en')return;
   const base=siteConfig.baseUrl;
   const tail=window.location.pathname.slice(base.length);
   window.location.replace(`${base}${language}/${tail}${window.location.search}${window.location.hash}`);
  }catch{ /* Storage may be disabled; keep the explicitly requested route. */ }
 },[i18n.currentLocale,siteConfig.baseUrl]);
 return <>{children}</>;
}
