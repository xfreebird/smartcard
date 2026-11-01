import {test} from 'node:test';
import assert from 'node:assert/strict';
import {sceneAt,cardGeometry,mobileReaderShift} from '../src/components/scrollScene.mjs';
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
 assert.equal(mobileReaderShift(sceneAt(.64)),100);
 for(let p=.64;p<=1;p+=.01){
  const state=sceneAt(p),reader={x:200+mobileReaderShift(state),y:650,width:380};
  const card=cardGeometry(reader);
  const x=card.x-(1-state.insert)*90;
  assert.ok(x>=0);
  assert.ok(x+card.width<=650);
 }
});
