import assert from 'node:assert/strict';
import {readFileSync,readdirSync} from 'node:fs';
import path from 'node:path';
import {fileURLToPath} from 'node:url';
import {test} from 'node:test';
import {layoutGuideCallouts} from '../src/components/guideCallouts.mjs';

const site = fileURLToPath(new URL('../', import.meta.url));
const roots = ['docs/platforms','i18n/ro/docusaurus-plugin-content-docs/current/platforms','i18n/ru/docusaurus-plugin-content-docs/current/platforms'];
const markdown = root => readdirSync(root,{withFileTypes:true}).flatMap(entry=>entry.isDirectory() ? markdown(path.join(root,entry.name)) : entry.name.endsWith('.md') ? [path.join(root,entry.name)] : []);
const panels = roots.flatMap(root => markdown(path.join(site,root)).flatMap(file => {
  const text = readFileSync(file, 'utf8');
  return [...text.matchAll(/<GuideScreenshot\b[\s\S]*?\/>/g)].map(([panel]) => {
    const src = panel.match(/src="([^"]+)"/)[1];
    const steps = JSON.parse(panel.match(/steps=\{(\[[\s\S]*\])\}/)[1]);
    const asset = readFileSync(path.join(site, 'static', src));
    const width = src.endsWith('.png') ? asset.readUInt32BE(16) : Number(asset.toString().match(/width="([\d.]+)"/)[1]);
    const height = src.endsWith('.png') ? asset.readUInt32BE(20) : Number(asset.toString().match(/height="([\d.]+)"/)[1]);
    return {src, steps, width, height};
  });
}));

test('all illustrated panels keep numbered labels outside app pixels at phone, desktop and actual size', () => {
  assert.equal(panels.length, 702);
  for (const panel of panels) {
    for (const available of [288,368,760,panel.width + 72]) {
      const positioned = panel.steps.filter(step => Number.isFinite(step.x) && Number.isFinite(step.y));
      const lanes = Math.max(positioned.filter(step => step.x <= 50).length, positioned.filter(step => step.x > 50).length);
      const width = Math.min(panel.width, available - 72);
      const height = width / panel.width * panel.height;
      const frame = {width: width + 72, height: Math.max(height + 12, 52, lanes * 32 + 12)};
      const image = {x:36, y:(frame.height-height)/2, width, height};
      const labels = layoutGuideCallouts(panel.steps, frame, image);
      assert.equal(labels.length, positioned.length, panel.src);
      for (const label of labels) {
        assert.ok(label.x + 12 < image.x || label.x - 12 > image.x + width, `${panel.src}: badge over image`);
        assert.ok(label.y >= 12 && label.y <= frame.height - 12, `${panel.src}: clipped badge`);
        const step = panel.steps[label.number - 1];
        assert.ok(label.side === 'left' ? label.targetX < image.x : label.targetX > image.x + width, `${panel.src}: pointer over image`);
        assert.equal(label.targetY, image.y + height * step.y / 100);
      }
      for (const side of ['left','right']) {
        const lane = labels.filter(label => label.side === side).sort((a,b)=>a.targetY-b.targetY);
        for (let index=1;index<lane.length;index++) assert.ok(lane[index].y-lane[index-1].y >= 31.99, `${panel.src}: colliding badges`);
      }
    }
  }
});

test('text-only steps retain their numbering without a misleading pointer', () => {
  const labels=layoutGuideCallouts([{text:'First'},{x:80,y:50,text:'Second'}],{width:300,height:100},{x:36,y:10,width:228,height:80},4);
  assert.deepEqual(labels.map(label=>label.number),[5]);
});

test('file protection screenshots are native captures in each documentation locale', () => {
  for (const platform of ['macos','iphone','ipad','android-phone','android-tablet','linux','windows']) {
    const scenarios = ['password','decrypt', ...(['macos','linux','windows'].includes(platform) ? ['remove'] : [])];
    for (const scenario of scenarios) {
      const captures = ['en','ro','ru'].map(locale => readFileSync(path.join(site, 'static/img/guide', platform, locale, `protect-${scenario}-light.png`)));
      for (let i = 0; i < captures.length; i++) for (let j = i + 1; j < captures.length; j++) {
        assert.ok(!captures[i].equals(captures[j]), `${platform}/${scenario}: untranslated screenshot reused`);
      }
    }
  }
});
