import test from 'node:test';
import assert from 'node:assert/strict';
import {readFileSync} from 'node:fs';
import vm from 'node:vm';

const template = readFileSync(new URL('../spec/browser/locale.js', import.meta.url), 'utf8');
function run(language, {saved = null, host = 'msign.gov.md', protocol = 'https:', port = '', frame = false, blocked = false} = {}) {
    let value = saved;
    let writes = 0;
    const window = {};
    window.top = frame ? {} : window;
    const context = {
        window, navigator: {language: 'ro', languages: ['ro']},
        location: {hostname: host, protocol, origin: protocol + '//' + host + (port ? ':' + port : '')},
        localStorage: {
            getItem() { if (blocked) throw Error('Storage disabled'); return value; },
            setItem(key, next) { assert.equal(key, 'vuex'); value = next; writes++; },
        },
    };
    const changed = vm.runInNewContext(template.replace('__APP_LANGUAGE__', language), context);
    return {changed, saved: value, writes, navigator: context.navigator};
}

for (const language of ['en', 'ro', 'ru']) {
    test(language + ': first document follows the app and preserves portal state', () => {
        const original = {language: {culture: 'old', other: 42}, auth: {session: 'fixture'}, documents: ['fixture.pdf']};
        const result = run(language, {saved: JSON.stringify(original)});
        assert.equal(result.navigator.language, language);
        assert.deepEqual(Array.from(result.navigator.languages), [language]);
        assert.deepEqual(JSON.parse(result.saved), {...original, language: {culture: language, other: 42}});
        assert.equal(result.changed, true);
        const repeat = run(language, {saved: result.saved});
        assert.equal(repeat.changed, false);
        assert.equal(repeat.writes, 0); // No Android fallback reload loop.
    });
}
test('switching the app language replaces a previously persisted portal choice', () => {
    const first = run('en');
    assert.equal(JSON.parse(run('ru', {saved: first.saved}).saved).language.culture, 'ru');
});
for (const saved of ['broken JSON', 'null', '[]', '17', '{"language":null}', '{"language":[]}']) {
    test('recover invalid locale storage: ' + saved, () => {
        assert.equal(JSON.parse(run('en', {saved}).saved).language.culture, 'en');
    });
}
for (const options of [{host: 'example.com'}, {host: 'msign.gov.md.example.com'}, {protocol: 'http:'}, {port: '8443'}, {frame: true}]) {
    test('leave other origins and embedded frames storage alone: ' + JSON.stringify(options), () => {
        const result = run('ru', {...options, saved: 'unchanged'});
        assert.equal(result.saved, 'unchanged');
        assert.equal(result.writes, 0);
        assert.equal(result.navigator.language, 'ru');
    });
}
test('blocked storage does not break page loading or browser language', () => {
    const result = run('en', {blocked: true});
    assert.equal(result.changed, false);
    assert.equal(result.navigator.language, 'en');
});
test('unsupported substitution is ignored', () => {
    const result = run('unsupported');
    assert.equal(result.changed, false);
    assert.equal(result.navigator.language, 'ro');
    assert.equal(result.writes, 0);
});
