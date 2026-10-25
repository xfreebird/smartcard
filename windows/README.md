# MoldSign for Windows (F-13)

Native Windows port of the MoldSign signing stack for the Moldovan eID card (IDEMIA CosmoX ID-A, IAS/ECC)
on a PC/SC reader (bit4id miniLector POCKET EVO). The C# core is a line-by-line port of the Swift
reference (`apple/Sources/MoldSignKit`), gated by the shared golden vectors in `../spec/vectors`.
Contracts: [`docs/09-architecture.md`](../docs/09-architecture.md), [`docs/10-design-system.md`](../docs/10-design-system.md),
[`spec/cli.md`](../spec/cli.md), plan items `WIN-*` and `CLI-*` in [`PLAN.md`](../PLAN.md).

## Project map

```
windows/
  MoldSign.slnx                  all projects (the WinUI app maps Any CPU → x64)
  MoldSign.Portable.slnf         Core + CLI + tests: builds and tests on any OS
  global.json                    .NET SDK 10.0.1xx or later feature band
  src/MoldSign.Core/             class library (net10.0, AOT-compatible), namespace MoldSign.Core
    Crypto/    Hex, AesPrimitives (ECB/CBC, no padding), Cmac (RFC 4493), Iso9797, DigestInfo
    Card/      SecureChannel (SM wrap/unwrap), IasEcc (KDF, external auth, session keys),
               CosmoXCard (APDU flow), CardException + CardErrorKind, ApduResponse
    Transport/ ICardTransport, WinSCardTransport (+ WinSCardNative P/Invoke, LibraryImport)
    Bridge/    BridgeOriginPolicy (embeds ../spec/bridge/allowed-origins.properties), BridgeProtocol DTOs
    Signing/   PadesSigner, XadesSigner, TrustServices, Validator   ← stubs, TODO(WIN-01)
    Services/  SigningService facade (docs/09 §3.4) + models (ReaderState, CertificateSummary, Consent…)
  src/MoldSign.Cli/              moldsign.exe, the Windows CLI (spec/cli.md, CLI-03)
  src/MoldSign.App/              WinUI 3 tray app (net10.0-windows10.0.19041.0, unpackaged)
    App.xaml(.cs)                tray-first lifetime (DispatcherShutdownMode.OnExplicitShutdown)
    MainWindow.xaml              Mica + NavigationView: Semnează, Verifică, Activitate, Card (+ Setări)
    Tray/                        TrayIconService (H.NotifyIcon), TrayFlyoutWindow (acrylic flyout = macOS popover)
    Controls/                    StatusCard, DropZone
    Views/                       SignPage, VerifyPage, ActivityPage, CardPage, SettingsPage
    Services/                    AppServices (composition root), ReaderWatcher, PinVault, BridgeHost (Kestrel),
                                 ConsentCoordinator (PIN dialog / Windows Hello), AppState, AppSettings, Loc
    Strings/ro-RO|en-US/         Resources.resw (Romanian default, English fallback; copy from docs/10 §5)
  tests/MoldSign.Core.Tests/     xUnit: spec/vectors, SM, card flow over fake transports, origin policy, CLI
```

## Prerequisites

| | Version |
|---|---|
| OS (run) | Windows 10 1809 (17763) or later, Windows 11; x64 or ARM64 |
| .NET SDK | 10.0.100 or later (verified with 10.0.402) |
| Visual Studio (app) | 2022 17.14+ or 2026, workloads ".NET desktop development" and "WinUI application development" (`.slnx` needs 17.13+) |
| Windows App SDK | 1.8.260921001 (NuGet, self-contained: no runtime installer needed) |
| Windows SDK build tools | 10.0.26100.7705 (NuGet) |
| H.NotifyIcon.WinUI | 2.4.1 |
| NativeAOT CLI | on Windows: VS "Desktop development with C++" (MSVC linker + Windows SDK) |
| Card | Smart Card service (`SCardSvr`) and the inbox Microsoft CCID driver (`usbccid.sys`) for the miniLector, see WIN-02 |

## Build, test, run

Any OS (macOS/Linux included, card commands excepted):

```sh
dotnet test MoldSign.Portable.slnf              # 108 tests: vectors, SM, card flow, origin policy, CLI
dotnet run --project src/MoldSign.Cli -- --help
dotnet run --project src/MoldSign.Cli -- readers # non-Windows: "error: PC/SC transport is only available on Windows", exit 5
```

Windows:

```powershell
dotnet build MoldSign.slnx -c Debug -p:Platform=x64
dotnet test  MoldSign.Portable.slnf
dotnet run --project src/MoldSign.App -p:Platform=x64      # or F5 in Visual Studio (MoldSign.App, x64)
dotnet run --project src/MoldSign.Cli -- readers
dotnet run --project src/MoldSign.Cli -- cert --out my-cert.der
dotnet run --project src/MoldSign.Cli -- sign-hex <digestinfo_hex>   # PIN prompt without echo; or $env:MSIGN_PIN / --pin-stdin
```

### Publishing the CLI (`moldsign.exe`)

Product RIDs: `win-x64`, `win-arm64`.

```powershell
# NativeAOT (must run ON Windows; AOT cannot cross-compile between OSes)
dotnet publish src/MoldSign.Cli -c Release -r win-x64   -p:PublishAot=true
dotnet publish src/MoldSign.Cli -c Release -r win-arm64 -p:PublishAot=true   # needs the MSVC ARM64 build tools
```

```sh
# From macOS/Linux (non-AOT, self-contained single file; works cross-OS)
dotnet publish src/MoldSign.Cli -c Release -r win-x64 --self-contained -p:PublishSingleFile=true
```

macOS and Linux CLIs are the native Swift `moldsign` (CLI-02), not this project.

## CLI (spec/cli.md)

`readers`, `cert [--out f.der]`, `sign-hex <digestinfo_hex>` are real. `sign`, `xades`, `verify`, `server`,
`cms-for-hash` print `error: not implemented yet (WIN-01)` and exit 1. Global options: `--reader <name|substring>`
(default: first reader with a card), `--quiet`, `--pin-stdin`. PIN order: `--pin-stdin` → `MSIGN_PIN` → prompt
without echo (`Console.ReadKey(intercept: true)`); `--pin` is rejected. Exit codes: 0 ok, 1 usage/unexpected,
2 verify invalid, 3 wrong PIN (remaining attempts on stderr), 4 PIN blocked, 5 no reader/card (and non-Windows),
6 network.

## Real vs stub

| Area | Status |
|---|---|
| Crypto (AES ECB/CBC, CMAC, ISO 9797-2, DigestInfo) | real, vector-tested |
| Secure messaging (wrap/unwrap, SSC rules, Le=00, 87/85/97/99/8E) | real, vector-tested |
| CosmoXCard: authenticate, SELECT MF/ADF, READ BINARY, VERIFY ref 03, MSE SET + INTERNAL AUTHENTICATE, certificate read | real, tested over fake transports; not yet run against a card |
| WinSCardTransport (SHARED, T0\|T1, `g_rgSCardT1Pci`, reconnect/reset option) | real; runtime unverified (WIN-02) |
| BridgeOriginPolicy (all 73 vendor values, vendor regex conversion, header only without Origin) | real, tested |
| SigningService: `Certificate()`, `SignDigestInfo()`, card lock, reader state, `DefaultOutputPath` (D-06) | real |
| SigningService: `SignPdf`, `SignXades`, `Verify` → PadesSigner / XadesSigner / Validator / TrustServices | stubs, `NotImplementedException` TODO(WIN-01) |
| App: tray icon + flyout, Mica main window, pages, StatusCard, DropZone, Romanian strings | real UI, signing buttons surface "not available yet (WIN-01)" |
| App: ReaderWatcher (DeviceWatcher + CardAdded/Removed), PIN-less holder greeting | real; toasts TODO(WIN-03) |
| App: PinVault (Credential Locker, Windows Hello gate via `UserConsentVerifierInterop`) | real (WIN-05) |
| App: BridgeHost (Kestrel 127.0.0.1:18480, origin gate, CORS, PNA preflight, `GET /certificates` → `{"certificateModel":[]}`) | skeleton; TLS 18443 PFX + signing routes TODO(WIN-06) |
| Start at login, single instance, first run, language override | TODO(WIN-04) |
| Explorer verb, MSIX/winget | TODO(WIN-07), TODO(WIN-08) |

## Deliberate deviations from the Swift reference (APDU bytes unchanged)

* **CMAC of the empty message** follows RFC 4493. `cpcsc.c` writes the pad byte out of bounds there; the card
  protocol never MACs an empty message, and the vectors include NIST's empty case.
* **READ BINARY unpads once.** `Card.swift` ISO-unpads each chunk again after `SecureChannel.unwrap` already did,
  which truncates any 128-byte chunk ending in `00`/`80`. It never fired on the reference card (no chunk boundary of
  its 1799-byte certificate ends in those bytes); a test covers it here. Swift should get the same fix.
* Malformed plain APDUs (Lc beyond the body, extended length) throw instead of being silently mangled.
* Like Swift, SM responses without tag 8E are accepted; rejecting them is TODO(WIN-01) once Swift changes first.

## How this was verified without Windows

On macOS with the .NET 10 SDK: Core, CLI and tests build with warnings as errors and all tests pass; the CLI
NativeAOT-compiles with no trim/AOT warnings; the win-x64 single-file publish produces a PE32+ console exe.
The WinUI app cannot be built off Windows (XAML compiler, MakePri), so its C# (services and code-behind, with
emulated XAML-generated members) was compiled against the real Windows App SDK 1.8 / Windows SDK / H.NotifyIcon
reference assemblies, every XAML type/attribute/property-element/setter name was type-checked via `nameof`, the
theme-resource keys were matched against WinUI's `generic.xaml`, and `BridgeHost` was run and probed with curl.
Still unverified: the XAML markup compile itself, the app at runtime, and WinSCard against a real reader.
