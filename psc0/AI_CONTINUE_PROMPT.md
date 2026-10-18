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

Latest fully qualified five-gate compiler/test SHA and current main:
**6cdb9a6ee36b3262b366d80f36c238b50fd9676d**.
Native39095176453, M339095176451, F139095176460, F239095176458 and
F339095176455 all completed SUCCESS. Receipt:
docs/PSCV0_M3_INTEGRATION_6CDB9A6E_2026-10-18.md.
Never cancel or supersede a healthy main Native run.

Latest fully successful preparation compiler/test SHA:
**9b5cc7c7f64bf18e2b1908cbb63fa4db0e60404f**.
Run39095995956/job117582435491 completed SUCCESS; artifact12124459802,
SHA256146bbd763d4b3046e3a803546deae79c08c6d98af4bfb939a1cc604f37395154.
Receipt: docs/PSCV0_M3_RUNTIME_OWNERSHIP_9B5CC7C7_2026-10-18.md.
Actual-functional executable ownership, original headers/returned functions,
prepared helper restoration, complete coverage and forged-body refusals passed.
All original logical and private runtime definitions were checked by the official
kernel. This receipt does not establish mutual WF source/backend execution.

## Current implementation and next work

This child activates source mutual WF through the shared PreDefinition owner.
Both surface grammars produce the same scoped typed blocks; the producer returns
actual auxiliaries/results, while PreDefinition independently reconstructs exact
source equations and derives ordinary checked private implementations. The first
source member owns the shared auxiliary; each member owns its private body.
Compiler recovery independently validates those bodies before typed erasure.
Original admissions and assurance graphs remain intact. Header opening is a
shared dependency leaf, avoiding a producer/runtime import cycle.

The child selects the independently measured five-declaration PSum extension and
strict identities below. Existing paired input/backend fixtures now cover a
three-member polymorphic WF component with reordered dependent parameters and
a returned function, plus ordinary partial P0 and selected fixedpoint P1.
General total-only IR admission and combined ordinary runtime admission are both
exercised. **This activation child is not yet qualified.**

Next:
1. Inspect the complete activation preparation run. Resolve actual invariant
   failures coherently; preserve all existing controls, timeouts and budgets.
2. After preparation passes, integrate its exact compiler/test SHA when main
   Native is idle; qualify Native, M3 and F1/F2/F3. Both input kinds must actually
   execute the new exports in existing JS/TS/Rust/GC/component lanes.
3. Reconcile all six M3 exits against source rules and pinned Lean source/tests.
   Data/elimination, owned strategies, total recursion, P0, P1 and cross-stage
   integration need scoped source/kernel/runtime or intended-refusal evidence.
   M3+B and full selected input parity remain OPEN.
4. Update both handoffs, roadmap and exit ledger at each completed milestone.
   M4+C/D and M5+E/C5 remain later phases; bounded M2 acceptance is historical.

## Foundation identity for the activation child

Selected Standard:3757declarations,44classes,371ordinary instances,13defaults.
FNV3071911941504503432; snapshot SHA
364627b451f83a04064643d29f0fa3bb1bda85eab70d588d3e66755ddc67efe1;
surface SHA9b07ab5dc1ce2e429fb5ebe4dba0e8da5db667d395521718e0a9a65f9e748214.
These exact candidate identities were independently measured by successful9b5
preparation before selection. Main6cdb and preparation9b5 retain the old selected
3752-declaration identity; do not relabel their evidence. PSum adds5declarations,
2rules,0assumptions and one reducibility registration, no runtime primitive.
Keep frozen pre-Order/pre-mutual authoring boundaries. Classical.propDecidable
is not an automatic runtime instance; approved assumptions remain exactly three.

## Scope and design invariants

Canonical v7.2 lines1872–1890 selects function-like mutual blocks (def/function),
not arbitrary native mutual commands. Native mutual inductive syntax is outside
that selected source grammar; internal mutual/nested data APIs retain separately
scoped evidence. Do not expand to unrestricted host Lean.

Pinned WF/Main31–35 rejects zero-varying members. WF/Rel first establishes one
fixed measure codomain and one dictionary in the fixed scope. Runtime recovery
uses disjoint fresh common fixed IDs above original raw headers because local
substitution is ordered. Do not globally change substitution semantics, erase
original source arity or flatten a returned function into the header.
Pinned WF/{Main,PackMutual,Rel,Fix,Eqns,Unfold}, Basic, ArgsPacker and fixedParams
tests are the reference; notices retained. See the runtime design note and
existing exact-component receipt for the independent equation/runtime boundaries.
