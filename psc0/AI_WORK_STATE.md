# PSC0 v7.2 AI work state — 18 October 2026

## Mission and constraints

Complete M3+B autonomously against the six written exits in [the roadmap](docs/PSCV0_NATIVE_IMPLEMENTATION_ROADMAP.md#m3b-detailed-exit--v72) and [the exit ledger](docs/PSCV0_M3_LEAN_FOUNDATION_AND_EXIT_LEDGER_2026-10-18.md). M2+A is complete at 2a7072064974cb0d051a1773a26caf15fc59838b. M3+B is open; M4+C/D and M5+E follow. Do not stop merely because a slice passes.

- GitHub connector and GitHub Linux CI exclusively. Do not clone, build, test or execute the compiler locally; no Desktop Commander workaround.
- Author portable algorithms in native .lean. Official Lean kernel only. No PSKernel-Core, C0, self-hosting, .ps compiler-source conversion, or C5 execution yet.
- Study the exact corresponding Lean 4.35.0 sources and tests before each substantial feature. Pin eb6cafb7290e8bd5f2937522d8d804f58f02bafc. Document important adaptations and upstream licensing.
- Foundation is exactly propext, Quot.sound and Classical.choice, explicitly approved by the user. Do not restore the obsolete two-axiom policy or add further assumptions.
- Keep Wasm GC internally; linear memory only at explicit ABI boundaries. Preserve readable JS/TS/Rust/WIT/WAT outputs and existing later source reconstruction design.
- Inspect whole affected mechanisms, design first, implement coherent features, then validate at meaningful boundaries. Preserve required semantics and evidence, not obsolete internal designs. No fixture-driven acceptance relaxation, silent ordinary fallback, assumed equations or kernel bypass.
- Keep PR109 draft/open/unmerged. Check fresh refs, preserve concurrent history and use expected-HEAD non-force updates. Never cancel or supersede a healthy Native workflow.
- Update this state and AI_CONTINUE_PROMPT.md after each meaningful slice, together with roadmap and exit ledger. Distinguish constructed, kernel checked, runtime observed and formally verified claims.

## Repositories and live checkpoint

Repository: dwijayuda/pskernel.
Main: psc0/pscv0-v7-native-lean-v1.
Preparation: psc0/m3-fixedpoint-foundation-20261018.
PR109 base: psc0/pscv0-v7-m1-parser-ownership-v1.
Canonical specification: PSCV0_LANGUAGE_REFERENCE_v7.2.md.

Last accepted main compiler/test SHA: f271f2a35789b120dbe1a6dcd5a555db44e72134.
Five successful workflows on that same SHA:
- Native39068626607, job117501396980: all34 steps succeeded.
- Focused M3 39068626598, job117501397034.
- F1 39068626634; F2 39068626600; F3 39068626601.

The focused970 total was expected, not observed: repeated log retrieval failed. Do not relabel it as measured. The historical78/100 rubric is an engineering estimate, not coverage or completion.

Main foundation/P0 receipt: [classical integration](docs/PSCV0_M3_CLASSICAL_P0_INTEGRATION_2026-10-18.md).
Preparation reconciled main and prep histories in merge f7c34243e017bf672893f1a624f9d0a1126fc750; do not wholesale merge unrelated branches.

## Qualified P1 preparation; main integration pending

Preparation `e8cb72b8c2bb5b08433b455b66e887f6bf79fcbe` passed [run39075748079](https://github.com/dwijayuda/pskernel/actions/runs/39075748079), job117522420411, in full. Observed: Order asset replay/audits; four portable order dictionaries; nine monotonicity proofs and nonmonotone refusal; retained source/P0/WF/indexed/recursive-deriving checks; four P1 source members in three actual fixedpoint components; exact whole/source equations; official-kernel checks under unchanged2m/20k limits; complete packed runtime ownership; kernel-valid adversarial mismatch and missing-layout refusals; all five exact historical policy-only programs checked logically and never executed; module private-callee/support hiding and explicit public equations; ordinary five-target emission and both verified-assurance refusals.

This checkpoint promotes the same qualified compiler/test content to main for Native/M3/F1/F2/F3 integration. No backend runtime parity or complete M3 claim follows from preparation. The P1 observer adds30 required comparisons. Run all retained cases and report actual totals.

Root causes resolved: correct Lean4.35.0 congrArg Core argument order, retained old policy cases now logical-only positives, native constructor-pattern spelling in the fixture, and fixture-only IO diagnostic syntax. No compiler grammar, proof criterion, negative criterion or budget was weakened. See [P1 design and evidence](docs/PSCV0_M3_PARTIAL_FIXPOINT_ACTIVATION_2026-10-18.md).


## Noncomputable source-policy candidate — 18 October 2026

Main integration is running at de6679464cac9780bae7066052714c53984dbd00. F1 39076409639, F2 39076409495 and F3 39076409521 succeeded; Native39076409463 and focused M3 39076409661 remain running. Do not supersede healthy Native. Last accepted complete five-gate main remains f271f2a35789b120dbe1a6dcd5a555db44e72134.

Preparation now implements noncomputable def/function as source execution policy, retaining unchanged kernel-checked logical declarations. Indexed environment metadata survives preparation, public interfaces, private project closure and source printing; generated helpers inherit ownership. Shared erasure omits these implementations and rejects computational references while permitting erased proof/type uses. Original mutual mains must agree on computability. No new trusted assumption or Standard asset is introduced. The consolidated native/source/import/erasure fixture plans10 runtime comparisons across five targets; compilation, kernel qualification and runtime evidence are pending. See [design and pinned Lean references](docs/PSCV0_M3_NONCOMPUTABLE_2026-10-18.md).

This slice does not close M3+B. Generic/dependent P1 qualification, generalized and mutual WF handling, the remaining selected data/source matrix and exact-SHA five-gate integration remain open.



## Selected P1 Standard identities

The selected Order candidate is independently replayed:3752 declarations,44 classes,370 ordinary instances,13 defaults.
- FNV: fnv1a64:18189421774150997966
- declaration SHA256:19acd30faa99f70362aac15e2e2a65f8fffe69a560e8fc0c329b4d3cc3635312
- surface SHA256:f364e3d926e0c7c198e6807a79d26e389afeb8d2ad1a7fe8761944fa3282a5a3

Order asset:117 declarations,9530 shared nodes,1574504 bytes,6 recursor rules. The frozen pre-Order replay boundary stays separate. Classical.propDecidable is not an ordinary runtime instance. Source noncomputable tags add no Standard declarations or foundation assumptions.

Accepted main before Order:3635 declarations,42 classes,359 ordinary instances,13 defaults; FNV8892060683078164058; declaration SHA85c0bcd0991126d00b7c1ad723182f8a3023bf9dedda79246d8ca1206750b14c; surface SHA22963f394b344142cfcca1584d14eae6286941ebc1d4f0897f05a6c6518da6df. Verify exact live manifest rather than copying this historical identity into a candidate.

## Next work, in dependency order

1. Qualify the noncomputable preparation candidate; current main P1 integration runs at de6679464cac9780bae7066052714c53984dbd00. Read exact failed diagnostics and root causes; retain all acceptance criteria. Preparation is a focused construction/emission gate, not backend runtime parity.
2. Promote a qualified coherent source candidate to main while preserving both histories, then allow Native, focused M3, F1, F2 and F3 to finish on one exact compiler/test SHA. Do not advance main while Native is healthy and running. P1 adds30 required observations; a later noncomputable slice plans10. Preserve all prior cases and report only actual executed totals.
3. Close selected generic/section/capture/dependent-result P1 coverage and actual ordinary runtime evidence. Current P1 uses checked Pi/PProd CCPO lifting, independent flat-order inhabitation, monotonicity, Order.fix/fix_eq and exact source equations. Runtime ownership reconstructs the entire retained functional; a kernel-valid unrelated equality cannot authorize a different body. Exact negative/verified boundaries remain.
4. Generalize total WF argument handling, then compatible mutual WF through the same abstraction. Existing code has explicit-only source calls and exactly-two measured/dependent slots. Keep actual source header ownership, evaluation order, dependent refinement, checked decreases and equations. Use pinned ArgsPacker.Unary's n-ary right-associated PSigma algorithm and WF/PackMutual's PSum component packing; do not flatten a user PSigma field or introduce two-function/three-argument special cases. Check selected PSum foundation availability before using it.
5. Audit all six M3 exits, including data/elimination/deriving matrix and selected modifier/head ownership. Native intentional deriving refusals are not missing positive features. Restricted unsafe requires a registered typed capability and belongs with M4 effects; no universal unsafe escape.
6. Only claim M3+B complete with every selected cell qualified and the final exact-SHA five-gate receipt. Keep M4 model/refinement, full conformance/target proofs and C5 distinct.

## Relevant implementation owners

- Syntax/Pscv0/Commands and ProgramRead: owned heads, suffixes, modifiers and helper syntax.
- Elab/WhereScope, Where, PreDefinition/Basic, PreDefinition, Command: checked source scopes, capture closure, original-main modifier compatibility, dependency components and support visibility.
- Elab/PartialFixpoint and Monotonicity: portable proof-producing P1; Compiler/Api owns its separately validated ordinary runtime view.
- Elab/RecursionParameters, WellFounded, WhereWellFounded; Meta/WellFounded; Erasure/WellFounded: current typed WF planning, proof, source consumer and exact adapter.
- Environment/Basic, Compiler/Api, Compiler/Pscv0Modules and shared Erasure: noncomputable metadata and execution boundary.
- host/NativeV7: immutable request assurance, independent official kernel checking and native target emission.
- test/Pscv0M3*.lean and scripts/pscv0-m3-runtime.mjs: retained conformance/negative/runtime controls.
- .github/workflows/psc0-m3-foundation-preparation.yml and psc0-m3-recursive-deriving.yml: focused Linux gates; native workflow remains the broad integration gate.

Pinned source study already covered PartialFixpoint Main/Eqns, Monotonicity, Init/Internal/Order/Basic, Init/Prelude congrArg/congrFun, Meta/ArgsPacker, WF/PackMutual/Main/Rel, MutualDef, PreDefinition/Basic, App, ResolveName and NoncomputableAttr/LCNF/ToLCNF. Relevant tests include partial_fixpoint, partial_fixpoint_mutual, partial_fixpoint_monotonicity, invalidProjection, usesOfNoncomputable, isNoncomputable, noncomputableUnused, wfrecUnary, wfrec-nat, mutual_termination_by_errors and termination_by_where.

## Historical context

Older checkpoint narratives are preserved in Git history, not repeated as current instructions:
[pre-consolidation work state](https://github.com/dwijayuda/pskernel/blob/e8cb72b8c2bb5b08433b455b66e887f6bf79fcbe/psc0/AI_WORK_STATE.md).
The roadmap, foundation ledger and dated receipts retain detailed older evidence. Prefer current live refs and this checkpoint over historical pending states.
