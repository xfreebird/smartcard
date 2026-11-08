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
body=urllib.request.urlopen(url,timeout=180).read()
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
