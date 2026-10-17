# Continue PSC0 v7.2 — Complete M3+B

Read AI_WORK_STATE.md first, then the v7.2 specification, M3 exit ledger and
implementation roadmap. Use live repository state over historical checkpoint text.

Work autonomously through connected GitHub tools and GitHub Linux CI only on
dwijayuda/pskernel. No local checkout/build/test/compiler or Desktop Commander.
Keep portable native .lean, official pinned Lean4.35.0
eb6cafb7290e8bd5f2937522d8d804f58f02bafc, minimal coherent validation, no
PSKernel-Core/C0/self-hosting/C5. Study pinned implementation/tests before each
feature; preserve semantics and architecture, not obsolete internals.
Approved assumptions are exactly propext, Quot.sound, Classical.choice.
Wasm GC inside; linear memory only at explicit ABI boundaries.

Main psc0/pscv0-v7-native-lean-v1 is accepted at
de6679464cac9780bae7066052714c53984dbd00 on Native/M3/F1/F2/F3.
Preparation psc0/m3-fixedpoint-foundation-20261018 holds later source work.
Keep PR109 draft/open/unmerged; attach it in a new chat. Fresh-ref expected-head
non-force writes only; never supersede a healthy main Native run.

Latest candidate adds shared fixed-parameter correspondence, adapted from pinned
FixedParams.Info and used by the singleton WF planner. Its native graph
differential is in the same consolidated packing probe; qualification is pending.
Packing itself passed atb9406c2/run39080316054. Reviewed pin candidate
abe1adc2/run39080406371 has passed strict surface/closure gates and is still
running source checks. Do not infer its final result.

Earlier preparation adds retained exact standalone PSum bytes and portable
Meta/MutualPacking with a focused independent kernel probe. The asset is not
selected, and source mutual WF is still refused. The export was checked at
f58d7e1/run39079183717; packing qualification is pending. Bridge candidate
abfc20d3/run39079996655 passed native signature/closure before its intended
strict digest refusal. The completed run independently measured the exact new FNV/snapshot/surface
digests now published in the strict guards; see work state. Noncomputable
metadata/proof/type erasure passed. Finish full source/runtime qualification.

Current source slice: n-ary WF/shared ordinary applications passed construction,
refusals and five-target emission at5b614f3/run39078823496; target execution
is pending. Extended generic P1 kernel checks passed before an incorrect
helper-privacy fixture assertion. Its correction now checks pinned native
source-helper visibility and hides generated support through the actual
module interface. Noncomputable qualification exposed the already-checked but
unregistered instNonemptyOfInhabited. The current candidate registers/audits
that general bridge; strict manifest pins use the independently observed Linux digests. PSum authoring f58d7e1/run39079183717 passed its export step; fetch
completed logs and exact source bytes. PSum activation/mutual WF are not done.

Continue candidate qualification and reviewed digest publication, then exact-SHA
five-gate integration without confusing emission with runtime parity. Implement
compatible mutual WF using common typed PSum/PSigma packing, original capture/
header ownership, actual decreases/source equations and validated complete
runtime functional. Audit all six M3 exits, including data/elimination,
strategies, total recursion, P0, P1 and integration. Native default induction
refusals for mutual/nested data are intentional; major-dependent constrained
matching is a separate transport question.

Update AI_WORK_STATE.md, this prompt, roadmap and exit ledger at each meaningful
milestone. Keep handoffs concise with exact evidence and remaining work.
Do not weaken criteria, add proof authority, use assumed equations or silently
downgrade verified requests. Do not stop merely to report a passed slice;
stop at complete M3+B or a genuine blocker requiring user intervention.
