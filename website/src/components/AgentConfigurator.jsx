import React,{useState} from 'react';
import CodeBlock from '@theme/CodeBlock';
import Link from '@docusaurus/Link';
import {clients,providers,providerExample,initialSettings,validation,configuration,steps,instructionFile,installationGuide} from './agentConfiguration.mjs';
import styles from './AgentConfigurator.module.css';

function download(name,text,type='text/plain') {
 const url=URL.createObjectURL(new Blob([text],{type:`${type};charset=utf-8`}));
 const anchor=document.createElement('a');anchor.href=url;anchor.download=name;anchor.click();
 setTimeout(()=>URL.revokeObjectURL(url),1000);
}
export default function AgentConfigurator() {
 const [settings,setSettings]=useState(()=>initialSettings());
 const [copied,setCopied]=useState('');
 const errors=validation(settings),config=configuration(settings),client=clients.find(c=>c.id===settings.client);
 function update(key,value) {setSettings(old=>({...old,[key]:value}));setCopied('');}
 function platform(value) {
  setSettings(old=>({...initialSettings(value),client:old.client,mode:old.mode}));setCopied('');
 }
 function field(key,label,hint) {
  return <label className={styles.field}>{label}<input type="text" value={settings[key]} onChange={e=>update(key,e.target.value)} spellCheck={false} autoComplete="off" aria-invalid={!!errors[key]} aria-describedby={errors[key]?`agent-error-${key}`:undefined}/>{hint&&<small>{hint}</small>}{errors[key]&&<span className={styles.error} id={`agent-error-${key}`}>{errors[key]}</span>}</label>;
 }
 async function copy() {
  try {await navigator.clipboard.writeText(config);setCopied('Configuration copied.');}
  catch {setCopied('Copy is unavailable here. Select the configuration text, or download it.');}
 }
 return <section className={styles.panel} aria-labelledby="agent-configurator-title">
  <h2 id="agent-configurator-title">Build your setup</h2>
  <p>Choose your agent and computer, then adjust the example paths. Your selections stay in this page; nothing is installed or sent to eSemnBun.</p>
  <div className={styles.grid}>
   <label className={styles.field}>AI agent<select value={settings.client} onChange={e=>update('client',e.target.value)}>{clients.map(c=><option key={c.id} value={c.id}>{c.name}</option>)}</select></label>
   <label className={styles.field}>Computer<select value={settings.platform} onChange={e=>platform(e.target.value)}><option value="macos">macOS</option><option value="windows">Windows</option><option value="linux">Linux</option></select></label>
  </div>
  <fieldset className={styles.modes}><legend>What do you want to do?</legend>{[
   ['verify','Verify signatures','Offline checks; no card or PIN needed.'],
   ['approval','Sign with desktop approval','Review and approve each PDF in the native app.'],
   ['unattended','Sign unattended','An operator-provisioned credential and matching card are required.'],
  ].map(([value,label,hint])=><label className={styles.mode} key={value}><input type="radio" name="agent-signing-mode" value={value} checked={settings.mode===value} onChange={()=>update('mode',value)}/><span className={styles.modeLabel}>{label}<small>{hint}</small></span></label>)}</fieldset>
  {settings.client==='claude-desktop'&&settings.platform==='linux'&&<p className={styles.notice}>Confirm that your Claude Desktop build supports Linux before using this example. Otherwise choose a supported local client, such as Claude Code.</p>}
  <details className={styles.paths} open><summary>Paths on your computer</summary>
   {field('command','Installed MCP executable',settings.platform==='macos'?'Apple Silicon Homebrew example. Intel Homebrew commonly uses /usr/local/bin/esemnbun-mcp.':'Use the actual installed executable, not a shell command.')}
   {field('root','Folder the agent may read','Replace “me” with your account name. Choose a narrow, existing physical folder.')}
   {settings.mode==='approval'&&field('broker','Private desktop approval directory','Copy the directory shown in the desktop app’s agent settings.')}
  </details>
  {settings.mode==='unattended'&&<fieldset className={styles.credentials}><legend>Unattended signing policy</legend>
   <p>This configuration allows signing without a per-document approval dialog. Provision and validate the credential provider independently. Do not enter a PIN here.</p>
   {field('certificate','Signing certificate SHA-256','The exact certificate DER fingerprint: 64 hexadecimal digits.')}
   {field('output','Private output folder','Create this dedicated folder with the permissions described below.')}
   <label className={styles.field}>Credential provider<select value={settings.provider} onChange={e=>{const provider=e.target.value;setSettings(old=>({...old,provider,reference:providerExample[provider]}));setCopied('');}}>{providers(settings.platform).map(p=><option value={p} key={p}>{{env:'Environment variable',keychain:'macOS Keychain',credential:'Windows Credential Manager','secret-service':'Linux Secret Service',onepassword:'1Password'}[p]}</option>)}</select></label>
   {field('reference','Credential reference',`Example: ${providerExample[settings.provider]}. Enter a reference, not the secret value.`)}
   {settings.provider==='onepassword'&&field('op','Installed 1Password CLI executable')}
  </fieldset>}
  <div className={styles.result}>
   <h3>Your installation guide</h3>
   <p><strong>{client.name} · {{macos:'macOS',windows:'Windows',linux:'Linux'}[settings.platform]}</strong></p>
   <ol className={styles.steps}>{steps(settings).map(step=><li key={step.title}><strong>{step.title}</strong><p>{step.text}{step.title==='Install the CLI and MCP helper'&&<> <Link to="/downloads/">Open Downloads →</Link></>}</p></li>)}</ol>
   <h3>Your MCP configuration</h3>
   {config?<>
    <p>Merge this fragment into the file indicated above. Keep existing settings and other servers.</p>
    <CodeBlock language={settings.client==='codex'?'toml':'json'}>{config}</CodeBlock>
    <div className={styles.actions}>
     <button type="button" className="button button--primary" onClick={copy}>Copy configuration</button>
     <button type="button" className="button button--secondary" onClick={()=>download(client.configPath.split('/').pop(),config)}>Download configuration</button>
     <button type="button" className="button button--secondary" onClick={()=>download(`esemnbun-${settings.client}-${settings.platform}-setup.md`,installationGuide(settings))}>Download installation guide</button>
    </div>
   </>:<p role="status">Complete the highlighted fields to generate your configuration and downloadable guide.</p>}
   <p role="status" aria-live="polite">{copied}</p>
   <button type="button" className="button button--secondary" onClick={()=>download(client.instructionsPath.split('/').pop(),instructionFile(settings.client))}>Download document {settings.client==='windsurf'?'workflow':['cline','roo'].includes(settings.client)?'rule':settings.client==='claude-desktop'?'instructions':'skill'}</button>
   <p className={styles.footnote}>Examples require the client’s supported MCP revision. The page cannot inspect your installed software, files, permissions or card. A credential reference and file paths may appear in downloads; keep them private. <a href="https://esemnbun.md/packages/mcp.md">Full protocol and signing policy</a>.</p>
  </div>
 </section>;
}
