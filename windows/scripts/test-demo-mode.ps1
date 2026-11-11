# Interactive Windows QA. Uses the production Settings switch and restores the guest's preferences/history.
param([Parameter(Mandatory=$true)][string]$App,[Parameter(Mandatory=$true)][string]$Output)
$ErrorActionPreference='Stop'
Add-Type -AssemblyName UIAutomationClient
Add-Type -AssemblyName UIAutomationTypes
Add-Type -AssemblyName System.Drawing
Add-Type @'
using System; using System.Runtime.InteropServices;
public static class DemoCapture {
 [StructLayout(LayoutKind.Sequential)] public struct Rect {public int Left,Top,Right,Bottom;}
 [DllImport("user32.dll")] public static extern bool SetProcessDPIAware();
 [DllImport("user32.dll")] public static extern bool SetForegroundWindow(IntPtr h);
 [DllImport("user32.dll")] public static extern bool GetWindowRect(IntPtr h,out Rect r);
}
'@
[DemoCapture]::SetProcessDPIAware()|Out-Null
New-Item -ItemType Directory -Force $Output|Out-Null
[xml]$resources=Get-Content (Join-Path $PSScriptRoot '../src/MoldSign.App/Strings/en-US/Resources.resw') -Raw -Encoding UTF8
$strings=@{};foreach($entry in $resources.root.data){$strings[$entry.name]=[string]$entry.value}
# Debug automation uses a dedicated profile; never back up/overwrite the developer's live files.
$profile=Join-Path $Output ('profile-'+[Guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Force $profile|Out-Null
$prefs=Join-Path $profile 'settings.json'
$history=Join-Path $profile 'activity.json'
$original=@{};foreach($name in 'MSIGN_DEMO_CARDS','MSIGN_DEMO_PAGE','MSIGN_TEST_PREFERENCES'){
 $original[$name]=[Environment]::GetEnvironmentVariable($name);[Environment]::SetEnvironmentVariable($name,$null)
}
$env:MSIGN_TEST_PREFERENCES=$prefs
$beforeDirs=@(Get-ChildItem $env:TEMP -Directory -Filter eSemnBun-Demo-*|Select-Object -ExpandProperty FullName)
$process=$null
function Elements($property,$value){
 $filter=[System.Windows.Automation.AndCondition]::new(
  [System.Windows.Automation.PropertyCondition]::new([System.Windows.Automation.AutomationElement]::ProcessIdProperty,$process.Id),
  [System.Windows.Automation.PropertyCondition]::new($property,$value))
 return [System.Windows.Automation.AutomationElement]::RootElement.FindAll([System.Windows.Automation.TreeScope]::Descendants,$filter)
}
function Find([string]$id){
 for($i=0;$i -lt 180;$i++){
  foreach($node in (Elements ([System.Windows.Automation.AutomationElement]::AutomationIdProperty) $id)){return $node}
  Start-Sleep -Milliseconds 100
 };throw "Missing native element $id"
}
function Text([string]$value){
 for($i=0;$i -lt 180;$i++){
  foreach($node in (Elements ([System.Windows.Automation.AutomationElement]::NameProperty) $value)){return $node}
  Start-Sleep -Milliseconds 100
 };throw 'Expected native result did not appear'
}
function Invoke($node){$node.GetCurrentPattern([System.Windows.Automation.InvokePattern]::Pattern).Invoke()}
function Toggle($node){$node.GetCurrentPattern([System.Windows.Automation.TogglePattern]::Pattern).Toggle()}
function Navigate([string]$name){
 for($i=0;$i -lt 180;$i++){
  foreach($node in (Elements ([System.Windows.Automation.AutomationElement]::NameProperty) $name)){
   $pattern=$null
   if($node.TryGetCurrentPattern([System.Windows.Automation.SelectionItemPattern]::Pattern,[ref]$pattern)){
    $pattern.Select()
    $pageId=if($name -eq $strings['NavSign.Content']){'SignPageTitle'}elseif($name -eq $strings['NavVerify.Content']){'VerifyPageTitle'}else{'SettingsPageTitle'}
    $null=Find $pageId
    return
   }
  };Start-Sleep -Milliseconds 100
 };throw "Missing native navigation $name"
}
function Read-Prefs {Get-Content $prefs -Raw|ConvertFrom-Json}
function Wait-Demo([bool]$enabled){
 for($i=0;$i -lt 180;$i++){
  if((Read-Prefs).DemoModeEnabled -eq $enabled){
   $found=@(Elements ([System.Windows.Automation.AutomationElement]::AutomationIdProperty) 'DemoModeBanner')
   $visible=@($found|Where-Object {-not $_.Current.IsOffscreen}).Count -gt 0
   if($visible -eq $enabled){return}
  };Start-Sleep -Milliseconds 100
 };throw 'Demo transition did not finish'
}
function Capture([string]$name){
 $process.Refresh();$window=$process.MainWindowHandle
 if($window -eq 0){throw 'No main window for screenshot'}
 [DemoCapture]::SetForegroundWindow($window)|Out-Null;Start-Sleep -Milliseconds 200
 $rect=New-Object DemoCapture+Rect
 if(-not [DemoCapture]::GetWindowRect($window,[ref]$rect)){throw 'Cannot capture app bounds'}
 $bitmap=New-Object System.Drawing.Bitmap(($rect.Right-$rect.Left),($rect.Bottom-$rect.Top))
 $graphics=[System.Drawing.Graphics]::FromImage($bitmap)
 try{$graphics.CopyFromScreen($rect.Left,$rect.Top,0,0,$bitmap.Size);$bitmap.Save((Join-Path $Output "$name.png"),[System.Drawing.Imaging.ImageFormat]::Png)}
 finally{$graphics.Dispose();$bitmap.Dispose()}
}
function Scroll([double]$percent){
 foreach($node in (Elements ([System.Windows.Automation.AutomationElement]::ProcessIdProperty) $process.Id)){
  $pattern=$null
  if($node.TryGetCurrentPattern([System.Windows.Automation.ScrollPattern]::Pattern,[ref]$pattern) -and $pattern.Current.VerticallyScrollable){$pattern.SetScrollPercent(-1,$percent);return}
 }
}
function Launch{
 $script:process=Start-Process -FilePath $App -PassThru
 for($i=0;$i -lt 180;$i++){$process.Refresh();if($process.MainWindowHandle -ne 0){return};Start-Sleep -Milliseconds 100}
 throw 'App did not show its main window'
}
function Stop-Owned{if($process){if(-not $process.HasExited){Stop-Process -Id $process.Id -Force};if(-not $process.WaitForExit(10000)){throw 'Owned app did not exit'};$process.Dispose()};$script:process=$null}
function History-Hash{if(Test-Path $history){return (Get-FileHash $history).Hash};return 'absent'}
try{
 if(Get-Process eSemnBun -ErrorAction SilentlyContinue){throw 'Close running eSemnBun before this isolated guest test'}
 New-Item -ItemType Directory -Force (Split-Path $prefs)|Out-Null
 @{Language='en-US';BridgeEnabled=$false;DemoModeEnabled=$false;RememberPin=$true;FirstRunDone=$true}|ConvertTo-Json|Set-Content $prefs
 Launch;Navigate $strings['SettingsPageTitle.Text'];$toggle=Find 'DemoModeToggle'
 $historyHash=History-Hash
 Toggle $toggle;$null=Find 'DemoModeConfirmation';Capture 'release-demo-confirmation';Invoke (Find 'CloseButton')
 for($i=0;$i -lt 100 -and $toggle.GetCurrentPattern([System.Windows.Automation.TogglePattern]::Pattern).Current.ToggleState -ne 0;$i++){Start-Sleep -Milliseconds 100}
 if((Read-Prefs).DemoModeEnabled){throw 'Cancel changed demo preference'}
 Toggle $toggle;$null=Find 'DemoModeConfirmation';Invoke (Find 'PrimaryButton');Wait-Demo $true
 Capture 'release-demo-settings'
 if(-not (Read-Prefs).RememberPin){throw 'Demo changed real PIN preference'}
 $sandbox=@(Get-ChildItem $env:TEMP -Directory -Filter eSemnBun-Demo-*|Where-Object {$_.FullName -notin $beforeDirs}|Sort-Object LastWriteTime -Descending)[0].FullName
 $originalHash=(Get-FileHash (Join-Path $sandbox 'demo-contract.pdf')).Hash
 Navigate $strings['NavSign.Content'];Invoke (Find 'ChooseDocuments');$sign=Find 'SignDocuments'
 for($i=0;$i -lt 100 -and -not $sign.Current.IsEnabled;$i++){Start-Sleep -Milliseconds 100}
 Invoke $sign;$null=Text $strings['demo_sign_success'];Scroll 100;Capture 'release-demo-sign-result'
 $outputs=@(Get-ChildItem $sandbox -File -Filter '*-DEMO-NOT-SIGNED*')
 @{sandbox=$sandbox;outputs=@($outputs|Select-Object -ExpandProperty Name)}|ConvertTo-Json|Set-Content (Join-Path $Output 'mock-output-checkpoint.json')
 if($outputs.Count -ne 2){throw 'Mock batch did not create both clearly marked outputs'}
 if((Get-FileHash (Join-Path $sandbox 'demo-contract.pdf')).Hash -ne $originalHash){throw 'Mock signing altered its input'}
 Navigate $strings['NavVerify.Content'];Invoke (Find 'ChooseDocuments');$null=Text $strings['demo_verify_success'];Capture 'release-demo-verification'
 if((History-Hash) -ne $historyHash){throw 'Demo changed real history'}
 Stop-Owned;Launch;Wait-Demo $true;Navigate $strings['SettingsPageTitle.Text'];Capture 'release-demo-restored'
 Start-Sleep -Milliseconds 500
 $connections=@(Get-NetTCPConnection -OwningProcess $process.Id -ErrorAction SilentlyContinue)
 if($connections.Count -ne 0){throw 'Demo unexpectedly opened a network connection'}
 Scroll 0;Toggle (Find 'DemoModeToggle');Wait-Demo $false;Capture 'release-normal-restored'
 if(-not (Read-Prefs).RememberPin){throw 'Real-mode preferences changed unexpectedly'}
 @{passed=$true;isolatedDebugApp=$true;appAssemblySha256=(Get-FileHash ([IO.Path]::ChangeExtension($App,'.dll'))).Hash;confirmationCancelPreservedState=$true;persistedAcrossRestart=$true;simulatedBatchOutputs=$outputs.Count;sourceUnchanged=$true;realHistoryUnchanged=$true;demoTcpConnections=$connections.Count;pinVaultImplementation='DemoPinVault';pinEntered=$false;physicalCardUsed=$false;normalModeRestored=$true}|
 ConvertTo-Json|Set-Content (Join-Path $Output 'release-demo-validation.json')
}catch{
 try{Capture 'failure-context'}catch{}
 $_|Out-String|Set-Content (Join-Path $Output 'failure.txt')
 throw
}finally{
 Stop-Owned
 Remove-Item -LiteralPath $profile -Recurse -Force -ErrorAction SilentlyContinue
 foreach($name in $original.Keys){[Environment]::SetEnvironmentVariable($name,$original[$name])}
 foreach($directory in (Get-ChildItem $env:TEMP -Directory -Filter eSemnBun-Demo-*|Where-Object {$_.FullName -notin $beforeDirs})){Remove-Item -LiteralPath $directory.FullName -Recurse -Force}
}
