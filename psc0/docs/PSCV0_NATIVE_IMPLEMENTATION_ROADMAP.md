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

Latest fully qualified five-gate compiler/test SHA:
**5785ada4d0521eaa910a57adc8569dbe95d4c5fe**.
Native39094184382, M339094184399, F139094184384, F239094184401 and
F339094184409 all completed SUCCESS. Receipt:
docs/PSCV0_M3_INTEGRATION_5785ADA4_2026-10-18.md.
Preparation39093434191/job117575381994 also completed SUCCESS.
Native lambda arguments and paired source runtime observations are qualified.
Previous fully qualified18fe0b3e retains its historical receipt. Never cancel or
supersede a healthy main Native; this checkpoint finished before any promotion.

Latest fully successful preparation compiler/test SHA:
**6cdb9a6ee36b3262b366d80f36c238b50fd9676d**.
Run39093766354/job117576869290 completed SUCCESS; artifact12124171379,
SHA25624765801ed8ccffd426e1190ed85dd35303be3e4917fdbdc7464779f424b67d2.
Receipt: docs/PSCV0_M3_EXACT_COMPONENT_6CDB9A6E_2026-10-18.md.
The full log confirms real three-member recursive bodies, fixed measures,
refined callbacks, decrease proofs, a shared closed auxiliary, three public
projections and exact retained-source equations checked by the official kernel.
Singleton WF uses the same independent equation validator; all retained checks
and input-parity preparation pass.

Historical3f7e0491 qualified internal bodies/fix_eq before public equations.
Failed09bcae transported an unreduced dictionary application and counted unused
varying arguments as dependencies. That design was removed: pinned WF/Rel first
establishes one fixed codomain, then synthesizes a single dictionary in the fixed
scope. WF/Main31-35 explicitly rejects zero-varying members, matching PSC0.

The public source dispatcher still refuses multi-member WF. Executable recovery
and strict selected PSum activation remain pending. Passing internal constructor
proofs does not establish runtime behavior. M3+B and full selected native grammar
parity remain OPEN. Fresh refs, complete logs and exact-SHA CI override this file.

## Current implementation and next work

Both input kinds have separate surface grammars and share the same v7.2 semantic
pipeline. The qualified paired fixture covers scopes, ordered binder annotations,
defaults, rich terms/proofs, data/classes/instances/deriving, both mixed-module
directions, local where/WF, pattern lets/if-let and typed do. The native lambda
argument child follows Parser.Term.fun maxPrec and argument argPrec; its paired
m3control observations remain6/8. All selected assurance refusals remain.

Mutual WF construction now owns retained source-call analysis, fixed permutations,
original measure scopes, dependent packing, per-callee refined callbacks, decrease
proofs, one shared auxiliary and exact public source equations. PreDefinition
independently reconstructs each RHS from retained Core, shared with singleton WF.
No Eq f=f, sidecar or name alone authorizes runtime. Pinned WF/Main, Basic,
WF/{PackMutual,Rel,Fix,Eqns,Unfold}, ArgsPacker and upstream fixedParams tests were
studied; notices retained.

Next:
1. Main6cdb9a6e is integrating after its successful preparation, promoted only
   after all5785ada4 gates finished. Do not cancel/supersede healthy Native.
   Latest runtime ownership candidate is on preparation; inspect its CI first.
2. Implement total mutual WF executable ownership after auditing the whole
   preparation/RecursorLift/erasure/assurance path. The provisional design is
   docs/PSCV0_M3_MUTUAL_RUNTIME_DESIGN_2026-10-18.md. Derive actual bodies from the
   checked functional, retain/check ordinary private definitions, and independently
   validate executable ownership. Do not use partialDecl for total WF.
3. Activate source dispatch and strict PSum selection only when logical equations,
   executable ownership and paired .ps/.lean source behavior are coherent. Extend
   existing meaningful fixtures/backend observers; no extra bootstrap/self-hosting
   or test proliferation.
4. Finish the selected native input audit and reconcile all six written M3 exits.
   Data/elimination, owned strategies, total recursion, P0, P1 and cross-stage cells
   require actual source/kernel/runtime or intended-refusal evidence. Do not infer
   full completion from isolated examples or old bounded M2 acceptance.
5. Qualify the completed compiler/test SHA across Native, M3, F1/F2/F3 with fresh
   manifests and receipts. M4+C/D and M5+E/C5 remain later roadmap phases.

## Input parity within the existing roadmap

.ps/.lean inputs share selected v7.2 semantics and assurance with their respective
grammars. M3 closes its data/recursion/source capabilities through both inputs;
M4+C/D adds effects/contracts through both; M5+E closes full selected conformance,
readable output and C5. There is no duplicate input-parity roadmap. The source
adapter and historical receipts document implemented and pending distinctions.

Update both handoffs, roadmap and exit ledger at every completed milestone slice.

## Runtime ownership candidate (qualification pending)

The new candidate adds ordinary checked private WF bodies derived from the actual
logical functional, shared helper restoration with P1, and independent executable
ownership checks. Existing packing validation now covers prepared helper recovery,
complete projection coverage and same-typed private-body forgery refusal. Source
mutual WF dispatch and strict PSum selection remain disabled; this is not backend
execution evidence. Next inspect preparation CI, then activate both source kinds
and qualify the existing backend lanes. Current main is6cdb9a6e; latest fully
qualified five-gate checkpoint remains5785ada4. See runtime design note.
