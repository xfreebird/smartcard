# DEBUG helper process integration, using injected reader snapshots, mock app UI and isolated preferences.
param([Parameter(Mandatory=$true)][string]$App,
      [Parameter(Mandatory=$true)][string]$Helper,
      [Parameter(Mandatory=$true)][string]$Output)
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'test-environment.ps1')
New-Item -ItemType Directory -Force $Output | Out-Null
$scenario = Join-Path $Output 'reader-snapshots.json'
$preferences = Join-Path $Output 'helper-preferences.json'
$ready = Join-Path $Output 'helper-opened-app.json'
$baseline = Join-Path $Output 'helper-baseline.ready'
$original = @{}
foreach ($name in 'MSIGN_DEMO_CARDS','MSIGN_DEMO_PAGE','MSIGN_DEMO_READY_FILE','MSIGN_DEMO_SELECTED') {
    $original[$name] = [Environment]::GetEnvironmentVariable($name)
}
$children = @()
$helperProcess = $null
function Write-AtomicJson([string]$path, $value) {
    $temporary = $path + '.tmp'
    [IO.File]::WriteAllText($temporary, (ConvertTo-Json -InputObject $value))
    if (Test-Path $path) { [IO.File]::Replace($temporary,$path,($path + '.bak')); Remove-Item ($path + '.bak') -ErrorAction SilentlyContinue } else { [IO.File]::Move($temporary,$path) }
}
function Set-Preferences([bool]$reader, [bool]$card) {
    Write-AtomicJson $preferences @{OpenOnReaderInsertion=$reader;OpenOnCardInsertion=$card}
}
function Wait-App {
    for ($i=0; $i -lt 100; $i++) {
        if (Test-Path $ready) {
            $state = Get-Content $ready -Raw | ConvertFrom-Json
            if ($state.ActualPage -ne 'SignPage') { throw 'Unexpected helper activation target.' }
            return Get-Process -Id $state.ProcessId -ErrorAction Stop
        }
        if ($helperProcess.HasExited) { throw 'Helper exited before insertion activation.' }
        Start-Sleep -Milliseconds 200
    }
    throw 'The helper did not open the closed app after insertion.'
}
try {
    Remove-Item $ready,$baseline -ErrorAction SilentlyContinue
    Write-AtomicJson $scenario @()
    Set-Preferences $true $false
    $env:MSIGN_DEMO_CARDS='none'
    $env:MSIGN_DEMO_PAGE='sign'
    $env:MSIGN_DEMO_READY_FILE=$ready
    $env:MSIGN_DEMO_SELECTED='0'
    $helperProcess = Start-Process $Helper -PassThru -ArgumentList @('--app',('"'+$App+'"'),
        '--scenario-file',('"'+$scenario+'"'),'--settings-file',('"'+$preferences+'"'),'--ready-file',('"'+$baseline+'"'))
    for ($i=0;$i -lt 150 -and -not (Test-Path $baseline);$i++) {
        if ($helperProcess.HasExited) {throw 'Helper exited before baseline initialization.'}
        Start-Sleep -Milliseconds 200
    }
    if (-not (Test-Path $baseline)) {throw 'Helper baseline initialization timed out.'}
    if (Test-Path $ready) { throw 'Starting the helper must not open the app before insertion.' }
    Write-AtomicJson $scenario @(@{Name='Fictional reader';CardPresent=$false;Mute=$false;EventCount=0})
    $first = Wait-App; $children += $first
    $firstId = $first.Id
    if ('CaptureWindow' -as [type]) {
        $state = Get-Content $ready -Raw | ConvertFrom-Json
        $handle = [IntPtr]([long]$state.Window)
        [CaptureWindow]::SetForegroundWindow($handle) | Out-Null
        Start-Sleep -Milliseconds 150
        if ([CaptureWindow]::GetForegroundWindow() -ne $handle) { throw 'First-launch app window is obscured.' }
        $bounds = New-Object CaptureWindow+Rect
        [CaptureWindow]::GetWindowRect($handle,[ref]$bounds) | Out-Null
        $bitmap = New-Object System.Drawing.Bitmap(($bounds.Right-$bounds.Left),($bounds.Bottom-$bounds.Top))
        $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
        try {
            $graphics.CopyFromScreen($bounds.Left,$bounds.Top,0,0,$bitmap.Size)
            $bitmap.Save((Join-Path $Output 'helper-first-launch.png'),[System.Drawing.Imaging.ImageFormat]::Png)
            Copy-Item $ready (Join-Path $Output 'helper-first-launch.json') -Force
        } finally { $graphics.Dispose(); $bitmap.Dispose() }
    }
    Stop-Process -Id $first.Id -Force
    $first.WaitForExit(3000) | Out-Null
    if (-not $first.HasExited) { throw 'First app did not close.' }
    Remove-Item $ready
    Set-Preferences $false $true
    Start-Sleep -Milliseconds 1200
    Write-AtomicJson $scenario @(@{Name='Fictional reader';CardPresent=$true;Mute=$false;EventCount=1})
    $second = Wait-App; $children += $second
    $secondId = $second.Id
    Stop-Process -Id $second.Id -Force
    $second.WaitForExit(3000) | Out-Null
    Set-Preferences $false $false
    if (-not $helperProcess.WaitForExit(5000)) { throw 'Disabling both insertion options must stop the helper.' }
    @{SyntheticReaders=$true;ReaderOpenedClosedApp=$true;CardOpenedClosedApp=$true;
      HelperStoppedWhenDisabled=$true;HelperProcessId=$helperProcess.Id;FirstAppProcessId=$firstId;SecondAppProcessId=$secondId;
      HardwareOrPinUsed=$false} | ConvertTo-Json | Set-Content (Join-Path $Output 'helper-process-proof.json') -Encoding UTF8
} finally {
    foreach ($child in $children) { if (-not $child.HasExited) { Stop-Process -Id $child.Id -Force } }
    if ($null -ne $helperProcess -and -not $helperProcess.HasExited) { Stop-Process -Id $helperProcess.Id -Force }
    foreach ($name in $original.Keys) { Set-TestEnvironmentVariable $name $original[$name] }
}
