import React,{useEffect,useRef,useState} from 'react';
import useBaseUrl from '@docusaurus/useBaseUrl';
import {iphone, androidPhone, desktop as desktopDisplay} from './deviceGeometry';
export default function SigningStory(){
 const root=useRef(null); const [step,setStep]=useState(0); const [mobile,setMobile]=useState(false); const [os,setOs]=useState('macos');
 const desktop=useBaseUrl('/img/macos.png'),phone=useBaseUrl('/img/iphone.png'),reader=useBaseUrl('/img/reader.png'); const android=useBaseUrl('/img/android.png'),windows=useBaseUrl('/img/windows.png'),linux=useBaseUrl('/img/linux.png'),card=useBaseUrl('/img/card.png');
 useEffect(()=>{
  const ua=navigator.userAgent; setOs(/Android/i.test(ua)?'android':/Windows/i.test(ua)?'windows':/Linux/i.test(ua)?'linux':'macos');
  const query=window.matchMedia('(max-width: 760px)');const choose=()=>setMobile(query.matches);choose();query.addEventListener('change',choose);
  let ticking=false;const update=()=>{const r=root.current?.getBoundingClientRect();if(r){const p=Math.max(0,Math.min(.999,-r.top/(r.height-window.innerHeight)));setStep(Math.floor(p*4));}ticking=false;};
  const scroll=()=>{if(!ticking){ticking=true;requestAnimationFrame(update);}};update();window.addEventListener('scroll',scroll,{passive:true});window.addEventListener('resize',scroll);
  return()=>{query.removeEventListener('change',choose);window.removeEventListener('scroll',scroll);window.removeEventListener('resize',scroll);};
 },[]);
 const titles=['Choose the document.','Use the app on your device.','Connect the reader and card.','Approve. Sign. Save.'];
 const copy=['Add your document. Card details stay hidden until a card is connected.','Native desktop and mobile apps, with the same straightforward workflow.','The reader connects through USB, with an adapter when needed.','Review the request and enter your PIN. Save or share the signed result.'];
 const disconnected={macos:useBaseUrl('/img/macos-disconnected.png'),windows:useBaseUrl('/img/windows-disconnected.png'),linux:useBaseUrl('/img/linux-disconnected.png'),android:useBaseUrl('/img/android-disconnected.png'),iphone:useBaseUrl('/img/iphone-disconnected.png')};
 const connectedScreenshot=mobile?(os==='android'?android:phone):(os==='windows'?windows:os==='linux'?linux:desktop);
 const screenshot=step<2?disconnected[mobile?(os==='android'?'android':'iphone'):os]:connectedScreenshot;
 const device=mobile?'phone':'desktop';
 const geometry=mobile?(os==='android'?androidPhone:iphone):desktopDisplay;
 const {frame,screen,port}=geometry;
 return <section className="signing-story" ref={root} aria-label="How signing works">
  <div className={`story-sticky step-${step}`}>
   <div className="story-heading"><span className="stage-count">Step {step+1} of 4</span><h2>{titles[step]}</h2><p>{copy[step]}</p></div>
   <svg className={`connection-scene ${device}`} viewBox={mobile?'0 0 650 940':'0 0 1100 900'} role="img" aria-label={`${titles[step]} ${copy[step]}`}>
    <defs><clipPath id="screen"><rect {...screen}/></clipPath></defs>
    <g className="hardware-frame">
     <rect {...frame} fill="#303533"/>
     {!mobile && <><path d="M500 525 H600 L615 580 H485Z" fill="#bac0bd"/><rect x="450" y="576" width="200" height="10" rx="5" fill="#adb5b0"/></>}
    </g>
    <rect {...screen} fill="#e1e6e9"/><image href={screenshot} x={screen.x} y={screen.y} width={screen.width} height={screen.height} preserveAspectRatio="xMidYMid meet" clipPath="url(#screen)"/>
    {mobile && <rect className="hardware-frame" x={frame.x+frame.width/2-35} y={screen.y+8} width="70" height="17" rx="9" fill="#202523"/>}
    <g className="connected-hardware">
     <path className="connection-cable" d={mobile?`M${port.x} ${port.y} V850 Q${port.x} 890 ${port.x+40} 890 H570 Q600 890 600 860 V804 Q600 774 570 774 H525`:'M980 480 H1010 Q1050 480 1050 520 V710 Q1050 740 1020 740 H942'}/>
     <rect x={port.x-(mobile?11:12)} y={port.y-11} width={mobile?22:25} height={mobile?35:22} rx="4" fill="#303533"/>
     <image href={card} x={mobile?225:635} y={mobile?701:673} width="150" height="93" preserveAspectRatio="xMidYMid meet"/>
     <image href={reader} x={mobile?200:600} y={mobile?650:610} width={mobile?380:400} height={mobile?253:267}/>
     <rect x={mobile?519:935} y={mobile?763:729} width="23" height="23" rx="4" fill="#303533"/>
    </g>
    <g className="signed-result" transform={mobile?'translate(35 646)':'translate(190 660)'}>
     <rect width="285" height="77" rx="12" fill="white" stroke="#d3ded7"/>
     <circle cx="32" cy="38" r="13" fill="#e2efe6"/><path d="M25 38 l5 5 10-12" fill="none" stroke="#307253" strokeWidth="3"/>
     <text x="57" y="32" fontSize="15" fill="#23392d">Contract-signed.pdf</text><text x="57" y="54" fontSize="12" fill="#567260">Ready to save or share</text>
    </g>
   </svg>
   <div className="story-steps" aria-label="Signing stages">{['Document','Device','Reader','Signature'].map((t,i)=><span key={t} aria-current={step===i?'step':undefined} className={`${step===i?'current':''} ${i<step?'complete':''}`}><b>{i+1}</b>{t}</span>)}</div>
  </div>
 </section>;
}
