import React,{useEffect,useState} from 'react';
import screenshots from '../data/screenshotRevision.json';

const desktopScreens=['disconnected','reader','ready'];
const mobileScreens=[...desktopScreens,'nfc','card'];

// Change native app states atomically. Blending whole captures doubles text,
// window edges and translucent chrome even when their canvases are identical.
export default function StoryScreen({root,platform,appearance,stage,screen,clip}){
 const prefix=`${root}${platform}/`;
 const screenNames=['iphone','android'].includes(platform)?mobileScreens:desktopScreens;
 const imagePath=state=>`${prefix}${state}-${appearance}.png?v=${screenshots.revision}`;
 const identity=`${prefix}${appearance}`;
 const [decoded,setDecoded]=useState({identity:null,stages:[]});
 useEffect(()=>{
  let active=true;
  const images=screenNames.map(state=>{
   const image=new Image();image.src=imagePath(state);
   return image.decode();
  });
  Promise.allSettled(images).then(results=>{
   if(active)setDecoded({identity,stages:results.map(result=>result.status==='fulfilled')});
  }).catch(()=>{if(active)setDecoded({identity,stages:[]});});
  return()=>{active=false;};
 },[identity,screenNames]);
 // Keep the last available earlier state if a later capture could not load.
 let selected=screenNames.indexOf(stage);
 if(selected>=3 && (decoded.identity!==identity || !decoded.stages[selected]))selected=stage==='nfc'?0:2;
 while(selected>0 && (decoded.identity!==identity || !decoded.stages[selected]))selected--;
 return <g clipPath={`url(#${clip})`} data-screen-stage={selected}>
  <rect {...screen} fill={appearance==='dark'?'#202124':'#f5f5f7'}/>
  <image href={imagePath(screenNames[selected])} {...screen} preserveAspectRatio="xMidYMid meet"/>
 </g>;
}
