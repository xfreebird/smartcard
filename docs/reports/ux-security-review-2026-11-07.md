# eSemnBun UX, security and integration review - 7 November 2026

Base: `d0f4f131499e7e23bad8e75be6ead77c0b07fd9b` plus this working tree. Existing release-report and plan changes were preserved. No release, store submission or real-card signing is included.

[Phone-friendly screenshot report](ux-review-2026-11-07.pdf), [individual screenshots](ux-2026-11-07/screenshots/) and [evidence manifest](ux-2026-11-07/screenshot-manifest.json).

## Implemented changes

- iOS Sign places card identity and files in separate scrollable columns from 560 points of usable width, including Duo outer landscape after vertical system-bar insets. The compact header frees space on shorter displays. Signing uses the native toolbar in compact-height layouts; accessibility text sizes select one column and put filenames above metadata/actions.
- iPhone Duo uses native SDK 27.1 layouts on both displays, with eight light/dark portrait/landscape captures. A single-scene declaration preserves the existing one-window ownership model. iOS delivery requires SDK 27.1+ while retaining the iOS 17 deployment minimum.
- iOS Verify has one instruction and a formats-only subtitle, translated in Romanian, English and Russian.
- Android landscape Sign uses separate card and file panes. Compact navigation uses readable localized labels at the normal font size. A compact status control preserves the application title on narrow phones and retains the full accessibility description. Short landscape navigation and document panes can scroll to their remaining controls.
- Apple production builds require protected Keychain storage for saved PINs and ignore legacy weak records. Android saved PIN ciphertext is authenticated against the target certificate and format version. Legacy saved records require manual re-entry and a new save after successful signing.
- Swift and Android bridge results are bound to their requesting origin. Swift releases non-retained batch PIN state after long-poll completion and denies browser requests to filesystem routes while retaining native-client compatibility.
- Windows keeps the signing action fixed while a queued batch scrolls, wraps drop instructions, bounds long status labels and localizes Settings switch states.
- Linux fixes narrow-window page measurement, header/bottom navigation, Documents rows, signing footer/file tags and Verify localization.
- Swift CLI detached XML references are confined beneath the selected document directory using descriptor-relative access; traversal, symlinks and special files are rejected. Windows CLI help now identifies its unimplemented commands.

The sampled macOS layouts did not establish a production visual defect. Debug-only preview controls now support explicit content sizes and isolated Settings capture.

## Hosts and coverage

The main Mac ran Apple and Android work: macOS 26.7.1, Xcode 26.6, an iPhone 17e and iPad mini simulator, and an Android API 36 emulator with explicit size profiles. The connected MacBook Air runs macOS 27.2 and hosted the Fedora 44 ARM64 and Windows 11 ARM64 QEMU guests. The Windows app runs as x64 under emulation. Android used the main Mac because the Air lacked its SDK at the discovered locations.

This is representative coverage across phone, tablet and desktop sizes. It does not claim every device, OS, language, text size or interaction combination. All card identities and documents in the screenshots are fictional or synthetic.

| Area | Evidence |
| --- | --- |
| iOS/iPadOS | [Platform report](ios-ux-2026-11-07.md) |
| iPhone Duo | [Native display review](iphone-duo-ux-2026-11-07.md), [SDK delivery gate](iphone-duo-build-2026-11-07.md) |
| Android | [Platform report](android-ux-2026-11-07.md) |
| macOS | [Platform report](macos-ux-2026-11-07.md) |
| Windows | [Platform report](windows-ux-2026-11-07.md) |
| Linux | [Platform report](linux-ux-2026-11-07.md) |
| PINs and bridge authorization | [Security report](security-2026-11-07.md) |

## Validation

- Full final Swift core suite: 63 tests executed, 5 opt-in tests skipped, 0 failures. Includes simulated-card, bridge and filesystem-containment regressions.
- Android core: 121 tests, 1 live TSA skip, 0 failures. Android certificate-bound AES-GCM regression: passed.
- Final iOS simulator Debug, signed macOS Debug and native Windows x64 Debug builds passed. macOS strict code-signature verification passed with the smart-card entitlement retained.
- Fedora native Debug build and 14 app tests passed. A subsequent native rebuild and focused Glibc filesystem-containment test passed after the shared helper was added.
- Windows native UI Automation exercised synthetic signing/verification and confirmed the queued action stays visible after scrolling. Android actual swipes reached the lower navigation and signing action. Linux scrolling, Verify disclosure and Clear results were exercised.
- Duo SDK 27.1 Debug and unsigned Release simulator builds passed; eight native images were inspected. One XCTest state-assertion test passed. Device Hub controls separately exercised actual portrait/landscape geometry, and reopening retained the selected card/two-file queue in the same process after simulator wake/reactivation. These are distinct checks; XCTest orientation requests alone did not rotate the inner surface. A normal iPhone SDK 27.1 smoke and maximum-text-size capture also passed.
- iOS SDK preflight rejected the old SDK and accepted 27.1 locally. Shell, Ruby, workflow YAML and whitespace checks passed; no hosted CI, archive or upload was run.
- Catalog completeness/export consistency and whitespace checks pass.

## Security assessment

Apple protected Keychain and Android authentication-bound Keystore encryption provide the strongest per-use controls in this implementation. Windows stores PINs in Credential Locker and separately gates application retrieval through Windows Hello. Linux uses a session-unlocked Secret Service and application consent; it has no equivalent per-read OS presence gate. These protection levels must not be described as interchangeable.

No actual PIN, private credential or card was accessed. Live biometric enrollment/cancellation, signed Release Keychain behavior, Windows Hello and locked Linux keyring behavior were not tested. Managed Swift/C# strings do not provide deterministic plaintext zeroization. The localhost compatibility header is public protocol text, so local-process authorization still depends on consent and card identity checks. Details and remaining limits are in the security report.

## Integration investigations

These are proposals, not shipped integrations:

- [Siri / App Intents](siri-integration-2026-11-07.md): start with file verification, foreground preparation for signing, and Documents navigation. Preserve native approval and PIN interaction. The current Siri AI beta/schema APIs require newer SDK/device checks; they do not establish a supported cryptographic-signing schema.
- [macOS features](macos-integration-2026-11-07.md): compare useful native integrations with the existing Finder Services, Open With, menu/tray and startup features.
- [CLI / MCP](agent-integration-2026-11-07.md): structured read-only verification first, then local stdio MCP and an authenticated foreground approval broker. PINs and signing approval never become model arguments. Windows CLI needs feature parity work before the shared CLI contract can be advertised there.

The research uses current official documentation and records API, language, platform and security limits. No App Intents, MCP server or new desktop approval broker was implemented.
