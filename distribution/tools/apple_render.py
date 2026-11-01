#!/usr/bin/env python3
"""Render localized Apple store screenshots from actual, unaltered fictional UI captures."""
import argparse,json,pathlib,hashlib
from PIL import Image,ImageDraw,ImageFont,ImageFilter
R=pathlib.Path(__file__).resolve().parents[2]
P=argparse.ArgumentParser();P.add_argument('--raw',required=True);P.add_argument('--output',required=True);P.add_argument('--supplemental-output');a=P.parse_args();raw=pathlib.Path(a.raw);out=pathlib.Path(a.output)
font='/System/Library/Fonts/Supplemental/Arial.ttf';bold='/System/Library/Fonts/Supplemental/Arial Bold.ttf'
COPY={
'ro':{'foot':'Necesită un act de identitate și un cititor USB compatibile.','steps':[('Semnează simplu.','Alege documentele. Selectează cardul. Semnează.'),('Mai multe documente. Un singur flux.','Pregătește lista și aprobă semnarea lotului.'),('Tu aprobi semnarea.','Confirmă cererea și folosește PIN-ul cardului.'),('Verifică documentele.','Deschide un PDF sau o semnătură XAdES.'),('Alege cardul potrivit.','Vezi titularul și certificatul înainte de semnare.'),('Servicii, în aplicație.','Deschide portalurile în browserul integrat.')]},
'en':{'foot':'Requires a compatible ID card and USB card reader.','steps':[('Signing, made simple.','Choose documents. Select your card. Sign.'),('More documents. One clear flow.','Prepare your list and approve the batch.'),('You approve the signature.','Confirm the request and use your card PIN.'),('Check your documents.','Open a PDF or an XAdES signature.'),('Choose the right card.','Review the holder and certificate before signing.'),('Services, inside your app.','Open public portals in the built-in browser.')]},
'ru':{'foot':'Нужны совместимые ID-карта и USB-считыватель.','steps':[('Подписывайте просто.','Выберите документы и карту. Подпишите.'),('Больше документов. Один процесс.','Подготовьте список и подтвердите пакет.'),('Вы подтверждаете подпись.','Проверьте запрос и введите PIN карты.'),('Проверяйте документы.','Откройте PDF или подпись XAdES.'),('Выберите нужную карту.','Проверьте владельца и сертификат карты.'),('Сервисы в приложении.','Открывайте порталы во встроенном браузере.')]}}
def wrap(draw,text,f,width):
 words=text.split();lines=[];line=''
 for w in words:
  n=(line+' '+w).strip()
  if draw.textbbox((0,0),n,font=f)[2]>width and line:lines.append(line);line=w
  else:line=n
 return lines+[line]
def textblock(draw,text,xy,size,width,color,b=False):
 f=ImageFont.truetype(bold if b else font,size); y=xy[1]
 for line in wrap(draw,text,f,width):draw.text((xy[0],y),line,font=f,fill=color);y+=int(size*1.2)
 return y
from apple_product_frames import device_frame,frame_resource

provenance={}
for file in sorted(raw.glob('manifest-*.json')):
 for item in json.loads(file.read_text()):
  if item.get('runtimeVersion') is not None or item['path'] not in provenance:provenance[item['path']]=item
manifest=[]
for lang in COPY:
 for family,dimensions in {'iphone':(1320,2868),'ipad':(2064,2752),'duo-compact':(1398,2034),'duo-expanded':(2853,2007),'macos':(2880,1800)}.items():
  source=raw/lang/family
  if not source.exists():continue
  for index,path in enumerate(sorted(source.glob('*.png'))):
   if index>=6:continue
   W,H=dimensions;canvas=Image.new('RGB',(W,H),(232,237,249));d=ImageDraw.Draw(canvas);m=int(W*.065)
   inset=int(W*.012);d.rounded_rectangle((inset,inset,W-inset,H-inset),radius=int(W*.035),fill=(243,246,253))
   # Decorative tint stays inside the rounded marketing panel.
   d.rounded_rectangle((W*.66,inset,W-inset,H*.31),radius=int(W*.035),fill=(224,232,255))
   icon=Image.open(R/'apple/Apps/iOS/Assets.xcassets/AppIcon.appiconset/AppIcon-1024.png').convert('RGB');s=int(W*(.028 if family=='macos' else .045));icon=icon.resize((s,s),Image.Resampling.LANCZOS);iconMask=Image.new('L',(s,s));ImageDraw.Draw(iconMask).rounded_rectangle((0,0,s-1,s-1),radius=int(s*.22),fill=255);canvas.paste(icon,(m,int(H*.035)),iconMask)
   textblock(d,'eSemnBun',(m+s+20,int(H*.038)),int(W*.026),W*.5,(34,51,85),True)
   headline,sub=COPY[lang]['steps'][index]
   size=int(W*(.061 if family in ('iphone','duo-compact') else .044 if family=='ipad' else .037));top=int(H*(.13 if family=='duo-expanded' else .105 if family=='macos' else .09))
   y=textblock(d,headline,(m,top),size,W-2*m,(22,39,73),True)
   y=textblock(d,sub,(m,y+int(H*.012)),int(size*.43),W-2*m,(65,80,110))
   image=device_frame(Image.open(path),family);box=(W-2*m,H-y-int(H*.085));scale=min(box[0]/image.width,box[1]/image.height)
   iw,ih=int(image.width*scale),int(image.height*scale);image=image.resize((iw,ih),Image.Resampling.LANCZOS);corner=int(min(iw,ih)*(.03 if family=='macos' else .045));mask=Image.new('L',(iw,ih));ImageDraw.Draw(mask).rounded_rectangle((0,0,iw-1,ih-1),radius=corner,fill=255);originalAlpha=image.getchannel('A');from PIL import ImageChops;image.putalpha(originalAlpha if family in ('iphone','duo-compact','duo-expanded') else ImageChops.multiply(originalAlpha,mask));x=(W-iw)//2;iy=y+int(H*.025)
   shadow=Image.new('RGBA',canvas.size)
   if family in ('iphone','duo-compact','duo-expanded'):shadow.paste((30,50,100,70),(x,iy,x+iw,iy+ih),image.getchannel('A'))
   else:ImageDraw.Draw(shadow).rounded_rectangle((x-8,iy-8,x+iw+8,iy+ih+8),radius=32,fill=(30,50,100,70))
   shadow=shadow.filter(ImageFilter.GaussianBlur(22));canvas=Image.alpha_composite(canvas.convert('RGBA'),shadow);canvas.paste(image,(x,iy),image);d=ImageDraw.Draw(canvas)
   textblock(d,COPY[lang]['foot'],(m,H-int(H*.035)),max(22,int(W*.015)),W-2*m,(75,89,115))
   target=pathlib.Path(a.supplemental_output) if family.startswith('duo-') and a.supplemental_output else out
   dest=target/lang/family/path.name;dest.parent.mkdir(parents=True,exist_ok=True);canvas.convert('RGB').save(dest,optimize=True)
   capture=provenance.get(str(path.relative_to(raw)),{})
   manifest.append({'sourceRuntime':capture.get('runtimeVersion'),'sourceSDKVersion':capture.get('sdkVersion'),'captureBackend':capture.get('captureBackend'),'path':str(dest.relative_to(target)),'source':str(path),'sourceSha256':hashlib.sha256(path.read_bytes()).hexdigest(),'dimensions':[W,H],'locale':lang,'family':family,'story':index+1,'format':'RGB PNG','uiAltered':False,'presentation':('unaltered official Apple product PNG frame with exact native display fit; opaque rounded marketing panel' if family in ('iphone','duo-compact','duo-expanded') else 'rounded native screenshot; opaque rounded marketing panel'),'deviceFrame':frame_resource(family)[2] if family in ('iphone','duo-compact','duo-expanded') else None})
official=[item for item in manifest if not item['family'].startswith('duo-')]
(out/'manifest.json').write_text(json.dumps(official if a.supplemental_output else manifest,ensure_ascii=False,indent=2)+'\n')
if a.supplemental_output:
 supplemental=pathlib.Path(a.supplemental_output);supplemental.mkdir(parents=True,exist_ok=True)
 (supplemental/'manifest.json').write_text(json.dumps({'classification':'iPhone-Duo-App-Store-device-slot-compact-and-expanded','assets':[item for item in manifest if item['family'].startswith('duo-')]},ensure_ascii=False,indent=2)+'\n')
print(f'Rendered {len(manifest)} store screenshots')
