import catalog from '../data/agent-integrations.json' with {type:'json'};
export const clients = catalog.clients;
export const skill = catalog.skill;
export const defaults = {
 macos: {command:'/opt/homebrew/bin/esemnbun-mcp',root:'/Users/me/Documents/Signing',broker:'/Users/me/Library/Application Support/eSemnBun/AgentBroker',output:'/Users/me/PrivateSigningOutput'},
 windows: {command:'C:\\Program Files\\eSemnBun\\bin\\esemnbun.exe',root:'C:\\Users\\me\\Documents\\Signing',broker:'C:\\Users\\me\\AppData\\Local\\MoldSign\\MCP',output:'C:\\Users\\me\\PrivateSigningOutput'},
 linux: {command:'/usr/bin/esemnbun-mcp',root:'/home/me/Documents/Signing',broker:'/home/me/.local/share/eSemnBun/AgentBroker',output:'/home/me/PrivateSigningOutput'},
};
export const providers = platform => ['env',...(platform==='macos'?['keychain']:platform==='windows'?['credential']:['secret-service']),'onepassword'];
export const providerExample = {env:'ESEMNBUN_AUTOMATION_PIN',keychain:'eSemnBun-Automation:account',credential:'eSemnBun-Automation','secret-service':'eSemnBun-Automation:account',onepassword:'op://Vault/Item/field'};
export function initialSettings(platform='macos') {
 return {client:'claude-code',platform,mode:'verify',...defaults[platform],certificate:'',provider:'env',reference:providerExample.env,op:platform==='windows'?'C:\\Program Files\\1Password CLI\\op.exe':platform==='macos'?'/opt/homebrew/bin/op':'/usr/bin/op'};
}
function pathError(value,platform) {
 if (!value || /[\x00-\x1f\x7f]/.test(value)) return 'Enter an absolute path without control characters.';
 if (platform==='windows' ? !/^[a-z]:[\\/]/i.test(value) : !value.startsWith('/')) return 'Use an absolute local path for the selected platform.';
 return '';
}
export function validation(settings) {
 const errors={};
 if (!clients.some(c=>c.id===settings.client)) errors.client='Choose an agent.';
 if (!defaults[settings.platform]) errors.platform='Choose a desktop platform.';
 if (!['verify','approval','unattended'].includes(settings.mode)) errors.mode='Choose a signing mode.';
 for (const field of ['command','root',...(settings.mode==='approval'?['broker']:[]),...(settings.mode==='unattended'?['output']:[])]) {
  const error=pathError(settings[field],settings.platform);if(error) errors[field]=error;
 }
 if (settings.mode==='unattended') {
  if (!/^[a-f0-9]{64}$/i.test(settings.certificate)) errors.certificate='Enter all 64 hexadecimal digits of the signing certificate SHA-256.';
  if (!providers(settings.platform).includes(settings.provider)) errors.provider='Choose a credential provider supported on this platform.';
  const ref=settings.reference;
  const valid=settings.provider==='env'?/^[A-Za-z_][A-Za-z0-9_]*$/.test(ref):settings.provider==='onepassword'?/^op:\/\/[^/]+\/[^/]+\/.+/.test(ref):['keychain','secret-service'].includes(settings.provider)?/^[^:\x00-\x1f]+:[^:\x00-\x1f]+$/.test(ref):!!ref && !/[\x00-\x1f]/.test(ref);
  if (!valid || /^[0-9]{4,8}$/.test(ref)) errors.reference='Enter a provider reference, not a PIN value.';
  if (settings.provider==='onepassword' && pathError(settings.op,settings.platform)) errors.op='Enter the absolute path to the installed 1Password CLI.';
 }
 return errors;
}
export function configuration(s) {
 if(Object.keys(validation(s)).length) return null;
 const args=s.platform==='windows'?['mcp']:[];
 args.push('--root',`documents=${s.root}`);
 if(s.mode==='approval') args.push('--broker-directory',s.broker);
 if(s.mode==='unattended') {
  args.push('--allow-unattended-signing','--signing-certificate-sha256',s.certificate,'--signing-output-directory',s.output,'--pin-source',`${s.provider}:${s.reference}`);
  if(s.provider==='onepassword')args.push('--onepassword-executable',s.op);
 }
 const server={command:s.command,args};
 let value;
 if(s.client==='codex') return '[mcp_servers.esemnbun]\ncommand = '+JSON.stringify(s.command)+'\nargs = '+JSON.stringify(args)+'\n';
 if(s.client==='opencode')value={mcp:{servers:{esemnbun:{type:'local',command:[s.command,...args],protocol:'2026-07-28'}}}};
 else if(s.client==='vscode')value={servers:{esemnbun:{type:'stdio',...server}}};
 else {
  if(s.client==='cline')Object.assign(server,{disabled:false,autoApprove:[]});
  if(s.client==='roo')Object.assign(server,{disabled:false,alwaysAllow:[]});
  if(s.client==='gemini')server.trust=false;
  value={mcpServers:{esemnbun:server}};
 }
 return JSON.stringify(value,null,2)+'\n';
}
export function configLocation(s) {
 const paths={
  'claude-code':'your workspace: .mcp.json',
  'claude-desktop':s.platform==='windows'?'%APPDATA%\\Claude\\claude_desktop_config.json':s.platform==='macos'?'~/Library/Application Support/Claude/claude_desktop_config.json':'the configuration file opened by Settings → Developer → Edit Config (confirm vendor OS support)',
  codex:'~/.codex/config.toml, or trusted-project .codex/config.toml',
  cursor:'your workspace: .cursor/mcp.json, or ~/.cursor/mcp.json',
  vscode:'your workspace: .vscode/mcp.json, or MCP: Open User Configuration',
  gemini:'your workspace: .gemini/settings.json, or ~/.gemini/settings.json',
  windsurf:'Open MCP config file in Cascade (use the file your installed app opens)',
  cline:'MCP Servers → Configure MCP Servers → cline_mcp_settings.json',
  roo:'your workspace: .roo/mcp.json, or MCP → Edit Global Config',
  opencode:'your workspace: opencode.json or opencode.jsonc',
 };
 return paths[s.client];
}
export function steps(s) {
 const client=clients.find(c=>c.id===s.client);
 const list=[
  {title:'Install the CLI and MCP helper',text:s.platform==='macos'?'Install with Homebrew: brew install xfreebird/utils/esemnbun-cli, or choose the signed macOS CLI archive on Downloads. The App Store app needs this separate helper. For Intel Homebrew, change the executable path to /usr/local/bin/esemnbun-mcp.':s.platform==='windows'?'Install the Windows CLI package or extract the CLI ZIP from Downloads. Locate the installed esemnbun.exe; this configuration supplies the mcp subcommand.':'Choose the APT, RPM, Arch or CLI archive instructions on Downloads. Install the PC/SC dependencies for card operations and locate esemnbun-mcp.'},
  {title:'Prepare the folders',text:`Create or select your input folder: ${s.root}. Use an existing physical folder without symlink ancestors. Paths must exist on the same computer as the agent. Verification needs no card or PIN.`},
 ];
 if(s.mode==='approval')list.push({title:'Enable desktop signing approval',text:`Run the standalone desktop app, enable local agent signing requests in Settings, and use its displayed private directory: ${s.broker}. Keep the app running as the same user. The broker and requests/responses/outputs directories must already have the required private ownership/permissions. macOS App Store users need the standalone broker; the Store app is not assumed to provide it.`});
 if(s.mode==='unattended')list.push({title:'Provision unattended signing',text:`This mode signs without a per-document dialog. Independently provision ${s.provider}:${s.reference}; never put the PIN in this page or agent settings. Create the dedicated output folder ${s.output}, owned by you (0700 on macOS/Linux; Windows ACL limited to you, SYSTEM and Administrators). Pin the exact signing certificate DER SHA-256. Authenticate/unlock the provider outside MCP. Keep a matching card and reader connected; validate the provider and installed helper before real use.`});
 list.push({title:'Merge the configuration',text:`Open ${configLocation(s)}. Merge only the esemnbun server entry from the configuration below; retain existing settings and other servers. Saving a downloaded fragment over an existing settings file would remove them. Reload/restart the client and approve/trust this server configuration as requested.`});
 list.push({title:'Add the document instructions',text:s.client==='claude-desktop'?'Download the document skill and paste its Markdown body into Claude Project instructions, or attach it to the conversation. It is not an automatically loaded Desktop skill.':`Save the downloaded document ${s.client==='windsurf'?'workflow':s.client==='cline'||s.client==='roo'?'rule':'skill'} at ${client?.instructionsPath}. ${s.client==='windsurf'?'Invoke /esemnbun-documents in Cascade.':'Reload skill/rule discovery and enable it if your client requires this.'} The all-client pack also contains a Claude Code plugin; use it instead of a duplicate standalone MCP entry.`});
 list.push({title:'Check the connection',text:'List MCP tools and call capabilities. The client must support 2026-07-28 or initialize with 2025-11-25; older revisions are rejected. Verify a fictional signed file using verify_document with rootId documents and its relativePath. Inspect verification status and incomplete checks, not just tool success.'});
 if(s.mode==='approval')list.push({title:'Request signing',text:'Ask the agent to prepare your PDF for approval. Review it and the certificate in the native app, enter the PIN there, and poll get_job on the same connection. A pending job is not a signature. Retrieve completed broker outputs within 24 hours; approval expires after five minutes.'});
 if(s.mode==='unattended')list.push({title:'Use unattended signing deliberately',text:'Confirm capabilities advertises sign_document, then authorize the specific PDF to sign. Never automatically retry a wrong PIN, timeout or uncertain result. Inspect card/output state and reconcile the persistent lock with the operator; do not automatically delete it. Cancellation does not prove no signature was made.'});
 return list;
}
export function instructionFile(client) {
 if(client==='windsurf')return '---\ndescription: Verify signatures or request eSemnBun smartcard signing\n---\n\n'+skill.split('---').slice(2).join('---').trimStart();
 if(['cline','roo','claude-desktop'].includes(client))return skill.split('---').slice(2).join('---').trimStart();
 return skill;
}
export function installationGuide(s) {
 const config=configuration(s);if(!config)return null;
 return `# eSemnBun — ${clients.find(c=>c.id===s.client).name}\n\nPlatform: ${s.platform}\nMode: ${s.mode}\n\n`+steps(s).map((step,i)=>`## ${i+1}. ${step.title}\n\n${step.text}\n`).join('\n')+`\n## Configuration fragment\n\n\`\`\`${s.client==='codex'?'toml':'json'}\n${config}\`\`\`\n\nhttps://esemnbun.md/docs/integrations/mcp-agents/\n`;
}
