# PSC0 v7.2 AI work state — M3+B

Updated 2026-10-18. Fresh repository and exact-SHA CI override this checkpoint.

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

Qualified compiler/test HEAD: **b95c629380ba03638a14c708c5c584ef1b8eaf16**.
All five exact-SHA integration gates completed SUCCESS:
Native39090324651, M339090324683, F139090324667, F239090324693,
F339090324659. Complete receipt:
docs/PSCV0_M3_INTEGRATION_B95C6293_2026-10-18.md.
Preparation39089622847/job117564131092 also passed at that exact SHA.

This qualifies source-kind routing; shared ordered binder/section annotation
scope; native rich terms, proofs, data/classes/instances/deriving; both mixed-module
directions; exact paired definition/equation Core comparison; official kernel;
five-target emission and execution; and assurance/noncomputable refusals.
The corrected P1 Rust producer/run ordering is included and the actual Rust
step passed. The full focused log endpoint failed; no aggregate runtime count
is claimed. Old037fda49 is historical evidence, not the latest checkpoint.
Source mutual WF and full selected native grammar parity are still OPEN.

Preparation code HEAD18fe0b3e3efd6f63ee0a6d1b0d851e40882fe290:
run39091873814/job117570152485 is IN PROGRESS. Native where helpers,
termination_by/decreasing_by, pattern lets, if-let, Boolean ! and native typed do
are implemented in that candidate, not yet qualified. It includes native do
as a whitespace/indent-sensitive function argument. Do not promote until the
whole preparation passes. Documentation-only descendants do not change the code
qualification identity. Always refresh refs and complete jobs before writes.

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
- Candidate Lean/Declarations owns native local where helpers and raw
  decreasing_by tactic sequences, reusing shared Where/PreDefinition/WF.
- Candidate Lean/Control owns native do layout, optional/trailing semicolons,
  dangling else and else-if. Selected bindings/returns/actions, pattern matrices,
  expected effects and continuations stay shared. No new effect family is added.
- One paired fixture now has three exports (m3parity, m3data, m3control) and
  existing five-target observers. The qualifiedb95 version has the first two;
  the third and local WF helper belong to the pending candidate.

Next actions:
1. Complete39091873814. Inspect actual diagnostics rather than guessing; retain
   its native proof and source/Core/backend requirements. The previous candidate
   fbcade224 built production but its native fixture attempted HAdd Nat (Id Nat).
   Pinned Init/Control/Id marks Id implicit-reducible; the candidate explicitly
   checks its value at Nat before addition. The earlier where proof now uses
   full simp then rfl and compiled successfully in fbcade224.
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
branch invariant. No new component source algorithm is implemented yet.

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
