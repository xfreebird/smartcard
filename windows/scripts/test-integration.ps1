param([Parameter(Mandatory=$true)][string]$Output)
$ErrorActionPreference = 'Stop'
if (Test-Path $Output) { throw 'Use a fresh output directory.' }
New-Item -ItemType Directory $Output | Out-Null
$Output = (Resolve-Path $Output).Path
$project = Join-Path $PSScriptRoot '../tests/MoldSign.Core.Tests/MoldSign.Core.Tests.csproj'
& dotnet test $project --logger 'trx;LogFileName=integration.trx' --results-directory $Output 2>&1 |
    Tee-Object -FilePath (Join-Path $Output 'integration.log')
if ($LASTEXITCODE -ne 0) { throw "Integration tests failed with exit code $LASTEXITCODE" }
