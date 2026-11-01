<#
.SYNOPSIS
    Builds the eSemnBun Windows release artifacts into dist/windows: MSI + MSIX per platform, the winget manifests
    and SHA256SUMS.txt (WIN-08, WIN-09, CLI-04). Public name eSemnBun; codename MoldSign in projects and IDs.

.DESCRIPTION
    Runs on Windows only (the WinUI XAML compiler, MakePri, Native AOT, WiX and signtool are Windows tools):

      1. CLI      dotnet publish src/MoldSign.Cli, Native AOT (esemnbun.exe) -> windows/artifacts/package/<rid>/cli
      2. App      dotnet publish src/MoldSign.App, self-contained,
                  unpackaged (eSemnBun.exe, the MSI payload)           -> windows/artifacts/package/<rid>/app
      3. Sign     our own executables/assemblies, before they go into the MSI (optional, see SIGNING)
      4. MSI      installer/MoldSign.Installer.wixproj (WiX v5)        -> dist/windows/eSemnBun-<v>-<arch>.msi (signed)
      5. MSIX     single-project MSIX of src/MoldSign.App              -> dist/windows/eSemnBun-<v>-<arch>.msix (signed)
      6. winget   installer/winget/*.yaml with the MSI's URL, SHA-256
                  and ProductCode                                      -> dist/windows/winget/<v>/

SIGNING
    Only environment variables are read; no certificate, key or password ever lives in the repository.
    Without any of them the artifacts are unsigned (CI default): fine for inspection, but an unsigned MSIX
    cannot be installed (use -SelfSignForTesting, or sign it).

      MOLDSIGN_SIGN_THUMBPRINT   SHA-1 thumbprint of a code-signing certificate already in Cert:\CurrentUser\My or
                                 Cert:\LocalMachine\My (e.g. imported by the CI job from a secret, or on a token)
      MOLDSIGN_TIMESTAMP_URL     RFC 3161 server for the thumbprint mode (default http://timestamp.digicert.com)

      Azure Trusted Signing (used instead of the thumbprint when MOLDSIGN_TS_ENDPOINT is set):
      MOLDSIGN_TS_ENDPOINT       e.g. https://weu.codesigning.azure.net
      MOLDSIGN_TS_ACCOUNT        Trusted Signing account name
      MOLDSIGN_TS_PROFILE        certificate profile name
      MOLDSIGN_TS_DLIB           path to Azure.CodeSigning.Dlib.dll (NuGet package Microsoft.Trusted.Signing.Client,
                                 bin\x64)
      AZURE_TENANT_ID, AZURE_CLIENT_ID, AZURE_CLIENT_SECRET   picked up by the dlib (DefaultAzureCredential)

      MSIX identity (Package.appxmanifest placeholders, restored after the build):
      MOLDSIGN_MSIX_IDENTITY     package name (Partner Center Package/Identity/Name for the Store); default NicolaeGhimbovschi.eSemnBun
      MOLDSIGN_MSIX_PUBLISHER    must equal the signing certificate's Subject; default: the thumbprint certificate's
                                 Subject, else the verified Partner Center publisher
      MOLDSIGN_MSIX_PUBLISHER_DISPLAY_NAME   the publisher's own display name (default Nicolae Ghimbovschi)

.PARAMETER Version
    Product version (major.minor.patch). Default: <Version> of windows/Directory.Build.props (0.2.0).

.PARAMETER Platforms
    x64 (default) and/or arm64. arm64 needs the MSVC ARM64 build tools for the Native AOT CLI.

.PARAMETER ReleaseBaseUrl
    Where the MSI will be downloaded from, for the winget InstallerUrl
    (e.g. https://github.com/<owner>/<repo>/releases/download/v0.2.0). Without it the URL token stays in the manifest.

.PARAMETER SelfSignForTesting
    Creates a throwaway code-signing certificate in Cert:\CurrentUser\My for the MSIX publisher, signs with it and
    exports only its public part (dist/windows/eSemnBun-test-signing.cer) so a test machine can trust it.

.EXAMPLE
    pwsh windows/scripts/package-windows.ps1

.EXAMPLE
    $env:MOLDSIGN_SIGN_THUMBPRINT = '<thumbprint>'
    pwsh windows/scripts/package-windows.ps1 -Version 0.2.0 -Platforms x64,arm64 `
        -ReleaseBaseUrl https://github.com/<owner>/<repo>/releases/download/v0.2.0
#>
#Requires -Version 7.2
[CmdletBinding()]
param(
    [string] $Version,
    [string] $StorePackageVersion,
    [ValidateSet('x64', 'arm64')]
    [string[]] $Platforms = @('x64'),
    [string] $Configuration = 'Release',
    [string] $ReleaseBaseUrl,
    [switch] $SkipMsi,
    [switch] $SkipMsix,
    [switch] $SelfSignForTesting
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

if (-not $IsWindows) { throw 'package-windows.ps1 runs on Windows only (WinUI, MakePri, Native AOT, WiX, signtool).' }

$WindowsDir = Split-Path -Parent $PSScriptRoot
$RepoRoot = Split-Path -Parent $WindowsDir
$Dist = Join-Path $RepoRoot 'dist/windows'
$Staging = Join-Path $WindowsDir 'artifacts/package'
$AppProject = Join-Path $WindowsDir 'src/MoldSign.App/MoldSign.App.csproj'
$WatcherProject = Join-Path $WindowsDir 'src/MoldSign.Watcher/MoldSign.Watcher.csproj'
$HelperPayload = Join-Path $WindowsDir 'src/MoldSign.App/HelperPayload'
$BuildProps = Join-Path $WindowsDir 'Directory.Build.props'
$CliProject = Join-Path $WindowsDir 'src/MoldSign.Cli/MoldSign.Cli.csproj'
$Installer = Join-Path $WindowsDir 'installer/MoldSign.Installer.wixproj'
$Manifest = Join-Path $WindowsDir 'src/MoldSign.App/Package.appxmanifest'
$WingetTemplates = Join-Path $WindowsDir 'installer/winget'

function Invoke-Tool {
    param([Parameter(Mandatory)] [string] $FilePath, [string[]] $Arguments = @())
    Write-Host "> $FilePath $($Arguments -join ' ')" -ForegroundColor DarkGray
    & $FilePath @Arguments
    if ($LASTEXITCODE -ne 0) { throw "$FilePath failed with exit code $LASTEXITCODE" }
}

function Get-ProjectVersion {
    $xml = [xml](Get-Content -Raw $BuildProps)
    $node = $xml.SelectSingleNode('/Project/PropertyGroup/Version')
    if ($null -eq $node) { throw "No <Version> in $BuildProps" }
    return $node.InnerText.Trim()
}

function Find-SignTool {
    $packages = if ($env:NUGET_PACKAGES) { $env:NUGET_PACKAGES } else { Join-Path $HOME '.nuget/packages' }
    $roots = @(
        (Join-Path $packages 'microsoft.windows.sdk.buildtools'),   # restored by the app build
        (Join-Path ${env:ProgramFiles(x86)} 'Windows Kits/10/bin')    # Windows SDK
    )
    $found = foreach ($root in $roots) {
        if (Test-Path $root) {
            Get-ChildItem $root -Recurse -Filter signtool.exe -ErrorAction SilentlyContinue |
                Where-Object { $_.Directory.Name -eq 'x64' }
        }
    }
    $tool = $found | Sort-Object FullName -Descending | Select-Object -First 1
    if ($null -eq $tool) { throw 'signtool.exe not found (Windows SDK or the Microsoft.Windows.SDK.BuildTools package)' }
    return $tool.FullName
}

function Get-SigningMode {
    if ($env:MOLDSIGN_TS_ENDPOINT) { return 'trusted-signing' }
    if ($env:MOLDSIGN_SIGN_THUMBPRINT) { return 'thumbprint' }
    if ($SelfSignForTesting) { return 'self-signed' }
    return 'none'
}

function Get-CertificateSubject([string] $Thumbprint) {
    $cert = Get-ChildItem Cert:\CurrentUser\My, Cert:\LocalMachine\My -ErrorAction SilentlyContinue |
        Where-Object { $_.Thumbprint -eq $Thumbprint } | Select-Object -First 1
    if ($null -eq $cert) { throw "Code-signing certificate $Thumbprint is not in CurrentUser\My or LocalMachine\My" }
    return $cert.Subject
}

function New-TestSigningCertificate([string] $Subject) {
    $cert = New-SelfSignedCertificate -Type Custom -Subject $Subject -KeyUsage DigitalSignature `
        -FriendlyName 'eSemnBun test signing (local only)' -CertStoreLocation 'Cert:\CurrentUser\My' `
        -TextExtension @('2.5.29.37={text}1.3.6.1.5.5.7.3.3', '2.5.29.19={text}') -NotAfter (Get-Date).AddDays(30)
    # Public part only: import it into Local Machine > Trusted People on the test machine to install the MSIX.
    Export-Certificate -Cert $cert -FilePath (Join-Path $Dist 'eSemnBun-test-signing.cer') | Out-Null
    return $cert.Thumbprint
}

function Invoke-Sign([string[]] $Files) {
    $Files = @($Files | Where-Object { $_ -and (Test-Path $_) })
    if ($Files.Count -eq 0) { return }
    switch ($script:SigningMode) {
        'none' {
            Write-Host "  unsigned: $($Files | ForEach-Object { Split-Path -Leaf $_ })" -ForegroundColor Yellow
        }
        'thumbprint' {
            $timestamp = if ($env:MOLDSIGN_TIMESTAMP_URL) { $env:MOLDSIGN_TIMESTAMP_URL } else { 'http://timestamp.digicert.com' }
            Invoke-Tool $script:SignTool (@('sign', '/sha1', $env:MOLDSIGN_SIGN_THUMBPRINT, '/fd', 'SHA256',
                '/tr', $timestamp, '/td', 'SHA256', '/d', 'eSemnBun') + $Files)
        }
        'trusted-signing' {
            foreach ($name in 'MOLDSIGN_TS_ACCOUNT', 'MOLDSIGN_TS_PROFILE', 'MOLDSIGN_TS_DLIB') {
                if (-not [Environment]::GetEnvironmentVariable($name)) { throw "Azure Trusted Signing needs $name" }
            }
            # Names only (no secrets): the dlib authenticates with the AZURE_* environment variables.
            $metadata = Join-Path ([IO.Path]::GetTempPath()) "moldsign-trusted-signing-$PID.json"
            @{
                Endpoint               = $env:MOLDSIGN_TS_ENDPOINT
                CodeSigningAccountName = $env:MOLDSIGN_TS_ACCOUNT
                CertificateProfileName = $env:MOLDSIGN_TS_PROFILE
            } | ConvertTo-Json | Set-Content -Path $metadata -Encoding utf8NoBOM
            try {
                Invoke-Tool $script:SignTool (@('sign', '/v', '/fd', 'SHA256', '/tr', 'http://timestamp.acs.microsoft.com',
                    '/td', 'SHA256', '/dlib', $env:MOLDSIGN_TS_DLIB, '/dmdf', $metadata) + $Files)
            }
            finally {
                Remove-Item $metadata -ErrorAction SilentlyContinue
            }
        }
        'self-signed' {
            Invoke-Tool $script:SignTool (@('sign', '/sha1', $script:SelfSignedThumbprint, '/fd', 'SHA256') + $Files)
        }
    }
}

function Get-MsiProperty([string] $Path, [string] $Name) {
    $installer = New-Object -ComObject WindowsInstaller.Installer
    $database = $installer.GetType().InvokeMember('OpenDatabase', 'InvokeMethod', $null, $installer, @($Path, 0))
    $view = $database.GetType().InvokeMember('OpenView', 'InvokeMethod', $null, $database,
        @("SELECT ``Value`` FROM ``Property`` WHERE ``Property`` = '$Name'"))
    $view.GetType().InvokeMember('Execute', 'InvokeMethod', $null, $view, $null) | Out-Null
    $record = $view.GetType().InvokeMember('Fetch', 'InvokeMethod', $null, $view, $null)
    $value = $record.GetType().InvokeMember('StringData', 'GetProperty', $null, $record, 1)
    $view.GetType().InvokeMember('Close', 'InvokeMethod', $null, $view, $null) | Out-Null
    return $value
}

function Set-MsixIdentity([string] $Name, [string] $Publisher, [string] $PackageVersion, [string] $PublisherDisplayName) {
    $xml = [xml]::new()
    $xml.PreserveWhitespace = $true
    $xml.Load($Manifest)
    $ns = [Xml.XmlNamespaceManager]::new($xml.NameTable)
    $ns.AddNamespace('m', 'http://schemas.microsoft.com/appx/manifest/foundation/windows10')
    $identity = $xml.SelectSingleNode('/m:Package/m:Identity', $ns)
    $identity.SetAttribute('Name', $Name)
    $identity.SetAttribute('Publisher', $Publisher)
    $identity.SetAttribute('Version', $PackageVersion)
    $xml.SelectSingleNode('/m:Package/m:Properties/m:PublisherDisplayName', $ns).InnerText = $PublisherDisplayName
    $xml.Save($Manifest)
}

# --- Setup ----------------------------------------------------------------------------------------------------

if (-not $Version) { $Version = Get-ProjectVersion }
if ($Version -notmatch '^\d+\.\d+\.\d+$') { throw "Version must be major.minor.patch, got '$Version'" }
if (-not $StorePackageVersion -and $env:BUILD_NUMBER) {
    if ($env:BUILD_NUMBER -notmatch '^[1-9][0-9]*$' -or [long]$env:BUILD_NUMBER -gt 65535) { throw 'BUILD_NUMBER must be an integer from 1 to 65535 for MSIX' }
    $marketingParts = $Version.Split('.')
    $StorePackageVersion = "$([Math]::Max(1, [int]$marketingParts[0])).$($marketingParts[1]).$($env:BUILD_NUMBER).0"
}
$MsixVersion = if ($StorePackageVersion) { $StorePackageVersion } else { "$Version.0" }
if ($MsixVersion -notmatch '^\d+\.\d+\.\d+\.0$') { throw 'Store package version must contain four numeric parts and end in zero' }
foreach ($part in $MsixVersion.Split('.')) {
    if ([int]$part -gt 65535) { throw 'MSIX version components must not exceed 65535' }
}

New-Item -ItemType Directory -Force -Path $Dist | Out-Null
Get-ChildItem $Dist -Force | Remove-Item -Recurse -Force
New-Item -ItemType Directory -Force -Path $Staging | Out-Null

$script:SigningMode = Get-SigningMode
$script:SignTool = if ($script:SigningMode -ne 'none') { Find-SignTool } else { $null }

$MsixName = if ($env:MOLDSIGN_MSIX_IDENTITY) { $env:MOLDSIGN_MSIX_IDENTITY } else { 'NicolaeGhimbovschi.eSemnBun' }
$MsixPublisher = if ($env:MOLDSIGN_MSIX_PUBLISHER) { $env:MOLDSIGN_MSIX_PUBLISHER }
                 elseif ($script:SigningMode -eq 'thumbprint') { Get-CertificateSubject $env:MOLDSIGN_SIGN_THUMBPRINT }
                 else { 'CN=3AAF334E-BE21-4B3F-8FDE-FBEDDF7498EE' }
$MsixPublisherDisplayName = if ($env:MOLDSIGN_MSIX_PUBLISHER_DISPLAY_NAME) { $env:MOLDSIGN_MSIX_PUBLISHER_DISPLAY_NAME } else { 'Nicolae Ghimbovschi' }
if ($script:SigningMode -eq 'self-signed') { $script:SelfSignedThumbprint = New-TestSigningCertificate $MsixPublisher }

Write-Host "eSemnBun $Version ($($Platforms -join ', ')) - signing: $($script:SigningMode) - MSIX publisher: $MsixPublisher"

# --- Build ----------------------------------------------------------------------------------------------------

$built = @{}
foreach ($platform in $Platforms) {
    $rid = "win-$platform"
    $msbuildPlatform = if ($platform -eq 'arm64') { 'ARM64' } else { 'x64' }
    $appOut = Join-Path $Staging "$rid/app"
    $cliOut = Join-Path $Staging "$rid/cli"
    Remove-Item -Recurse -Force (Join-Path $Staging $rid) -ErrorAction SilentlyContinue

    Write-Host "`n== ${rid}: CLI esemnbun.exe (Native AOT)" -ForegroundColor Cyan
    Invoke-Tool dotnet @('publish', $CliProject, '-c', $Configuration, '-r', $rid, '-p:PublishAot=true',
        "-p:Version=$Version", '-o', $cliOut)

    # Separate self-contained process: no WinUI, card connection, PIN or credential-vault dependency.
    Remove-Item -Recurse -Force $HelperPayload -ErrorAction SilentlyContinue
    Invoke-Tool dotnet @('publish', $WatcherProject, '-c', $Configuration, '-r', $rid,
        '--self-contained', '-p:PublishSingleFile=true', "-p:Version=$Version", '-o', $HelperPayload)
    Get-ChildItem $HelperPayload -Recurse -Filter *.pdb | Remove-Item -Force

    Write-Host "`n== ${rid}: app eSemnBun.exe (self-contained, unpackaged)" -ForegroundColor Cyan
    & (Join-Path $PSScriptRoot 'build-explorer-command.ps1') -Platform $platform -OutputDirectory (Join-Path (Split-Path $AppProject) 'ShellPayload')
    Invoke-Tool dotnet @('publish', $AppProject, '-c', $Configuration, '-r', $rid, "-p:Platform=$msbuildPlatform",
        '--self-contained', '-p:WindowsPackageType=None', "-p:Version=$Version", '-o', $appOut)
    Get-ChildItem $appOut, $cliOut -Recurse -Filter *.pdb | Remove-Item -Force
    if (-not (Test-Path (Join-Path $appOut 'Assets/Tray/tray-connected-dark.ico'))) {
        throw "The tray icons are missing from $appOut (Content items of MoldSign.App)"
    }
    Invoke-Sign @((Join-Path $appOut 'eSemnBun.exe'), (Join-Path $appOut 'eSemnBun.dll'),
        (Join-Path $appOut 'eSemnBun.Explorer.dll'),
        (Join-Path $appOut 'MoldSign.Core.dll'), (Join-Path $cliOut 'esemnbun.exe'), (Join-Path $appOut 'helper/eSemnBun.Watcher.exe'))

    if (-not $SkipMsi) {
        Write-Host "`n== ${rid}: MSI (WiX v5)" -ForegroundColor Cyan
        $msiOut = Join-Path $Staging "$rid/msi"
        Invoke-Tool dotnet @('build', $Installer, '-c', $Configuration, "-p:InstallerPlatform=$platform",
            "-p:ProductVersion=$Version", "-p:AppDir=$appOut", "-p:CliDir=$cliOut", "-p:OutputPath=$msiOut/")
        $msi = Join-Path $Dist "eSemnBun-$Version-$platform.msi"
        Copy-Item (Join-Path $msiOut "eSemnBun-$Version-$platform.msi") $msi
        Invoke-Sign @($msi)
        $built["msi-$platform"] = $msi
    }

    if (-not $SkipMsix) {
        Write-Host "`n== ${rid}: MSIX (single-project)" -ForegroundColor Cyan
        $msixOut = Join-Path $Staging "$rid/msix"
        $backup = "$Manifest.orig"
        Copy-Item $Manifest $backup -Force
        try {
            Set-MsixIdentity -Name $MsixName -Publisher $MsixPublisher -PackageVersion $MsixVersion `
                -PublisherDisplayName $MsixPublisherDisplayName
            # --no-incremental: the obj folder was just used by the unpackaged publish above.
            Invoke-Tool dotnet @('build', $AppProject, '-c', $Configuration, '-r', $rid, "-p:Platform=$msbuildPlatform",
                '--self-contained', '--no-incremental', '-p:WindowsPackageType=MSIX', '-p:GenerateAppxPackageOnBuild=true',
                '-p:AppxPackageSigningEnabled=false', "-p:Version=$Version", "-p:AppxPackageDir=$msixOut/")
        }
        finally {
            Move-Item $backup $Manifest -Force
        }
        $package = Get-ChildItem $msixOut -Recurse -Filter *.msix | Sort-Object LastWriteTime -Descending | Select-Object -First 1
        if ($null -eq $package) { throw "No .msix under $msixOut" }
        $msix = Join-Path $Dist "eSemnBun-$Version-$platform.msix"
        Copy-Item $package.FullName $msix
        Invoke-Sign @($msix)
        $built["msix-$platform"] = $msix
    }
}

# --- winget manifests (x64 MSI) -------------------------------------------------------------------------------

if ($built.ContainsKey('msi-x64')) {
    Write-Host "`n== winget manifests" -ForegroundColor Cyan
    $msi = $built['msi-x64']
    $tokens = [ordered]@{
        '__VERSION__'               = $Version
        '__RELEASE_DATE__'          = (Get-Date -Format 'yyyy-MM-dd')
        '__MSI_X64_SHA256__'        = (Get-FileHash $msi -Algorithm SHA256).Hash
        '__MSI_X64_PRODUCT_CODE__'  = (Get-MsiProperty $msi 'ProductCode')
    }
    if ($ReleaseBaseUrl) { $tokens['__MSI_X64_URL__'] = "$($ReleaseBaseUrl.TrimEnd('/'))/$(Split-Path -Leaf $msi)" }
    $wingetOut = Join-Path $Dist "winget/$Version"
    New-Item -ItemType Directory -Force -Path $wingetOut | Out-Null
    foreach ($template in Get-ChildItem $WingetTemplates -Filter *.yaml) {
        $text = Get-Content -Raw $template.FullName
        foreach ($token in $tokens.Keys) { $text = $text.Replace($token, [string]$tokens[$token]) }
        Set-Content -Path (Join-Path $wingetOut $template.Name) -Value $text -Encoding utf8NoBOM -NoNewline
    }
    $left = Select-String -Path (Join-Path $wingetOut '*.yaml') -Pattern '__[A-Z0-9_]+__' -AllMatches |
        ForEach-Object { $_.Matches.Value } | Sort-Object -Unique
    if ($left) { Write-Host "  still to fill before submitting: $($left -join ', ')" -ForegroundColor Yellow }
}

# --- Checksums ------------------------------------------------------------------------------------------------

$sums = Get-ChildItem $Dist -File | Where-Object { $_.Extension -in '.msi', '.msix' } | Sort-Object Name |
    ForEach-Object { '{0}  {1}' -f (Get-FileHash $_.FullName -Algorithm SHA256).Hash.ToLowerInvariant(), $_.Name }
Set-Content -Path (Join-Path $Dist 'SHA256SUMS.txt') -Value $sums -Encoding ascii

Write-Host "`nDone: $Dist" -ForegroundColor Green
Get-ChildItem $Dist -Recurse -File | ForEach-Object { '  {0,12:N0}  {1}' -f $_.Length, $_.FullName.Substring($Dist.Length + 1) }

Remove-Item -Recurse -Force $HelperPayload -ErrorAction SilentlyContinue
