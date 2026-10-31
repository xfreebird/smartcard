# Linux signing batch audit — 2026-10-30

The GNOME document-signing flow obtains one PIN/consent decision for the entire selected batch.
`AppController.signAll()` sets `isSigning` before requesting a PIN, captures the file URLs/formats,
reader and certificate, and passes that snapshot to `runSigning()`. A second start is rejected while
that decision or batch is active. The PIN prompt lists the holder and every captured filename/format.
The selected card cannot change during the batch. The core compares the expected certificate before
sending VERIFY, so a physically swapped card is rejected without receiving the previous card's PIN.

The worker reuses its local PIN argument across the frozen file list. There is no controller property
holding a session PIN. Cancelled prompts do not schedule the worker; success/failure clears busy/progress
state. The worker's PIN references end with that queued work. This is reference lifetime management,
not a claim that Swift String storage is securely zeroed. A later batch always requests a fresh PIN or
fresh consent for an explicitly saved PIN; no silent in-memory reuse crosses batch boundaries.

The first error stops the loop. Wrong/blocked PIN errors delete the saved PIN and never retry another
file. Optional saving after the card accepts the PIN is attempted once per batch, including when the
keyring rejects or cancels saving. This prevents another keyring permission prompt on each later file.
The production controller and browser bridge use `SigningService.shared`, preserving the same card
operation lock. Explicitly injected services remain available to tests.

Evidence and scope:

- Source audit: `linux/Sources/MoldSignGnome/Model/AppController.swift`, `UI/Dialogs.swift`, and
  `swift/MoldSignKit/Sources/MoldSignKit/Services/SigningService.swift`.
- Debug UI fixtures show two document rows and one batch PIN dialog, including the complete file list
  and a separate remaining-attempt warning. These fixtures never submit a PIN or call the card/keyring.
- Fedora Debug/Release and Ubuntu 24.04 container builds were run during this change. The final small
  batch guard/consent/save-once changes were rebuilt in Fedora Debug.
- No physical multi-document signing batch was performed, and no supplied personal PIN was used.
  The UI fixtures do not constitute an integration test of the production signing loop.
