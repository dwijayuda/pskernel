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

Main is now b95c629380ba03638a14c708c5c584ef1b8eaf16, promoted non-force from
037fda49 only after complete preparation succeeded. All five integration gates
are RUNNING, not accepted yet:
Native39090324651; M339090324683; F139090324667; F239090324693; F339090324659.
Do not supersede or cancel healthy runs. The last five-gate accepted ancestor
remains037fda49; see docs/PSCV0_M3_INTEGRATION_037FDA49_2026-10-18.md.

Preparation b95c6293 / run39089622847 / job117564131092 is SUCCESS.
Artifact12122063924, SHA256
8924921c8e5c1c8df51be7e57424b2bc6bc8bdb44e89482c7ec7ddd56bac2ab7.
The full log records PSCV0_M3_INPUT_PARITY PASS, retained-call analysis PASS,
dependent component packing PASS, and all retained preparation steps successful.
This covers exact definition/equation comparison, grouped binder shadow refusals,
universe/named/operator/scientific terms, native proofs, data/classes/instances/
deriving, both mixed-module directions, official kernel, five-target emission,
and assurance/noncomputable refusals. Backend runtime observations are PENDING.
Receipt: docs/PSCV0_M3_NATIVE_INPUT_B95C6293_2026-10-18.md.

Preparation code child3b95a506a46c164a63d01017490fe0949d178908 /
run39090023014 / job117565128449 is RUNNING. It adds native where helpers and
explicit decreasing_by tactic syntax using shared recursion/proof owners.
The same paired data export exercises a local well-founded identity helper.
The current documentation-only descendant changes no compiler/test inputs;
the qualification identity for this native-where code is3b95a506.
Fresh refs and complete logs override these checkpoints.

**Historical P1 Rust gap:** the previous focused workflow overwrote its P1
harness before Cargo ran. Preparation includes the producer/run ordering fix;
the new focused integration must confirm actual P1 Rust observations. Prior
workflow success alone is not that evidence. Source mutual WF is still refused.
M3+B and full selected native grammar parity remain OPEN.

## Current implementation

- Explicit sourceKind routes .lean and .ps isolated files and mixed projects to
  their own PsSyntaxProgram parsers, then shared scopes/elaboration/kernel/erasure/
  validated IR and every target. The CLI accepts both extensions. There is no
  source-text conversion, old syntax-module fallback or arbitrary host elaboration.
- Native rich terms share v7 literals, universes, operators, named applications,
  binder groups, projections/indexing and tactic AST. Native application, if,
  match rows, let/have separators and by layout remain grammar-owned.
- Pinned Elab/Binders.lean:136-168,208-235,423-456 processes names sequentially.
  Shared Scope/Binders/section variables now resolve/elaborate each annotation
  at its preceding-name prefix. Source-group origin metadata preserves receipts
  and selected section-capture IDs. Earlier group-wide caching masked shadowing.
  Three native negative controls compiled; the old invalid positives use valid
  nonshadowing names with unchanged observations. Both input refusals stay required.
- New native data/class/instance/deriving adapter shares field-header and
  lambda/ascription construction and attribute registration. Native layout is
  separate from .ps brace/comma/newline grammar. Old ParseLean data dispatch is
  removed from the v7 native program route. Native instance fields infer bare
  parameters from expected class fields. Initial Standard still excludes
  value-form instance declarations and unselected native extensions.
- One existing paired fixture now emits m3parity and m3data from both inputs to
  JS, TS, Rust, Wasm GC core and component. Existing observers compare pinned native
  values. Preparation checks construction/emission; runtime observers run in
  the focused integration workflow. Do not equate emission with execution.

See docs/PSCV0_M3_NATIVE_INPUT_ROUTING_2026-10-18.md and
docs/PSCV0_M3_RETAINED_CALL_ANALYSIS_2026-10-18.md for design/source references.
Native where/decrease grammar is implemented in the pending child. Native do,
remaining selected grammar gaps and full input parity still need reconciliation.

## Remaining work

1. Complete the current preparation qualification, preserving all existing checks.
   Reconcile binder source receipts and both grammar inputs against pinned Lean.
   Update exact evidence in both handoffs, roadmap and exit ledger at each slice.
2. Complete the selected native input syntax using the same semantic owners.
   Do not infer parity from native oracle tests or an extension change.
3. Complete source mutual WF: shared arity-owned PSigma/PSum packing, fixed
   parameter permutations, original captures, actual measures/relation,
   branch-scoped decrease proofs and public projections. Keep multi-member
   source-WF refusal until the whole path is implemented.
4. Derive exact public equations from actual fix_eq with checked cases/funext.
   Compare retained original source bodies independently. Validate actual
   functional/callback types before executable adaptation; f=f is not authority
   to replace a body. Recover typed public members before erasure.
5. Reconcile all six M3 exits: data/elimination/deriving; source strategies;
   structural/WF; P0; P1; same-SHA cross-stage integration. Run Native, focused
   M3, F1, F2, F3 at one final compiler/test SHA. Requalify the P1 Rust lane.
   M3+B is OPEN. Do not start M4 or C5 or relabel the prior bounded M2 qualification.

## Foundation identity

Selected Standard:3752 declarations,44 classes,371 ordinary instances,13 defaults.
FNV7907908279927868945; snapshot SHA
855c1945851fc7983481cb271120ab12ceb78537ce6faef61e0b36f87ff99eec;
surface SHA24e975d8e8d8b61df05bcc78a488a7e9f7465f99972577110876f5f4e39d08d5.
The new candidate changes no foundation identity. Retain the frozen pre-Order
authoring boundary. Classical.propDecidable is not an automatic runtime instance.
Standalone PSum has5 declarations,2 rules,0 assumptions,6779 UTF8 bytes and is
still UNSELECTED. Activation requires reviewed strict manifest/surface identities.


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

