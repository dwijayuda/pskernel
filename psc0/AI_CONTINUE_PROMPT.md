# Continue PSC0 v7.2 — Complete M3+B

Continue implementation autonomously using repository truth. First read
AI_WORK_STATE.md, the canonical PSCV0_LANGUAGE_REFERENCE_v7.2.md, the existing
roadmap and docs/PSCV0_M3_LEAN_FOUNDATION_AND_EXIT_LEDGER_2026-10-18.md.
Reconcile current refs, complete CI job steps/logs/artifacts and the unmerged
draft PR109 before writes. Do not restart completed work or cancel healthy CI.

## Work contract

Complete all six M3+B exits autonomously through GitHub connectors and GitHub
Linux CI only. No local checkout/files/build/test/compiler or Desktop Commander.
Native portable .lean, official Lean4.35.0
 eb6cafb7290e8bd5f2937522d8d804f58f02bafc. Study pinned source/tests before
substantial design; preserve upstream Apache-2.0 notices. Minimal coherent
validation; no PSKernel-Core/C0, self-hosting or C5. Approved assumptions exactly
propext, Quot.sound, Classical.choice. Wasm GC internally; linear memory only
at explicit ABI boundaries. Never weaken acceptance or enlarge budgets.

**Input-language contract clarified by the user on18 October:** both `.ps`
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

Repo dwijayuda/pskernel. Main psc0/pscv0-v7-native-lean-v1; preparation
psc0/m3-fixedpoint-foundation-20261018. PR109 stays draft/open/unmerged on
psc0/pscv0-v7-m1-parser-ownership-v1. Fresh refs, expected-HEAD non-force writes,
preserve concurrent history. Never supersede/cancel a healthy main Native.
Prep cancel-in-progress:false; keep at most one active and one pending run.


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

Preparation candidate3f7e0491341599cce3e259de640ae09a1b16f526:
run39093165102/job117574003095, RUNNING at this checkpoint. It adds internal
source-owned mutual measures and actual recursive component functionals, using
the existing packing fixture/native oracle. This code is NOT yet qualified.
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

## Foundation identity

Selected Standard:3752 declarations,44 classes,371 ordinary instances,13 defaults.
FNV7907908279927868945; snapshot SHA
855c1945851fc7983481cb271120ab12ceb78537ce6faef61e0b36f87ff99eec;
surface SHA24e975d8e8d8b61df05bcc78a488a7e9f7465f99972577110876f5f4e39d08d5.
The new candidate changes no foundation identity. Retain the frozen pre-Order
authoring boundary. Classical.propDecidable is not an automatic runtime instance.
Standalone PSum has5 declarations,2 rules,0 assumptions,6779 UTF8 bytes and is
still UNSELECTED. Activation requires reviewed strict manifest/surface identities.



Update both handoffs, roadmap and exit ledger at each completed milestone slice.

## Native lambda argument candidate

Pinned Parser.Term.fun has max precedence; Parser.Term.argument accepts it after
native whitespace/indentation. The native adapter now reads fun/lambda bodies in
argument position, sharing ordinary expected-type elaboration. The existing
m3control paired fixture/native oracle includes the call with unchanged outputs;
it remains on the existing five-target execution path. This child is unqualified
until its own preparation and integration complete. Leading-precedence terms
(match/if/let/by) still require grouping in argument position. No grammar change
to .ps, source rewriting or host elaboration is introduced.
