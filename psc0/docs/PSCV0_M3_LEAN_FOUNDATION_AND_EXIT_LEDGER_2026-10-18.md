# M3+B — approved Lean foundation and completion ledger

## Authority and current state

On 18 October 2026 at 00:50 Asia/Jakarta (17 October 2026 at 17:50 UTC), the user explicitly instructed:

> ok do it, also add other logical axiom that Lean 4 approved if we need, also continue completing M3/B

This authorizes implementing the recommended pinned Lean logical foundation and continuing all selected M3+B work. It supersedes the earlier two-axiom-only implementation restriction. Ordinary development, GitHub changes and Linux CI are authorized; no repeated permission request is needed for this decision.

At authorization, the live branch `psc0/pscv0-v7-native-lean-v1` is `0638879c8ee8b3e265adbe16d8378b51a514229e`. Its qualified compiler/test ancestor is `e6b7f11750fdde6e1feacab86cfb32f2a82be8a5`, with Native, focused M3, F1, F2 and F3 all successful at that exact SHA. Those historical artifacts retain their original two-axiom foundation. This authorization document does not relabel them or claim a newly qualified compiler.

PR #109 stays draft/open/unmerged on `psc0/pscv0-v7-m1-parser-ownership-v1`. The sole source authority remains [v7.2](../PSCV0_LANGUAGE_REFERENCE_v7.2.md). Keep native portable Lean, the official pinned checker, GitHub/cloud Linux execution, expected-HEAD/non-force updates, and all existing runtime/assurance gates.

## Approved logical foundation

Lean is pinned to 4.35.0, commit `eb6cafb7290e8bd5f2937522d8d804f58f02bafc`. Its [standard axiom inventory](https://github.com/leanprover/lean4/blob/eb6cafb7290e8bd5f2937522d8d804f58f02bafc/src/lake/Lake/CLI/Check.lean#L662) contains exactly:

```text
propext
Quot.sound
Classical.choice
```

`propext` and `Quot.sound` are already admitted. The needed addition is the exact pinned [choice declaration](https://github.com/leanprover/lean4/blob/eb6cafb7290e8bd5f2937522d8d804f58f02bafc/src/Init/Prelude.lean#L865):

```lean
axiom Classical.choice {α : Sort u} : Nonempty α → α
```

Approve exact declaration identity, universe telescope, type and provenance. Audit each generated/imported declaration's actual transitive assumptions. Definitions and theorems such as `Classical.choose`, `Classical.ofNonempty`, excluded middle and function extensionality must retain their checked native bodies/proofs and actual dependencies; they are not additional axioms merely because they use classical logic.

The authorization to use other Lean-approved logical axioms is bounded by this pinned standard inventory and demonstrated need. The kernel's generic ability to accept an arbitrary axiom does not make that axiom part of Lean's standard approved foundation. User source axioms, `sorry`/`sorryAx`, unresolved metavariables, uncontrolled native proof escapes and contingent backend/FFI/scheduler assumptions remain unavailable. No runtime intrinsic for `Classical.choice` is introduced.

The official kernel checks each axiom's well-formed type and subsequent declarations relative to the selected foundation; it does not prove the foundational axiom. Record the exact immutable manifest and closure in each new qualified artifact. Existing smaller per-asset assumption closures remain independently checked.

## Implementation work

| Work item | Owner / mechanism | Current status | Required evidence |
| --- | --- | --- | --- |
| FND-1 exact choice foundation | Selected Standard, official replay, StandardManifest, PrimitiveAudit | Qualified at f271f2a3: all five exact-SHA workflows succeeded | Pinned signature, exact native closure, regenerated environment/surface identities, all existing admission refusals |
| P0-1 Nonempty fallback | `Ps.Elab.Mutual.psElabPartialInhabitant` | Qualified five-gate foundation/P0 integration at f271f2a3; exact focused count unconfirmed | Native-compatible constructive-first search and checked Nonempty fallback; body-sensitive execution; opacity and uninhabited-result refusals |
| P1-1 order-library closure | Native authoring export and portable declaration replay | 117-declaration replay, four dictionaries and immutable pins qualified at a53b3651; active and strictly audited at abe1adc2 | Required CCPO/order/monotonicity/fix/equation declarations exported with complete proof/value/type dependencies and official trust-zero replay |
| P1-2 logical elaborator | Typed recursive components and selected fixedpoint consumer | Qualified source/kernel preparation at abe1adc2, including generic/section/helper/dependent cases; all five target lanes passed | Actual functional, order instance, monotonicity proof, checked fixedpoint declaration, retained captures/universes/mutual projections |
| P1-3 exact equations | Pinned fix_eq-based proof construction | Exact source equations independently kernel checked at abe1adc2; all five main gates passed | Generated source equations independently checked; no assumed equations or proof holes |
| P1-4 ordinary implementation | Explicit P1 logical/body ownership and validated runtime view | Complete-layout adapter, adversarial refusals and five-target emission passed at abe1adc2; all five target lanes passed | Original logical graph preserved; exact recursive body selected for ordinary execution; type/telescope/identity checks |
| SRC-1 plain section dictionary | Existing typed predefinition route for unregistered ordinary section definitions | Capture/header/private-equation source checks qualified at a53b3651 / 39073278997 | True no-Where/no-hint native/portable controls, two actual dictionaries, complete capture headers/equations, preserved registration/privacy/theorem policies |

The P1 source consumer is implemented and independently kernel checked, including exact equations and complete-layout executable ownership. The standalone library probe remains authoring evidence only. Native imports, parsed suffixes and unused-hint warnings do not substitute for source/body qualification. The extended runtime matrix passed exact main integration at abe1adc2; its receipt is linked below.

## M3+B exit ledger

Use the [six written milestone exits](PSCV0_NATIVE_IMPLEMENTATION_ROADMAP.md#m3b-detailed-exit--v72) as the completion denominator. A percentage is an engineering estimate only.

| Exit | Remaining required work | Closure condition |
| --- | --- | --- |
| Data and elimination | Selected indexed/dependent/nested/mutual data, motive families, source induction, recursive matching and shared deriving | Required native-positive cases yield checked declarations/proofs and applicable runtime evidence; invalid indices/positivity/elimination/dictionaries retain intended refusals |
| Owned source strategies | Plain section captures; selected heads/modifiers; suffix/local-helper/mutual ownership; selected proof/spec noncomputable behavior | Each selected rule has positive or intended-refusal evidence with exact phase and checked declaration identity |
| Total recursion | Larger changing state packs, supported parameter telescopes and compatible mutual WF | Every accepted recursive call has checked decrease evidence and exact logical equations; body/capture/state handling and runtime observations agree |
| Ordinary partial P0 | Complete selected syntax, admissibility and ordinary body/execution matrix, including Nonempty-only cases | Checked independent inhabitation, logical opacity, actual-body identity and all selected backend/module/erasure checks |
| Selected fixedpoint P1 | FND/P1 work items above | Checked selected fixedpoint semantics, equations, assumptions and ordinary executable ownership across required cases |
| Cross-stage integration | Combined completed surface and retained negative behavior | Every required cell is qualified; Native, focused M3, F1, F2 and F3 succeed at one exact compiler/test SHA; full receipt and handoffs current |

For each remaining case record: source rule, pinned native locator, expected positive/refusal, implementation owner, fixture, proof/assumption evidence, applicable runtime lanes, and exact successful SHA. Do not count a native handler's intentional deriving refusal as a missing positive feature. Do not infer broad completion from isolated successful examples.

## Staging and execution

M3+B covers its selected logical constructions and ordinary execution. General effects and outcome semantics stay in M4+C; contracts, operational models and body relations stay in M4+D; full selected conformance, target correspondence, tooling and C5 stay in M5+E. Missing verified model/refinement evidence continues to reject the requested verified artifact without an ordinary fallback.

Prepare the foundation/library probe early while closing independent source/data/WF/P0 work. Use a separate preparation branch for bounded Linux probes where useful. Do not cancel or supersede a healthy Native run. Final qualification must use one compiler/test SHA and fresh manifests, not a mix of earlier passing gates.


## Current state and evidence

Latest fully qualified five-gate compiler/test SHA:
**5785ada4d0521eaa910a57adc8569dbe95d4c5fe**.
Native39094184382, M339094184399, F139094184384, F239094184401 and
F339094184409 all completed SUCCESS. Receipt:
docs/PSCV0_M3_INTEGRATION_5785ADA4_2026-10-18.md.
Preparation39093434191/job117575381994 also completed SUCCESS.
Native lambda arguments and paired source runtime observations are qualified.
Previous fully qualified18fe0b3e retains its historical receipt. Never cancel or
supersede a healthy main Native; this checkpoint finished before any promotion.

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
1. Main6cdb9a6e is integrating after its successful preparation, promoted only
   after all5785ada4 gates finished. Do not cancel/supersede healthy Native.
   Latest runtime ownership candidate is on preparation; inspect its CI first.
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

## Input parity within the existing roadmap

.ps/.lean inputs share selected v7.2 semantics and assurance with their respective
grammars. M3 closes its data/recursion/source capabilities through both inputs;
M4+C/D adds effects/contracts through both; M5+E closes full selected conformance,
readable output and C5. There is no duplicate input-parity roadmap. The source
adapter and historical receipts document implemented and pending distinctions.

Update both handoffs, roadmap and exit ledger at every completed milestone slice.

## Runtime ownership candidate (qualification pending)

The new candidate adds ordinary checked private WF bodies derived from the actual
logical functional, shared helper restoration with P1, and independent executable
ownership checks. Existing packing validation now covers prepared helper recovery,
complete projection coverage and same-typed private-body forgery refusal. Source
mutual WF dispatch and strict PSum selection remain disabled; this is not backend
execution evidence. Next inspect preparation CI, then activate both source kinds
and qualify the existing backend lanes. Current main is6cdb9a6e; latest fully
qualified five-gate checkpoint remains5785ada4. See runtime design note.
