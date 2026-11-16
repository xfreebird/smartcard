import {test} from 'node:test';
import assert from 'node:assert/strict';
import {readFileSync} from 'node:fs';
import {createHash} from 'node:crypto';
const assets=new URL('../static/img/',import.meta.url);
test('macOS story captures preserve native window title, size and content setup',()=>{
 const manifest=JSON.parse(readFileSync(new URL('macos-story.json',assets),'utf8'));
 assert.equal(manifest.theme,'light');
 assert.equal(manifest.document,'Sample-contract.pdf');
 assert.equal(manifest.states.length,3);
 assert.equal(new Set(manifest.states.map(state=>state.title)).size,1);
 assert.ok(manifest.states.every(state=>!state.title.toLowerCase().includes('preview')));
 assert.equal(new Set(manifest.states.map(state=>state.dimensions.join('x'))).size,1);
 for(const state of manifest.states){
  const bytes=readFileSync(new URL(state.file,assets));
  assert.equal(bytes.subarray(1,4).toString(),'PNG');
  assert.deepEqual([bytes.readUInt32BE(16),bytes.readUInt32BE(20)],state.dimensions);
  assert.equal(createHash('sha256').update(bytes).digest('hex'),state.sha256);
 }
});

test('published scenes, normalized clocks and window crops match the reviewed images',()=>{
 for(const [name,key] of [['screenshot-refresh.json',null],['screenshot-clocks.json','images'],['screenshot-window-crops.json','images']]){
  const manifest=JSON.parse(readFileSync(new URL(name,assets),'utf8'));
  const rows=key?manifest[key]:manifest;
  assert.ok(rows.length>0);
  for(const row of rows){
   const path=(row.target || row.path).replace('website/static/img/','');
   const bytes=readFileSync(new URL(path,assets));
   assert.equal(createHash('sha256').update(bytes).digest('hex'),row.sha256,`${path}: review the refreshed asset and update its manifest`);
   assert.deepEqual([bytes.readUInt32BE(16),bytes.readUInt32BE(20)],row.dimensions,path);
  }
 }
});

test('each platform has distinct refreshed states in both appearances',()=>{
 const rows=JSON.parse(readFileSync(new URL('screenshot-refresh.json',assets),'utf8'));
 assert.equal(rows.length,38);
 for(const platform of ['macos','windows','linux','iphone','android']){
  const captures=rows.filter(row=>row.platform===platform);
  const mobile=['iphone','android'].includes(platform);
  assert.equal(captures.length,mobile?10:6);
  assert.equal(new Set(captures.map(row=>row.sha256)).size,captures.length,platform);
  assert.ok(captures.every(row=>row.bannerHidden && row.mock));
  if(mobile) assert.ok(captures.every(row=>row.statusBarTime==='09:41'));
 }
});

test('every landing state shares the same capture canvas within its platform',()=>{
 for(const platform of ['macos','windows','linux','iphone','android']){
  let expected;
  const states=['iphone','android'].includes(platform)?['disconnected','nfc','reader','card','ready']:['disconnected','reader','ready'];
  for(const appearance of ['light','dark'])for(const state of states){
   const file=`landing/${platform}/${state}-${appearance}.png`;
   const bytes=readFileSync(new URL(file,assets));
   const dimensions=[bytes.readUInt32BE(16),bytes.readUInt32BE(20)];
   expected??=dimensions;
   assert.deepEqual(dimensions,expected,`${file} must align with the other story states`);
  }
 }
});
