# Rounded promotional screenshot sets

The campaign compositor matches the Apple palette, typography, rounded outer panel, rounded inset screenshot and rounded brand icon. It preserves the screenshot's aspect ratio and actual UI. Only the outer corners are masked; it never replaces app text, card data, controls or validation results.

`render-crossplatform-promos.py --output <pack>/promotional --android-raw <pack>/google/assets/android --windows-raw <pack>/microsoft/assets` renders 48 localized images by default: 36 Android (phone, portrait tablet and landscape tablet) and 12 Windows. `--stores android` or `--stores windows` renders only that platform. All three languages are required for selected platforms. Missing source images or wrong native sizes fail instead of silently producing incomplete artwork.

These optional campaign images are **separate** from native Microsoft Store and Google tablet submission screenshots. Keep the native files under `microsoft/assets` and `google/assets/android` for upload where store policy requires unadorned UI. The promotional canvases remain opaque rectangular RGB PNGs; their inset artwork is rounded. Each manifest records the raw image checksum and final file checksum.

## Capture automation

- `capture-windows-store-remote.py --output <pack>` stages current source on the MacBook Air's Windows VM, publishes a self-contained Debug build and captures all three languages in an interactive task. Mock startup skips the normal application instance broker, and isolated preferences prevent changing the installed app. It transfers the 12 native screenshots into `<pack>/microsoft/assets`. The VM must be running and its normal SSH keys configured; `--air`, `--guest`, `--port` and `--stage` override the defaults. No physical reader is attached by this driver.
- `capture-android-store-all.py --output <pack>` builds the current Debug APK, starts a dedicated read-only emulator on port 5562, captures all 36 native screenshots and stops only that emulator. `--sdk`, `--avd` and `--port` configure installed tooling. It refuses a busy emulator port. The underlying AVD is never saved. The existing capture fixtures never use physical card transport.

The top-level repository screenshot command coordinates these drivers with Apple capture, rendering and validation. Do not run Android capture concurrently with resource-heavy simulator capture on a memory-constrained machine.
