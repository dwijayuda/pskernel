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

PSC0's portable compiler is authored in native `.lean` under the v7.2 language
and semantic contract. Use the selected v7.2 capabilities and audited library
closure, retaining a clean path to future readable `.ps` reconstruction.
Native Lean syntax remains native (v7.2 §§2, 11 and 14); `.ps` comma calls and
braced layout are not imposed on `.lean`. Host Lean compiler/elaborator APIs
belong only in the explicit host or independent reference-test boundary.
Do not use unrestricted host functionality to bypass an unavailable portable
capability. This is an authoring/design boundary, not a claim that PSC0 already
self-compiles or that current CI establishes full v7.2 conformance.

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
At this checkpoint main Native39084512384 and M3 39084512415 are running;
F1 39084512357, F2 39084512390 and F3 39084512422 have succeeded.
Do not claim new five-gate acceptance until both running gates finish.
The last complete five-gate receipt remains abe1adc2.

Preparation3386891ffa1852e3c2596bc44f60a986bc7bc095/run39084134295/
job117547901808 is running. The existing packing step completed successfully,
including the new checked mutual functional construction. Whole preparation
is not yet accepted. Source mutual WF remains refused.

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

The current child adds fixed-parameter scope creation and per-member checked
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
