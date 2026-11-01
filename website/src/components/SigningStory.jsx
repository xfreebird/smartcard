import React,{useEffect,useRef,useState,useId} from 'react';
import useBaseUrl from '@docusaurus/useBaseUrl';
import useText from '../i18n/useText';
import {iphone, androidPhone, desktop as desktopDisplay} from './deviceGeometry';
import {sceneAt,cardGeometry,clamp} from './scrollScene.mjs';

export default function SigningStory(){
 const t=useText();const root=useRef(null);const clip=useId();
 const [progress,setProgress]=useState(0),[mobile,setMobile]=useState(false),[os,setOs]=useState('macos');
 const [viewport,setViewport]=useState({width:1440,height:960}),[reduced,setReduced]=useState(false);
 const assets={macos:useBaseUrl('/img/macos.png'),iphone:useBaseUrl('/img/iphone.png'),android:useBaseUrl('/img/android.png'),windows:useBaseUrl('/img/windows.png'),linux:useBaseUrl('/img/linux.png')};
 const disconnected={macos:useBaseUrl('/img/macos-disconnected.png'),windows:useBaseUrl('/img/windows-disconnected.png'),linux:useBaseUrl('/img/linux-disconnected.png'),android:useBaseUrl('/img/android-disconnected.png'),iphone:useBaseUrl('/img/iphone-disconnected.png')};
 const readerImage=useBaseUrl('/img/reader.png'),cardImage=useBaseUrl('/img/card.png');
 useEffect(()=>{
  const ua=navigator.userAgent;setOs(/Android/i.test(ua)?'android':/Windows/i.test(ua)?'windows':/Linux/i.test(ua)?'linux':'macos');
  const motion=window.matchMedia('(prefers-reduced-motion: reduce)');
  const resize=()=>{setMobile(window.innerWidth<=760);setViewport({width:window.innerWidth,height:window.innerHeight});setReduced(motion.matches);};
  let raf=0;
  const update=()=>{raf=0;const r=root.current?.getBoundingClientRect();if(r)setProgress(clamp(-r.top/Math.max(1,r.height-window.innerHeight)));};
  const scroll=()=>{if(!raf)raf=requestAnimationFrame(update);};
  resize();update();window.addEventListener('scroll',scroll,{passive:true});window.addEventListener('resize',resize);motion.addEventListener('change',resize);
  return()=>{cancelAnimationFrame(raf);window.removeEventListener('scroll',scroll);window.removeEventListener('resize',resize);motion.removeEventListener('change',resize);};
 },[]);
 const state=sceneAt(reduced?1:progress);
 const step=progress<.24?0:progress<.4?1:progress<.82?2:3;
 const geometry=mobile?(os==='android'?androidPhone:iphone):desktopDisplay;
 const {frame,screen,port}=geometry;
 const platform=mobile?(os==='android'?'android':'iphone'):os;
 const reader=mobile?{x:200,y:650,width:380,height:253.333}:{x:600,y:520,width:330,height:220};
 const card=cardGeometry(reader);
 // The desktop screen starts at 100vw, reaches exactly 75vw at .24, then keeps
 // that width. Translate the scene up later to reveal the connected hardware.
 const screenFraction=1-.25*state.shrink;
 const svgWidth=mobile?Math.min(viewport.width,560):viewport.width*screenFraction*1100/screen.width;
 const unit=svgWidth/(mobile?650:1100);
 const screenCenter=screen.y+screen.height/2;
 const firstY=viewport.height*.62;
 const centerY=viewport.height*.5;
 const readerBottom=reader.y+977*reader.width/1536;
 const hardwareLift=Math.max(0,centerY+(readerBottom-screenCenter)*unit-(viewport.height-110));
 const sceneY=firstY+(centerY-firstY)*state.shrink-hardwareLift*state.connect;
 const left=mobile?(viewport.width/2-(frame.x+frame.width/2)*unit):(viewport.width/2-(screen.x+screen.width/2)*unit);
 const top=sceneY-screenCenter*unit;
 const titles=[1,2,3,4].map(i=>t(`stage${i}`));
 const copy=[1,2,3,4].map(i=>t(`stageBody${i}`));
 return <section className={`signing-story continuous-story ${reduced?'reduced-story':''}`} ref={root} aria-label={t('how')}>
  <div className="story-sticky continuous-sticky" data-progress={progress.toFixed(3)}>
   <div className="story-heading continuous-heading"><span className="stage-count">{t('step')} {step+1} {t('of')} 4</span><h2>{titles[step]}</h2><p>{copy[step]}</p></div>
   <svg className="continuous-scene" viewBox={mobile?'0 0 650 940':'0 0 1100 900'} style={{width:svgWidth,left,top}} role="img" aria-label={`${titles[step]} ${copy[step]}`}>
    <defs><clipPath id={clip}><rect {...screen}/></clipPath></defs>
    <g opacity={state.frame}>
     <rect {...frame} fill="#303533"/>
     {!mobile&&<><path d="M500 525 H600 L615 580 H485Z" fill="#bac0bd"/><rect x="450" y="576" width="200" height="10" rx="5" fill="#adb5b0"/></>}
    </g>
    <rect {...screen} fill="#e1e6e9"/>
    <image href={disconnected[platform]} {...screen} preserveAspectRatio={mobile?'xMidYMid meet':'xMidYMin slice'} clipPath={`url(#${clip})`}/>
    <image href={assets[platform]} {...screen} opacity={state.app} preserveAspectRatio={mobile?'xMidYMid meet':'xMidYMin slice'} clipPath={`url(#${clip})`}/>
    {mobile&&<rect opacity={state.frame} x={frame.x+frame.width/2-35} y={screen.y+8} width="70" height="17" rx="9" fill="#202523"/>}
    <g opacity={clamp(state.connect*4)}>
     <path className="connection-cable" pathLength="1" strokeDasharray="1" strokeDashoffset={1-state.connect} d={mobile?`M${port.x} ${port.y} V850 Q${port.x} 890 ${port.x+40} 890 H570 Q600 890 600 860 V804 Q600 774 570 774 H525`:'M980 480 H1010 Q1050 480 1050 520 V597 Q1050 627 1020 627 H882'}/>
     <rect x={port.x-(mobile?11:12)} y={port.y-11} width={mobile?22:25} height={mobile?35:22} rx="4" fill="#303533"/>
    </g>
    {/* Card is painted behind the reader; its chip disappears into the body. */}
    <image href={cardImage} x={card.x-(1-state.insert)*220} y={card.y} width={card.width} height={card.height} opacity={clamp(state.insert*5)} preserveAspectRatio="xMidYMid meet"/>
    <g opacity={clamp(state.connect*3)} transform={`translate(${(1-state.connect)*110} ${(1-state.connect)*45})`}>
     <image href={readerImage} {...reader}/>
     <rect x={mobile?519:875} y={mobile?763:616} width="23" height="23" rx="4" fill="#303533"/>
    </g>
    <g opacity={state.signed} transform={`translate(${mobile?35:190} ${660+(1-state.signed)*20})`}>
     <rect width="285" height="77" rx="12" fill="white" stroke="#d3ded7"/><circle cx="32" cy="38" r="13" fill="#e2efe6"/><path d="M25 38 l5 5 10-12" fill="none" stroke="#307253" strokeWidth="3"/>
     <text x="57" y="32" fontSize="15" fill="#23392d">Contract-signed.pdf</text><text x="57" y="54" fontSize="12" fill="#567260">{t('ready')}</text>
    </g>
   </svg>
   <div className="story-steps continuous-progress" aria-label={t('how')}>
    <div className="scroll-progress-track" aria-hidden="true"><div style={{transform:`scaleX(${state.progress})`}}/></div>
    {['document','device','reader','signature'].map(key=>t(key)).map((label,i)=><span key={label} aria-current={step===i?'step':undefined} className={`${step===i?'current':''} ${i<step?'complete':''}`}><b>{i+1}</b>{label}</span>)}
   </div>
  </div>
 </section>;
}
