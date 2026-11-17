---
title: Design system across platforms
description: Shared semantic tokens and component contracts implemented with SwiftUI, Compose, WinUI and GTK/libadwaita.
---

eSemnBun shares a visual language and interaction rules while using native controls. A card selection, warning or signing result should mean the same thing everywhere. Its widget implementation, navigation and system dialogs should fit the host platform.

## Three parts of a component

1. **Content:** already-formatted labels, values and accessibility descriptions.
2. **Appearance:** semantic colors, spacing, typography, artwork and focus/selection states.
3. **Interaction:** callbacks for selection, opening, removing or retrying; screen/application code owns the operation.

A reusable card face should not read a reader, look up a PIN, localize raw domain values or launch a signing service. The screen maps domain state into display content and supplies callbacks. This makes components previewable with fictional data and keeps protocol work out of drawing code.

## Tokens and their native equivalents

| Role | Light / dark reference | Use |
| --- | --- | --- |
| Brand | `#2350D8` / `#7C9BFF` | Product accent, prominent emphasis |
| Brand soft | `#E8EEFF` / `#1C2547` | Low-emphasis selected surface |
| Success | `#15803D` / `#4ADE80` | Successful result or ready state |
| Warning | `#B45309` / `#FBBF24` | Needs attention or incomplete evidence |
| Danger | `#C62828` / `#F87171` | Failed operation or invalid result |
| Raised surface | `#FFFFFF` / `#1E1F24` | Cards/panels where native styling allows |

These are semantic roles, not a rule to replace every native surface with a fixed hex color. Android can use Material You dynamic colors for its general scheme while retaining semantic status colors. Linux maps to libadwaita named colors and the user's accent. Windows high-contrast resources use system colors. Apple prominent actions retain native button styling.

Common spacing uses multiples around 4, 8, 12, 16, 24 and 32 logical units; some platform scales also include 20. Shared card/sheet radii commonly use 14/18. Control radii and typography remain platform-specific. Use the actual token name instead of duplicating its numeric value in a screen.

## Platform implementation

| Platform | Implementation entry points | Native behavior |
| --- | --- | --- |
| Apple | `apple/Apps/Shared/DesignSystem/Theme.swift`, `NativeButtonStyle.swift`, content and label structs | SwiftUI environment appearance, system fonts, native actions; UIKit/AppKit at OS integration points |
| Android | `android/app/src/main/kotlin/md/moldsign/app/ui/theme/Theme.kt`, `ui/components/` | Material 3 theme, composition-local status colors, dp/sp sizing and Compose semantics |
| Windows | `windows/src/MoldSign.App/Themes/Tokens.xaml`, `Controls/`, presentation mappers | Theme resources, Fluent controls, keyboard/UI Automation and high-contrast dictionaries |
| Linux | `linux/Sources/MoldSignGnome/Presentation/DesignSystem/` | GTK widgets, libadwaita named colors, CSS, Cairo/Pango card artwork and AT-SPI |
| Website | `website/src/css/palette.css`, `custom.css`, React components | Docusaurus appearance, system fonts and original native screenshots |

### Apple: native action styling and shared screens

`Theme` resolves light/dark semantic colors. Shared screens use content types such as `IdentityCardContent` and label bundles. `CardSelector` composes selection behavior around card artwork; it is screen-level composition, not a transport API.

`NativeButtonStyle` uses system glass/prominent styles on supported iOS versions and native fallbacks elsewhere. Do not put a second custom fill behind a system action or change its style when disabled. Toolbar and menu controls inherit their context. A safe-area inset reserves space for the bottom Sign action so document rows can scroll clear of it. Icon actions need accessible names and adequate hit areas.

### Android: theme roles and state-driven composition

`MoldSignTheme` supplies Material color/shape/typography roles and `LocalStatusColors`. Presentation mappers prepare card content; components receive values and events. Use `dp` for layout and `sp` for scalable text. The wallet uses native Compose paging/selection behavior, with selected reader identity retained independently of position. File access remains behind document services, not composables.

### Windows: resources and accessible controls

Use `ThemeResource` for appearance-dependent brushes and native resources for text and surfaces. `Tokens.xaml` includes light, default/dark and high-contrast dictionaries. `Controls/CardWalletContent.cs` and `Presentation/CardWalletContentMapper.cs` separate rendered card content from application state. Keep automation identifiers and keyboard paths stable when changing controls; native journey scripts depend on those semantic actions.

### Linux: libadwaita with Swift

The app calls GTK/libadwaita's C API from Swift. `Style.swift` adds project CSS to native widgets, while `CardArt.swift` draws the identity-card illustration. Content types keep drawing independent of localization and card I/O. Signals and pointer conversions live in the GTK adapter helpers. Background results return with the GLib main-loop helper; a regular Apple main-queue assumption is insufficient on this platform.

## Component behavior to preserve

| Component | Contract |
| --- | --- |
| Identity-card wallet | Select a reader/certificate; keep the selected identity stable; accessible keyboard/touch selection |
| Card illustration | Fictional silhouette, neutral emblem, certificate-derived name/expiry; no photograph, MRZ or document-number claim |
| Empty/reading/error card | Explain the state and next action without pretending a usable identity exists |
| Document row | File name and known size, readable format/stamp settings, full semantic action targets |
| Signing progress | Separate connection, authorization, signature, timestamp and save; do not show completion before output exists |
| Verification result | Distinguish valid, invalid and evidence that cannot be confirmed; color accompanies text/icon |
| PIN/consent UI | State the selected identity and requester, allow cancellation, never silently retry a failed PIN |
| Saved files/history | Clearing history does not delete output files; removing a queued input does not delete its original |

The current card artwork uses a stylized landscape ratio of approximately 1.618 and a 3:5 portrait area. It is not a pixel-exact reproduction of a physical ID. Its paper colors remain fixed in dark mode; the surrounding controls adapt. Historical design notes include earlier vertical switchers and ratios, so follow current components when maintaining the UI.

## Localization

`localization/catalog.json` and `scripts/localize.py` coordinate native strings. Website UI has its own `website/src/i18n/catalog.json`; Docusaurus translations live under `website/i18n/ro` and `website/i18n/ru`.

Before regenerating native outputs, compare the catalog with current native resources. Import/reconcile newer native text first so an export does not erase it. Localize labels and templates, not a certificate holder's name or a file path. Keep technical format identifiers stable even when the visible label is friendlier.

```sh
python3 scripts/localize.py --check --require-complete
python3 scripts/export-browser-services.py --check
python3 scripts/prepare-store-metadata.py --check
```

Run regeneration only after reviewing the source changes. These commands check existing outputs; they do not translate missing text.

## Signing and Settings navigation

On phones, keep the signing method and primary action at stable positions. NFC shows its illustration and help. Choosing a reader shows the next connection step, or the connected card artwork and identity. Layouts with more space should show the same connection state and selected card. Keep card details discoverable through the info action on Sign and card management in Settings.

Settings starts with Demo mode. Group cards, readers and saved PIN actions by task. Use dismissible sheets or dialogs for a focused task such as card details or signing help. Desktop Settings follows each platform’s navigation conventions. File protection belongs in Documents, while Sign and Verify retain their file-selection and desktop drop areas.

## Adding or changing a component

Define its content and callbacks first, then implement it using that platform's tokens. Add it to an appropriate Debug fixture and inspect long names, empty states, light/dark appearance, large text, narrow windows and keyboard/screen-reader behavior. For interactive work, use [native automation](testing.md); a screenshot alone cannot prove that the whole row is clickable or that selection reaches the correct card.

The repository's design-boundary checks live in `scripts/ci/test_design_system_boundaries.py` and `scripts/ci/check-linux-design-system.py`. They complement native compilation and interaction checks; they do not replace them.
