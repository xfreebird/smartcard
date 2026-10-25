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
    public const int FlyoutHeight = 600;

    /// <summary>docs/10 §2: main window min 860 × 580.</summary>
    public const int MainMinWidth = 860;
    public const int MainMinHeight = 580;

    public static nint Handle(Window window) => WinRT.Interop.WindowNative.GetWindowHandle(window);

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
        window.AppWindow.Resize(new SizeInt32((int)(1100 * scale), (int)(720 * scale)));
        if (window.AppWindow.Presenter is OverlappedPresenter presenter)
        {
            presenter.PreferredMinimumWidth = (int)(MainMinWidth * scale);
            presenter.PreferredMinimumHeight = (int)(MainMinHeight * scale);
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
    /// Bottom-right corner of the primary work area, i.e. above the notification area for the default
    /// taskbar position. TODO(WIN-04): follow the taskbar edge (top/left/right) and the monitor the icon is on.
    /// </summary>
    public static void PlaceNearTray(Window window)
    {
        var scale = Scale(window);
        var width = (int)(FlyoutWidth * scale);
        var height = (int)(FlyoutHeight * scale);
        var margin = (int)(12 * scale);
        var area = DisplayArea.Primary.WorkArea;
        window.AppWindow.MoveAndResize(new RectInt32(
            area.X + area.Width - width - margin,
            area.Y + area.Height - height - margin,
            width,
            height));
    }

    /// <summary>HWND of the window hosting <paramref name="root"/> (pickers need it in unpackaged apps).</summary>
    public static nint HandleFor(XamlRoot root) =>
        Win32Interop.GetWindowFromWindowId(root.ContentIslandEnvironment.AppWindowId);

    /// <summary>Multi-file open picker owned by the window of <paramref name="root"/>; empty when cancelled.</summary>
    public static async Task<IReadOnlyList<string>> PickFilesAsync(XamlRoot root, params string[] extensions)
    {
        var picker = new Windows.Storage.Pickers.FileOpenPicker();
        WinRT.Interop.InitializeWithWindow.Initialize(picker, HandleFor(root));
        if (extensions.Length == 0) picker.FileTypeFilter.Add("*");
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

    /// <summary>Brush from the merged theme dictionaries (Themes/Tokens.xaml), or a fallback.</summary>
    public static Brush ThemeBrush(string key) =>
        Application.Current.Resources.TryGetValue(key, out var value) && value is Brush brush
            ? brush
            : new SolidColorBrush(Colors.Gray);

    [LibraryImport("user32.dll")]
    private static partial uint GetDpiForWindow(nint hwnd);
}
