# Android edge-to-edge — 2026-11-22

Google Play's 0.2.14 (1793624701) finding names `Window.setStatusBarColor`,
`Window.setNavigationBarColor` and `LAYOUT_IN_DISPLAY_CUTOUT_MODE_SHORT_EDGES`.
The exact signed build's mapping and DEX resolve every listed call site to Activity 1.12.3:

| Play site | Owning implementation |
| --- | --- |
| `b.n.b` | `EdgeToEdgeApi26.setUp` |
| `b.p.b` | `EdgeToEdgeApi29.setUp` |
| `b.r.b` | `EdgeToEdgeApi35.setUp` |
| `V.o.p` | Shared synthetic setter called by `EdgeToEdgeApi28`; writes cutout mode 1 |

The arbitrary synthetic class name is not evidence of a Compose layout defect. Direct bytecode
inspection of Core 1.17.0 also showed both color setters and a pre-30 `SHORT_EDGES` branch in
`WindowCompat.enableEdgeToEdge`. Switching helpers alone would retain the reported API uses.

## Implementation

- `MainActivity` uses `WindowCompat.setDecorFitsSystemWindows(window, false)` and preserves
  `adjustResize`; its Compose side effect applies icon appearance from the actual app theme.
- Theme resources configure transparent status/navigation surfaces instead of runtime color
  setters. API 26 keeps a dark navigation surface because dark navigation icons require API 27.
  API 29+ keeps Android's three-button contrast protection. API 30+ declares cutout `always`.
  API 28/29 retain platform-default cutout behavior. The empty night override was removed so
  night mode inherits the same window policy through the DayNight parent.
- Scaffold continues to apply and consume safe-drawing insets once around navigation/content.
- Isolated Debug capture destinations survive theme/rotation recreation without replaying
  document imports, shortcuts or consent. Release capture support remains a no-op.

This follows the [manual edge-to-edge setup](https://developer.android.com/develop/ui/views/layout/edge-to-edge-manually)
for theme-based transparency and explicit inset handling. The convenience APIs remain the normal
Android recommendation; this app uses explicit setup to avoid their retained deprecated bytecode.

## Local UI evidence

On dedicated `emulator-5580`, Android 16/API 36 Google APIs ARM64, the new suite exercised:

| Axis | Values |
| --- | --- |
| Window | Phone 1080×1920 at 420 dpi; tablet 1600×2560 at 240 dpi |
| Navigation | Gestural; three-button |
| Orientation | Portrait; landscape, verified against actual window dimensions |
| Theme | Light; dark, with actual status/navigation icon appearance assertions |
| Cutout | Tall phone emulation, required to be present in root insets |
| Keyboard | Production PIN dialog with a real IME; confirm/cancel actions above the keyboard |

All **16 theme/configuration cases passed**, retaining **32 workspace/keyboard screenshots**.
Assertions also require full-window content and title/navigation controls inside safe drawing
bounds. Inputs and identities were fictional; no PIN was entered and no card was authenticated.
Selected landscape PIN and tablet dark-mode screenshots were visually inspected.
The suite also passed with `show_ime_with_hard_keyboard` initially disabled and restored it to 0
after both light/dark keyboard checks. The preference is managed within the suite, so CI does not
depend on the emulator profile's keyboard default.

The harness explicitly rotates after activity launch, observes recreated activities, waits for
destruction before the next consent fixture and applies themes before context attachment.
Earlier attempts exposed those fixture timing/orientation assumptions; the successful evidence
requires actual orientation and cutout presence rather than trusting requested settings.

Evidence lives under ignored `.local/validation/android-edge-2026-11-22/`, including the successful
`matrix-complete/` logs/screenshots and `summary.json`. The matrix restores display overrides,
navigation/cutout overlays and rotation/keyboard preferences. The test emulator is separate from
physical devices and enrolled accounts.

## Build and binary checks

The final source passed core/USB/app Debug/Release unit tests (222 passed, one opt-in live TSA
skip), Debug app/test APKs, optimized Release APK/AAB, and Debug/Release lint. Debug has 176 warnings
and one hint; Release has 177 warnings and one hint, with zero errors. CI guard tests passed 86
cases and Play publisher guards passed 12. The complete local 34-journey native batch and all six
integration phases passed, including the default light/dark edge-to-edge phase. The final AAB
contains 3,698,020 bytes of DEX; R8 metadata indicates 96.66% obfuscation, 95.60% optimization and
96.44% shrinking.

The optimized DEX contains no invokes of either reported color setter and no retained
`androidx.activity.EdgeToEdge*` implementations. Its only remaining cutout field assignment writes
3 (`ALWAYS`), not 1 (`SHORT_EDGES`). API-qualified themes provide the activity cutout policy.

The required CI native batch now includes the suite-specific `PASS: edge-to-edge` marker.
Local test success does not establish real-card/biometric acceptance, older Android runtime
coverage, Play review approval or that Play's generic advisory has refreshed.

## Committed delivery and closed alpha

Source [`d42523c0`](https://github.com/xfreebird/smartcard/commit/d42523c013fbdf555035f436f5925c8b0341bfed)
and the keyboard-policy instrumentation follow-up
[`cfa8a537`](https://github.com/xfreebird/smartcard/commit/cfa8a537e9ec2d81e18e3b414a58059e7fa25a7b)
were committed/pushed to main as `xfreebird <xfreebird@gmail.com>`. The follow-up changes only the
Android-test source and documentation; the signed builder's application inputs are identical.
The superseded initial validation run was cancelled by the repository's normal concurrency policy.

| Operation | Verified outcome |
| --- | --- |
| [CI 45020997437](https://github.com/xfreebird/smartcard/actions/runs/45020997437) | Success on the latest source: routing guards, localization, Android integration/mock UI and aggregate `CI result`; 34 journey markers plus light/dark edge markers and all required integration phases |
| [Signed build 45020720486](https://github.com/xfreebird/smartcard/actions/runs/45020720486) | Success, exact application source above, 0.2.14 (1793624702); upload disabled during build |
| [Play publish 45021611601](https://github.com/xfreebird/smartcard/actions/runs/45021611601) | Success, `closed_testing`, selected `alpha`, result `submitted` |

Both live uploaded and reserved maxima were 1793624701 before reservation. Verified signed package
`md.esemnbun.app`, versionName 0.2.14, versionCode 1793624702, expected upload-certificate SHA-256
`0bd6c7ce1a0e57b3f959917d6c166c433184a3101cad5ddd5333b82bce9324cf` and AAB signature.

- Signed APK SHA-256: `1eb92346792a1c8579edad5fd89ce9d65f318439c075b097c5c3b6bd74657ad6`.
- Signed AAB SHA-256: `331cbeeb3e047c7cc8827f2d6a068702dd9da86f1eb4065b5532edf0598ec83f`.

The signed AAB has 3,697,700 bytes of uncompressed DEX and retains the mapping, R8 metadata,
bridge allow-list/TLS identity, public CA certificates and stamp metrics. Its actual optimized DEX
was independently inspected: zero invokes of either reported color setter, no Activity edge
helper classes and a sole cutout field assignment of 3 (`ALWAYS`). Its R8 percentages match the
local final build above.

The publisher reused this exact signed Actions artifact with EN/RO/RU notes. Independent API
inspection after submission verified versionCode/AAB hash and that production, internal and beta
matched their pre-submission state. No tester lists, listings, public GitHub release assets or
other platform packages were changed.

[Play Console alpha](https://play.google.com/console/u/1/developers/8344963402071617946/app/4973211912255144827/tracks/4698313398880262778)
visibly confirmed **Release 0.2.14 (1793624702) in review**; 1793624701 remained **Available to
selected testers**. Submission/API `completed` is not approval or new-build availability. Review
approval and refreshed Play advisories remain pending; neither advisory's disappearance was claimed.

Local evidence also includes `github-ci.log`, `signed-1793624702/identity.json`, the exact signed
APK/AAB and mapping, `publish-result/play-result.json`, and `play-before.json` / `play-after.json`.
