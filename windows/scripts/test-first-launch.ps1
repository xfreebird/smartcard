# Native app first/manual launch with fresh isolated storage, no mock/force-show switches, no signing actions.
param([Parameter(Mandatory=$true)][string]$App,[Parameter(Mandatory=$true)][string]$Output)
$ErrorActionPreference='Stop'
. (Join-Path $PSScriptRoot 'test-environment.ps1')
Add-Type -AssemblyName UIAutomationClient
Add-Type -AssemblyName UIAutomationTypes
. (Join-Path $PSScriptRoot 'ui-automation.ps1')
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
$presentReaders=@(Get-PnpDevice -Class SmartCardReader -PresentOnly -ErrorAction SilentlyContinue)
if($presentReaders.Count -gt 0) {throw 'Detach smart-card readers before the isolated ordinary-launch test.'}
$labels=@()
Get-ChildItem (Join-Path $PSScriptRoot '..\src\MoldSign.App\Strings\*\Resources.resw') | ForEach-Object {
    $strings=New-Object System.Xml.XmlDocument
    $strings.Load($_.FullName)
    $node=$strings.SelectSingleNode("/root/data[@name='DropTitle.Text']/value")
    if($null -ne $node) {$labels += $node.InnerText}
}
$original=@{}
foreach($name in 'MSIGN_TEST_PREFERENCES','MSIGN_DEMO_CARDS','MSIGN_DEMO_PAGE','MSIGN_DEMO_PIN_ONLY','MSIGN_DEMO_READY_FILE','MSIGN_DEMO_SELECTED','MSIGN_DEMO_DARK','MSIGN_UI_TEST_SCENARIO','MSIGN_SCREENSHOT_CAPTURE') {
    $original[$name]=[Environment]::GetEnvironmentVariable($name)
    Set-TestEnvironmentVariable $name $null
}
$testProfile=Join-Path $Output ('fresh-profile-'+[Guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Force $testProfile | Out-Null
$preferences=Join-Path $testProfile 'settings.json'
# Network listener off; FirstRunDone is absent (fresh false default), no instruction to open a window.
'{"BridgeEnabled":false}' | Set-Content $preferences -Encoding UTF8
$env:MSIGN_TEST_PREFERENCES=$preferences
$process=$null
try {
    for($launch=0;$launch -lt 2;$launch++) {
        $process=Start-Process -FilePath $App -PassThru
        for($i=0;$i -lt 100;$i++) {
            Start-Sleep -Milliseconds 200
            $process.Refresh()
            if($process.HasExited) {throw 'Ordinary app launch exited before presenting its main window.'}
            if($process.MainWindowHandle -ne 0) {break}
        }
        if($process.MainWindowHandle -eq 0) {throw 'Ordinary launch did not show a main window.'}
        $window=[System.Windows.Automation.AutomationElement]::FromHandle($process.MainWindowHandle)
        if($launch -eq 0) {
            # The first run shows the onboarding dialog; dismiss it so the page itself is checked.
            $dismissed=$false
            # ContentDialog is hosted in a popup and can take longer to initialize on ARM emulation.
            # Search the process's desktop accessibility tree, not only the main window subtree.
            for($i=0;$i -lt 150;$i++) {
                $idCondition=[System.Windows.Automation.PropertyCondition]::new([System.Windows.Automation.AutomationElement]::AutomationIdProperty,'PrimaryButton')
                $processCondition=[System.Windows.Automation.PropertyCondition]::new([System.Windows.Automation.AutomationElement]::ProcessIdProperty,$process.Id)
                $condition=[System.Windows.Automation.AndCondition]::new($idCondition,$processCondition)
                $button=Find-AppAutomationElements $process $condition | Select-Object -First 1
                if($null -ne $button) {
                    [void]$button.GetCurrentPattern([System.Windows.Automation.InvokePattern]::Pattern).Invoke()
                    $dismissed=$true
                    break
                }
                if($dismissed) {break}
                Start-Sleep -Milliseconds 100
            }
            if(-not $dismissed) {throw 'First-run onboarding was not presented for dismissal.'}
            Start-Sleep -Milliseconds 300
        }
        $ready=$false
        for($i=0;$i -lt 50;$i++) {
            foreach($label in $labels) {
                $condition=[System.Windows.Automation.PropertyCondition]::new([System.Windows.Automation.AutomationElement]::NameProperty,$label)
                $text=$window.FindFirst([System.Windows.Automation.TreeScope]::Descendants,$condition)
                if($null -ne $text -and -not $text.Current.IsOffscreen) {$ready=$true;break}
            }
            if($ready) {break}
            Start-Sleep -Milliseconds 100
        }
        if(-not $ready) {throw 'The ordinary first launch did not render the Sign page.'}
        if($launch -eq 0) {
            [CaptureWindow]::SetForegroundWindow($process.MainWindowHandle) | Out-Null
            Start-Sleep -Milliseconds 150
            if([CaptureWindow]::GetForegroundWindow() -ne $process.MainWindowHandle) {throw 'First-launch window is obscured.'}
            $rect=New-Object CaptureWindow+Rect
            [CaptureWindow]::GetWindowRect($process.MainWindowHandle,[ref]$rect) | Out-Null
            $bitmap=New-Object System.Drawing.Bitmap(($rect.Right-$rect.Left),($rect.Bottom-$rect.Top))
            $graphics=[System.Drawing.Graphics]::FromImage($bitmap)
            try {
                $graphics.CopyFromScreen($rect.Left,$rect.Top,0,0,$bitmap.Size)
                $bitmap.Save((Join-Path $Output 'ordinary-first-launch.png'),[System.Drawing.Imaging.ImageFormat]::Png)
            } finally {$graphics.Dispose();$bitmap.Dispose()}
        }
        $persisted=$false
        for($i=0;$i -lt 30;$i++) {
            # The onboarding persists completion asynchronously once dismissed; allow that save to land.
            $state=Get-Content $preferences -Raw | ConvertFrom-Json
            if($state.FirstRunDone) {$persisted=$true;break}
            Start-Sleep -Milliseconds 100
        }
        if(-not $persisted) {throw 'First launch did not persist completion in the isolated profile.'}
        Stop-Process -Id $process.Id -Force
        $process.WaitForExit(3000) | Out-Null
    }
    @{FreshProfileShowsWindow=$true;SubsequentOrdinaryLaunchShowsWindow=$true;NoForcedUiArguments=$true;
      NoDemoOrPinPreviewFlags=$true;IsolatedStorage=$true;SigningOrPinActions=$false} |
        ConvertTo-Json | Set-Content (Join-Path $Output 'ordinary-first-launch-proof.json') -Encoding UTF8
} finally {
    if($null -ne $process -and -not $process.HasExited) {Stop-Process -Id $process.Id -Force}
    foreach($name in $original.Keys) {Set-TestEnvironmentVariable $name $original[$name]}
    Remove-Item -Recurse -Force $testProfile -ErrorAction SilentlyContinue
}
