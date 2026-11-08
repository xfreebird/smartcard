import React,{useEffect,useState} from 'react';

// Change native app states atomically. Blending whole captures doubles text,
// window edges and translucent chrome even when their canvases are identical.
export default function StoryScreen({root,platform,appearance,stage,screen,clip}){
 const prefix=`${root}${platform}/`;
 const sources=['disconnected','reader','ready'].map(state=>`${prefix}${state}-${appearance}.png`);
 const identity=`${prefix}${appearance}`;
 const [decoded,setDecoded]=useState({identity:null,stages:[]});
 useEffect(()=>{
  let active=true;
  const images=['disconnected','reader','ready'].map(state=>{
   const image=new Image();image.src=`${prefix}${state}-${appearance}.png`;
   return image.decode();
  });
  Promise.allSettled(images).then(results=>{
   if(active)setDecoded({identity,stages:results.map(result=>result.status==='fulfilled')});
  });
  return()=>{active=false;};
 },[identity,prefix,appearance]);
 // Keep the last available earlier state if a later capture could not load.
 let selected=stage;
 while(selected>0 && (decoded.identity!==identity || !decoded.stages[selected]))selected--;
 return <g clipPath={`url(#${clip})`} data-screen-stage={selected}>
  <rect {...screen} fill={appearance==='dark'?'#202124':'#f5f5f7'}/>
  <image href={sources[selected]} {...screen} preserveAspectRatio="xMidYMid meet"/>
 </g>;
}
