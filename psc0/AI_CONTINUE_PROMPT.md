# Continue PSC0 v7.2 — Complete M3+B

Read AI_WORK_STATE.md, canonical v7.2, the M3 exit ledger and roadmap.
Live repository/CI overrides this checkpoint. Continue autonomously through
GitHub connectors and GitHub Linux CI only; no local checkout/files/build/test/
compiler or Desktop Commander. Native portable .lean; Lean4.35.0
 eb6cafb7290e8bd5f2937522d8d804f58f02bafc. Study pinned source/tests before
substantial design. Minimal coherent validation, no PSKernel-Core/C0/self-host/C5.
Approved assumptions exactly propext, Quot.sound, Classical.choice. Wasm GC inside;
linear memory only at explicit ABI boundaries.

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

Repo dwijayuda/pskernel, main psc0/pscv0-v7-native-lean-v1, prep
psc0/m3-fixedpoint-foundation-20261018. PR109 draft/open/unmerged on its original
base; attach in a new chat. Fresh refs and expected-head non-force writes only.
Never supersede/cancel a healthy main Native; at most one active/one pending prep.

Main037fda4914ba30b5b8f2074e82ffbf9b0efeef0c is now the last complete
five-gate acceptance: Native39084512384, M3 39084512415, F1 39084512357,
F2 39084512390 and F3 39084512422 all SUCCESS. Exact artifacts and scope:
docs/PSCV0_M3_INTEGRATION_037FDA49_2026-10-18.md. Both attempts to retrieve the
whole focused log failed; no measured aggregate runtime count is claimed.

Preparation3386891/run39084134295/job117547901808 completed SUCCESS for
component-functional construction. Preparationade87651/run39084942848/
job117549579617 completed SUCCESS for fixed scopes and shared source preparation.
These later constructions are not in main037's accepted compiler/test identity.

Retained-call candidatea5287a1b50110d348303e67255ab888711931ff7,
run39085518962/job117551185828, is still running but its existing packing step
failed. The remaining retained checks continue. Full failure diagnostics have
not yet been retrieved; do not promote or claim this candidate qualified.
Diagnose the concrete cause before any correction; preserve the original
acceptance assertions.

Continue complete mutual-WF source/proof/runtime integration using the shared
PSum/PSigma and fixed-scope owners. Preserve original capture identities, actual
member measures and common relation, branch-scoped decrease evidence, exact
original-body equations and whole-functional runtime validation. A valid f=f
cannot authorize body replacement. PSum remains a retained unselected5-declaration
asset. Source multi-member WF stays refused until the whole path is ready.

Reconcile six M3 exits and qualify Native/M3/F1/F2/F3 at one exact SHA.
Update both handoffs, roadmap and exit ledger each meaningful slice.
Do not stop merely to report a passed slice, weaken assertions or invent counts.

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
