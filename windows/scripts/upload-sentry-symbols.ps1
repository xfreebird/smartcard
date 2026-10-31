param(
    [Parameter(Mandatory=$true)][string]$SymbolsPath,
    [string]$SentryCli = 'sentry-cli',
    [string]$Project = 'esemnbun-windows'
)
$ErrorActionPreference = 'Stop'
if (-not $env:SENTRY_AUTH_TOKEN) { throw 'Set SENTRY_AUTH_TOKEN through the CI secret store.' }
if (-not (Test-Path -LiteralPath $SymbolsPath)) { throw 'SymbolsPath does not exist.' }
# Only upload assemblies/PDBs. Never recurse over documents, logs or the private bridge identity.
$staging = Join-Path ([IO.Path]::GetTempPath()) ('esemnbun-symbols-' + [guid]::NewGuid())
New-Item -ItemType Directory -Path $staging | Out-Null
try {
    Get-ChildItem -LiteralPath $SymbolsPath -Recurse -File |
        Where-Object { $_.Extension -in '.pdb', '.dll', '.exe' } |
        ForEach-Object {
            $relative = [IO.Path]::GetRelativePath((Resolve-Path -LiteralPath $SymbolsPath).Path, $_.FullName)
            $destination = Join-Path $staging $relative
            New-Item -ItemType Directory -Force -Path (Split-Path $destination) | Out-Null
            Copy-Item -LiteralPath $_.FullName -Destination $destination
        }
    & $SentryCli --url https://de.sentry.io debug-files upload --org personal-kee --project $Project $staging
    if ($LASTEXITCODE -ne 0) { throw 'Sentry debug-symbol upload failed.' }
} finally { Remove-Item -LiteralPath $staging -Recurse -Force }
