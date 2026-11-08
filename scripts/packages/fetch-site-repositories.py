#!/usr/bin/env python3
"""Fetch the release's digest-verified, signed package feeds for Pages."""
import hashlib,io,json,subprocess,sys,tarfile,tempfile,urllib.request
from pathlib import Path
release=json.load(open(sys.argv[1]));name='esemnbun-package-repositories.tar.gz'
a=next((a for a in release['assets'] if a['name']==name),None)
if a is None:
 print('Package feeds not published for this release yet.');raise SystemExit(0)
url=f'https://github.com/xfreebird/smartcard/releases/download/{release["tag_name"]}/{name}'
assert a['browser_download_url']==url
body=subprocess.check_output(['gh','api',a['url'],'-H','Accept: application/octet-stream'])
assert a.get('digest')=='sha256:'+hashlib.sha256(body).hexdigest(),'Repository archive digest mismatch'
root=Path(__file__).resolve().parents[2]
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
 destination=root/'website/static/packages'
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
index=destination/'index.html'
index.write_text(index.read_text().replace('@VERSION@',release['tag_name'].removeprefix('v')))
