using System.Runtime.InteropServices;
using Microsoft.UI.Text;
using Microsoft.UI.Windowing;
using Microsoft.UI.Xaml;
using Microsoft.UI.Xaml.Controls;
using Microsoft.UI.Xaml.Input;
using Windows.Graphics;
using Windows.System;

namespace MoldSign.App.Services;

/// <summary>
/// PIN QSCD window (docs/10 §4.3), the Windows twin of the macOS auth panel: a small always-on-top window centered on
/// the screen under the pointer, so it never depends on where (or whether) the main window is shown and never hides
/// behind the browser that asked for the signature. 4–8 digits, no paste, Enter signs, Escape or close cancels.
/// </summary>
internal sealed partial class PinWindow : Window
{
    private const double ContentWidth = 480;

    private readonly TaskCompletionSource<(string? Pin, bool Remember)> _result =
        new(TaskCreationOptions.RunContinuationsAsynchronously);
    private readonly Grid _root = new() { Padding = new Thickness(28, 20, 28, 24), RowSpacing = 16 };
    private readonly PasswordBox _box = new()
    {
        MaxLength = 8,
        FontSize = 28,
        MinHeight = 56,
        Padding = new Thickness(20, 10, 20, 10),
        HorizontalContentAlignment = HorizontalAlignment.Center,
        PlaceholderText = "••••",
        Width = 300,
        HorizontalAlignment = HorizontalAlignment.Center,
        InputScope = new InputScope { Names = { new InputScopeName(InputScopeNameValue.NumericPin) } },
    };
    private readonly CheckBox _remember = new() { Content = Loc.Get("Pin_Remember") };
    private readonly Button _sign = new() { Content = Loc.Get("Action_Sign"), IsEnabled = false, MinWidth = 120 };

    public PinWindow(string heading, IReadOnlyList<string> details, bool remember, int? attemptsLeft,
                     ElementTheme? appearance = null)
    {
        _root.RequestedTheme = appearance ?? (App.Current.Services.Settings.Theme switch
        {
            "light" => ElementTheme.Light,
            "dark" => ElementTheme.Dark,
            _ => ElementTheme.Default,
        });
        Title = Loc.Get("Pin_Title");
        AppWindow.Title = Loc.Get("Pin_Title");
        AppWindow.SetIcon(Path.Combine(AppContext.BaseDirectory, "Assets", "AppIcon.ico"));
        AppWindow.IsShownInSwitchers = true;
        if (AppWindow.Presenter is OverlappedPresenter presenter)
        {
            presenter.IsResizable = false;
            presenter.IsMaximizable = false;
            presenter.IsMinimizable = false;
            presenter.IsAlwaysOnTop = true;
        }
        WindowHelpers.ApplyMica(this);

        var text = new StackPanel { Spacing = 6 };
        text.Children.Add(new FontIcon
        {
            Glyph = "\uE72E", // Lock
            FontSize = 28,
            HorizontalAlignment = HorizontalAlignment.Center,
            Foreground = WindowHelpers.ThemeBrush("BrandBrush"),
        });
        text.Children.Add(new TextBlock
        {
            Text = Loc.Get("Pin_Title"), FontSize = 20, FontWeight = FontWeights.SemiBold,
            HorizontalAlignment = HorizontalAlignment.Center,
        });
        text.Children.Add(new TextBlock
        {
            Text = heading, TextWrapping = TextWrapping.Wrap, TextAlignment = TextAlignment.Center,
            HorizontalAlignment = HorizontalAlignment.Center,
        });
        var documentDetails = new StackPanel { Spacing = 6 };
        foreach (var line in details)
        {
            documentDetails.Children.Add(new TextBlock
            {
                Text = SignatureLabels.Human(line), TextWrapping = TextWrapping.Wrap, TextAlignment = TextAlignment.Center,
                HorizontalAlignment = HorizontalAlignment.Center, Opacity = 0.75,
            });
        }

        if (details.Count > 0) text.Children.Add(new ScrollViewer
        {
            MaxHeight = 180, VerticalScrollBarVisibility = ScrollBarVisibility.Auto,
            HorizontalScrollBarVisibility = ScrollBarVisibility.Disabled, Content = documentDetails,
        });

        _box.Paste += (_, e) => e.Handled = true;
        _box.PasswordChanged += (_, _) => _sign.IsEnabled = IsValid;
        _remember.IsChecked = remember;

        var form = new StackPanel { Spacing = 10 };
        form.Children.Add(_box);
        form.Children.Add(_remember);
        if (attemptsLeft is { } left)
        {
            form.Children.Add(new TextBlock
            {
                Text = Loc.Format("Pin_Attempts", left),
                Foreground = WindowHelpers.ThemeBrush(left <= 2 ? "WarningBrush" : "TextFillColorSecondaryBrush"),
            });
        }

        var cancel = new Button { Content = Loc.Get("Action_Cancel"), MinWidth = 120 };
        cancel.Click += (_, _) => Finish(null);
        _sign.Style = WindowHelpers.ButtonStyle(accent: true);
        _sign.Click += (_, _) => Submit();
        var buttons = new Grid { ColumnSpacing = 12 };
        buttons.ColumnDefinitions.Add(new ColumnDefinition { Width = GridLength.Auto });
        buttons.ColumnDefinitions.Add(new ColumnDefinition { Width = new GridLength(1, GridUnitType.Star) });
        buttons.ColumnDefinitions.Add(new ColumnDefinition { Width = GridLength.Auto });
        buttons.Children.Add(cancel);
        Grid.SetColumn(_sign, 2);
        buttons.Children.Add(_sign);

        _root.RowDefinitions.Add(new RowDefinition { Height = GridLength.Auto });
        _root.RowDefinitions.Add(new RowDefinition { Height = GridLength.Auto });
        _root.RowDefinitions.Add(new RowDefinition { Height = GridLength.Auto });
        _root.Children.Add(text);
        Grid.SetRow(form, 1);
        _root.Children.Add(form);
        Grid.SetRow(buttons, 2);
        _root.Children.Add(buttons);
        _root.Width = ContentWidth;
        _root.HorizontalAlignment = HorizontalAlignment.Center;
        _root.VerticalAlignment = VerticalAlignment.Center;
        _root.PreviewKeyDown += OnKeyDown;
        _root.Loaded += (_, _) =>
        {
            FitAndCenter();
            _box.Focus(FocusState.Programmatic);
        };
        Content = _root;

        AppWindow.Closing += (_, _) => _result.TrySetResult((null, false));
    }

#if DEBUG
    internal bool HasEmptyPin => _box.Password.Length == 0;
    internal void ClearPreviewPlaceholder() => _box.PlaceholderText = " ";
#endif

    private bool IsValid => _box.Password.Length is >= 4 and <= 8 && _box.Password.All(char.IsAsciiDigit);

    /// <summary>Shows the window centered and in front; completes with the PIN, or null when cancelled.</summary>
    public async Task<(string? Pin, bool Remember)> ShowAsync(CancellationToken cancellationToken)
    {
        FitAndCenter(estimatedHeight: 360);
        using var registration = cancellationToken.Register(() => DispatcherQueue.TryEnqueue(() => Finish(null)));
        AppWindow.Show();
        Activate();
        _ = SetForegroundWindow(WindowHelpers.Handle(this));
        return await _result.Task;
    }

    private void OnKeyDown(object sender, KeyRoutedEventArgs e)
    {
        if (e.Key == VirtualKey.Escape)
        {
            e.Handled = true;
            Finish(null);
        }
        else if (e.Key == VirtualKey.Enter && IsValid)
        {
            e.Handled = true;
            Submit();
        }
    }

    private void Submit()
    {
        if (IsValid) Finish(_box.Password);
    }

    private void Finish(string? pin)
    {
        if (!_result.TrySetResult(pin is null ? (null, false) : (pin, _remember.IsChecked == true))) return;
        _box.Password = "";
        Close();
    }

    /// <summary>Client size from the measured content, window centered in the work area of the display under the pointer.</summary>
    private void FitAndCenter(double? estimatedHeight = null)
    {
        var scale = WindowHelpers.Scale(this);
        var height = estimatedHeight ?? MeasuredHeight();
        AppWindow.ResizeClient(new SizeInt32((int)Math.Ceiling(ContentWidth * scale), (int)Math.Ceiling(height * scale)));
        _ = GetCursorPos(out var cursor);
        var area = DisplayArea.GetFromPoint(new PointInt32(cursor.X, cursor.Y), DisplayAreaFallback.Primary).WorkArea;
        var size = AppWindow.Size;
        AppWindow.Move(new PointInt32(area.X + (area.Width - size.Width) / 2, area.Y + (area.Height - size.Height) / 2));
    }

    private double MeasuredHeight()
    {
        _root.Measure(new Windows.Foundation.Size(ContentWidth, double.PositiveInfinity));
        return Math.Max(_root.DesiredSize.Height, 240);
    }

    [StructLayout(LayoutKind.Sequential)]
    private struct NativePoint
    {
        public int X;
        public int Y;
    }

    [LibraryImport("user32.dll")]
    [return: MarshalAs(UnmanagedType.Bool)]
    private static partial bool GetCursorPos(out NativePoint point);

    [LibraryImport("user32.dll")]
    private static partial int SetForegroundWindow(nint hwnd);
}
