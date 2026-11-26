---
name: esemnbun-ci-automation
description: Audit, optimize and validate eSemnBun GitHub Actions, job routing, build counters, artifact reuse and publishing boundaries. Use when changing workflows or diagnosing CI/publishing cases; not for routine app UI edits.
---

# CI and publishing automation

Read [the workflow decision guide](../../../docs/14-github-actions.md) before changing a trigger, permission, secret, concurrency group or store operation. Inspect current workflow/scripts and live run/store state; historical release reports are evidence for their recorded source only.

- CI is secret-free validation, including native Debug mock UI suites in each selected platform job. Missing UI prerequisites and incomplete XCTest runs must fail, not skip. The signed Android builder is manual-only; branch pushes must not reserve versions or invoke publishing. PR/main diffs select affected native jobs through `scripts/ci/select_jobs.py`; unknown files/missing history run all. Preserve the stable `CI result` aggregate and docs-only skips. Manual CI dispatch runs all platforms.
- Apple simulator selection stays within the active SDK's major/minor release line, requires both phone and tablet, and retains runtime/device inventories. Within the newest eligible runtime prefer iPhone Duo and iPad mini, retaining all tablet cases and rotations with less framebuffer pressure on the 7 GB runner. Newer-runtime compatibility failures remain separate open evidence; do not represent SDK-line CI as fixing them.
- macOS fixture journeys require the generated QA runner to launch with its environment/arguments intact. Xcode's runner template can inject App Sandbox independently of `ENABLE_APP_SANDBOX`; `run-verification-ui-tests.sh` builds first, asserts the QA runner identifier, re-signs that generated runner without the sandbox entitlement, verifies it, then tests without rebuilding. Preserve the tested app signature and host authorization. Build-only harness validation must not interrupt the owner's running app.
- Keep iOS validation bounded across both required families: isolated iPhone/iPad matrix jobs, `max-parallel: 1`, 50-minute job and 45-minute UI-step caps per device family (100/90 minutes combined, plus bounded cancellation cleanup). Boot only the assigned simulator after compilation; overlapping cold boot with package resolution stalled a hosted build. Compile the runner architecture and shared XCTest harness once and generate document fixtures. CI runs all 35 cases in one `test-without-building` session; keep the exact 35-pass/zero-skip guard and both protection/Documents filesystem postchecks. Local per-suite runners remain available. Prepared per-suite runs install the supplied app before XCTest unless the caller explicitly sets `MSIGN_UI_APP_INSTALLED=1`; do not validate a stale installed build after changing the app. Each job retains bounded build and always-run evidence upload; artifact names include the family. Boot only the assigned family: the Duo and iPad require different runtimes on the hosted SDK image. Stop worker descendants and shut down its simulator on failure/cancellation; matrix fail-fast is disabled so an independent family still finishes, while every failing device stops its own work. Rerun only failed jobs after investigation; preserve completed family passes. Direct local runs may collect all failures. Disable expensive whole-simulator sysdiagnose with `-collect-test-diagnostics never`; retain normal XCTest evidence. Do not turn timeouts or incomplete runs into passing checks.
- Android CI checks the required saved-identity and browser-authentication instrumentation markers alongside the main journeys and protection persistence phases. The browser UI regression deduplicates fictional certificate metadata, checks the serial number and changes the method without opening NFC or requesting a PIN. When a hosted Gradle run reports only an unresolved managed plugin, use the implementation POM at its official repository to distinguish missing versions from retryable resolution failures. Preserve the three-attempt cap.
- Retain native postcheck proof with UI artifacts, including each iOS protection `roundtrip.json`; a passing XCTest bundle alone does not report the filesystem assertions performed afterward.
- Cancel superseded validation, never an active publishing/signing operation to save time. Android build/upload/publish operations share `android-play-version-code`; Apple Store uploads share `apple-store-ios`/`apple-store-macos`. Do not promise an unlimited publishing queue.
- Cache dependency downloads, not keys/keychains, signed outputs, mutable edits or provider credentials. Preserve bounded dependency-only retries, signature/digest checks and explicit source-run selection.
- Build once when the exact signed artifact already contains the requested source. For Play, use `android-play-publish.yml` with the inspected Android-build/Release run ID; `artifact_only` and `closed_testing` have different effects. A deferred review is a visible non-submission, not a publish success. Uncertain commits require a live read before retrying.
- Public installer releases, artifact uploads, TestFlight uploads, review submissions and rollouts are independent. Use [the release skill](../esemnbun-release-stores/SKILL.md) for actual delivery, within the user's requested scope. Optimizing a workflow does not authorize a store mutation.
- Secret names and backup locations belong in the guide's inventory. Audit with `gh secret list`/`gh variable list`, never print values. On the owner's setup, gh/push/dispatch run only on the main Mac with `GH_HOST=github.com`; other developers resolve their own approved environment.

Batch validation after edits:

```sh
python3 -m unittest discover -s scripts/ci -p 'test_*.py'
python3 -m unittest discover -s scripts -p test_play_publish.py
# Needs Pillow, requests, PyJWT and cryptography (scripts/requirements/sonar-coverage.txt + store-publish.txt).
python3 -m unittest discover -s scripts/tests -p 'test_*.py'
(cd website && npm ci --ignore-scripts && node --test tests/*.test.mjs)
bash -n scripts/ci/reserve-android-version.sh
ruby -c fastlane/Fastfile
# Run the pinned official actionlint release; .github/actionlint.yaml declares xcode-27.
actionlint
```

Test changed publishing guards with simulated API responses. Do not dispatch a real upload as a smoke test. After an authorized push, inspect the exact head's selected/skipped jobs and aggregate; distinguish local checks, hosted CI and real store outcomes. Update `PLAN.md`, the workflow guide and affected release/build skills in the same change.

For a hosted-budget Pages outage, `website.yml` supports an explicitly selected `esemnbun-recovery` runner label on manual dispatch. Use a trusted, repository-scoped ephemeral runner per job and clean its credentials/workspace afterward; never install a persistent service or route untrusted PRs to an owner machine. Automatic jobs remain hosted.


Scanner hardening: preserve action SHA pins/version comments and job-scoped write permissions for publishers and Android version reservation. Store Python installs are wheel-only/hash checked through `scripts/requirements/store-publish.txt`. Android verification metadata is enforced normally; its dedicated resolution task refreshes hashes only after reviewed dependency changes, never as a CI retry. Automatic Sonar analysis cannot import coverage and must not run alongside a CI scanner. Respect the owner's current delivery boundary: static/dependency checks do not replace the full native/real integration matrix in `docs/reports/scanner-hardening-integration-2026-11-22.md`.


Android R8 follow-up: AGP 9.0.1 uses Gradle 9.1.0 and built-in Android Kotlin, aligned with the Kotlin/JVM/Compose compiler 2.2.10. Optimized resource shrinking is explicit; preserve Release minification and the Gradle distribution checksum. Validate the actual optimized Release app's resources and real reader/NFC/portal flows, then inspect its APK/AAB metadata. Debug journeys or dependency resolution do not establish that Play's uploaded-bundle advisory is cleared.


Android Actions use the shared `scripts/ci/android_build_policy.py` preflight and artifact metadata gate. All four builders check the selected wrapper/daemon policy; secret-free CI also builds/lints an unsigned optimized Release bundle. Signed packaging checks before signing and records the final AAB hash with mapping/configuration under the existing artifact's `optimization/` directory. Keep those records in Actions evidence, preserve the public installer filter and do not treat artifact-only publishers as rebuilding old bundles. Hosted passes require an authorized push/run; local uncommitted wiring is not CI execution.
