import React,{useId} from 'react';
import useText from '../i18n/useText';
import {previewPlatforms} from './previewPlatformState.mjs';

const names={macos:'macOS',windows:'Windows',linux:'Linux',iphone:'iPhone',android:'Android'};
export default function PlatformPreview({value,onChange}){
 const t=useText(),id=useId();
 return <aside className="platform-preview" aria-label={t('debugPreview')}>
  <label htmlFor={id}>{t('debugPreview')}</label>
  <select id={id} value={value} onChange={event=>onChange(event.target.value)}>
   {previewPlatforms.map(platform=><option key={platform} value={platform}>{names[platform] || t('automaticPlatform')}</option>)}
  </select>
 </aside>;
}
