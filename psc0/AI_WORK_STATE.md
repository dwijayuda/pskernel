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

Main `psc0/pscv0-v7-native-lean-v1` and the latest fully qualified compiler/test
SHA are **33676076bcda7b0de5ec1f9803f49b8b1d28a058**. All five required integration
gates succeeded at that exact SHA; no healthy run was cancelled or superseded.

| Gate | Run | Job | Artifact |
| --- | --- | --- | --- |
| Native | 39099546592 | 117592811170 | 12125584016 |
| M3 | 39099546513 | 117592810896 | 12125729084 |
| F1 | 39099546493 | 117592810615 | 12126345791 |
| F2 | 39099546574 | 117592810822 | 12126166657 |
| F3 | 39099546446 | 117592810775 | 12125762304 |

Full artifact digests and scope: docs/PSCV0_M3_INTEGRATION_33676076_2026-10-18.md.
The prep receipt remains docs/PSCV0_M3_SOURCE_MUTUAL_WF_33676076_2026-10-18.md.
Earlier 6cdb and 9b5 receipts retain their original narrower scopes/identities.

## Completed integration slice

Source mutual WF uses the shared PreDefinition construction owner. Both
actual grammars elaborate the same typed components, independently checked
retained equations and ordinary private runtime implementations. Runtime
recovery rederives the actual functional body after owned helper restoration.
Original admissions, graph and assurance boundaries remain intact.

The paired source module covers three mutually well-founded functions,
reordered dependent fixed parameters, a returned function, ordinary partial P0
and selected fixedpoint P1. Checked-Core comparison, total-only IR admission,
combined ordinary admission, mixed modules and assurance refusals passed.
Actual JS/TS/Rust/Wasm-GC/component execution now passed for both input kinds,
including m3parity, m3data, m3control, m3mutual and m3strategies.

The shared ordered application engine retains the untouched suffix beyond an
owned source header. WF constructs the checked call/decrease proof and resumes
ordinary application on its result. Runtime packing specialization uses actual
checked PSum/PSigma definitions and registered iota/projection reduction.
Non-value beta arguments retain real lets; a result let preserves original
returned-function header arity. Independent private-body identity, forged-body
and incomplete-coverage controls remain. No target primitive or budget increase.

## Active preparation — function fields and public source telescopes

Unqualified preparation follows fully qualified main33676076. Fresh refs are
authoritative. At this checkpoint parent69e73ede6ab1d982a1aa4bdb40f55b21188d1ca6
(run39102651449) is still running; this child completes the public recursor
telescope repair. Keep at most one active and one pending preparation run.
Do not promote until preparation is green, or supersede a healthy main Native.

Implemented:
- Positive dependent function fields across Data, singleton/mutual structural
  elaboration, deriving and shared typed recursor erasure. Actual applied child
  indices/arguments and full IH types are checked; negative domains reject.
  Deriving distinguishes direct recursive method IHs from function fields,
  which require ordinary dictionaries. No fabricated function dictionary.
- Native namedPriority versus PS positionalPrefix is explicit syntax intent,
  preserved through shared application, WF argument capture and suffix calls.
  Both grammars keep duplicate/unknown name and PS overlap/placement refusals.
- Prop structural components use checked And/True; other components PProd with
  exact inferred sort validation, singleton identity and actual projections.
  No implicit universe lift or assertion of arbitrary Sort-u support.
- Generated public recursors now use pinned motive/motive_1..., constructor
  minor names, t, field_ih and strict implicit inference over the full telescope.
  Existing Core producers keep complete argument layout. Source Vector/V calls
  use named motives. Group tests compare names/kinds against official Lean in
  addition to existing kernel signature witnesses.

Existing paired input module adds m3fields true192013/false232417, explicit
dependent recursor and induction, singleton/mutual function-field recursion,
Hashable via a real function dictionary, dependent proof-valued mutual
functions and positive-function predicate recursion. Internal mutual-data
fixture covers one/zero owned Prop components. Five-target observers retain
all earlier exports. Native explicit recursor is noncomputable with a checked
agreement theorem to an executable structural oracle; PSC0 inputs must execute
the actual primitive recursor. Symbolic node-hash proof keeps default limits.

Qualification history (no assertions removed):
28e6 missing direct import; 5f49 native generator refused primitive recursor
oracle; f379 source PS argument placement and direct-versus-pointwise deriving
classification; f3e9 concrete hash-oracle proof reduction depth; 64ce actual
native argument placement; a25cadb9/run39102542931 built and passed all other
substantive checks but branchByRec still type-mismatched. Source inspection
located generated _motive explicit instead of native public motive inference.
This child fixes that shared owner; do not label it green before CI.

Designs:
docs/PSCV0_M3_POSITIVE_FUNCTION_FIELDS_2026-10-18.md
docs/PSCV0_M3_NAMED_APPLICATION_PLACEMENT_2026-10-18.md
docs/PSCV0_M3_STRUCTURAL_COMPONENT_PACKING_2026-10-18.md
docs/PSCV0_M3_RECURSOR_SOURCE_TELESCOPES_2026-10-18.md

## Selected foundation

3757 declarations, 44 classes, 371 ordinary instances, 13 defaults.
FNV3071911941504503432; snapshot SHA256
364627b451f83a04064643d29f0fa3bb1bda85eab70d588d3e66755ddc67efe1;
surface SHA2569b07ab5dc1ce2e429fb5ebe4dba0e8da5db667d395521718e0a9a65f9e748214.
Approved assumptions exactly propext, Quot.sound, Classical.choice.
Classical.propDecidable is not an automatic runtime instance. Preserve frozen
pre-Order/pre-mutual authoring boundaries. Historical 6cdb/9b5 used3752.

## Next work within M3+B

1. Qualify current preparation, inspect actual failure causes, and only after
   green preparation plus idle main advance exact code for all five integration
   gates. Keep both handoffs, roadmap and exit ledger synchronized each milestone.
2. Audit/reconcile retained Nat.rec's legacy explicit _motive signature against
   native source behavior in an explicit foundation-metadata slice. Its audited
   bytes/fingerprints are unchanged in this generated-recursor slice. Preserve
   frozen authoring boundaries and independently measure any later update.
3. Implement v7.2 selected named/generalizing matches using existing Match,
   PatternMatrix and dependent refinement. AST currently has no metadata.
   Pinned Elab/Match.generalize defaults true, can disable, and ignores let
   declarations; Meta/Match/Match.withEqs binds Eq/HEq original-to-pattern and
   supplies reflexivity at actual application. Named equations must not enter
   the automatically discharged index-constraint queue. Study branch scopes,
   shadowing, irrefutable/computed/multiple discriminants and indexed transport
   before implementation; no copied host elaborator or fresh matcher.
4. Finish the six-exit source-rule/native-owner/evidence audit. M3+B and full
   selected .lean/.ps input parity remain OPEN. Continue M3+B -> M4+C/D -> M5+E.

Canonical v7.2 retains structural-subterm restrictions and pending equation-style
acceptance. Source mutual blocks select definitions/functions, not mutual data
syntax. Native default mutual/nested induction refusal is intentional; explicit
recursors have separate support. Acc.rec large elimination does not authorize
automatic Type-valued predicate recursion.

Pinned references studied include kernel/{inductive,expr}.cpp, util/name.cpp;
Elab/App, Elab/Match, Parser/Term, Meta/Match/{Basic,Match},
Meta/Match/MatcherApp/Basic; PreDefinition/WF/{Main,PackMutual,Rel,Fix,Eqns,Unfold},
Structural/{BRecOn,IndPred,Main,FindRecArg}; Meta/PProdN,
Meta/Constructions/BRecOn; Elab/{Structure,MutualInductive,Inductive};
Compiler/LCNF/ToLCNF, Simp/Main; Deriving/{Hashable,Repr,BEq,DecEq};
tests/elab/{match1,match2,match3,matchGenIssue,matchGenBug,discrRefinement,
discrRefinement2,structuralOverNested,mutualDefThms,indPredRecursion}.lean.
Preserve upstream notices, official kernel, native .lean, GitHub Linux only.

## Recursor surface audit queued

The existing foundation inventory now compares public recursor binder names and
kinds with the pinned Lean environment, without selecting or changing any asset.
This checks whether the retained Nat mismatch is isolated before a foundation
redesign. Actual mutualLeanSource now explicitly uses the named-interleaved WF
call (n := m), in addition to the native oracle, through source header capture
and returned-function application. No new lane, runtime primitive or budget.

Preparation bba4f8b5/run39103375064 stopped before compiler build because the
new Name helper used Lean's reserved keyword prefix as a binder. Renamed to
originalPrefix; no algorithm or acceptance change. This child remains
unqualified pending complete preparation.
