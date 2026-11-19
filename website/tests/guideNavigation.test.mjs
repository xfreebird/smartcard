import assert from 'node:assert/strict';
import {readFileSync,existsSync} from 'node:fs';
import {test} from 'node:test';
import GithubSlugger from 'github-slugger';
const site=new URL('../',import.meta.url);
const nav=JSON.parse(readFileSync(new URL('src/data/guide-navigation.json',site)));
const read=(locale,file)=>readFileSync(new URL(`${locale==='en'?'docs':`i18n/${locale}/docusaurus-plugin-content-docs/current`}/platforms/${file}.md`,site),'utf8');
test('task directories preserve panels, device navigation and old localized bookmarks',()=>{
 let pages=0,panels=0,anchors=0;
 for(const locale of ['en','ro','ru']) for(const platform of nav.platforms){
  const overview=read(locale,platform.id);
  assert.match(overview,/<GuideDirectory platform=/);
  assert.doesNotMatch(overview,/<GuideScreenshot /);
  const destinations=new Map();
  for(const topic of platform.topics){
   const text=read(locale,`${platform.id}/${topic.id}`);
   const count=(text.match(/<GuideScreenshot /g)||[]).length;
   if(platform.id==='windows'||platform.id==='windows-cli'){
    assert.ok(count>0,`Windows task must have numbered illustrations: ${locale}/${platform.id}/${topic.id}`);
    assert.doesNotMatch(text,/<PlatformScreenshots/);
   }
   assert.equal(count,topic.panels[locale]);panels+=count;pages++;
   const folder=locale==='en'?'docs':`i18n/${locale}/docusaurus-plugin-content-docs/current`;
   const taskUrl=new URL(`${folder}/platforms/${platform.id}/${topic.id}.md`,site);
   for(const [,link] of text.matchAll(/\]\((\.{1,2}\/[^)#?]+\.md)(?:#[^)]*)?\)/g))
    assert.ok(existsSync(new URL(link,taskUrl)),`${locale}/${platform.id}/${topic.id}: missing ${link}`);
   for(const [,target] of text.matchAll(/pagination_(?:prev|next): "([^"]+)"/g)) assert.ok(target===`platforms/${platform.id}`||target.startsWith(`platforms/${platform.id}/`));
   const slugger=new GithubSlugger();
   destinations.set(topic.id,new Set([...text.matchAll(/^#{1,6} (.+)$/gm)].map(([,heading])=>slugger.slug(heading))));
  }
  for(const target of Object.values(platform.anchors[locale])){
   const [topic,anchor]=target.split('/#');assert.ok(destinations.get(topic)?.has(anchor),`${locale}/${platform.id}/${target}`);anchors++;
  }
 }
 assert.equal(pages,327);assert.equal(panels,792);assert.equal(anchors,594);
});
