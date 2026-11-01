import React,{useEffect,useRef,useState,useId} from 'react';
import useBaseUrl from '@docusaurus/useBaseUrl';
import useText from '../i18n/useText';
import StoryProgress from './StoryProgress';
import {iphone, androidPhone, desktop as desktopDisplay} from './deviceGeometry';
import {sceneAt,cardGeometry,clamp,desktopScreenFraction,mobileReaderGeometry,mobileSceneWidth,storyScrollProgress,mobileSceneTop,readerConnectionOffset} from './scrollScene.mjs';

export default function SigningStory(){
 const t=useText();const root=useRef(null);const clip=useId();
 const [progress,setProgress]=useState(0),[mobile,setMobile]=useState(false),[os,setOs]=useState('macos');
 const [viewport,setViewport]=useState({width:1440,height:960}),[reduced,setReduced]=useState(false);
 const assets={macos:useBaseUrl('/img/macos.png'),iphone:useBaseUrl('/img/iphone.png'),android:useBaseUrl('/img/android.png'),windows:useBaseUrl('/img/windows.png'),linux:useBaseUrl('/img/linux.png')};
 const disconnected={macos:useBaseUrl('/img/macos-disconnected.png'),windows:useBaseUrl('/img/windows-disconnected.png'),linux:useBaseUrl('/img/linux-disconnected.png'),android:useBaseUrl('/img/android-disconnected.png'),iphone:useBaseUrl('/img/iphone-disconnected.png')};
 const readerScreens={macos:useBaseUrl('/img/macos-reader.png'),iphone:useBaseUrl('/img/iphone-reader.png'),android:useBaseUrl('/img/android-reader.png'),windows:useBaseUrl('/img/windows-reader.png'),linux:useBaseUrl('/img/linux-reader.png')};
 const readerImage=useBaseUrl('/img/reader.png'),cardImage=useBaseUrl('/img/card.png');
 useEffect(()=>{
  const ua=navigator.userAgent;setOs(/Android/i.test(ua)?'android':/Windows/i.test(ua)?'windows':/Linux/i.test(ua)?'linux':'macos');
  const motion=window.matchMedia('(prefers-reduced-motion: reduce)');
  const mobileScreen=/Android/i.test(ua)?androidPhone.screen:iphone.screen;
  let raf=0;
  const readViewport=()=>({width:window.innerWidth,height:root.current?.firstElementChild?.getBoundingClientRect().height || window.innerHeight});
  const update=()=>{
   raf=0;const r=root.current?.getBoundingClientRect();if(!r)return;
   const viewport=readViewport();
   setProgress(storyScrollProgress(r,viewport,viewport.width<=760?mobileScreen:desktopDisplay.screen));
   document.documentElement.classList.toggle('story-active',!motion.matches && r.top<=1 && r.bottom>=viewport.height-1);
  };
  const resize=()=>{setMobile(window.innerWidth<=760);setViewport(readViewport());setReduced(motion.matches);update();};
  const scroll=()=>{if(!raf)raf=requestAnimationFrame(update);};
  const observer=new ResizeObserver(resize);
  if(root.current?.firstElementChild)observer.observe(root.current.firstElementChild);
  resize();window.addEventListener('scroll',scroll,{passive:true});window.addEventListener('resize',resize);window.visualViewport?.addEventListener('resize',resize);motion.addEventListener('change',resize);
  return()=>{cancelAnimationFrame(raf);observer.disconnect();document.documentElement.classList.remove('story-active');window.removeEventListener('scroll',scroll);window.removeEventListener('resize',resize);window.visualViewport?.removeEventListener('resize',resize);motion.removeEventListener('change',resize);};
 },[]);
 const state=sceneAt(reduced?1:progress);
 const step=progress<.24?0:progress<.4?1:progress<.84?2:3;
 const geometry=mobile?(os==='android'?androidPhone:iphone):desktopDisplay;
 const {frame,screen,port}=geometry;
 const platform=mobile?(os==='android'?'android':'iphone'):os;
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
    <image href={readerScreens[platform]} {...screen} opacity={state.reader} preserveAspectRatio={mobile?'xMidYMid meet':'xMidYMin slice'} clipPath={`url(#${clip})`}/>
    <image href={assets[platform]} {...screen} opacity={state.app} preserveAspectRatio={mobile?'xMidYMid meet':'xMidYMin slice'} clipPath={`url(#${clip})`}/>
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
     <rect width="285" height="77" rx="12" fill="white" stroke="#d3ded7"/><circle cx="32" cy="38" r="13" fill="#e2efe6"/><path d="M25 38 l5 5 10-12" fill="none" stroke="#307253" strokeWidth="3"/>
     <text x="57" y="32" fontSize="15" fill="#23392d">Contract-signed.pdf</text><text x="57" y="54" fontSize="12" fill="#567260">{t('ready')}</text>
    </g>
   </svg>
   <StoryProgress mobile={mobile} progress={state.progress} step={step} label={t('how')}
    labels={['document','device','reader','signature'].map(key=>t(key))}/>
  </div>
 </section>;
}
