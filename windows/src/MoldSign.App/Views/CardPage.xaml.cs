using System.Globalization;
using Microsoft.UI.Xaml;
using Microsoft.UI.Xaml.Controls;
using Microsoft.UI.Xaml.Input;
using Windows.System;
using MoldSign.App.Services;
using MoldSign.Core;

namespace MoldSign.App.Views;

/// <summary>Card page: the selected wallet card's details follow the wallet selection.</summary>
public sealed partial class CardPage : Page
{
    public CardPage()
    {
        InitializeComponent();
        RememberToggle.IsEnabled = !App.Current.Services.IsDemo;
        ForgetPinButton.IsEnabled = !App.Current.Services.IsDemo;
        CardScroll.AddHandler(KeyDownEvent, new KeyEventHandler(OnScrollKeyDown), handledEventsToo: true);
        Loaded += (_, _) =>
        {
            RememberToggle.IsOn = App.Current.Services.Settings.RememberPin;
            State.WalletChanged += OnWalletChanged;
            ShowSelectedCard();
        };
        Unloaded += (_, _) => State.WalletChanged -= OnWalletChanged;
    }

    public AppState State => AppState.Current;

    private void OnWalletChanged(object? sender, EventArgs e) => ShowSelectedCard();

    private void ShowSelectedCard()
    {
        CertificateSummary? certificate = State.Certificate;
        HolderText.Text = certificate?.CommonName ?? "—";
        IssuerText.Text = certificate?.Issuer ?? "—";
        ValidityText.Text = certificate is null
            ? "—"
            : string.Create(CultureInfo.CurrentCulture,
                $"{certificate.NotBefore.ToLocalTime():dd.MM.yyyy} – {certificate.NotAfter.ToLocalTime():dd.MM.yyyy}");
        SerialText.Text = certificate?.SerialNumber ?? "—";
        Sha1Text.Text = certificate?.Sha1 ?? "—";
        ReaderText.Text = State.SelectedReader ?? "—";
    }

    private void OnScrollKeyDown(object sender, KeyRoutedEventArgs e)
    {
        double? offset = e.Key switch
        {
            VirtualKey.End => CardScroll.ScrollableHeight,
            VirtualKey.Home => 0,
            VirtualKey.PageDown => Math.Min(CardScroll.ScrollableHeight, CardScroll.VerticalOffset + CardScroll.ViewportHeight * 0.85),
            VirtualKey.PageUp => Math.Max(0, CardScroll.VerticalOffset - CardScroll.ViewportHeight * 0.85),
            _ => null,
        };
        if (offset is null) return;
        CardScroll.ChangeView(null, offset.Value, null, disableAnimation: true);
        e.Handled = true;
    }

    private void OnRereadClick(object sender, RoutedEventArgs e) => App.Current.Services.RereadCards();

    private void OnRememberToggled(object sender, RoutedEventArgs e)
    {
        if (App.Current.Services.IsDemo) return;
        var settings = App.Current.Services.Settings;
        if (settings.RememberPin == RememberToggle.IsOn) return;
        settings.RememberPin = RememberToggle.IsOn;
        if (!RememberToggle.IsOn) App.Current.Services.Pins.DeleteAll();
        settings.Save();
    }

    private void OnForgetClick(object sender, RoutedEventArgs e)
    {
        if (App.Current.Services.IsDemo) return;
        App.Current.Services.Pins.DeleteAll();
        Result.Severity = InfoBarSeverity.Success;
        Result.Message = Loc.Get("Card_PinForgotten");
        Result.IsOpen = true;
    }
}
