# Desktop Documents implementation — 7 November 2026

## Implemented

Windows and Linux now maintain the signed-document library independently from operation history. Successful local signing adds or updates a library record, deduplicated by output path. The library is not truncated with the 100-entry history. Clearing history retains the library and does not remove files.

Existing successful signing records migrate on first load. Windows stores the separate library collection in the existing atomic JSON snapshot. Linux stores `signed-documents.json` alongside `activity.json`; it refuses history cleanup if the library cannot be persisted, so a failed migration cannot lose its source records. Records already erased by an earlier history cleanup cannot be recovered from that old log automatically.

Activating a document row opens a modal with freshly computed verification results, signer details, signing and timestamp information, checks and certificate disclosures. Both implementations reuse the corresponding Verify renderer. Inspecting a document neither adds a new history entry nor replaces files/results selected in Verify. Dismissing the modal ignores late results. Windows retains the detached-original picker and file reveal control in the modal. Linux retains a separate folder-reveal action in the list.

Linux saved-document verification now resolves detached XML references through the core's directory-descriptor containment helper, rejecting traversal and symlink escapes beneath the signature directory. Demo activity and saved-library changes remain in memory.

## Validation

Swift frontend syntax parsing passed for the six modified Linux files. Both modified Windows XAML files parsed successfully as XML. Whitespace checks passed. These are static checks; no application build, automated test or native UI run was performed in this implementation round, following the repository's owner-run build/test convention.

Native follow-up should exercise migration from an old profile, clearing history, relaunch persistence, more than 100 history events, duplicate output paths, moved/deleted/unreadable outputs, invalid/unsigned and detached XML files, closing while verification runs, and minimum-size light/dark windows. Windows Desktop and Store packages and Fedora/Flatpak should each be checked. Fresh verification does not establish revocation or timestamp-chain guarantees beyond the existing Verify implementation.
