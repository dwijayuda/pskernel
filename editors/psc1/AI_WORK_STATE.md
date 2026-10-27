# PSC1 LSP / VS Code work state

Updated 2026-10-28 Asia/Jakarta. Branch `feat/psc1-lsp-vscode-20261028`; base `9d0e23c34484e4b1159f3e2428f5452139df530a` from qualified PR197. GitHub/cloud-only development, Linux CI, single-parent non-force expected-HEAD updates. No merge or registry publication.

## Architecture and completed source

Independent `editors/psc1` tooling contains a stdio LSP, bounded project-data adapter, isolated public-API compiler worker, original VS Code extension, and Lean-inspired Infoview. Both distributables bundle the unchanged qualified `.12` compiler and official Lean4.35.0 linear-memory Wasm checker. Compiler source, existing npm package layout, provider internals, self-hosting inputs and core CI are unchanged.

Compiler-backed: real refusals, actual independent admission, source-origin declarations and presentation of elaborated Core types correlated to the checked receipt. Syntax-only: incomplete outline, keywords, current declaration-name suggestions and spelling highlights. Definition navigation uses origin declarations and explicit imports; no guessed reference binding. No interactive proof-state snapshots, inferred term types, binding-aware references/rename/signatures or semantic quick fixes are fabricated.

Unsaved project sources, versions/generations, supersession, process-group cancellation, per-job temporary cleanup, project capture bounds, trust gating and script-disabled escaped Infoview implemented. `.lean` opt-in uses explicit PSC1 language mode without automatic takeover.

## Qualification

Initial implementation is ready for the dedicated `proofscript-editor.yml` workflow. Source was assembled in cloud scratch and written through GitHub Git object/ref APIs; no local compiler, dependency installation or test execution is used. CI must verify real LSP integration, theorem/type refusal, stale jobs, imports, actual fresh offline npm install and actual installed VSIX activation. Record exact successful run, commit, dependency lock and artifacts here after qualification; do not describe this initial checkpoint as qualified.

## Remaining before delivery

Resolve any concrete CI failures, capture the generated dependency lock, rerun the focused workflow on the locked implementation, record receipt/artifact SHA-256 and open a draft PR against the compiler baseline branch. No compiler fixed-point or kernel qualification reruns are needed because their inputs are unchanged.

## Known limits

Linux qualification only; `.lean` subset requires explicit project selection. Source closure order/grammar/import restrictions are inherited from PSC1. Parse positions may be module-level. Legacy inline project text lacks disk-file provenance. 64 open sources, 512 declared files, 8 MiB project capture, configurable 30-second deadline. Cold compiler startup and full-project checking are retained; no compiler redesign. Original input artifact expires 2027-01-25 unless retained externally; delivered VSIX/npm packages include the payload and do not fetch it at runtime.
