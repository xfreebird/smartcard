import React,{useEffect,useRef,useState,useId} from 'react';
import useBaseUrl from '@docusaurus/useBaseUrl';
import {useColorMode} from '@docusaurus/theme-common';
import useText from '../i18n/useText';
import StoryProgress from './StoryProgress';
import StoryScreen from './StoryScreen';
import PlatformPreview from './PlatformPreview';
import {debugPreviewEnabled,previewChoice,storyPlatform} from './previewPlatformState.mjs';
import {iphone, androidPhone, desktop as desktopDisplay} from './deviceGeometry';
import {sceneAt,mobileSceneAt,desktopStoryStages,mobileStoryStages,cardGeometry,clamp,desktopScreenFraction,mobileReaderGeometry,mobileSceneWidth,storyScrollProgress,mobileSceneTop,readerConnectionOffset} from './scrollScene.mjs';

const desktopStages=['document','device','reader','signature'];
const mobileStages=['document','nfc','reader','card','signature'];
const mobileScreens=['disconnected','nfc','reader','card','ready'];

export default function SigningStory(){
 const t=useText();const root=useRef(null);const clip=useId();
 const {colorMode}=useColorMode();
 const [progress,setProgress]=useState(0),[platform,setPlatform]=useState('macos');
 const [debug,setDebug]=useState(false),[preview,setPreview]=useState('auto');
 const mobile=platform==='iphone' || platform==='android';
 const [viewport,setViewport]=useState({width:1440,height:960}),[reduced,setReduced]=useState(false);
 const landingRoot=useBaseUrl('/img/landing/');
 const appearance=colorMode==='dark'?'dark':'light';
 const readerImage=useBaseUrl('/img/reader.png'),cardImage=useBaseUrl('/img/card.png');
 useEffect(()=>{
  const enabled=debugPreviewEnabled(window.location.hostname,process.env.NODE_ENV==='development');
  setDebug(enabled);
  if(enabled){try{setPreview(previewChoice(sessionStorage.getItem('esemnbun.previewPlatform')));}catch{ /* Preview still works without storage. */ }}
 },[]);
 const changePreview=value=>{
  const choice=previewChoice(value);setPreview(choice);
  try{sessionStorage.setItem('esemnbun.previewPlatform',choice);}catch{ /* Optional per-tab persistence. */ }
 };
 useEffect(()=>{
  const ua=navigator.userAgent;
  const motion=window.matchMedia('(prefers-reduced-motion: reduce)');
  const selectedPlatform=()=>storyPlatform(debug?preview:'auto',ua,window.innerWidth);
  const selectedScreen=()=>selectedPlatform()==='android'?androidPhone.screen:selectedPlatform()==='iphone'?iphone.screen:desktopDisplay.screen;
  let raf=0, previousTime=0, displayed=0, target=0;
  const readViewport=()=>({width:window.innerWidth,height:root.current?.firstElementChild?.getBoundingClientRect().height || window.innerHeight});
  let measuredViewport=readViewport();
  const measure=()=>{
   const r=root.current?.getBoundingClientRect();if(!r)return;
   target=storyScrollProgress(r,measuredViewport,selectedScreen());
   document.documentElement.classList.toggle('story-active',!motion.matches && r.top<=1 && r.bottom>=measuredViewport.height-1);
  };
  const animate=time=>{
   raf=0;
   const elapsed=previousTime?Math.min(time-previousTime,64):16;previousTime=time;
   // Time-based easing stays consistent on 60 Hz and 120 Hz displays.
   displayed=motion.matches?target:displayed+(target-displayed)*(1-Math.exp(-elapsed/65));
   if(Math.abs(target-displayed)<0.0001)displayed=target;
   setProgress(displayed);
   if(displayed!==target)raf=requestAnimationFrame(animate);else previousTime=0;
  };
  const scroll=()=>{measure();if(!raf)raf=requestAnimationFrame(animate);};
  const resize=()=>{
   measuredViewport=readViewport();setPlatform(selectedPlatform());setViewport(measuredViewport);setReduced(motion.matches);
   measure();cancelAnimationFrame(raf);raf=0;previousTime=0;displayed=target;setProgress(displayed);
  };
  const observer=new ResizeObserver(resize);
  if(root.current?.firstElementChild)observer.observe(root.current.firstElementChild);
  resize();window.addEventListener('scroll',scroll,{passive:true});window.addEventListener('resize',resize);window.visualViewport?.addEventListener('resize',resize);motion.addEventListener('change',resize);
  return()=>{cancelAnimationFrame(raf);observer.disconnect();document.documentElement.classList.remove('story-active');window.removeEventListener('scroll',scroll);window.removeEventListener('resize',resize);window.visualViewport?.removeEventListener('resize',resize);motion.removeEventListener('change',resize);};
 },[debug,preview]);
 const p=reduced?1:progress;
 const boundaries=mobile?mobileStoryStages:desktopStoryStages;
 const stages=mobile?mobileStages:desktopStages;
 const state=mobile?mobileSceneAt(p):sceneAt(p);
 const step=boundaries.slice(0,-1).filter(start=>p>=start).length-1;
 const geometry=mobile?(platform==='android'?androidPhone:iphone):desktopDisplay;
 const {frame,screen,port}=geometry;
 const reader=mobile?mobileReaderGeometry(state):{x:600,y:520,width:330,height:220};
 const cableX=mobile?reader.x+325*reader.width/380:882;
 const cableY=mobile?reader.y+124*reader.width/380:627;
 const card=cardGeometry(reader);
 const readerOffset=readerConnectionOffset(state,mobile);
 // The desktop screen reaches 75vw at .24, then shrinks further during
 // connection so the complete rig remains visible.
 const screenFraction=desktopScreenFraction(state,viewport,reader,frame,screen);
 const mobileStart=viewport.width*1.4*650/screen.width;
 const mobileEnd=mobileSceneWidth(viewport,screen,frame);
 const svgWidth=mobile?mobileStart+(mobileEnd-mobileStart)*state.shrink:viewport.width*screenFraction*1100/screen.width;
 const unit=svgWidth/(mobile?650:1100);
 const screenCenter=screen.y+screen.height/2;
 const firstY=viewport.height*.95;
 const centerY=mobile?mobileSceneTop(viewport,frame,unit)+screenCenter*unit:viewport.height*.5;
 const readerBottom=reader.y+977*reader.width/1536;
 const hardwareLift=mobile?0:Math.max(0,centerY+(readerBottom-screenCenter)*unit-(viewport.height-110));
 const sceneY=firstY+(centerY-firstY)*state.shrink-hardwareLift*state.connect;
 const left=mobile?(viewport.width/2-(frame.x+frame.width/2)*unit):(viewport.width/2-(screen.x+screen.width/2)*unit);
 const top=sceneY-screenCenter*unit;
 const chapter=(mobile?['1','Nfc','Reader','Card','4']:['1','2','3','4'])[step];
 const title=t(`stage${chapter}`);
 const copy=t(`stageBody${chapter}`);
 const screenStage=mobile?mobileScreens[step]:state.app>=.5?'ready':state.reader>=.5?'reader':'disconnected';
 return <>{debug && <PlatformPreview value={preview} onChange={changePreview}/>}
 <section className={`signing-story continuous-story ${reduced?'reduced-story':''}`} ref={root} aria-label={t('how')} data-platform={platform}>
  <div className="story-sticky continuous-sticky" data-progress={progress.toFixed(3)}>
   <div className="story-heading continuous-heading"><span className="stage-count">{t('step')} {step+1} {t('of')} {stages.length}</span><h2>{title}</h2><p>{copy}</p></div>
   <svg className="continuous-scene" viewBox={mobile?'0 0 650 940':'0 0 1100 900'} style={{width:svgWidth,transform:`translate3d(${left}px, ${top}px, 0)`}} role="img" aria-label={`${title} ${copy}`}>
    <defs><clipPath id={clip}><rect {...screen}/></clipPath></defs>
    <g opacity={state.frame}>
     <rect {...frame} fill="#303533" stroke="var(--site-hardware-border)" strokeWidth="1"/>
     {!mobile&&<><path d="M500 525 H600 L615 580 H485Z" fill="#bac0bd"/><rect x="450" y="576" width="200" height="10" rx="5" fill="#adb5b0"/></>}
    </g>
    <StoryScreen root={landingRoot} platform={platform} appearance={appearance} stage={screenStage} screen={screen} clip={clip}/>
    {mobile&&<rect opacity={state.frame} x={frame.x+frame.width/2-35} y={screen.y+8} width="70" height="17" rx="9" fill="#202523"/>}
    <g opacity={clamp(state.connect*4)}>
     <path className="connection-cable" style={{strokeWidth:mobile?6:10}} pathLength="1" strokeDasharray="1" strokeDashoffset={1-state.connect} d={mobile?`M${port.x} ${port.y} V635 Q${port.x} 646 ${port.x+20} 646 H445 Q467 646 467 624 V${cableY+14} Q467 ${cableY} ${cableX} ${cableY}`:'M980 480 H1010 Q1050 480 1050 520 V597 Q1050 627 1020 627 H882'}/>
     <rect x={port.x-(mobile?11:12)} y={port.y-11} width={mobile?22:25} height={mobile?35:22} rx="4" fill="#303533"/>
    </g>
    {/* Card is painted behind the reader; its chip disappears into the body. */}
    <image href={cardImage} x={card.x-(1-state.insert)*(mobile?25:220)} y={card.y} width={card.width} height={card.height} opacity={clamp(state.insert*5)} preserveAspectRatio="xMidYMid meet"/>
    <g opacity={clamp(state.connect*3)} transform={`translate(${readerOffset.x} ${readerOffset.y})`}>
     <image href={readerImage} {...reader}/>
     <rect x={mobile?reader.x+319*reader.width/380:875} y={mobile?reader.y+113*reader.width/380:616} width={mobile?12:23} height={mobile?12:23} rx="4" fill="#303533"/>
    </g>
    <g opacity={state.signed} transform={`translate(${mobile?175:190} ${(mobile?550:660)+(1-state.signed)*20})`}>
     <rect width="285" height="77" rx="12" fill="var(--site-surface)" stroke="var(--site-border)"/><circle cx="32" cy="38" r="13" fill="var(--site-success-bg)"/><path d="M25 38 l5 5 10-12" fill="none" stroke="var(--site-success)" strokeWidth="3"/>
     <text x="57" y="32" fontSize="15" fill="var(--ifm-font-color-base)">Contract-signed.pdf</text><text x="57" y="54" fontSize="12" fill="var(--site-muted)">{t('ready')}</text>
    </g>
   </svg>
   <StoryProgress progress={state.progress} step={step} label={t('how')} stages={stages} boundaries={boundaries} t={t}/>
  </div>
 </section></>;
}
