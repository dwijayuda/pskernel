# PSCV0 native implementation roadmap — v7.2 sole target

Updated 18 October 2026. **The forward feature/semantic contract for both `.ps` and `.lean` inputs is [v7.2](../PSCV0_LANGUAGE_REFERENCE_v7.2.md), with their respective source syntax.** No v7/v7.1 compatibility mode, legacy grammar fallback or architectural restart. Apply the user's [stage directive](PSCV0_V72_STAGE_DIRECTIVE_2026-10-16.md) before every new slice. The [migration matrix](PSCV0_V7_TO_V72_MIGRATION_IMPACT_2026-10-16.md) separates actual semantic changes from formatting and specified behavior from implemented/qualified capability.

**M2+A remains COMPLETE for its original `pscv0-v7-native-bounded/73` profile. M3+B is OPEN.** The accepted [M2 exit review](PSCV0_M2_A_EXIT_REVIEW_2026-10-16.md) and [integration receipt](PSCV0_M2_A_INTEGRATION_QUALIFICATION_2026-10-16.md) are unchanged historical evidence, not full v7.2 conformance. Qualified integration2a707206 passed native38832366451, F1 38832366381, F2 38832366374 and F3/F4/platform38832366314; acceptance280e1e4e records its artifact. Do not repeat that integration.

## History and authority

The pre-v7.2 roadmap is preserved byte-for-byte in [pre-v7.2 history](PSCV0_NATIVE_IMPLEMENTATION_ROADMAP_PRE_V72_HISTORY_2026-10-16.md), blob `fe0d2e84f74d1544bfefd6962b1a5c8612c8413e`. Its research and development journals remain separately retained in their dated history files. Historical version selections and pending-run instructions describe their original checkpoints, not current authority. The v7 and v7.1 reference contents and previous adoption manifest are preserved without creating legacy source modes.

## Architecture and trust boundaries

Native portable `.lean`, official Lean4.35.0 `eb6cafb7290e8bd5f2937522d8d804f58f02bafc`. Keep source syntax -> name resolution -> elaboration -> prepared Core -> official checking -> typed erasure -> validated IR -> target emission, retaining the same prepared graph. Study corresponding pinned Lean source/tests before each substantial change. **Input-language contract clarified by the user on18 October:** both `.ps`
and `.lean` files supplied to PSC0 follow the selected v7.2 language features,
semantics and assurance rules when compiling to JavaScript, TypeScript, Rust,
Wasm, WAT and other supported artifacts. This concerns compiler INPUTS; it is
not merely an instruction about the compiler implementation's .lean files.
The two source kinds keep their respective surface grammars: native Lean layout
and application in .lean, owned ProofScript spelling in .ps. Both must converge
on shared resolution/elaboration, checked Core, typed erasure, validated IR and
backends. A .lean extension cannot bypass unsupported-feature, dependency,
assumption, recursion or verification rules. Do not silently parse .lean as .ps,
treat arbitrary host Lean as accepted input, or infer input parity from native
reference tests. Record actual support separately until paired qualification
passes. Compiler implementation remains native portable .lean; self-hosting
and immediate C5 stay out of scope.

The approved pinned logical foundation is exactly `propext`, `Quot.sound` and `Classical.choice`, per the user's recorded 18 October authorization in the [M3 exit ledger](PSCV0_M3_LEAN_FOUNDATION_AND_EXIT_LEDGER_2026-10-18.md). Audit exact transitive assumptions; native checked definitions and theorems are not additional axioms. Source admission does not grant unchecked logical authority. No sorry, source axioms, unresolved proof/inference holes in emitted artifacts, unapproved dependency closure, weakened tests or enlarged budgets.

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
5. **Selected partial_fixpoint P1:** pinned construction/monotonicity, independently checked generated equations and transitive assumption audit. Keep unsupported models and dependencies outside the approved pinned foundation unavailable. Equations do not by themselves prove executable termination, source/model correspondence or target refinement.
6. **Cross-stage qualification:** source/kernel/IR, positive/negative phase-correct fixtures, preserved module/API/proof erasure and admitted backend execution. Ordinary execution must not acquire a verified label. Verified use with unavailable model/refinement remains rejected. Update both handoffs and exact evidence for each completed slice; full M3 closure requires all selected v7.2 criteria, not just one runtime optimization.

## M4+C effects and executable behavior

Generalize through checked bind/pure and selected StateT/ReaderT/ExceptT and appropriate instances. Cover typed do, mutable/erased state, for/while, early return and selected throw/try/catch/finally, explicit world/IO/FFI boundaries. Accommodate ordinary partial execution without equating Return, Throw, Trap or Diverge. Define failure/effect semantics independently of JavaScript exceptions.

Bare ordinary while may execute only under explicit ordinary admission with no behavioral certificate. Total verified loops require invariant, measure and checked effect/proof rules. Potentially divergent verified loops stay staged until the selected operational finite-trace model and target correspondence exist. Restricted unsafe needs an exact registered typed runtime capability, never proof-producing authority.

## M4+D contracts and assurance

Produce kernel-checked proof terms for selected rewriting/simp/omega/grind and admitted automation. Implement given/requires/ensures, proof-only assert, invariant/decreasing and selected Std.WP/vcgen/spec-tail obligations with traceable ledgers. Contract-bearing ordinary source may not discard an unimplemented or unproved contract.

Distinguish type correctness, partial correctness, total correctness, finite-prefix safety and separately promised liveness/progress/fairness. Opaque partial/unsafe behavior requires a safe checked operational model and a proved relation to the executable body for verified use. A normal-return postcondition alone does not prove safety of a never-returning service.

Both v7.2 input languages have explicit ordinary checked, closed verified and boundary-qualified verified artifact identities. Every emitted artifact must truthfully identify its assurance. **No verified executable while any applicable specification, effect, assumption, dependency, termination/trace, erasure, executable-refinement or target obligation remains open. Never automatically downgrade a verified request to ordinary.** Boundary assumptions must be precise, immutable, disclosed and permitted; strict closed policy rejects unsupported external assumptions.

## M5+E full selected v7.2 conformance

Close source-rule -> positive/negative fixture -> exact phase -> pinned Lean elaborated-term/semantic correspondence -> checked IR/backend matrix. Separate parsing, kernel acceptance, ordinary execution, verified admission and formal target correspondence. Validate transitive assumption/primitive/erasure safety, environment cryptographic identity, public/private modules, JS/TS/Rust/GC/Wasmtime evidence and reproducible version/SHA/artifact records.

Complete incremental compilation, tooling, validated optimization/performance and C5 source reconstruction/correspondence. Only then declare selected core/essential v7.2 complete; the earlier bounded M2 all-green result is insufficient. Compiler-source migration/bootstrap and independent kernel remain separate future tasks.

## Qualified runtime slice and performance limits

The [M3 runtime receipt](PSCV0_M3_RUNTIME_QUALIFICATION_AND_PAIRED_PERFORMANCE_2026-10-16.md) qualifies compiler133af061 and records paired same-runner study38840337837. Actual-AST suspension analysis and generic lowering passed all native and independent workflows; generic Nat/Bool recursion ran100000/50000 steps. The same-runner study found about9.25–10.11x improvement for List-to-Array conversion and smaller head/array gains, **not a meaningful deep-list lookup or reversal improvement**. Do not relabel old247x–3158x native-Lean ratios as compiler throughput, universal language speed, Rust performance or solved production performance.

Next measured work is actual-IR closure/dictionary specialization and safe recursive/direct-call lowering, preserving generic instantiation, scope, evaluation order, failure behavior, persistent representations and stack safety. No source-name special cases or unchecked Number substitution. Keep original benchmarks and add representative workload evidence rather than hiding a regression with changed iterations or budgets.


## Current state and evidence

Latest fully qualified five-gate compiler/test SHA and current main:
**6cdb9a6ee36b3262b366d80f36c238b50fd9676d**.
Native39095176453, M339095176451, F139095176460, F239095176458 and
F339095176455 all completed SUCCESS. Receipt:
docs/PSCV0_M3_INTEGRATION_6CDB9A6E_2026-10-18.md.
Never cancel or supersede a healthy main Native run.

Latest fully successful preparation compiler/test SHA:
**9b5cc7c7f64bf18e2b1908cbb63fa4db0e60404f**.
Run39095995956/job117582435491 completed SUCCESS; artifact12124459802,
SHA256146bbd763d4b3046e3a803546deae79c08c6d98af4bfb939a1cc604f37395154.
Receipt: docs/PSCV0_M3_RUNTIME_OWNERSHIP_9B5CC7C7_2026-10-18.md.
Actual-functional executable ownership, original headers/returned functions,
prepared helper restoration, complete coverage and forged-body refusals passed.
All original logical and private runtime definitions were checked by the official
kernel. This receipt does not establish mutual WF source/backend execution.

## Current implementation and next work

This child activates source mutual WF through the shared PreDefinition owner.
Both surface grammars produce the same scoped typed blocks; the producer returns
actual auxiliaries/results, while PreDefinition independently reconstructs exact
source equations and derives ordinary checked private implementations. The first
source member owns the shared auxiliary; each member owns its private body.
Compiler recovery independently validates those bodies before typed erasure.
Original admissions and assurance graphs remain intact. Header opening is a
shared dependency leaf, avoiding a producer/runtime import cycle.

The child selects the independently measured five-declaration PSum extension and
strict identities below. Existing paired input/backend fixtures now cover a
three-member polymorphic WF component with reordered dependent parameters and
a returned function, plus ordinary partial P0 and selected fixedpoint P1.
General total-only IR admission and combined ordinary runtime admission are both
exercised. **This activation child is not yet qualified.**

Next:
1. Inspect the complete activation preparation run. Resolve actual invariant
   failures coherently; preserve all existing controls, timeouts and budgets.
2. After preparation passes, integrate its exact compiler/test SHA when main
   Native is idle; qualify Native, M3 and F1/F2/F3. Both input kinds must actually
   execute the new exports in existing JS/TS/Rust/GC/component lanes.
3. Reconcile all six M3 exits against source rules and pinned Lean source/tests.
   Data/elimination, owned strategies, total recursion, P0, P1 and cross-stage
   integration need scoped source/kernel/runtime or intended-refusal evidence.
   M3+B and full selected input parity remain OPEN.
4. Update both handoffs, roadmap and exit ledger at each completed milestone.
   M4+C/D and M5+E/C5 remain later phases; bounded M2 acceptance is historical.

## Foundation identity for the activation child

Selected Standard:3757declarations,44classes,371ordinary instances,13defaults.
FNV3071911941504503432; snapshot SHA
364627b451f83a04064643d29f0fa3bb1bda85eab70d588d3e66755ddc67efe1;
surface SHA9b07ab5dc1ce2e429fb5ebe4dba0e8da5db667d395521718e0a9a65f9e748214.
These exact candidate identities were independently measured by successful9b5
preparation before selection. Main6cdb and preparation9b5 retain the old selected
3752-declaration identity; do not relabel their evidence. PSum adds5declarations,
2rules,0assumptions and one reducibility registration, no runtime primitive.
Keep frozen pre-Order/pre-mutual authoring boundaries. Classical.propDecidable
is not an automatic runtime instance; approved assumptions remain exactly three.

## Scope and design invariants

Canonical v7.2 lines1872–1890 selects function-like mutual blocks (def/function),
not arbitrary native mutual commands. Native mutual inductive syntax is outside
that selected source grammar; internal mutual/nested data APIs retain separately
scoped evidence. Do not expand to unrestricted host Lean.

Pinned WF/Main31–35 rejects zero-varying members. WF/Rel first establishes one
fixed measure codomain and one dictionary in the fixed scope. Runtime recovery
uses disjoint fresh common fixed IDs above original raw headers because local
substitution is ordered. Do not globally change substitution semantics, erase
original source arity or flatten a returned function into the header.
Pinned WF/{Main,PackMutual,Rel,Fix,Eqns,Unfold}, Basic, ArgsPacker and fixedParams
tests are the reference; notices retained. See the runtime design note and
existing exact-component receipt for the independent equation/runtime boundaries.
