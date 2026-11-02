import {useEffect, useState} from 'react';
import {browserPlatform} from './browserPlatform.mjs';

// Rendering a neutral control first keeps Docusaurus SSR and hydration stable.
export default function useBrowserPlatform() {
 const [platform, setPlatform] = useState('other');
 useEffect(() => setPlatform(browserPlatform(navigator.userAgent, navigator.maxTouchPoints || 0)), []);
 return platform;
}
