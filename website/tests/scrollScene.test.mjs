import {test} from 'node:test';
import assert from 'node:assert/strict';
import {sceneAt,cardGeometry} from '../src/components/scrollScene.mjs';
test('scroll timeline continuously moves and reveals the card only after insertion',()=>{
 const keys=['shrink','frame','connect','insert','app','signed'];
 for(let p=0;p<.999;p+=.001){
  const a=sceneAt(p),b=sceneAt(p+.001);
  assert.ok(keys.some(k=>Math.abs(a[k]-b[k])>0),`Idle interval at ${p}`);
  assert.ok(keys.every(k=>Math.abs(a[k]-b[k])<.02),`Jump at ${p}`);
 }
 assert.equal(1-.25*sceneAt(0).shrink,1);
 assert.equal(1-.25*sceneAt(.24).shrink,.75);
 assert.equal(sceneAt(.82).insert,1);
 assert.equal(sceneAt(.82).app,0);
 assert.equal(sceneAt(.92).app,1);
});
test('physical ID is 98% of the reader insertion height and retains its aspect ratio',()=>{
 for(const reader of [{x:600,y:520,width:330},{x:200,y:650,width:380}]){
  const card=cardGeometry(reader);
  assert.ok(Math.abs(card.height/card.openingHeight-.98)<1e-9);
  assert.ok(Math.abs(card.width/card.height-1080/667)<1e-9);
 }
});
