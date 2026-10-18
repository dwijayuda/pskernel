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

Candidateade87651 adds checked fixed-scope/per-member header specialization
and shared Where source preparation. Read PSCV0_M3_FIXED_SCOPES_2026-10-18.md.
The existing packing executable validates dependent fixed values, three reordered
generic headers, returned functions, exact kernel equations and intended refusals.
It is pending qualification; no source mutual WF or runtime capability is claimed.

Continue complete mutual-WF source/proof/runtime integration using the shared
PSum/PSigma and fixed-scope owners. Preserve original capture identities, actual
member measures and common relation, branch-scoped decrease evidence, exact
original-body equations and whole-functional runtime validation. A valid f=f
cannot authorize body replacement. PSum remains a retained unselected5-declaration
asset. Source multi-member WF stays refused until the whole path is ready.

Reconcile six M3 exits and qualify Native/M3/F1/F2/F3 at one exact SHA.
Update both handoffs, roadmap and exit ledger each meaningful slice.
Do not stop merely to report a passed slice, weaken assertions or invent counts.

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
