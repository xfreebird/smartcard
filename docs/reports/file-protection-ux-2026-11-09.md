# File protection UX revision

The form now separates file selection from access requirements. Users choose Encrypt or Decrypt, select their file, then choose Password or Certificate / card. Only the chosen method's inputs appear. A short instruction describes the next step; What do I need? expands the acquisition and compatibility guidance.

| Platform | Native components and layout |
| --- | --- |
| macOS, iPhone, iPad | Grouped SwiftUI Form sections, pickers, secure fields, DisclosureGroup, native file import/export |
| Android phone/tablet/foldable | Material single-choice segmented controls, outlined password fields with mismatch feedback, expandable help, scrolling form and fixed action footer with keyboard insets, system document pickers |
| Windows | ContentDialog primary action, ComboBox headers, PasswordBox, Expander and system pickers |
| Linux | GTK linked controls, password entries, expanders, Adwaita dialog/header/action footer and native file dialogs |

Certificate recipient names remain visible. Longer fingerprints and public-certificate export are secondary details. PIN entry appears only after selecting a card identity. Export still works without selecting a document or entering a PIN.

Guidance covers creating and sharing a password separately, obtaining the password from the sender, requesting a recipient's public encryption certificate, exporting one's own certificate, and using the matching physical card, reader and PIN to decrypt. Signing-only certificates and the legacy format's integrity limits are explained in help. Desktop removal warnings and confirmation remain visible.

All new text is localized in Romanian, English and Russian. Cryptographic processing and CLI behavior are unchanged.

## Verification

Passed: Swift frontend syntax parsing for Apple/Linux views, localization export consistency, whitespace checks, and static review of action gating and conditional fields.

Not run: native builds, interactive device/accessibility checks or screenshot refresh. The standing repository instruction reserves builds/tests for the owner. Earlier screenshots predate this revision.

Suggested validation batch: on each native app exercise password encrypt/decrypt, certificate import, card discovery with one/multiple/no identities, export without a selected document, PIN visibility, mismatch feedback, save cancellation/retry, help expansion, and desktop removal confirmation. Check narrow landscape layouts, large text, keyboard visibility and all three languages. Use simulated identities for routine checks; physical card operations remain separately unverified.

## Screenshot refresh

The owner subsequently requested rebuilt screenshots and upload to Google Drive. Debug builds passed on macOS, iOS simulator, Android, Fedora GNOME and Windows WinUI (Windows: zero warnings/errors). Capture review exposed a partly clipped Apple primary action; moved it to a bottom safe-area inset outside the scrolling Form and rebuilt. macOS secure fields retain native rounded borders with duplicate labels hidden.

Captures use fictional filenames/cards, isolated screenshot mode and no demo banner. This is visual evidence, not physical-card encryption/decryption verification. The v2 set covers password encryption, certificate encryption, password decryption and desktop removal in light/dark themes on macOS, Windows, Linux, iPhone, iPad, iPhone Duo, Android tablet/foldable and a phone-sized Android display. CLI behavior is unchanged.

Delivered 54 individual PNG files in eight platform/device folders to xfreebird@gmail.com: [UI v2 - 2026-11-09](https://drive.google.com/drive/u/0/folders/1DUgpL_zEnuWyPUakXwfcs8GCnUcTGnwz). Google Drive confirmed all 62 upload items (54 files and eight folders) completed.
