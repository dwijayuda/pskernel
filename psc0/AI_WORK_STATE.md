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

Main `psc0/pscv0-v7-native-lean-v1` is now
**33676076bcda7b0de5ec1f9803f49b8b1d28a058**.
It was advanced non-forcibly after confirming that all previous main runs were
completed. Integration is running at that exact compiler/test SHA:

| Gate | Run |
| --- | --- |
| Native | 39099546592 |
| M3, including actual paired backend execution | 39099546513 |
| F1 | 39099546493 |
| F2 | 39099546574 |
| F3 | 39099546446 |

These outcomes were pending when this checkpoint was written. Inspect live job
steps and complete logs. Never supersede or cancel a healthy main Native run.
The latest **fully qualified five-gate** SHA remains
6cdb9a6ee36b3262b366d80f36c238b50fd9676d until all five new gates pass.
Its receipt is docs/PSCV0_M3_INTEGRATION_6CDB9A6E_2026-10-18.md.

Preparation **33676076** is fully successful:
run 39098870650, job 117590844318, artifact 12125298815,
SHA256 b5fece53772a2634949b1016eca4ec31e7fc6909c769479ce75a962e59fbcc43.
See docs/PSCV0_M3_SOURCE_MUTUAL_WF_33676076_2026-10-18.md.
This documentation child retains that compiler/test tree; fresh refs override
the checkpoint. Historical runtime-ownership 9b5 and exact-component 6cdb
receipts remain valid within their original scopes.

## Completed preparation slice

Source mutual WF now uses the shared PreDefinition construction owner.
Both grammars elaborate the same typed components. Exact retained-source
equations and ordinary private runtime implementations are independently
checked; runtime recovery independently rederives the actual functional body
after owned helper restoration. Original admissions and assurance graphs stay
intact. Header opening is a shared dependency leaf.

The paired input fixture covers three mutually well-founded functions,
reordered dependent fixed parameters, a returned function, ordinary partial P0,
and selected fixedpoint P1. Strict checked-Core comparison, total-only validated
IR admission, combined ordinary admission, five-target emission, mixed modules
and assurance refusals all passed preparation. Actual new target execution is
the separate M3 integration run above, not established by emission.

The ordered application engine now returns the untouched suffix beyond an owned
source header. WF builds the checked call and decrease proof, then resumes the
ordinary engine on that result. This fixes native flat application versus
ProofScript chained calls without another argument elaborator.

Runtime recovery specializes only actual checked PSum/PSigma packing wrappers
through existing recursor/projection reduction. Public definitions and logical
fixedpoints never unfold. Non-value beta arguments retain real lets; a result
let below the original header preserves returned-function entry arity. The
specialized body and closed implementation are checked before the independent
prepared-body identity test. Forged-body and incomplete-coverage controls pass.
No new target primitive, assumption, timeout or budget.

## Selected foundation

Selected Standard: **3757 declarations, 44 classes, 371 ordinary instances,
13 defaults**. FNV 3071911941504503432; snapshot SHA256
364627b451f83a04064643d29f0fa3bb1bda85eab70d588d3e66755ddc67efe1;
surface SHA256
9b07ab5dc1ce2e429fb5ebe4dba0e8da5db667d395521718e0a9a65f9e748214.
Strict selected audit and independent pinned exporter agree at 33676076.
PSum adds five declarations, two rules, zero assumptions and one reducibility
registration. Preserve frozen pre-Order and pre-mutual authoring boundaries.
Approved assumptions remain exactly propext, Quot.sound and Classical.choice;
Classical.propDecidable is not an automatic runtime instance. Old 6cdb/9b5
artifacts retain their earlier 3752-declaration selected identity.

## Next work in the existing M3+B exits

1. Finish the five exact-SHA integration gates. Confirm the paired exports
   m3parity, m3data, m3control, m3mutual and m3strategies actually execute for both
   input kinds in JS/TS/Rust/Wasm GC/components. Record real run/job/artifact
   identities, not only green workflow labels or emitted files.
2. Continue the six-exit source-rule/native-owner/evidence audit. Data and
   elimination, owned strategies, total recursion, P0, P1 and cross-stage
   integration remain the denominator. M3+B and full selected parity are OPEN.
3. Investigate positive function-valued recursive fields as a coherent data
   capability. Pinned kernel/inductive.cpp opens Pi codomains and rejects
   recursive occurrences in domains; Core/InductiveGroup already constructs
   such field targets and IH telescopes. Source Data currently rejects them.
   Any extension must inspect Term, MutualStructural and Erasure/Recursion
   together: all currently assume direct child fields. Use actual checked IH
   telescopes and ordinary typed application/erasure, not invented hypotheses
   or per-target patches. Research and design only; this feature is not yet
   implemented or qualified.
4. Update both handoffs, roadmap and the exit ledger at every completed slice.
   Continue M3+B -> M4+C/D -> M5+E; do not start self-hosting or C5.

## Scope and pinned implementation references

Canonical v7.2 lines 1870/1874/1929 explicitly retain PS structural-subterm
restrictions; arithmetic n-1 is not structural evidence. Lines 1872–1890 select
function-like mutual source blocks, not native mutual inductive commands.
Equation-style source acceptance remains explicitly pending at line 1819.
Both .ps and .lean inputs share the selected semantics; neither accepts arbitrary
host Lean. Internal mutual/nested data APIs have separately scoped evidence.

Pinned Lean Tactic/Induction.lean 817–838 intentionally rejects default induction
over mutual/nested types. Structural/BRecOn.mkBRecOnConst documents the common
component-universe restriction. Do not misclassify these intended refusals as
missing positives. Meta/PProdN and Structural/IndPred distinguish general Sort
and Prop motives; the current Type-valued source structural owner is narrower.
Acc.rec's explicit large elimination does not imply native automatic structural
elimination into Type. Preserve these distinctions in the remaining audit.

Pinned references studied for this slice: Elab/App; PreDefinition/WF/{Main,
PackMutual,Rel,Fix,Eqns,Unfold}; Basic.addAndCompilePartialRec;
Compiler/LCNF/ToLCNF.visitCases and Simp/Main.simpCasesOnCtor?.
Further data research: kernel/inductive.cpp, Structural/{BRecOn,IndPred,Main},
Meta/PProdN, tests/elab/structuralOverNested.lean and structuralRec1/2.lean.
Retain upstream notices. Fresh common fixed IDs must stay disjoint from original
headers because psElabSubstituteLocals is ordered; do not change its semantics.

## Positive dependent recursive fields — preparation implementation

The next coherent M3+B slice implements positive function-valued constructor
fields through the shared owned frontend and eraser. This preparation commit
is NOT yet qualified. Main remains 33676076: F1/F2/F3 and M3 backend execution
are successful; Native is still running. Do not supersede healthy main Native.

Data traverses Pi codomains in fresh local contexts, rejects recursive family
occurrences in domains, and retains uniform parameter checks. Shared structural
lookup applies a field's actual arguments to its real IH; mutual ownership
selects the source function component only after those arguments. The native
inductive-predicate restriction remains; Acc's explicit large recursor does not
allow automatic Type-valued recursion. No hypothetical IH is manufactured.

Runtime IHs now use typed Core calls with the original declaration identities,
opened Core header, and actual child indices. One field telescope closure
builder serves singleton, mutual and auxiliary structure slots. The inferred
replacement type must match the actual minor IH domain before ordinary erasure.
No backend-specific closure construction, primitive, assumption or budget change.

The existing paired input fixture now covers a positive field with a dependent
proof argument, singleton and reordered-state mutual recursion, an explicit
recursor and consumed proof IH. Both real grammars must agree on declaration
metadata and checked values; a parsed negative field domain must fail positivity.
The existing five-target observers add m3fields; no new test executable or lane.
See docs/PSCV0_M3_POSITIVE_FUNCTION_FIELDS_2026-10-18.md. Next: complete preparation,
inspect existing controls, then integrate this exact code only when main is idle.

Preparation 28e6b4fd / run39100352434 stopped at compilation: StructuralField
needed the existing Refinement dependency that owns psExprAppView. The direct
import is corrected here; no semantic check or acceptance criterion changed.
Full positive-field qualification remains pending.
