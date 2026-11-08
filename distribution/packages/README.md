# CLI package distribution

User installation instructions: https://esemnbun.md/packages/

- Homebrew: reuse `xfreebird/homebrew-utils`, formula `esemnbun-cli` (macOS 15+, ARM64 and Intel).
- Scoop: `bucket/esemnbun-cli.json` in the same repository, standalone Windows x64 CLI.
- Chocolatey: `esemnbun-cli` package with the digest-verified executable embedded published as a release `.nupkg`. Download into an empty directory and run `choco install esemnbun-cli --source . --yes`. No community-catalog account/key is configured; do not claim a default-source/community listing.
- APT: signed repository at `/packages/apt`, CLI packages for amd64. Use a dedicated `signed-by` keyring. Current binaries target Ubuntu 24.04 / compatible Debian 13 libraries.
- DNF: signed RPMs and signed repository metadata at `/packages/rpm/x86_64`; both `gpgcheck` and `repo_gpgcheck` remain enabled. Compatible RPM systems can use the same repository if dependencies resolve.
- Arch: generated `PKGBUILD` for x86-64; inspect and run `makepkg -si`. Not yet submitted to AUR.
- Other Linux: release tar archive with both executables. Requires glibc/OpenSSL/libcurl/PCSC; not an Alpine/musl build. Do not claim ARM64 packages until built and published.

## Automation

`CLI package repositories` runs after a successful Release workflow, weekly, or manually. It selects a complete stable release and verifies upstream asset SHA-256 digests. Missing platform assets defer publication without replacing existing package definitions. APT installs and executes the CLI on an Ubuntu runner; RPM signatures are checked against an isolated RPM database. A Windows job packs Chocolatey and checks installation, CLI execution and uninstallation. No test invokes card signing or configures unattended signing.

Public binary URLs use `esemnbun.md/packages/downloads/vVERSION/` because the source repository is private. Authenticated CI downloads are digest verified before publication.

The workflow publishes signed repository and definition archives, the Chocolatey `.nupkg`, and refreshed SHA256SUMS to the existing release. Website deployment verifies the repository archive digest and the pinned signing key before exposing the repositories. It does not hold the private signing key. Partial releases keep the last complete package feed live; website deployment also retains CLI downloads for two previous packaged versions. The tap workflow checks for definitions every six hours, verifies the archive digest, and updates only the two eSemnBun package definitions. Manual tap workflow dispatch also exercises Homebrew install/test.

Windows packaging now emits a standalone Native AOT ZIP for future releases. The initial 0.2.6 ZIP contains the exact `bin/esemnbun.exe` from the verified 1.2.206.0 MSIX, plus LICENSE and usage notes. It installs no GUI, certificate, service or PIN configuration.

## Signing-key custody

Public fingerprint: `F8075499A4B311BA30E53156E5622B86C8280D0B`.

The dedicated package key is in the existing repository's `PACKAGE_SIGNING_KEY` Actions secret. The owner keeps the private backup and revocation certificate outside Git. The public key is committed here and served by the website. Its expiry is November 2028. Rotation requires a reviewed public-key/fingerprint update in the workflow and client instructions; never disable signature checks to work around expiry. APT metadata expires after 90 days and is refreshed weekly.

The RPMs in the repository are signed copies of upstream release RPMs, so their hashes differ from the original unsigned RPM assets. Existing release artifacts remain unchanged. The repository archive and its current digest are recorded by GitHub; installed clients additionally check signed APT/RPM metadata.
