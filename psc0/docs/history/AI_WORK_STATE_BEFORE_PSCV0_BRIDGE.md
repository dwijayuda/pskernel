# PSC0 AI work state — PSCV0 source-language adoption review

## New user direction (2026-10-11)

Pause broader architecture expansion long enough to improve compiler authoring. The user wants the verbose bounded `.lean` compiler migrated to readable `.ps`, with a readable `.lean` round trip, while preserving compiler self-hosting. They explicitly select the uploaded **PSCV0 Lean4.35.0-rc4 Expanded Lean-First Unified Language Reference** as the language reference for future PSC0 development, replacing older ProofScript references. **No backwards compatibility with the old `.ps` language is required.**

Selected original upload: `Lean4_ProofScript_PSCV0_Lean435rc4_Expanded_Lean_First_Unified_Language_Reference(2).md`.
SHA-256: `a419955383fd3e35d873f82c939ecf3a92dc65b162cc9d0d3cadf5b853a0f4b0` (230234 bytes).
Upstream target: `v4.35.0-rc4`, commit `c29b6dda4f7c20e3eeaa717c4e565663c5cfa364`.

The full original remains the user's attachment; this review did not commit a verbatim copy. Retrieve that exact file from the task conversation/available file library and verify the digest before implementing. Do not substitute the older reference or reconstruct the full grammar from the summary.

[Adoption identity/policy](docs/PSCV0_REFERENCE_ADOPTION.json).
[Source review, feature ranking, package ownership and migration plan](docs/PSC0_PSCV0_SELFHOST_MIGRATION_REVIEW.md).

## Status: analysis/design adoption, not implemented language migration

Inspected branch `psc0/npm-modular-packages-v1` at `f7b92aa3479cd2c39ce959cab82d69dfb8d969a4`. This task changed only documentation. No compiler/parser/kernel/runtime/seed code, package dependency, qualification baseline or CI workflow changed. No new language-conformance tests or expensive self-host tests were run. `.lean` remains the current implementation source authority and the existing executable still advertises its actual old bounded grammar. It must not be renamed PSCV0-conformant without implementing and qualifying the relevant capability scope.

Old `docs/selfhost-language/CURRENT.md` and SH/1 documents now describe the existing seed and historical qualification, **not the new language-design ceiling**. Preserve their evidence but do not use them to veto the user's new features. Adoption of a design and replacement of an executable parser are different events.

## Recommendation and next implementation slice

1. First retain the exact reference and resolve the small recorded contradictions explicitly (deriving admission, illustrative forbidden gap calls, real Lean comments in adjacency tests, exactly-one-Unit completion).
2. Plan one PSCV0 compiler-workload capability subset: complete selected call/body rules, source-preserving PS/Lean printers, bounded Except-do, known-expected-type conveniences, result projections, nondependent record updates, and simple patterns.
3. Reuse already available Foundation.List helpers (`psListMapExcept` etc.) and current changing-parameter recursion support before introducing new mechanisms. Preserve fuel limits, first-error behavior and full curried signatures.
4. Implement features in portable `.lean` source consumable by the old seed; then generate a bridge compiler. Only afterward let compiler implementation source use the richer features. No permanent JavaScript preprocessing implementation and no hidden native-Lean frontend dependency.
5. Retain rich source intent for both printers; compilation lowers separately. Otherwise `.ps` to `.lean` simply recreates the old verbosity. Upgrade the owned Lean reader for the readable native equivalents.
6. Migrate coherent source families, then switch authoring authority to `.ps`. Old `.lean` seed code stays at historical commits; no two manually maintained source masters and no old `.ps` compatibility/fallback mode.
7. Use focused cached/incremental cloud checks during edits. At promotion, run a deliberate **compiler-only** self-host qualification. The old exact-source inheritance guard cannot prove changed compiler code correct; do not disable or casually repin it. Record a new candidate/seed identity and preserve old receipts.

Do not wait for full dependent matching, general typeclasses/deriving, omega/grind, experimental contracts, let-mut/loop elaboration, every application library, or kernel metatheory to start the readable compiler migration. Those are larger distinct capabilities of the same selected language, not alternate dialects.

## Kernel/version boundary

The current executable checker and bootstrap tools are Lean4.34-based; the new language reference is RC4. Early syntax improvements can target the explicitly tested common term subset, but this does not confer RC4 semantic conformance. Keep the existing checker pinned and coordinate RC4-only declarations/primitives separately. Kernel implementation and proofs remain owned by the other branch; no kernel edits or rebuilds are authorized by this review.

## Existing completed architecture work — preserve, do not restart

The pre-adoption full AI work state is preserved byte-for-byte at [AI_WORK_STATE_BEFORE_PSCV0_ADOPTION.md](docs/history/AI_WORK_STATE_BEFORE_PSCV0_ADOPTION.md), blob `05776241ee82cf07f878e6229c17dae65c720883`.

Latest tested implementation `af6b7727163f57bcf78bbde28d96a878fd82d0f8`, successful run `38089350504`, 100 tests/platform and report attestation; full identities are in that archived state and `docs/PSC0_CI_EVIDENCE_QUALIFICATION.json`. Current compiler: 69 unchanged source files, 64-module bootstrap closure. Historical qualified source `1fa5559a72b293defc56ef7e7020cf82d4b44b79`; retained runtime source `2f42a52814f3785ff2d92bd826f6e7fb3eb9bc8a`; TypeScript7.0.2. That evidence remains valid for its exact old source, not a future changed compiler.

The checked host, bounded frontend, target-toolchain binding, library disclosure, atomic-generation output and signed CI-report verification remain in force. Ordinary source libraries remain data; executable extension support is still not implemented. Optional backend/tactic/application packages must not silently become required proof authorities or fill the default npm install.

## Work process

GitHub is canonical and code execution/qualification uses cloud CI; no repository local checkout/build/test or Desktop Commander. Reading/hash-identifying the supplied attachment is not a repository build. Use live HEAD and expected-HEAD non-force updates, preserve concurrent branches and original references, and do not publish npm or merge main implicitly.

This is an adoption-and-review checkpoint, not authorization to report new PSCV0 conformance or self-host success. The next implementation must state which exact language subset it delivers, retain unsupported-feature diagnostics, and update this state with actual evidence.
