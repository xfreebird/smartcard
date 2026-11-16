import React from 'react';
import {segment} from './scrollScene.mjs';

const icons={
 document:'M7 3h7l4 4v14H7z M14 3v5h4 M10 12h5 M10 16h5',
 device:'M5 4h14v12H5z M9 20h6 M12 16v4',
 nfc:'M6 9a4 4 0 0 1 0 6 M10 6a8 8 0 0 1 0 12 M14 3a12 12 0 0 1 0 18',
 reader:'M4 6h16v12H4z M4 10h16 M8 14h2',
 card:'M4 5h16v14H4z M8 10h3v4H8z M14 10h3 M14 14h3',
 signature:'M5 12l4 4L19 6',
};

export default function StoryProgress({progress,step,stages,t,label,boundaries}){
 const current=stages[step];
 return <div className="story-progress" role="progressbar" aria-label={label}
  aria-valuemin={0} aria-valuemax={100} aria-valuenow={Math.round(progress*100)}
  aria-valuetext={`${step+1}/${stages.length} ${t(current)}`}>
  <svg className="story-progress-icon" viewBox="0 0 24 24" aria-hidden="true"><path d={icons[current]}/></svg>
  <span className="story-progress-label">{t(current)}</span>
  <div className="story-progress-segments" aria-hidden="true">
   {boundaries.slice(0,-1).map((start,index)=><span key={start}><i style={{transform:`scaleX(${segment(progress,start,boundaries[index+1])})`}}/></span>)}
  </div>
 </div>;
}
