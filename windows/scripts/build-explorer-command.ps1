param([ValidateSet('x64','arm64')][string]$Platform = 'x64', [string]$OutputDirectory)
$ErrorActionPreference = 'Stop'
if (!$OutputDirectory) { $OutputDirectory = Join-Path $PSScriptRoot '../artifacts/shell' }
$version = '20261020'
$cache = Join-Path $env:LOCALAPPDATA "eSemnBun/llvm-mingw-$version"
$root = Join-Path $cache "llvm-mingw-$version-ucrt-x86_64"
if (!(Test-Path (Join-Path $root 'bin/clang++.exe'))) {
    New-Item -ItemType Directory -Force $cache | Out-Null
    $archive = Join-Path $cache 'toolchain.zip'
    Invoke-WebRequest "https://github.com/mstorsjo/llvm-mingw/releases/download/$version/llvm-mingw-$version-ucrt-x86_64.zip" -OutFile $archive
    if ((Get-FileHash $archive -Algorithm SHA256).Hash -ne 'FD5462B7F5D93B2FF981FCD3F9C7E427E47F3203C64EA91C27BCC444EEBD74CD') { throw 'Compiler archive checksum mismatch' }
    Expand-Archive $archive $cache -Force
    Remove-Item $archive
}
New-Item -ItemType Directory -Force $OutputDirectory | Out-Null
$target = if ($Platform -eq 'arm64') { 'aarch64' } else { 'x86_64' }
$catalog = Get-Content (Join-Path $PSScriptRoot '../../localization/catalog.json') -Raw -Encoding UTF8 | ConvertFrom-Json
$title = $catalog.entries | Where-Object { $_.platform -eq 'windows' -and $_.key -eq 'Explorer_Sign' }
$verifyTitle = $catalog.entries | Where-Object { $_.platform -eq 'windows' -and $_.key -eq 'Explorer_Verify' }
$signIcon = (Join-Path $PSScriptRoot '../shell/sign.ico').Replace('\','/')
$verifyIcon = (Join-Path $PSScriptRoot '../shell/verify.ico').Replace('\','/')
$rc = '#pragma code_page(65001)' + "`n201 ICON `"$signIcon`"`n202 ICON `"$verifyIcon`"`n"
foreach ($language in @(@('en',9,1),@('ro',24,1),@('ru',25,1))) {
    $value = $title.translations.($language[0]).Replace('"','""')
    $verifyValue = $verifyTitle.translations.($language[0]).Replace('"','""')
    $rc += "LANGUAGE $($language[1]), $($language[2])`nSTRINGTABLE`nBEGIN`n101 `"$value`"`n102 `"$verifyValue`"`nEND`n"
}
$resource = Join-Path $OutputDirectory 'ExplorerStrings.rc'
[IO.File]::WriteAllText($resource, $rc, [Text.UTF8Encoding]::new($false))
& (Join-Path $root "bin/$target-w64-mingw32-windres.exe") -i $resource -o (Join-Path $OutputDirectory 'ExplorerStrings.o')
if ($LASTEXITCODE -ne 0) { throw 'Explorer resource compilation failed' }
& (Join-Path $root "bin/$target-w64-mingw32-clang++.exe") (Join-Path $PSScriptRoot '../shell/ExplorerCommand.cpp') (Join-Path $PSScriptRoot '../shell/ExplorerCommand.def') (Join-Path $OutputDirectory 'ExplorerStrings.o') -shared -static -std=c++17 -O2 '-Wl,--no-insert-timestamp' -o (Join-Path $OutputDirectory 'eSemnBun.Explorer.dll') -lole32 -luuid -lshlwapi -lshell32
if ($LASTEXITCODE -ne 0) { throw 'Explorer command compilation failed' }
