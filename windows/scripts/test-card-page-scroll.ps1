# Native mouse-wheel and keyboard scroll proof. No card, PIN, credential or signing action is invoked.
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
function Assert-Visible($element,$viewport,[string]$label) {
    $r=$element.Current.BoundingRectangle;$v=$viewport.Current.BoundingRectangle
    if($element.Current.IsOffscreen -or $r.Width -le 0 -or $r.Height -le 0 -or
       $r.Top -lt $v.Top-1 -or $r.Bottom -gt $v.Bottom+1 -or $r.Left -lt $v.Left-1 -or $r.Right -gt $v.Right+1) {
        throw "$label is not fully visible in its viewport."
    }
}
function Is-Bottom($pattern) {return -not $pattern.Current.VerticallyScrollable -or $pattern.Current.VerticalScrollPercent -ge 99.5}
function Wait-Bottom($pattern) {
    for($attempt=0;$attempt -lt 60;$attempt++) {if(Is-Bottom $pattern) {return};Start-Sleep -Milliseconds 100}
    throw 'Native scrolling did not reach the bottom.'
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
try {
    foreach($theme in 'light','dark') {
        $ready=Join-Path $env:TEMP ('card-scroll-ready-'+[Guid]::NewGuid().ToString('N')+'.json')
        $env:MSIGN_DEMO_CARDS='3';$env:MSIGN_DEMO_PAGE='card';$env:MSIGN_DEMO_SELECTED='1'
        $env:MSIGN_DEMO_DARK=if($theme -eq 'dark') {'1'} else {'0'}
        $env:MSIGN_DEMO_READY_FILE=$ready;$env:MSIGN_DEMO_PIN_ONLY=$null
        $process=Start-Process $App -PassThru
        try {
            for($attempt=0;$attempt -lt 150 -and -not (Test-Path $ready);$attempt++) {
                if($process.HasExited) {throw 'Mock app exited before readiness.'};Start-Sleep -Milliseconds 200
            }
            if(-not (Test-Path $ready)) {throw 'Mock Card page did not become ready.'}
            $state=Get-Content $ready -Raw|ConvertFrom-Json
            if($state.ActualPage -ne 'CardPage' -or -not $state.CarouselsCentered) {throw 'Wrong or uncentered page.'}
            $handle=[IntPtr]([long]$state.Window)
            [CardScrollInput]::SetForegroundWindow($handle)|Out-Null
            $window=[System.Windows.Automation.AutomationElement]::FromHandle($handle)
            $scroll=Find-Id $window 'CardScroll'
            $pattern=$scroll.GetCurrentPattern([System.Windows.Automation.ScrollPattern]::Pattern)
            $button=Find-Id $window 'CardForgetPin';$tips=Find-Id $window 'CardTips'
            foreach($size in @(@{Width=1100;Height=720},@{Width=900;Height=580})) {
                [CardScrollInput]::SetWindowPos($handle,[IntPtr]::Zero,0,0,$size.Width,$size.Height,0x0006)|Out-Null
                Start-Sleep -Milliseconds 400
                $scroll.SetFocus();Start-Sleep -Milliseconds 150;[CardScrollInput]::ScrollKey(0x24);Start-Sleep -Milliseconds 250
                # NavigationView animates its pane when crossing the compact-width breakpoint. Wait for stable geometry.
                $stable=0
                for($attempt=0;$attempt -lt 60;$attempt++) {
                    $viewport=Find-Id $window 'CardCarouselViewport';$card=Find-Id $window 'WalletCard2'
                    $r=$card.Current.BoundingRectangle;$v=$viewport.Current.BoundingRectangle
                    $delta=[Math]::Abs(($r.Left+$r.Right-$v.Left-$v.Right)/2)
                    if($delta -le 2) {$stable++} else {$stable=0}
                    if($stable -ge 3) {break}
                    Start-Sleep -Milliseconds 100
                }
                Assert-Visible $card $viewport 'Selected second card'
                if($stable -lt 3) {
                    Capture $handle ("card-resize-failure-$($size.Height)-$theme")
                    throw "Selected card is not centered after resizing. Card=$r Viewport=$v Delta=$delta"
                }
                # UIAutomation rectangles are physical pixels. The large wallet's current
                # layout contract is a maximum 360 DIPs, including its horizontal padding.
                $scale=[CardScrollInput]::GetDpiForWindow($handle)/96.0
                if($scale -le 0) {throw 'Window DPI is unavailable'}
                $cardWidthDip=$r.Width/$scale
                if($cardWidthDip -gt 360) {throw "Card exceeds 360 DIPs: $cardWidthDip ($($r.Width) pixels)"}
                Capture $handle ("card-top-$($size.Height)-$theme")
                # Real wheel events over the selected card exercise nested horizontal/vertical scroll chaining.
                [CardScrollInput]::SetCursorPos([int](($r.Left+$r.Right)/2),[int](($r.Top+$r.Bottom)/2))|Out-Null
                for($attempt=0;$attempt -lt 25 -and -not (Is-Bottom $pattern);$attempt++) {
                    [CardScrollInput]::Wheel(-600);Start-Sleep -Milliseconds 150
                }
                Wait-Bottom $pattern
                Assert-Visible $button $scroll 'Saved-PIN action after wheel scrolling'
                Assert-Visible $tips $scroll 'Last help text after wheel scrolling'
                if([string]::IsNullOrEmpty((Find-Id $window 'WalletCard2').Current.ItemStatus)) {throw 'Wheel scrolling changed the selected card.'}
                $wheelOffset=$pattern.Current.VerticalScrollPercent
                [CardScrollInput]::SetForegroundWindow($handle)|Out-Null;$scroll.SetFocus();Start-Sleep -Milliseconds 150;[CardScrollInput]::ScrollKey(0x24)
                for($attempt=0;$attempt -lt 60 -and $pattern.Current.VerticallyScrollable -and $pattern.Current.VerticalScrollPercent -gt 1;$attempt++) {Start-Sleep -Milliseconds 100}
                if($pattern.Current.VerticallyScrollable -and $pattern.Current.VerticalScrollPercent -gt 1) {throw 'Home did not return to the top.'}
                [CardScrollInput]::ScrollKey(0x23)
                Wait-Bottom $pattern
                Assert-Visible $button $scroll 'Saved-PIN action after keyboard scrolling'
                Assert-Visible $tips $scroll 'Last help text after keyboard scrolling'
                Capture $handle ("card-bottom-$($size.Height)-$theme")
                $proof += @{Theme=$theme;CardWidthDip=$cardWidthDip;DpiScale=$scale;Width=$size.Width;Height=$size.Height;SelectedSecondCardFullAndCentered=$true;
                    MouseWheelReachedEnd=$true;KeyboardReachedEnd=$true;PinActionFullyVisible=$true;LastHelpFullyVisible=$true;
                    WheelScrollPercent=$wheelOffset;KeyboardScrollPercent=$pattern.Current.VerticalScrollPercent}
            }
        } finally {
            if(-not $process.HasExited) {Stop-Process -Id $process.Id -Force}
            if(-not $process.WaitForExit(10000)) {throw "Owned app did not exit"}
            $process.Dispose()
            $process=$null
            Remove-Item $ready -ErrorAction SilentlyContinue
        }
    }
    Get-ChildItem $Output -Filter 'card-resize-failure-*.png'|Remove-Item
    $proof|ConvertTo-Json|Set-Content (Join-Path $Output 'card-scroll-proof.json') -Encoding UTF8
} finally {
    if($null -ne $process -and -not $process.HasExited) {Stop-Process -Id $process.Id -Force}
    foreach($name in $original.Keys) {[Environment]::SetEnvironmentVariable($name,$original[$name])}
}
