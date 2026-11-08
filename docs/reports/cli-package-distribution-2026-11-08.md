# CLI package distribution — 2026-11-08

Released CLI package-manager support for eSemnBun 0.2.6. Public installation instructions: https://esemnbun.md/packages/.

## Delivered

- Reused https://github.com/xfreebird/homebrew-utils without modifying its existing utility formulas. Added `esemnbun-cli` for macOS 15+ on Apple silicon and Intel: `brew install xfreebird/utils/esemnbun-cli`.
- Added a Scoop bucket in the same repository for Windows x64: `scoop bucket add esemnbun https://github.com/xfreebird/homebrew-utils`, then `scoop install esemnbun/esemnbun-cli`.
- Published an embedded-executable Chocolatey package: download https://esemnbun.md/packages/downloads/v0.2.6/esemnbun-cli.0.2.6.nupkg into an empty directory, then `choco install esemnbun-cli --source . --yes`.
- Published signed APT repositories for Ubuntu 24.04+/compatible Debian 13 amd64 and signed RPM repositories for Fedora x86-64. The public package page includes key-fingerprint verification and setup commands. RPM package and repository signature checking remain enabled.
- Added an Arch Linux binary PKGBUILD and a Linux tar archive. Current Linux binaries are x86-64 and require glibc, OpenSSL, libcurl and PC/SC; not Alpine/musl builds.
- Added standalone Windows CLI ZIP generation to future release builds. The initial 0.2.6 ZIP preserves the exact executable bytes from the verified 1.2.206.0 MSIX.
- Public package downloads use the website because the source repository is private. The source repository's visibility was not changed.

## Automation and security

The package workflow runs after successful releases, weekly and on demand. It verifies source asset digests, signs APT/RPM repositories, packages Chocolatey, checks installation and refreshes all release checksums. The tap refreshes definitions every six hours and tests Homebrew, Scoop and Fedora installation from public downloads.

Website deployment validates the release archive digest and signatures against the committed public key. Incomplete releases preserve the last complete feed. Downloads for two prior packaged versions are retained for package-manager caches.

Dedicated package-key fingerprint: `F8075499A4B311BA30E53156E5622B86C8280D0B`. The private key is stored in the Actions secret and the owner's protected offline backup, not Git. APT metadata expires after 90 days; the key expires in November 2028. Installing packages does not start a broker/service, configure unattended signing or store a PIN.

## Validation

- Package workflow passed: https://github.com/xfreebird/smartcard/actions/runs/42454456478 — APT installation and CLI execution, RPM signature checks, Chocolatey pack/install/help/uninstall.
- Public installation workflow passed: https://github.com/xfreebird/homebrew-utils/actions/runs/42454901480 — Homebrew install/test, Scoop install/help/uninstall, Fedora DNF signed installation/CLI execution/removal.
- Website build and deployment passed: https://github.com/xfreebird/smartcard/actions/runs/42454724394.
- Anonymous downloads of the macOS archive, Windows ZIP, Linux archive, Chocolatey package and package definitions matched their release SHA-256 digests. All 15 release assets match the refreshed checksum manifest. Downloaded APT and RPM metadata signatures independently verified against the committed key.
- Full cross-platform CI passed on cc2aad7: https://github.com/xfreebird/smartcard/actions/runs/42454518426. Latest b73b298 CI also passed all seven jobs, https://github.com/xfreebird/smartcard/actions/runs/42454723240.

## Explicit limits

Chocolatey is project-distributed, not listed in the community catalog; community publishing requires a publisher account/API key. The Arch recipe is not submitted to AUR and was not runtime-tested. Debian and openSUSE installations were not separately exercised. No physical-card signing, PIN-provider authorization or unattended operation was invoked for package validation.
