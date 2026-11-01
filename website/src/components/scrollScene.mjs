export const clamp = value => Math.max(0, Math.min(1, value));
export const segment = (progress, start, end) => clamp((progress-start)/(end-start));
export function sceneAt(progress){
 const p=clamp(progress);
 return {
  shrink:segment(p,0,.24), frame:segment(p,.24,.4),
  connect:segment(p,.38,.54), reader:segment(p,.50,.56),
  spread:segment(p,.54,.64), insert:segment(p,.64,.84),
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

// Shift the reader before the card enters, keeping the complete approaching ID
// inside the phone scene. The cable endpoint follows the reader connector.
export function mobileReaderShift(state){return 60*state.spread;}

// Begin the mobile timeline during entrance, after 10% of the enlarged screen
// is visible. Waiting for the section to reach the top compresses the zoom-out.
export function mobileStoryProgress(bounds,viewport,screen){
 const openingHeight=viewport.width*1.4*screen.height/screen.width;
 const openingTop=Math.max(0,viewport.height*.95-openingHeight/2);
 const startTop=Math.max(0,viewport.height-openingTop-openingHeight*.1);
 return clamp((startTop-bounds.top)/Math.max(1,bounds.height-viewport.height+startTop));
}

// Keep the phone prominent; only short viewports constrain the 85vw target.
export function mobileSceneWidth(viewport,screen){
 const screenWidth=Math.min(viewport.width*.85,Math.max(300,viewport.height-100)*screen.width/screen.height);
 return screenWidth*650/screen.width;
}
export function mobileReaderGeometry(state){
 return {x:235+mobileReaderShift(state),y:420,width:200,height:200*1024/1536};
}
