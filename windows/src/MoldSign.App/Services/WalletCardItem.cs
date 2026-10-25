using System.Globalization;
using MoldSign.Core;

namespace MoldSign.App.Services;

/// <summary>What a wallet slot shows (docs/10 §0.2/§0.2b: empty and error states are cards too).</summary>
public enum WalletItemKind
{
    /// <summary>An inserted card (reading, ready or failed): drawn as the ID-card illustration.</summary>
    Card,
    /// <summary>Dashed outline "Introdu cardul": a reader is connected, no card.</summary>
    InsertCard,
    /// <summary>Dashed outline "Conectează cititorul": no reader.</summary>
    ConnectReader,
    /// <summary>Red-tinted outline: a card sits in a reader but does not answer.</summary>
    MuteCard,
}

/// <summary>One wallet slot, mirrored from <see cref="CardWallet"/> (Core) by <see cref="AppState"/> on the UI thread.</summary>
public sealed class WalletCardItem(WalletItemKind kind, string? reader)
{
    public WalletItemKind Kind { get; } = kind;

    /// <summary>PC/SC reader name (cards and "insert card"); null for "connect the reader" / mute.</summary>
    public string? Reader { get; } = reader;

    /// <summary>Latest model snapshot for a card slot.</summary>
    public WalletCard? Card { get; private set; }

    public bool IsSelected { get; private set; }

    public CertificateSummary? Certificate => Card?.Certificate;

    public CardErrorKind? Problem => Card?.Problem;

    public bool IsReading => Kind == WalletItemKind.Card && Card is { IsReading: true };

    /// <summary>Holder name for menus ("ION POPESCU"), or "Card în {reader}" before the certificate is read.</summary>
    public string Holder => Certificate?.CommonName ?? Loc.Format("Wallet_CardInReader", Reader ?? "");

    public string PlaceholderGlyph => Kind switch
    {
        WalletItemKind.ConnectReader => "", // USB
        WalletItemKind.MuteCard => "",      // Warning
        _ => "",                            // PaymentCard
    };

    public string PlaceholderTitle => Kind switch
    {
        WalletItemKind.ConnectReader => Loc.Get("Wallet_ConnectTitle"),
        WalletItemKind.MuteCard => Loc.Get("Wallet_MuteTitle"),
        _ => Loc.Get("Wallet_InsertTitle"),
    };

    public string PlaceholderMessage => Kind switch
    {
        WalletItemKind.ConnectReader => Loc.Get("Wallet_ConnectMessage"),
        WalletItemKind.MuteCard => Loc.Get("Error_CardStuck"),
        _ => Reader ?? "",
    };

    /// <summary>"{holder}, card de identitate, valabil până la …, {i} din {n}" (docs/10 §0.2b accessibility).</summary>
    public string AccessibleName(int index, int count)
    {
        if (Kind != WalletItemKind.Card) return $"{PlaceholderTitle}. {PlaceholderMessage}";
        if (Problem is { } problem)
            return Loc.Format("Wallet_CardErrorName", Reader ?? "", AppState.ErrorText(problem), index, count);
        if (Certificate is not { } cert) return Loc.Format("Wallet_CardReadingName", Reader ?? "", index, count);
        return Loc.Format("Wallet_CardName", cert.CommonName,
                          cert.NotAfter.ToLocalTime().ToString("dd MM yyyy", CultureInfo.InvariantCulture), index, count);
    }

    internal void Update(WalletCard? card, bool selected)
    {
        Card = card;
        IsSelected = selected;
    }
}
