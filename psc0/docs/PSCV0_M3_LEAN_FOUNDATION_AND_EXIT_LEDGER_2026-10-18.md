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
