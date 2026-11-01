#!/usr/bin/env python3
"""Compose Store artwork using exact native app captures and an orthographic cable path."""
import argparse,hashlib,json,math
from pathlib import Path
from PIL import Image,ImageDraw,ImageFilter,ImageFont
from apple_product_frames import device_frame,frame_resource
ROOT=Path(__file__).resolve().parents[2]
p=argparse.ArgumentParser(description=__doc__)
p.add_argument('--raw',type=Path,required=True)
p.add_argument('--output',type=Path,default=ROOT/'distribution/apple/creative/source')
a=p.parse_args();a.output.mkdir(parents=True,exist_ok=True)
W,H=5244,2950

def background():
 small=Image.new('RGB',(640,360));pixels=small.load()
 for y in range(360):
  for x in range(640):
   glow=math.exp(-((x-340)**2/(380**2)+(y-170)**2/(220**2)))
   t=.35*x/639+.65*y/359
   pixels[x,y]=tuple(round(start*(1-t)+end*t+glow*5) for start,end in ((238,201),(243,214),(255,244)))
 return small.resize((W,H),Image.Resampling.BICUBIC).convert('RGBA')

def place(canvas,item,xy,blur=15,opacity=45,offset=(0,12)):
 shadow=Image.new('RGBA',canvas.size)
 alpha=item.getchannel('A').point(lambda v:round(v*opacity/255))
 shadow.paste((24,40,75,255),xy,alpha)
 shadow=shadow.filter(ImageFilter.GaussianBlur(blur))
 shifted=Image.new('RGBA',canvas.size);shifted.alpha_composite(shadow,offset)
 canvas.alpha_composite(shifted);canvas.alpha_composite(item,xy)

def curve(points,p0,p1,p2,p3):
 for step in range(1,81):
  t=step/80;u=1-t
  points.append((u**3*p0[0]+3*u*u*t*p1[0]+3*u*t*t*p2[0]+t**3*p3[0],u**3*p0[1]+3*u*u*t*p1[1]+3*u*t*t*p2[1]+t**3*p3[1]))

# Hardware cutout contains no card or UI. Only native captures supply those pixels.
reader_path=ROOT/'distribution/apple/creative/assets/reader.png'
reader=Image.open(reader_path).convert('RGBA').crop((449,44,1314,977))
reader.putalpha(reader.getchannel('A').point(lambda value:255 if value>200 else value))
reader=reader.resize((round(reader.width*830/reader.height),830),Image.Resampling.LANCZOS)
reader_xy=(3830,1015)
adapter_tip=(reader_xy[0]+reader.width,1420)
phone_xy=(970,150);phone_width=1100;phone_height=round(3000*phone_width/1470)
# The connector and first cable segment share one vertical axis in the image plane.
phone_axis=phone_xy[0]+phone_width/2
phone_port=phone_xy[1]+round(phone_height*2970/3000)
plug_bottom=phone_port+125
wire=[(phone_axis,plug_bottom),(phone_axis,2630)]
curve(wire,wire[-1],(phone_axis,2760),(1630,2780),(1810,2780))
wire.append((4460,2780))
curve(wire,wire[-1],(4780,2780),(4850,2640),(4850,2400))
wire.append((4850,1635))
curve(wire,wire[-1],(4850,1465),(4750,1420),(adapter_tip[0]+95,1420))
def stroke(image,points,color,width):
 draw=ImageDraw.Draw(image);points=[(round(x),round(y)) for x,y in points]
 draw.line(points,fill=color,width=width)
 radius=width/2
 for x,y in points:draw.ellipse((round(x-radius),round(y-radius),round(x+radius),round(y+radius)),fill=color)

catalog=json.loads((ROOT/'localization/catalog.json').read_text())
copy=catalog['storeCreative']
font_regular='/System/Library/Fonts/Supplemental/Arial.ttf'
font_bold='/System/Library/Fonts/Supplemental/Arial Bold.ttf'

def textblock(draw,text,xy,size,width,color,bold=False):
 font=ImageFont.truetype(font_bold if bold else font_regular,size);y=xy[1]
 for paragraph in text.split('\n'):
  line=''
  for word in paragraph.split():
   candidate=(line+' '+word).strip()
   if draw.textlength(candidate,font=font)>width and line:
    draw.text((xy[0],y),line,font=font,fill=color);y+=round(size*1.18);line=word
   else:line=candidate
  draw.text((xy[0],y),line,font=font,fill=color);y+=round(size*1.18)
 return y

manifest=[]
for locale in ('en','ro','ru'):
 screen_path=a.raw/locale/'iphone/02-batch.png'
 card_path=a.raw/locale/'iphone/01-sign.png'
 screen=Image.open(screen_path).convert('RGBA');assert screen.size==(1320,2868)
 card_capture=Image.open(card_path).convert('RGBA');assert card_capture.size==(1320,2868)
 # Exact visible IDCardFace from the single-card capture; no pager overlaps its border.
 card_box=(120,540,1200,1207)
 card=card_capture.crop(card_box)
 mask=Image.new('L',card.size);ImageDraw.Draw(mask).rounded_rectangle((0,0,card.width-1,card.height-1),radius=49,fill=255);card.putalpha(mask)
 card=card.resize((1240,round(1240*card.height/card.width)),Image.Resampling.LANCZOS)
 # IDCardFace places the contact at 85.5%–95.5% of the card width.
 chip=(2800+1240*.855-reader_xy[0],1047+(card.height-1240*.075)/2-reader_xy[1],2800+1240*.955-reader_xy[0],1047+(card.height+1240*.075)/2-reader_xy[1])
 assert reader.getchannel('A').crop(tuple(round(v) for v in chip)).getextrema()[0]>250,'Physical chip must be fully covered by the reader'
 phone=device_frame(screen,'iphone').resize((phone_width,phone_height),Image.Resampling.LANCZOS)
 canvas=background()
 # All cable geometry is drawn top-down, with constant width and no perspective bend.
 shadow=Image.new('RGBA',canvas.size);stroke(shadow,[(x,y+9) for x,y in wire],(20,30,55,65),54);canvas.alpha_composite(shadow.filter(ImageFilter.GaussianBlur(10)))
 stroke(canvas,wire,'#101217',42);stroke(canvas,wire,'#292c33',28);stroke(canvas,[(x-2,y-3) for x,y in wire],'#444852',7);d=ImageDraw.Draw(canvas)
 # A straight USB-C plug seats into the phone; its cable exits vertically downward.
 d.rounded_rectangle((phone_axis-52,phone_port-8,phone_axis+52,plug_bottom),radius=13,fill='#171a20',outline='#444852',width=3)
 d.rectangle((phone_axis-35,phone_port-9,phone_axis+35,phone_port+9),fill='#969ba4')
 d.rounded_rectangle((phone_axis-27,plug_bottom-8,phone_axis+27,plug_bottom+30),radius=10,fill='#22262d')
 # Female extension socket fits over the reader adapter's horizontal USB-C tip.
 place(canvas,card,(2800,1047),blur=11,opacity=45,offset=(0,8))
 place(canvas,reader,reader_xy,blur=12,opacity=35,offset=(0,8))
 ImageDraw.Draw(canvas).rounded_rectangle((adapter_tip[0]-95,adapter_tip[1]-46,adapter_tip[0]+95,adapter_tip[1]+46),radius=16,fill='#191c22',outline='#444852',width=3)
 place(canvas,phone,phone_xy,blur=22,opacity=45,offset=(0,12))
 # Localized marketing copy lives in the same keyed catalog as all store strings.
 d=ImageDraw.Draw(canvas)
 icon=Image.open(ROOT/'apple/Apps/iOS/Assets.xcassets/AppIcon.appiconset/AppIcon-1024.png').convert('RGBA').resize((112,112),Image.Resampling.LANCZOS)
 icon_mask=Image.new('L',icon.size);ImageDraw.Draw(icon_mask).rounded_rectangle((0,0,111,111),radius=26,fill=255);icon.putalpha(icon_mask);canvas.alpha_composite(icon,(2800,190))
 textblock(d,catalog['storeMetadata'][locale]['name'],(2945,197),83,1650,'#243a62',True)
 y=textblock(d,copy['headline'][locale],(2800,365),145,1980,'#1c3055',True)
 y=textblock(d,copy['featureSummary'][locale],(2800,y+42),54,1960,'#405775')
 assert y<970,'Marketing heading must keep a clear margin above the reader'
 for index,key in enumerate(('stepConnect','stepChoose','stepConfirm')):
  y=1930+index*130
  d.ellipse((2800,y+5,2876,y+81),fill='#3157db')
  f=ImageFont.truetype(font_bold,43);label=str(index+1);box=d.textbbox((0,0),label,font=f)
  d.text((2838-(box[2]-box[0])/2,y+15),label,font=f,fill='white')
  end=textblock(d,copy[key][locale],(2920,y+13),54,1770,'#263d61')
  assert end<y+125,'Usage step must stay within its row'
 textblock(d,copy['keyPrivacy'][locale],(2800,2385),48,1900,'#526582')
 dest=a.output/f'{locale}.png';canvas.convert('RGB').save(dest,optimize=True)
 manifest.append({'locale':locale,'path':dest.name,'dimensions':[W,H],'phoneScreenshot':str(screen_path.relative_to(a.raw)),'phoneScreenshotSha256':hashlib.sha256(screen_path.read_bytes()).hexdigest(),'cardScreenshot':str(card_path.relative_to(a.raw)),'cardCrop':card_box,'cardScreenshotSha256':hashlib.sha256(card_path.read_bytes()).hexdigest(),'deviceFrame':frame_resource('iphone')[2],'readerAssetSha256':hashlib.sha256(reader_path.read_bytes()).hexdigest(),'marketingCopySource':'localization/catalog.json/storeCreative','physicalChipCovered':True,'cable':'orthographic: vertical USB-C exit, straight down segment, then rightward curve','sha256':hashlib.sha256(dest.read_bytes()).hexdigest()})
(a.output/'composition-manifest.json').write_text(json.dumps(manifest,ensure_ascii=False,indent=2)+'\n')
print('Composed three localized images from exact native app screenshots and ID-card crops')
