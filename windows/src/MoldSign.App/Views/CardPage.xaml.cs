using System.Globalization;
using Microsoft.UI.Xaml;
using Microsoft.UI.Xaml.Controls;
using Microsoft.UI.Xaml.Input;
using Windows.System;
using MoldSign.App.Services;
using MoldSign.Core;
using MoldSign.Desktop;

namespace MoldSign.App.Views;

/// <summary>Card page: the selected wallet card's details follow the wallet selection.</summary>
public sealed partial class CardPage : Page
{
    public CardPage()
    {
        InitializeComponent();
        ForgetPinLabel.Text = Loc.Get("CardForgetPin/Content");
        ForgetPinButton.IsEnabled = !App.Current.Services.IsDemo;
        CardScroll.AddHandler(KeyDownEvent, new KeyEventHandler(OnScrollKeyDown), handledEventsToo: true);
        Loaded += (_, _) =>
        {
            State.WalletChanged += OnWalletChanged;
            ShowSelectedCard();
        };
        Unloaded += (_, _) => State.WalletChanged -= OnWalletChanged;
    }

    private void OnCardSelected(object? sender, string reader) => App.Current.Services.SelectCard(reader);

    public AppState State => AppState.Current;

    private void OnWalletChanged(object? sender, EventArgs e) => ShowSelectedCard();

    private void ShowSelectedCard()
    {
        CertificateSummary? certificate = State.Certificate;
        CertificateProperties.Visibility = certificate is null ? Visibility.Collapsed : Visibility.Visible;
        HolderText.Text = certificate?.CommonName ?? "—";
        IssuerText.Text = certificate?.Issuer ?? "—";
        ValidityText.Text = certificate is null
            ? "—"
            : string.Create(CultureInfo.CurrentCulture,
                $"{certificate.NotBefore.ToLocalTime():dd.MM.yyyy} – {certificate.NotAfter.ToLocalTime():dd.MM.yyyy}");
        SerialText.Text = certificate?.SerialNumber ?? "—";
        Sha1Text.Text = certificate?.Sha1 ?? "—";
        ReaderText.Text = State.SelectedReader ?? "—";
        ForgetPinButton.IsEnabled = !App.Current.Services.IsDemo && certificate is not null && App.Current.Services.Pins.Contains(certificate.Sha1);
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

    private void OnForgetClick(object sender, RoutedEventArgs e)
    {
        if (!SavedPinActions.ForgetSelected(App.Current.Services.Pins, State.Certificate?.Sha1, App.Current.Services.IsDemo)) return;
        ShowSelectedCard();
        Result.Severity = InfoBarSeverity.Success;
        Result.Message = Loc.Get("Card_PinForgotten");
        Result.IsOpen = true;
    }
}
