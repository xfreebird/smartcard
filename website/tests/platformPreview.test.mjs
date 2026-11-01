import {test} from 'node:test';
import assert from 'node:assert/strict';
import {debugPreviewEnabled,previewChoice,previewPlatforms,storyPlatform} from '../src/components/previewPlatformState.mjs';

test('production preview controls are restricted to loopback hosts',()=>{
 for(const hostname of ['localhost','127.0.0.1','::1','[::1]'])assert.equal(debugPreviewEnabled(hostname),true);
 for(const hostname of ['xfreebird.github.io','esemnbun.md','localhost.example.com','192.168.50.126'])assert.equal(debugPreviewEnabled(hostname),false);
 assert.equal(debugPreviewEnabled('192.168.50.126',true),true);
});

test('explicit platform overrides both browser detection and viewport category',()=>{
 for(const platform of previewPlatforms.filter(value=>value!=='auto')){
  for(const width of [390,1440]){
   for(const ua of ['Macintosh','Android','Windows NT','Linux','iPhone']){
    assert.equal(storyPlatform(platform,ua,width),platform);
   }
  }
 }
});

test('automatic restores device and responsive browser detection',()=>{
 assert.equal(storyPlatform('auto','Macintosh',1440),'macos');
 assert.equal(storyPlatform('auto','Windows NT',1440),'windows');
 assert.equal(storyPlatform('auto','Linux',1440),'linux');
 assert.equal(storyPlatform('auto','Macintosh',390),'iphone');
 assert.equal(storyPlatform('auto','iPhone',1440),'iphone');
 assert.equal(storyPlatform('auto','Android',1440),'android');
});

test('missing or obsolete saved preview values fall back to automatic',()=>{
 for(const value of [null,undefined,'','web','AUTO']){
  assert.equal(previewChoice(value),'auto');
  assert.equal(storyPlatform(value,'Windows NT',1440),'windows');
 }
});
