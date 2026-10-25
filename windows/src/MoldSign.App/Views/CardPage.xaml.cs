using System.Globalization;
using Microsoft.UI.Xaml;
using Microsoft.UI.Xaml.Controls;
using MoldSign.App.Services;
using MoldSign.Core;

namespace MoldSign.App.Views;

/// <summary>Card page: the selected wallet card's details follow the wallet selection.</summary>
public sealed partial class CardPage : Page
{
    public CardPage()
    {
        InitializeComponent();
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

    private void OnRereadClick(object sender, RoutedEventArgs e) => App.Current.Services.RereadCards();

    private void OnRememberToggled(object sender, RoutedEventArgs e)
    {
        var settings = App.Current.Services.Settings;
        if (settings.RememberPin == RememberToggle.IsOn) return;
        settings.RememberPin = RememberToggle.IsOn;
        if (!RememberToggle.IsOn) App.Current.Services.Pins.DeleteAll();
        settings.Save();
    }

    private void OnForgetClick(object sender, RoutedEventArgs e)
    {
        App.Current.Services.Pins.DeleteAll();
        Result.Severity = InfoBarSeverity.Success;
        Result.Message = Loc.Get("Card_PinForgotten");
        Result.IsOpen = true;
    }
}
