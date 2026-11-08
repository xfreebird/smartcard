$ErrorActionPreference = 'Stop'
if (-not [Environment]::Is64BitOperatingSystem) { throw 'eSemnBun CLI requires 64-bit Windows.' }
$toolsDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
Install-ChocolateyZipPackage -PackageName 'esemnbun-cli' -Url64bit 'https://github.com/xfreebird/smartcard/releases/download/v0.2.6/esemnbun-cli-0.2.6-windows-x64.zip' -Checksum64 '9f8a3189792917c065717861f4ae09f208bd9a547f6fc610bd2fe75ccb7b9231' -ChecksumType64 'sha256' -UnzipLocation $toolsDir
