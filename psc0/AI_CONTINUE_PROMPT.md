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

Main remains037fda4914ba30b5b8f2074e82ffbf9b0efeef0c. Native39084512384,
M339084512415, F139084512357, F239084512390 and F339084512422 all succeeded
at that SHA. Receipt: docs/PSCV0_M3_INTEGRATION_037FDA49_2026-10-18.md.
**Qualification gap:** the old focused Rust step overwrote the P1 harness before
executing Cargo. Historical job success does not qualify those P1 Rust observations.
The preparation workflow code now executes each harness immediately after generation;
exact-SHA runtime requalification is still required. No aggregate runtime count claimed.

Preparation8f0950c0c918f077ba8a952fb8bc413b519c39b9 /
run39088579549 / job117560230257 completed FAILURE with exactly one failed step:
the native input fixture parsed then as an argument and reported
PSCV0-PARSE: then at9:79; got else. All other steps passed. The complete retained
call-analysis probe executed successfully, including reordered dependent headers,
actual branch/let scopes, full application spines, returned-function arity and
conservative underapplication. PSigma/PSum dependent construction and exact projection
equations passed. These are bounded construction results; source mutual WF stays open.

Keyword correction af9a0e3133601917b3375b8a6e9c1708e9efef18 /
run39088772197 / job117561623591 is still running when this checkpoint is written.
It keeps the native keyword table at native application boundaries. Do not cancel it.
The current preparation child adds native data/dictionary syntax; read its actual
HEAD/run state before continuing. That addition is unqualified until CI completes.

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
Native where/do/full termination grammar and full input parity remain open.

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


Study the relevant pinned Lean4.35.0 source and tests before substantial design.
Work in complete coherent features, inspect the affected subsystem, fix root
causes and use focused validation then retained integration. Do not weaken gates,
expand budgets, introduce temporary logical axioms or use test_sorry as authority.
Preserve upstream Apache-2.0 notices and exact foundation manifests.

M0-M5 and A-E remain interleaved: M2+A → M3+B → M4+C/D → M5+E.
The .ps/.lean input parity obligation follows those same milestones; create no
parallel roadmap and do not confuse C5 source reconstruction with accepted input.
Update this prompt and AI_WORK_STATE.md at every meaningful completed slice,
including exact passed/pending evidence and next concrete work. Continue until
M3+B exits are genuinely satisfied or a user-dependent blocker requires input.
