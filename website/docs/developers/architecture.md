---
title: Layered architecture
description: The native apps, application services, cryptographic core, platform adapters and external systems in eSemnBun.
---

The project shares behavior across platforms without sharing one web-based UI. Apple and Linux use the Swift core. Android uses a Kotlin implementation and Windows a C# implementation. Shared contracts and golden byte vectors keep their card behavior aligned.

## Component diagram

![Layered component diagram: native interfaces call application services, which coordinate the cryptographic core and platform adapters; adapters reach the card, storage and PKI services.](/img/developers/architecture.svg)

[Open the full-size diagram](/img/developers/architecture.svg). Arrows show calls or data exchange; the layers describe responsibilities, not separate servers. Most components run inside the app process. The operating system's smart-card service and remote PKI endpoints are outside it.

| Layer | Responsibility | What belongs elsewhere |
| --- | --- | --- |
| Native presentation | Screens, accessibility, file selection, progress and consent UI | APDU construction and cryptographic keys |
| Application services | Selected signing method and card, queued documents, identity checks, batch policy, persistence and bridge lifetime | Drawing a card or parsing USB descriptors |
| Cryptographic core | Card session, secure messaging, PDF/XML signing, verification and protocol models | Native dialogs and credential-store UI |
| Platform adapters | Card transport, cryptographic primitives, HTTP, file access and protected storage | User-facing workflow decisions |
| External systems | The reader/card, OS services, filesystem and timestamp/revocation services | App state |

## Implementation map

| Target | UI and orchestration | Core and physical transport |
| --- | --- | --- |
| macOS | SwiftUI/AppKit; `apple/Apps/macOS`, `apple/Apps/Shared` | `swift/MoldSignKit`; CryptoTokenKit for native slot access, PC/SC for CLI paths |
| iPhone / iPad | SwiftUI/UIKit; `apple/Apps/iOS`, shared screens and model | Same Swift core with `TKSmartCard` for reader sessions and Core NFC ISO 7816 sessions on supported iPhones |
| Android | Compose / Material 3; `android/app` | Kotlin `android/core` with USB CCID/T=1 in `android/transport-usb` and `IsoDep` in Android reader mode |
| Windows | WinUI 3; `windows/src/MoldSign.App` | C# `windows/src/MoldSign.Core`; Windows `WinSCard` |
| Linux | GTK4/libadwaita via Swift C interop; `linux/` | Same Swift core, pcsc-lite, OpenSSL and POSIX sockets |
| CLI and MCP | Swift executables on macOS/Linux; C# executables on Windows | The same signing and verification services as the platform core |

The Swift C shim in `Sources/CPCSC/cpcsc.c` includes the platform's real PC/SC headers. Swift sees fixed-width wrappers. This matters because similarly named PC/SC types have different widths on macOS and Linux. Do not reproduce operating-system declarations by guessing their size.

## A small interface makes hardware replaceable

The Swift card transport contract is intentionally narrow:

```swift
public protocol CardTransport: AnyObject {
    var readerName: String { get }
    func transmit(_ apdu: Data) throws -> Data
    func disconnect()
}
```

`transmit` returns response data **including the final two status bytes**. `CosmoXCard` interprets card status and handles `61xx` response continuation. Kotlin's `ApduTransport` and C#'s `ICardTransport` serve the same role. A simulated card implements this boundary, so card workflows can be exercised without a physical device or a real PIN.

## Mobile NFC signing

Sign offers both methods on supported NFC phones, even with a USB reader connected. The same PIN coordinator or dialog serves both methods. NFC collects authorization first, then reads the signing certificate and signs during one foreground session per document. The batch binds to the first accepted certificate, and known certificates must match the scanned card before PIN verification. Connection loss, a card mismatch or a PIN error ends the attempt so the user can decide how to proceed.

Stored PINs use the signing-certificate identity across both transports. NFC reuses the existing document preparation and output path. The public certificate supplies the holder and validity information shown in the app. Access to photos, biometrics or travel-document data has not been established. iPad and desktop signing use a card reader. See the [iOS and Android protocol and sequence diagrams](reader-protocol.md#mobile-nfc-transport).

## State, concurrency and identity

Card operations are serialized through the signing service. A secure session contains a changing send sequence counter; interleaving two operations would make the host and card disagree. Kotlin and C# use static/shared locks; Swift's lock belongs to the service instance, so callers must share the intended service instead of creating independent services for the same reader. These locks do not coordinate unrelated processes such as the vendor app.

Each reader has a card generation. Removal/reinsertion changes that generation and invalidates cached certificate data. A slow certificate read must not overwrite the state of a newer card. Selection identifies a reader and certificate, not just a position in a list.

Before PIN verification, the service reads the certificate again and compares it with the approved identity. A mismatch stops the operation before `VERIFY`. Certificate SHA-1 is used as an identity/cache identifier in this protocol; that does not mean PDF signatures use SHA-1.

Blocking card and network work runs away from the UI thread. Results return through the platform's UI scheduler: the main actor/queue on Apple, coroutine/UI state on Android, the WinUI dispatcher on Windows, and GLib's main loop on Linux. `DispatchQueue.main` alone is not a GTK main-loop integration.

## Platform services and their limits

| Concern | Platform solution |
| --- | --- |
| Remembered PIN | Apple Keychain and system authentication; Android Keystore encryption and biometric APIs; Windows credential storage and platform authentication; Linux Secret Service |
| Files | Apple document pickers/security-scoped access; Android Storage Access Framework and content URIs; Windows native pickers/filesystem; Linux GTK/GIO and desktop portals |
| Background operation | macOS menu bar and helper, Windows tray/helper, Android foreground service, Linux application hold/desktop portal; iOS execution depends on app lifecycle |
| Network compatibility | A controlled HTTP path for the PKI endpoints, preserving required HTTP URLs and avoiding unintended HSTS/proxy behavior |

These mechanisms have different guarantees. Linux Secret Service, for example, does not provide the same per-read biometric gate as a mobile keystore flow. A simulator cannot establish physical reader compatibility or distribution entitlements.

## Where to begin a change

Trace a user action from its screen to the application service, then into the core or adapter. For a protocol change, inspect `Card/Card.swift`, the Kotlin/C# equivalents, `spec/vectors/card-crypto.json` and simulated-card tests together. For a UI change, begin with [the design-system boundaries](design-system.md). For a delivery change, begin with [the workflow matrix](releasing.md).
