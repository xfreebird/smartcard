# Run in the interactive Windows desktop session; no card, bridge or PIN is used.
param(
    [Parameter(Mandatory=$true)][string]$App,
    [string]$Output = "$env:USERPROFILE\Desktop\esemnbun-screenshots\windows",
    [string[]]$Scenarios = @('none','empty','mute','reading','1','multiple','multiple-second','3','blocked','stuck','signing'),
    [string[]]$Pages = @('sign','card','settings','verify','activity'),
    [string[]]$Themes = @('light','dark'),
    [switch]$PinOnly
)
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing
if (-not ('CaptureWindow' -as [type])) {
Add-Type @'
using System;
using System.Runtime.InteropServices;
public static class CaptureWindow {
    [StructLayout(LayoutKind.Sequential)] public struct Rect { public int Left, Top, Right, Bottom; }
    [DllImport("user32.dll")] public static extern bool GetWindowRect(IntPtr hwnd, out Rect rect);
    [DllImport("user32.dll")] public static extern bool SetForegroundWindow(IntPtr hwnd);
    [DllImport("user32.dll")] public static extern IntPtr GetForegroundWindow();
    [DllImport("user32.dll")] public static extern bool SetProcessDPIAware();
}
'@
}
[CaptureWindow]::SetProcessDPIAware() | Out-Null
New-Item -ItemType Directory -Path $Output -Force | Out-Null
if ($PinOnly) { $Scenarios = @('batch-pin'); $Pages = @('pin') }
$original = @{}
foreach ($name in 'MSIGN_DEMO_CARDS','MSIGN_DEMO_DARK','MSIGN_DEMO_PAGE','MSIGN_DEMO_READY_FILE','MSIGN_DEMO_PIN_ONLY') { $original[$name] = [Environment]::GetEnvironmentVariable($name) }
try {
    foreach ($theme in $Themes) {
        foreach ($scenario in $Scenarios) {
            foreach ($page in $Pages) {
                $env:MSIGN_DEMO_CARDS = $scenario
                $env:MSIGN_DEMO_PIN_ONLY = if ($PinOnly) { '1' } else { $null }
                $env:MSIGN_DEMO_DARK = if ($theme -eq 'dark') { '1' } else { '0' }
                $env:MSIGN_DEMO_PAGE = $page
                $readyFile = Join-Path $env:TEMP ("esemnbun-ready-" + [Guid]::NewGuid().ToString('N') + '.json')
                $env:MSIGN_DEMO_READY_FILE = $readyFile
                $process = Start-Process -FilePath $App -PassThru
                try {
                    for ($i = 0; $i -lt 150; $i++) {
                        Start-Sleep -Milliseconds 200
                        $process.Refresh()
                        if ($process.HasExited) { throw 'Demo app exited before capture.' }
                        if ((Test-Path $readyFile) -and $process.MainWindowHandle -ne 0) { break }
                    }
                    if ($process.MainWindowHandle -eq 0) { throw 'No demo window; run this script in the interactive desktop session.' }
                    if (-not (Test-Path $readyFile)) { throw "Requested page did not render: $scenario/$page/$theme" }
                    $ready = Get-Content $readyFile -Raw | ConvertFrom-Json
                    $expectedPage = @{sign='SignPage';card='CardPage';settings='SettingsPage';verify='VerifyPage';activity='ActivityPage';pin='PinWindow'}[$page]
                    if ($ready.ProcessId -ne $process.Id -or $ready.Page -ne $page -or $ready.ActualPage -ne $expectedPage -or $ready.Scenario -ne $scenario -or -not $ready.CarouselsCentered) {
                        throw "Capture readiness mismatch for $scenario/$page/$theme"
                    }
                    if ($PinOnly -and -not $ready.BlankPin) { throw 'PIN preview must remain empty.' }
                    $captureName = if ($PinOnly) { "batch-pin-$theme" } else { "$scenario-$page-$theme" }
                    $hwnd = [IntPtr]([long]$ready.Window)
                    [CaptureWindow]::SetForegroundWindow($hwnd) | Out-Null
                    Start-Sleep -Milliseconds 150
                    if ([CaptureWindow]::GetForegroundWindow() -ne $hwnd) { throw 'Demo window is not in the foreground; refusing an obscured screenshot.' }
                    $rect = New-Object CaptureWindow+Rect
                    if (-not [CaptureWindow]::GetWindowRect($hwnd,[ref]$rect)) { throw 'Cannot read demo window bounds.' }
                    $bitmap = New-Object System.Drawing.Bitmap(($rect.Right-$rect.Left),($rect.Bottom-$rect.Top))
                    $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
                    try {
                        $graphics.CopyFromScreen($rect.Left,$rect.Top,0,0,$bitmap.Size)
                        $bitmap.Save((Join-Path $Output "$captureName.png"),[System.Drawing.Imaging.ImageFormat]::Png)
                        Copy-Item $readyFile (Join-Path $Output "$captureName.json") -Force
                    } finally { $graphics.Dispose(); $bitmap.Dispose() }
                } finally {
                    if ($PinOnly -and -not $process.HasExited) {
                        $process.CloseMainWindow() | Out-Null
                        $process.WaitForExit(3000) | Out-Null
                    }
                    if (-not $process.HasExited) { Stop-Process -Id $process.Id -Force }
                    Remove-Item $readyFile -ErrorAction SilentlyContinue
                }
            }
        }
    }
} finally {
    foreach ($name in $original.Keys) { [Environment]::SetEnvironmentVariable($name,$original[$name]) }
}
