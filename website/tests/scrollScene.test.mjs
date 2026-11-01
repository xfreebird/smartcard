import {test} from 'node:test';
import assert from 'node:assert/strict';
import {sceneAt,cardGeometry,mobileReaderShift,mobileStoryProgress,mobileReaderGeometry,mobileSceneWidth} from '../src/components/scrollScene.mjs';
test('scroll timeline continuously moves and reveals the card only after insertion',()=>{
 const keys=['shrink','frame','connect','reader','spread','insert','app','signed'];
 for(let p=0;p<.999;p+=.001){
  const a=sceneAt(p),b=sceneAt(p+.001);
  assert.ok(keys.some(k=>Math.abs(a[k]-b[k])>0),`Idle interval at ${p}`);
  assert.ok(keys.every(k=>Math.abs(a[k]-b[k])<.02),`Jump at ${p}`);
 }
 assert.equal(sceneAt(.54).connect,1);
 assert.equal(sceneAt(.60).reader,1);
 assert.equal(sceneAt(.60).insert,0);
 assert.equal(sceneAt(.84).insert,1);
 assert.equal(sceneAt(.84).app,0);
 assert.equal(sceneAt(.94).app,1);
});
test('physical ID is 98% of the reader insertion height and retains its aspect ratio',()=>{
 for(const reader of [{x:600,y:520,width:330},{x:200,y:650,width:380}]){
  const card=cardGeometry(reader);
  assert.ok(Math.abs(card.height/card.openingHeight-.98)<1e-9);
  assert.ok(Math.abs(card.width/card.height-1080/667)<1e-9);
 }
});

test('connected desktop rig fits the available vertical space',async()=>{
 const {desktopScreenFraction}=await import('../src/components/scrollScene.mjs');
 const reader={x:600,y:520,width:330},frame={y:25},screen={width:840};
 for(const viewport of [{width:1440,height:900},{width:1920,height:800},{width:1024,height:768}]){
  assert.equal(desktopScreenFraction(sceneAt(0),viewport,reader,frame,screen),1.4);
  assert.ok(Math.abs(desktopScreenFraction(sceneAt(.24),viewport,reader,frame,screen)-.75)<1e-9);
  const fraction=desktopScreenFraction(sceneAt(1),viewport,reader,frame,screen);
  const unit=viewport.width*fraction/screen.width;
  const height=(reader.y+977*reader.width/1536-frame.y)*unit;
  assert.ok(height<=viewport.height-200+.001);
 }
});

test('mobile reader moves aside before insertion and keeps the approaching ID visible',()=>{
 assert.equal(mobileReaderShift(sceneAt(.54)),0);
 assert.equal(mobileReaderShift(sceneAt(.64)),60);
 for(let p=.64;p<=1;p+=.01){
  const state=sceneAt(p),reader=mobileReaderGeometry(state);
  const card=cardGeometry(reader);
  const x=card.x-(1-state.insert)*25;
  assert.ok(x>=0);
  assert.ok(x+card.width<=650);
 }
});

test('mobile zoom starts during entrance after ten percent is visible',()=>{
 for(const viewport of [{width:320,height:568},{width:390,height:844},{width:430,height:932}]){
  for(const screen of [{width:264,height:573.6},{width:264,height:586.6667}]){
   const openingHeight=viewport.width*1.4*screen.height/screen.width;
   const imageTop=viewport.height*.95-openingHeight/2;
   const bounds={height:viewport.height*2.3,top:viewport.height-imageTop-openingHeight*.1};
   assert.ok(Math.abs(mobileStoryProgress(bounds,viewport,screen))<1e-9);
   assert.equal(mobileStoryProgress({...bounds,top:bounds.top+1},viewport,screen),0);
   const entering=mobileStoryProgress({...bounds,top:bounds.top-20},viewport,screen);
   assert.ok(entering>0 && sceneAt(entering).shrink>0);
   assert.ok(sceneAt(mobileStoryProgress({...bounds,top:0},viewport,screen)).shrink>.9);
   assert.equal(mobileStoryProgress({...bounds,top:viewport.height-bounds.height},viewport,screen),1);
  }
 }
});

test('final portrait phone screen is 85vw with the ID and reader over its lower part',()=>{
 const screen={x:185,y:43.2,width:264,height:573.6};
 const viewport={width:390,height:844},unit=mobileSceneWidth(viewport,screen)/650;
 assert.ok(Math.abs(screen.width*unit/viewport.width-.85)<1e-9);
 for(let p=.64;p<=1;p+=.01){
  const state=sceneAt(p),reader=mobileReaderGeometry(state),card=cardGeometry(reader);
  const left=viewport.width/2-317*unit;
  const cardLeft=left+(card.x-(1-state.insert)*25)*unit;
  assert.ok(cardLeft>=10);
  assert.ok(cardLeft+card.width*unit<=viewport.width-10);
  assert.ok(reader.y>screen.y+screen.height*.6);
  assert.ok(reader.y+reader.height<630);
 }
});
