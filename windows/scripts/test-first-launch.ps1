# Native app first/manual launch with fresh isolated storage, no mock/force-show switches, no signing actions.
param([Parameter(Mandatory=$true)][string]$App,[Parameter(Mandatory=$true)][string]$Output)
$ErrorActionPreference='Stop'
Add-Type -AssemblyName UIAutomationClient
Add-Type -AssemblyName UIAutomationTypes
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
foreach($name in 'MSIGN_TEST_PREFERENCES','MSIGN_DEMO_CARDS','MSIGN_DEMO_PAGE','MSIGN_DEMO_PIN_ONLY','MSIGN_DEMO_READY_FILE','MSIGN_DEMO_SELECTED','MSIGN_DEMO_DARK') {
    $original[$name]=[Environment]::GetEnvironmentVariable($name)
    [Environment]::SetEnvironmentVariable($name,$null)
}
$profile=Join-Path $Output ('fresh-profile-'+[Guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Force $profile | Out-Null
$preferences=Join-Path $profile 'settings.json'
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
        $state=Get-Content $preferences -Raw | ConvertFrom-Json
        if(-not $state.FirstRunDone) {throw 'First launch did not persist completion in the isolated profile.'}
        Stop-Process -Id $process.Id -Force
        $process.WaitForExit(3000) | Out-Null
    }
    @{FreshProfileShowsWindow=$true;SubsequentOrdinaryLaunchShowsWindow=$true;NoForcedUiArguments=$true;
      NoDemoOrPinPreviewFlags=$true;IsolatedStorage=$true;SigningOrPinActions=$false} |
        ConvertTo-Json | Set-Content (Join-Path $Output 'ordinary-first-launch-proof.json') -Encoding UTF8
} finally {
    if($null -ne $process -and -not $process.HasExited) {Stop-Process -Id $process.Id -Force}
    foreach($name in $original.Keys) {[Environment]::SetEnvironmentVariable($name,$original[$name])}
    Remove-Item -Recurse -Force $profile -ErrorAction SilentlyContinue
}
