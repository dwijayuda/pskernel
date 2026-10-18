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

Activation preparation began at c15c2bc054555ea0a301f7eba6a7ec937f6a3623
(run39096826484). The child also updates both adversarial singleton producer
fixtures to the shared component result interface; their exact forged-source
and returned-function rejection assertions are unchanged. Inspect the newest
preparation SHA before promotion; no source/backend qualification is claimed.

## Shared application continuation correction

Activation preparation c15c2bc0 (run39096826484/job117584917200) built and passed
strict manifests, component kernel/runtime ownership and all other retained
preparation groups. Its paired native source check failed with
PSCV0-WF-ARITY: the recursive call exceeds its source header telescope.
The flat native application supplied returned-function arguments in the same
spine; the old owned-prefix capture incorrectly rejected that suffix, while
chained .ps calls already separated it.

The child returns the unconsumed positional/named suffix from the same generic
ordered application engine. The WF owner constructs/closes exactly the original
header call and genuine decrease proof, then resumes ordinary application on
that actual checked result. It preserves once-only header capture, result
arity, argument order, constraints and expected types. Ordinary completion
explicitly rejects an accidentally unconsumed suffix. No parser rewrite or
second argument elaborator. Reference: pinned Lean4.35.0
Elab/PreDefinition/WF/Fix.lean72–95 and Elab/App.lean's ordered argument engine.
Existing paired fixture/strict checked-Core comparison remains unchanged.
Qualification pending; newest expected-HEAD preparation child is authoritative.

Continuation e9eb8f73 failed compilation only: clearing both generic suffix
lists left the prefix finisher's argument-kind parameter unconstrained. The
child explicitly pins that existing source argument kind to PsSyntaxTerm;
no algorithm, source fixture or acceptance condition changed. Inspect the
child's complete preparation before promotion.

## Checked packing specialization before runtime erasure

Preparation feac89b1 / run39097887649 built and passed all groups except the
paired source/runtime check. Source elaboration and strict checked-Core parity
advanced past the earlier header-spine failure; total-only IR admission failed:
`PSCV0-ERASURE: unknown constant PSum.casesOn (in parityFirst)`.
The exact source assertions remain unchanged.

Runtime recovery now specializes its actual checked packing functional before
constructing the ordinary private implementation. It unfolds only the actual
selected PSum/PSigma casesOn definitions and uses shared registered recursor/
projection iota. Public definitions and logical fixedpoints never delta-reduce.
Non-value beta arguments retain real lets, preserving source evaluation order
and sharing. A result let below the original header preserves returned-function
entry arity. Both the specialized body and its closed private definition are
type checked; the independent prepared-body reconstruction and forged-body/
incomplete-coverage refusals remain active.

Pinned references: Lean4.35.0 eb6cafb7290e8bd5f2937522d8d804f58f02bafc,
Compiler/LCNF/ToLCNF.lean visitCases, Compiler/LCNF/Simp/Main.lean
simpCasesOnCtor?, plus WF/Main and Basic.addAndCompilePartialRec. This is
Core construction using the existing reducer, with upstream notices retained;
no target primitive, runtime PSum dependency, new axiom or budget change.
Qualification is pending the newest preparation; main6cdb remains fully qualified.

Packing specialization f52b4147 failed at compile time only: its pure Boolean
value classifier used a do-style let-else. The child uses an ordinary match;
no algorithm, fixture or acceptance condition changed. Qualification pending.
