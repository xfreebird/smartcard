import React, {useState, useId} from 'react';
import useText from '../i18n/useText';
const release = 'https://github.com/xfreebird/smartcard/releases/latest';
export default function Downloads() {
 const t=useText();
 const [open,setOpen]=useState(false); const menuId=useId();
 return <div className="download-control" onMouseEnter={()=>setOpen(true)} onMouseLeave={()=>setOpen(false)} onBlur={e=>{if(!e.currentTarget.contains(e.relatedTarget))setOpen(false)}} onKeyDown={e=>{if(e.key==='Escape')setOpen(false)}}>
  <button className="download-button" aria-expanded={open} aria-controls={menuId} onClick={()=>setOpen(true)}>{t('download')}</button>
  {open && <div className="download-options" id={menuId}>
   <a href={release}><b>GitHub Releases</b><small>macOS · Windows · Android · Linux</small></a>
   <a href="https://apps.apple.com/app/id6829451042"><b>Mac App Store</b><small>{t('review')}</small></a>
   <a href="https://apps.apple.com/app/id6826865290"><b>App Store · iPhone & iPad</b><small>{t('review')}</small></a>
   <a href="https://play.google.com/store/apps/details?id=md.esemnbun.app"><b>Google Play</b><small>{t('testing')}</small></a>
   <a href="https://apps.microsoft.com/detail/9PDPR6RNT42S"><b>Microsoft Store</b><small>{t('certification')}</small></a>
  </div>}
 </div>;
}
