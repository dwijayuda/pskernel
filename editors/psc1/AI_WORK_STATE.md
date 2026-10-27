# PSC1 LSP / VS Code work state

Updated 2026-10-28 Asia/Jakarta. Branch `feat/psc1-lsp-vscode-20261028`; base `9d0e23c34484e4b1159f3e2428f5452139df530a` from qualified PR197. GitHub/cloud-only development, Linux CI, single-parent non-force expected-HEAD updates. No merge or registry publication.

## Active 0.1.1 performance and platform follow-up

User reported slow checking and a screenshot of `PSC1_SERVICE_PUBLICATION_PLATFORM_UNQUALIFIED` with Infoview stuck pending. The repair uses existing public candidate-analysis and exact-graph checking APIs, removing duplicate analysis/target publication work. Compiler and kernel sources remain unchanged. The receipt explicitly records logical-admission scope, no target validation, and no publication. The loader preserves client URI identity and unsaved buffers, including Windows aliases. Terminal UI state and dependency-version tracking were repaired. The server now skips unchanged saves, caches up to eight exact source results within 16 MiB, and terminates Windows compiler descendants on cancellation. Cursor selection no longer requires a server round-trip.

Version 0.1.1 is under qualification. The updated workflow compares the previous immutable 0.1.0 npm package with this candidate on the same Linux runner, then installs the exact new artifacts on Windows and macOS. No local compiler execution, tests or dependency installation have been run. The historical sections below describe 0.1.0 and are not new-version qualification claims.

### First follow-up run

Implementation `5188e44f95abaa9ca71a0e3583b075a97111d4ad`, run [40590223438](https://github.com/dwijayuda/pskernel/actions/runs/40590223438), passed all 23 tests, Linux installed npm/VSIX smoke and the same delivered artifacts on native macOS. The same-runner small-source comparison measured old/new distinct-edit medians 1956.08/667.95 ms (65.85% lower), with identical admissions/source digests for every sample; default benchmark debounce was 50 ms. Unchanged save required no new check (0.41 ms LSP round-trip); returning to an identical snapshot used the cache (52.32 ms including debounce). Actual installed VS Code with default 350 ms debounce reached initial checked status in 1210 ms.

The Windows job failed before tests because GNU tar interpreted an absolute `D:` archive path as a remote host. The native-artifact unpack helper now uses relative paths. This follow-up changes only the test harness/workflow and documentation, not the installed editor payload. Native Windows qualification is still pending the corrected run.

### Corrected unpack run

Run [40590701343](https://github.com/dwijayuda/pskernel/actions/runs/40590701343) at `efe40c49cb8bc611c63376635e08227e3a19a78d` passed Linux and macOS qualification. Windows passed all 23 real/UI tests, the real latency harness, and fresh offline npm installation. Its VSIX harness failed before extension activation because the assumed internal VS Code `resources/app/out/cli.js` path was absent from the downloaded Windows archive. The harness now invokes the actual official `code.cmd` returned by the VS Code test library, with an explicit system command processor and safely bounded/quoted generated test paths, and records the launcher's actual entry references. No editor runtime or compiler source changed for this repair.

## Architecture and completed source

Independent `editors/psc1` tooling contains a stdio LSP, bounded project-data adapter, isolated public-API compiler worker, original VS Code extension, and Lean-inspired Infoview. Both distributables bundle the unchanged qualified `.12` compiler and official Lean4.35.0 linear-memory Wasm checker. Compiler source, existing npm package layout, provider internals, self-hosting inputs and core CI are unchanged.

Compiler-backed: real refusals, actual independent admission, source-origin declarations and presentation of elaborated Core types correlated to the checked receipt. Syntax-only: incomplete outline, keywords, current declaration-name suggestions and spelling highlights. Definition navigation uses origin declarations and explicit imports; no guessed reference binding. No interactive proof-state snapshots, inferred term types, binding-aware references/rename/signatures or semantic quick fixes are fabricated.

Unsaved project sources, versions/generations, supersession, process-group cancellation, per-job temporary cleanup, project capture bounds, trust gating and script-disabled escaped Infoview implemented. `.lean` opt-in uses explicit PSC1 language mode without automatic takeover.

## Qualification

Source was assembled in cloud scratch and written through GitHub Git object/ref APIs; no local compiler, dependency installation or test execution is used. Draft PR [199](https://github.com/dwijayuda/pskernel/pull/199) targets the compiler baseline branch.

Initial run [40584667014](https://github.com/dwijayuda/pskernel/actions/runs/40584667014) built both bundles and verified the compiler archive, then exposed an invalid `connection.onClose` call. The call was removed after inspecting the exact upstream 11.0.0 lifecycle; existing shutdown/exit handlers terminate process groups. The runner-generated dependency lock was captured and committed.

Run [40585014908](https://github.com/dwijayuda/pskernel/actions/runs/40585014908), commit `93aaeb3ad2d7aae18639d7acf173d3a7ffb390fa`, passed all 16 integration tests, VSIX/npm packaging, and fresh offline installed-npm checking. Its installed VSIX smoke exposed a test serialization mistake: VS Code MarkdownString accessors serialized as empty objects. The corrected test reads the public hover `.value` and retains the actual Nat assertion.

**Complete qualification passed** in [40585721463](https://github.com/dwijayuda/pskernel/actions/runs/40585721463), job 122476455210, exact implementation `34beabcfc3fce89e4c89bcc6aa4e372e0c1bdeb1`. All 16 automated tests pass. Fresh offline npm installation (empty cache, no lifecycle scripts, SDK-free PATH) launches the installed bin and accepts the genuine Wasm-checked source. The actual installed VSIX passes activation, language registration, genuine checking, symbols, actual hover type, Infoview requests/view command, unsaved rejection, Problems diagnostics, manual restart/recovery, and save in VS Code 1.143.1 / Electron 43.7.7 / Node 24.21.0. Standalone CI uses Node 22.23.3. No source extension substitutes for the installed VSIX.

See [complete machine-readable receipt](QUALIFICATION_2026-10-28.json). This final work-state/receipt/README update changes documentation only; no additional compiler or editor execution inputs change and no optional test rerun is needed.

## Installable delivery

Qualified [editor artifact 12772441610](https://github.com/dwijayuda/pskernel/actions/runs/40585721463/artifacts/12772441610): 7462227 bytes, ZIP SHA256 `e350b263662d2cf4d321ed8181e3e134ff10494e3deab7f9d25efa84ae471cf0`.

- `proofscript-psc1-0.1.0.vsix`: 3594823 bytes, SHA256 `99cf053d2ff015d8fa9f2d8f9d31499044d1ea6a9f7a826e6b6cf16c31eb725f`.
- `proofscript-lsp-0.1.0.tgz`: 3917035 bytes, SHA256 `29f46476552dfb33a0756b02a1a6e2797b6079195ec222fe547ce651bafae2cd`.
- [Evidence artifact 12771637295](https://github.com/dwijayuda/pskernel/actions/runs/40585721463/artifacts/12771637295) retains actual runtime/installation receipts, audit, build identity, and exact dependency lock.

The unchanged qualified compiler tarball remains `9a66dcd0f92aaa60f600674fb91b31bc0d67b211d1e9e004146baa8e96502fcc`; its actual compiler source closure is `073e5156a3fb521119bcfb4b06ad18ff136e734a0b2e10a676b1e16225835ef9`.

Observed small-fixture full-check worker times: stdio 3612 ms, fresh installed npm 3054 ms, VS Code initial 4684 ms, post-restart 4429 ms. These are CI observations, not a large-project latency guarantee. The server remains asynchronous; deeper compiler reuse/incrementality is a future performance improvement.

The build dependency audit records one MSAL advisory through three dev-only publisher/authentication nodes. No authentication or publication is used and those modules are excluded from the actual bundled runtime inventory. See RESEARCH.md for the upstream range constraint and reason not to force an incompatible major override.

## Remaining scope

This usable Linux editor preview is delivered. Future priorities are public compiler proof-state/binding APIs, more precise diagnostics, large-project performance, non-Linux qualification, and permanent hosting before registry/Marketplace release. No compiler fixed-point or kernel qualification reruns are needed for the delivered tooling because their inputs are unchanged. PR remains draft; no merge or publication is authorized.

## Known limits

Linux qualification only; `.lean` subset requires explicit project selection. Source closure order/grammar/import restrictions are inherited from PSC1. Parse positions may be module-level. Legacy inline project text lacks disk-file provenance. 64 open sources, 512 declared files, 8 MiB project capture, configurable 30-second deadline. Cold compiler startup and full-project checking are retained; no compiler redesign. Original input artifact expires 2027-01-25 unless retained externally; delivered VSIX/npm packages include the payload and do not fetch it at runtime.
