#!/usr/bin/env python3
"""Crop unused iPad canvas and build evidence; never retouch native UI or fictional data."""
import argparse,hashlib,json,runpy
from pathlib import Path
from PIL import Image
ROOT=Path(__file__).resolve().parents[2]
p=argparse.ArgumentParser();p.add_argument('raw_ipad');p.add_argument('phone_manifest');p.add_argument('ipad_manifest');args=p.parse_args()
layout=runpy.run_path(str(Path(__file__).with_name('generate-apple-mobile-guides.py')))
crops=layout['IPAD_CROPS'];records=[]
for form,manifest_path in [('iphone',args.phone_manifest),('ipad',args.ipad_manifest)]:
 manifest=json.loads(Path(manifest_path).read_text())
 for row in manifest['records']:
  path=ROOT/f'website/static/img/guide/{form}'/row['locale']/(row['name']+'.png')
  raw=(Path(args.raw_ipad)/row['locale']/(row['name']+'.png')) if form=='ipad' else path
  assert hashlib.sha256(raw.read_bytes()).hexdigest()==row['sha256'],raw
  im=Image.open(raw);source_size=list(im.size);box=None
  if form=='ipad' and row['name'] in crops:
   l,t,r,b=crops[row['name']];box=[round(l*im.width),round(t*im.height),round(r*im.width),round(b*im.height)];im=im.crop(box);im.save(path,optimize=True)
  records.append({**row,'platform':form,'device':manifest['device'],'binarySha256':manifest['binarySha256'],'sourceDimensions':source_size,'cropPixels':box,'dimensions':list(im.size),'path':str(path.relative_to(ROOT)),'assetSha256':hashlib.sha256(path.read_bytes()).hexdigest()})
result={'date':'2026-11-08','sourceCommit':'b60af1e59d1da8205bde4de20f2947ea9440090d','configuration':'Debug arm64 iOS Simulator; Xcode27.1 RC build','runtime':'iOS27.0','captureHost':'MacBook Air','mock':True,'theme':'light','isolation':'MSIGN_QA_NO_HARDWARE + md.esemnbun.qa.* isolated preferences + MSIGN_SCREENSHOT_CAPTURE; native demo banner absent','method':'simctl fixture launch, stdout readiness marker, native PNG screenshot; untouched screenshots except declared iPad crop of unused canvas or focus on a sheet','rawOriginals':'capture host /tmp/esemnbun-guide-mobile/{iphone,ipad}/','limitations':['Fictional identity and result fixtures, not proof of real card signing or saved-credential access.','Browser remains offline and navigation disabled in isolated fixture mode; production steps checked in source.','Siri, Shortcuts execution, Spotlight indexing and cross-device Handoff were source-reviewed, not exercised end-to-end.','iPad is native portrait with expanded side-by-side workspace; no landscape, split-view or drag/drop validation claimed.','PIN fields contain no PIN; no real reader, credential provider or trust-service operation used.'],'records':records}
(ROOT/'docs/user-guide/apple-mobile-evidence.json').write_text(json.dumps(result,ensure_ascii=False,indent=2)+'\n')
print('Validated',len(records),'native images; crops and hashes recorded.')
