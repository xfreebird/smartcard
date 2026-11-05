# Document workflow changes — 2026-11-05

Implemented certificate detail disclosures for PDF/XAdES verification, readable dates, multiple document result lists, document error continuation, one error per failed signing row without retry, card display retention, dashed drop zones, and content-sized Windows tray placement.

Document errors continue under the existing batch authorization. Card, identity, PIN and cancellation failures remain terminal. Windows consent advances past documents that fail before requesting the PIN.

Validation:
- Android debug build; 117 core tests, 1 skipped, no failures. App launched in a fresh API 36 ARM64 emulator; dashed signing zone visually inspected.
- Apple app policy package: 22 tests, no failures, including continuation after a failed document.
- iOS simulator and macOS Debug builds passed. iOS signing drop-zone rounded dashed outline visually inspected after repairing native Form clipping.
- Fedora 44 VM: GNOME build passed; core suite ran 38 tests, 7 skipped, no failures.
- Windows 11 ARM64 VM: x64 WinUI build passed. Batch continuation regression and core suite rerun after correcting consent advancement.
- git diff --check passed.

Limitations: real-card batch signing, card removal during signing, full document-picker workflows, and visual tray placement have not been exercised end to end. Certificate details expose metadata; they do not add TSA path validation or revocation verification.

## Verification layout follow-up

The signed macOS development build was launched locally. Two signed PDFs produced separate document cards with filename, verdict and per-signature disclosures. Selecting one different signed PDF removed both earlier cards. Sign and Verify now use the same DropZone with identical outside spacing. iOS uses a scroll layout to keep the rounded dashed border clear of native Form clipping; a simulator screenshot confirmed all four corners. The selected card display is captured for the full local signing batch, including transitions between files. This last behavior has not been verified with another physical-card signing run.

## Successful signing rows

Successful output rows now expose one full-row action, including filename and the trailing action. macOS highlights the complete row on hover and reveals the file in Finder, with App Store export retained in the context menu. iOS uses a full-row ShareLink. Linux makes its action row activate the existing reveal button. Windows uses a stretched native button containing the filename and Show in Explorer. Android now retains all completed output URIs, including partial batches, and displays clickable result cards with an Open action. Mobile platforms use native share/open behavior.

## Author headings, certificate rendering, and macOS windows

Signature headings expose Author, signature number, personal IDNP when the subject serialNumber is 13 ASCII digits, and formatted signing time. Issuer organizationIdentifier is rendered separately as an organization identifier. Subject and issuer DNs are parsed from ASN.1 into individual Unicode fields. Apple renders Subject, Issuer and Certificate sections and full-width disclosure buttons. Unknown extensions retain their OID and raw value; recognized key usage, certificate policies, QC statements, alternative names, key identifiers and authority/revocation URLs have decoded fields.

Metadata corrections: only the leaf DER contributes to the certificate fingerprint, and URL extraction respects ASN.1 string lengths. Three new local metadata tests passed, including Unicode field extraction, issuer-versus-subject IDNP semantics, leaf-only hashing and bounded URL extraction. Fedora suite: 41 tests, 7 skipped, zero failures. Windows: 200 passed. Android build and core tests passed. Signed macOS and iOS simulator builds passed.

Live macOS checks confirmed the author/IDNP/date heading, expansion by clicking the full heading, structured fields and corrected fingerprint/URLs. About exposes Close, with Zoom disabled and minimization/resizing disabled. Selecting eSemnBun Help opened https://esemnbun.md/docs/start/ in Safari.

## Clearing results and tablet drag input

Verification has explicit clear-results actions. Apple uses a generation token and Windows uses selection/request versions so results cannot reappear from an earlier request after clearing. Linux invalidates the verification generation on reset. Android tracks/cancels verification jobs, removes the result when its document is removed, and exposes removal for earlier results as well as clearing the full batch.

Apple drop handling now accepts file URL and concrete document representations from Files, copying the contents within the NSItemProvider callback before its temporary URL expires. Sign and Verify both use this loader. Android signing also accepts external document drops with temporary URI grants held until copying completes.

Validation: 24 Apple policy tests passed, including two new tests for temporary provider file lifetimes and multiple file URL representations; Android debug/core tests passed; iOS simulator and signed macOS builds passed; Fedora and Windows app builds passed. Clear-results was exercised live on macOS with an existing signed PDF. Actual cross-app drag gestures have not been exercised. Pixel Tablet emulator emulator-5556 runs the latest Android APK and contains 24 test files under Downloads/Mac Downloads. The iPad simulator has the updated app and existing sample documents.

## iPad Safari certificate preview

An explicit Debug simulator fixture starts the real localhost HTTPS listener with two fictional, short-lived self-signed certificates named DEMO POPESCU ION and DEMO RUSU ANA. Activation requires simulator compilation, fixture mode, the no-hardware flag and an isolated QA preferences suite. The normal demo banner stays visible. Preview certificates replace the UI cards and the enumeration response; the server rejects every non-enumeration route before consent, file parsing or card access. Production defaults and normal demo mode are unchanged.

Validation: the certificate-preview endpoint test passed without enumerating readers or requesting a PIN; the updated iPad build launched; HTTPS /certificates returned both fictional identities and the MSign CORS origin without disabling TLS verification; an actual preview /sign/data request returned 403. The iPhone app was stopped to free the host-shared bridge ports. The iPad simulator is left running with its existing multitasking windows. Actual MSign portal UI identity enumeration in Safari remains for the user to check.
