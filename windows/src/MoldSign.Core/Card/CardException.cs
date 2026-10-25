namespace MoldSign.Core;

/// <summary>
/// Error taxonomy from docs/09-architecture.md §3.3. The UI maps each kind to one recovery action;
/// the raw status word stays in <see cref="CardException.StatusWord"/> for "technical details".
/// </summary>
public enum CardErrorKind
{
    /// <summary>No PC/SC reader (or the Smart Card service is not running). UI: <c>error.noReader</c>.</summary>
    NoReader,
    /// <summary>Reader empty or connect failed. UI: <c>error.noCard</c>.</summary>
    NoCard,
    /// <summary>Transport failure or a response shorter than SW1 SW2.</summary>
    CardNotResponding,
    /// <summary><c>63Cx</c> on VERIFY: delete the stored PIN, show the remaining attempts, never auto-retry.</summary>
    WrongPin,
    /// <summary><c>6983</c>: stop, explain PUK/unblock at CEV. UI: <c>error.pinBlocked</c>.</summary>
    PinBlocked,
    /// <summary><c>6985</c>: physically re-insert the card. Do NOT retry auth. UI: <c>error.cardStuck</c>.</summary>
    CardStateStuck,
    /// <summary><c>6988</c> or an SM/authentication MAC mismatch: drop the session, reconnect once.</summary>
    SmOutOfSync,
    /// <summary>Any other non-9000 status word.</summary>
    UnexpectedStatus,
    /// <summary>A well-formed exchange with unusable content (bad lengths, no certificate in EF 0001…).</summary>
    UnexpectedResponse,
    /// <summary>PIN not 4–8 ASCII characters (rejected before anything is sent to the card).</summary>
    InvalidPinFormat,
    /// <summary>TSA/OCSP/CRL failure (TrustServices).</summary>
    Network,
    /// <summary>PDF/XML parse errors.</summary>
    Format,
    /// <summary>User dismissed PIN/consent. Silent in the UI.</summary>
    Cancelled,
}

/// <summary>Every failure surfaced by the card stack and the signing facade.</summary>
public sealed class CardException : Exception
{
    public CardException(CardErrorKind kind, string message, ushort? statusWord = null,
                         int? remainingAttempts = null, Exception? innerException = null)
        : base(message, innerException)
    {
        Kind = kind;
        StatusWord = statusWord;
        RemainingAttempts = remainingAttempts;
    }

    public CardErrorKind Kind { get; }

    /// <summary>SW1SW2 when the error came from the card.</summary>
    public ushort? StatusWord { get; }

    /// <summary>PIN tries left for <see cref="CardErrorKind.WrongPin"/> (the x of <c>63Cx</c>).</summary>
    public int? RemainingAttempts { get; }

    /// <summary>Maps a non-9000 status word to the taxonomy.</summary>
    public static CardException FromStatusWord(ushort sw, string? context = null)
    {
        var where = string.IsNullOrEmpty(context) ? "" : $"{context}: ";
        var sw1 = (byte)(sw >> 8);
        var sw2 = (byte)sw;

        // 63Cx = verification failed, x tries left. The Swift reference treats any 63xx on VERIFY
        // as a wrong PIN with (SW2 & 0x0F) remaining; keep that, but only trust the count for 63Cx.
        if (sw1 == 0x63)
        {
            int? remaining = (sw2 & 0xF0) == 0xC0 ? sw2 & 0x0F : null;
            return new CardException(CardErrorKind.WrongPin,
                $"{where}wrong PIN" + (remaining is { } r ? $", {r} attempt(s) remaining" : ""),
                sw, remaining);
        }

        return sw switch
        {
            0x6983 => new CardException(CardErrorKind.PinBlocked, $"{where}PIN blocked (6983)", sw, 0),
            0x6985 => new CardException(CardErrorKind.CardStateStuck,
                $"{where}conditions of use not satisfied (6985): remove and re-insert the card", sw),
            0x6988 => new CardException(CardErrorKind.SmOutOfSync,
                $"{where}secure messaging data objects incorrect (6988)", sw),
            _ => new CardException(CardErrorKind.UnexpectedStatus, $"{where}APDU error {sw:X4}", sw),
        };
    }
}
