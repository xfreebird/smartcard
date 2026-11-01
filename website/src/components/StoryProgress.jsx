import React from 'react';
import {segment} from './scrollScene.mjs';

const ranges=[[0,.24],[.24,.4],[.4,.84],[.84,1]];
const icons=[
 'M7 3h7l4 4v14H7z M14 3v5h4 M10 12h5 M10 16h5',
 'M5 4h14v12H5z M9 20h6 M12 16v4',
 'M4 6h16v12H4z M4 10h16 M8 14h2',
 'M5 12l4 4L19 6',
];

export default function StoryProgress({progress,step,labels,label,mobile=false}){
 return <div className="story-progress" role="progressbar" aria-label={label}
  aria-valuemin={0} aria-valuemax={100} aria-valuenow={Math.round(progress*100)}
  aria-valuetext={`${step+1}/4 ${labels[step]}`}>
  <svg className="story-progress-icon" viewBox="0 0 24 24" aria-hidden="true"><path d={mobile&&step===1?'M8 2h8v20H8z M11 18h2':icons[step]}/></svg>
  <span className="story-progress-label">{labels[step]}</span>
  <div className="story-progress-segments" aria-hidden="true">
   {ranges.map(([start,end],index)=><span key={index}><i style={{transform:`scaleX(${segment(progress,start,end)})`}}/></span>)}
  </div>
 </div>;
}
