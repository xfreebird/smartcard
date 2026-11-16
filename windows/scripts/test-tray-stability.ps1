# Run in the interactive desktop with the test app's tray flyout already open.
# Records native window bounds only; never invokes card, PIN or signing actions.
param([Parameter(Mandatory=$true)][int]$AppProcess,
      [Parameter(Mandatory=$true)][string]$Output)
$ErrorActionPreference='Stop'
Add-Type @'
using System;
using System.Collections.Generic;
using System.Runtime.InteropServices;
public static class TrayObserve {
 public delegate bool EnumProc(IntPtr hwnd,IntPtr data);
 [StructLayout(LayoutKind.Sequential)] public struct Rect {public int Left,Top,Right,Bottom;}
 [DllImport("user32.dll")] static extern bool EnumWindows(EnumProc callback,IntPtr data);
 [DllImport("user32.dll")] static extern uint GetWindowThreadProcessId(IntPtr hwnd,out uint process);
 [DllImport("user32.dll")] public static extern bool GetWindowRect(IntPtr hwnd,out Rect rect);
 [DllImport("user32.dll")] public static extern bool IsWindowVisible(IntPtr hwnd);
 [DllImport("user32.dll")] public static extern uint GetDpiForWindow(IntPtr hwnd);
 [DllImport("user32.dll")] public static extern bool SetProcessDPIAware();
 public static IntPtr[] Windows(int process) {var windows=new List<IntPtr>(); EnumWindows((h,d)=>{uint p;GetWindowThreadProcessId(h,out p);if(p==process)windows.Add(h);return true;},IntPtr.Zero);return windows.ToArray();}
}
'@
[TrayObserve]::SetProcessDPIAware()|Out-Null
$handles=@()
# A scheduled runner can briefly take focus. Allow the flyout to be opened after launch.
for($attempt=0;$attempt -lt 150 -and $handles.Count -eq 0;$attempt++) {
$handles=@([TrayObserve]::Windows($AppProcess) | Where-Object {
 if(![TrayObserve]::IsWindowVisible($_)){return $false}
 $rect=New-Object TrayObserve+Rect
 [TrayObserve]::GetWindowRect($_,[ref]$rect)|Out-Null
 $scale=[Math]::Max(1,[TrayObserve]::GetDpiForWindow($_)/96.0)
 $width=($rect.Right-$rect.Left)/$scale
 return $width -ge 200 -and $width -le 600 -and ($rect.Bottom-$rect.Top) -ge 100
})
 if($handles.Count -eq 0){Start-Sleep -Milliseconds 100}
}
if($handles.Count -ne 1){throw 'Open only the test app tray flyout before running this check.'}
$samples=@()
$watch=[Diagnostics.Stopwatch]::StartNew()
for($i=0;$i -lt 300;$i++){
 foreach($handle in $handles){
  if(![TrayObserve]::IsWindowVisible($handle)){continue}
  $r=New-Object TrayObserve+Rect
  [TrayObserve]::GetWindowRect($handle,[ref]$r)|Out-Null
  $samples+=@{Ms=$watch.ElapsedMilliseconds;Handle=$handle.ToInt64();Left=$r.Left;Top=$r.Top;Width=$r.Right-$r.Left;Height=$r.Bottom-$r.Top;Dpi=[TrayObserve]::GetDpiForWindow($handle)}
 }
 Start-Sleep -Milliseconds 10
}
$samples | ConvertTo-Json | Set-Content -Encoding UTF8 $Output

$bounds=@($samples | ForEach-Object {"$($_.Left),$($_.Top),$($_.Width),$($_.Height),$($_.Dpi)"} | Sort-Object -Unique)
if($samples.Count -ne 300){throw 'The tray flyout hid during the idle check.'}
if($bounds.Count -ne 1){throw "Tray moved while idle: $($bounds -join '; ')"}
Write-Output "Tray stayed at $($bounds[0]) throughout $($samples[-1].Ms)ms ($($samples.Count) samples)."
