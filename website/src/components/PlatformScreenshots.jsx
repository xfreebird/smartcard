import React from 'react';
import useBaseUrl from '@docusaurus/useBaseUrl';

/** A paired, real-app capture from the same mock scenario in both supported themes. */
export default function PlatformScreenshots({platform, scenario = 'ready', alt}) {
  const source = theme => useBaseUrl(`/img/docs/v0.2.0/${platform}/${scenario}-${theme}.png`);
  return <div className="platform-screenshots" aria-label={`${alt} screenshots`}>
    <figure><img src={source('light')} alt={`${alt}, light appearance`} /><figcaption>Light appearance</figcaption></figure>
    <figure><img src={source('dark')} alt={`${alt}, dark appearance`} /><figcaption>Dark appearance</figcaption></figure>
  </div>;
}
