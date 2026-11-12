# 10 — Design System and Screens

## Current adjustments (12 November 2026)

These decisions supersede earlier vertical expand/collapse wallet descriptions below:

- Use a horizontal carousel; the selected card stays centered on swipe, arrow selection, resize and wallet changes.
- Draw the stylized card at width/height = 1.618034. The avatar frame uses width:height =
  3:5 (latest owner amendment); the head remains circular and shoulders retain their own proportions.
- Place the contact chip at the right edge, vertically centered. Reserve field width so text never crosses it.
  Draw eight contacts: three left, three right, two central pads; avoid an additional center island that creates extra regions.
- Draw a compact head-and-shoulders bust inside the 3:5 portrait frame, without long vertical torso sides.
  PIN entry is larger, bounded to available width and centered with its heading and document context.
- Keep nonzero native content gutters and intercomponent spacing throughout; backgrounds may extend to window edges. Windows Sign stacks the card above the document drop zone.
- Keep one hierarchy across platforms with native controls: card selection, document workspace, primary action,
  then outcomes/history. Desktop preferences expose language, appearance, stored PIN management and optional
  reader/card-insertion activation. Non-store macOS and Windows have a separately running helper that can open
  a closed app; startup/background permissions remain visible and configurable. First launch shows the main
  window on macOS, Windows and Linux, including the initial background-start case.
- Android tablets use the desktop vertical hierarchy: centered card, documents/picker below, then a compact
  centered signing action. From 600dp window width, keep the native navigation rail and bounded 680dp content
  with 24dp gutters; narrower multitasking windows use the compact layout.
- iOS and macOS use one floating Sign action at the trailing bottom safe area. At wide iOS widths (iPad and expanded iPhone Duo),
  signing/card controls sit left and document browsing/selection/operations sit right. Adapt to available width,
  including rotation and window resizing. Wide pane contents use symmetric 24pt inner/outer gutters; the primary
  action stays outside the scrolling content. macOS and Windows reader-empty states use one dotted rectangle without an
  additional titled panel; Windows keeps the document drop area below it. Signed results expose native sharing/export.
- iOS browser has address entry, navigation and share controls. Connectivity guidance refers only to mobile
  readers/adapters. Browser requests still require the normal origin and consent checks.

Translations are maintained in `localization/catalog.json` with stable semantic IDs; `scripts/localize.py`
exports native resources and typed Apple/Linux key APIs. Display wording is not a lookup key.
Debug mock scenarios use fictional cardholders and isolate hardware operations. Screenshots from older designs
remain historical evidence; dated captures live under the owner's Desktop screenshot directory.


Visual mock-ups of every screen below (all platforms, light/dark): **[eSemn UI concepts](https://claude.ai/artifact/5LZRjfVTDrQ9TKnscfWTyi)**
(private artifact; "eSemn" is a placeholder product name, see D-07).

Replaces the vendor suite's tabbed Swing window (four big icon tabs, file tables, empty
fieldsets, three dropdowns before the first click) with a **status-first, drop-first** design:
the app tells you what state the card is in and takes documents with one gesture.

Plan items: F-11, F-15, MAC-01…10, IOS-03…06, AND-*, WIN-04.

## 0. Design v2 (2026-10-25): status light, card wallet, native guidelines

v2 supersedes the per-screen details below wherever they disagree. Plan items: UX-01…UX-08.

### 0.1 Status light (tray / menu bar / notification)

The one glance that answers "can I sign?". It uses the same semantics everywhere:

| State | Light | Meaning | Tooltip / accessibility label |
|---|---|---|---|
| `ready` | **green** dot | at least one card read and ready | "Card pregătit · {holder}" (+ "· N carduri") |
| `reader` | **amber** dot | reader(s) connected, no card (or card being read) | "Cititor conectat · introdu cardul" |
| `busy` | **blue** dot (pulses where the platform allows) | signing / bridge request in progress | "Se semnează…" |
| `error` | **red** dot | mute card, card stuck, PIN blocked, PC/SC service down | the error's one-line recovery |
| `idle` | no dot, glyph dimmed | nothing connected | "Conectează cititorul" |

The dot sits on the bottom-right of the app glyph and is never the only signal: tooltip/label text always
says the same thing (WCAG, color blindness). The glyph stays monochrome/template so it fits the system bar;
only the dot carries color.

* **macOS:** `MenuBarExtra` label = template SF Symbol drawn in `labelColor` plus a `systemGreen/Orange/Blue/Red` dot
  (an `NSImage` drawing handler, so it adapts to light/dark/tinted menu bars).
* **Windows:** tray icon variants (glyph + colored dot) generated at runtime; tooltip = label.
* **Android:** the foreground-service notification uses a small icon + colored `setColor`, status text as content;
  a Quick Settings tile is optional (later).
* **GNOME:** no tray (GNOME HIG). Status goes to the Background portal (`SetStatus`, shown under Quick Settings →
  Background Apps) and to the window's status banner/card wallet.
* **iOS:** no tray; the wallet header carries the light.

### 0.2 Card wallet (card switching *is* the card illustration)

Every inserted card is drawn as an ID-card illustration and the illustrations are the selector. There is no separate
picker anywhere.

* **Card face:** rounded rect (ISO ID-1 ratio 85.6 × 54 → 1.585:1), brand gradient with a hue nudged per card
  (from the certificate SHA-1, ±25°) so two cards are told apart at a glance; gold chip; holder name (headline,
  1–2 lines, never truncated to "…" when short); "MDQSign · valabil până la MM/AAAA"; reader name (caption);
  state badge top-right (✓ ready, spinner reading, ⚠ error).
* **Selection:** the selected card is front-and-center at full scale with a "Folosit pentru semnare" (Used for signing)
  check badge and a focus ring. Other cards sit beside it slightly smaller (0.92) and dimmed (0.6); tap/click one to
  select it (spring animation, haptic on iOS/Android). Keyboard: ←/→ moves selection, Space/Enter selects. Paging
  dots when > 1 card.
* **Empty states are cards too:** dashed outline card "Introdu cardul" (reader connected), connector illustration
  "Conectează cititorul" (no reader), red-tinted card with the recovery text on error.
* **Re-read** ("Recitește cardul") is a context-menu / long-press action on a card plus a small toolbar button,
  not a separate panel.
* **Sizes:** popover/flyout compact (≈ 260 × 164), window large (≈ 340 × 214), phone full width minus 2 × 24 pt.
* **Accessibility:** each card is a button: "{holder}, card MDQSign, valabil până la …, {selected|neselectat}";
  selection is announced.

| Platform | Component |
|---|---|
| macOS / iOS | `ScrollView(.horizontal)` + `scrollTargetBehavior(.viewAligned)`, `matchedGeometryEffect`, `sensoryFeedback` (iOS) |
| Android | Material 3 `HorizontalMultiBrowseCarousel` (or `HorizontalPager`) with cards as `ElevatedCard`, haptic `LongPress` |
| Windows | `FlipView` / horizontal `ItemsView` of card templates (Fluent elevation, Mica), arrow-key selection |
| GNOME | `AdwCarousel` + `AdwCarouselIndicatorDots`, cards as `.card` styled boxes |

### 0.2b v3: national-ID card face, card and selector as ONE component, two-state tray (UX-09…UX-11)

Supersedes the card face in §0.2 and the tray colors in §0.1.

**Card face (UX-09).** The card is drawn as a stylized illustration of the Moldovan identity card (2025 design):
light pastel paper with guilloche lines, bilingual headings, a portrait frame and labelled fields. It is an
illustration of the user's own card: **no photo, no state coat of arms, no document number, no MRZ, no IDNP**.
It shows only data from the signing certificate. Fixed colors in light and dark mode (it depicts a physical object,
like a Wallet pass), with a hairline border and a shadow so it reads on dark backgrounds.

Normalized layout (W = card width, H = W / 1.586, corner radius 0.045 W, origin top-left):

| Element | Position | Style |
|---|---|---|
| Paper | full card | linear gradient TL→BR `#F4EAF0` → `#ECEFF7` → `#F6F0E1` |
| Guilloche | full card, behind everything | 12 sine waves across the width (amplitude 0.04 H, period ≈ 0.55 W, phase step 0.35 rad), 0.5–0.8 px, alternating rose `#C6A3BC` / blue `#A7B6DA` at 35 % opacity; a rosette of 8 ellipses centred (0.78 W, 0.62 H), radius ≤ 0.22 W, gold `#C9B48A` at 25 %. Per card the guilloche hue is rotated ±20° from the first byte of the certificate SHA-1, so two cards differ at a glance |
| "REPUBLICA MOLDOVA" / "REPUBLIC OF MOLDOVA" | top-left, x 0.045 W, y 0.06 H | navy `#283A8C`; 1st line bold, 0.036 W, letter-spaced; 2nd line regular 0.026 W; a 1 px navy rule under each |
| Emblem | centred between the headings, ≈ 0.07 W tall | **neutral shield outline** (bronze `#8C6A3A` stroke, `#E9D9B4` fill 60 %). Never the state coat of arms |
| "CARTE DE IDENTITATE" / "IDENTITY CARD" | top, right of the emblem | burgundy `#9E2A3F`; same sizes as the left heading |
| Contact chip | top-right corner, 0.10 W × 0.075 W | the gold chip from v2 |
| Portrait frame | x 0.045–0.285 W, y 0.30–0.90 H, radius 0.02 W | vertical gradient `#D9DCE3` → `#BFC4CF`, neutral grey silhouette (head + shoulders, `#8E95A3`) |
| Fields | x from 0.32 W; rows at y 0.30, 0.47, 0.64 H | label 0.024 W `#5A6070` "Numele/Surname", "Prenumele/Given name(s)", "Valabil până la/Valid until" (+ a second column at x 0.66 W on row 3: "Emitent/Issuer"); value 0.046 W semibold `#1E2230`, UPPERCASE with diacritics kept (MÎNDRU). Surname/given names come from the certificate's SN/GN; fallback: split the holder name at the first space. Date as `dd MM yyyy` (certificate notAfter, not the document expiry) |
| Status strip | x from 0.32 W, y 0.80–0.95 H | dot + one line: green "Pregătit pentru semnare", amber "Se citește cardul…" (with placeholder bars instead of field values), red problem text; reader name as a caption on large sizes |
| Disclosure (only with > 1 card) | right edge, vertically centred: centre (0.935 W, 0.50 H), diameter 0.085 W | round button, 85 % white fill + hairline, chevron pointing right (collapsed) that turns to point down (expanded), see below. Field values stop at 0.88 W so they never run under it |

Typography: the system font everywhere (SF / Roboto / Segoe UI Variable / Cantarell–Inter); sizes are relative to W so the
face scales from the popover (W ≈ 288) to phone width. Text uses fixed dark colors, never the theme's label color.

**Card + selector = one component (UX-10, revised).** There is no picker, menu, dots or carousel outside the card.
Collapsed, the component shows the *selected* card. With more than one card, a **disclosure button** sits inside the
card at the right edge, vertically centred:

* **Collapsed → expanded:** the chevron (pointing right) turns to point down and the component expands *in place* into a
  vertical list of **every** inserted card, each drawn at exactly the same size as the collapsed card (same face,
  same status strip), in reader order, 10–12 pt apart. The selected card carries the accent focus ring, and its status
  strip reads "✓ Folosit pentru semnare" in the brand blue instead of "Pregătit pentru semnare" (no separate badge:
  every other spot collides with the headings, chip or portrait); the disclosure button stays on it.
* **Pick:** tap/click any card in the list → it becomes the signing card and the list collapses back to it (spring /
  ease-out 250 ms, no motion with Reduce Motion). The disclosure button, Escape or a click on the selected card collapse
  without changing anything.
* **Keyboard:** the disclosure button is focusable (Space/Enter toggles); ←/→ on the collapsed card still switch to the
  previous/next card; ↑/↓ move between cards in the expanded list.
* **Context menu / long press** (unchanged): "Recitește cardul", plus "Semnează cu {holder}" for the other cards.
* With one card there is no disclosure button; with none, the component is the empty-state card (§0.2 rules).
* Containers grow with it: the menu-bar popover / tray flyout gets taller, forms/lists push the content below down.

Accessibility: collapsed, the card is one element "{holder}, card de identitate, valabil până la …, {i} din {n}",
adjustable (increment/decrement = next/previous card); the disclosure button is "Alege cardul ({n} carduri)" with
expanded/collapsed state. Expanded, each card is a button "Semnează cu {holder}" and the selected one reports *selected*.

**Tray / menu bar (UX-11).** The glyph follows the menu-bar convention (GitHub's, for one): a **solid disc with the
signature cut out**, so the bar shows through the signature; macOS draws it in `labelColor` with SF Symbol
`signature` punched out (`StatusIcon.swift`), Windows renders `windows/design/icons/tray.svg` per taskbar theme, the
Android notification icon is the same disc without the dot (`android/design/ic_stat.svg`). Two states only, on the
bottom-right dot of the glyph:

| Dot | When | Tooltip |
|---|---|---|
| **green** | at least one card is inserted (reading, ready or signing) | "eSemnBun · Card conectat · {holder}" |
| **gray** | no card (no reader, empty reader, or only cards in error) | "eSemnBun · Niciun card conectat" (or the error's one-liner) |

The richer five-state light (§0.1) stays inside the popover/flyout/window header. GNOME has no tray: the Background
portal status text carries the same wording. Android: the bridge notification's accent color is green/gray the same way.

**App icon (UX-13).** Same motif as the tray glyph: a white disc with the signature cut out (the plate shows through)
on the brand-blue gradient plate (`#3F6EF5` → `#1A39A6`), finer signature strokes than the 16 px tray version. One
generator, `scripts/make-app-icons.py`, writes every platform from the constants at its top (masters in
`design/app-icon/`): iOS 1024 px full bleed and opaque, macOS 16…1024 px on Apple's grid (824 px body + shadow),
Android adaptive icon (gradient background vector + foreground/monochrome PNGs inside the 66 dp safe circle) and the
512 px Play listing icon, Windows `app.svg` → `AppIcon.ico` + MSIX tiles, GNOME 128 px SVG (112 px body).

**Name (UX-12, D-07 decided).** The public product name is **eSemnBun** (exactly this casing) on every platform: app and
window titles, menu-bar/tray tooltips, About, installers, package and file names. The CLI command is `esemnbun`.
The codename `MoldSign` stays in code (modules, namespaces, bundle/application IDs `md.moldsign.*`, storage paths,
keychain/credential service names, `MSIGN_PIN`). Vendor references stay "MoldSign" (the STISC suite, the bridge
protocol, `/Reason(MoldSign Signature)` in PDFs, "Porturi ocupate de MoldSign (Java)").

### 0.3 Native guidelines per platform

| | Do | Avoid |
|---|---|---|
| macOS (HIG) | `MenuBarExtra(.window)`, sidebar `NavigationSplitView`, `Form(.grouped)`, `.borderedProminent` default action, toolbar items, SF Symbols, materials (`.regularMaterial`), Settings scene | custom-drawn buttons, colored menu-bar glyphs (only the dot is colored) |
| iOS (HIG) | `NavigationStack` large titles, `List(.insetGrouped)`, bottom prominent action, sheets with detents, Dynamic Type, haptics | dense desktop layouts |
| Android (Material 3) | dynamic color, `TopAppBar` + `NavigationBar`, `ExtendedFloatingActionButton` for Sign, carousel, `ModalBottomSheet` for PIN, edge-to-edge | iOS-style chevrons, custom toggles |
| Windows (Fluent 2) | `NavigationView`, Mica, `InfoBar` for status/errors, accent `Button` style, `TeachingTip` for first run, tray flyout with acrylic | custom title bars without Snap support |
| GNOME (HIG) | `AdwApplicationWindow`, `AdwHeaderBar` + `AdwViewSwitcher`, `AdwStatusPage` empty states, `AdwPreferencesDialog`, `AdwToast`, suggested-action pill, background portal | tray icons, custom chrome |

## 1. Principles

1. **Status first.** The top of every surface answers "can I sign right now?" (reader, card, holder).
2. **Drop to act.** Files dropped on the window or the Dock icon start the flow (not on the menu-bar popover or tray flyout: they close when a drag starts elsewhere). The format is chosen automatically.
3. **One primary button.** It's filled and in the brand color. Everything else is plain or secondary.
4. **Explain consent.** Signing always shows *what*, *for whom*, *with which certificate*, and a biometric confirm.
5. **Calm errors.** Say what happened and what to do next, plus one recovery action. Never show raw status words. The SW goes in the technical details.
6. **Platform-native.** Same structure, native controls: SwiftUI materials on Apple, Material 3 on Android, Fluent / Mica on Windows.

## 2. Tokens

Colors are semantic. Each platform maps them onto its own system palette where one exists.

| Token | Light | Dark | Use |
|---|---|---|---|
| `brand` | `#2350D8` | `#7C9BFF` | primary buttons, selection, links |
| `brandSoft` | `#E8EEFF` | `#1C2547` | drop-zone fill on hover, selected rows |
| `accent` | `#F5B700` | `#FFCD3C` | card-chip illustration, small highlights only (flag yellow) |
| `success` | `#15803D` | `#4ADE80` | valid signature, done steps |
| `warning` | `#B45309` | `#FBBF24` | indeterminate validation, low PIN attempts |
| `danger` | `#C62828` | `#F87171` | invalid signature, blocked PIN, destructive |
| `onBrand` | `#FFFFFF` | `#0B1230` | text/icons on `brand` fills (white on `#7C9BFF` is only 2.6:1) |
| `successSoft` / `warningSoft` / `dangerSoft` | `#EDF7F0` / `#FEF5E7` / `#FDECEC` | `#12291B` / `#2E2410` / `#331616` | status fills; status text on them stays ≥ 4.5:1 |
| `surface` | system window bg | system window bg | |
| `surfaceRaised` | `#FFFFFF` | `#1E1F24` | cards, sheets (or platform material) |
| `textPrimary` / `textSecondary` | system label / secondary label | | |

Contrast notes from the mock-up review (F-15): `warning` text reaches 4.5:1 only on raised (white) surfaces or
its soft fill, so never put it on the grey window background. Light-mode secondary text is `#5F636B` (6:1)
where the platform grey is too light. `accent` (1.8:1 on white) is decoration only, never text.

Android: dynamic color (Material You) on Android 12+, falling back to a scheme generated from `brand`.
Windows: the system accent color for selection, `brand` for the primary button. Mica backdrop.

| Token | Value |
|---|---|
| Spacing scale | 4, 8, 12, 16, 20, 24, 32 |
| Radius | control 8 (Win) / 10 (Apple) / 12 (M3 small); card 14; sheet 18 |
| Popover / flyout width | 360 pt (macOS), 360 epx (Windows) |
| Main window | min 860 × 580 |
| Type | SF Pro / Roboto (or the system font) / Segoe UI Variable. Title 22 semibold, headline 15 semibold, body 13 (mac) / 17 (iOS) / 14 (Win), caption 11–12 |
| Icons | SF Symbols / Material Symbols Rounded / Fluent System Icons |
| Motion | 200–250 ms ease-out; card slides in on insert; check-mark draws on success. All motion off with Reduce Motion |

## 3. Core components

| Component | Description |
|---|---|
| **StatusCard** | Card-art thumbnail (yellow chip on a blue card) + holder name + status line + validity. States: `noReader` (outline card, "Conectează cititorul"), `empty` ("Introdu cardul"), `reading` (shimmer), `ready` (name + "Card pregătit" + green dot), `busy` (progress), `error` (danger icon + one-line fix) |
| **DropZone** | Dashed 1.5 pt border, radius 14, icon + "Trage documentele aici" + format hint + an "Alege fișiere…" button inside. Large (~170–190 pt) while the list is empty, one compact line under the list once files are added. Drag-over: `brandSoft` fill, solid `brand` border. Window only, never in the popover/flyout |
| **FileRow** | Doc icon, name (middle-truncated), size, **format chip** (`PAdES-T`, `XAdES-T`…) and a remove button |
| **FormatChip** | Per-file format menu. PDF: PAdES-T (default, inside the PDF) or XAdES-BES/T/C (detached `.xml`); other files: XAdES-BES/T/C |
| **StepProgress** | Horizontal steps on desktop, vertical on phones: Card → PIN → Semnătură → Marcă temporală → Salvare. Each step is pending, active (spinner) or done (check) |
| **PinField** | 4–8 boxed secure digits, numeric keyboard on mobile, paste disabled. Under it: remaining-attempts line (`warning` at ≤ 2) |
| **ConsentSheet** | Requester (origin or "Tu"), document row(s), certificate row, "Ai încredere în site 10 minute" checkbox, buttons **Refuză** / **Semnează** (with the biometric glyph) |
| **VerdictBadge** | Large icon + title: ✓ *Semnătură validă* (success), ✕ *Semnătură invalidă* (danger), ! *Nu poate fi confirmată* (warning) |
| **SignatureCard** | Signer name, signing time, TSA time, level; check chips for Integritate / Semnătură / Lanț de încredere; "Detalii tehnice" disclosure |
| **ActivityRow** | Status icon, file name, action ("Semnat" / "Verificat" / "Cerere msign.gov.md"), relative time, reveal action |
| **ConnectionGuide** (mobile) | Three adapter tiles: USB-C → USB-A (iPhone 15+, iPad, Android) · Lightning → USB 3 Camera Adapter (iPhone ≤ 14, power recommended) · direct USB-A (computers) |

## 4. Screens

### 4.1 macOS menu-bar popover (MAC-01) / Windows tray flyout

Menu-bar / tray glyph: monochrome `signature` glyph with the two-state dot (§0.2b UX-11: green = card inserted,
gray = none). No drop target on the popover/flyout: it closes as soon as Finder/Explorer takes focus, so a drag can
never reach it. Files go to the main window or the Dock icon. Every action (Semnează…/Verifică…, Settings, open
window, a recent document) closes the popover/flyout first. While the main window or Settings is open the macOS app
is a regular app (Dock icon, Cmd-Tab); with only the menu-bar item it is an agent again.

```
┌──────────────────────────────────────────┐
│  eSemnBun                             ⚙︎  │
│ ╭──────────────────────────────────────╮ │
│ │ REPUBLICA MOLDOVA ⛉ CARTE DE IDENT. ▦│ │  CardSelector (§0.2b): the card
│ │ ┌───┐ Numele/Surname                 │ │  is the status and the switcher
│ │ │ ◯ │ POPESCU                        │ │
│ │ │╱ ╲│ Prenumele/Given name(s)  ION   │ │
│ │ └───┘ ● Pregătit pentru semnare [1/2]│ │
│ ╰──────────────────────────────────────╯ │
│  [ Semnează… ]        [ Verifică… ]      │
│  Documente recente             Golește   │  files that still exist, no timestamps;
│  ✓ contract-semnat.pdf                   │  click = reveal in Finder/Explorer;
│  ✓ factura-semnat.xml                    │  "Golește" hides them, Activity keeps its log
│ ──────────────────────────────────────── │
│  ● Conexiune browser activă         ⏻   │  switch on the trailing edge
│ ──────────────────────────────────────── │
│  Deschide eSemnBun                       │  one menu-style row each
│  Ieșire                             ⌘Q   │
└──────────────────────────────────────────┘
```

### 4.2 macOS / Windows main window (MAC-03, MAC-06, WIN-04)

Sidebar: **Semnează**, **Verifică**, **Activitate**, **Card**. Settings via ⌘, (mac) or the gear (Win).

*Semnează*: title, DropZone (collapses to a compact bar once files exist), FileRows with
auto FormatChips, disclosure **Opțiuni avansate** (format per type: PDF → PAdES-T;
others → XAdES-BES/T/C; tip Detașat/Încorporat; algorithm SHA-256 shown read-only;
output: "Lângă original" / "Alege dosar…"). Footer: StatusCard (compact) on the left,
primary **Semnează 3 documente** (⌘↩) on the right.

*Verifică*: DropZone → VerdictBadge + SignatureCards. Actions: **Contrasemnează** (counter-sign),
**Arată în Finder**. For a detached `.xml` signature, ask for the signed file(s) with an inline picker row.

*Card*: large card art, holder, issuer (MDQSign), validity, serial, reader name. Toggles: **Ține minte
PIN-ul** (Touch ID / Windows Hello) and **Șterge PIN-ul salvat**. Card troubleshooting tips.

*Settings*: General (Pornește la autentificare, Limba: Română / Русский / English),
Semnare (default formats, output policy), Conexiune browser (on/off, port status, allowed sites list,
"site-uri de încredere temporar"), Avansat (diagnostics export, reset).

### 4.3 PIN and consent sheets (MAC-04, MAC-07)

```
┌──────────────────────────────────┐   ┌──────────────────────────────────────┐
│          🔒  PIN QSCD            │   │  🌐 msign.gov.md                      │
│   pentru ION POPESCU             │   │  solicită o semnătură                 │
│  ┌─┐┌─┐┌─┐┌─┐┌─┐┌─┐┌─┐┌─┐        │   │  📄 contract.pdf · 245 KB · PAdES-T   │
│  │•││•││•││•││ ││ ││ ││ │        │   │  🪪 ION POPESCU — MDQSign             │
│  └─┘└─┘└─┘└─┘└─┘└─┘└─┘└─┘        │   │  ☐ Ai încredere în site 10 minute     │
│  ☑ Ține minte (Touch ID)         │   │                                      │
│  ⚠ Încercări rămase: 2           │   │      [ Refuză ]  [ Semnează  ⌁ ]      │
│      [ Anulează ] [ Semnează ]   │   └──────────────────────────────────────┘
└──────────────────────────────────┘
```

With a stored PIN, the consent sheet's **Semnează** goes straight to Touch ID. Without one, it opens
the PIN sheet. On wrong PIN the stored PIN is deleted and the sheet shows the remaining attempts.

### 4.4 iOS (IOS-03…06)

Tab bar: **Semnează · Verifică · Browser · Card**. A *connection banner* sits at the top of Semnează /
Verifică and follows the StatusCard states. In the `noReader` state, tapping it opens the
ConnectionGuide sheet with the adapter tiles.

*Semnează*: big **Alege document** button (Files), then the document preview (QuickLook thumbnail),
an automatic FormatChip, and **Semnează cu Face ID**. Ends with a success screen offering
**Partajează** / **Salvează în Fișiere**.
*Browser*: in-app WKWebView opened on `msign.gov.md` with a slim bridge-status pill
("Conexiune MoldSign activă") above the web content.

### 4.5 Android (AND-*)

Material 3 with bottom NavigationBar (same four destinations), a top app bar with the reader status
chip, and a FAB **Semnează** on the Semnează screen. The ongoing notification reads
"MoldSign · conexiune browser activă" with a **Oprește** action. A signing request from Chrome arrives as a
heads-up notification **Semnează contract.pdf pentru msign.gov.md?** and tapping it opens the ConsentSheet.
USB permission explainer: "Permite accesul la cititor" before the system dialog.

### 4.6 Windows (WIN-04)

The tray flyout mirrors 4.1 with Fluent styling (Acrylic flyout, Segoe Fluent Icons). The main window
uses NavigationView (left) and Mica. Toasts on reader connect/disconnect (can be turned off) and on
completed bridge requests.

### 4.7 First run (all platforms)

Three steps, skippable: **1** Conectează cititorul (live detection) → **2** Introdu cardul (holder name appears)
→ **3** Preferințe: Ține minte PIN-ul · Conexiune browser · Pornește la autentificare (desktop).

## 5. Copy (ro → en reference)

| Key | Română | English |
|---|---|---|
| status.noReader | Conectează cititorul | Connect the reader |
| status.empty | Introdu cardul în cititor | Insert the card |
| status.ready | Card pregătit | Card ready |
| drop.title | Trage documentele aici | Drop documents here |
| drop.subtitle | sau alege fișiere | or choose files |
| action.sign | Semnează | Sign |
| action.verify | Verifică | Verify |
| action.countersign | Contrasemnează | Counter-sign |
| pin.title | PIN QSCD | QSCD PIN |
| pin.remember | Ține minte PIN-ul | Remember PIN |
| pin.attempts | Încercări rămase: %d | Attempts left: %d |
| consent.title | %@ solicită o semnătură | %@ requests a signature |
| consent.trust | Ai încredere în site 10 minute | Trust this site for 10 minutes |
| verdict.valid | Semnătură validă | Valid signature |
| verdict.invalid | Semnătură invalidă | Invalid signature |
| verdict.unknown | Nu poate fi confirmată | Cannot be confirmed |
| bridge.on | Conexiune browser activă | Browser connection on |
| error.cardStuck | Scoate și reintrodu cardul | Remove and re-insert the card |
| error.pinBlocked | PIN blocat. Deblochează-l la CEV | PIN blocked. Unblock it at CEV |

Russian (`ru`) ships in MAC-16 / equivalents.

## 6. Accessibility

Full keyboard paths (⌘O open, ⌘↩ sign, ⌘⇧V verify; Esc cancels sheets), VoiceOver/TalkBack/Narrator
labels on every icon-only control, Dynamic Type / font scaling up to XXL without truncating primary
actions, WCAG AA contrast (tokens above pass on both themes), and no information carried by color alone
(icons accompany every status color).

### Native iOS action styling

Use `NativeButtonStyle` for standalone actions. On iOS 26 and later it delegates to SwiftUI's
[`glass`](https://developer.apple.com/documentation/swiftui/primitivebuttonstyle/glass) or
[`glassProminent`](https://developer.apple.com/documentation/swiftui/primitivebuttonstyle/glassprominent)
style; older iOS and macOS retain the specified native fallback. Do not paint another fill or border
behind the button, or switch styles when disabling it. The system owns disabled/pressed appearance.
Toolbar, alert and menu-item styling is supplied by their native context; content rows remain full-row
interactions rather than floating action surfaces.

Use `nativeButtonIconFrame` inside icon-only action labels. Glass supplies native padding; the
fallback keeps an explicit 44-point target for older borderless controls. The share extension uses
UIKit's [`prominentGlass()`](https://developer.apple.com/documentation/UIKit/UIButton/Configuration-swift.struct/prominentGlass%28%29)
configuration on supported versions.

The iOS Sign action sits at the trailing bottom safe area, above tab navigation. Reserve its space
with a safe-area inset so documents remain scrollable and unobscured. Keep a single action in all
window widths and orientations, with a capsule shape and a 44-point minimum touch target.

On macOS, use the native prominent capsule at large control size, with a minimum 120-point label
width and 44-point control height. Reserve 24-point side and 16-point bottom gutters. Keep ⌘Return,
the document count and the existing readiness rules. Hide the action only when the queue is empty;
keep the same native style while disabled. Scrolling and window resizing must preserve its placement.
