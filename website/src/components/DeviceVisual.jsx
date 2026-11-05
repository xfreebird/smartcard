import React from 'react';
import useBaseUrl from '@docusaurus/useBaseUrl';

export default function DeviceVisual({image, alt, className = ''}) {
 return <img className={`device-visual ${className}`} src={useBaseUrl(image)} alt={alt} loading="lazy"/>;
}
