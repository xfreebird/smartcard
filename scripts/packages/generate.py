#!/usr/bin/env python3
"""Generate CLI package-manager definitions from immutable release asset digests."""
import argparse, hashlib, json, re
from pathlib import Path
from xml.sax.saxutils import escape

p=argparse.ArgumentParser();p.add_argument('release',type=Path);p.add_argument('--out',type=Path,required=True);a=p.parse_args()
r=json.loads(a.release.read_text());v=r['tag_name'].removeprefix('v')
if not re.fullmatch(r'\d+\.\d+\.\d+',v) or r.get('draft') or r.get('prerelease'):p.error('Expected stable published release')
assets={x['name']:x for x in r['assets']}
def asset(name):
 x=assets[name];url=x['browser_download_url'];digest=x.get('digest','')
 if url!=f'https://github.com/xfreebird/smartcard/releases/download/v{v}/{name}' or not re.fullmatch(r'sha256:[0-9a-f]{64}',digest):raise ValueError('Untrusted asset URL or missing digest: '+name)
 return f'https://esemnbun.md/packages/downloads/v{v}/{name}',digest[7:]
def write(name,s):
 f=a.out/name;f.parent.mkdir(parents=True,exist_ok=True);f.write_text(s)
mac,mh=asset(f'esemnbun-{v}-macos-universal.tar.gz')
win,wh=asset(f'esemnbun-cli-{v}-windows-x64.zip')
linux,lh=asset(f'esemnbun-{v}-linux-x86_64.tar.gz')
write('esemnbun-cli.rb',f'''class EsemnbunCli < Formula
  desc "Electronic ID signing and local MCP command-line tools"
  homepage "https://esemnbun.md"
  url "{mac}"
  version "{v}"
  sha256 "{mh}"
  license "MIT"

  depends_on :macos
  on_macos do
    depends_on macos: :sequoia
  end

  def install
    bin.install "esemnbun", "esemnbun-mcp"
  end

  def caveats
    <<~EOS
      MCP runs over stdio: esemnbun-mcp --root documents=/absolute/path
      Signing requires a compatible reader and card. Unattended signing is opt-in.
      No background service is enabled by this formula.
    EOS
  end

  test do
    assert_match "esemnbun", shell_output("#{{bin}}/esemnbun --version")
  end
end
''')
write('bucket/esemnbun-cli.json',json.dumps({'version':v,'description':'eSemnBun signing CLI and local MCP server','homepage':'https://esemnbun.md','license':'MIT','architecture':{'64bit':{'url':win,'hash':wh}},'bin':'esemnbun.exe','checkver':{'url':'https://esemnbun.md/packages/version.json','jsonpath':'$.version'},'autoupdate':{'architecture':{'64bit':{'url':'https://esemnbun.md/packages/downloads/v$version/esemnbun-cli-$version-windows-x64.zip'}}}},indent=2)+'\n')
write('chocolatey/esemnbun-cli.nuspec',f'''<?xml version="1.0" encoding="utf-8"?>
<package xmlns="http://schemas.microsoft.com/packaging/2015/06/nuspec.xsd"><metadata>
<id>esemnbun-cli</id><version>{v}</version><title>eSemnBun CLI</title>
<authors>Nicolae Ghimbovschi</authors><owners>xfreebird</owners>
<projectUrl>https://esemnbun.md</projectUrl><licenseUrl>https://github.com/xfreebird/smartcard/blob/main/LICENSE</licenseUrl>
<requireLicenseAcceptance>false</requireLicenseAcceptance>
<projectSourceUrl>https://github.com/xfreebird/smartcard</projectSourceUrl>
<bugTrackerUrl>https://github.com/xfreebird/smartcard/issues</bugTrackerUrl>
<tags>esemnbun cli mcp signing smartcard</tags><summary>Electronic ID signing and local MCP CLI</summary>
<description>Sign and verify documents with the Moldovan electronic ID card. Includes a local stdio MCP interface. Card signing requires compatible hardware and explicit authorization. No service or unattended signing is enabled by installation. Windows x64 only.</description>
<releaseNotes>https://github.com/xfreebird/smartcard/releases/tag/v{v}</releaseNotes>
</metadata><files><file src="tools\\**" target="tools" /></files></package>
''')
license_path=Path(__file__).resolve().parents[2]/'LICENSE';license_hash=hashlib.sha256(license_path.read_bytes()).hexdigest()
write('arch/PKGBUILD',f'''# Maintainer: Nicolae Ghimbovschi <xfreebird@gmail.com>
pkgname=esemnbun-cli-bin
pkgver={v}
pkgrel=1
pkgdesc='Electronic ID signing and local MCP command-line tools'
arch=('x86_64')
url='https://esemnbun.md'
license=('MIT')
depends=('glibc>=2.39' 'openssl' 'pcsclite' 'curl')
optdepends=('ccid: USB card reader driver')
provides=('esemnbun-cli')
conflicts=('esemnbun-cli')
source=('{linux}' 'LICENSE::https://esemnbun.md/packages/downloads/v{v}/LICENSE')
sha256sums=('{lh}' '{license_hash}')
package() {{
  install -Dm755 "esemnbun-$pkgver/esemnbun" "$pkgdir/usr/bin/esemnbun"
  install -Dm755 "esemnbun-$pkgver/esemnbun-mcp" "$pkgdir/usr/bin/esemnbun-mcp"
  install -Dm644 "esemnbun-$pkgver/share/moldsign/localhost.p12" "$pkgdir/usr/share/moldsign-cli/localhost.p12"
  install -Dm644 "esemnbun-$pkgver/esemnbun-server.service" "$pkgdir/usr/lib/systemd/user/esemnbun-server.service"
  install -Dm644 LICENSE "$pkgdir/usr/share/licenses/$pkgname/LICENSE"
}}
''')
print('Generated Homebrew, Scoop, Chocolatey and Arch definitions for',v)
