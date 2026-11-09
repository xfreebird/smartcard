#!/usr/bin/env python3
"""Generate focused task pages from the localized journey source, preserving every illustration."""
import argparse
import json
import re
import subprocess
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
LOCALES = ('en', 'ro', 'ru')
def tr(en, ro, ru): return dict(zip(LOCALES, (en, ro, ru)))
TOPICS = {
 'setup': (tr('Get started','Primii pași','Начало работы'), tr('Install, connect a reader and choose your card.','Instalează, conectează cititorul și alege cardul.','Установите приложение, подключите считыватель и выберите карту.')),
 'signing': (tr('Sign documents','Semnează documente','Подпишите документы'), tr('Add files, choose the format and stamp, approve and save the output.','Adaugă fișiere, alege formatul și ștampila, aprobă și salvează rezultatul.','Добавьте файлы, выберите формат и штамп, подтвердите и сохраните результат.')),
 'verification': (tr('Check a signature','Verifică o semnătură','Проверьте подпись'), tr('Verify a PDF or XML and inspect its signer and certificate.','Verifică un PDF sau XML și inspectează semnatarul și certificatul.','Проверьте PDF или XML, сведения о подписанте и сертификате.')),
 'results': (tr('Understand verification results','Înțelege rezultatele verificării','Разберитесь в результатах проверки'), tr('Distinguish invalid signatures, unconfirmed trust and unsigned files.','Deosebește semnăturile invalide, încrederea neconfirmată și fișierele nesemnate.','Различайте неверную подпись, неподтверждённое доверие и файлы без подписи.')),
 'documents': (tr('Find saved documents','Găsește documentele salvate','Найдите сохранённые документы'), tr('Open signing details, share saved files and clear recent history.','Deschide detaliile semnării, distribuie fișierele și golește istoricul recent.','Откройте сведения о подписи, отправьте файлы и очистите историю.')),
 'browser': (tr('Sign on websites','Semnează pe site-uri','Подпишите на сайте'), tr('Connect a service, review requests and manage website sessions.','Conectează un serviciu, verifică cererile și gestionează sesiunile web.','Подключите сервис, проверьте запросы и управляйте сеансами сайтов.')),
 'preferences': (tr('Change settings','Modifică setările','Измените настройки'), tr('Manage language, appearance, saved PINs, startup and updates.','Gestionează limba, aspectul, PIN-urile salvate, pornirea și actualizările.','Настройте язык, оформление, сохранённые PIN, запуск и обновления.')),
 'automation': (tr('Use Shortcuts and automation','Folosește Scurtături și automatizări','Используйте команды и автоматизацию'), tr('Set up Siri, Spotlight, Handoff and the supported approval workflow.','Configurează Siri, Spotlight, Handoff și aprobarea disponibilă pe dispozitiv.','Настройте Siri, Spotlight, Handoff и поддерживаемое подтверждение.')),
 'help': (tr('Fix a problem','Rezolvă o problemă','Решите проблему'), tr('Resolve reader, PIN, document and connection problems safely.','Rezolvă în siguranță problemele de cititor, PIN, document și conexiune.','Безопасно решайте проблемы считывателя, PIN, документов и соединения.')),
 'mcp': (tr('Connect an agent with MCP','Conectează un agent prin MCP','Подключите агента через MCP'), tr('Choose trusted folders and configure your MCP host.','Alege dosarele autorizate și configurează clientul MCP.','Выберите доверенные папки и настройте клиент MCP.')),
 'approval': (tr('Approve local signing','Aprobă semnarea locală','Подтвердите локальную подпись'), tr('Prepare a PDF and review its foreground approval request.','Pregătește un PDF și verifică cererea de aprobare în aplicație.','Подготовьте PDF и проверьте запрос подтверждения в приложении.')),
 'unattended': (tr('Configure unattended signing','Configurează semnarea nesupravegheată','Настройте подпись без присутствия'), tr('Pin the certificate, choose a secret provider and restrict output.','Fixează certificatul, alege sursa secretului și restricționează rezultatele.','Закрепите сертификат, выберите источник секрета и ограничьте вывод.')),
 'service': (tr('Run the browser service','Pornește serviciul pentru browser','Запустите службу браузера'), tr('Start and stop the local bridge or supported user service.','Pornește și oprește conexiunea locală sau serviciul utilizatorului.','Запускайте и останавливайте локальный мост или службу пользователя.')),
}
MOBILE = {'setup':[0,1,15],'signing':[2,3,4,5,6],'verification':[7,8],'results':[9],'documents':[10,11],'browser':[12],'preferences':[13],'automation':[14],'help':[16],'_overview':[17]}
ANDROID = {'setup':[0,22],'signing':[1,2,3,4,5,6,7],'verification':[8,12,13],'results':[9,10,11],'documents':[14,15,16],'browser':[17,18,19,20,21],'preferences':[23],'help':[24]}
MAPS = {
 'macos': {'setup':[0,1,2],'signing':[3,4,5,6,7,8],'verification':[9,10,11],'results':[12,13,14],'documents':[15,16,17],'browser':[18,19,24],'preferences':[20,25],'automation':[21,22,23],'help':[26]},
 'ios': MOBILE, 'ipad': MOBILE, 'android': ANDROID, 'android-tablet': ANDROID,
 'linux': {'setup':[0,1,2],'signing':[3,4,5,6,7,8,9],'verification':[10,11,15],'results':[12,13,14],'documents':[16,17,18],'browser':[25],'preferences':[19,20,21,22,23],'approval':[24],'help':[26]},
 'windows': {'setup':[0],'signing':[1],'verification':[2],'documents':[6],'preferences':[3],'browser':[4],'approval':[7],'help':[5]},
 'macos-cli': {'setup':[0,1],'signing':[2],'verification':[3],'mcp':[4],'approval':[5],'unattended':[6],'service':[7]},
 'linux-cli': {'setup':[0,1],'signing':[2],'verification':[3],'mcp':[4],'unattended':[5],'service':[6]},
 'windows-cli': {'setup':[0,1],'verification':[2],'mcp':[3],'unattended':[4]},
}
# File-protection journeys appended to the canonical sources.
for _platform, _mapping in list(MAPS.items()):
 _mapping = {key: list(value) for key, value in _mapping.items()}
 _start = max(i for group in _mapping.values() for i in group) + 1
 for _offset, _topic in enumerate(('encrypt-password', 'encrypt-certificate', 'decrypt-file', 'share-certificate') + (() if _platform in ('ios','ipad','android','android-tablet') else ('remove-file',))):
  _mapping[_topic] = [_start + _offset]
 MAPS[_platform] = _mapping
TOPICS['encrypt-password'] = (tr(*('Encrypt a file with a password', 'Criptează un fișier cu parolă', 'Зашифруйте файл паролем')), tr(*('Encrypt a file with a password', 'Criptează un fișier cu parolă', 'Зашифруйте файл паролем')))
TOPICS['encrypt-certificate'] = (tr(*('Encrypt for a certificate holder', 'Criptează pentru titularul unui certificat', 'Зашифруйте для владельца сертификата')), tr(*('Encrypt for a certificate holder', 'Criptează pentru titularul unui certificat', 'Зашифруйте для владельца сертификата')))
TOPICS['decrypt-file'] = (tr(*('Decrypt a received file', 'Decriptează un fișier primit', 'Расшифруйте полученный файл')), tr(*('Decrypt a received file', 'Decriptează un fișier primit', 'Расшифруйте полученный файл')))
TOPICS['share-certificate'] = (tr(*('Share your encryption certificate', 'Distribuie certificatul tău de criptare', 'Поделитесь сертификатом шифрования')), tr(*('Share your encryption certificate', 'Distribuie certificatul tău de criptare', 'Поделитесь сертификатом шифрования')))
TOPICS['remove-file'] = (tr(*('Remove a local file', 'Elimină un fișier local', 'Удалите локальный файл')), tr(*('Remove a local file', 'Elimină un fișier local', 'Удалите локальный файл')))

NAMES = {
 'macos': tr('Mac','Mac','Mac'), 'ios':tr('iPhone','iPhone','iPhone'), 'ipad':tr('iPad','iPad','iPad'),
 'android':tr('Android phone','Telefon Android','Телефон Android'), 'android-tablet':tr('Android tablet','Tabletă Android','Планшет Android'),
 'linux':tr('Linux','Linux','Linux'), 'windows':tr('Windows','Windows','Windows'),
 'macos-cli':tr('Mac · Command line (CLI)','Mac · Linie de comandă (CLI)','Mac · Командная строка (CLI)'),
 'linux-cli':tr('Linux · Command line (CLI)','Linux · Linie de comandă (CLI)','Linux · Командная строка (CLI)'),
 'windows-cli':tr('Windows · Command line (CLI)','Windows · Linie de comandă (CLI)','Windows · Командная строка (CLI)'),
}
ASSETS={'ios':'iphone','android':'android-phone',**{key:key for key in MAPS if key not in ('ios','android')}}
GROUPS=[('macos',['macos','macos-cli'],tr('Mac','Mac','Mac')),('ios',['ios'],NAMES['ios']),('ipad',['ipad'],NAMES['ipad']),('android',['android','android-tablet'],tr('Android','Android','Android')),('linux',['linux','linux-cli'],NAMES['linux']),('windows',['windows','windows-cli'],tr('Windows','Windows','Windows'))]
WORDS = {
 'overview':tr('Choose what you want to do. Each task has its own short illustrated guide.','Alege ce vrei să faci. Fiecare activitate are un ghid ilustrat separat.','Выберите задачу. Для каждой есть отдельное краткое иллюстрированное руководство.'),
 'before':tr('Before you begin','Înainte de a începe','Перед началом'),
 'all':tr('Platform overview','Ghidurile platformei','Все руководства платформы'),
 'setup':tr('Installation and reader setup','Instalare și conectarea cititorului','Установка и подключение считывателя'),
 'samples':tr('Illustrations use fictional data. Follow the instructions in your installed app.','Ilustrațiile folosesc date fictive. Urmează instrucțiunile în aplicația instalată.','В иллюстрациях используются вымышленные данные. Выполняйте действия в установленном приложении.'),
}
def doc_root(lang): return ROOT/('website/docs' if lang=='en' else f'website/i18n/{lang}/docusaurus-plugin-content-docs/current')
def clean_heading(value): return re.sub(r'^\d+\.\s*','',value)
def fix_links(text): return re.sub(r'\]\(\./([^)]*)\)',r'](../\1)',text)
def slug_groups(groups):
 code="import Slugger from 'github-slugger';let s='';for await(const c of process.stdin)s+=c;console.log(JSON.stringify(JSON.parse(s).map(heads=>{const x=new Slugger();return heads.map(h=>x.slug(h));})));"
 p=subprocess.run(['node','--input-type=module','-e',code],cwd=ROOT/'website',input=json.dumps(groups),capture_output=True,text=True,check=True)
 return json.loads(p.stdout)
def frontmatter(values):
 return '---\n'+''.join(f'{key}: {json.dumps(value,ensure_ascii=False)}\n' for key,value in values.items())+'---\n\n'
def organize(check=False):
 outputs={};platforms=[];audit=[]
 for platform,mapping in MAPS.items():
  entry={'id':platform,'labels':NAMES[platform],'assetPlatform':ASSETS[platform],'kind':'cli' if platform.endswith('-cli') else 'app','topics':[],'anchors':{}}
  for topic,indices in mapping.items():
   if topic.startswith('_'): continue
   labels,descriptions=TOPICS[topic]
   if platform=='windows-cli' and topic=='verification': labels=tr('Verify with MCP','Verifică prin MCP','Проверьте через MCP')
   entry['topics'].append({'id':topic,'labels':labels,'descriptions':descriptions,'headings':{},'panels':{}})
  for lang in LOCALES:
   source=ROOT/'docs/user-guide/content'/lang/f'{platform}.md'
   if not source.exists():
    if check: raise SystemExit(f'Missing canonical source {source}')
    source.parent.mkdir(parents=True,exist_ok=True);source.write_text((doc_root(lang)/'platforms'/f'{platform}.md').read_text())
   raw=source.read_text();body=re.sub(r'\A---\n.*?\n---\n','',raw,count=1,flags=re.S)
   parts=re.split(r'^## (.+)\n',body,flags=re.M);prefix=parts[0];sections=list(zip(parts[1::2],parts[2::2]))
   indices=[i for group in mapping.values() for i in group]
   assert sorted(indices)==list(range(len(sections))), (platform,lang,len(sections),indices)
   imports='\n'.join(re.findall(r'^import .+$',prefix,re.M))
   intro=re.sub(r'^import .+\n','',prefix,flags=re.M);intro=re.sub(r'^# .+\n','',intro,count=1,flags=re.M).strip()
   titles=[clean_heading(head) for head,_ in sections]
   old_slugs=slug_groups([[head for head,_ in sections]])[0]
   aliases={};topic_ids=[item['id'] for item in entry['topics']]
   original_panels=raw.count('<GuideScreenshot ');new_panels=0
   for item in entry['topics']:
    topic=item['id'];chosen=mapping[topic];label=item['labels'][lang];name=NAMES[platform][lang]
    header=f'{label} — {name}';new_slugs=slug_groups([[header]+[titles[i] for i in chosen]])[0][1:]
    for index,slug in zip(chosen,new_slugs): aliases[old_slugs[index]]=f'{topic}/#{slug}'
    content='\n\n'.join(f'## {titles[index]}\n\n{fix_links(sections[index][1].strip())}' for index in chosen)+'\n'
    count=content.count('<GuideScreenshot ');new_panels+=count;item['panels'][lang]=count;item['headings'][lang]=[titles[i] for i in chosen]
    position=topic_ids.index(topic)
    meta={'title':header,'sidebar_label':label,'description':item['descriptions'][lang],
          'pagination_prev':f'platforms/{platform}/{topic_ids[position-1]}' if position else f'platforms/{platform}',
          'pagination_next':f'platforms/{platform}/{topic_ids[position+1]}' if position+1<len(topic_ids) else None}
    context=f'[{WORDS["all"][lang]}](../{platform}.md)'
    if topic!='setup': context+=f' · [{WORDS["setup"][lang]}](./setup.md)'
    if topic in ('approval','unattended'):
     mcp_path='./mcp.md' if 'mcp' in mapping else f'../{platform}-cli/mcp.md'
     context+=f' · [{TOPICS["mcp"][0][lang]}]({mcp_path})'
    used_imports='\n'.join(line for line in imports.splitlines() if re.search(r'import (\w+)',line).group(1) in content)
    text=frontmatter(meta)+used_imports+'\n\n# '+header+'\n\n'+context+'\n\n'+item['descriptions'][lang]+'\n\n'
    if count: text+=WORDS['samples'][lang]+'\n\n'
    outputs[doc_root(lang)/'platforms'/platform/f'{topic}.md']=text+content
   assert new_panels==original_panels,(platform,lang,new_panels,original_panels)
   entry['anchors'][lang]=aliases
   overview_title=(NAMES[platform][lang]+' '+{'en':'guides','ro':'— ghiduri','ru':'— руководства'}[lang])
   overview=frontmatter({'title':overview_title,'sidebar_label':NAMES[platform][lang],'hide_table_of_contents':True,'pagination_prev':None,'pagination_next':f'platforms/{platform}/setup'})
   overview+="import GuideDirectory from '@site/src/components/GuideDirectory';\nimport GuideAnchorRedirect from '@site/src/components/GuideAnchorRedirect';\n\n"
   overview+=f'# {overview_title}\n\n{WORDS["overview"][lang]}\n\n<GuideDirectory platform="{platform}" />\n<GuideAnchorRedirect platform="{platform}" />\n\n## {WORDS["before"][lang]}\n\n{intro}\n'
   for index in mapping.get('_overview',[]): overview+=f'\n## {titles[index]}\n\n{sections[index][1].strip()}\n'
   outputs[doc_root(lang)/'platforms'/f'{platform}.md']=overview
   audit.append({'platform':platform,'locale':lang,'topics':len(topic_ids),'panels':new_panels,'originalSections':len(sections),'redirects':len(aliases)})
  platforms.append(entry)
 manifest={'platforms':platforms,'groups':[{'id':group,'platforms':members,'labels':labels} for group,members,labels in GROUPS]}
 outputs[ROOT/'website/src/data/guide-navigation.json']=json.dumps(manifest,ensure_ascii=False,indent=2)+'\n'
 outputs[ROOT/'docs/user-guide/navigation-coverage.json']=json.dumps({'overviews':len(audit),'taskPages':sum(item['topics'] for item in audit),'panels':sum(item['panels'] for item in audit),'coverage':audit},ensure_ascii=False,indent=2)+'\n'
 drift=[str(path.relative_to(ROOT)) for path,text in outputs.items() if not path.exists() or path.read_text()!=text]
 if check:
  if drift: raise SystemExit('Guide organization drift:\n'+'\n'.join(drift))
 else:
  for path,text in outputs.items(): path.parent.mkdir(parents=True,exist_ok=True);path.write_text(text)
 print(json.dumps({'overviews':len(audit),'taskPages':sum(item['topics'] for item in audit),'panels':sum(item['panels'] for item in audit),'filesUpdated':len(drift)}))
if __name__=='__main__':
 parser=argparse.ArgumentParser();parser.add_argument('--check',action='store_true');organize(parser.parse_args().check)
