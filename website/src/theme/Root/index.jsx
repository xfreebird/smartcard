import React from 'react';
import Head from '@docusaurus/Head';
import {useLocation} from '@docusaurus/router';
import useDocusaurusContext from '@docusaurus/useDocusaurusContext';
import discovery from '../../data/search-discovery.json';

export default function Root({children}) {
 const {siteConfig}=useDocusaurusContext();
 const {pathname}=useLocation();
 const root=new URL(siteConfig.baseUrl,siteConfig.url);
 const route=pathname.slice(root.pathname.length).replace(/\/$/,'');
 const documentId=route.startsWith('docs/') ? route.slice(5) : null;
 // Keep the requested URL and language stable for people, crawlers and shared links.
 // Docusaurus' language menu provides explicit navigation between translations.
 return <><Head>
  <link rel="alternate" type="text/plain" href={new URL('llms.txt',root).href} title="eSemnBun documentation index"/>
  <link rel="describedby" type="application/json" href={new URL('discovery.json',root).href}/>
  {discovery.documents.includes(documentId) && <link rel="alternate" type="text/markdown" href={new URL(`markdown/${documentId}.md`,root).href} title="Markdown"/>}
 </Head>{children}</>;
}
