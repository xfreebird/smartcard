# Architecture and test review follow-up

Current build, native test and delivery evidence is tracked in [commit CI validation](commit-ci-validation-2026-11-11.md). The unrun/pending statements below describe the earlier review checkpoint.

This follow-up implements the concrete remaining areas identified in the two earlier review reports:
consent/PIN lifecycle, signing-session policy, screenshot orchestration and core parser decomposition.
It adds native automation entry points for macOS, iOS, Android, Linux and Windows, integration regression
cases, and explicit traceability for all 47 documented journeys plus three current protection journeys.

## Findings and changes

| Finding | Change | Regression evidence added (not executed) |
| --- | --- | --- |
| Apple consent presentation could answer before its continuation was installed; cancellation could strand a waiting worker. | `DecisionChannel` installs before presentation and resolves only its own request. `CancellableRequestScope` owns bridge tasks and invalidates results when the listener stops. Queued callbacks check their server instance. | Synchronous answer, overlapping request, cancel/dismiss, bridge shutdown, noncooperative late result. |
| Apple PIN lookup and browser consent were interleaved with unrelated application state. | `PINCoordinator` owns saved-credential acquisition/presentation; `BridgeAuthorizationCoordinator` owns consent/origin trust. The UI keeps existing bindings through forwarding properties. Wrong-PIN bridge cleanup uses the requested certificate, not an unrelated selected card. | Request lifetime tests; existing frozen-identity/batch tests remain required. Actual OS authentication is unrun. |
| Android consent and stamp requests could overwrite an existing prompt and clear another request's state. | Compare-and-set admission/cleanup rejects overlap. Consent shutdown releases workers; unused/late PIN arrays are cleared. Container shutdown cancels both brokers. | Overlap, timeout, shutdown, late/duplicate answer and consumed credential lifetime tests. |
| Android batch failure policy lacked direct integration coverage. | Real `SignDocuments` workflow runs against injected signing, fixture data and output ports. UI callback exceptions propagate without being misclassified as document failures. | Format/network/output failures continue, wrong PIN/card change/cancellation stop, selected reader/certificate forwarding, consumer failure preserves one save. |
| Linux consent callbacks could outlive the bridge, and duplicate consent could start two PIN reads. | Dedicated coordinator owns one pending request. Stop rejects pending authorization; duplicate callbacks are ignored. Vault lookup checks request validity before opening a late PIN prompt. | Late consent, duplicate consent/PIN, invalidated in-flight lookup, exactly one completion. |
| Windows cancellation waited for UI dispatch, which may never run during shutdown. | Toolkit-independent `ConsentDispatch` completes the worker directly on cancellation and prevents a delayed callback from presenting. | Unrun UI queue, rejected enqueue, late dispatch after cancellation. |
| Screenshot fixture construction crowded application coordinators. | Apple and Linux `DemoScenarioState` build fictional state outside their app coordinators. Fixture files/data remain in providers. Domain/service files are separated by responsibility. Android screens retain their required imports after an additional extraction audit. | Native fixture assertions and existing demo isolation tests; no real-signature claim. |
| Shared bridge parser could overflow on a hostile content length or index an empty query component. JSON error escaping omitted control characters. | Separate `BridgeWireFormat`; bounded body arithmetic, explicit invalid-framing rejection, safe query components, Foundation JSON string encoding. | Fragmented UTF-8 body, impossible/duplicate lengths, transfer-encoding rejection, empty query names/values, JSON control-character round trips, absolute result URL. |
| DER length readers and certificate parsing could slice truncated data; PAdES assumed fixed certificate header lengths. | Extract reusable `DER`/`CertFields`; bounded element ranges and parent checks; CMS and OCSP share certificate fields. Timestamp token extraction and CMS padding stripping use the checked reader. | Every truncated certificate/timestamp prefix, invalid lengths/offsets, valid extraction, malformed certificate rejected before signing callback. |
| XML validator could construct reversed ranges from malformed closing tags; its parser was embedded in the general validator file. | Extract `XMLSignatureValidator`; search closing tags after the matching opening tag, remove an always-true condition, and reject missing signed properties. | Malformed/reversed tags cannot crash; simulated signed XAdES with removed properties must fail content integrity. |

The earlier provider and workflow changes remain: replaceable live/demo data ports, Apple document
library and verification feature models, Linux verification workspace, Android batch workflow and Windows
verification workflow. Large shell coordinators still exist, but the reviewed policies now have named
owners and test seams. This is not a certification that every possible repository-wide code smell has
been eliminated. No new framework, generic repository layer, service locator or inheritance hierarchy
was introduced.

## Test delivery

Follow-up: [interactive mock workflows](mock-ui-workflows-2026-11-11.md) adds real signing, queue, format,
stamp, history and disclosure actions using injected scenario services on every native platform.


See [test instructions](../testing/README.md) for exact batch commands and native prerequisites.
`tests/journeys/catalog.json` maps every inventory row, acceptance criteria, edge cases, platform and
suite path. `scripts/check-journey-coverage.py` validates those references; its strict automation gate
fails while coverage remains partial. This makes missing OS/hardware coverage visible instead of silently
counting fixture screenshots as end-to-end tests.

New native suites cover verification/clear on every GUI platform, Apple/Android reader errors, Apple/Linux
PIN cancellation, Android output and batch failures, and the Linux scenario catalog. Existing document,
carousel, demo, protection, first-launch, helper, CLI and MCP suites are included in the execution plan.

## Validation and remaining work

Performed: Swift syntax parsing in normal and Debug/demo configurations, shell/Python syntax checks,
XML project/XAML parsing, journey-reference consistency, and diff whitespace checks. These are static
checks only; no type checking, application build, test execution, native interaction or live device
validation was performed. The repository's owner-run build/test instruction remains in force.

The full automated UI requirement is **not complete**: installer/Store flows, physical USB/PCSC and
permissions, OS credential prompts, real file-provider/share/drag-drop routes, Shortcuts, Spotlight,
Handoff, autostart and live portal checks still need the native work explicitly recorded in the catalog.
All newly authored tests also need execution on their target platform. The test plan must not be treated
as passing evidence. In particular, the shared parser changes need the complete Swift/portable signing,
verification and bridge suites before merge; native app builds are needed to catch type/access/import
errors that syntax parsing cannot establish.

No changes were committed, pushed, released or submitted to a store. Existing unrelated reports and
runtime evidence were preserved.

## Subsequent runtime validation

The owner subsequently authorized builds and tests. See [native test validation](native-test-validation-2026-11-11.md)
for the earlier local execution record. See [commit CI validation](commit-ci-validation-2026-11-11.md)
for current hosted builds, native UI results and remaining coverage limits.

## Additional deletion review — 12 November

Apple, Android and Linux validated selected library entries by ID but then deleted the location supplied
by the caller. A copied entry with the same ID and a different location could target a file outside the
saved library. Deletion now requires the confirmed location to match the stored entry. The UI receives
a failure for mismatches; neither file is deleted. Foreign IDs remain ignored. Android and Linux now
own this policy in application workflows, keeping file selection/deletion separate from presentation
and persistence. Windows already compares the complete immutable record, including its path.

Regression tests exercise substituted locations, valid confirmed deletion, unrelated-file preservation,
duplicate/foreign selections, missing files, failed deletion and symbolic links. Local validation passed:
42 Apple application cases, 14 Android application cases and app/instrumentation builds, and 35 Fedora
application cases with the native app build. Hosted native validation of this follow-up remains pending.
