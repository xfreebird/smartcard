# MoldSign desktop client compatibility

The full desktop distribution can act as the signing server for the official MoldSign desktop client. Enable the desktop-client option in eSemnBun's browser/server settings, close the official **server** in its tray menu, keep eSemnBun's server enabled, and open the official desktop client. Store distributions do not offer this filesystem-based integration.

This option is separate from website access. Government websites continue to use the existing origin allow-list. The official desktop client only sends `moldSign: DesktopSuiteClient` for certificate enumeration; its connection check, signing requests and result polls omit that header. Compatibility accepts those exact legacy routes only when explicitly enabled, the host permits filesystem routes, a consent callback exists, and both Origin and browser fetch metadata are absent. A supplied untrusted Origin, including `null`, is still refused. Each signing operation requires eSemnBun authorization; explicit batch sessions reuse the approved credential in memory with the existing expiry and card matching checks.

Supported signing workflow:

- Connection check: `GET /hello`.
- Card enumeration: `GET /certificates?private_only=true` with the vendor header.
- Certificate refresh: `POST /certificates/refresh`.
- PDF: JSON `POST /sign/pdf`, native result poll and JSON output path.
- XAdES: JSON or XML `POST /sign/file`, native result poll and result container.
- Batch signing: `use_pin_session` on later requests and `keep_pin_session=1` on the first result poll.

Async result URLs use the actual listener's HTTP or HTTPS scheme and configured port, with the fixed loopback hostname. Caller-controlled Host headers cannot redirect result URLs elsewhere.

Validation: the simulated CosmoX card exercises real IAS/ECC secure messaging and RSA signatures. The installed, unmodified vendor Java `CertificatesClient` and `SignFileClient` successfully deserialize certificates, refresh, send JSON signing requests, poll the returned HTTP URL, and deserialize the output model. The resulting XAdES validates cryptographically. Tests also check opt-in behavior, denial without PIN verification, browser-origin rejection, store/CLI restrictions, and batch consent reuse. Both Apple Network.framework and portable POSIX/OpenSSL listener implementations pass the bridge suite.

No physical-card signing or vendor desktop GUI automation was performed for this change. Encryption, decryption, secure deletion, signature removal and signature-information management are not implemented by this compatibility option; it covers the signing workflow. The Java integration test skips when the vendor client jars are absent.

Windows validation: the ARM64 WinUI application builds without warnings/errors, and all 197 Core tests pass in the Windows VM on the MacBook Air, including injected native filesystem-signing and authorization tests. Windows native filesystem verification remains disabled until it has a consent-only workflow; existing-signature XAdES countersigning is rejected explicitly. Windows vendor GUI/physical-card interoperability was not exercised.

Linux validation: the Fedora GTK application and 13 tests pass. A fresh isolated app instance recovered both bridge ports automatically after disposable test listeners exited and served the certificate endpoint successfully. No physical reader or PIN was used for this validation.
