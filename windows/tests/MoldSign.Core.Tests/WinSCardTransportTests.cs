namespace MoldSign.Core.Tests;

/// <summary>
/// WinSCard error mapping, and the no-reader behaviour of the real PC/SC stack. The hardware checks run only on
/// Windows without an attached reader (CI, test VMs): they never connect to a card or send an APDU.
/// </summary>
public sealed class WinSCardTransportTests
{
    [Theory]
    [InlineData(0x8010002Eu, CardErrorKind.NoReader, "no smart-card reader")]   // SCARD_E_NO_READERS_AVAILABLE
    [InlineData(0x8010001Du, CardErrorKind.NoReader, "no smart-card reader")]   // SCARD_E_NO_SERVICE
    [InlineData(0x8010001Eu, CardErrorKind.NoReader, "no smart-card reader")]   // SCARD_E_SERVICE_STOPPED
    [InlineData(0x80100017u, CardErrorKind.NoReader, "no smart-card reader")]   // SCARD_E_READER_UNAVAILABLE
    [InlineData(0x8010000Cu, CardErrorKind.NoCard, "no card in the reader")]    // SCARD_E_NO_SMARTCARD
    [InlineData(0x80100069u, CardErrorKind.NoCard, "no card in the reader")]    // SCARD_W_REMOVED_CARD
    [InlineData(0x80100067u, CardErrorKind.NoCard, "no card in the reader")]    // SCARD_W_UNPOWERED_CARD
    [InlineData(0x80100066u, CardErrorKind.NoCard, "no card in the reader")]    // SCARD_W_UNRESPONSIVE_CARD
    [InlineData(0x80100068u, CardErrorKind.SmOutOfSync, "PC/SC error")]         // SCARD_W_RESET_CARD
    [InlineData(0x8010000Bu, CardErrorKind.CardNotResponding, "PC/SC error")]   // SCARD_E_SHARING_VIOLATION
    public void Pcsc_codes_map_to_card_error_kinds(uint code, CardErrorKind kind, string text)
    {
        if (!OperatingSystem.IsWindows()) return; // WinSCard is the Windows transport
        var error = WinSCardTransport.Map(code, "SCardConnect");
        Assert.Equal(kind, error.Kind);
        Assert.Equal($"SCardConnect failed: {text} (0x{code:X8})", error.Message);
    }

    [Fact]
    public void Unknown_connect_failures_can_default_to_no_card()
    {
        if (!OperatingSystem.IsWindows()) return;
        Assert.Equal(CardErrorKind.NoCard, WinSCardTransport.Map(0x80100008, "SCardConnect", noCardByDefault: true).Kind);
        Assert.Equal(CardErrorKind.CardNotResponding, WinSCardTransport.Map(0x80100008, "SCardTransmit").Kind);
    }

    /// <summary>Null when PC/SC answers; the refusal when the Smart Card service denies this session (e.g. over SSH).</summary>
    [System.Runtime.Versioning.SupportedOSPlatform("windows")]
    internal static CardException? PcscRefusal(out int readers)
    {
        readers = 0;
        try { readers = WinSCardTransport.GetReaderStates().Count; return null; }
        catch (CardException refused) { return refused; }
    }

    [Fact]
    public void Without_pcsc_access_every_entry_point_fails_with_the_same_card_error()
    {
        if (!OperatingSystem.IsWindows() || PcscRefusal(out _) is not { } refused) return; // PC/SC answers here
        foreach (var entryPoint in EntryPoints()) Assert.Equal(refused.Message, Assert.Throws<CardException>(entryPoint).Message);
    }

    [System.Runtime.Versioning.SupportedOSPlatform("windows")]
    private static Action[] EntryPoints() =>
    [
        () => WinSCardTransport.ListReadersWithCardPresence(),
        () => WinSCardTransport.ListReaders(),
        () => WinSCardTransport.Connect(),
    ];

    [Fact]
    public void Without_a_reader_every_entry_point_reports_no_reader()
    {
        if (!OperatingSystem.IsWindows() || PcscRefusal(out var readers) is not null || readers > 0) return; // refused or a reader is attached

        Assert.Empty(WinSCardTransport.ListReadersWithCardPresence());
        try { Assert.Empty(WinSCardTransport.ListReaders()); }
        catch (CardException stopped) { Assert.Equal(CardErrorKind.NoReader, stopped.Kind); } // Smart Card service stopped
        foreach (var options in new WinSCardOptions?[] { null, new() { ReaderName = "miniLector" }, new() { Exclusive = true, ResetOnConnect = true } })
            Assert.Equal(CardErrorKind.NoReader, ConnectError(options).Kind);
    }

    [System.Runtime.Versioning.SupportedOSPlatform("windows")]
    private static CardException ConnectError(WinSCardOptions? options) =>
        Assert.Throws<CardException>(() => WinSCardTransport.Connect(options));
}
