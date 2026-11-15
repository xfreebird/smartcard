import {test} from 'node:test';
import assert from 'node:assert/strict';
import {downloadPlatformFromHash, focusedDownloadPlatform} from '../src/components/downloadNavigation.mjs';

const section = (id, top, bottom) => ({id, top, bottom});
const choose = (sections, currentId = 'macos', top = 150, bottom = 750) =>
 focusedDownloadPlatform(sections, {currentId, top, bottom});

test('scrolling in either direction follows the card at the reading position', () => {
 assert.equal(choose([section('macos', -800, 200), section('windows', 220, 1200)]), 'windows');
 assert.equal(choose([section('macos', 180, 700), section('windows', 720, 1700)], 'windows'), 'macos');
});

test('a long card stays selected even when only a small percentage is visible', () => {
 assert.equal(choose([section('android', -600, 100), section('linux', 120, 6000)], 'android'), 'linux');
});

test('sticky controls are excluded from the reading area', () => {
 assert.equal(choose([section('ios', -100, 280), section('android', 300, 1000)], 'ios', 250), 'android');
});

test('gaps choose the closest section without selecting one outside the viewport', () => {
 assert.equal(choose([section('ios', 100, 330), section('android', 400, 900)], 'android'), 'ios');
 assert.equal(choose([section('ios', -500, 149), section('android', 600, 1000)], 'ios'), 'android');
});

test('short final sections are selected near the bottom of the document', () => {
 assert.equal(choose([section('android', -500, 120), section('linux', 160, 260)], 'android'), 'linux');
});

test('desktop columns preserve explicit selection when both contain the focus position', () => {
 const row = [section('macos', 180, 950), section('windows', 180, 1200)];
 assert.equal(choose(row, 'windows'), 'windows');
 assert.equal(choose(row, 'linux'), 'macos');
 assert.equal(choose([section('ios', -500, 300), section('android', -500, 650)], 'ios'), 'android');
});

test('header, footer and a fully obscured viewport retain the last selected platform', () => {
 assert.equal(choose([section('macos', 800, 1800)]), 'macos');
 assert.equal(choose([section('linux', -900, 100)], 'linux'), 'linux');
 assert.equal(choose([], 'windows'), 'windows');
 assert.equal(choose([section('ios', 0, 600)], 'ios', 750, 400), 'ios');
});

test('direct and legacy links resolve without interpreting unrelated page anchors', () => {
 const ids = ['macos', 'windows', 'ios', 'android', 'linux'];
 for (const id of ids) assert.equal(downloadPlatformFromHash(`#${id}`, ids), id);
 assert.equal(downloadPlatformFromHash('#linux-cli', ids), 'linux');
 assert.equal(downloadPlatformFromHash('#cli', ids), 'macos');
 for (const hash of ['', '#', '#unknown', '#__docusaurus_skipToContent_fallback']) {
  assert.equal(downloadPlatformFromHash(hash, ids), null);
 }
});
