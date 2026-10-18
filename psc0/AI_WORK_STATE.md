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

## Active preparation — positive dependent recursive fields

Current compiler/test preparation parent is
**f3798882c2b4bc66cf134a53ea90cd75ad1bfe87**; run **39100665889** is pending/running.
This documentation child does not qualify that code. Check fresh refs and jobs.
Keep main33676076 stable until preparation is fully green. Preserve at most one
active and one pending prep run, cancel-in-progress:false, and expected-HEAD
non-force updates. Do not cancel/supersede healthy main Native.

Implemented, not qualified: Data opens positive Pi codomains under fresh locals,
rejects recursive families in domains and retains uniformity. StructuralField
shares actual child-argument lookup; singleton and mutual owners apply those
arguments to the real IH before source component selection. Native predicate
recursion restrictions stay intact. Erasure builds typed Core recursive calls
using original header identities and actual child indices, closes a single
shared field telescope, checks the real minor IH domain and uses ordinary
lambda/call erasure across targets and auxiliary structure slots.

The existing paired fixture adds a field forall(i:Nat), i=i -> ParityBranch,
singleton/mutual state recursion, explicit primitive recursion, and a theorem
consuming its actual IH. Declaration metadata and values compare across actual
inputs. Parsed negative domains must fail positivity. m3fields true=192013,
false=232417 is added to existing backend observers; no new lane/executable.

Preparation28e6b4fd stopped on a missing direct Refinement import, corrected at
5f494f22. That run compiled compiler changes but native code generation refused
the explicit primitive recursor oracle. f3798882 retains its noncomputable
checked definition and proves equality with a separately executable structural
native oracle. PSC0 still must compile and execute the explicit recursor in both
inputs. No positive requirement or negative check was removed.
Design: docs/PSCV0_M3_POSITIVE_FUNCTION_FIELDS_2026-10-18.md.

## Selected foundation

3757 declarations, 44 classes, 371 ordinary instances, 13 defaults.
FNV3071911941504503432; snapshot SHA256
364627b451f83a04064643d29f0fa3bb1bda85eab70d588d3e66755ddc67efe1;
surface SHA2569b07ab5dc1ce2e429fb5ebe4dba0e8da5db667d395521718e0a9a65f9e748214.
Approved assumptions exactly propext, Quot.sound, Classical.choice.
Classical.propDecidable is not an automatic runtime instance. Preserve frozen
pre-Order/pre-mutual authoring boundaries. Historical 6cdb/9b5 used3752.

## Next work within M3+B

1. Complete the positive-field preparation. Inspect full failed-step context if
   necessary; address shared invariants, not fixture-specific patches. Retain
   forged ownership, missing metadata, child family/index, nondecreasing-call,
   predicate elimination and strict negative-positivity controls.
2. Only after preparation is fully green and main idle, advance the exact
   qualified code for Native/M3/F1/F2/F3 integration. Confirm actual execution of
   m3fields on both input paths and all targets. Update these two handoffs,
   roadmap and exit ledger at each completed milestone.
3. Continue the six-exit source-rule/native-owner/evidence audit: data/elimination,
   owned strategies, total recursion, P0, P1, cross-stage integration. M3+B and
   full selected parity remain OPEN. Continue M3+B -> M4+C/D -> M5+E.

Canonical v7.2 retains structural-subterm restrictions (1870/1874/1929), pending
equation-style acceptance (1819), and function-like source mutual blocks
(1872–1890). Internal mutual data APIs have separately scoped evidence. Both
input kinds share selected semantics, never arbitrary host Lean acceptance.
Pinned Tactic/Induction817–838 intentionally rejects default mutual/nested
induction; Structural/BRecOn requires common motive universes. Do not turn those
intended refusals into missing positives. Current source structural packing's
Type-only restriction is narrower than native general Sort/Prop handling; audit
against selected requirements before changing it. Acc.rec explicit large
elimination does not imply automatic Type-valued predicate recursion.

Pinned Lean4.35.0 eb6cafb7290e8bd5f2937522d8d804f58f02bafc references studied:
Elab/App; PreDefinition/WF/{Main,PackMutual,Rel,Fix,Eqns,Unfold};
Compiler/LCNF/ToLCNF and Simp/Main; kernel/inductive.cpp;
Structural/{BRecOn,IndPred,Main,FindRecArg}; Meta/PProdN;
Meta/Constructions/BRecOn; tests/elab/structuralOverNested.lean.
Retain upstream notices. Native portable .lean, official kernel, GitHub/Linux
only; no local checkout/build/test, pskernel-core, self-hosting or immediate C5.

## Function-field qualification follow-up

f3798882 / run39100665889 failed only the source and deriving steps; build,
selected manifest, packing/ownership, indexed cases, Order/P1 and noncomputable
checks passed. Full log retained by its GitHub artifact; no runtime failure was
reported. Causes: the new .ps fixture placed positional arguments after a named
motive (unselected syntax), and old deriving code confused pointwise recursive
fields with direct class-method IHs.

The PS fixture now keeps named motives last. Shared DerivingContext validates
positive field codomains and full actual IH telescopes, but marks only direct
fields for recursive class methods. Pointwise function IHs remain checked and
bound, while ordinary dictionaries handle functions, matching pinned native
Hashable/Repr/BEq/DecEq. Existing negative function-field fixtures now require the
missing-dictionary error instead of the obsolete positive-data refusal. The
paired positive fixture supplies a real function Hashable dictionary, derives
Hashable for ParityBranch and observes the native-equivalent hash as part of
m3fields (expected192013/232417 unchanged). No assertion is dropped.

This child remains unqualified until preparation passes. Main remains fully
qualified33676076. Both handoffs, roadmap and exit receipt were updated at that
completed integration milestone; continue qualification before promoting code.
