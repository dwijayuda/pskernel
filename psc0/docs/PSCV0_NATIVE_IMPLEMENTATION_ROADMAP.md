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

Latest fully qualified compiler/test SHA and current main:
**18fe0b3e3efd6f63ee0a6d1b0d851e40882fe290**.
All five exact-SHA gates completed SUCCESS: Native39092425439,
M339092425489, F139092425401, F239092425419, F339092425556.
Full run/job/artifact digest receipt:
docs/PSCV0_M3_INTEGRATION_18FE0B3E_2026-10-18.md.
Preparation39091873814/job117570152485 also passed at that exact SHA.
Historicalb95c6293 remains qualified, but is no longer the latest checkpoint.

This qualifies both input routes, ordered binder/section scope, native rich
terms/proofs/data/classes/instances/deriving, mixed modules, local where/WF,
pattern lets, if-let and typed do control. The paired m3parity/m3data/m3control
fixtures share checked Core and equations and execute through the existing
JavaScript, TypeScript, Rust, GC core and component observers. Actual P1 Rust
execution is included. No aggregate runtime count is inferred from job metadata.
Full native syntax parity and source mutual WF remain OPEN.

Preparation3f7e0491341599cce3e259de640ae09a1b16f526 completed SUCCESS:
run39093165102/job117574003095; artifact12123597417; SHA256
1e5791d310d082d311dd782219cabe61f9b76c7313f695edcb87b69a9a39d97a.
The complete log records SOURCE_COMPONENT PASS, including actual source bodies,
refined callbacks, decrease goals and official-kernel fixedpoint equation.
Receipt: docs/PSCV0_M3_SOURCE_COMPONENT_3F7E0491_2026-10-18.md.
This qualifies internal construction only. Main18fe0b3e remains the latest
five-gate runtime checkpoint. Native lambda argument candidate5785ada4 has
preparation39093434191/job117575381994 RUNNING.

The current preparation child builds one shared checked auxiliary, reconstructs
public members in their original parameter order, and derives genuine fix_eq
equations. PreDefinition now shares one exact retained-source equation validator
between singleton and component WF; it stages all genuine definitions before
replacing every retained peer. No reflexive f=f equation or source sidecar alone
grants runtime authority. The existing kernel fixture now checks the three public
members and exact retained-source equations. This child is UNQUALIFIED; source
dispatch, executable recovery and strict PSum activation remain disabled.
The preceding09bcae preparation failed because an unreduced closed dictionary
application falsely retained unused varying arguments. The replacement follows
pinned WF/Rel: establish one fixed codomain and synthesize a single relation
dictionary in the common fixed scope. Per-member dictionary transport is removed.

The body candidate uses actual per-callee dependent callbacks, checks final fixed
arguments in their branch scopes, solves genuine decrease goals, closes and checks
the recursive functional and its fix_eq. It does not activate the public source
dispatcher. Public projections, exact retained-body equations, typed executable
ownership and strict PSum selection are still required.
Fresh refs, complete logs and exact-SHA CI override this checkpoint.

## Current implementation and next work

- SourceKind routes .lean and .ps to their own PsSyntaxProgram parsers, then
  shared scopes, elaboration, official checking, typed erasure, IR and targets.
  Source text is never rewritten and no arbitrary host elaborator is invoked.
- Scope/Binders/section variables elaborate each annotation at the preceding-name
  prefix, following pinned Elab/Binders.lean. Group origin metadata preserves
  receipts and selected captures. Three Lean shadowing refusals and paired Core
  comparisons are qualified. The old invalid shadowing positives were corrected
  with unchanged observations.
- Native data/class/instance/deriving syntax reuses shared field and declaration
  owners. Inferred native method parameters use expected class fields.
- Lean/Declarations owns native local where helpers and raw
  decreasing_by tactic sequences, reusing shared Where/PreDefinition/WF.
- Lean/Control owns native do layout, optional/trailing semicolons,
  dangling else and else-if. Selected bindings/returns/actions, pattern matrices,
  expected effects and continuations stay shared. No new effect family is added.
- One paired fixture now has three exports (m3parity, m3data, m3control) and
  existing five-target observers; all three and the local WF helper are qualified
  across all five integration gates at18fe.

Next actions:
1. Qualify the source component measure/body candidate. Main18fe integration is complete. This reuses the existing retained-source packing fixture;
   no new executable or workflow is added. Build that existing fixture before
   long audits to catch authoring errors early. Exporter source bytes remain
   in complete artifact logs/files; redundant console source dumps are filtered.
   Acceptance checks, runtime lanes and budgets are unchanged.
2. Finish the selected native source adapter audit. Source input parity is broader
   than implementation .lean or oracle .lean coverage. Keep both grammars and all
   assurance boundaries. Once prep passes, promote non-force and retain five gates.
3. Complete source mutual WF with the existing retained-call, fixed-permutation,
   typed PSigma/PSum packing and source-owned measure preparation. Current
   PreDefinitionDispatch deliberately refuses multi-member WF components.
4. Re-elaborate bodies under actual typed dependent callbacks in each branch.
   Infer callback signatures from actual fix; build genuine per-callee injections
   and decrease goals, respecting original captures/arity/returned functions.
   Close public projections and derive exact equations from fix_eq plus checked
   cases/funext. Independently compare retained original bodies; f=f is no runtime
   authority. No temporary global axiom or partialDecl shortcut for total WF.
5. Recover typed public-member execution before erasure. Inspect the complete
   Erasure/WellFounded and Compiler/Api P1 ownership mechanisms before designing
   this boundary; heterogeneous packed result motives cannot simply be assumed
   to have one runtime type. Do not copy a shape-only body rewrite.
6. Reconcile all six M3 exits and qualify one final compiler/test SHA across
   Native, M3, F1, F2 and F3. M3+B remains OPEN. Do not start M4/C5 or relabel
   the historical bounded M2 acceptance as full v7.2 completion.

Pinned source/design references:
docs/PSCV0_M3_NATIVE_INPUT_ROUTING_2026-10-18.md,
docs/PSCV0_M3_RETAINED_CALL_ANALYSIS_2026-10-18.md.
WF study: FixedParams, ArgsPacker, WF/{Main,PackMutual,Rel,Fix,Unfold};
Fix.processSumCasesOn/processPSigmaCasesOn refines callbacks before recursive
replacement. PSC0's existing singleton source re-elaboration preserves the same
branch invariant. The internal source-body component candidate is implemented but not yet qualified.

## Input parity within the existing roadmap

.ps/.lean inputs share selected v7.2 semantics and assurance with their respective
grammars. M3 closes its data/recursion/source capabilities through both inputs;
M4+C/D adds effects/contracts through both; M5+E closes full selected conformance,
readable output and C5. There is no duplicate input-parity roadmap. The source
adapter and historical receipts document implemented and pending distinctions.

## Native lambda argument candidate

Pinned Parser.Term.fun has max precedence; Parser.Term.argument accepts it after
native whitespace/indentation. The native adapter now reads fun/lambda bodies in
argument position, sharing ordinary expected-type elaboration. The existing
m3control paired fixture/native oracle includes the call with unchanged outputs;
it remains on the existing five-target execution path. This child is unqualified
until its own preparation and integration complete. Leading-precedence terms
(match/if/let/by) still require grouping in argument position. No grammar change
to .ps, source rewriting or host elaboration is introduced.
