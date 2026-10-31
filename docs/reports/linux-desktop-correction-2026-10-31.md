# Linux desktop correction — 2026-10-31

The GNOME app now presents its main window on a fresh profile, including when first started with
`--background`. It records first presentation only after GTK maps the window. Later background launches
may remain hidden when background features are available; explicit activation always presents the window.

## Implementation

The source is grouped into `Application`, `Domain`, `Infrastructure`, and `Presentation`. The application
controller coordinates screen state and dialogs through focused services:

- `ReaderSession`: reader generations, card selection, stale certificate-read rejection.
- `BatchSigningService` / `DocumentSigning`: a frozen reader/certificate/PIN per batch, first-error stop,
  and at most one vault-save attempt after a successful signature.
- `DocumentVerifying`: validation and detached-document loading.
- `SettingsCoordinator` / `SettingsStoring`: preference invariants and persistence.
- `ActivationPolicy` / `LaunchStateStoring`: first presentation and subsequent startup decisions.
- `BridgeHosting`: HTTPS listener lifecycle and worker/main-loop callbacks.

Application ports use domain values for settings, reader snapshots, and PIN lookup results rather than
concrete adapter types. PC/SC, libsecret, JSON storage, GTK, and portal implementations remain in Infrastructure.

User-facing text uses generated `L10n.Key` values, including dynamic, accessibility, consent, and error
messages. Views render finished strings and never use display text as a lookup key. Certificate dates follow
the selected language. Historical activity descriptions retain the language used when the event was recorded.

The portrait is a compact circular head with broad shallow shoulders inside the 3:5 frame. The chip has
exactly eight contact regions: three on each side and two in the center. The PIN field is larger and centered;
the native alert controls its own sizing so it works on libadwaita 1.5 as well as newer versions.

## Validation

| Check | Ubuntu 24.04.5 ARM64 | Fedora 44 ARM64 |
|---|---|---|
| Native debug build | Passed, Swift 6.2.4 | Passed, Swift 6.4.1 |
| Application tests | 9 passed, 0 failures | 9 passed, 0 failures |
| GTK/libadwaita | 4.14.5 / 1.5.0 | 4.22.5 / 1.9.4 |
| Fresh `--background` launch | Window mapped, launch state persisted | Window mapped, launch state persisted |
| Subsequent `--background` launch | Hidden, HTTPS responding | Hidden, HTTPS responding |
| Explicit activation | Window presented | Window presented |
| Bundled HTTPS identity | System CA and hostname verification passed | System CA and hostname verification passed |
| Release package | Static Swift release built, both .deb packages reinstalled; dpkg audit clean | Not repackaged this round |

Tests cover startup persistence (including missing/corrupt state), explicit activation, settings invariants,
frozen batch identity, wrong-PIN stop/delete without retry, a single failed vault-save attempt per batch,
numbered substitution preserving user data, and language-aware certificate dates. No test accesses a real PIN.
`python3 scripts/localize.py --check`, shell syntax checks, and `git diff --check` pass.

## Final screenshot scope

The final dated folders each contain **31 images** captured from the final source: 28 fictional UI states
plus three native startup transitions. This is a scoped correction set, not a new exhaustive state matrix.

- RO/EN/RU × light/dark: multi-card wallet, selected-card details, PIN (18).
- English × light/dark: preferences, PIN error, signing progress, mock result, invalid verification (10).
- Native: first background launch, subsequent background launch, explicit activation (3).

Locations on the main Mac:

- `/Users/nghimbovschi/Desktop/esemnbun-screenshots/linux/2026-10-31/ubuntu24.04`
- `/Users/nghimbovschi/Desktop/esemnbun-screenshots/linux/2026-10-31/fedora44`

Each folder includes an evidence directory with source/binary hashes, logs, and readiness-marker archives.
Intermediate captures were moved outside the delivered dated folder; no final image uses the earlier chip.
The 2026-10-30 evidence remains historical. Capture/launch scripts are in `linux/scripts/`.

## Boundaries

No physical reader, real PIN, signing operation, live PKI network suite, or portal signing was exercised.
The real native bridge returned an empty certificate list, as expected without a reader. Mock verification
and result screens are visibly identified as demonstrations.

**Flatpak permission approval was not tested.** These checks ran unsandboxed GNOME applications; they do
not establish that the Flatpak Background portal approval flow works. The existing unsandboxed portal
`SetStatus` denial remains logged, while status is available in the window.

Fedora's display scale is restored to its original 200% after capture. Both Linux guests are shut down after
evidence collection; the Windows VM and hardware ownership are unchanged by this work.

## Final artifacts

Packages on the main Mac: `dist/linux/ubuntu24.04-arm64/`.

| Artifact | SHA-256 |
|---|---|
| Ubuntu GUI .deb | `979983e79cc59e8cae11d4f2a02d0bf57ab5719c9d9cccbbf2bc7c5955153a4b` |
| Ubuntu CLI .deb | `b8e83a658a2c5e97ed53807b316b27f6f3f2c6e6331069b20a0b2c4bc38b0a17` |
| Installed Ubuntu release GUI | `877f2623d66f36743bb349782ca5529197e1f5a779441349b6574a044839a951` |
| Ubuntu debug GUI | `470dc83e1115c4524b359cf3e384e281433555eaf59f8fe71df5f82bc8c1913b` |
| Fedora debug GUI | `3f28189f9af8753d227832ba46b8561b7e20ac4902e19b54397b1c6c6cbb187e` |

The source-input manifests in both guests match the main working tree for Linux sources/tests/manifests,
shared core sources/tests/manifests, and `spec`. Each final folder's `manifest.json` associates every image
with its binary hash and the common source manifest. The CLI user service remains disabled after installation.

## Final wording correction

The saved-PIN explanation now says that confirmation happens once for the entire document batch in RO, EN,
and RU, using the semantic key `ui_pin_confirmation_scope_help`. This replaces the contradictory
“before each signature” explanation. The generated table and its one CardPage callsite are the only product
changes in this final pass. Both native builds, the Ubuntu release/package/install check, all 31 screenshots
per distro, and the three native startup transitions were refreshed after this correction.

The nine application-policy tests passed before this text-only correction and were not rerun in the final
pass; their implementation is unchanged. Their retained log is explicitly named
`policy-tests-before-copy-change.log`. Current screenshot and artifact hashes above reflect the corrected text.
