import React, {useState, useId, useRef, useEffect} from 'react';
import Link from '@docusaurus/Link';
import useText from '../i18n/useText';
import PlatformIcon from './PlatformIcon';

export default function Downloads() {
 const t = useText();
 const [open, setOpen] = useState(false);
 const [placement, setPlacement] = useState({above: false, space: 460});
 const control = useRef(null);
 const menuId = useId();
 useEffect(() => {
  if (!open) return;
  const rect = control.current.getBoundingClientRect();
  const below = window.innerHeight - rect.bottom - 24;
  const above = rect.top - 96;
  const useAbove = below < 460 && above > below;
  setPlacement({above: useAbove, space: Math.max(160, useAbove ? above : below)});
  const dismiss = event => {if (!control.current.contains(event.target)) setOpen(false);};
  document.addEventListener('pointerdown', dismiss);
  return () => document.removeEventListener('pointerdown', dismiss);
 }, [open]);
 return <div ref={control} className="download-control" onMouseEnter={() => {if (window.matchMedia('(hover: hover) and (min-width: 761px)').matches) setOpen(true);}} onMouseLeave={() => setOpen(false)} onBlur={e => {if (!e.currentTarget.contains(e.relatedTarget)) setOpen(false);}} onKeyDown={e => {if (e.key === 'Escape') {setOpen(false); e.currentTarget.querySelector('button').focus();}}}>
  <div className="download-button-group">
   <Link className="download-button" to="/downloads"><PlatformIcon name="download"/>{t('download')}</Link>
   <button className="download-toggle" type="button" aria-label={t('downloadOptions')} aria-expanded={open} aria-controls={menuId} onClick={() => setOpen(true)}><PlatformIcon name="chevron"/></button>
  </div>
  {open && <div className={`download-options${placement.above ? ' download-options-above' : ''}`} style={{'--download-menu-space': `${placement.space}px`}} id={menuId}>
   <div className="download-menu-surface">
    <div className="download-menu-heading"><span>{t('choosePlatform')}</span><button type="button" aria-label={t('closeDownloads')} onClick={() => setOpen(false)}><svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8" aria-hidden="true"><path d="m6 6 12 12M6 18 18 6"/></svg></button></div>
    {['macos', 'windows', 'ios', 'android', 'linux'].map(platform => <Link key={platform} to={`/downloads#${platform}`} onClick={() => setOpen(false)}><PlatformIcon name={platform}/><span><b>{t(`platform_${platform}`)}</b><small>{t(`downloadHint_${platform}`)}</small></span><PlatformIcon name="external" className="download-menu-trailing"/></Link>)}
    <Link className="download-menu-all" to="/downloads" onClick={() => setOpen(false)}>{t('allDownloads')}</Link>
   </div>
  </div>}
 </div>;
}
