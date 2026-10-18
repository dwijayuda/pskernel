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


## Current evidence

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

## Compiler input-language clarification — 18 October 2026

The user clarified that BOTH .ps and .lean compiler inputs follow v7.2; this is not merely a compiler-authoring rule.

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
