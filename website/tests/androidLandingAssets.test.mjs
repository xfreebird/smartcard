import {readFileSync} from 'node:fs';
import {resolve} from 'node:path';
import {fileURLToPath} from 'node:url';
import {test} from 'node:test';
import assert from 'node:assert/strict';

const root=resolve(fileURLToPath(new URL('..',import.meta.url)));
const scenes=['disconnected','reader','ready'];
const appearances=['light','dark'];

function pngDimensions(path){
 const bytes=readFileSync(path);
 assert.deepEqual([...bytes.subarray(1,4)],[80,78,71],`${path} must remain a PNG`);
 return {width:bytes.readUInt32BE(16),height:bytes.readUInt32BE(20)};
}

test('Android landing scenes use native phone captures, never tablet captures',()=>{
 for(const scene of scenes)for(const appearance of appearances){
  const path=resolve(root,`static/img/landing/android/${scene}-${appearance}.png`);
  const {width,height}=pngDimensions(path);
  assert.equal(width,1080,`${scene}-${appearance} should be a phone-width capture`);
  assert.equal(height,2400,`${scene}-${appearance} should keep the Android phone height`);
 }
});
