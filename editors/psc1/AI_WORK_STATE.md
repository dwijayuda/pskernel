# PSC1 LSP / VS Code work state

Updated 2026-10-28 Asia/Jakarta. Branch `feat/psc1-lsp-vscode-20261028`; base `9d0e23c34484e4b1159f3e2428f5452139df530a` from qualified PR197. GitHub/cloud-only development, Linux CI, single-parent non-force expected-HEAD updates. No merge or registry publication.

## Architecture and completed source

Independent `editors/psc1` tooling contains a stdio LSP, bounded project-data adapter, isolated public-API compiler worker, original VS Code extension, and Lean-inspired Infoview. Both distributables bundle the unchanged qualified `.12` compiler and official Lean4.35.0 linear-memory Wasm checker. Compiler source, existing npm package layout, provider internals, self-hosting inputs and core CI are unchanged.

Compiler-backed: real refusals, actual independent admission, source-origin declarations and presentation of elaborated Core types correlated to the checked receipt. Syntax-only: incomplete outline, keywords, current declaration-name suggestions and spelling highlights. Definition navigation uses origin declarations and explicit imports; no guessed reference binding. No interactive proof-state snapshots, inferred term types, binding-aware references/rename/signatures or semantic quick fixes are fabricated.

Unsaved project sources, versions/generations, supersession, process-group cancellation, per-job temporary cleanup, project capture bounds, trust gating and script-disabled escaped Infoview implemented. `.lean` opt-in uses explicit PSC1 language mode without automatic takeover.

## Qualification

Source was assembled in cloud scratch and written through GitHub Git object/ref APIs; no local compiler, dependency installation or test execution is used. Draft PR [199](https://github.com/dwijayuda/pskernel/pull/199) targets the compiler baseline branch.

Initial run [40584667014](https://github.com/dwijayuda/pskernel/actions/runs/40584667014) built both bundles and verified the compiler archive, then exposed an invalid `connection.onClose` call. The call was removed after inspecting the exact upstream11.0.0 lifecycle; existing shutdown/exit handlers terminate process groups. The runner-generated dependency lock was captured and committed.

Run [40585014908](https://github.com/dwijayuda/pskernel/actions/runs/40585014908), commit `93aaeb3ad2d7aae18639d7acf173d3a7ffb390fa`, passes all16 integration tests, VSIX/npm packaging, and fresh offline installed-npm checking. The installed VSIX activates, checks a real source and exposes symbols, then its test incorrectly serializes VS Code MarkdownString accessors as empty objects. The test now reads the public hover `.value` and still requires the actual Nat type. Final full installed-extension qualification is pending the corrected smoke.

The build dependency audit records one MSAL advisory through three dev-only publisher/authentication nodes. No authentication or publication is used and those modules are excluded from the actual bundled runtime inventory. See RESEARCH.md for the upstream range constraint and reason not to force an incompatible major override.

## Remaining before delivery

Finish installed VSIX checks, record the final complete receipt/artifact SHA-256, and update the draft PR. No compiler fixed-point or kernel qualification reruns are needed because their inputs are unchanged.

## Known limits

Linux qualification only; `.lean` subset requires explicit project selection. Source closure order/grammar/import restrictions are inherited from PSC1. Parse positions may be module-level. Legacy inline project text lacks disk-file provenance. 64 open sources, 512 declared files, 8 MiB project capture, configurable 30-second deadline. Cold compiler startup and full-project checking are retained; no compiler redesign. Original input artifact expires 2027-01-25 unless retained externally; delivered VSIX/npm packages include the payload and do not fetch it at runtime.
