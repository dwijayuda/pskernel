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

Latest fully qualified five-gate compiler/test SHA:
**18fe0b3e3efd6f63ee0a6d1b0d851e40882fe290**.
Native39092425439, M339092425489, F139092425401, F239092425419,
F339092425556 all completed SUCCESS. Receipt:
docs/PSCV0_M3_INTEGRATION_18FE0B3E_2026-10-18.md.

Current main: **5785ada4d0521eaa910a57adc8569dbe95d4c5fe**.
Preparation39093434191/job117575381994 completed SUCCESS; receipt
docs/PSCV0_M3_NATIVE_LAMBDA_5785ADA4_2026-10-18.md.
Native39094184382 and M339094184399 are RUNNING;
F139094184384, F239094184401 and F339094184409 completed SUCCESS.
Never supersede/cancel a healthy main Native. Main was promoted only after
all18fe gates finished. Native lambda argument runtime integration is pending.

Latest fully successful preparation compiler/test SHA:
**6cdb9a6ee36b3262b366d80f36c238b50fd9676d**.
Run39093766354/job117576869290 completed SUCCESS; artifact12124171379,
SHA25624765801ed8ccffd426e1190ed85dd35303be3e4917fdbdc7464779f424b67d2.
Receipt: docs/PSCV0_M3_EXACT_COMPONENT_6CDB9A6E_2026-10-18.md.
The full log confirms real three-member recursive bodies, fixed measures,
refined callbacks, decrease proofs, a shared closed auxiliary, three public
projections and exact retained-source equations checked by the official kernel.
Singleton WF uses the same independent equation validator; all retained checks
and input-parity preparation pass.

Historical3f7e0491 qualified internal bodies/fix_eq before public equations.
Failed09bcae transported an unreduced dictionary application and counted unused
varying arguments as dependencies. That design was removed: pinned WF/Rel first
establishes one fixed codomain, then synthesizes a single dictionary in the fixed
scope. WF/Main31-35 explicitly rejects zero-varying members, matching PSC0.

The public source dispatcher still refuses multi-member WF. Executable recovery
and strict selected PSum activation remain pending. Passing internal constructor
proofs does not establish runtime behavior. M3+B and full selected native grammar
parity remain OPEN. Fresh refs, complete logs and exact-SHA CI override this file.

## Current implementation and next work

Both input kinds have separate surface grammars and share the same v7.2 semantic
pipeline. The qualified paired fixture covers scopes, ordered binder annotations,
defaults, rich terms/proofs, data/classes/instances/deriving, both mixed-module
directions, local where/WF, pattern lets/if-let and typed do. The native lambda
argument child follows Parser.Term.fun maxPrec and argument argPrec; its paired
m3control observations remain6/8. All selected assurance refusals remain.

Mutual WF construction now owns retained source-call analysis, fixed permutations,
original measure scopes, dependent packing, per-callee refined callbacks, decrease
proofs, one shared auxiliary and exact public source equations. PreDefinition
independently reconstructs each RHS from retained Core, shared with singleton WF.
No Eq f=f, sidecar or name alone authorizes runtime. Pinned WF/Main, Basic,
WF/{PackMutual,Rel,Fix,Eqns,Unfold}, ArgsPacker and upstream fixedParams tests were
studied; notices retained.

Next:
1. Finish main5785ada4 integration without canceling healthy jobs. Record exact
   jobs/artifact digests and update both handoffs. The exact-equation preparation
   is green at6cdb9a6e; do not rerun it without new changes or unresolved concerns.
2. Implement total mutual WF executable ownership after auditing the whole
   preparation/RecursorLift/erasure/assurance path. The provisional design is
   docs/PSCV0_M3_MUTUAL_RUNTIME_DESIGN_2026-10-18.md. Derive actual bodies from the
   checked functional, retain/check ordinary private definitions, and independently
   validate executable ownership. Do not use partialDecl for total WF.
3. Activate source dispatch and strict PSum selection only when logical equations,
   executable ownership and paired .ps/.lean source behavior are coherent. Extend
   existing meaningful fixtures/backend observers; no extra bootstrap/self-hosting
   or test proliferation.
4. Finish the selected native input audit and reconcile all six written M3 exits.
   Data/elimination, owned strategies, total recursion, P0, P1 and cross-stage cells
   require actual source/kernel/runtime or intended-refusal evidence. Do not infer
   full completion from isolated examples or old bounded M2 acceptance.
5. Qualify the completed compiler/test SHA across Native, M3, F1/F2/F3 with fresh
   manifests and receipts. M4+C/D and M5+E/C5 remain later roadmap phases.

## Foundation identity

Selected Standard:3752 declarations,44 classes,371 ordinary instances,13 defaults.
FNV7907908279927868945; snapshot SHA
855c1945851fc7983481cb271120ab12ceb78537ce6faef61e0b36f87ff99eec;
surface SHA24e975d8e8d8b61df05bcc78a488a7e9f7465f99972577110876f5f4e39d08d5.
The new candidate changes no foundation identity. Retain the frozen pre-Order
authoring boundary. Classical.propDecidable is not an automatic runtime instance.
Standalone PSum has5 declarations,2 rules,0 assumptions,6779 UTF8 bytes and is
still UNSELECTED. Activation requires reviewed strict manifest/surface identities.



Update both handoffs, roadmap and exit ledger at each completed milestone slice.

Update both handoffs, roadmap and exit ledger at every completed milestone slice.
