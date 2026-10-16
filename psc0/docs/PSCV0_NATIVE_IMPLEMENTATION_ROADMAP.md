# PSCV0 native implementation roadmap — v7.2 sole target

Updated 16 October 2026. **The sole forward `.ps` target is [v7.2](../PSCV0_LANGUAGE_REFERENCE_v7.2.md).** No v7/v7.1 compatibility mode, legacy grammar fallback or architectural restart. Apply the user's [stage directive](PSCV0_V72_STAGE_DIRECTIVE_2026-10-16.md) before every new slice. The [migration matrix](PSCV0_V7_TO_V72_MIGRATION_IMPACT_2026-10-16.md) separates actual semantic changes from formatting and specified behavior from implemented/qualified capability.

**M2+A remains COMPLETE for its original `pscv0-v7-native-bounded/73` profile. M3+B is OPEN.** The accepted [M2 exit review](PSCV0_M2_A_EXIT_REVIEW_2026-10-16.md) and [integration receipt](PSCV0_M2_A_INTEGRATION_QUALIFICATION_2026-10-16.md) are unchanged historical evidence, not full v7.2 conformance. Qualified integration2a707206 passed native38832366451, F1 38832366381, F2 38832366374 and F3/F4/platform38832366314; acceptance280e1e4e records its artifact. Do not repeat that integration.

## History and authority

The pre-v7.2 roadmap is preserved byte-for-byte in [pre-v7.2 history](PSCV0_NATIVE_IMPLEMENTATION_ROADMAP_PRE_V72_HISTORY_2026-10-16.md), blob `fe0d2e84f74d1544bfefd6962b1a5c8612c8413e`. Its research and development journals remain separately retained in their dated history files. Historical version selections and pending-run instructions describe their original checkpoints, not current authority. The v7 and v7.1 reference contents and previous adoption manifest are preserved without creating legacy source modes.

## Architecture and trust boundaries

Native portable `.lean`, official Lean4.35.0 `eb6cafb7290e8bd5f2937522d8d804f58f02bafc`. Keep source syntax -> name resolution -> elaboration -> prepared Core -> official checking -> typed erasure -> validated IR -> target emission, retaining the same prepared graph. Study corresponding pinned Lean source/tests before each substantial change. `.lean` retains official Lean source semantics; ProofScript-specific grammar is for `.ps`.

Only `propext` and `Quot.sound` are approved logical assumptions. New source admission does not grant unchecked logical authority. A fixedpoint construction introducing additional classical dependencies remains unavailable under the current policy until explicitly resolved. No sorry, source axioms, unresolved proof/inference holes in emitted artifacts, unapproved dependency closure, weakened tests or enlarged budgets.

JS/TS share the ECMA lowering; retain Rust and Wasm GC, with linear memory only at explicit Canonical ABI boundaries. No pskernel-core, independent kernel, compiler-source `.ps` migration, self-hosting or immediate C5 execution. GitHub/cloud Linux only; preserve branches/history with expected-HEAD/non-force updates. PR109 remains draft/open on its existing base; never merge for milestone acceptance.

## Established dependency order

| Milestone | Shared architecture and selected exit |
| --- | --- |
| M0 | Accepted selected typed-erasure/IR foundation, not entire language |
| M1 | Accepted selected checked indexing/library foundation; preserve laws and boundaries |
| M2+A | Accepted selected constraints/search/defaults/rollback/replay/source retention and library/registry/module/runtime evidence at original profile |
| M3+B | General data/elimination, recursion strategies and deriving, extended by v7.2 partial P0 and selected fixedpoint P1 requirements |
| M4+C | General effects, operational outcome distinctions, ordinary partial execution and restricted typed runtime boundaries |
| M4+D | Contracts, partial/total/trace proof obligations, safe model/body/refinement and assurance identity |
| M5+E | Whole selected v7.2 conformance, dependency/target evidence, tooling/incremental/validated optimization/performance and C5 correspondence |

Continue **M3+B -> M4+C/D -> M5+E**. Collect final-E evidence and performance data throughout; solve measured shared bottlenecks when relevant, not through isolated backend-specific source semantics.

## M2+A acceptance retained, not reopened

All six original selected criteria are accepted: (1) checked indexing and selected libraries; (2) five selected checked deriving handlers and refusals; (3) common scoped constraints/instance keys/default ordering/fresh replay/rollback and measured scaling; (4) retained source scopes, references, inserted evidence and once-only projection resumption; (5) strict declaration and live-surface registry/assumption/provenance audits; (6) complete source/kernel/IR/module/backend/GC/ABI/native-host measurement and history-preserving exact integration qualification. Exact owners and results remain in the original exit review; this migration changes neither those receipts nor their bounded denominator.

That completion is not full data/recursion/deriving, a general semantic-preservation theorem, complete verification, production-speed acceptance or v7.2 conformance. Additional v7.2 obligations below are tracked separately.

## M3+B detailed exit — v7.2

1. **Data and elimination:** selected heterogeneous/indexed/dependent and recursive type formation, nested/mutual inductives, constructor consistency, strict positivity, independent motives and recursive pattern matrices. Preserve invalid-index and elimination refusals and proof/runtime erasure on supported backends. Expand deriving through shared data mechanisms.
2. **Owned source strategies:** implement §0B/§2/§5 declaration-head/modifier matrix and body -> recursion suffix -> where ordering. Preserve total-only const, nullary function ownership and compatible mutual strategy rules. Invalid prefixes, duplicate/mixed strategies and wrong suffix ownership reject at intended rules, not unrelated parse errors.
3. **Total recursion:** structural and well-founded elaboration with checked decreasing evidence and exact logical equations; no partial/unsafe shortcut around totality promised by the declaration or contract.
4. **Partial P0 ordinary source:** selected partial def/function, inhabited-result admissibility, checked body typing and logical opacity, explicit executable-body/dependency identity and supported backend lowering. A partial body is not a definitional equation for proofs. Source parsing alone does not close this criterion.
5. **Selected partial_fixpoint P1:** pinned construction/monotonicity, independently checked generated equations and transitive assumption audit. Keep unsupported models or forbidden classical dependencies unavailable rather than broadening policy. Equations do not by themselves prove executable termination, source/model correspondence or target refinement.
6. **Cross-stage qualification:** source/kernel/IR, positive/negative phase-correct fixtures, preserved module/API/proof erasure and admitted backend execution. Ordinary execution must not acquire a verified label. Verified use with unavailable model/refinement remains rejected. Update both handoffs and exact evidence for each completed slice; full M3 closure requires all selected v7.2 criteria, not just one runtime optimization.

## M4+C effects and executable behavior

Generalize through checked bind/pure and selected StateT/ReaderT/ExceptT and appropriate instances. Cover typed do, mutable/erased state, for/while, early return and selected throw/try/catch/finally, explicit world/IO/FFI boundaries. Accommodate ordinary partial execution without equating Return, Throw, Trap or Diverge. Define failure/effect semantics independently of JavaScript exceptions.

Bare ordinary while may execute only under explicit ordinary admission with no behavioral certificate. Total verified loops require invariant, measure and checked effect/proof rules. Potentially divergent verified loops stay staged until the selected operational finite-trace model and target correspondence exist. Restricted unsafe needs an exact registered typed runtime capability, never proof-producing authority.

## M4+D contracts and assurance

Produce kernel-checked proof terms for selected rewriting/simp/omega/grind and admitted automation. Implement given/requires/ensures, proof-only assert, invariant/decreasing and selected Std.WP/vcgen/spec-tail obligations with traceable ledgers. Contract-bearing ordinary source may not discard an unimplemented or unproved contract.

Distinguish type correctness, partial correctness, total correctness, finite-prefix safety and separately promised liveness/progress/fairness. Opaque partial/unsafe behavior requires a safe checked operational model and a proved relation to the executable body for verified use. A normal-return postcondition alone does not prove safety of a never-returning service.

One `.ps` language has explicit ordinary checked, closed verified and boundary-qualified verified artifact identities. Every emitted artifact must truthfully identify its assurance. **No verified executable while any applicable specification, effect, assumption, dependency, termination/trace, erasure, executable-refinement or target obligation remains open. Never automatically downgrade a verified request to ordinary.** Boundary assumptions must be precise, immutable, disclosed and permitted; strict closed policy rejects unsupported external assumptions.

## M5+E full selected v7.2 conformance

Close source-rule -> positive/negative fixture -> exact phase -> pinned Lean elaborated-term/semantic correspondence -> checked IR/backend matrix. Separate parsing, kernel acceptance, ordinary execution, verified admission and formal target correspondence. Validate transitive assumption/primitive/erasure safety, environment cryptographic identity, public/private modules, JS/TS/Rust/GC/Wasmtime evidence and reproducible version/SHA/artifact records.

Complete incremental compilation, tooling, validated optimization/performance and C5 source reconstruction/correspondence. Only then declare selected core/essential v7.2 complete; the earlier bounded M2 all-green result is insufficient. Compiler-source migration/bootstrap and independent kernel remain separate future tasks.

## Qualified runtime slice and performance limits

The [M3 runtime receipt](PSCV0_M3_RUNTIME_QUALIFICATION_AND_PAIRED_PERFORMANCE_2026-10-16.md) qualifies compiler133af061 and records paired same-runner study38840337837. Actual-AST suspension analysis and generic lowering passed all native and independent workflows; generic Nat/Bool recursion ran100000/50000 steps. The same-runner study found about9.25–10.11x improvement for List-to-Array conversion and smaller head/array gains, **not a meaningful deep-list lookup or reversal improvement**. Do not relabel old247x–3158x native-Lean ratios as compiler throughput, universal language speed, Rust performance or solved production performance.

Next measured work is actual-IR closure/dictionary specialization and safe recursive/direct-call lowering, preserving generic instantiation, scope, evaluation order, failure behavior, persistent representations and stack safety. No source-name special cases or unchecked Number substitution. Keep original benchmarks and add representative workload evidence rather than hiding a regression with changed iterations or budgets.

## Direct-recursive Repr accepted — 16 October 2026

The [Repr qualification receipt](PSCV0_M3_RECURSIVE_REPR_QUALIFICATION_2026-10-16.md) records exact compiler/test commit **4501164e5f1c32e00c81ae98d171e7bf201d1907**. Native38898123679, independent F1 38898123552/F2 38898123501/F3-F4-platform38898123787 and focused recursive deriving38898124015 all passed that commit. The full native pipeline passed all33 reported steps, with none skipped. Artifact identities and digests are in the receipt, not inferred from prior runs.

Repr now handles selected direct uniform nonindexed recursive families through the shared checked induction interface. Exact native-oracle strings for generic Nat/Bool trees passed JS, strict compiled TS, Rust, V8 GC and Wasmtime. The existing Hashable law and refusal cases remain; three Repr refusal cases cover unsupported nested/indexed families and missing independent dictionaries. One obsolete native direct-Repr negative became an unsupported nested-Repr negative while its assertion and intended failure phase were retained. The temporary preparation workflow was removed. Parent58d439's abstracted-motive correction and checked Hashable remain preserved.

**This closes the Repr slice, not M3+B.** Broader recursive BEq/DecidableEq, nested/indexed/mutual data and deriving, motives/patterns, total recursion and selected P0/P1 execution/assurance/fixedpoint obligations remain governed by the unchanged M3 exit above. Current partial logical checking retains an independent inhabitant, public opaque logical self and the actual typed private partial marker; all partial executable admission still fails before erasure. Never execute the inhabitant or infer runtime verification from logical opacity.

No new speedup or general compiler-preservation result is claimed. Continue shared mechanisms and focused qualification from this accepted baseline rather than repeating the completed Repr gate or reopening M2+A.

## Direct-recursive BEq accepted; DecidableEq candidate — 16 October 2026

The [BEq qualification receipt](PSCV0_M3_RECURSIVE_BEQ_QUALIFICATION_2026-10-16.md) accepts compiler **058fb67f1eec12add5adc1b3419644eb7e7363c5**. Native38905476639, F1 38905476304, F2 38905476313, F3/F4/platform38905476451 and focused38905476153 all passed the same commit. All33 native steps passed, none skipped. Exact native/focused artifacts12049320144/12048186682 and their digests are recorded in that receipt.

Selected uniform nonindexed direct-recursive BEq now uses checked left-child comparison hypotheses, right constructor case analysis, independent field dictionaries and no reflexivity/pointer shortcut. Native-oracle comparison masks, a non-reflexive field dictionary, checked defining law and all selected target lanes passed. Two obsolete direct-recursive negatives became unsupported nested cases without changing their rejection assertions or phases. This entry supersedes the historical Repr entry's pending BEq status, not its accepted evidence or the unchanged full M3 exit.

The next [recursive DecidableEq candidate](PSCV0_M3_RECURSIVE_DECEQ_2026-10-16.md) extends the same induction mechanism with actual child decision proofs and existing equality transport. Its native-oracle fixture includes proof-bearing recursion and equality independent of custom BEq. **That new compiler remains unqualified until its own five same-commit workflows pass.** BEq success is not DecidableEq or full M3 acceptance. Broader data/elimination/total recursion/P0/P1 remain open; no new performance improvement is claimed.


## Selected definitional strict-child recursion — accepted 16 October 2026

The [qualification receipt](PSCV0_M3_STRUCTURAL_CHILD_QUALIFICATION_2026-10-16.md) accepts `8e7f18885a3e917fbdf000d7d108842b2cc1f067` after all five same-commit workflows passed. No general source `k + 0` projection inference, arbitrary arithmetic decrease, non-first computed major, broader inductives, partial execution or fixedpoint is implied. M3+B remains OPEN. Its older pending deriving text above is historical; exact recursive DecidableEq is already accepted separately.

### Current candidate: computed strict major after unchanged prefix

The accepted strict-child receipt above remains immutable. Candidate extending first-position-only admission to later explicit parameter positions requires all earlier arguments be identical local binder references, retaining once-only elaboration and dependent telescope checks. A pinned-Lean oracle and exact-phase changing-prefix refusal are included in the existing focused suite; qualification pending. No other M3 exit item is claimed closed.

### Focused qualification correction: changing parameters can be total
The focused 38927587017 candidate compiled and accepted the newly written
`badPrefix(flag, n)` negative, because its changed flag is permitted through
the existing checked changing-argument worker normalization; termination
is controlled by the strictly decreasing structural n, not invariant flag.
Therefore this was a *false negative expectation*, not unsound acceptance.
Do **not** outlaw legitimate changing state to satisfy this fixture.
The same focused suite instead checks `badLaterMajor(flag, Nat.succ(k))`
with an unchanged prefix but a nondecreasing recursive major at a later
argument position; that must reject by the same strict-child rule. Actual
typed-elaboration and proof gates remain intact. Qualification pending.

### Candidate positive evidence — evolving prefix state
The prior `badPrefix` refusal was invalid: recursion may change a prefix
state parameter while strictly decreasing a later major through the
existing checked worker-normalization. Focused 38927983884 successfully
qualified the corrected nondecreasing-later-major refusal at 6fe169bf.
This candidate adds `m3flipPrefix(flag,n)`, an independent pinned-Lean
structural proof, one exact Bool→UInt64 observation for each flag across
existing JS/TS/Rust/GC/Wasmtime lanes, and a checked source equation.
It preserves the conservative once-only computed-major prefix path as
a distinct supported case and leaves unsupported dependent/nested/mutual
recursion unchanged. The full five-gate exact-commit acceptance is pending.

## Accepted M3+B fixed and evolving prefix recursion

Compiler/test `8f8aa47fc3b742488bd1ce4ad15024a63c0b6d4f` passed native 38928344482 (33/33 steps), F1 38928344465, F2 38928344501, F3/F4/platform 38928344471 and focused 38928344644 (pinned Lean / JS / TS / Rust / V8 GC / Wasmtime). Read [exact qualification](PSCV0_M3_PREFIX_RECURSION_QUALIFICATION_2026-10-16.md). Both unchanged-prefix computed child and separately checked evolving-prefix worker normalization are qualified in the selected family. Prior candidate pending statuses are historical. M3+B overall OPEN; source strategy, nested/indexed/mutual data, larger elimination, total well-founded recursion, P0/P1 and full cross-stage exit remain pending.

## New v7.2 M3 total recursion conversion candidate — exact CI pending
This descendant of accepted compiler `8f8aa47f` and docs `88931aa3`
extends the shared, portable `Ps.Meta.NatReduce` conversion with **exact**
open `Nat.sub a 0 ↝ a` (stable Lean 4.35.0 `Init/Prelude.lean`).
It is a definitional right-zero equation, not an arithmetic decreasing
heuristic, and does not admit `Nat.sub k 1` as a structural subterm.

The existing focused independent pinned-Lean oracle and generated application
now exercise `normalizedSubChild`, a checked source unfolding equation and
one additional Bool→UInt64 output per flag in all previously supported lanes.
The new `badSubMajor(Nat.sub(k,1))` negative must reject at the structural
major rule. Existing strict-child, fixed/evolving-prefix, direct-recursive
deriving, benchmark, module, proof, erasure and runtime cases are preserved.
Five exact-commit native/F1/F2/F3-F4/focused workflows are REQUIRED before
admission. No new speedup or entire M3+B closure is claimed.
