using System.Runtime.InteropServices;
using System.Runtime.Versioning;
using static MoldSign.Core.WinSCardNative;

namespace MoldSign.Core;

/// <summary>Connection options for <see cref="WinSCardTransport"/>.</summary>
public sealed record WinSCardOptions
{
    /// <summary>
    /// Reader to use: an exact name, or a case-insensitive substring (<c>--reader miniLector</c>).
    /// Null = the first reader with a card (spec/cli.md).
    /// </summary>
    public string? ReaderName { get; init; }

    /// <summary>
    /// <c>SCardReconnect(SCARD_RESET_CARD)</c> right after connecting. docs/01 calls it required to kill
    /// stale SM state left by a crashed session, but it still needs on-device verification (MAC-12) before
    /// it becomes the default.
    /// TODO(WIN-02): verify on the miniLector + Microsoft CCID class driver, then default to true.
    /// </summary>
    public bool ResetOnConnect { get; init; }

    /// <summary>Request OS-enforced exclusive reader access for unattended automation.</summary>
    public bool Exclusive { get; init; }
}

/// <summary>A PC/SC reader and whether a card answered a SHARED connect.</summary>
public sealed record SmartCardReaderInfo(string Name, bool CardPresent);

/// <summary>
/// PC/SC transport over winscard.dll (docs/09 §3.1, spec/cli.md CLI-04): share mode SHARED, protocols
/// T0|T1, transmit with <c>g_rgSCardT1Pci</c> (the CosmoX negotiates T=1; T=0 gets <c>g_rgSCardT0Pci</c>).
/// Windows only. macOS and Linux use the native Swift CLI/app, not this transport.
/// </summary>
[SupportedOSPlatform("windows")]
public sealed class WinSCardTransport : ICardTransport
{
    private const int ReceiveBufferSize = 65536 + 2;

    private nint _context;
    private nint _card;
    private uint _activeProtocol;
    private readonly uint _shareMode;

    private WinSCardTransport(nint context, nint card, uint activeProtocol, string readerName, uint shareMode)
    {
        _context = context;
        _card = card;
        _activeProtocol = activeProtocol;
        ReaderName = readerName;
        _shareMode = shareMode;
    }

    public string ReaderName { get; }

    /// <summary>Negotiated protocol (<c>SCARD_PROTOCOL_T0</c> = 1, <c>SCARD_PROTOCOL_T1</c> = 2).</summary>
    public uint ActiveProtocol => _activeProtocol;

    /// <summary>Names of the attached readers (empty when none, or when the Smart Card service is stopped).</summary>
    public static IReadOnlyList<string> ListReaders()
    {
        var ctx = EstablishContext();
        try
        {
            return ListReaders(ctx);
        }
        finally
        {
            _ = SCardReleaseContext(ctx);
        }
    }

    /// <summary>
    /// Readers plus card presence, probed with a SHARED connect + <c>SCARD_LEAVE_CARD</c> disconnect
    /// (no reset, no APDU). Avoids SCardGetStatusChange and its per-OS struct layout.
    /// </summary>
    public static IReadOnlyList<SmartCardReaderInfo> ListReadersWithCardPresence()
    {
        nint ctx;
        try
        {
            ctx = EstablishContext();
        }
        catch (CardException e) when (e.Kind == CardErrorKind.NoReader)
        {
            return [];
        }

        try
        {
            var result = new List<SmartCardReaderInfo>();
            foreach (var reader in ListReaders(ctx))
            {
                var rv = SCardConnect(ctx, reader, SCARD_SHARE_SHARED, SCARD_PROTOCOL_T0 | SCARD_PROTOCOL_T1,
                                      out var card, out _);
                if (rv == SCARD_S_SUCCESS) _ = SCardDisconnect(card, SCARD_LEAVE_CARD);
                // A sharing violation means another process holds the card: it is present.
                var present = rv == SCARD_S_SUCCESS || unchecked((uint)rv) == SCARD_E_SHARING_VIOLATION;
                result.Add(new SmartCardReaderInfo(reader, present));
            }
            return result;
        }
        finally
        {
            _ = SCardReleaseContext(ctx);
        }
    }

    /// <summary>
    /// Every reader with card presence, the mute flag and the card event counter (upper 16 bits of
    /// <c>dwEventState</c>), from <c>SCardGetStatusChange</c> with a zero timeout on a fresh context. It never
    /// connects, so it is safe next to a running signing session (docs/09 §3.1b; feed it to
    /// <see cref="ReaderGenerationTracker"/>). Empty when there is no reader or the Smart Card service is stopped
    /// (Windows stops it when the last reader goes away).
    /// </summary>
    public static unsafe IReadOnlyList<ReaderStatus> GetReaderStates()
    {
        nint ctx;
        try
        {
            ctx = EstablishContext();
        }
        catch (CardException e) when (e.Kind == CardErrorKind.NoReader)
        {
            return [];
        }

        var names = new List<nint>();
        try
        {
            var readers = ListReaders(ctx);
            if (readers.Count == 0) return [];

            var states = new ScardReaderState[readers.Count];
            for (var i = 0; i < readers.Count; i++)
            {
                var name = Marshal.StringToHGlobalUni(readers[i]);
                names.Add(name);
                states[i].szReader = name;
                states[i].dwCurrentState = SCARD_STATE_UNAWARE;
            }

            int rv;
            fixed (ScardReaderState* first = states)
            {
                rv = SCardGetStatusChange(ctx, 0, first, (uint)states.Length);
            }
            var code = unchecked((uint)rv);
            if (rv != SCARD_S_SUCCESS && code != SCARD_E_TIMEOUT)
            {
                var error = Map(code, "SCardGetStatusChange");
                if (error.Kind == CardErrorKind.NoReader) return []; // unplugged between the two calls
                throw error;
            }

            var result = new List<ReaderStatus>(readers.Count);
            for (var i = 0; i < readers.Count; i++)
            {
                var events = states[i].dwEventState;
                var present = (events & SCARD_STATE_PRESENT) != 0;
                result.Add(new ReaderStatus(readers[i], present, present && (events & SCARD_STATE_MUTE) != 0,
                                            (int)(events >> 16)));
            }
            return result;
        }
        finally
        {
            foreach (var name in names) Marshal.FreeHGlobal(name);
            _ = SCardReleaseContext(ctx);
        }
    }

    /// <summary>Establishes a context, picks a reader, connects SHARED with T0|T1 (and optionally resets the card).</summary>
    public static WinSCardTransport Connect(WinSCardOptions? options = null)
    {
        options ??= new WinSCardOptions();
        var ctx = EstablishContext();
        try
        {
            var readers = ListReaders(ctx);
            if (readers.Count == 0)
                throw new CardException(CardErrorKind.NoReader, "No smart-card reader found");

            var candidates = readers;
            if (options.ReaderName is { } wanted)
            {
                var match = readers.FirstOrDefault(r => string.Equals(r, wanted, StringComparison.Ordinal))
                            ?? readers.FirstOrDefault(r => r.Contains(wanted, StringComparison.OrdinalIgnoreCase))
                            ?? throw new CardException(CardErrorKind.NoReader,
                                   $"Reader '{wanted}' not found (available: {string.Join(", ", readers)})");
                candidates = [match];
            }

            // First reader that accepts a connect, i.e. the first one with a card.
            var lastError = SCARD_E_NO_SMARTCARD;
            foreach (var reader in candidates)
            {
                var rv = SCardConnect(ctx, reader, options.Exclusive ? 1u : SCARD_SHARE_SHARED, SCARD_PROTOCOL_T0 | SCARD_PROTOCOL_T1,
                                      out var card, out var protocol);
                if (rv != SCARD_S_SUCCESS)
                {
                    lastError = unchecked((uint)rv);
                    continue;
                }

                var transport = new WinSCardTransport(ctx, card, protocol, reader, options.Exclusive ? 1u : SCARD_SHARE_SHARED);
                if (options.ResetOnConnect)
                {
                    try
                    {
                        transport.Reset();
                    }
                    catch
                    {
                        _ = SCardDisconnect(card, SCARD_LEAVE_CARD);
                        throw; // the outer catch releases the context
                    }
                }
                return transport;
            }

            throw Map(lastError, candidates.Count == 1 ? $"SCardConnect({candidates[0]})" : "SCardConnect", noCardByDefault: true);
        }
        catch
        {
            _ = SCardReleaseContext(ctx);
            throw;
        }
    }

    /// <summary><c>SCardReconnect(current share mode, T0|T1, SCARD_RESET_CARD)</c>: resets the card and drops any SM state.</summary>
    public void Reset()
    {
        ThrowIfDisposed();
        var rv = SCardReconnect(_card, _shareMode, SCARD_PROTOCOL_T0 | SCARD_PROTOCOL_T1,
                                SCARD_RESET_CARD, out var protocol);
        if (rv != SCARD_S_SUCCESS) throw Map(unchecked((uint)rv), "SCardReconnect");
        _activeProtocol = protocol;
    }

    public byte[] Transmit(byte[] apdu)
    {
        ArgumentNullException.ThrowIfNull(apdu);
        ThrowIfDisposed();

        var receive = new byte[ReceiveBufferSize];
        var receiveLength = (uint)receive.Length;
        var rv = SCardTransmit(_card, PciFor(_activeProtocol), apdu, (uint)apdu.Length, 0, receive, ref receiveLength);
        if (rv != SCARD_S_SUCCESS) throw Map(unchecked((uint)rv), "SCardTransmit");
        if (receiveLength < 2)
            throw new CardException(CardErrorKind.CardNotResponding, "Card returned no status word");
        return receive.AsSpan(0, (int)receiveLength).ToArray();
    }

    public void Dispose()
    {
        if (_card != 0)
        {
            _ = SCardDisconnect(_card, SCARD_LEAVE_CARD);
            _card = 0;
        }
        if (_context != 0)
        {
            _ = SCardReleaseContext(_context);
            _context = 0;
        }
    }

    private void ThrowIfDisposed() => ObjectDisposedException.ThrowIf(_card == 0, this);

    private static nint EstablishContext()
    {
        int rv;
        nint ctx;
        try
        {
            rv = SCardEstablishContext(SCARD_SCOPE_USER, 0, 0, out ctx);
        }
        catch (DllNotFoundException e)
        {
            throw new CardException(CardErrorKind.NoReader, "winscard.dll is not available", innerException: e);
        }
        if (rv != SCARD_S_SUCCESS) throw Map(unchecked((uint)rv), "SCardEstablishContext");
        return ctx;
    }

    private static List<string> ListReaders(nint ctx)
    {
        uint length = 0;
        var rv = unchecked((uint)SCardListReaders(ctx, null, null, ref length));
        if (rv is SCARD_E_NO_READERS_AVAILABLE or SCARD_E_NO_SERVICE or SCARD_E_SERVICE_STOPPED || (rv == 0 && length <= 1))
            return [];
        if (rv != 0) throw Map(rv, "SCardListReaders");

        var buffer = new char[length];
        rv = unchecked((uint)SCardListReaders(ctx, null, buffer, ref length));
        if (rv == SCARD_E_NO_READERS_AVAILABLE) return [];
        if (rv != 0) throw Map(rv, "SCardListReaders");

        // Multi-string: "name1\0name2\0\0"
        return new string(buffer, 0, (int)Math.Min(length, (uint)buffer.Length))
            .Split('\0', StringSplitOptions.RemoveEmptyEntries)
            .ToList();
    }

    internal static CardException Map(uint code, string call, bool noCardByDefault = false)
    {
        var kind = code switch
        {
            // The Smart Card service stops when the last reader is unplugged.
            SCARD_E_NO_READERS_AVAILABLE or SCARD_E_NO_SERVICE or SCARD_E_SERVICE_STOPPED
                or SCARD_E_READER_UNAVAILABLE => CardErrorKind.NoReader,
            SCARD_E_NO_SMARTCARD or SCARD_W_REMOVED_CARD or SCARD_W_UNPOWERED_CARD
                or SCARD_W_UNRESPONSIVE_CARD => CardErrorKind.NoCard,
            // Someone else reset the card: any SM session is gone.
            SCARD_W_RESET_CARD => CardErrorKind.SmOutOfSync,
            _ => noCardByDefault ? CardErrorKind.NoCard : CardErrorKind.CardNotResponding,
        };
        var text = kind switch
        {
            CardErrorKind.NoReader => "no smart-card reader",
            CardErrorKind.NoCard => "no card in the reader",
            _ => "PC/SC error",
        };
        return new CardException(kind, $"{call} failed: {text} (0x{code:X8})");
    }
}
