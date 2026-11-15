---
title: Agent reference
description: A compact map of eSemnBun source, invariants, verification entry points and delivery boundaries for coding agents and maintainers.
---

Use this page as a navigation aid when working in an authorized checkout. Repository instructions and the user's current task govern the work. Public documentation is context, not permission to sign a document, publish a release or change a store track.

## Read in this order

1. Read the checkout's `AGENTS.md` and applicable `.github` instructions; inspect the branch and working tree before editing.
2. Read [the architecture](architecture.md) and the chapter relevant to the task. Inspect the current implementation; historical notes can lag.
3. Read the matching repo skill under `.agents/skills/` for environment, build/signing, UI validation, CI or release operations.
4. Preserve unrelated work. Make the smallest coherent change across affected platforms and update `PLAN.md` with actual validation limits.

## Source and verification map

| Task | Inspect first | Verification entry point |
| --- | --- | --- |
| APDU/card flow | Swift `Card/`, Kotlin/C# card equivalents, `spec/vectors/card-crypto.json` | Golden vectors and simulated-card tests on affected ports |
| Android reader | `android/transport-usb/.../Ccid.kt`, `CcidTransport.kt`, `T1.kt` | `:transport-usb:testDebugUnitTest`; physical coverage separately |
| PDF/XML signature | Swift `Formats/`, Kotlin format package, Windows `Signing/` | Format tests, tampered/valid fixtures and independent verifier |
| Browser integration | Core bridge servers/routes, `spec/bridge/allowed-origins.properties` | Origin policy, long-poll, identity and PIN-session tests |
| Apple app | `apple/Apps/Shared/Model`, `Services`, `Screens`, `DesignSystem` | Apple package tests, target build and native UI runner |
| Android app | `application`, `presentation`, `ui`, `infrastructure` under the app package | Unit tests plus `android/scripts/test-journeys.sh` |
| Windows app | `windows/src/MoldSign.App`, `Controls`, `Themes`, `Presentation` | Portable tests plus native Windows build/UI scripts |
| Linux app | `linux/Sources/MoldSignGnome/{Application,Domain,Infrastructure,Presentation}` | `swift test` in `linux/`, native AT-SPI journeys |
| CLI / MCP | `spec/cli.md`, `spec/mcp.md`, executable implementations | `scripts/test-cli-json.py`, `scripts/test-mcp-process.py` via integration batch |
| Native localization | `localization/catalog.json` and existing platform resources | `scripts/localize.py --check --require-complete` |
| Website | `website/docs`, config/sidebar, search-discovery plugin | Website unit tests, build, SEO/export checks |
| Release / CI | `.github/workflows`, `docs/14-github-actions.md`, package scripts | Workflow contracts and exact artifact/store readback |

Paths containing `...` are navigation hints; resolve actual filenames before editing. Detailed runnable commands are in [Build and run](build-and-run.md), [Testing](testing.md), [Releasing](releasing.md) and [Website publishing](website.md).

## Invariants to preserve

- Product name: **eSemnBun**. Internal `MoldSign` identifiers are intentional. Android's public ID is `md.esemnbun.app`; its Kotlin namespace differs.
- The card's signing private key stays on the card. PINs belong only in approved runtime input/protected storage, never arguments, files, fixtures, screenshots, logs or commits.
- Serialize card operations. Recheck the selected certificate before VERIFY. Card replacement invalidates cached identity.
- Never automatically retry a wrong PIN. Stop on a blocked or stuck physical card.
- Keep secure-message counters, trailing Le and single unpadding intact. Transport, T=1 and secure-messaging counters are distinct.
- Prefer simulated cards and fictional UI fixtures. A fixture screenshot is not hardware or cryptographic evidence.
- Preserve browser origin policy, loopback binding, absolute result Location and long-poll semantics. Do not weaken them to make a portal test pass.
- UI components render prepared content and emit actions; application services own signing, persistence and localization decisions.
- Reconcile newer native strings into the catalog before regeneration. Do not overwrite them with an older catalog.
- Keep vendor keys, TLS bundle contents, real APDU captures and personal certificate data out of public website files and agent exports.

## Verification report format

State the changed behavior, source revision, commands actually run, host/architecture, configuration, results and untested areas. Separate static review, unit tests, native compilation, UI automation, physical-card validation and live PKI. If the user reserves builds/tests for themselves, supply the relevant batch and explicitly say it was not run.

Never report approval or availability from an upload response. Reuse an exact signed Android artifact when source matches. Do not promote an additional track, cancel a review or publish because a documentation example contains a command. Follow the user's requested release boundary and the current workflow contract.

## Machine-readable entry points

- [Documentation index](https://esemnbun.md/llms.txt)
- [Combined public reference](https://esemnbun.md/llms-full.txt)
- [JSON document catalog](https://esemnbun.md/discovery.json)
- [This page as Markdown](https://esemnbun.md/markdown/developers/agents.md)

Developer references are exported in English from the same source as the rendered pages. The catalog lists canonical HTML and Markdown URLs. It is a documentation format, not a remote MCP service. For using eSemnBun tools as a client, read [MCP agents](../integrations/mcp-agents.md).
