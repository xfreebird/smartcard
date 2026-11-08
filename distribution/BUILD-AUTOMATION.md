# Build and publishing entry points

Use the [complete workflow guide](../docs/14-github-actions.md) for supported operations, inputs, expected deferrals and the secret/storage inventory. Workflow files and live store state are authoritative.

- **Validate:** CI selects affected platforms on PR/main changes; docs-only edits skip native builds. Manual CI dispatch selects all. The `CI result` aggregate must pass; no signing/Store secrets enter validation.
- **Build Android:** `android-build.yml` produces signed APK/AAB artifacts and reserves a code. Default push/manual behavior does not upload to Play. Optional `upload_play=true` uploads an artifact only.
- **Publish Android:** `android-play-publish.yml` reuses the exact completed main Android-build or trusted Release run. Choose upload-only or one existing closed track. It preserves active reviews and other tracks, verifies identity/hashes and records uncertain results. It does not publish production or alter tester lists/listings.
- **Apple:** `apple-testflight.yml` allocates only the selected iOS/macOS runners and requires an explicit higher build number. Upload is TestFlight only. `macos-app-store.yml` is a compatible macOS-only shortcut. Review selection/submission is separate.
- **Windows:** `windows-build.yml` builds installers/CLI without Partner Center submission. `windows-store-credentials.yml` checks access read-only. Optional MSI signing uses existing credentials; self-signed MSI trust is distinct from Store MSIX signing.
- **Public installers:** `release.yml` creates/replaces the selected GitHub release assets, preserving other platforms. TestFlight, Play artifact and Windows Store operations require separate manual flags, default false; version tags do not activate them.
- **Package repositories:** `cli-packages.yml` consumes a complete release, signs APT/RPM feeds and publishes tested brew/Chocolatey definitions/assets. Community/upstream package-manager submission is not automated.
- **Huawei:** `huawei-appgallery.yml` requires an exact source run and stages a draft. An active review produces a visible deferral; cancellation and production submission remain separate authorized operations.
- **Website:** validates all locales and deploys Pages on main website/guide changes, explicit dispatch or successful release/feed completion. Installer/feed metadata derives from the actual latest release.

Credentials belong in Actions secrets or the owner's approved external secret source. The configured main-Mac backup is `~/Desktop/eSemnBun-secrets/`, not this repository. The [inventory](../docs/14-github-actions.md#secrets-identities-and-storage) lists exact names and backup files, including optional/unconfigured integrations. Build numbers, track identifiers, package identities and certificate fingerprints are configuration, not passwords.

Use the [CI skill](../.agents/skills/esemnbun-ci-automation/SKILL.md) for workflow changes and the [release skill](../.agents/skills/esemnbun-release-stores/SKILL.md) for delivery. Neither a workflow nor a skill expands the user's requested publication scope.
