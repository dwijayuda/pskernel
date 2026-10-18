# PSC0 v7.2 AI work state — M3+B

Updated 2026-10-18. Repository and live exact-SHA CI are authoritative.
This concise checkpoint supersedes historical pending narratives in older docs.

## Work contract

Complete all six M3+B exits autonomously through connected GitHub tools and
GitHub Linux CI only. No local checkout/files/build/test/compiler or Desktop
Commander. Portable native .lean; official Lean4.35.0,
eb6cafb7290e8bd5f2937522d8d804f58f02bafc. Study pinned implementations and
tests before design; document adaptations and Apache-2.0 attribution.
Minimal coherent validation; no PSKernel-Core/C0, self-hosting or C5.
Approved assumptions: propext, Quot.sound, Classical.choice. Wasm GC internally;
linear memory only at explicit ABI boundaries. Never weaken acceptance.

Repo dwijayuda/pskernel. Main psc0/pscv0-v7-native-lean-v1.
Prep psc0/m3-fixedpoint-foundation-20261018. PR109 remains draft/open/unmerged.
Fresh-ref expected-head non-force writes. Preserve concurrent history.
Never supersede/cancel a healthy main Native run. Prep concurrency keeps
cancel-in-progress:false; leave healthy work running and avoid excess queueing.

## Exact evidence and current branches

Last complete five-gate acceptance:
de6679464cac9780bae7066052714c53984dbd00.
Native39076409463, focusedM3 39076409661, F1 39076409639,
F2 39076409495, F3 39076409521 all succeeded, reverified live.
Focused backend steps passed, but its whole-job log transport failed; no
measured aggregate count was claimed.

Main has now fast-forwarded to abe1adc2ff96c632dd9ed82b8ae6357832545a32.
Its prep run39080406371/job117536629068 completed SUCCESS.
Main integration is running at that exact SHA:
Native39081215932 and focusedM3 39081215919 are still running.
F1 39081215915, F2 39081215934 and F3 39081216307 completed SUCCESS.
Fetch final Native/M3 results before promotion/claims.

Verified preparation at abe1 includes:
- Exact native instNonemptyOfInhabited signature, no axioms, priority1000;
  strict selected surface, closure and manifest audits.
- N-ary dependent WF packing, shared ordinary named/default/implicit/instance
  applications, exact equations/refusals and five-target emission.
- Extended P1 generic universes, section/helper captures and dependent result,
  independently kernel-checked equations and runtime-body ownership.
- Noncomputable logical ownership, proof/type erasure, imported/private policy,
  direct/transitive/export refusals and five-target emission.
- Standalone exact PSum bytes and kernel-checked typed component packing.
These are construction/emission receipts; target execution awaits main M3.

Prep32af8e2af9e7ed188532fe8e0ae0cf3ebfbd77d3 adds the finite fixed-parameter
graph and singleton integration. Run39080826738/job117538048531 completed
SUCCESS, including the pinned native graph differential and all retained checks.

Candidate03ab1dce70d34c869e226942bba5a9a904029a82 extends saved lexical WF authority to multiple
hygienic callees and records the exact callee on each typed observation.
Lifted captures resolve their current refined lexical binding before ordinary
application completes the original target telescope. Local shadows and bare
recursive-value refusal remain. Decreasing proofs clear all callback authority.
Typed owner analysis now uses actual per-owner headers and branch-scoped calls;
singleton WF uses the same mechanism. Consolidated packing probe adds two
callees, refined captures, shadowing, saved scope, cross-owner reordered headers
and outside-component refusal. Run39081538098/job117539508499 compiled production
and passed retained WF/P1/noncomputable source checks. Only the new packing fixture
failed to parse a nested record at line133. The current candidate fixes its field
layout without changing assertions; the new callback probe remains unqualified.
No source mutual WF acceptance or runtime claim follows from these mechanisms.

The same candidate implements major-dependent constrained matching using ordered
Eq/HEq index and major constraints, existing eq_of_heq after type alignment, and
the shared dependent-context Eq.rec transport. No new foundation declaration.
It substitutes actual free variables before proof-irrelevant equality, following
pinned UnifyEq. The existing match fixture gains fixed-major/context, compound
and repeated-index positives plus a computational dependent callback; missing HEq
still refuses. Group-match observations increase40 to50 across all five lanes.
Preparation adds this existing fixture's kernel/emission check. Qualification is
pending; see docs/PSCV0_M3_HETEROGENEOUS_MATCH_2026-10-18.md.

## Selected foundation

At abe1 strict pins are FNV7907908279927868945,
snapshot SHA855c1945851fc7983481cb271120ab12ceb78537ce6faef61e0b36f87ff99eec,
surface SHA24e975d8e8d8b61df05bcc78a488a7e9f7465f99972577110876f5f4e39d08d5.
The constructive bridge is one ordinary instance registration of an existing
checked theorem, not a new declaration/axiom/primitive. Keep Classical.propDecidable
out of automatic runtime instance selection and retain the frozen Order authoring
boundary. The five-declaration, two-rule, zero-assumption PSum asset is exactly
6779 UTF8 bytes and still UNSELECTED. Its independent export and byte comparison
passed; activation requires reviewed strict manifest identities.

## Remaining work, in dependency order

1. Finish current prep and main CI; distinguish actual runtime comparisons
   from expected counts. P1 now requires40, noncomputable10, and WF includes
   both n-ary and ordinary-application observations. Preserve every prior case.
2. Complete mutual WF using arity-owned PSum/PSigma packing, common fixed
   parameters/permutations, original capture owner/id identities, actual
   measures/relation, branch-scoped decrease proofs and public projections.
   No Bool-tag or two-member shortcut and no provisional axioms.
3. Derive exact public equations from real fix_eq with checked cases/funext;
   independently compare against retained original source bodies. Runtime
   adaptation must validate the complete actual functional and all typed
   callbacks. A kernel-valid f=f cannot authorize replacing an executable body.
   Current multi-member WF refusal stays until this full path is complete.
4. Qualify the current major-dependent constrained matching implementation
   against the pinned Eq/HEq generalization design. Default mutual/nested induction refusals are
   intentional in Lean and remain separate from this real transport question.
5. Reconcile all six exits: data/elimination/deriving, strategies,
   structural/WF, P0, P1, and exact-SHA five-gate integration. M3+B is OPEN.
   Do not drift into M4 effects/contracts or M5 correspondence/C5.

## Source owners and references

Elab/WhereScope, Where, PreDefinition, Command own source scopes, captures,
components and visibility. Elab/PartialFixpoint, Monotonicity and Compiler/Api
own checked P1 and executable adaptation. Elab/FixedParameters,
RecursionParameters, Application, WellFounded, WhereWellFounded,
Meta/MutualPacking, Meta/WellFounded and Erasure/WellFounded own WF.
Environment, Compiler/Api/Pscv0Modules, Erasure, Host/NativeV7 own noncomputable
policy. Consolidated test/Pscv0M3*.lean and scripts/pscv0-m3-runtime.mjs provide
focused source/kernel/backend evidence.

Pinned references: FixedParams, ArgsPacker, WF/{Main,PackMutual,Rel,Fix,Unfold},
PartialFixpoint/{Main,Eqns}, Monotonicity, Init/Internal/Order/Basic,
MutualDef, Where, App, NoncomputableAttr, LCNF/ToLCNF, Meta/Tactic/Cases,
Generalize and Elab/Tactic/Induction. Tests include fixedParamsReorder,
funind_mutual_dep, wfrecUnary, mutual_termination_by_errors, termination_by_where,
partial_fixpoint*, usesOfNoncomputable, noncomputableUnused, optParam,
invalidNamedArgs, inductionMutual and errorOnInductionForNested.
Never copy upstream test_sorry into proof authority.

Roadmap and exit ledger are now consolidated around current architecture and
six exits; obsolete checkpoint narratives remain in Git history at03ab1dce.
The canonical roadmap now correctly records all three approved axioms.

Update this file, AI_CONTINUE_PROMPT.md, roadmap and exit ledger at every
meaningful slice. Stop only at complete M3+B or a genuine user-dependent blocker.
