using System.Runtime.InteropServices;
using Microsoft.UI;
using Microsoft.UI.Composition.SystemBackdrops;
using Microsoft.UI.Windowing;
using Microsoft.UI.Xaml;
using Microsoft.UI.Xaml.Media;
using Windows.Graphics;

namespace MoldSign.App.Services;

/// <summary>AppWindow plumbing shared by the main window and the tray flyout.</summary>
internal static partial class WindowHelpers
{
    /// <summary>Flyout width (docs/10 §2: 360 epx).</summary>
    public const int FlyoutWidth = 360;
    public const int FlyoutHeight = 660;

    /// <summary>docs/10 §2: main window min 860 × 580.</summary>
    public const int MainMinWidth = 860;
    public const int MainMinHeight = 580;

    public static nint Handle(Window window) => WinRT.Interop.WindowNative.GetWindowHandle(window);

    public static IDisposable PresentConsent(Window window, bool aboveBrowser)
    {
        var presenter = window.AppWindow.Presenter as OverlappedPresenter;
        var wasTopmost = presenter?.IsAlwaysOnTop ?? false;
        if (presenter is not null)
        {
            if (aboveBrowser) presenter.IsAlwaysOnTop = true;
            if (presenter.State == OverlappedPresenterState.Minimized) presenter.Restore();
        }
        window.AppWindow.Show();
        window.Activate();
        _ = SetForegroundWindow(Handle(window));
        return new ConsentPresentation(presenter, wasTopmost);
    }

    private sealed class ConsentPresentation(OverlappedPresenter? presenter, bool wasTopmost) : IDisposable
    {
        public void Dispose()
        {
            try
            {
                if (presenter is not null) presenter.IsAlwaysOnTop = wasTopmost;
            }
            catch (COMException error) { AppLog.Error(error); }
        }
    }

    /// <summary>Keep caption buttons legible when app appearance differs from the system theme.</summary>
    public static void ApplyCaptionTheme(Window window)
    {
        if (!AppWindowTitleBar.IsCustomizationSupported() || window.Content is not FrameworkElement root) return;
        var dark = root.ActualTheme == ElementTheme.Dark;
        var foreground = dark ? Colors.White : Colors.Black;
        var titleBar = window.AppWindow.TitleBar;
        titleBar.ButtonForegroundColor = foreground;
        titleBar.ButtonHoverForegroundColor = foreground;
        titleBar.ButtonPressedForegroundColor = foreground;
        titleBar.ButtonInactiveForegroundColor = dark ? Colors.LightGray : Colors.DimGray;
        titleBar.ButtonBackgroundColor = Colors.Transparent;
        titleBar.ButtonInactiveBackgroundColor = Colors.Transparent;
        titleBar.ButtonHoverBackgroundColor = Windows.UI.Color.FromArgb(0x22, foreground.R, foreground.G, foreground.B);
        titleBar.ButtonPressedBackgroundColor = Windows.UI.Color.FromArgb(0x33, foreground.R, foreground.G, foreground.B);
    }

    /// <summary>Effective-pixel scale of the window's monitor.</summary>
    public static double Scale(Window window)
    {
        var dpi = GetDpiForWindow(Handle(window));
        return dpi == 0 ? 1.0 : dpi / 96.0;
    }

    /// <summary>Mica when supported (Windows 11), else desktop acrylic, else the plain theme background.</summary>
    public static void ApplyMica(Window window)
    {
        if (MicaController.IsSupported()) window.SystemBackdrop = new MicaBackdrop();
        else if (DesktopAcrylicController.IsSupported()) window.SystemBackdrop = new DesktopAcrylicBackdrop();
    }

    /// <summary>Acrylic flyout (docs/10 §4.6).</summary>
    public static void ApplyAcrylic(Window window)
    {
        if (DesktopAcrylicController.IsSupported()) window.SystemBackdrop = new DesktopAcrylicBackdrop();
    }

    public static void ResizeMain(Window window)
    {
        var scale = Scale(window);
        var work = DisplayArea.GetFromWindowId(window.AppWindow.Id, DisplayAreaFallback.Nearest).WorkArea;
        var width = Math.Min((int)(1100 * scale), work.Width);
        var height = Math.Min((int)(720 * scale), work.Height);
        window.AppWindow.Resize(new SizeInt32(width, height));
        window.AppWindow.Move(new PointInt32(work.X + (work.Width - width) / 2, work.Y + (work.Height - height) / 2));
        if (window.AppWindow.Presenter is OverlappedPresenter presenter)
        {
            presenter.PreferredMinimumWidth = Math.Min((int)(MainMinWidth * scale), work.Width);
            presenter.PreferredMinimumHeight = Math.Min((int)(MainMinHeight * scale), work.Height);
        }
    }

    /// <summary>Borderless, fixed-size, always-on-top, hidden from Alt+Tab and the taskbar.</summary>
    public static void MakeFlyout(Window window)
    {
        var appWindow = window.AppWindow;
        appWindow.IsShownInSwitchers = false;
        if (appWindow.Presenter is OverlappedPresenter presenter)
        {
            presenter.IsResizable = false;
            presenter.IsMaximizable = false;
            presenter.IsMinimizable = false;
            presenter.IsAlwaysOnTop = true;
            presenter.SetBorderAndTitleBar(hasBorder: true, hasTitleBar: false);
        }
    }

    /// <summary>
    /// Bottom-right corner of the primary work area, i.e. above the notification area for the default taskbar position.
    /// <paramref name="extraHeight"/> (epx) grows the flyout, e.g. for the expanded card list (docs/10 §0.2b); the height
    /// is clamped to the work area and the bottom edge stays anchored, so the flyout never leaves the screen.
    /// TODO(WIN-04): follow the taskbar edge (top/left/right) and the monitor the icon is on.
    /// </summary>
    public static void PlaceNearTray(Window window, double extraHeight = 0)
    {
        var scale = Scale(window);
        var area = DisplayArea.Primary.WorkArea;
        var margin = (int)(12 * scale);
        var width = (int)(FlyoutWidth * scale);
        var frameWidth = 0;
        var frameHeight = 0;
        if (GetClientRect(Handle(window), out var client))
        {
            frameWidth = Math.Max(0, window.AppWindow.Size.Width - (client.Right - client.Left));
            frameHeight = Math.Max(0, window.AppWindow.Size.Height - (client.Bottom - client.Top));
        }
        double measuredHeight = FlyoutHeight + Math.Max(0, extraHeight);
        if (window.Content is FrameworkElement content)
        {
            // XAML lays out in the client area. Measuring at the outer window width makes
            // the card carousel alternate widths and request another resize on every render.
            content.Measure(new Windows.Foundation.Size(Math.Max(1, width - frameWidth) / scale, double.PositiveInfinity));
            if (content.DesiredSize.Height > 0) measuredHeight = content.DesiredSize.Height;
        }
        var height = (int)Math.Min(Math.Ceiling(measuredHeight * scale) + frameHeight, area.Height - 2 * margin);
        var bounds = new RectInt32(
            area.X + area.Width - width - margin,
            area.Y + area.Height - height - margin,
            width,
            height);
        if (window.AppWindow.Position.X == bounds.X && window.AppWindow.Position.Y == bounds.Y &&
            window.AppWindow.Size.Width == bounds.Width && window.AppWindow.Size.Height == bounds.Height) return;
        window.AppWindow.MoveAndResize(bounds);
    }

    /// <summary>Tallest flyout that fits in the primary work area (epx).</summary>
    public static double MaxFlyoutHeight(Window window) => DisplayArea.Primary.WorkArea.Height / Scale(window) - 24;

    /// <summary>HWND of the window hosting <paramref name="root"/> (pickers need it in unpackaged apps).</summary>
    public static nint HandleFor(XamlRoot root) =>
        Win32Interop.GetWindowFromWindowId(root.ContentIslandEnvironment.AppWindowId);

    /// <summary>Multi-file open picker owned by the window of <paramref name="root"/>; empty when cancelled.</summary>
    public static Task<IReadOnlyList<string>> PickFilesAsync(XamlRoot root, params string[] extensions)
    {
        var windowId = root.ContentIslandEnvironment.AppWindowId;
        if (windowId.Value == 0) windowId = App.Current.EnsureMainWindow(activate: true).AppWindow.Id;
        return PickFilesAsync(windowId, extensions);
    }

    public static async Task<IReadOnlyList<string>> PickFilesAsync(WindowId windowId, params string[] extensions)
    {
        var picker = new Microsoft.Windows.Storage.Pickers.FileOpenPicker(windowId);
        foreach (var extension in extensions) picker.FileTypeFilter.Add(extension);
        var files = await picker.PickMultipleFilesAsync();
        return files is null ? [] : files.Select(f => f.Path).Where(p => !string.IsNullOrEmpty(p)).ToList();
    }

    /// <summary>File paths from a drag-and-drop payload (storage items only).</summary>
    public static async Task<IReadOnlyList<string>> DroppedPathsAsync(Windows.ApplicationModel.DataTransfer.DataPackageView data)
    {
        if (!data.Contains(Windows.ApplicationModel.DataTransfer.StandardDataFormats.StorageItems)) return [];
        var items = await data.GetStorageItemsAsync();
        return items.OfType<Windows.Storage.StorageFile>().Select(f => f.Path).Where(p => !string.IsNullOrEmpty(p)).ToList();
    }

    /// <summary>Opens Explorer with <paramref name="path"/> selected ("Arată în Explorer").</summary>
    public static void RevealInExplorer(string path)
    {
        if (!File.Exists(path)) return;
        System.Diagnostics.Process.Start(new System.Diagnostics.ProcessStartInfo("explorer.exe", $"/select,\"{path}\"")
        {
            UseShellExecute = true,
        });
    }

    /// <summary>
    /// Primary-action style: AccentButtonStyle only while the button is enabled, DefaultButtonStyle otherwise (Fluent:
    /// never show a disabled accent-filled button).
    /// </summary>
    public static Style? ButtonStyle(bool accent) =>
        Application.Current.Resources.TryGetValue(accent ? "AccentButtonStyle" : "DefaultButtonStyle", out var value)
            ? value as Style
            : null;

    /// <summary>Brush from the merged theme dictionaries (Themes/Tokens.xaml), or a fallback.</summary>
    public static Brush ThemeBrush(string key) =>
        Application.Current.Resources.TryGetValue(key, out var value) && value is Brush brush
            ? brush
            : new SolidColorBrush(Colors.Gray);

    [LibraryImport("user32.dll")]
    private static partial uint GetDpiForWindow(nint hwnd);

    [StructLayout(LayoutKind.Sequential)]
    private struct ClientRect
    {
        public int Left, Top, Right, Bottom;
    }

    [LibraryImport("user32.dll")]
    [return: MarshalAs(UnmanagedType.Bool)]
    private static partial bool GetClientRect(nint hwnd, out ClientRect rect);

    [LibraryImport("user32.dll")]
    private static partial int SetForegroundWindow(nint hwnd);
}
