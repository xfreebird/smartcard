using System.Globalization;
using MoldSign.App.Controls;
using MoldSign.App.Services;

namespace MoldSign.App.Presentation;

internal static class CardWalletContentMapper
{
    internal static CardWalletContent From(AppState state) => new(
        state.WalletItems.Select((item, index) => From(item, index + 1, state.CardCount, state.IsBusy)).ToArray(),
        state.SelectedIndex, state.IsBusy, Loc.Get("Wallet_Previous"), Loc.Get("Wallet_Next"), Loc.Get("Wallet_UsedForSigning"));

    internal static IdentityCardContent From(WalletCardItem item, int index, int count, bool busy)
    {
        var certificate = item.Certificate;
        var (surname, given) = certificate?.NameParts() ?? ("", "");
        var tone = item.Problem is not null ? CardStatusTone.Error
            : busy && item.IsSelected ? CardStatusTone.Busy
            : certificate is null ? CardStatusTone.Reading : CardStatusTone.Ready;
        var used = item.IsSelected && count > 1;
        return new IdentityCardContent
        {
            IsCard = item.Kind == WalletItemKind.Card,
            IsErrorPlaceholder = item.Kind == WalletItemKind.MuteCard,
            Reader = item.Reader, Surname = certificate is null ? null : surname,
            GivenNames = certificate is null ? null : given,
            ValidUntil = certificate?.NotAfter.ToLocalTime().ToString("dd MM yyyy", CultureInfo.InvariantCulture),
            Issuer = certificate?.IssuerName, HueOffset = CardArt.HueOffset(certificate?.Sha1),
            Tone = tone, IsSelected = item.IsSelected, UsedForSigning = used,
            StatusText = item.Problem is { } problem ? AppState.ErrorText(problem)
                : Loc.Get(tone == CardStatusTone.Busy ? "Light_Busy" : tone == CardStatusTone.Reading ? "Light_Reading"
                    : used ? "Wallet_UsedForSigning" : "Wallet_StatusReady"),
            AccessibilityLabel = item.AccessibleName(index, Math.Max(1, count)),
            PlaceholderGlyph = item.PlaceholderGlyph, PlaceholderTitle = item.PlaceholderTitle,
            PlaceholderMessage = item.PlaceholderMessage,
            Labels = new(Loc.Get("Card_CountryPrimary"), Loc.Get("Card_CountrySecondary"),
                Loc.Get("Card_TypePrimary"), Loc.Get("Card_TypeSecondary"), Loc.Get("Card_LabelSurname"),
                Loc.Get("Card_LabelGivenNames"), Loc.Get("Card_LabelValidUntil"), Loc.Get("Card_LabelIssuer")),
        };
    }
}
