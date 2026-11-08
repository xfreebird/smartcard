# Embedded MCP and the Mac App Store sandbox — 7 November 2026

MCP is not intrinsically excluded from an App Store app. Apple explicitly documents embedding command-line helper tools in sandboxed apps. The current eSemnBun MCP executable, however, is designed for an external client to launch over stdio with configured filesystem roots and an optional external credential command. Copying that executable into the App Store bundle would not make those operations inherit the app's permissions or provide a working sandboxed approval broker. This delivery therefore provides the CLI fallback and bundles it with the standalone macOS app; it does not advertise embedded App Store MCP as implemented.

## Supported Apple model

Apple's [embedded helper guide](https://developer.apple.com/documentation/xcode/embedding-a-helper-tool-in-a-sandboxed-app) describes a tool launched by its containing sandboxed app. The helper is signed with the sandbox and inheritance entitlements; the guide disables injected base entitlements to avoid incompatible `get-task-allow`, sets Skip Install, and signs nested code before its enclosing application.

Apple's [sandbox inheritance reference](https://developer.apple.com/library/archive/documentation/Miscellaneous/Reference/EntitlementKeyReference/Chapters/EnablingAppSandbox.html) distinguishes static entitlement inheritance from dynamically obtained file access. For files selected after launch, the app must explicitly pass bytes or an appropriate bookmark to the helper. A path string is not a file-access grant. The main application must not itself use the inheritance entitlement.

Apple also documents [file access and bookmark resolution](https://developer.apple.com/documentation/security/accessing-files-from-the-macos-app-sandbox). These mechanisms support a future app-owned MCP workflow; they do not justify removing the sandbox or granting arbitrary filesystem access.

## Concrete gaps in this implementation

- The external MCP client starts the executable directly and owns stdin/stdout. That is a different process topology from a helper launched by eSemnBun. An inherited helper cannot be assumed to inherit permissions from a containing app that did not launch it.
- `TrustedRoot` validates filesystem boundaries using descriptor-relative operations, but configured root paths are administrator/user configuration, not sandbox grants. The App Store target only has user-selected read/write access, not arbitrary-root access.
- The optional unattended credential provider launches a configured external executable. It is unsuitable as an assumed App Store helper capability; external binaries and credential paths need their own sandbox-compatible design and explicit user authorization.
- The current desktop approval broker is excluded from `APP_STORE`. Its filesystem spool and local-client activation are standalone implementation choices; the App Store target has no equivalent paired transport and sandbox-managed import/export flow.

A supported future implementation could keep the Mac App Store app as the transport/authorization owner: pair local clients, let the user select files or workspace roots through the app, persist only appropriate security-scoped access, pass bounded document bytes or bookmarks into an app-launched sandbox/inherit helper, and return approved output bytes through the same paired connection. The existing immutable PDF approval gate could remain the signing boundary. A separately distributed stdio shim could proxy to this app-owned endpoint. This requires an actual transport, access lifecycle, authentication and runtime validation change, not only packaging or entitlements.

## Standalone packaging review

Embedding the helper under `Contents/Helpers`, signing it first, and resealing the app while preserving its existing identifier, requirements, flags and entitlements follows Apple's [inside-out code-signing guidance](https://developer.apple.com/library/archive/technotes/tn2206/). In particular, do not replace the app's smartcard or provisioned iCloud entitlement values with the helper's entitlements, and do not use `codesign --deep --force` as a signing shortcut.

The distribution boundary validator performs recursive strict verification. Release validation must additionally prove the helper is present, universal and signed, that app entitlements survive resealing, and that notarization accepts the complete output. None of this assessment constitutes App Store review approval or an entitlement/security exception. No store upload or publication was performed.

Packaging now captures and compares the actual app entitlements before/after resealing, verifies the nested helper signature and both CPU architectures, requests timestamps only for a real signing identity, and submits an isolated notarization ZIP containing both CLI executables. Shell syntax and whitespace checks passed. No signed package build, notarization submission, App Store helper runtime test or store review was performed in this assessment.
