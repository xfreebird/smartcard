using Microsoft.UI.Xaml;
using Microsoft.UI.Xaml.Automation;
using Microsoft.UI.Xaml.Automation.Peers;
using Microsoft.UI.Xaml.Controls;
using Microsoft.UI.Xaml.Controls.Primitives;
using Microsoft.UI.Xaml.Input;
using Microsoft.UI.Xaml.Media;
using Windows.Foundation;
using Windows.System;
using Windows.UI;

namespace MoldSign.App.Controls;

/// <summary>Horizontal, keyboard-accessible card carousel. Selection always uses the wallet's reader identity.</summary>
public sealed partial class CardWallet : UserControl
{
    public const double CompactMaxWidth = 480;
    public const double LargeMaxWidth = 560;
    private const double Pad = 4;
    private readonly ScrollViewer _scroller = new()
    {
        HorizontalScrollMode = ScrollMode.Enabled,
        HorizontalScrollBarVisibility = ScrollBarVisibility.Hidden,
        VerticalScrollMode = ScrollMode.Disabled,
        VerticalScrollBarVisibility = ScrollBarVisibility.Disabled,
        HorizontalSnapPointsType = SnapPointsType.None,
        IsVerticalScrollChainingEnabled = true,
        HorizontalSnapPointsAlignment = SnapPointsAlignment.Center,
    };
    private readonly StackPanel _cards = new() { Orientation = Orientation.Horizontal, Spacing = 0 };
    private readonly StackPanel _navigation = new() { Orientation = Orientation.Horizontal, Spacing = 2, Margin = new Thickness(0, 4, 0, 4), HorizontalAlignment = HorizontalAlignment.Center };
    private readonly Grid _viewport = new() { HorizontalAlignment = HorizontalAlignment.Stretch,
        Background = new SolidColorBrush(Microsoft.UI.Colors.Transparent) };
    private readonly Button _previous;
    private readonly Button _next;
    private double _width;
    private double _pageWidth;
    private bool _rendering;
    private bool _alignSelection;
    private bool _pointerOverCard;

    public CardWallet()
    {
        HorizontalAlignment = HorizontalAlignment.Stretch;
        var panel = new StackPanel { Spacing = 4 };
        _scroller.Content = _cards;
        AutomationProperties.SetAutomationId(_scroller, "CardCarouselViewport");
        _previous = CreateArrow("\uE76B", "Wallet_Previous", "CardPrevious", HorizontalAlignment.Left);
        _next = CreateArrow("\uE76C", "Wallet_Next", "CardNext", HorizontalAlignment.Right);
        _previous.Click += (_, _) => Step(-1);
        _next.Click += (_, _) => Step(1);
        _viewport.Children.Add(_scroller);
        _viewport.Children.Add(_previous);
        _viewport.Children.Add(_next);
        _viewport.AddHandler(PointerEnteredEvent, new PointerEventHandler((_, _) => { _pointerOverCard = true; UpdateArrows(); }), true);
        _viewport.AddHandler(PointerMovedEvent, new PointerEventHandler((_, _) => { if (!_pointerOverCard) { _pointerOverCard = true; UpdateArrows(); } }), true);
        _viewport.AddHandler(PointerExitedEvent, new PointerEventHandler((_, _) => { _pointerOverCard = false; UpdateArrows(); }), true);
        panel.Children.Add(_viewport);
        panel.Children.Add(_navigation);
        Content = panel;
        _scroller.ViewChanged += (_, e) =>
        {
            if (e.IsIntermediate || _rendering || _width <= 0 || _alignSelection) return;
            var cards = Wallet.Items.Where(c => c.IsCard).ToList();
            if (cards.Count < 2) return;
            var index = Math.Clamp((int)Math.Round(_scroller.HorizontalOffset / _pageWidth), 0, cards.Count - 1);
            Select(cards[index]);
            AlignSelection();
        };
        // Route before the native horizontal ScrollViewer handles the wheel, so selection cannot change.
        _cards.AddHandler(PointerWheelChangedEvent, new PointerEventHandler((_, e) =>
        {
            if (RouteVerticalWheel(e)) e.Handled = true;
        }), handledEventsToo: true);
        _scroller.SizeChanged += (_, _) => AlignSelection();
        Loaded += (_, _) => Render();
    }

    public static readonly DependencyProperty WalletProperty = DependencyProperty.Register(
        nameof(Wallet), typeof(CardWalletContent), typeof(CardWallet),
        new PropertyMetadata(CardWalletContent.Empty, (sender, _) =>
        {
            var control = (CardWallet)sender;
            control.InvalidateMeasure();
            control.Render();
        }));

    public CardWalletContent Wallet
    {
        get => (CardWalletContent)GetValue(WalletProperty);
        set => SetValue(WalletProperty, value);
    }
    public event EventHandler<string>? CardSelected;
    public bool IsCompact { get; set; } = true;
    // Kept for existing tray sizing: the carousel never expands vertically.
    public double MaxExpandedHeight { get; set; } = double.PositiveInfinity;
    public bool IsExpanded => false;
    public bool IsSelectionCentered => Wallet.CardCount < 2 || Math.Abs(_scroller.HorizontalOffset - TargetOffset) < 1;
    private double TargetOffset => Math.Max(0, Wallet.SelectedIndex) * _pageWidth;
    public double CollapsedHeight => _width / IdCardFace.AspectRatio + 2 * Pad + (Wallet.CardCount > 1 ? 34 : 0);
    public double ExpandedExtraHeight => 0;
    public event EventHandler? ExpandedChanged;
    public event EventHandler? CardActivated;
    public void Collapse() { }

    protected override Size MeasureOverride(Size availableSize)
    {
        var fallback = IsCompact ? CompactMaxWidth : LargeMaxWidth;
        var outer = double.IsInfinity(availableSize.Width) ? fallback : Math.Max(1, availableSize.Width);
        // Each card occupies a full viewport page. Neighbours are never clipped into decorative slivers.
        // The card itself stays readable and centered; hover arrows live in the surrounding gutters.
        var gutter = Wallet.CardCount > 1 ? Math.Min(88, Math.Max(0, outer - 120)) : 8;
        var width = Math.Max(1, Math.Floor(Math.Min(IsCompact ? 288 : 360, outer - gutter) - 2 * Pad));
        _cards.Padding = new Thickness(0);
        if (Math.Abs(width - _width) > 0.5 || Math.Abs(outer - _pageWidth) > 0.5)
        {
            _width = width;
            _pageWidth = outer;
            DispatcherQueue.TryEnqueue(Render);
        }
        _scroller.Width = outer;
        _viewport.Width = outer;
        return base.MeasureOverride(new Size(outer, availableSize.Height));
    }

    private void Render()
    {
        if (_width <= 0) return;
        _rendering = true;
        AutomationProperties.SetName(_previous, Wallet.PreviousLabel);
        AutomationProperties.SetName(_next, Wallet.NextLabel);
        ToolTipService.SetToolTip(_previous, Wallet.PreviousLabel);
        ToolTipService.SetToolTip(_next, Wallet.NextLabel);
        _cards.Children.Clear();
        var items = Wallet.Items.ToList();
        foreach (var item in items)
        {
            if (!item.IsCard)
            {
                // Reader instructions are a static dotted rectangle, not another button/group box.
                var empty = new IdCardFace(item, _width) { Margin = new Thickness(Pad), HorizontalAlignment = HorizontalAlignment.Center };
                _cards.Children.Add(new Grid
                {
                    Width = _pageWidth, Height = _width / IdCardFace.AspectRatio + 2 * Pad,
                    Children = { empty },
                });
                continue;
            }
            var button = new Button
            {
                Width = _width + 2 * Pad,
                HorizontalAlignment = HorizontalAlignment.Center,
                Height = _width / IdCardFace.AspectRatio + 2 * Pad,
                Padding = new Thickness(item.IsSelected && Wallet.CardCount > 1 ? Pad - 2 : Pad),
                Opacity = item.IsSelected || Wallet.CardCount < 2 ? 1 : 0.65,
                RenderTransformOrigin = new Point(0.5, 0.5),
                RenderTransform = new ScaleTransform { ScaleX = item.IsSelected ? 1 : 0.94, ScaleY = item.IsSelected ? 1 : 0.94 },
                BorderThickness = new Thickness(item.IsSelected && Wallet.CardCount > 1 ? 2 : 0),
                BorderBrush = ControlTheme.Brush("SystemControlHighlightAccentBrush"),
                Background = new SolidColorBrush(Microsoft.UI.Colors.Transparent),
                HorizontalContentAlignment = HorizontalAlignment.Center,
                VerticalContentAlignment = VerticalAlignment.Center,
                Content = new IdCardFace(item, _width),
            };
            AutomationProperties.SetAutomationId(button, $"WalletCard{items.IndexOf(item) + 1}");
            AutomationProperties.SetItemStatus(button, item.IsSelected ? Wallet.SelectedLabel : "");
            AutomationProperties.SetName(button, item.AccessibilityLabel);
            button.Click += (_, _) =>
            {
                if (item.IsSelected || !item.IsCard) CardActivated?.Invoke(this, EventArgs.Empty);
                else Select(item);
            };
            _cards.Children.Add(new Grid
            {
                Width = _pageWidth,
                Children = { button },
            });
        }
        _navigation.Visibility = Wallet.CardCount > 1 ? Visibility.Visible : Visibility.Collapsed;
        _navigation.Children.Clear();
        for (var index = 0; index < Wallet.CardCount; index++)
        {
            var dot = new Microsoft.UI.Xaml.Shapes.Ellipse
            {
                Width = 7, Height = 7,
                Fill = ControlTheme.Brush("SystemControlHighlightAccentBrush"),
                Opacity = index == Wallet.SelectedIndex ? 1 : 0.3,
            };
            AutomationProperties.SetAccessibilityView(dot, AccessibilityView.Raw);
            var cardIndex = index;
            var button = new Button
            {
                Width = 22, Height = 22, MinWidth = 0, MinHeight = 0, Padding = new Thickness(0),
                Background = new SolidColorBrush(Microsoft.UI.Colors.Transparent),
                BorderThickness = new Thickness(0), Content = dot,
                HorizontalContentAlignment = HorizontalAlignment.Center,
                VerticalContentAlignment = VerticalAlignment.Center,
            };
            var cards = Wallet.Items.Where(c => c.IsCard).ToList();
            if (cardIndex < cards.Count)
                AutomationProperties.SetName(button, cards[cardIndex].AccessibilityLabel);
            button.Click += (_, _) => { if (cardIndex < cards.Count) Select(cards[cardIndex]); };
            _navigation.Children.Add(button);
        }
        UpdateArrows();
        _rendering = false;
        _alignSelection = true;
        DispatcherQueue.TryEnqueue(AlignSelection);
        ExpandedChanged?.Invoke(this, EventArgs.Empty);
    }

    private void AlignSelection()
    {
        if (Math.Abs(_scroller.HorizontalOffset - TargetOffset) > 0.5)
            _scroller.ChangeView(TargetOffset, null, null, disableAnimation: true);
        _alignSelection = false;
    }

    private static Button CreateArrow(string glyph, string labelKey, string automationId, HorizontalAlignment alignment)
    {
        var button = new Button
        {
            Width = 32, Height = 32, MinWidth = 0, MinHeight = 0, Padding = new Thickness(0),
            Margin = new Thickness(10, 0, 10, 0), CornerRadius = new CornerRadius(16),
            Background = new SolidColorBrush(Color.FromArgb(230, 255, 255, 255)),
            BorderBrush = new SolidColorBrush(Color.FromArgb(100, 30, 30, 30)),
            BorderThickness = new Thickness(1),
            Foreground = new SolidColorBrush(Microsoft.UI.Colors.Black),
            HorizontalAlignment = alignment, VerticalAlignment = VerticalAlignment.Center,
            HorizontalContentAlignment = HorizontalAlignment.Center, VerticalContentAlignment = VerticalAlignment.Center,
            Content = new FontIcon { Glyph = glyph, FontSize = 12 }, Visibility = Visibility.Collapsed,
        };
        AutomationProperties.SetName(button, labelKey);
        AutomationProperties.SetAutomationId(button, automationId);
        ToolTipService.SetToolTip(button, labelKey);
        return button;
    }

    private void UpdateArrows()
    {
        var visibility = _pointerOverCard && Wallet.CardCount > 1 ? Visibility.Visible : Visibility.Collapsed;
        _previous.Visibility = visibility;
        _next.Visibility = visibility;
        _previous.IsEnabled = !Wallet.IsBusy && Wallet.SelectedIndex > 0;
        _next.IsEnabled = !Wallet.IsBusy && Wallet.SelectedIndex < Wallet.CardCount - 1;
    }

    private bool RouteVerticalWheel(PointerRoutedEventArgs e)
    {
        var pointer = e.GetCurrentPoint(this).Properties;
        if (pointer.IsHorizontalMouseWheel) return false;
        for (var ancestor = VisualTreeHelper.GetParent(this); ancestor is not null; ancestor = VisualTreeHelper.GetParent(ancestor))
        {
            if (ancestor is not ScrollViewer page || page.ScrollableHeight <= 0) continue;
            var offset = Math.Clamp(page.VerticalOffset - pointer.MouseWheelDelta * 0.5, 0, page.ScrollableHeight);
            page.ChangeView(null, offset, null, disableAnimation: true);
            return true;
        }
        return false;
    }

    private void Step(int delta)
    {
        var cards = Wallet.Items.Where(c => c.IsCard).ToList();
        if (cards.Count < 2 || Wallet.IsBusy) return;
        var current = Math.Clamp(Wallet.SelectedIndex, 0, cards.Count - 1);
        var target = Math.Clamp(current + delta, 0, cards.Count - 1);
        if (target != current) Select(cards[target]);
    }

    private void Select(IdentityCardContent item)
    {
        if (!Wallet.IsBusy && item.Reader is { } reader) CardSelected?.Invoke(this, reader);
    }

    protected override void OnKeyDown(KeyRoutedEventArgs e)
    {
        if (e.Key is VirtualKey.Left or VirtualKey.Right)
        {
            Step(e.Key == VirtualKey.Left ? -1 : 1);
            e.Handled = true;
            return;
        }
        base.OnKeyDown(e);
    }
}
