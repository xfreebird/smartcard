using System.Runtime.InteropServices;
using System.Runtime.Versioning;

namespace MoldSign.Core;

/// <summary>
/// Minimal winscard.dll surface (Unicode entry points). DWORD is 32-bit; SCARDCONTEXT/SCARDHANDLE are
/// ULONG_PTR (pointer-sized). Source-generated (LibraryImport) so the CLI can be published with NativeAOT.
/// </summary>
[SupportedOSPlatform("windows")]
internal static partial class WinSCardNative
{
    private const string Lib = "winscard.dll";

    // dwScope
    public const uint SCARD_SCOPE_USER = 0;

    // dwShareMode
    public const uint SCARD_SHARE_SHARED = 2;

    // dwPreferredProtocols / active protocol
    public const uint SCARD_PROTOCOL_T0 = 0x0001;
    public const uint SCARD_PROTOCOL_T1 = 0x0002;

    // dwDisposition / dwInitialization
    public const uint SCARD_LEAVE_CARD = 0;
    /// <summary>SCardGetAttrib: the card's answer-to-reset.</summary>
    public const uint SCARD_ATTR_ATR_STRING = 0x00090303;
    public const uint SCARD_RESET_CARD = 1;

    // SCARD_READERSTATE dwCurrentState / dwEventState bits; the upper 16 bits of dwEventState count card events.
    public const uint SCARD_STATE_UNAWARE = 0x0000;
    public const uint SCARD_STATE_PRESENT = 0x0020;
    public const uint SCARD_STATE_MUTE = 0x0200;

    // Return codes (LONG; compared as unchecked uint)
    public const int SCARD_S_SUCCESS = 0;
    public const uint SCARD_E_TIMEOUT = 0x8010000A;
    public const uint SCARD_E_SHARING_VIOLATION = 0x8010000B;
    public const uint SCARD_E_NO_SMARTCARD = 0x8010000C;
    public const uint SCARD_E_READER_UNAVAILABLE = 0x80100017;
    public const uint SCARD_E_NO_SERVICE = 0x8010001D;
    public const uint SCARD_E_SERVICE_STOPPED = 0x8010001E;
    public const uint SCARD_E_NO_READERS_AVAILABLE = 0x8010002E;
    public const uint SCARD_W_UNRESPONSIVE_CARD = 0x80100066;
    public const uint SCARD_W_UNPOWERED_CARD = 0x80100067;
    public const uint SCARD_W_RESET_CARD = 0x80100068;
    public const uint SCARD_W_REMOVED_CARD = 0x80100069;

    /// <summary>SCARD_IO_REQUEST: { DWORD dwProtocol; DWORD cbPciLength; } (8 bytes on Windows).</summary>
    [StructLayout(LayoutKind.Sequential)]
    public struct ScardIoRequest
    {
        public uint dwProtocol;
        public uint cbPciLength;
    }

    /// <summary>
    /// SCARD_READERSTATEW: { LPCWSTR szReader; LPVOID pvUserData; DWORD dwCurrentState; DWORD dwEventState;
    /// DWORD cbAtr; BYTE rgbAtr[36]; } = 64 bytes on x64/ARM64. Blittable: the reader name is a caller-owned
    /// UTF-16 pointer.
    /// </summary>
    [StructLayout(LayoutKind.Sequential)]
    public unsafe struct ScardReaderState
    {
        public nint szReader;
        public nint pvUserData;
        public uint dwCurrentState;
        public uint dwEventState;
        public uint cbAtr;
        public fixed byte rgbAtr[36];
    }

    private static readonly Lazy<nint> s_t0Pci = new(() => ResolvePci("g_rgSCardT0Pci", SCARD_PROTOCOL_T0));
    private static readonly Lazy<nint> s_t1Pci = new(() => ResolvePci("g_rgSCardT1Pci", SCARD_PROTOCOL_T1));

    /// <summary>
    /// <c>SCARD_PCI_T0</c> / <c>SCARD_PCI_T1</c>: the exported <c>g_rgSCardT?Pci</c> of winscard.dll, or an
    /// identical <c>{protocol, 8}</c> struct if the export can't be resolved.
    /// </summary>
    public static nint PciFor(uint activeProtocol) =>
        activeProtocol == SCARD_PROTOCOL_T0 ? s_t0Pci.Value : s_t1Pci.Value;

    private static unsafe nint ResolvePci(string export, uint protocol)
    {
        if (NativeLibrary.TryLoad(Lib, typeof(WinSCardNative).Assembly, null, out var handle) &&
            NativeLibrary.TryGetExport(handle, export, out var address))
        {
            return address;
        }
        // Process-lifetime allocation (two 8-byte structs at most).
        var pci = (ScardIoRequest*)NativeMemory.AllocZeroed((nuint)sizeof(ScardIoRequest));
        pci->dwProtocol = protocol;
        pci->cbPciLength = (uint)sizeof(ScardIoRequest);
        return (nint)pci;
    }

    [LibraryImport(Lib)]
    public static partial int SCardEstablishContext(uint dwScope, nint pvReserved1, nint pvReserved2, out nint phContext);

    [LibraryImport(Lib)]
    public static partial int SCardReleaseContext(nint hContext);

    [LibraryImport(Lib, EntryPoint = "SCardListReadersW", StringMarshalling = StringMarshalling.Utf16)]
    public static partial int SCardListReaders(nint hContext, string? mszGroups,
        [Out] char[]? mszReaders, ref uint pcchReaders);

    [LibraryImport(Lib, EntryPoint = "SCardConnectW", StringMarshalling = StringMarshalling.Utf16)]
    public static partial int SCardConnect(nint hContext, string szReader, uint dwShareMode,
        uint dwPreferredProtocols, out nint phCard, out uint pdwActiveProtocol);

    [LibraryImport(Lib)]
    public static partial int SCardReconnect(nint hCard, uint dwShareMode, uint dwPreferredProtocols,
        uint dwInitialization, out uint pdwActiveProtocol);

    [LibraryImport(Lib)]
    public static partial int SCardDisconnect(nint hCard, uint dwDisposition);

    [LibraryImport(Lib, EntryPoint = "SCardGetStatusChangeW")]
    public static unsafe partial int SCardGetStatusChange(nint hContext, uint dwTimeout,
        ScardReaderState* rgReaderStates, uint cReaders);

    [LibraryImport(Lib)]
    public static partial int SCardGetAttrib(nint hCard, uint dwAttrId, [Out] byte[] pbAttr, ref uint pcbAttrLen);

    [LibraryImport(Lib)]
    public static partial int SCardTransmit(nint hCard, nint pioSendPci,
        byte[] pbSendBuffer, uint cbSendLength, nint pioRecvPci,
        [Out] byte[] pbRecvBuffer, ref uint pcbRecvLength);
}
