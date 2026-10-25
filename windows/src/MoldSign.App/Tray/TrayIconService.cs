using H.NotifyIcon;
using Microsoft.UI;
using Microsoft.UI.Xaml.Controls;
using Microsoft.UI.Xaml.Media;
using MoldSign.App.Services;
using Windows.UI;

namespace MoldSign.App.Tray;

/// <summary>
/// Notification-area icon (WIN-04, H.NotifyIcon.WinUI). Left click toggles the flyout (docs/10 §4.6, mirrors
/// the macOS popover); right click shows the native menu (Deschide fereastra / Ieșire).
/// The icon is generated (no binary asset): dimmed with no reader, brand when ready, "!" on error.
/// </summary>
public sealed class TrayIconService(Action toggleFlyout, Action openWindow, Action quit) : IDisposable
{
    private static readonly Color Brand = Color.FromArgb(0xFF, 0x23, 0x50, 0xD8);
    private static readonly Color Muted = Color.FromArgb(0xFF, 0x6B, 0x72, 0x80);
    private static readonly Color Danger = Color.FromArgb(0xFF, 0xC6, 0x28, 0x28);

    private TaskbarIcon? _icon;
    private StatusKind? _shown;

    public void Create()
    {
        if (_icon is not null) return;

        var menu = new MenuFlyout();
        menu.Items.Add(new MenuFlyoutItem { Text = Loc.Get("Tray_OpenWindow"), Command = new RelayCommand(openWindow) });
        menu.Items.Add(new MenuFlyoutSeparator());
        menu.Items.Add(new MenuFlyoutItem { Text = Loc.Get("Tray_Quit"), Command = new RelayCommand(quit) });

        _icon = new TaskbarIcon
        {
            ToolTipText = "MoldSign",
            ContextMenuMode = ContextMenuMode.PopupMenu,
            ContextFlyout = menu,
            LeftClickCommand = new RelayCommand(toggleFlyout),
            NoLeftClickDelay = true,
        };
        Update(StatusKind.NoReader, Loc.Get("Status_NoReader"));
        _icon.ForceCreate();
        // TODO(WIN-04): accept files dropped on the flyout/taskbar entry; the notification area itself has no drop target.
    }

    public void Update(StatusKind kind, string statusLine)
    {
        if (_icon is null) return;
        _icon.ToolTipText = $"MoldSign · {statusLine}";
        if (_shown == kind) return;
        _shown = kind;
        _icon.IconSource = new GeneratedIconSource
        {
            Text = kind switch
            {
                StatusKind.Error => "!",
                StatusKind.Busy or StatusKind.Reading => "…",
                _ => "✍",
            },
            Foreground = new SolidColorBrush(Colors.White),
            Background = new SolidColorBrush(kind switch
            {
                StatusKind.Error => Danger,
                StatusKind.NoReader or StatusKind.Empty => Muted,
                _ => Brand,
            }),
            FontSize = 36,
        };
    }

    public void Dispose()
    {
        _icon?.Dispose();
        _icon = null;
    }
}
