---
name: esemnbun-ci-automation
description: Audit, optimize and validate eSemnBun GitHub Actions, job routing, build counters, artifact reuse and publishing boundaries. Use when changing workflows or diagnosing CI/publishing cases; not for routine app UI edits.
---

# CI and publishing automation

Read [the workflow decision guide](../../../docs/14-github-actions.md) before changing a trigger, permission, secret, concurrency group or store operation. Inspect current workflow/scripts and live run/store state; historical release reports are evidence for their recorded source only.

- CI is secret-free validation. PR/main diffs select affected native jobs through `scripts/ci/select_jobs.py`; unknown files/missing history run all. Preserve the stable `CI result` aggregate and docs-only skips. Manual CI dispatch runs all platforms.
- Cancel superseded validation, never an active publishing/signing operation to save time. Android build/upload/publish operations share `android-play-version-code`; Apple Store uploads share `apple-store-ios`/`apple-store-macos`. Do not promise an unlimited publishing queue.
- Cache dependency downloads, not keys/keychains, signed outputs, mutable edits or provider credentials. Preserve bounded dependency-only retries, signature/digest checks and explicit source-run selection.
- Build once when the exact signed artifact already contains the requested source. For Play, use `android-play-publish.yml` with the inspected Android-build/Release run ID; `artifact_only` and `closed_testing` have different effects. A deferred review is a visible non-submission, not a publish success. Uncertain commits require a live read before retrying.
- Public installer releases, artifact uploads, TestFlight uploads, review submissions and rollouts are independent. Use [the release skill](../esemnbun-release-stores/SKILL.md) for actual delivery, within the user's requested scope. Optimizing a workflow does not authorize a store mutation.
- Secret names and backup locations belong in the guide's inventory. Audit with `gh secret list`/`gh variable list`, never print values. On the owner's setup, gh/push/dispatch run only on the main Mac with `GH_HOST=github.com`; other developers resolve their own approved environment.

Batch validation after edits:

```sh
python3 -m unittest discover -s scripts/ci -p 'test_*.py'
python3 -m unittest discover -s scripts -p test_play_publish.py
bash -n scripts/ci/reserve-android-version.sh
ruby -c fastlane/Fastfile
# Run the pinned official actionlint release; .github/actionlint.yaml declares xcode-27.
actionlint
```

Test changed publishing guards with simulated API responses. Do not dispatch a real upload as a smoke test. After an authorized push, inspect the exact head's selected/skipped jobs and aggregate; distinguish local checks, hosted CI and real store outcomes. Update `PLAN.md`, the workflow guide and affected release/build skills in the same change.

For a hosted-budget Pages outage, `website.yml` supports an explicitly selected `esemnbun-recovery` runner label on manual dispatch. Use a trusted, repository-scoped ephemeral runner per job and clean its credentials/workspace afterward; never install a persistent service or route untrusted PRs to an owner machine. Automatic jobs remain hosted.
