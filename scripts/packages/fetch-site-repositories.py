#!/usr/bin/env python3
"""Fetch the release's digest-verified, signed package feeds for Pages."""
import argparse,hashlib,io,json,subprocess,tarfile,tempfile
from pathlib import Path
root=Path(__file__).resolve().parents[2]
parser=argparse.ArgumentParser(description=__doc__)
parser.add_argument('release',type=Path)
parser.add_argument('--destination',type=Path,default=root/'website/static/packages')
args=parser.parse_args()
release=json.loads(args.release.read_text());name='esemnbun-package-repositories.tar.gz'
def complete(r):
 names={a['name'] for a in r['assets']}
 return not r.get('draft') and not r.get('prerelease') and name in names and 'esemnbun-package-definitions.zip' in names and any(n.endswith('.nupkg') for n in names)
# Partial platform releases must not remove the last working public package feeds.
releases=json.loads(subprocess.check_output(['gh','api','repos/xfreebird/smartcard/releases?per_page=100']))
if not complete(release):
 release=next((r for r in releases if complete(r)),None)
 if release is None:
  print('No complete package release is available yet.');raise SystemExit(0)
a=next(a for a in release['assets'] if a['name']==name)
url=f'https://github.com/xfreebird/smartcard/releases/download/{release["tag_name"]}/{name}'
assert a['browser_download_url']==url
body=subprocess.check_output(['gh','api',a['url'],'-H','Accept: application/octet-stream'])
assert a.get('digest')=='sha256:'+hashlib.sha256(body).hexdigest(),'Repository archive digest mismatch'
with tempfile.TemporaryDirectory() as tmp:
 staging=Path(tmp)
 with tarfile.open(fileobj=io.BytesIO(body),mode='r:gz') as archive:
  assert all(m.name=='packages' or m.name.startswith('packages/') for m in archive.getmembers())
  archive.extractall(staging,filter='data')
 keyring=staging/'trusted.gpg'
 subprocess.run(['gpg','--batch','--dearmor','--output',str(keyring),str(root/'distribution/packages/signing-key.asc')],check=True)
 repo=staging/'packages'
 for signature,payload in [('apt/dists/stable/Release.gpg','apt/dists/stable/Release'),('rpm/x86_64/repodata/repomd.xml.asc','rpm/x86_64/repodata/repomd.xml')]:
  subprocess.run(['gpgv','--keyring',str(keyring),str(repo/signature),str(repo/payload)],check=True)
 import shutil
 destination=args.destination
 if destination.exists():shutil.rmtree(destination)
 shutil.copytree(repo,destination)
 shutil.copyfile(root/'distribution/packages/index.html',destination/'index.html')
print('Verified signed package repositories staged for Pages')

for asset in release['assets']:
 if asset['name'].endswith('.nupkg') or asset['name']=='esemnbun-package-definitions.zip':
  data=subprocess.check_output(['gh','api',asset['url'],'-H','Accept: application/octet-stream'])
  assert asset.get('digest')=='sha256:'+hashlib.sha256(data).hexdigest()
  (destination/'downloads'/release['tag_name']/asset['name']).write_bytes(data)

import zipfile
with zipfile.ZipFile(destination/'downloads'/release['tag_name']/'esemnbun-package-definitions.zip') as z:
 (destination/'PKGBUILD').write_bytes(z.read('arch/PKGBUILD'))
shutil.copyfile(root/'spec/mcp.md',destination/'mcp.md')
(root/'website/src/data/package-release.json').write_text(json.dumps({'version':release['tag_name'].removeprefix('v')})+'\n')
index=destination/'index.html'
index.write_text(index.read_text().replace('@VERSION@',release['tag_name'].removeprefix('v')))

# Keep two previous published versions available while package-manager caches refresh.
previous=[r for r in releases if complete(r) and r['tag_name']!=release['tag_name']][:2]
for older in previous:
 asset=next(a for a in older['assets'] if a['name']==name)
 data=subprocess.check_output(['gh','api',asset['url'],'-H','Accept: application/octet-stream'])
 assert asset.get('digest')=='sha256:'+hashlib.sha256(data).hexdigest()
 prefix='packages/downloads/'+older['tag_name']+'/'
 with tarfile.open(fileobj=io.BytesIO(data),mode='r:gz') as archive:
  for member in archive.getmembers():
   if member.isfile() and member.name.startswith(prefix) and '/' not in member.name[len(prefix):]:
    target=destination/'downloads'/older['tag_name']/Path(member.name).name
    target.parent.mkdir(parents=True,exist_ok=True)
    target.write_bytes(archive.extractfile(member).read())
