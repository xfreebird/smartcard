export const clamp = value => Math.max(0, Math.min(1, value));
export const segment = (progress, start, end) => clamp((progress-start)/(end-start));
export function sceneAt(progress){
 const p=clamp(progress);
 return {
  shrink:segment(p,0,.24), frame:segment(p,.24,.4),
  connect:segment(p,.38,.6), insert:segment(p,.6,.82),
  app:segment(p,.82,.92), signed:segment(p,.9,1),
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
