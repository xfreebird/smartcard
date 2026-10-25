using MoldSign.Core;

namespace MoldSign.Cli;

/// <summary>Reader access seam (fakes in tests, WinSCard in the product).</summary>
internal interface ICardAccess
{
    IReadOnlyList<SmartCardReaderInfo> ListReaders();

    ICardTransport Connect(string? readerName);
}

/// <summary>WinSCard on Windows; everywhere else card commands fail with exit code 5.</summary>
internal sealed class WinSCardAccess : ICardAccess
{
    public const string NotWindowsMessage = "PC/SC transport is only available on Windows";

    public IReadOnlyList<SmartCardReaderInfo> ListReaders()
    {
        if (!OperatingSystem.IsWindows()) throw new CardException(CardErrorKind.NoReader, NotWindowsMessage);
        return WinSCardTransport.ListReadersWithCardPresence();
    }

    public ICardTransport Connect(string? readerName)
    {
        if (!OperatingSystem.IsWindows()) throw new CardException(CardErrorKind.NoReader, NotWindowsMessage);
        // TODO(WIN-02): flip ResetOnConnect on once SCardReconnect(SCARD_RESET_CARD) is verified on device.
        return WinSCardTransport.Connect(new WinSCardOptions { ReaderName = readerName });
    }
}
