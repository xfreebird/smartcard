param([Parameter(Mandatory=$true)][string]$App,[Parameter(Mandatory=$true)][string]$OutputDirectory,[string[]]$Pages=@('sign','card','verify','settings'))
$ErrorActionPreference='Stop'
Add-Type -AssemblyName System.Drawing
Add-Type -AssemblyName UIAutomationClient
Add-Type -AssemblyName UIAutomationTypes
Add-Type @'
using System;using System.Runtime.InteropServices;
public static class StoreWindow {
 [StructLayout(LayoutKind.Sequential)] public struct RECT {public int Left,Top,Right,Bottom;}
 [DllImport("dwmapi.dll")] public static extern int DwmGetWindowAttribute(IntPtr h,int attribute,out RECT rect,int size);
 [DllImport("user32.dll")] public static extern bool MoveWindow(IntPtr h,int x,int y,int w,int hgt,bool repaint);
 [DllImport("user32.dll")] public static extern bool SetForegroundWindow(IntPtr h);
 [DllImport("user32.dll")] public static extern bool ShowWindow(IntPtr h,int cmd);
}
'@
New-Item -ItemType Directory -Force $OutputDirectory | Out-Null
$audit=@();$launched=$null
try {
 foreach($locale in @('ro-RO','en-US','ru-RU')) {
  $folder=Join-Path $OutputDirectory $locale;New-Item -ItemType Directory -Force $folder | Out-Null
  foreach($page in $Pages) {
   $prefs=Join-Path $folder 'qa-settings.json';[IO.File]::WriteAllText($prefs,(@{Language=$locale;Theme='light';BridgeEnabled=$false;FirstRunDone=$true}|ConvertTo-Json))
   $env:MSIGN_SCREENSHOT_CAPTURE='1';$env:MSIGN_TEST_PREFERENCES=$prefs;$env:MSIGN_DEMO_CARDS='2';$env:MSIGN_DEMO_DARK='0';$env:MSIGN_DEMO_PAGE=$page
   $ready=Join-Path $folder "$page.ready";Remove-Item $ready -ErrorAction SilentlyContinue;$env:MSIGN_DEMO_READY_FILE=$ready
   $launched=Start-Process $App -PassThru
   $deadline=(Get-Date).AddSeconds(40)
   while(!(Test-Path $ready) -and (Get-Date)-lt $deadline){Start-Sleep -Milliseconds 200;$launched.Refresh();if($launched.HasExited){throw "QA app exited $($launched.ExitCode)"}}
   if(!(Test-Path $ready)){throw "Ready timeout $page"}
   $launched.Refresh();$h=$launched.MainWindowHandle
   if(!$h){throw 'No QA main window'}
   [StoreWindow]::ShowWindow($h,9)|Out-Null;[StoreWindow]::MoveWindow($h,20,20,1382,916,$true)|Out-Null;[StoreWindow]::SetForegroundWindow($h)|Out-Null;Start-Sleep -Milliseconds 1500
   if($page -eq 'card') {
    $element=[System.Windows.Automation.AutomationElement]::FromHandle($h)
    $condition=[System.Windows.Automation.PropertyCondition]::new([System.Windows.Automation.AutomationElement]::AutomationIdProperty,'SettingsCardDetails')
    $button=$element.FindFirst([System.Windows.Automation.TreeScope]::Descendants,$condition)
    if(!$button){throw 'Cards and readers action is missing from Settings'}
    $button.GetCurrentPattern([System.Windows.Automation.InvokePattern]::Pattern).Invoke()
    Start-Sleep -Milliseconds 1200
   }
   if($page -eq 'sign') {
    $element=[System.Windows.Automation.AutomationElement]::FromHandle($h)
    $condition=[System.Windows.Automation.PropertyCondition]::new([System.Windows.Automation.AutomationElement]::ControlTypeProperty,[System.Windows.Automation.ControlType]::Button)
    $buttons=$element.FindAll([System.Windows.Automation.TreeScope]::Descendants,$condition)
    foreach($button in $buttons){if($button.Current.Name -match 'Alege|Choose|\u0412\u044b\u0431'){try{$button.GetCurrentPattern([System.Windows.Automation.InvokePattern]::Pattern).Invoke();break}catch{}}}
    Start-Sleep -Milliseconds 1800
   }
   $rect=[StoreWindow+RECT]::new();[StoreWindow]::DwmGetWindowAttribute($h,9,[ref]$rect,16)|Out-Null
   $width=$rect.Right-$rect.Left;$height=$rect.Bottom-$rect.Top
   if($width -lt 1366 -or $height -lt 768){throw "Native screenshot is too small: $width x $height"}
   $bitmap=[Drawing.Bitmap]::new($width,$height);$g=[Drawing.Graphics]::FromImage($bitmap);$g.CopyFromScreen($rect.Left,$rect.Top,0,0,$bitmap.Size);$target=Join-Path $folder "$page.png";$bitmap.Save($target,[Drawing.Imaging.ImageFormat]::Png);$g.Dispose();$bitmap.Dispose()
   $audit+=@{locale=$locale;page=$page;file=$target;source=$App;dimensions="${width}x${height}";fixture='two fictional cards'}
   Stop-Process -Id $launched.Id;$launched=$null;Remove-Item $ready,$prefs -ErrorAction SilentlyContinue
  }
 }
 $audit|ConvertTo-Json -Depth 5|Set-Content (Join-Path $OutputDirectory 'capture-manifest.json')
} finally {if($launched -and !$launched.HasExited){Stop-Process -Id $launched.Id}}
