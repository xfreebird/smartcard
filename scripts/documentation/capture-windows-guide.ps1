param([switch]$VerificationOnly)
$ErrorActionPreference='Stop'
$root="$env:USERPROFILE\esemnbun-windows-guide-screenshots-20261108"
$env:DOTNET_ROOT="$env:USERPROFILE\dotnet-x64";$env:DOTNET_ROOT_X64=$env:DOTNET_ROOT;$env:PATH="$env:DOTNET_ROOT;$env:PATH"
$out=Join-Path $root 'captures';New-Item -ItemType Directory -Force $out|Out-Null
$env:MSIGN_TEST_PREFERENCES=Join-Path $root 'profile\settings.json';New-Item -ItemType Directory -Force (Split-Path $env:MSIGN_TEST_PREFERENCES)|Out-Null
$env:MSIGN_SCREENSHOT_CAPTURE='1'
$app=Join-Path $root 'publish\eSemnBun.exe'
[xml]$resources=Get-Content "$root\windows\src\MoldSign.App\Strings\ro-RO\Resources.resw" -Raw -Encoding UTF8
function L([string]$key){return [string]($resources.resources.data|Where-Object name -eq $key).value}
# .resw root is named root, not resources.
function L([string]$key){return [string]($resources.root.data|Where-Object name -eq $key).value}
Add-Type -AssemblyName System.Drawing;Add-Type -AssemblyName UIAutomationClient;Add-Type -AssemblyName UIAutomationTypes
Add-Type @'
using System;using System.Runtime.InteropServices;
public static class CaptureNative {
 [StructLayout(LayoutKind.Sequential)] public struct Rect {public int Left,Top,Right,Bottom;}
 [DllImport("user32.dll")]public static extern bool GetWindowRect(IntPtr h,out Rect r);
 [DllImport("user32.dll")]public static extern bool MoveWindow(IntPtr h,int x,int y,int w,int z,bool p);
 [DllImport("user32.dll")]public static extern bool SetForegroundWindow(IntPtr h);
 [DllImport("user32.dll")]public static extern IntPtr GetForegroundWindow();
 [DllImport("user32.dll")]public static extern bool SetWindowPos(IntPtr h,IntPtr after,int x,int y,int w,int z,uint f);
 [DllImport("kernel32.dll")]public static extern uint GetCurrentThreadId();
 [DllImport("user32.dll")]public static extern uint GetWindowThreadProcessId(IntPtr h,IntPtr p);
 [DllImport("user32.dll")]public static extern bool AttachThreadInput(uint a,uint b,bool attach);
 [DllImport("user32.dll")]public static extern bool SetProcessDPIAware();
 [DllImport("user32.dll")]public static extern bool SetCursorPos(int x,int y);
 [DllImport("user32.dll")]public static extern void mouse_event(uint f,uint x,uint y,uint d,UIntPtr e);
 public static void Focus(IntPtr h){uint own=GetCurrentThreadId(),other=GetWindowThreadProcessId(GetForegroundWindow(),IntPtr.Zero);bool a=own!=other&&AttachThreadInput(own,other,true);try{SetForegroundWindow(h);}finally{if(a)AttachThreadInput(own,other,false);}}
 public static void Click(int x,int y){SetCursorPos(x,y);mouse_event(2,0,0,0,UIntPtr.Zero);mouse_event(4,0,0,0,UIntPtr.Zero);}
}
'@
[CaptureNative]::SetProcessDPIAware()|Out-Null
$records=[Collections.Generic.List[object]]::new()
if(Test-Path "$out\manifest.json"){(Get-Content "$out\manifest.json" -Raw|ConvertFrom-Json).records|ForEach-Object{$records.Add($_)}}
function Id([string]$id){$ui.FindFirst([System.Windows.Automation.TreeScope]::Descendants,[System.Windows.Automation.PropertyCondition]::new([System.Windows.Automation.AutomationElement]::AutomationIdProperty,$id))}
function Name([string]$name){$ui.FindFirst([System.Windows.Automation.TreeScope]::Descendants,[System.Windows.Automation.PropertyCondition]::new([System.Windows.Automation.AutomationElement]::NameProperty,$name))}
function Nodes {$ui.FindAll([System.Windows.Automation.TreeScope]::Descendants,[System.Windows.Automation.Condition]::TrueCondition)}
function Invoke($node){if($null -eq $node){throw 'Required native UI node absent'};$pat=$null;if($node.TryGetCurrentPattern([System.Windows.Automation.InvokePattern]::Pattern,[ref]$pat)){$pat.Invoke()}else{$b=$node.Current.BoundingRectangle;[CaptureNative]::Click([int]($b.X+$b.Width/2),[int]($b.Y+$b.Height/2))};Start-Sleep -Milliseconds 300}
function Nav([string]$page){$key=@{sign='NavSign.Content';verify='NavVerify.Content';activity='NavActivity.Content';card='NavCard.Content';settings='NavSettings.Content'}[$page];if($page -eq 'settings'){Invoke (Id 'SettingsItem');return};$node=Nodes|Where-Object{$_.Current.ClassName -eq 'Microsoft.UI.Xaml.Controls.NavigationViewItem' -and $_.Current.Name -eq (L $key)}|Select-Object -First 1;Invoke $node}
function Scroll-End {foreach($node in (Nodes)){$pat=$null;if($node.TryGetCurrentPattern([System.Windows.Automation.ScrollPattern]::Pattern,[ref]$pat) -and $pat.Current.VerticallyScrollable){$pat.SetScrollPercent(-1,100)}};Start-Sleep -Milliseconds 400}
function Focus {for($i=0;$i -lt 6;$i++){[CaptureNative]::Focus($hwnd);$bounds=New-Object CaptureNative+Rect;[CaptureNative]::GetWindowRect($hwnd,[ref]$bounds)|Out-Null;[CaptureNative]::Click([int](($bounds.Left+$bounds.Right)/2),$bounds.Top+15);Start-Sleep -Milliseconds 250;if([CaptureNative]::GetForegroundWindow() -eq $hwnd){return}};throw 'Task window could not take foreground'}
function Shot([string]$suffix='') {
 if([System.Windows.Automation.AutomationElement]::FromHandle([CaptureNative]::GetForegroundWindow()).Current.ProcessId -ne $process.Id){Focus};$name=$jobName+$suffix
 $banner=Id 'DemoModeBanner';if($banner -and !$banner.Current.IsOffscreen){throw 'Demo banner is visible'}
 $r=New-Object CaptureNative+Rect;if(![CaptureNative]::GetWindowRect($hwnd,[ref]$r)){throw 'Window bounds unavailable'}
 [CaptureNative]::SetCursorPos(1590,990)|Out-Null
 $bmp=New-Object Drawing.Bitmap(($r.Right-$r.Left),($r.Bottom-$r.Top));$g=[Drawing.Graphics]::FromImage($bmp)
 try{$g.CopyFromScreen($r.Left,$r.Top,0,0,$bmp.Size);$bmp.Save("$out\$name.png",[Drawing.Imaging.ImageFormat]::Png)}finally{$g.Dispose();$bmp.Dispose()}
 $record=@{file="$name.png";platform='windows';form=$form;theme=$theme;reader=$reader;page=$page;stage=$stage;width=$r.Right-$r.Left;height=$r.Bottom-$r.Top;processId=$process.Id;simulated=$true;bannerHidden=$true;binarySHA256=(Get-FileHash $app -Algorithm SHA256).Hash;language=$locale;readiness=$ready}
 $record|ConvertTo-Json -Depth 8|Set-Content "$out\$name.json" -Encoding UTF8;$records.Add($record)
 @{platform='windows';language=$locale;records=$records.ToArray()}|ConvertTo-Json -Depth 9|Set-Content "$out\manifest.json" -Encoding UTF8
 Write-Output $name
}
function Open-Verify {
 Invoke (Id 'ChooseDocuments')
 for($i=0;$i -lt 100;$i++){$n=Id 'VerificationOutcome';if($n -and !$n.Current.IsOffscreen -and $n.Current.Name){return};Start-Sleep -Milliseconds 100}
 throw 'Verification fixture did not settle'
}
function Open-Queue {Invoke (Id 'ChooseDocuments');Start-Sleep -Milliseconds 300}
function Open-Success {Open-Queue;Invoke (Id 'SignDocuments');for($i=0;$i -lt 100;$i++){$n=Nodes|Where-Object{$_.Current.Name -like '*DEMO-NOT-SIGNED*'}|Select-Object -First 1;if($n){foreach($node in (Nodes)){$pat=$null;if($node.TryGetCurrentPattern([System.Windows.Automation.ScrollPattern]::Pattern,[ref]$pat) -and $pat.Current.VerticallyScrollable){$pat.SetScrollPercent(-1,0)}};Start-Sleep -Milliseconds 300;return};Start-Sleep -Milliseconds 100};throw 'Signing fixture did not settle'}
function Run-Job([string]$reader,[string]$page,[string]$stage='baseline') {
 $script:reader=$reader;$script:page=$page;$script:stage=$stage;$script:jobName="$locale-$reader-$page-$stage"

 $env:MSIGN_DEMO_CARDS=$reader;$env:MSIGN_DEMO_PAGE=$page;$env:MSIGN_DEMO_DARK=$(if($theme -eq 'dark'){'1'}else{'0'});$env:MSIGN_DEMO_PIN_ONLY=$null;$env:MSIGN_DEMO_VERIFY=$null
 if($stage.StartsWith('verify-')){$env:MSIGN_DEMO_VERIFY=$stage.Substring(7)}
 @{Language=$locale;Theme=$theme;FirstRunDone=$true;BridgeEnabled=$false;DemoModeEnabled=$true;InsertionHelperEnabled=$false}|ConvertTo-Json|Set-Content $env:MSIGN_TEST_PREFERENCES
 $env:MSIGN_DEMO_READY_FILE="$root\ready-"+[Guid]::NewGuid().ToString('N')+'.json'
 if($stage -eq 'pin'){$env:MSIGN_DEMO_PIN_ONLY='1'}
 $script:process=Start-Process $app -WorkingDirectory (Split-Path $app) -PassThru
 try{
  for($i=0;$i -lt 200;$i++){Start-Sleep -Milliseconds 100;if($process.HasExited){throw 'App exited before readiness'};if(Test-Path $env:MSIGN_DEMO_READY_FILE){break}}
  if(!(Test-Path $env:MSIGN_DEMO_READY_FILE)){throw 'No fresh readiness marker'}
  $script:ready=Get-Content $env:MSIGN_DEMO_READY_FILE -Raw|ConvertFrom-Json
  if($ready.ProcessId -ne $process.Id -or !$ready.CarouselsCentered){throw 'Readiness belongs to wrong process or unstable layout'}
  $script:hwnd=[IntPtr]([long]$ready.Window)
  if($stage -ne 'pin'){[CaptureNative]::MoveWindow($hwnd,30,30,$width,$height,$true)|Out-Null}
  [CaptureNative]::SetWindowPos($hwnd,[IntPtr](-1),0,0,0,0,0x43)|Out-Null;Focus
  $script:ui=[System.Windows.Automation.AutomationElement]::FromHandle($hwnd)
  Start-Sleep -Milliseconds 300
  switch($stage){
   'stamp'{Open-Queue;$n=Nodes|Where-Object{$_.Current.ControlType -eq [System.Windows.Automation.ControlType]::Button -and $_.Current.Name -eq (L 'file_options')}|Select-Object -First 1;Invoke $n;Invoke (Name (L 'Stamp_Add'));Start-Sleep -Milliseconds 600;$script:hwnd=[CaptureNative]::GetForegroundWindow();$script:ui=[System.Windows.Automation.AutomationElement]::FromHandle($hwnd);if($ui.Current.ProcessId -ne $process.Id){throw 'Editor does not belong to task'};[CaptureNative]::MoveWindow($hwnd,30,30,$width,$height,$true)|Out-Null;Start-Sleep -Milliseconds 500;Shot;break}
'queue'{Open-Queue;Shot;break}
   'success'{Open-Success;Shot;break}
   'formats'{Open-Queue;$node=Nodes|Where-Object{$_.Current.ControlType -eq [System.Windows.Automation.ControlType]::Button -and $_.Current.Name -eq (L 'file_options')}|Select-Object -First 1;Invoke $node;Shot;break}
   'about'{Invoke (Id 'AboutTab');Shot;break}
   'settings-lower'{Scroll-End;Shot;break}
   'documents'{Open-Success;Nav 'activity';Shot;break}
   'history'{Open-Success;Nav 'activity';Invoke (Id 'DocumentFilter');Invoke (Name (L 'saved_history'));Shot;break}
   'document-details'{Open-Success;Nav 'activity';$row=Nodes|Where-Object{$_.Current.ClassName -eq 'ListViewItem'}|Select-Object -First 1;Invoke $row;Start-Sleep -Milliseconds 600;$script:hwnd=[CaptureNative]::GetForegroundWindow();$script:ui=[System.Windows.Automation.AutomationElement]::FromHandle($hwnd);if($ui.Current.ProcessId -ne $process.Id){throw 'Editor does not belong to task'};[CaptureNative]::MoveWindow($hwnd,30,30,$width,$height,$true)|Out-Null;Start-Sleep -Milliseconds 500;Shot;break}
   'clear-history'{Open-Success;Nav 'activity';Invoke (Id 'DocumentFilter');Invoke (Name (L 'saved_history'));Invoke (Id 'ClearButton');Shot;Invoke (Id 'PrimaryButton');Shot '-empty';break}
   {$_ -like 'verify-*'}{Open-Verify;Shot '-summary';Scroll-End;$expanded=0;foreach($n in (Nodes)){$p=$null;if($n.TryGetCurrentPattern([System.Windows.Automation.ExpandCollapsePattern]::Pattern,[ref]$p) -and $n.Current.ClassName -like '*Expander'){$p.Expand();$expanded++;Write-Output ('EXPANDED '+$n.Current.Name)}};if($expanded -eq 0){throw 'No native expanders expanded'};Scroll-End;Shot '-expanded-details';break}
   default{Shot}
  }
 }finally{if($process -and !$process.HasExited){Stop-Process -Id $process.Id -Force};Remove-Item $env:MSIGN_DEMO_READY_FILE -ErrorAction SilentlyContinue}
}
try {
 $form='desktop';$width=1100;$height=900;$theme='light'
 foreach($locale in @('en-US','ro-RO','ru-RU')) {
  [xml]$resources=Get-Content "$root\windows\src\MoldSign.App\Strings\$locale\Resources.resw" -Raw -Encoding UTF8
  if($VerificationOnly){Run-Job 'multiple' 'verify' 'verify-valid';continue}
  Run-Job 'none' 'card'
  Run-Job 'multiple' 'card'
  Run-Job 'multiple' 'sign' 'queue'
  Run-Job 'multiple' 'sign' 'stamp'
  Run-Job 'multiple' 'pin' 'pin'
  Run-Job 'multiple' 'sign' 'success'
  Run-Job 'multiple' 'verify'
  Run-Job 'multiple' 'verify' 'verify-valid'
  Run-Job 'multiple' 'sign' 'documents'
  Run-Job 'multiple' 'sign' 'document-details'
  Run-Job 'multiple' 'settings'
  Run-Job 'multiple' 'settings' 'settings-lower'
  Run-Job 'multiple' 'settings' 'about'
 }
 'COMPLETE'|Set-Content "$root\capture-status.txt"
} catch {($_|Out-String)+$_.ScriptStackTrace|Set-Content "$root\capture-status.txt";throw}
