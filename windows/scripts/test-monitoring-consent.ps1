# Run in the interactive Windows desktop. Every change is made through native consent/Settings controls.
param([Parameter(Mandatory=$true)][string]$App,[Parameter(Mandatory=$true)][string]$Output,[switch]$SendVerification)
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName UIAutomationClient
Add-Type -AssemblyName UIAutomationTypes
Add-Type -AssemblyName System.Drawing
Add-Type @'
using System;
using System.Runtime.InteropServices;
public static class ConsentWindowCapture {
    [DllImport("user32.dll")] public static extern bool SetProcessDPIAware();
    [StructLayout(LayoutKind.Sequential)] public struct Rect { public int Left, Top, Right, Bottom; }
    [DllImport("user32.dll")] public static extern bool SetForegroundWindow(IntPtr window);
    [DllImport("user32.dll")] public static extern bool GetWindowRect(IntPtr window, out Rect rect);
}
'@
[ConsentWindowCapture]::SetProcessDPIAware()|Out-Null
New-Item -ItemType Directory -Force $Output | Out-Null
$proof = Join-Path $Output 'current-state.json'
$prefs = Join-Path $Output 'preferences.json'
$original = @{}
foreach($name in 'MSIGN_DEMO_CARDS','MSIGN_DEMO_PAGE','MSIGN_TEST_PREFERENCES','MSIGN_MONITORING_PROOF_FILE','MSIGN_SENTRY_VERIFY') {
    $original[$name] = [Environment]::GetEnvironmentVariable($name)
}
Remove-Item Env:MSIGN_DEMO_CARDS -ErrorAction SilentlyContinue
$env:MSIGN_DEMO_PAGE='settings'
$env:MSIGN_TEST_PREFERENCES=$prefs;$env:MSIGN_MONITORING_PROOF_FILE=$proof
Remove-Item Env:MSIGN_SENTRY_VERIFY -ErrorAction SilentlyContinue
$process=$null
function Wait-State([bool]$decided,[bool]$crash,[bool]$metrics,[bool]$sdk) {
    for($i=0;$i -lt 180;$i++) {
        if(Test-Path $proof) {
            try {
                $state=Get-Content $proof -Raw | ConvertFrom-Json
                if($state.ProcessId -eq $process.Id -and $state.DecisionMade -eq $decided -and
                    $state.CanSendCrash -eq $crash -and $state.CanSendMetrics -eq $metrics -and $state.SdkEnabled -eq $sdk) {return $state}
            } catch {}
        }
        Start-Sleep -Milliseconds 100
    }
    throw 'Monitoring state did not match expected native consent.'
}
function Find-Id([string]$id) {
    $condition=[System.Windows.Automation.AndCondition]::new(
        [System.Windows.Automation.PropertyCondition]::new([System.Windows.Automation.AutomationElement]::AutomationIdProperty,$id),
        [System.Windows.Automation.PropertyCondition]::new([System.Windows.Automation.AutomationElement]::ProcessIdProperty,$process.Id))
    $root=[System.Windows.Automation.AutomationElement]::RootElement
    for($i=0;$i -lt 180;$i++) {
        $node=$root.FindFirst([System.Windows.Automation.TreeScope]::Descendants,$condition)
        if($node -and $node.Current.ProcessId -eq $process.Id){return $node}
        Start-Sleep -Milliseconds 100
    }
    throw "Missing native consent element $id"
}
function Toggle($node) {$node.GetCurrentPattern([System.Windows.Automation.TogglePattern]::Pattern).Toggle()}
function Invoke($node) {$node.GetCurrentPattern([System.Windows.Automation.InvokePattern]::Pattern).Invoke()}
function Capture([string]$name) {
    $process.Refresh()
    $window=$process.MainWindowHandle
    if($window -eq 0){throw 'Missing visible app window for consent capture'}
    [ConsentWindowCapture]::SetForegroundWindow($window)|Out-Null
    Start-Sleep -Milliseconds 200
    $rect=New-Object ConsentWindowCapture+Rect
    if(-not [ConsentWindowCapture]::GetWindowRect($window,[ref]$rect)){throw 'Cannot read consent capture bounds'}
    $bitmap=New-Object System.Drawing.Bitmap(($rect.Right-$rect.Left),($rect.Bottom-$rect.Top))
    $graphics=[System.Drawing.Graphics]::FromImage($bitmap)
    try {
        $graphics.CopyFromScreen($rect.Left,$rect.Top,0,0,$bitmap.Size)
        $bitmap.Save((Join-Path $Output "$name.png"),[System.Drawing.Imaging.ImageFormat]::Png)
    } finally {$graphics.Dispose();$bitmap.Dispose()}
}
function Reveal-Settings {
    $root=[System.Windows.Automation.AutomationElement]::RootElement
    $condition=[System.Windows.Automation.PropertyCondition]::new([System.Windows.Automation.AutomationElement]::ProcessIdProperty,$process.Id)
    foreach($node in $root.FindAll([System.Windows.Automation.TreeScope]::Descendants,$condition)) {
        $pattern=$null
        if($node.TryGetCurrentPattern([System.Windows.Automation.ScrollPattern]::Pattern,[ref]$pattern) -and $pattern.Current.VerticallyScrollable) {
            $pattern.SetScrollPercent(-1,75)
            return
        }
    }
}
function Navigate-Settings {
    $filter=[System.Windows.Automation.AndCondition]::new(
        [System.Windows.Automation.PropertyCondition]::new([System.Windows.Automation.AutomationElement]::ProcessIdProperty,$process.Id),
        [System.Windows.Automation.PropertyCondition]::new([System.Windows.Automation.AutomationElement]::NameProperty,'Settings'))
    foreach($node in [System.Windows.Automation.AutomationElement]::RootElement.FindAll([System.Windows.Automation.TreeScope]::Descendants,$filter)) {
        $selection=$null
        if($node.TryGetCurrentPattern([System.Windows.Automation.SelectionItemPattern]::Pattern,[ref]$selection)) {
            $selection.Select();$null=Find-Id 'SettingsPageTitle';return
        }
    }
    throw 'Native Settings navigation is unavailable'
}
function Launch {
    Remove-Item $proof -ErrorAction SilentlyContinue
    $script:process=Start-Process -FilePath $App -PassThru
}
function Stop-Owned {
    if($process -and -not $process.HasExited){Stop-Process -Id $process.Id -Force}
    $script:process=$null
}
try {
    # Unknown/first launch: no SDK, both controls off. Decline is an explicit persisted decision.
    @{Language='en-US';BridgeEnabled=$false}|ConvertTo-Json|Set-Content $prefs
    Launch
    $unknown=Wait-State $false $false $false $false
    $dialog=Find-Id 'MonitoringConsentDialog'
    foreach($id in 'MonitoringConsentCrash','MonitoringConsentMetrics') {
        $control=Find-Id $id
        if($control.GetCurrentPattern([System.Windows.Automation.TogglePattern]::Pattern).Current.ToggleState -ne 0){throw 'Consent default must be off'}
    }
    Capture 'first-launch-default-off'
    Invoke (Find-Id 'CloseButton')
    $declined=Wait-State $true $false $false $false
    Stop-Owned
    # Restore the declined state: no prompt, no SDK. Later opt-in/out is through the native Settings toggles.
    Launch
    $restored=Wait-State $true $false $false $false
    Navigate-Settings
    $metricToggle=Find-Id 'MonitoringSettingsMetrics'
    Toggle $metricToggle
    $metricsOnly=Wait-State $true $false $true $true
    Reveal-Settings
    Capture 'settings-metrics-only'
    Toggle $metricToggle
    $optOut=Wait-State $true $false $false $false
    Capture 'settings-opted-out'
    $saved=Get-Content $prefs -Raw|ConvertFrom-Json
    if(-not $saved.MonitoringDecisionMade -or $saved.MonitoringCrashReports -or $saved.MonitoringUsageMetrics){throw 'Opt-out not persisted'}
    Stop-Owned
    @{passed=$true;unknown=$unknown;declined=$declined;restored=$restored;metricsOnly=$metricsOnly;optOut=$optOut;hardwareAccess=$false;pinEntered=$false}|
        ConvertTo-Json -Depth 6|Set-Content (Join-Path $Output 'consent-validation.json')
    if($SendVerification) {
        # QA explicitly chooses both signals in a fresh native prompt; this flag never grants consent itself.
        @{Language='en-US';BridgeEnabled=$false}|ConvertTo-Json|Set-Content $prefs
        $env:MSIGN_SENTRY_VERIFY='1'
        Launch
        $null=Wait-State $false $false $false $false
        $null=Find-Id 'MonitoringConsentDialog'
        Toggle (Find-Id 'MonitoringConsentCrash')
        Toggle (Find-Id 'MonitoringConsentMetrics')
        Invoke (Find-Id 'PrimaryButton')
        if(-not $process.WaitForExit(60000)){throw 'Consented verification did not finish'}
        if($process.ExitCode -ne 0){throw 'Consented verification failed'}
        @{passed=$true;app='WinUI';explicitNativeConsent=$true;exitCode=$process.ExitCode;hardwareAccess=$false;pinEntered=$false}|
            ConvertTo-Json|Set-Content (Join-Path $Output 'verification-validation.json')
    }
} finally {
    Stop-Owned
    foreach($name in $original.Keys){[Environment]::SetEnvironmentVariable($name,$original[$name])}
}
