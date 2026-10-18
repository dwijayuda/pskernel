# PSC0 v7.2 AI work state — M3+B

Updated 2026-10-18. Live repository and exact-SHA CI override this checkpoint.

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

## Current evidence

Main is now 037fda4914ba30b5b8f2074e82ffbf9b0efeef0c after complete successful
preparation39083926961/job117546418053. The unchanged riFixedIndexEq rfl
assertion passes through native-style nullary-predicate K computation.
Typed callback scopes, fixed-major Eq/HEq refinement, impossible cases,
complete unary packing and retained WF/P1/noncomputable checks also passed.
At this checkpoint main Native39084512384 is running. FocusedM3 39084512415,
F1 39084512357, F2 39084512390 and F3 39084512422 have succeeded.
Do not claim new five-gate acceptance until Native finishes.
The last complete five-gate receipt remains abe1adc2.

Preparation3386891ffa1852e3c2596bc44f60a986bc7bc095/run39084134295/
job117547901808 completed SUCCESS, including checked mutual functional
construction and all retained checks. Source mutual WF remains refused.

The exact abe1adc2 acceptance is in
docs/PSCV0_M3_INTEGRATION_ABE1ADC2_2026-10-18.md:
Native39081215932, M3 39081215919, F1 39081215915, F2 39081215934 and
F3 39081216307 all successful at abe1adc2ff96c632dd9ed82b8ae6357832545a32.
It qualifies the constructive Nonempty bridge, n-ary dependent WF/ordinary
applications, extended P1 and noncomputable execution across all five lanes.
No measured aggregate runtime count is claimed from required workflow counts.

The previous fad13e51 preparation failed unchanged riFixedIndexEq and an
incorrect PSigma implicit-domain call in the new unary fixture. Generic K
computation—not completed-type transport elision alone—closed the omitted-result
computation gap. The source invocation was corrected with its arity, dependency,
user-PSigma and returned-function requirements unchanged. Exact history remains
in the K/unary design docs and Git; no failed checkpoint is current acceptance.

## Current candidate and next dependency

Candidateade87651 adds fixed-parameter scope creation and per-member checked
specialization, including reordered dependent fixed parameters and returned
functions. It factors existing Where WF preparation into a shared typed record.
See docs/PSCV0_M3_FIXED_SCOPES_2026-10-18.md. Qualification is pending.
The existing packing executable checks three generic reordered headers, exact
kernel equations and malformed-permutation/dependency/value refusals.

The3386891 component construction separates dependent result motives from a
common nondependent measure codomain, validates original member domains, and
infers functional/callback types from the actual checked fixpoint signature.
Its three-member branches are nonrecursive; do not claim source decreases or
runtime adaptation from that construction probe.

## Foundation identity

Selected Standard:3752 declarations,44 classes,371 ordinary instances,13 defaults.
FNV7907908279927868945; snapshot SHA
855c1945851fc7983481cb271120ab12ceb78537ce6faef61e0b36f87ff99eec;
surface SHA24e975d8e8d8b61df05bcc78a488a7e9f7465f99972577110876f5f4e39d08d5.
The new candidate changes no foundation identity. Retain the frozen pre-Order
authoring boundary. Classical.propDecidable is not an automatic runtime instance.
Standalone PSum has5 declarations,2 rules,0 assumptions,6779 UTF8 bytes and is
still UNSELECTED. Activation requires reviewed strict manifest/surface identities.

## Remaining work

1. Finish current preparation and main037 five-gate integration. Preserve the
   healthy Native run. Record actual status and exact artifacts before promotion.
2. Complete source mutual WF using shared arity-owned PSigma/PSum packing,
   common fixed permutations, original capture owner/id identity, actual measures
   and relation, branch-scoped decrease proofs and public projections.
3. Derive exact public equations from actual fix_eq with checked cases/funext;
   independently compare with retained original source bodies. Validate the whole
   actual functional and every typed callback before runtime adaptation. An f=f
   theorem cannot authorize replacing an executable body. Recover typed public
   members before erasure; a PSum-dependent result is not an unknown IR type.
   Keep source multi-member WF refusal until this complete path is implemented.
4. Reconcile all six written M3 exits: data/elimination/deriving, source strategies,
   structural/WF, P0, P1 and same-SHA cross-stage integration. M3+B remains OPEN.
   Intentional native default mutual/nested induction refusals are separate from
   required positive dependent-match capabilities. Do not reopen M2+A or start M4/C5.

## Owners and references

WhereScope/Where/WhereWellFounded/PreDefinition/Command own source scopes,
captures, strategy components, exact source identity and visibility.
FixedParameters/RecursionParameters/Application/WellFounded and
Meta/MutualPacking/MutualWellFounded/WellFounded own parameter analysis,
applications, typed packing/relation/functional construction. Erasure/WellFounded
and Compiler/Api own independently validated executable adaptation.
Match/Equality and Meta/Iota own dependent constraints and native K computation.
PartialFixpoint/Monotonicity and Compiler/Api retain P1 proof/runtime ownership.
Environment/Compiler/Api/Pscv0Modules/Erasure/Host/NativeV7 retain noncomputable policy.

Pinned references: FixedParams; ArgsPacker; WF/{Main,PackMutual,Rel,Fix,Unfold};
PartialFixpoint/{Main,Eqns}; Monotonicity; Init/Internal/Order/Basic; MutualDef;
Where; App; NoncomputableAttr; LCNF/ToLCNF; Meta/Tactic/{Cases,Generalize,Subst,UnifyEq};
Meta/WHNF and kernel/inductive. Tests include fixedParamsReorder, funind_mutual_dep,
wfrecUnary, mutual_termination_by_errors, termination_by_where, partial_fixpoint*,
usesOfNoncomputable, noncomputableUnused, optParam, invalidNamedArgs, eqRecursors,
2552, substWithoutExpectedType, inductionMutual and errorOnInductionForNested.
Never import upstream test_sorry as proof authority.

Update both AI handoffs, roadmap and exit ledger at every meaningful slice.
Stop only at complete M3+B or a genuine user-dependent blocker.

## Latest qualification and current child

Preparation3386891/run39084134295/job117547901808 completed SUCCESS.
The whole component-construction probe and all retained foundation/source/WF/P1/
noncomputable checks passed. Its branches remain nonrecursive; this is not source
mutual-WF admission or executable adaptation.

Scope candidateade87651f3365853702d3f1c733df5e05a1aafae/run39084942848/
job117549579617 is running. Its packing step passed; whole acceptance is pending.
Main037fda49 now has focusedM3 39084512415 and F1/F2/F3 successful; Native
39084512384 is still running. Preserve it. Last complete five-gate acceptance
remains abe1adc2 until that exact run succeeds.

The current child analyzes fixed parameters from the independently rechecked
retained Core source bodies, following pinned FixedParams.getFixedParamsInfo.
It opens real binder/let contexts, observes complete application spines once,
keeps returned-function arguments outside the original header and treats missing
underapplication arguments conservatively as varying. This analysis grants no
recursive-call permission. The existing packing executable adds three source-owned
reordered generic members and independent native controls. Qualification pending.

## Input parity within the existing roadmap

Read docs/PSCV0_V72_INPUT_LANGUAGE_CONTRACT_2026-10-18.md. Atade87651,
Compiler/Api.lean routes .lean through ParseLean into PsSyntaxModule, while
Host/NativeV7.lean uses the Pscv0 PsSyntaxProgram frontend with no explicit source
kind. ParseLean's declaration dispatch is the older def/partial-def/theorem/
inductive/structure selection. Existing .ps qualification therefore does not
establish .lean parity for newer scopes, strategies or mutual declarations.

Close the selected M3+B input-routing/feature gap as part of its existing source
strategy and cross-stage exits. Carry the same two-input obligation through
M4+C/D and M5+E; do not create another roadmap or reopen the historical bounded
M2 acceptance. Use common syntax/semantic owners and paired source fixtures,
not a second elaborator or a text/filename workaround. Do not claim parity before
actual .lean input traverses PSC0's checked pipeline and required backend lanes.
