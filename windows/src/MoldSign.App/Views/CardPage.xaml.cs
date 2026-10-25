using System.ComponentModel;
using System.Globalization;
using Microsoft.UI.Xaml;
using Microsoft.UI.Xaml.Controls;
using MoldSign.App.Services;
using MoldSign.Core;

namespace MoldSign.App.Views;

public sealed partial class CardPage : Page
{
    public CardPage()
    {
        InitializeComponent();
        Loaded += (_, _) =>
        {
            RememberToggle.IsOn = App.Current.Services.Settings.RememberPin;
            State.PropertyChanged += OnStateChanged;
            ShowCertificate(State.Certificate);
        };
        Unloaded += (_, _) => State.PropertyChanged -= OnStateChanged;
    }

    public AppState State => AppState.Current;

    private void OnStateChanged(object? sender, PropertyChangedEventArgs e)
    {
        if (e.PropertyName == nameof(AppState.Certificate)) ShowCertificate(State.Certificate);
    }

    private void ShowCertificate(CertificateSummary? certificate)
    {
        IssuerText.Text = certificate?.Issuer ?? "—";
        ValidityText.Text = certificate is null
            ? "—"
            : string.Create(CultureInfo.CurrentCulture,
                $"{certificate.NotBefore.ToLocalTime():dd.MM.yyyy} – {certificate.NotAfter.ToLocalTime():dd.MM.yyyy}");
        SerialText.Text = certificate?.SerialNumber ?? "—";
        Sha1Text.Text = certificate?.Sha1 ?? "—";
    }

    private async void OnReadClick(object sender, RoutedEventArgs e)
    {
        var services = App.Current.Services;
        try
        {
            var certificate = await Task.Run(() => services.Signing.Certificate());
            services.Signing.PublishReaderState(new ReaderState.CardPresent(State.ReaderName ?? "", certificate.CommonName, certificate));
            Result.IsOpen = false;
        }
        catch (CardException ex)
        {
            Result.Severity = InfoBarSeverity.Warning;
            Result.Message = AppState.ErrorText(ex.Kind);
            Result.IsOpen = true;
        }
    }

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
