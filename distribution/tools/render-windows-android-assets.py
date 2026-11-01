#!/usr/bin/env python3
"""Render store promotional artwork from local brand/UI assets; preserve raw screenshots."""
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont, ImageFilter
import json,hashlib
ROOT=Path(__file__).resolve().parents[2]
FONT='/System/Library/Fonts/Supplemental/Arial.ttf';BOLD='/System/Library/Fonts/Supplemental/Arial Bold.ttf'
COPY={
'ro':{'headline':'Semnează simplu.\nPăstrează controlul.','detail':'Documente PDF și XAdES\ncu propriul card de identitate.','captions':['Alege documentul și formatul semnăturii.','Selectează cardul pentru semnare.','Verifică semnăturile documentelor.','Revino la documentele semnate.']},
'en':{'headline':'Sign simply.\nStay in control.','detail':'PDF and XAdES documents\nwith your own identity card.','captions':['Choose a document and signature format.','Select the card used for signing.','Check document signatures.','Return to your signed documents.']},
'ru':{'headline':'Подписывайте\nпод своим контролем.','detail':'Документы PDF и XAdES\nс вашей картой удостоверения личности.','captions':['Выберите документ и формат подписи.','Выберите карту для подписания.','Проверьте подписи документов.','Вернитесь к подписанным документам.']}}
def background(size):
 w,h=size;im=Image.new('RGB',size);px=im.load()
 for y in range(h):
  for x in range(w):
   glow=max(0,1-(((x-w*.82)/(w*.85))**2+((y-h*.25)/(h*1.2))**2))
   px[x,y]=(int(13+22*glow),int(23+28*glow),int(48+57*glow))
 return im
def save(im,path):path.parent.mkdir(parents=True,exist_ok=True);im.convert('RGB').save(path,optimize=True)
BROWSER={'ro':'Folosește cardul pe portaluri compatibile.','en':'Use your card on compatible portals.','ru':'Используйте карту на совместимых порталах.'}
SETTINGS={'ro':'Alege limba, tema și preferințele aplicației.','en':'Choose the app language, theme and preferences.','ru':'Выберите язык, тему и настройки приложения.'}
for lang,c in COPY.items():
 # Google feature graphic: text occupies safe left half, actual UI card is the right-side visual.
 image=background((1024,500));d=ImageDraw.Draw(image)
 d.text((60,45),'eSemnBun',font=ImageFont.truetype(BOLD,24),fill='#B5C8FF')
 font=ImageFont.truetype(BOLD,42 if lang!='ru' else 33)
 d.multiline_text((60,112),c['headline'],font=font,fill='white',spacing=12)
 d.multiline_text((60,300),c['detail'],font=ImageFont.truetype(FONT,21 if lang!='ru' else 17),fill='#DAE3FA',spacing=9)
 source=ROOT/f'distribution/google/assets/android/{lang}/phone/01-sign.png'
 if source.exists():
  ui=Image.open(source).convert('RGB').crop((68,278,1013,870));ui.thumbnail((410,260),Image.Resampling.LANCZOS)
  mask=Image.new('L',ui.size);ImageDraw.Draw(mask).rounded_rectangle((0,0,ui.width-1,ui.height-1),radius=20,fill=255)
  image.paste(ui,(570,124),mask)
 save(image,ROOT/f'distribution/google/assets/android/{lang}/feature-graphic.png')
 (ROOT/f'distribution/google/assets/android/{lang}/captions.json').write_text(json.dumps(c['captions'][:3]+[BROWSER[lang]],ensure_ascii=False,indent=2)+'\n')
 folder=ROOT/f'distribution/microsoft/assets/{lang}';folder.mkdir(parents=True,exist_ok=True)
 (folder/'captions.json').write_text(json.dumps(c['captions'][:3]+[SETTINGS[lang]],ensure_ascii=False,indent=2)+'\n')
# Microsoft hero: no text, app UI, national or device imagery. Document-and-signature motif.
im=background((1920,1080));layer=Image.new('RGBA',im.size);d=ImageDraw.Draw(layer)
d.ellipse((930,-220,2140,990),fill=(82,107,209,35));d.ellipse((-400,400,550,1350),fill=(93,187,221,20))
d.rounded_rectangle((550,125,1265,800),radius=45,fill='#9EAFE8')
d.rounded_rectangle((600,90,1315,765),radius=45,fill='#E9EEFF')
d.rounded_rectangle((650,55,1365,730),radius=45,fill='#FFFFFF')
for y,w in [(160,420),(220,510),(280,465),(340,510),(400,335)]:d.rounded_rectangle((730,y,730+w,y+16),radius=8,fill='#CFD8F2')
# Signature flourish, based on the app's signing/document purpose; no lettering.
d.line([(745,600),(785,556),(814,588),(847,505),(861,629),(905,562),(941,595),(985,560),(1030,580),(1110,555)],fill='#3456C5',width=13,joint='curve')
d.ellipse((1150,490,1440,780),fill='#3456C5');d.line([(1217,634),(1273,689),(1373,580)],fill='white',width=22,joint='curve')
im=Image.alpha_composite(im.convert('RGBA'),layer).convert('RGB');save(im,ROOT/'distribution/microsoft/assets/hero-1920x1080.png')
icon=Image.open(ROOT/'android/design/play-store-icon-512.png').convert('RGB');save(icon,ROOT/'distribution/google/assets/android/app-icon-512.png')
icon=Image.open(ROOT/'windows/src/MoldSign.App/Assets/Square150x150Logo.scale-200.png').convert('RGBA');bg=Image.new('RGBA',icon.size,'#314CD4');bg.alpha_composite(icon);save(bg,ROOT/'distribution/microsoft/assets/app-tile-300.png')
print('Rendered localized feature graphics, captions and text-free Windows hero')
