using System.Numerics;
using Microsoft.UI;
using Microsoft.UI.Input;
using Microsoft.UI.Xaml;
using Microsoft.UI.Xaml.Automation;
using Microsoft.UI.Xaml.Automation.Peers;
using Microsoft.UI.Xaml.Automation.Provider;
using Microsoft.UI.Xaml.Controls;
using Microsoft.UI.Xaml.Input;
using Microsoft.UI.Xaml.Media;
using Microsoft.UI.Xaml.Media.Animation;
using MoldSign.App.Services;
using Windows.Foundation;
using Windows.System;
using Windows.UI;
using Windows.UI.ViewManagement;

namespace MoldSign.App.Controls;

/// <summary>
/// The card and its selector in ONE component (docs/10 §0.2b, UX-10 revised). Collapsed, it shows only the selected
/// card as the ID-card illustration (<see cref="IdCardFace"/>). With more than one card a round disclosure button sits
/// inside the card (centre 0.935 W, 0.50 H; chevron right, turning down when expanded):
/// <list type="bullet">
/// <item>it expands the component IN PLACE into a vertical list of every card, same size, in reader order, 11 epx apart;
///       the selected one keeps an accent ring, the check badge "Folosit pentru semnare" and the disclosure button;</item>
/// <item>a click on another card makes it the signing card and collapses the list; the disclosure, Escape or a click
///       on the selected card collapse without change (Fluent theme transitions, none when animations are off);</item>
/// <item>keyboard: Space/Enter on the disclosure, ←/→ on the collapsed card, ↑/↓ in the list, Escape;</item>
/// <item>context menu (right click, Shift+F10, Menu key): "Recitește cardul" and "Semnează cu {holder}".</item>
/// </list>
/// Nothing sits outside the card: no capsule, menu, dots or carousel. With no card it is the dashed empty-state card.
/// UI Automation: collapsed, the component is one adjustable element ("{holder}, card de identitate, valabil până la …,
/// {i} din {n}", RangeValue); the disclosure is "Alege cardul ({n} carduri)" with ExpandCollapse; expanded, every card
/// is a button "Semnează cu {holder}" with SelectionItem (the selected one reports selected).
/// Code-only (no XAML), so every part is compile-checked.
/// </summary>
public sealed partial class CardWallet : UserControl
{
    public const double CompactMaxWidth = 328;
    public const double LargeMaxWidth = 420;

    /// <summary>Room around each card for the accent ring of the selected card.</summary>
    private const double Pad = 4;
    private const double ListSpacing = 11;

    private static readonly UISettings s_ui = new();

    private readonly ScrollViewer _scroller = new()
    {
        HorizontalScrollMode = ScrollMode.Disabled,
        HorizontalScrollBarVisibility = ScrollBarVisibility.Disabled,
        VerticalScrollMode = ScrollMode.Auto,
        VerticalScrollBarVisibility = ScrollBarVisibility.Auto,
        IsTabStop = false,
    };
    private readonly StackPanel _panel = new() { Spacing = ListSpacing };
    private readonly EntranceThemeTransition _entrance = new() { IsStaggeringEnabled = false };
    private readonly TransitionCollection _transitions = [];
    private readonly MenuFlyout _contextMenu = new();
    private readonly Dictionary<string, CardSlot> _slots = new(StringComparer.Ordinal);

    private double _faceWidth;
    private bool _expanded;
    private string _shownName = "";
    private int _shownPosition;
    private int _pendingDirection;

    public CardWallet()
    {
        IsTabStop = true;
        UseSystemFocusVisuals = true;
        HorizontalAlignment = HorizontalAlignment.Left;
        _transitions.Add(_entrance);
        _transitions.Add(new RepositionThemeTransition { IsStaggeringEnabled = false });
        _scroller.Content = _panel;
        Content = _scroller;

        ContextFlyout = _contextMenu;
        _contextMenu.Opening += OnContextMenuOpening;

        Loaded += (_, _) =>
        {
            State.WalletChanged += OnWalletChanged;
            Render();
        };
        Unloaded += (_, _) => State.WalletChanged -= OnWalletChanged;
    }

    public AppState State => AppState.Current;

    /// <summary>Compact (up to 328 wide: tray flyout, Sign page) or large (up to 420: Card page).</summary>
    public bool IsCompact { get; set; } = true;

    /// <summary>Cap for the expanded list; beyond it the list scrolls (the tray flyout sets it from the screen height).</summary>
    public double MaxExpandedHeight
    {
        get => _scroller.MaxHeight;
        set => _scroller.MaxHeight = value;
    }

    public bool IsExpanded => _expanded;

    /// <summary>Height of the collapsed component (one card + ring padding), epx.</summary>
    public double CollapsedHeight => _faceWidth > 0 ? SlotHeight : 0;

    /// <summary>How much taller than collapsed the component is now (epx), for hosts that size their window.</summary>
    public double ExpandedExtraHeight =>
        _expanded ? Math.Min((_panel.Children.Count - 1) * (SlotHeight + ListSpacing), Math.Max(0, MaxExpandedHeight - SlotHeight)) : 0;

    /// <summary>Raised when the list expands or collapses, or its length changes while expanded.</summary>
    public event EventHandler? ExpandedChanged;

    /// <summary>Click on the collapsed card itself (not the disclosure): the flyout opens the Card page. Never destructive.</summary>
    public event EventHandler? CardActivated;

    internal string AutomationName => _shownName;
    internal int Position => _shownPosition;
    internal int Count => State.CardCount;

    private double FaceHeight => _faceWidth / IdCardFace.AspectRatio;
    private double SlotHeight => FaceHeight + 2 * Pad;

    private static bool AnimationsEnabled
    {
        get
        {
            try
            {
                return s_ui.AnimationsEnabled;
            }
            catch (Exception)
            {
                return true;
            }
        }
    }

    /// <summary>Collapses the list without changing the selection (the flyout calls it when it hides).</summary>
    public void Collapse() => SetExpanded(false, focusSelf: false);

    // MARK: - Layout: W from the available width (minus the ring padding), H = W / 1.586

    protected override Size MeasureOverride(Size availableSize)
    {
        var max = IsCompact ? CompactMaxWidth : LargeMaxWidth;
        var outer = double.IsInfinity(availableSize.Width) ? max : Math.Min(availableSize.Width, max);
        var width = Math.Max(Math.Floor(outer - 2 * Pad), 200);
        if (Math.Abs(width - _faceWidth) > 0.5)
        {
            _faceWidth = width;
            DispatcherQueue.TryEnqueue(() => Render()); // never change children inside Measure
        }
        _scroller.Measure(new Size(width + 2 * Pad, availableSize.Height));
        return new Size(width + 2 * Pad, Math.Max(_scroller.DesiredSize.Height, _faceWidth > 0 ? SlotHeight : 0));
    }

    protected override AutomationPeer OnCreateAutomationPeer() => new CardWalletAutomationPeer(this);

    // MARK: - Rendering

    private void OnWalletChanged(object? sender, EventArgs e)
    {
        var direction = _pendingDirection != 0 ? _pendingDirection : Math.Sign(State.SelectedIndex + 1 - _shownPosition);
        _pendingDirection = 0;
        Render(direction);
    }

    private List<WalletCardItem> Cards() => State.WalletItems.Where(i => i.Kind == WalletItemKind.Card).ToList();

    /// <summary>Reconciles the slots with the model: collapsed = the selected card; expanded = every card.</summary>
    private void Render(int direction = 0)
    {
        if (_faceWidth <= 0 || State.WalletItems.Count == 0) return;
        var cards = Cards();
        var wasExpanded = _expanded;
        var previousCount = _panel.Children.Count;
        if (cards.Count < 2) _expanded = false;

        var selected = State.SelectedItem ?? cards.FirstOrDefault();
        List<WalletCardItem> wanted = cards.Count == 0 ? [State.WalletItems[0]] : _expanded ? cards : [selected!];

        // Motion: entering cards slide in (sideways for ←/→, from above for the list), moved cards reposition.
        _panel.ChildrenTransitions = AnimationsEnabled ? _transitions : null;
        _entrance.FromHorizontalOffset = _expanded ? 0 : 32 * direction;
        _entrance.FromVerticalOffset = _expanded ? -12 : 0;

        var keep = wanted.Select(SlotFor).ToList();
        for (var i = _panel.Children.Count - 1; i >= 0; i--)
        {
            if (_panel.Children[i] is CardSlot slot && !keep.Contains(slot)) _panel.Children.RemoveAt(i);
        }
        for (var i = 0; i < keep.Count; i++)
        {
            var at = _panel.Children.IndexOf(keep[i]);
            if (at < 0) _panel.Children.Insert(i, keep[i]);
            else if (at != i) _panel.Children.Move((uint)at, (uint)i);
        }
        foreach (var stale in _slots.Where(p => !keep.Contains(p.Value)).Select(p => p.Key).ToList())
            _slots.Remove(stale);

        for (var i = 0; i < keep.Count; i++)
        {
            var item = wanted[i];
            var isSelected = item.Kind == WalletItemKind.Card && item.IsSelected;
            keep[i].Update(item, _faceWidth, State.IsBusy && isSelected, isSelected, _expanded, cards.Count);
        }
        IsTabStop = !_expanded;

        UpdateAutomation(selected, cards.Count, animate: direction != 0 && !_expanded);
        if (wasExpanded != _expanded || (_expanded && previousCount != _panel.Children.Count))
            ExpandedChanged?.Invoke(this, EventArgs.Empty);
    }

    private CardSlot SlotFor(WalletCardItem item)
    {
        var key = item.Kind == WalletItemKind.Card ? $"card:{item.Reader}" : $"empty:{item.Kind}:{item.Reader}";
        if (!_slots.TryGetValue(key, out var slot)) _slots[key] = slot = new CardSlot(this);
        return slot;
    }

    private void UpdateAutomation(WalletCardItem? selected, int count, bool animate)
    {
        var position = Math.Max(0, State.SelectedIndex) + 1;
        var name = (selected ?? State.WalletItems[0]).AccessibleName(position, Math.Max(count, 1));
        var previousName = _shownName;
        var previousPosition = _shownPosition;
        _shownName = name;
        _shownPosition = position;
        if (FrameworkElementAutomationPeer.FromElement(this) is not { } peer || name == previousName) return;
        peer.RaisePropertyChangedEvent(AutomationElementIdentifiers.NameProperty, previousName, name);
        if (position != previousPosition)
            peer.RaisePropertyChangedEvent(RangeValuePatternIdentifiers.ValueProperty, (double)previousPosition, (double)position);
        if (animate)
        {
            peer.RaiseNotificationEvent(AutomationNotificationKind.ActionCompleted,
                AutomationNotificationProcessing.ImportantMostRecent, name, "CardSwitched");
        }
    }

    // MARK: - Expand / collapse / pick

    private void SetExpanded(bool expanded, bool focusSelf)
    {
        if (expanded && Cards().Count < 2) expanded = false;
        if (_expanded == expanded) return;
        _expanded = expanded;
        Render(); // the disclosure stays on the selected card and keeps focus; ↑/↓ move from there
        if (!expanded && focusSelf) Focus(FocusState.Keyboard);
    }

    /// <summary>A card was clicked: collapsed → open (CardActivated); in the list → pick it (or just collapse).</summary>
    private void OnCardClicked(CardSlot slot)
    {
        if (!_expanded)
        {
            CardActivated?.Invoke(this, EventArgs.Empty);
            return;
        }
        if (!slot.IsSelectedCard && slot.Item?.Reader is { } reader)
        {
            _expanded = false;               // collapse onto the picked card…
            App.Current.Services.SelectCard(reader); // …which re-renders through WalletChanged
            ExpandedChanged?.Invoke(this, EventArgs.Empty);
            Focus(FocusState.Programmatic);
            return;
        }
        SetExpanded(false, focusSelf: true);
    }

    /// <summary>Next (+1) / previous (−1) card on the collapsed component, wrapping around.</summary>
    internal void Step(int delta)
    {
        var cards = Cards();
        if (cards.Count < 2) return;
        var current = Math.Max(0, cards.FindIndex(c => c.IsSelected));
        _pendingDirection = Math.Sign(delta);
        Select(cards[(current + delta + cards.Count) % cards.Count]);
    }

    /// <summary>1-based position (RangeValue SetValue).</summary>
    internal void SelectPosition(int position)
    {
        var cards = Cards();
        if (position < 1 || position > cards.Count) return;
        _pendingDirection = Math.Sign(position - _shownPosition);
        Select(cards[position - 1]);
    }

    private static void Select(WalletCardItem card)
    {
        if (card.Reader is { } reader) App.Current.Services.SelectCard(reader);
    }

    protected override void OnKeyDown(KeyRoutedEventArgs e)
    {
        if (_expanded)
        {
            switch (e.Key)
            {
                case VirtualKey.Escape:
                    SetExpanded(false, focusSelf: true);
                    e.Handled = true;
                    return;
                case VirtualKey.Up or VirtualKey.Down or VirtualKey.GamepadDPadUp or VirtualKey.GamepadDPadDown:
                    MoveFocus(e.Key is VirtualKey.Up or VirtualKey.GamepadDPadUp ? -1 : +1);
                    e.Handled = true;
                    return;
            }
        }
        else if (e.Key is VirtualKey.Left or VirtualKey.GamepadDPadLeft or VirtualKey.Right or VirtualKey.GamepadDPadRight)
        {
            Step(e.Key is VirtualKey.Left or VirtualKey.GamepadDPadLeft ? -1 : +1);
            e.Handled = true;
            return;
        }
        base.OnKeyDown(e);
    }

    /// <summary>↑/↓ in the expanded list: focus the previous/next card.</summary>
    private void MoveFocus(int delta)
    {
        var slots = _panel.Children.OfType<CardSlot>().ToList();
        if (slots.Count == 0) return;
        var focused = XamlRoot is null ? null : FocusManager.GetFocusedElement(XamlRoot) as DependencyObject;
        var current = slots.FindIndex(s => s.Contains(focused));
        var next = current < 0 ? 0 : Math.Clamp(current + delta, 0, slots.Count - 1);
        slots[next].FocusCard(FocusState.Keyboard);
        slots[next].StartBringIntoView();
    }

    // MARK: - Context menu (unchanged by the revision)

    /// <summary>"Recitește cardul" for the selected card, plus "Semnează cu {holder}" for every other card.</summary>
    private void OnContextMenuOpening(object? sender, object e)
    {
        _contextMenu.Items.Clear();
        var selected = State.SelectedItem;
        if (selected is null)
        {
            _contextMenu.Items.Add(RereadItem(Loc.Get("Wallet_RereadAll"), reader: null));
            return;
        }
        _contextMenu.Items.Add(RereadItem(Loc.Get("Wallet_Reread"), selected.Reader));
        foreach (var other in Cards().Where(c => !c.IsSelected))
        {
            var entry = new MenuFlyoutItem
            {
                Text = Loc.Format("Wallet_SignWith", other.Holder),
                Icon = new FontIcon { Glyph = "" },
            };
            entry.Click += (_, _) => Select(other);
            _contextMenu.Items.Add(entry);
        }
    }

    private static MenuFlyoutItem RereadItem(string text, string? reader)
    {
        var item = new MenuFlyoutItem { Text = text, Icon = new FontIcon { Glyph = "" } };
        item.Click += (_, _) => App.Current.Services.RereadCards(reader);
        return item;
    }

    // MARK: - One card of the component

    /// <summary>
    /// One card: the face inside a borderless button, the accent ring (selected card in the list) and, on the selected
    /// card with more than one card inserted, the disclosure button. Reused across renders (keyed by reader) so
    /// entrance motion only plays for cards that really appear.
    /// </summary>
    private sealed partial class CardSlot : Grid
    {
        private readonly CardWallet _owner;
        private readonly CardButton _face = new();
        private readonly Border _ring = new() { BorderThickness = new Thickness(2), Visibility = Visibility.Collapsed };
        private readonly DisclosureButton _disclosure = new();
        private readonly Grid _chevron = new();
        private string _signature = "";

        public CardSlot(CardWallet owner)
        {
            _owner = owner;
            _face.Click += (_, _) => _owner.OnCardClicked(this);
            _face.Margin = new Thickness(Pad);
            _face.Shadow = new ThemeShadow();
            _disclosure.Click += (_, _) => _owner.SetExpanded(!_owner._expanded, focusSelf: false);
            _disclosure.Owner = owner;
            _disclosure.Content = _chevron;
            _chevron.Children.Add(new FontIcon { Glyph = "", Foreground = new SolidColorBrush(CardArt.Value) }); // ChevronRight
            Children.Add(_ring);
            Children.Add(_face);
            Children.Add(_disclosure);
        }

        public WalletCardItem? Item { get; private set; }

        public bool IsSelectedCard { get; private set; }

        public void FocusCard(FocusState state) => _face.Focus(state);

        public bool Contains(DependencyObject? element)
        {
            for (; element is not null; element = VisualTreeHelper.GetParent(element))
            {
                if (element == this) return true;
            }
            return false;
        }

        public void Update(WalletCardItem item, double width, bool signing, bool selected, bool expanded, int count)
        {
            Item = item;
            IsSelectedCard = selected;
            var height = width / IdCardFace.AspectRatio;
            var radius = 0.045 * width;
            var isCard = item.Kind == WalletItemKind.Card;
            var withDisclosure = isCard && selected && count > 1;
            var usedForSigning = expanded && selected;

            Width = width + 2 * Pad;
            Height = height + 2 * Pad;

            // Rebuild the face only when what it shows changed (keeps reading → ready from flickering the list).
            var signature = string.Join('|', item.Kind, item.Reader, item.Certificate?.Sha1, item.Problem, item.IsReading,
                                        signing, withDisclosure, usedForSigning, width);
            if (signature != _signature)
            {
                _signature = signature;
                _face.Content = new IdCardFace(item, width, signing, withDisclosure, usedForSigning);
            }
            _face.Width = width;
            _face.Height = height;
            _face.CornerRadius = new CornerRadius(radius);
            _face.Translation = isCard ? new Vector3(0, 0, 16) : Vector3.Zero;

            // Collapsed: the component itself is the focusable, adjustable element; the face is just a click target.
            // Expanded: every card is a button "Semnează cu {holder}" with SelectionItem.
            _face.InList = expanded && isCard;
            _face.IsSelectedCard = selected;
            _face.IsTabStop = expanded && isCard;
            AutomationProperties.SetAccessibilityView(_face, expanded && isCard ? AccessibilityView.Content : AccessibilityView.Raw);
            AutomationProperties.SetName(_face, isCard ? Loc.Format("Wallet_SignWith", item.Holder) : "");
            _face.ProtectedCursorShape(expanded && isCard);

            _ring.Visibility = expanded && selected ? Visibility.Visible : Visibility.Collapsed;
            _ring.CornerRadius = new CornerRadius(radius + Pad - 1);
            _ring.BorderBrush = WindowHelpers.ThemeBrush("AccentFillColorDefaultBrush");

            // Disclosure: centre (0.935 W, 0.50 H), diameter 0.085 W, 85 % white + hairline, chevron right → down.
            var diameter = Math.Max(0.085 * width, 22);
            _disclosure.Visibility = withDisclosure ? Visibility.Visible : Visibility.Collapsed;
            _disclosure.Width = _disclosure.Height = diameter;
            _disclosure.CornerRadius = new CornerRadius(diameter / 2);
            _disclosure.HorizontalAlignment = HorizontalAlignment.Left;
            _disclosure.VerticalAlignment = VerticalAlignment.Top;
            _disclosure.Margin = new Thickness(Pad + 0.935 * width - diameter / 2, Pad + 0.5 * height - diameter / 2, 0, 0);
            _disclosure.CardCount = count;
            _disclosure.SetExpandedState(expanded);
            AutomationProperties.SetName(_disclosure, Loc.Format("Wallet_DisclosureName", count));
            ToolTipService.SetToolTip(_disclosure, Loc.Format("Wallet_DisclosureName", count));
            _chevron.Width = _chevron.Height = diameter;
            ((FontIcon)_chevron.Children[0]).FontSize = Math.Max(diameter * 0.42, 9);
            _chevron.CenterPoint = new Vector3((float)(diameter / 2), (float)(diameter / 2), 0);
            if (AnimationsEnabled) _chevron.RotationTransition ??= new ScalarTransition { Duration = TimeSpan.FromMilliseconds(250) };
            else _chevron.RotationTransition = null;
            _chevron.Rotation = expanded ? 90 : 0;
        }
    }

    /// <summary>Borderless button around a card face (fixed card colors: no theme hover fill).</summary>
    private sealed partial class CardButton : Button
    {
        public CardButton()
        {
            Padding = new Thickness(0);
            BorderThickness = new Thickness(0);
            Background = new SolidColorBrush(Color.FromArgb(0, 0, 0, 0));
            HorizontalContentAlignment = HorizontalAlignment.Stretch;
            VerticalContentAlignment = VerticalAlignment.Stretch;
            foreach (var key in new[] { "ButtonBackgroundPointerOver", "ButtonBackgroundPressed", "ButtonBackgroundDisabled",
                                        "ButtonBorderBrushPointerOver", "ButtonBorderBrushPressed", "ButtonBorderBrushDisabled" })
                Resources[key] = new SolidColorBrush(Color.FromArgb(0, 0, 0, 0));
        }

        public bool InList { get; set; }
        public bool IsSelectedCard { get; set; }

        public void ProtectedCursorShape(bool hand) =>
            ProtectedCursor = hand ? InputSystemCursor.Create(InputSystemCursorShape.Hand) : null;

        protected override AutomationPeer OnCreateAutomationPeer() => new CardButtonAutomationPeer(this);
    }

    /// <summary>Expanded list item: a button that reports whether it is the signing card.</summary>
    private sealed partial class CardButtonAutomationPeer(CardButton owner) : ButtonAutomationPeer(owner), ISelectionItemProvider
    {
        protected override object GetPatternCore(PatternInterface patternInterface) =>
            patternInterface == PatternInterface.SelectionItem && owner.InList ? this : base.GetPatternCore(patternInterface);

        public bool IsSelected => owner.IsSelectedCard;

        public IRawElementProviderSimple SelectionContainer => null!;

        public void Select()
        {
            if (!owner.IsSelectedCard) Invoke();
        }

        public void AddToSelection() => Select();

        public void RemoveFromSelection()
        {
        }
    }

    /// <summary>The round disclosure button: "Alege cardul ({n} carduri)", ExpandCollapse pattern.</summary>
    private sealed partial class DisclosureButton : Button
    {
        private bool _expanded;

        public DisclosureButton()
        {
            Padding = new Thickness(0);
            MinWidth = 0;
            MinHeight = 0;
            Background = new SolidColorBrush(Color.FromArgb(0xD9, 0xFF, 0xFF, 0xFF)); // white at 85 %
            BorderBrush = new SolidColorBrush(CardArt.Hairline);
            BorderThickness = new Thickness(1);
            HorizontalContentAlignment = HorizontalAlignment.Center;
            VerticalContentAlignment = VerticalAlignment.Center;
            Resources["ButtonBackgroundPointerOver"] = new SolidColorBrush(Colors.White);
            Resources["ButtonBackgroundPressed"] = new SolidColorBrush(Color.FromArgb(0xB3, 0xFF, 0xFF, 0xFF));
            Resources["ButtonBorderBrushPointerOver"] = new SolidColorBrush(CardArt.Hairline);
            Resources["ButtonBorderBrushPressed"] = new SolidColorBrush(CardArt.Hairline);
        }

        public CardWallet? Owner { get; set; }
        public int CardCount { get; set; }
        public bool IsExpanded => _expanded;

        public void SetExpandedState(bool expanded)
        {
            if (_expanded == expanded) return;
            _expanded = expanded;
            if (FrameworkElementAutomationPeer.FromElement(this) is { } peer)
            {
                peer.RaisePropertyChangedEvent(ExpandCollapsePatternIdentifiers.ExpandCollapseStateProperty,
                    expanded ? ExpandCollapseState.Collapsed : ExpandCollapseState.Expanded,
                    expanded ? ExpandCollapseState.Expanded : ExpandCollapseState.Collapsed);
            }
        }

        protected override AutomationPeer OnCreateAutomationPeer() => new DisclosureAutomationPeer(this);
    }

    private sealed partial class DisclosureAutomationPeer(DisclosureButton owner) : ButtonAutomationPeer(owner), IExpandCollapseProvider
    {
        protected override object GetPatternCore(PatternInterface patternInterface) =>
            patternInterface == PatternInterface.ExpandCollapse ? this : base.GetPatternCore(patternInterface);

        public ExpandCollapseState ExpandCollapseState =>
            owner.IsExpanded ? ExpandCollapseState.Expanded : ExpandCollapseState.Collapsed;

        public void Expand() => owner.Owner?.SetExpanded(true, focusSelf: false);

        public void Collapse() => owner.Owner?.SetExpanded(false, focusSelf: false);
    }

    // MARK: - UI Automation: collapsed component = one adjustable element

    private sealed partial class CardWalletAutomationPeer(CardWallet owner) : FrameworkElementAutomationPeer(owner), IRangeValueProvider
    {
        protected override string GetNameCore() => owner.AutomationName;

        protected override string GetClassNameCore() => nameof(CardWallet);

        protected override AutomationControlType GetAutomationControlTypeCore() =>
            owner.IsExpanded ? AutomationControlType.List : AutomationControlType.Spinner;

        protected override object GetPatternCore(PatternInterface patternInterface) =>
            patternInterface == PatternInterface.RangeValue && !owner.IsExpanded ? this : base.GetPatternCore(patternInterface);

        public double Value => owner.Position;
        public double Minimum => 1;
        public double Maximum => Math.Max(1, owner.Count);
        public double SmallChange => 1;
        public double LargeChange => 1;
        public bool IsReadOnly => owner.Count < 2;

        public void SetValue(double value) => owner.SelectPosition((int)Math.Round(value));
    }
}
