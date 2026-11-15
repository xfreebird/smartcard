import React from 'react';
import useBaseUrl from '@docusaurus/useBaseUrl';
import {useColorMode} from '@docusaurus/theme-common';
import screenshots from '../data/screenshotRevision.json';

/** Show the native capture matching the documentation's current appearance. */
export default function PlatformScreenshots({platform, scenario = 'ready', alt, caption}) {
  const {colorMode} = useColorMode();
  const root = useBaseUrl(`/img/docs/v0.2.0/${platform}/`);
  return <div className="platform-screenshots" aria-label={`${alt} screenshots`}>
    <figure><img src={`${root}${scenario}-${colorMode === 'dark' ? 'dark' : 'light'}.png?v=${screenshots.revision}`} alt={alt} loading="lazy" />{caption && <figcaption>{caption}</figcaption>}</figure>
  </div>;
}
