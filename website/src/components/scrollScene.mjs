export const clamp = value => Math.max(0, Math.min(1, value));
export const segment = (progress, start, end) => clamp((progress-start)/(end-start));
// Ease the physical movement at each phase boundary without adding scroll lag.
const ease = value => value * value * (3 - 2 * value);
const easedSegment = (progress, start, end) => ease(segment(progress, start, end));
export function sceneAt(progress){
 const p=clamp(progress);
 return {
  shrink:easedSegment(p,0,.24), frame:segment(p,.24,.4),
  connect:easedSegment(p,.38,.54), reader:segment(p,.50,.60),
  insert:easedSegment(p,.60,.84),
  app:segment(p,.84,.94), signed:segment(p,.92,1),
  progress:p,
 };
}
// The white reader body spans y=44…977 in the 1536×1024 source image.
// Size the card against that insertion height, not the transparent PNG canvas.
export function cardGeometry(reader){
 const openingHeight=933*reader.width/1536;
 const height=openingHeight*.98;
 const width=height*1080/667;
 const slotX=reader.x+449*reader.width/1536;
 return {height,width,x:slotX-width+70*reader.width/400,
  y:reader.y+44*reader.width/1536+(openingHeight-height)/2,openingHeight};
}

export function desktopScreenFraction(state,viewport,reader,frame,screen){
 const readerBottom=reader.y+977*reader.width/1536;
 const visibleHeight=Math.max(250,viewport.height-200);
 const fitFraction=Math.min(.75,visibleHeight*screen.width/((readerBottom-frame.y)*viewport.width));
 return 1.4-.65*state.shrink+(fitFraction-.75)*state.connect;
}

// Begin every layout during entrance, after 10% of the enlarged screen
// is visible. Waiting for the section to reach the top compresses the zoom-out.
export function storyScrollProgress(bounds,viewport,screen){
 const openingHeight=viewport.width*1.4*screen.height/screen.width;
 const openingTop=Math.max(0,viewport.height*.95-openingHeight/2);
 const startTop=Math.max(0,viewport.height-openingTop-openingHeight*.1);
 return clamp((startTop-bounds.top)/Math.max(1,bounds.height-viewport.height+startTop));
}

// Keep the phone prominent; only short viewports constrain the 85vw target.
export function mobileSceneWidth(viewport,screen,frame={height:600}){
 const screenWidth=Math.min(viewport.width*.85,Math.max(240,viewport.height-76)*screen.width/frame.height);
 return screenWidth*650/screen.width;
}
export function mobileReaderGeometry(){
 return {x:295,y:420,width:200,height:200*1024/1536};
}
export function mobileSceneTop(viewport,frame,unit){
 const frameTop=Math.max(8,(viewport.height-64-frame.height*unit)/2);
 return frameTop-frame.y*unit;
}
export function readerConnectionOffset(state,mobile){
 return mobile?{x:0,y:0}:{x:(1-state.connect)*110,y:(1-state.connect)*45};
}
