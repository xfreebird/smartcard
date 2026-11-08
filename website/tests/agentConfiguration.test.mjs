import {test} from 'node:test';
import assert from 'node:assert/strict';
import {execFileSync} from 'node:child_process';
import {clients,skill,initialSettings,configuration,validation,steps,installationGuide,providers} from '../src/components/agentConfiguration.mjs';
function server(s) {
 const config=JSON.parse(configuration(s));
 return s.client==='opencode'?config.mcp.servers.esemnbun:s.client==='vscode'?config.servers.esemnbun:config.mcpServers.esemnbun;
}
test('browser configuration matches shipped exporter for all 30 client/platform pairs',()=>{
 const outputs=[];
 for(const client of clients)for(const platform of ['macos','windows','linux']){
  const s={...initialSettings(platform),client:client.id};outputs.push({client:s.client,platform,command:s.command,root:s.root,config:configuration(s)});
 }
 const script=`import sys,json;sys.path.insert(0,'scripts/agents');from export_integrations import render,CLIENTS,SKILL
rows=json.load(sys.stdin)
for row in rows:
 expected=render(row['client'],row['platform'],row['command'],row['root'])
 if row['client']=='codex':
  decode=lambda text: [json.loads(line.split(' = ',1)[1]) for line in text.splitlines()[1:]]
  assert decode(row['config'])==decode(expected)
 else: assert json.loads(row['config'])==json.loads(expected)
print(json.dumps({'skill':SKILL.read_text(),'clients':list(CLIENTS)}))`;
 const actual=JSON.parse(execFileSync('python3',['-c',script],{cwd:new URL('../../',import.meta.url),input:JSON.stringify(outputs),encoding:'utf8'}));
 assert.equal(actual.skill,skill);assert.deepEqual(actual.clients,clients.map(c=>c.id));
});
test('foreground mode adds only operator-selected broker and Windows mcp subcommand',()=>{
 const s={...initialSettings('windows'),client:'vscode',mode:'approval',broker:'C:\\Private Broker'};
 assert.deepEqual(server(s).args,['mcp','--root','documents=C:\\Users\\me\\Documents\\Signing','--broker-directory','C:\\Private Broker']);
 assert.ok(steps(s).some(x=>x.title==='Enable desktop signing approval'));
});
test('unattended mode requires certificate pin and platform-supported secret reference',()=>{
 for(const platform of ['macos','windows','linux']){
  const s={...initialSettings(platform),client:'vscode',mode:'unattended'};
  assert.equal(configuration(s),null);assert.ok(validation(s).certificate);
  s.certificate='ab'.repeat(32);assert.ok(configuration(s));
  const args=server(s).args;assert.ok(args.includes('--allow-unattended-signing'));assert.ok(args.includes('env:ESEMNBUN_AUTOMATION_PIN'));
  s.provider=platform==='windows'?'keychain':'credential';assert.ok(validation(s).provider);assert.equal(configuration(s),null);
 }
});
test('paths and references cannot inject extra process arguments',()=>{
 const s={...initialSettings('linux'),client:'vscode',root:'/home/me/a "quote" --pin-source env:OTHER'};
 assert.equal(server(s).args[1],'documents='+s.root);
 for(const path of ['relative','~/Signing','/home/me/line\nbreak'])assert.equal(configuration({...s,root:path}),null);
 assert.equal(configuration({...initialSettings('windows'),root:'\\\\server\\share'}),null);
});
test('1Password needs an absolute executable and provider reference',()=>{
 const s={...initialSettings('windows'),client:'cline',mode:'unattended',certificate:'ef'.repeat(32),provider:'onepassword',reference:'op://Automation/Card/PIN'};
 assert.ok(configuration(s));assert.deepEqual(server(s).autoApprove,[]);
 assert.equal(configuration({...s,op:'op.exe'}),null);
 assert.equal(configuration({...s,reference:'123456'}),null);
 assert.equal(configuration({...s,provider:'env',reference:'123456'}),null);
});
test('every agent/platform/mode combination has tailored steps and guide',()=>{
 for(const client of clients)for(const platform of ['macos','windows','linux'])for(const mode of ['verify','approval','unattended']){
  const s={...initialSettings(platform),client:client.id,mode,certificate:'ab'.repeat(32)};
  const guide=installationGuide(s);assert.ok(guide.includes(configuration(s)));assert.ok(guide.includes(client.name));
  assert.equal(steps(s).filter(x=>x.title==='Provision unattended signing').length,mode==='unattended'?1:0);
 }
 assert.ok(providers('linux').includes('secret-service'));assert.ok(!providers('windows').includes('keychain'));
});
