# M2+A exit review — 16 October 2026

## Review boundary

Reviewed research implementation `3405c32a7a0fdadb930b8f72c8c95f7ff7c31f53` against `PSCV0_NATIVE_IMPLEMENTATION_ROADMAP.md` (Phase A detailed exit gate and M2/M3/M4/M5 interleaving), the current M2 design notes, selected implementation owners and existing qualification code. This is an evidence inventory, NOT an M2+A completion declaration or a new language specification.

Official source pin remains Lean 4.35.0 `eb6cafb7290e8bd5f2937522d8d804f58f02bafc`. Newer v7.1/v7.2 design documents must be preserved at integration, but do not silently expand the selected executable profile or approved assumptions.

## Exact current qualification

- Implementation: `3405c32a7a0fdadb930b8f72c8c95f7ff7c31f53`, parent `414f08be74489380b7742c6f062e97aa35749789`.
- Native: https://github.com/dwijayuda/pskernel/actions/runs/38823906652 ; job `116726744360`.
- Independent F3/F4/platform dependency review: https://github.com/dwijayuda/pskernel/actions/runs/38823906736 ; job `116726744576`; completed SUCCESS, including all three substantive review steps.
- Latest observed native state at this receipt: compilation, parser/native foundation checks and all preceding frozen asset regeneration steps passed; checked source/Standard qualification was running. Module/backend/Wasmtime/performance results were still pending. Refresh before making any later claim.
- Previous native38821837990 at `be634b576572ab2fa4ba43962abec67f1ee6eec5` passed source and three-module emission, then failed explicit32-bit `checkGetWidth` erasure in the GC qualification step. Those successes do not substitute for the new commit's required gates.

The implementation diff is nine additions and one deletion in `packages/erasure/src/Ps/Erasure/Platform.lean`; other changed files are documentation. Existing tests, expectations, budgets, frozen assets and workflows are unchanged. The change uses the prepared generic Subtype layout rather than a deliberately monomorphic helper. See `PSCV0_M2_PLATFORM_SUBTYPE_LAYOUT_2026-10-16.md` for pinned source study and invariants.

## Criterion-to-owner inventory

| Existing criterion | Owners/evidence inspected | Current conclusion and remaining gate |
| --- | --- | --- |
| Actual checked indexing and selected library boundaries | Roadmap Phase A gate; prior fully qualified f1bb4bb8 baseline; current platform and native fixture inventory | Retain existing proof/optional/bang/lawfulness tests. Current all-target qualification is still required; the baseline does not qualify newly added libraries. |
| Selected deriving: Inhabited, BEq, DecidableEq, Repr, Hashable | `packages/elab/src/Ps/Elab/Deriving.lean` exact five-handler dispatch; `host/src/Ps/Host/StandardManifest.lean` cross-checks independent roster and parser vocabulary; `test/Pscv0NativeTests.lean` `derivingBoundaries` and module-case assertions | Handler inventory and fail-closed boundary checks are present. Official source/kernel and runtime gates must pass. General recursive/indexed/dependent deriving stays with M3+B; do not mark it implemented or add it to this selected exit merely to enlarge the task. |
| M2 shared constraints, scope and replay | `test/Pscv0NativeTests.lean` `syntheticBoundaries`, source-info fixture, pinned default-instance oracle; M2 scheduling/generalized-constraint design notes | Existing checks cover independent term/universe freshening, captured-scope refusal, mandatory-default wakeup, incompatible expected result, exhausted-budget rollback and higher-rank runtime refusal. Full current source gate remains mandatory. This is not a proof of complete Lean elaborator equivalence. |
| M2 instance-key scaling | `packages/meta/src/Ps/Meta/InstanceKey.lean`; `PSCV0_M2_INSTANCE_KEYS_2026-10-16.md` | Structural scoped hash/key construction uses bounded read-only beta/zeta/permitted delta, not primitive index computation. Hash identity is not proof evidence. Existing graph/collision/replay/scaling gates remain mandatory; obtain measured counters from the completed run, not the design text. |
| Operator and decision integration | Independent pinned Lean operator/logic/default oracles at the top of `test/Pscv0NativeTests.lean`; M2 operator/logic design notes | Preserve the isolated global-default theorem/refusal and explicitly typed scalar in the shared runtime application. Current 1069 planned observations are not yet an all-backend pass. |
| M2 source retention, without C5 execution | `test/Pscv0NativeTests.lean` `sourceInfoBoundaries`; `PSCV0_M2_SOURCE_INFO_2026-10-16.md` | Checks require ordered distinct binder IDs, implicit/default/inferred-explicit arguments, resolved global identity, actual constructor ownership, one successful postponed projection occurrence and final expressions contained in saved local scopes. This is retention evidence only, not source reconstruction or round-trip correctness. |
| Comprehensive selected registry | `host/src/Ps/Host/StandardManifest.lean`, both halves | Actual notation dispatch and precedence, deriving parser/handler rosters, tactic handler identity, typed Id/Option/Except selection, class result keys, ordered instances/defaults, approved assumptions, registered axioms and unavailable proof prerequisites are inventoried. Dual declaration hashes plus separate surface-v3 hash are strict. Export final counts/receipts from CI; do not equate a declaration digest with the whole environment manifest. |
| Actual project/module provenance | `StandardManifest.lean` module/interface/profile encoding; `PSCV0_M2_PROFILE_PROVENANCE_2026-10-16.md`; native workflow module commands | Receipt consumes retained compiled interfaces and source identities, imports/visibility, private/own/exposed identities, ordered instances/defaults and target width. Source graph and checked interface receipts are distinct from executable preservation. Current module/linking and all-target gates remain mandatory. |
| Explicit32/64 target words | `test/Pscv0PlatformTests.lean`, `Platform.lean`, unchanged workflow platform lanes | One common35-probe family per target, independent native64 and fixed32 models, generic/partial/captured calls, record/BitVec boundaries, ABI echoes, missing-profile and false-width-theorem refusals. Runtime width must never specialize the logical opaque inhabitant. New getNumBits fix requires execution qualification, not just compilation. |
| Complete milestone integration | Both branch comparisons below; unchanged native and independent workflows | Research green, exit reconciliation, two-parent history-preserving integration, exact-integration native and applicable independent replays, and truthful draft-PR metadata remain outstanding. Never merge PR109. |

## Concurrency: do not copy only a remembered list of files

Inspected development `e6183db9ddeeb532cdad3c3aae8c3396c99574b9`. Relative to `da16d1ddea0a27d1f3b0549146ac6c665683edbb`, its two new commits modify `psc0/README.md` and add `psc0/docs/PSCV0_V72_ITERATIVE_CONSISTENCY_AUDIT_2026-10-16.md` (122 lines).

The actual merge base with research3405c32a is `ac3887d173347d6f39356f93b646976941212b3f`. At the inspection, research was36 commits ahead and37 behind development. Development's changes from this common base are documentation-only, but comprise TEN paths, not just six language-reference files: both handoffs, v7.1/v7.2 references, README, scalar-completion note, roadmap and three audit documents. Reconcile the two status documents and roadmap with the newer research receipts; preserve development's qualified F4 receipt and all six language/reference/README/audit paths. Preserve both commit-parent histories and re-fetch all heads before integrating.

No development ref or PR setting was changed by this review.

## Decision

**M2+A remains OPEN.** Current implementation and test inventory support continuing the coherent qualification, not inventing unrelated feature work or weakening a failing gate. Native/backend completion and an exact integration receipt are still absent at this snapshot. Bounded tests and checked source admission are not a general backend semantic-preservation theorem. Keep later M3+B data/termination, M4+C/D effects/specification/proof automation, and M5/E C5 publication and global integration work separately labeled.
