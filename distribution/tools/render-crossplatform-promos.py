#!/usr/bin/env python3
"""Render localized Google Play screenshots and optional Windows artwork from native captures."""
import argparse, hashlib, json
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont, ImageFilter
ROOT=Path(__file__).resolve().parents[2]
p=argparse.ArgumentParser();p.add_argument('--output',type=Path,required=True);p.add_argument('--stores',default='android,windows');p.add_argument('--android-raw',type=Path,default=ROOT/'distribution/google/assets/android');p.add_argument('--windows-raw',type=Path,default=ROOT/'distribution/microsoft/assets');a=p.parse_args()
selected=set(a.stores.split(','))
if not selected or not selected <= {'android','windows'}:raise SystemExit('--stores must select android and/or windows')
FONT='/System/Library/Fonts/Supplemental/Arial.ttf';BOLD='/System/Library/Fonts/Supplemental/Arial Bold.ttf'
COPY={
'ro':{'foot':'Necesită un act de identitate și un cititor USB compatibile.','steps':{'sign':('Semnează simplu.','Alege documentul și aprobă semnarea.'),'card':('Alege cardul potrivit.','Vezi titularul și certificatul înainte de semnare.'),'verify':('Verifică documentele.','Deschide un PDF sau o semnătură XAdES.'),'browser':('Servicii, în aplicație.','Folosește cardul pe portaluri compatibile.'),'settings':('Aplicația, pe gustul tău.','Alege limba, tema și preferințele aplicației.')}},
'en':{'foot':'Requires a compatible ID card and USB card reader.','steps':{'sign':('Signing, made simple.','Choose your document and approve the signature.'),'card':('Choose the right card.','Review the holder and certificate before signing.'),'verify':('Check your documents.','Open a PDF or an XAdES signature.'),'browser':('Services, inside your app.','Use your card on compatible portals.'),'settings':('Make it your own.','Choose your language, theme and preferences.')}},
'ru':{'foot':'Нужны совместимые ID-карта и USB-считыватель.','steps':{'sign':('Подписывайте просто.','Выберите документ и подтвердите подпись.'),'card':('Выберите нужную карту.','Проверьте владельца и сертификат карты.'),'verify':('Проверяйте документы.','Откройте PDF или подпись XAdES.'),'browser':('Сервисы в приложении.','Используйте карту на совместимых порталах.'),'settings':('Настройте приложение.','Выберите язык, тему и настройки приложения.')}}}
def block(d,text,x,y,size,width,bold=False,color='#162749'):
 f=ImageFont.truetype(BOLD if bold else FONT,size);line='';lines=[]
 for word in text.split():
  trial=(line+' '+word).strip()
  if d.textbbox((0,0),trial,font=f)[2]>width and line:lines.append(line);line=word
  else:line=trial
 lines.append(line)
 for line in lines:d.text((x,y),line,font=f,fill=color);y+=int(size*1.22)
 return y
# Fail closed rather than producing a partial or empty campaign pack.
for lang in COPY:
 for family in (('phone','seven-inch','ten-inch') if 'android' in selected else ()):
  for name in ('01-sign.png','02-card.png','03-verify.png','04-browser.png'):
   source=a.android_raw/lang/family/name
   if not source.is_file():raise SystemExit(f'Missing Android source: {source}')
   image=Image.open(source)
   expected=(1920,1080) if family=='ten-inch' else (1080,1920)
   if image.size!=expected:raise SystemExit(f'Wrong Android source size {source}: {image.size}, expected {expected}')
 for name in (('01-sign.png','02-card.png','03-verify.png','04-settings.png') if 'windows' in selected else ()):
  source=a.windows_raw/lang/name
  if not source.is_file():raise SystemExit(f'Missing Windows source: {source}')
  image=Image.open(source)
  if image.width<1366 or image.height<768:raise SystemExit(f'Windows source below Store size: {source}')
manifest=[]
for store,raw in [('android',a.android_raw),('windows',a.windows_raw)]:
 if store not in selected:continue
 for lang in COPY:
  sets=[(x,raw/lang/x) for x in ('phone','seven-inch','ten-inch')] if store=='android' else [('desktop',raw/lang)]
  for family,folder in sets:
   for source in sorted(folder.glob('*.png')):
    story=source.stem.split('-',1)[-1]
    if story not in COPY[lang]['steps']:continue
    portrait=family in ('phone','seven-inch');W,H=((1440,2560) if portrait else (2560,1440)) if store=='android' else (2880,1800)
    canvas=Image.new('RGBA',(W,H),'#e8edf9');d=ImageDraw.Draw(canvas);outer=int(W*.012);d.rounded_rectangle((outer,outer,W-outer,H-outer),radius=int(W*.035),fill='#f3f6fd');m=int(W*.065)
    icon=Image.open(ROOT/'android/design/play-store-icon-512.png').convert('RGBA');s=int(W*(.045 if portrait else .028));icon=icon.resize((s,s),Image.Resampling.LANCZOS);mask=Image.new('L',icon.size);ImageDraw.Draw(mask).rounded_rectangle((0,0,s-1,s-1),radius=int(s*.22),fill=255);canvas.paste(icon,(m,int(H*.035)),mask)
    d=ImageDraw.Draw(canvas);block(d,'eSemnBun',m+s+20,int(H*.038),int(W*.026),W*.6,True)
    title,subtitle=COPY[lang]['steps'][story];size=int(W*(.061 if portrait else .037));y=block(d,title,m,int(H*(.09 if portrait else .105)),size,W-2*m,True);y=block(d,subtitle,m,y+int(H*.012),int(size*.43),W-2*m,color='#41506e')
    ui=Image.open(source).convert('RGBA');available=(W-2*m,H-y-int(H*.11));scale=min(available[0]/ui.width,available[1]/ui.height);ui=ui.resize((int(ui.width*scale),int(ui.height*scale)),Image.Resampling.LANCZOS);x=(W-ui.width)//2;top=y+int(H*.025);radius=int(min(ui.width,ui.height)*(.04 if portrait else .03));uiMask=Image.new('L',ui.size);ImageDraw.Draw(uiMask).rounded_rectangle((0,0,ui.width-1,ui.height-1),radius=radius,fill=255)
    shadow=Image.new('RGBA',canvas.size);ImageDraw.Draw(shadow).rounded_rectangle((x-6,top-6,x+ui.width+6,top+ui.height+6),radius=radius,fill=(30,50,100,65));canvas=Image.alpha_composite(canvas,shadow.filter(ImageFilter.GaussianBlur(22)));canvas.paste(ui,(x,top),uiMask);d=ImageDraw.Draw(canvas);block(d,COPY[lang]['foot'],m,H-int(H*.055),max(22,int(W*.015)),W-2*m,color='#4b5973')
    target=a.output/store/lang/family/source.name;target.parent.mkdir(parents=True,exist_ok=True);canvas.convert('RGB').save(target,optimize=True)
    manifest.append({'file':str(target.relative_to(a.output)),'source':str(source),'sourceSha256':hashlib.sha256(source.read_bytes()).hexdigest(),'sha256':hashlib.sha256(target.read_bytes()).hexdigest(),'locale':lang,'family':family,'dimensions':[W,H],'submissionScreenshot':store=='android','role':('localized Google Play screenshot; native capture retained separately' if store=='android' else 'optional Windows campaign art; native screenshots remain separate'),'treatment':'rounded outer mask only; UI contents unaltered'})
expected=(36 if 'android' in selected else 0)+(12 if 'windows' in selected else 0)
assert len(manifest)==expected, f'Expected {expected} campaign images, got {len(manifest)}'
a.output.mkdir(parents=True,exist_ok=True);(a.output/'manifest.json').write_text(json.dumps(manifest,ensure_ascii=False,indent=2)+'\n');print(f'Rendered {len(manifest)} rounded promotional images')
