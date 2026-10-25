# 10 — Design System and Screens

Visual mock-ups of every screen below (all platforms, light/dark): **[eSemn UI concepts](https://claude.ai/artifact/5LZRjfVTDrQ9TKnscfWTyi)**
(private artifact; "eSemn" is a placeholder product name, see D-07).

Replaces the vendor suite's tabbed Swing window (four big icon tabs, file tables, empty
fieldsets, three dropdowns before the first click) with a **status-first, drop-first** design:
the app tells you what state the card is in and takes documents with one gesture.

Plan items: F-11, F-15, MAC-01…10, IOS-03…06, AND-*, WIN-04.

## 1. Principles

1. **Status first.** The top of every surface answers "can I sign right now?" (reader, card, holder).
2. **Drop to act.** Files dropped on the menu-bar popover, the window, the Dock icon or the tray flyout start the flow. The format is chosen automatically.
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
| **DropZone** | Dashed 1.5 pt border, radius 14, icon + "Trage documentele aici" + secondary "sau alege fișiere". Hover/drag-over: `brandSoft` fill, solid `brand` border |
| **FileRow** | Doc icon, name (middle-truncated), size, **format chip** (`PAdES-T`, `XAdES-T`…) and a remove button |
| **FormatChip** | Small capsule. Tapping it opens the per-file format menu |
| **StepProgress** | Horizontal steps on desktop, vertical on phones: Card → PIN → Semnătură → Marcă temporală → Salvare. Each step is pending, active (spinner) or done (check) |
| **PinField** | 4–8 boxed secure digits, numeric keyboard on mobile, paste disabled. Under it: remaining-attempts line (`warning` at ≤ 2) |
| **ConsentSheet** | Requester (origin or "Tu"), document row(s), certificate row, "Ai încredere în site 10 minute" checkbox, buttons **Refuză** / **Semnează** (with the biometric glyph) |
| **VerdictBadge** | Large icon + title: ✓ *Semnătură validă* (success), ✕ *Semnătură invalidă* (danger), ! *Nu poate fi confirmată* (warning) |
| **SignatureCard** | Signer name, signing time, TSA time, level; check chips for Integritate / Semnătură / Lanț de încredere; "Detalii tehnice" disclosure |
| **ActivityRow** | Status icon, file name, action ("Semnat" / "Verificat" / "Cerere msign.gov.md"), relative time, reveal action |
| **ConnectionGuide** (mobile) | Three adapter tiles: USB-C → USB-A (iPhone 15+, iPad, Android) · Lightning → USB 3 Camera Adapter (iPhone ≤ 14, power recommended) · direct USB-A (computers) |

## 4. Screens

### 4.1 macOS menu-bar popover (MAC-01)

Menu-bar icon: SF Symbol `signature`, template-rendered. It's dimmed with no reader, at full strength
when a card is ready, shows the `ellipsis` pulse while busy and `exclamationmark.triangle` on error.
Files can be dropped on the icon.

```
┌──────────────────────────────────────────┐
│  MoldSign                         ⚙︎  ⋯   │
│ ┌──────────────────────────────────────┐ │
│ │ ▣  ION POPESCU                       │ │  StatusCard
│ │    ● Card pregătit · miniLector EVO  │ │
│ │    Certificat valabil până 03.2030   │ │
│ └──────────────────────────────────────┘ │
│ ┌ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ┐ │
│        ⤓  Trage documentele aici         │  DropZone (drop = sign)
│      PDF → PAdES · altele → XAdES        │
│ └ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ┘ │
│  [ Semnează… ]        [ Verifică… ]      │
│  RECENTE                                 │
│  ✓ contract-semnat.pdf          acum 2m  │
│  ✓ msign.gov.md · cerere.pdf      10:12  │
│ ──────────────────────────────────────── │
│  🌐 Conexiune browser         ● activă ⏻ │
│  Deschide fereastra            Ieșire    │
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
