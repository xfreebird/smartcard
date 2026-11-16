# Native Settings category navigation proof. No card, PIN, credential or signing action is invoked.
param([Parameter(Mandatory=$true)][string]$App,[Parameter(Mandatory=$true)][string]$Output)
$ErrorActionPreference='Stop'
Add-Type -AssemblyName UIAutomationClient
Add-Type -AssemblyName UIAutomationTypes
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
if(-not ('CardScrollInput' -as [type])) {
Add-Type @'
using System;
using System.Runtime.InteropServices;
public static class CardScrollInput {
    [StructLayout(LayoutKind.Sequential)] public struct Rect { public int Left,Top,Right,Bottom; }
    [DllImport("user32.dll")] public static extern uint GetDpiForWindow(IntPtr hwnd);
    [DllImport("user32.dll")] public static extern bool SetWindowPos(IntPtr hwnd,IntPtr after,int x,int y,int w,int h,uint flags);
    [DllImport("user32.dll")] public static extern bool GetWindowRect(IntPtr hwnd,out Rect rect);
    [DllImport("user32.dll")] public static extern bool SetForegroundWindow(IntPtr hwnd);
    [DllImport("user32.dll")] public static extern IntPtr GetForegroundWindow();
    [DllImport("user32.dll")] public static extern bool SetCursorPos(int x,int y);
    [DllImport("user32.dll")] private static extern void mouse_event(uint flags,uint x,uint y,uint data,UIntPtr extra);
    public static void Wheel(int delta) { mouse_event(0x0800,0,0,unchecked((uint)delta),UIntPtr.Zero); }
    [DllImport("user32.dll")] private static extern void keybd_event(byte key,byte scan,uint flags,UIntPtr extra);
    public static void ScrollKey(byte key) {
        if (key != 0x24 && key != 0x23) throw new ArgumentOutOfRangeException("key");
        byte scan = key == 0x24 ? (byte)0x47 : (byte)0x4f;
        // Home/End are extended navigation keys, not NumLock-sensitive keypad keys.
        keybd_event(0x11,0x1d,0,UIntPtr.Zero); keybd_event(key,scan,1,UIntPtr.Zero);
        keybd_event(key,scan,3,UIntPtr.Zero); keybd_event(0x11,0x1d,2,UIntPtr.Zero);
    }
    [DllImport("user32.dll")] public static extern bool SetProcessDPIAware();
}
'@
}
[CardScrollInput]::SetProcessDPIAware()|Out-Null
New-Item -ItemType Directory -Force $Output|Out-Null
$original=@{}
foreach($name in 'MSIGN_DEMO_CARDS','MSIGN_DEMO_PAGE','MSIGN_DEMO_DARK','MSIGN_DEMO_SELECTED','MSIGN_DEMO_READY_FILE','MSIGN_DEMO_PIN_ONLY') {$original[$name]=[Environment]::GetEnvironmentVariable($name)}
$proof=@()
$process=$null
function Find-Id($parent,[string]$id) {
    $condition=[System.Windows.Automation.PropertyCondition]::new([System.Windows.Automation.AutomationElement]::AutomationIdProperty,$id)
    $element=$parent.FindFirst([System.Windows.Automation.TreeScope]::Descendants,$condition)
    if($null -eq $element) {throw "Missing native UI element: $id"}
    return $element
}
function Capture([IntPtr]$window,[string]$name) {
    if([CardScrollInput]::GetForegroundWindow() -ne $window) {throw 'Capture window is obscured.'}
    $rect=New-Object CardScrollInput+Rect
    [CardScrollInput]::GetWindowRect($window,[ref]$rect)|Out-Null
    $bitmap=New-Object System.Drawing.Bitmap(($rect.Right-$rect.Left),($rect.Bottom-$rect.Top))
    $graphics=[System.Drawing.Graphics]::FromImage($bitmap)
    try {$graphics.CopyFromScreen($rect.Left,$rect.Top,0,0,$bitmap.Size);$bitmap.Save((Join-Path $Output ($name+'.png')),[System.Drawing.Imaging.ImageFormat]::Png)}
    finally {$graphics.Dispose();$bitmap.Dispose()}
}
# Retained script name for CI compatibility: Card is now removed from navigation.
# Verify its replacement Settings route, category selection, and top-level Demo access.
try {
    foreach($theme in 'light','dark') {
        $ready=Join-Path $env:TEMP ('settings-ready-'+[Guid]::NewGuid().ToString('N')+'.json')
        $env:MSIGN_DEMO_CARDS='3';$env:MSIGN_DEMO_PAGE='settings';$env:MSIGN_DEMO_SELECTED='1'
        $env:MSIGN_DEMO_DARK=if($theme -eq 'dark') {'1'} else {'0'}
        $env:MSIGN_DEMO_READY_FILE=$ready;$env:MSIGN_DEMO_PIN_ONLY=$null
        $process=Start-Process $App -PassThru
        try {
            for($attempt=0;$attempt -lt 150 -and -not (Test-Path $ready);$attempt++) {
                if($process.HasExited) {throw 'App exited before readiness'};Start-Sleep -Milliseconds 200
            }
            if(-not (Test-Path $ready)) {throw 'Settings did not become ready'}
            $state=Get-Content $ready -Raw|ConvertFrom-Json
            if($state.ActualPage -ne 'SettingsPage') {throw 'Wrong page'}
            $handle=[IntPtr]([long]$state.Window)
            [CardScrollInput]::SetForegroundWindow($handle)|Out-Null
            $window=[System.Windows.Automation.AutomationElement]::FromHandle($handle)
            foreach($size in @(@{Width=1100;Height=720},@{Width=900;Height=580})) {
                [CardScrollInput]::SetWindowPos($handle,[IntPtr]::Zero,0,0,$size.Width,$size.Height,0x0006)|Out-Null
                Start-Sleep -Milliseconds 700
                # Modal dismissal intentionally preserves root scroll position. Reset through
                # category Back before testing the top of Settings at the next window size.
                $general=Find-Id $window 'SettingsGeneral'
                $scrollItem=$null
                if($general.TryGetCurrentPattern([System.Windows.Automation.ScrollItemPattern]::Pattern,[ref]$scrollItem)) {$scrollItem.ScrollIntoView()}
                $general.GetCurrentPattern([System.Windows.Automation.InvokePattern]::Pattern).Invoke()
                Start-Sleep -Milliseconds 200
                (Find-Id $window 'SettingsBack').GetCurrentPattern([System.Windows.Automation.InvokePattern]::Pattern).Invoke()
                Start-Sleep -Milliseconds 250
                $demo=Find-Id $window 'DemoModeToggle'
                if($demo.Current.IsOffscreen) {throw 'Demo is not visible at the top'}
                Capture $handle ("settings-root-$($size.Height)-$theme")
                foreach($category in 'General','Browser','Advanced') {
                    $item=Find-Id $window ('Settings'+$category)
                    $scrollItem=$null
                    if($item.TryGetCurrentPattern([System.Windows.Automation.ScrollItemPattern]::Pattern,[ref]$scrollItem)) {$scrollItem.ScrollIntoView()}
                    $item.GetCurrentPattern([System.Windows.Automation.InvokePattern]::Pattern).Invoke()
                    Start-Sleep -Milliseconds 350
                    $back=Find-Id $window 'SettingsBack'
                    if($back.Current.IsOffscreen) {throw "Back is hidden in $category"}
                    Capture $handle ("settings-$category-$($size.Height)-$theme")
                    $back.GetCurrentPattern([System.Windows.Automation.InvokePattern]::Pattern).Invoke()
                    Start-Sleep -Milliseconds 250
                    $proof+=@{Theme=$theme;Width=$size.Width;Height=$size.Height;Category=$category;Opened=$true;BackVisible=$true}
                }
                foreach($category in 'Pins','About') {
                    $item=Find-Id $window ('Settings'+$category)
                    $scrollItem=$null
                    if($item.TryGetCurrentPattern([System.Windows.Automation.ScrollItemPattern]::Pattern,[ref]$scrollItem)) {$scrollItem.ScrollIntoView()}
                    $item.GetCurrentPattern([System.Windows.Automation.InvokePattern]::Pattern).Invoke()
                    Start-Sleep -Milliseconds 400
                    $dialog=Find-Id $window ('Settings'+$category+'Dialog')
                    if($dialog.Current.IsOffscreen) {throw "Dialog is hidden: $category"}
                    Capture $handle ("settings-$category-dialog-$($size.Height)-$theme")
                    [System.Windows.Forms.SendKeys]::SendWait('{ESC}')
                    Start-Sleep -Milliseconds 300
                    $rootItem=Find-Id $window ('Settings'+$category)
                    if($rootItem.Current.IsOffscreen) {throw "Dismissal lost Settings position: $category"}
                    $proof+=@{Theme=$theme;Width=$size.Width;Height=$size.Height;Category=$category;Opened=$true;Modal=$true;ReturnedToRow=$true}
                }
                $cardButton=Find-Id $window 'SettingsCardDetails'
                $cardButton.GetCurrentPattern([System.Windows.Automation.InvokePattern]::Pattern).Invoke()
                Start-Sleep -Milliseconds 600
                $cardScroll=Find-Id $window 'CardScroll'
                if($cardScroll.Current.IsOffscreen) {throw 'Card details did not open'}
                Capture $handle ("settings-card-details-$($size.Height)-$theme")
                [System.Windows.Forms.SendKeys]::SendWait('{ESC}')
                Start-Sleep -Milliseconds 300
            }
        } finally {
            if(-not $process.HasExited) {Stop-Process -Id $process.Id -Force}
            $null=$process.WaitForExit(10000);$process.Dispose();$process=$null
            Remove-Item $ready -ErrorAction SilentlyContinue
        }
    }
    $proof|ConvertTo-Json|Set-Content (Join-Path $Output 'settings-navigation-proof.json') -Encoding UTF8
} finally {
    if($null -ne $process -and -not $process.HasExited) {Stop-Process -Id $process.Id -Force}
    foreach($name in $original.Keys) {[Environment]::SetEnvironmentVariable($name,$original[$name])}
}
