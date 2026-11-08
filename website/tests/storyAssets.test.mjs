import {test} from 'node:test';
import assert from 'node:assert/strict';
import {readFileSync} from 'node:fs';
import {createHash} from 'node:crypto';
const assets=new URL('../static/img/',import.meta.url);
test('macOS story captures preserve native window title, size and content setup',()=>{
 const manifest=JSON.parse(readFileSync(new URL('macos-story.json',assets),'utf8'));
 assert.equal(manifest.theme,'light');
 assert.equal(manifest.document,'Contract.pdf');
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

test('every landing state shares the same capture canvas within its platform',()=>{
 for(const platform of ['macos','windows','linux','iphone','android']){
  let expected;
  for(const appearance of ['light','dark'])for(const state of ['disconnected','reader','ready']){
   const file=`landing/${platform}/${state}-${appearance}.png`;
   const bytes=readFileSync(new URL(file,assets));
   const dimensions=[bytes.readUInt32BE(16),bytes.readUInt32BE(20)];
   expected??=dimensions;
   assert.deepEqual(dimensions,expected,`${file} must align with the other story states`);
  }
 }
});
