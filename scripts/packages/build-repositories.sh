#!/usr/bin/env bash
# Build signed CLI-only APT and RPM repositories from verified published assets.
set -euo pipefail
release_json="$1"
repo_out="$2"
: "${GNUPGHOME:?Set an isolated signing key directory}"
: "${PACKAGE_SIGNING_FINGERPRINT:?Set the expected signing fingerprint}"
mkdir -p "$repo_out/apt/pool/main/e/esemnbun-cli" "$repo_out/apt/dists/stable/main/binary-amd64" "$repo_out/rpm/x86_64"
python3 - "$release_json" "$repo_out" <<'PY'
import hashlib,json,re,sys,subprocess
from pathlib import Path
r=json.load(open(sys.argv[1]));v=r['tag_name'].removeprefix('v');out=Path(sys.argv[2])
if not re.fullmatch(r'\d+\.\d+\.\d+',v) or r.get('draft') or r.get('prerelease'):raise SystemExit('Expected stable published release')
for name,folder in [(f'esemnbun-cli_{v}-1_amd64.deb','apt/pool/main/e/esemnbun-cli'),(f'esemnbun-cli-{v}-1.x86_64.rpm','rpm/x86_64')]:
 a=next(x for x in r['assets'] if x['name']==name)
 url=f'https://github.com/xfreebird/smartcard/releases/download/v{v}/{name}'
 if a['browser_download_url']!=url or not re.fullmatch(r'sha256:[0-9a-f]{64}',a.get('digest','')):raise SystemExit('Invalid asset metadata')
 data=subprocess.check_output(['gh','api',a['url'],'-H','Accept: application/octet-stream'])
 if 'sha256:'+hashlib.sha256(data).hexdigest()!=a['digest']:raise SystemExit('Asset digest mismatch: '+name)
 (out/folder/name).write_bytes(data)
downloads=out/'downloads'/r['tag_name'];downloads.mkdir(parents=True,exist_ok=True)
for name in [f'esemnbun-{v}-macos-universal.tar.gz',f'esemnbun-{v}-linux-x86_64.tar.gz',f'esemnbun-cli-{v}-windows-x64.zip']:
 a=next(x for x in r['assets'] if x['name']==name)
 data=subprocess.check_output(['gh','api',a['url'],'-H','Accept: application/octet-stream'])
 assert a.get('digest')=='sha256:'+hashlib.sha256(data).hexdigest()
 (downloads/name).write_bytes(data)
(downloads/'LICENSE').write_bytes(Path('LICENSE').read_bytes())
(out/'version.json').write_text(json.dumps({'version':v}))
PY
gpg --batch --armor --export "$PACKAGE_SIGNING_FINGERPRINT" > "$repo_out/signing-key.asc"
gpg --batch --export "$PACKAGE_SIGNING_FINGERPRINT" > "$repo_out/signing-key.gpg"
(
 cd "$repo_out/apt"
 dpkg-scanpackages --multiversion pool /dev/null > dists/stable/main/binary-amd64/Packages
 gzip -n -9 -c dists/stable/main/binary-amd64/Packages > dists/stable/main/binary-amd64/Packages.gz
 apt-ftparchive -o APT::FTPArchive::Release::Origin=eSemnBun \
   -o APT::FTPArchive::Release::Label=eSemnBun \
   -o APT::FTPArchive::Release::Suite=stable -o APT::FTPArchive::Release::Codename=stable \
   -o APT::FTPArchive::Release::Architectures=amd64 -o APT::FTPArchive::Release::Components=main \
   release dists/stable > dists/stable/Release
 # Refresh weekly; expired metadata is rejected instead of silently trusted forever.
 printf 'Valid-Until: %s\n' "$(date -u -d '+90 days' -R)" >> dists/stable/Release
 gpg --batch --yes --local-user "$PACKAGE_SIGNING_FINGERPRINT" --digest-algo SHA256 --clearsign -o dists/stable/InRelease dists/stable/Release
 gpg --batch --yes --local-user "$PACKAGE_SIGNING_FINGERPRINT" --digest-algo SHA256 --armor --detach-sign -o dists/stable/Release.gpg dists/stable/Release
)
for package in "$repo_out"/rpm/x86_64/*.rpm; do
 rpmsign --define "_gpg_name $PACKAGE_SIGNING_FINGERPRINT" --define "_gpg_path $GNUPGHOME" --define '__gpg /usr/bin/gpg' --addsign "$package"
done
createrepo_c "$repo_out/rpm/x86_64"
gpg --batch --yes --local-user "$PACKAGE_SIGNING_FINGERPRINT" --digest-algo SHA256 --armor --detach-sign "$repo_out/rpm/x86_64/repodata/repomd.xml"
cat > "$repo_out/esemnbun.repo" <<'REPO'
[esemnbun-cli]
name=eSemnBun CLI
baseurl=https://esemnbun.md/packages/rpm/$basearch
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://esemnbun.md/packages/signing-key.asc
REPO
gpg --verify "$repo_out/apt/dists/stable/Release.gpg" "$repo_out/apt/dists/stable/Release"
gpg --verify "$repo_out/rpm/x86_64/repodata/repomd.xml.asc" "$repo_out/rpm/x86_64/repodata/repomd.xml"
printf '%s\n' "$PACKAGE_SIGNING_FINGERPRINT" > "$repo_out/signing-key-fingerprint.txt"
