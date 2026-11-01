#!/usr/bin/env python3
"""Fill an exported Partner Center CSV with localized text and current screenshots."""
import argparse,csv,json,shutil
from pathlib import Path
p=argparse.ArgumentParser();p.add_argument('--template',type=Path,required=True);p.add_argument('--pack',type=Path,required=True);p.add_argument('--output',type=Path,required=True);a=p.parse_args()
root=Path(__file__).resolve().parents[1];a.output.mkdir(parents=True,exist_ok=True)
rows=list(csv.reader(a.template.open(encoding='utf-8-sig')))
rows[0]=rows[0][:4]+['ro-ro','en-us','ru-ru']
for row in rows[1:]:
 row[:]=row[:3]+['']*4
 for col,loc in enumerate(('ro','en','ru'),4):
  d=json.loads((root/'microsoft/listings'/f'{loc}.json').read_text());field=row[0]
  value={'Description':d['description'],'ReleaseNotes':d['releaseNotes'],'Title':d['name'],'ShortTitle':d['name'],'ShortDescription':d['shortDescription'],'DevStudio':'Nicolae Ghimbovschi','CopyrightTrademarkInformation':'2026 Nicolae Ghimbovschi'}.get(field,'')
  for prefix,key in [('Feature','features'),('SearchTerm','searchTerms')]:
   if field.startswith(prefix) and field[len(prefix):].isdigit():
    i=int(field[len(prefix):])-1;value=d[key][i] if i<len(d[key]) else ''
  if field.startswith('DesktopScreenshotCaption'):
   i=int(field.removeprefix('DesktopScreenshotCaption'))-1;captions=json.loads((a.pack/f'microsoft/assets/{loc}/captions.json').read_text());value=captions[i] if i<len(captions) else ''
  elif field.startswith('DesktopScreenshot'):
   i=int(field.removeprefix('DesktopScreenshot'))-1;images=sorted((a.pack/f'microsoft/assets/{loc}').glob('*.png'))
   if i<len(images):
    rel=Path('images')/loc/images[i].name;dest=a.output/rel;dest.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(images[i],dest)
    # Partner Center requires the selected root folder name in asset paths.
    value=(Path(a.output.name)/rel).as_posix()
  row[col]=value
with (a.output/'listings.csv').open('w',encoding='utf-8-sig',newline='') as f:csv.writer(f).writerows(rows)
print(a.output/'listings.csv')
