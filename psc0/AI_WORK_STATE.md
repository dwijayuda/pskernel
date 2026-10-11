# PSC0 AI work state — first PSCV0-authored compiler module candidate

## Current implementation checkpoint (2026-10-11)

Branch `psc0/pscv0-readable-selfhost-v1`; this migration started at `82ad3c6ef1cc634a5c3d94a1bad7ad2babd2e263`. The selected real compiler module is `Ps.Syntax.Translate`, now authored as `packages/syntax/src-ps/Ps/Syntax/Translate.ps` in an explicit candidate source map. The original public compiler remains unchanged.

The first source candidate `1d578cd6d96b3bd6a3a57ff90c8340a2b47c1870`, run `38110082840`, job `114383654200`, failed in the cheap round-trip gate: the predecessor printer expanded a higher-order parameter's `epsilon -> PsTranslationError` into `(_ : epsilon) -> PsTranslationError`, which the owned native binder reader could not reread. No expensive retained-compiler preparation ran. See `docs/PSCV0_FIRST_MODULE_VALIDATION.md`.

The general correction adds portable `Pscv0/TypePrint.lean`, rendering anonymous explicit Pi as ordinary arrows while preserving named/non-explicit binders. `Pscv0/Module.lean` uses it for both readable and lowered declaration headers. No original69 compiler source file, kernel code, host or source expectation is changed. This changes the new bridge itself, so its previous artifact cannot simply be relabeled qualified for the new behavior.

**Status:** corrected implementation is being committed for native/generated qualification. Read live HEAD and exact CI results before claiming success. Whole compiler migration and new full self-hosting are not complete.

## Candidate authoring authority

`pscv0-authoring.json` selects exactly `Ps.Syntax.Translate` from `.ps`. Missing, malformed or unsupported selected source fails with no fallback to the old `.lean` file. The four API signatures, error wrappers, values and failure order must be preserved; the source uses simple Except do and a generic error adapter rather than duplicated match chains.

The original `.lean` source is frozen predecessor code, blob `eafd7159b14a251fe11ffdbfb1e2482bcc773c9b`, not a second editable candidate master. `src-ps` keeps the candidate out of the old npm packer's source collision path. This is a staged source-authority selection, not a permanent dual-source architecture. Public npm source roots and CLI have not switched.

The selected reference is the user's PSCV0 Lean4.35.0-rc4 document, SHA-256 `a419955383fd3e35d873f82c939ecf3a92dc65b162cc9d0d3cadf5b853a0f4b0`, RC4 commit `c29b6dda4f7c20e3eeaa717c4e565663c5cfa364`. Its base do, arrows, binder visibility and source-formatter meaning apply. No backward-compatible old `.ps` option is required. Predecessor leaf translation APIs remain internal bootstrap functionality, not a future public old-grammar mode.

## Systematic two-stage bootstrap with shared prefix

1. Native cloud preflight checks all five portable PSCV0 modules, source round trips and the real Translate.ps projection. Eight Lean4.34 theorems compare its two projections against all four frozen predecessor APIs for every String input. These are native preflight files, NOT compiler inputs.
2. The hash-pinned retained PSC0 JS compiler prepares the unchanged syntax/foundation prefix once. Its documented pure preparation state is retained IN MEMORY immediately before Translate. Nothing is serialized into a trust token.
3. The compiler generates the current20-module surface bootstrap using the frozen predecessor Translate. This actual generated portable bridge—not native Lean or JavaScript string rewriting—then reads, prints and lowers the selected Translate.ps. Its views must exactly match native preflight, and the eight proofs run again on the generated products.
4. Resume the same pure prefix with PS-derived Translate and prepare the remaining suffix to emit the final candidate bridge. Report the reused prefix, both generated stages and all exact source/product identities. This avoids preparing the expensive unchanged prefix twice.
5. Linux/Windows run the original38 bridge tests unchanged, eight authoring tests (including36 original/candidate positive/negative comparisons) and four anonymous-arrow regressions. The generated candidate must read its own selected PS source and reproduce both projections. RC4 separately checks the actual generated module equalities and existing do fixture theorem.

Only syntax/foundation source is regenerated, not the whole64-module compiler or kernel. No full C2/C3 or selected-seed promotion is performed. A native pass alone does not qualify generated JS.

## Owners and preserved boundaries

- `Syntax/Pscv0/TypePrint.lean`: small portable anonymous-arrow/declaration-type printer; no change to kernel Pi meaning. Other expression/dependent-parser capabilities retain their limits.
- `Syntax/Pscv0/Module.lean`: common source declaration/header and lowered projection owner.
- `scripts/pscv0-authoring.mjs`: source-map IO and identity checks, invoking generated portable code for language meaning; proof-source assembly compares unmodified generated functions with frozen original definitions.
- `scripts/pscv0-build-bridge.mjs`: retained compiler and shared pure prefix, explicit ordered two-stage candidate generation.
- `scripts/Pscv0AuthoringSmoke.lean`: cheap native preflight only, no generated-runtime substitution.
- `scripts/pscv0-authoring-proof.mjs`: source/product-bound correspondence proof checks and zero-axiom report.
- `scripts/pscv0-authoring.test.mjs`, `pscv0-arrow.test.mjs`: genuinely generated source/API correspondence and regression cases.

All original69 compiler source files, public host, kernel source/JS adapter, selected seed and toolchain remain pinned. Previous qualified bridge evidence applies to its exact old four-module source, not to the corrected five-module candidate.

Retained compiler: source `2f42a52814f3785ff2d92bd826f6e7fb3eb9bc8a`, run38075437516, artifact11678641329; JS SHA-256 `6cddc3c34c38f1524ef9a355c46b0eb17949c45c54fd59367ea370c1af861ab3`, TypeScript7.0.2, bootstrap Lean4.34.0. No new npm dependencies.

Previous surface qualification: implementation `1ed94be7b1d3c49f11e302464478be76fa299172`, run38098425773 Linux/Windows38 passed but original overall run failed; separate successful RC4 replay38108354566. Full predecessor evidence is preserved in `docs/history/AI_WORK_STATE_BEFORE_FIRST_PS_MODULE.md` and `docs/PSCV0_BRIDGE_CAPABILITIES.json`.

## Limits and continuation

First selected module has no comments; both original and candidate trivia inventories are checked and exact source replay is required. General comment anchoring/formatting is still pending. Do not strip comments to migrate another file. Diagnostics after lowering still use generated-Lean positions; full PS diagnostic remapping remains pending before public source-path promotion.

This is not full PSCV0, complete source migration, independent13-package self-hosting, kernel proof/admission of the entire bridge, or a new C2/C3 fixed point. No public CLI change, npm publication, replacement release ZIP or main merge.

GitHub for all repo reads/writes; cloud CI for execution. No local checkout/build/test, Desktop Commander, force push or kernel edits. Read live HEAD and use expected-HEAD non-force updates. Preserve historical failures and old qualification records; never loosen tests or source baselines merely to obtain a pass. Native checks first; regenerate only when source semantics changed. Update this file with observed run outcomes.
