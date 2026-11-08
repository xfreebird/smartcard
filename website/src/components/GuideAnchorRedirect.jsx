import {useEffect} from 'react';
import useBaseUrl from '@docusaurus/useBaseUrl';
import useDocusaurusContext from '@docusaurus/useDocusaurusContext';
import navigation from '@site/src/data/guide-navigation.json';

/** Continue bookmarked sections at their new focused task page. */
export default function GuideAnchorRedirect({platform}) {
  const {i18n} = useDocusaurusContext();
  const base = useBaseUrl(`/docs/platforms/${platform}/`);
  useEffect(()=>{
    let anchor;
    try {anchor=decodeURIComponent(window.location.hash.slice(1));} catch {return;}
    const item=navigation.platforms.find(entry=>entry.id===platform);
    const target=item?.anchors[i18n.currentLocale]?.[anchor];
    if (target) window.location.replace(base+target);
  },[platform,base,i18n.currentLocale]);
  return null;
}
