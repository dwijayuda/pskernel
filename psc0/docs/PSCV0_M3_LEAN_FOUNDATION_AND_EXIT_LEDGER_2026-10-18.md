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

Latest fully qualified compiler/test SHA: **b95c629380ba03638a14c708c5c584ef1b8eaf16**.
All five exact-SHA integration gates completed SUCCESS:
Native39090324651, M339090324683, F139090324667, F239090324693,
F339090324659. Complete receipt:
docs/PSCV0_M3_INTEGRATION_B95C6293_2026-10-18.md.
Preparation39089622847/job117564131092 also passed at that exact SHA.

This qualifies source-kind routing; shared ordered binder/section annotation
scope; native rich terms, proofs, data/classes/instances/deriving; both mixed-module
directions; exact paired definition/equation Core comparison; official kernel;
five-target emission and execution; and assurance/noncomputable refusals.
The corrected P1 Rust producer/run ordering is included and the actual Rust
step passed. The full focused log endpoint failed; no aggregate runtime count
is claimed. Old037fda49 is historical evidence, not the latest checkpoint.
Source mutual WF and full selected native grammar parity are still OPEN.

Preparation18fe0b3e3efd6f63ee0a6d1b0d851e40882fe290 completed SUCCESS:
run39091873814/job117570152485; artifact12123620366; SHA256
d9070df90395b4c96c96dbdc0c6eb21501ebb9b601582b1446b0d82d85895045.
Its complete log records INPUT_PARITY PASS including native where/WF, pattern
lets, conditional patterns and typed do control, plus all retained checks.
This includes official native reference proofs, paired checked value/equation
comparison and both inputs' five-target emission. Runtime integration is pending.

Main has been promoted non-force to18fe0b3e. Native remains RUNNING; M3, F1, F2 and F3 completed SUCCESS:
 Native39092425439, M339092425489, F139092425401,
F239092425419, F339092425556. Do not supersede/cancel healthy main Native.
The last fully qualified five-gate SHA remainsb95c6293.
Receipt: docs/PSCV0_M3_NATIVE_CONTROL_18FE0B3E_2026-10-18.md.

Preparation09bcae7989e1394c07cfad57e40b783c1b165b44 failed its component
measure check (run39092554668/job117572173163). The source stage applied a
closed dictionary without beta reduction, then counted unused varying arguments
as free dependencies. The replacement follows pinned WF/Rel directly: establish
one fixed measure codomain, then synthesize one dictionary in the common fixed
scope. Per-member dictionary transport is removed.

This preparation child also constructs actual internal source component bodies:
per-callee proof-restricted callbacks, dependent branch refinement, final fixed
argument validation, real decrease goals and closed typed component branches.
The existing three-member packing fixture now independently checks the resulting
recursive functional and its genuine fix_eq with the official kernel. These new
checks are PENDING; no public mutual-WF acceptance or runtime authority is claimed.
The source dispatcher remains fail-closed pending public projections, exact
retained-body equations, executable ownership and selected PSum activation.

## Current implementation and next work

- SourceKind routes .lean and .ps to their own PsSyntaxProgram parsers, then
  shared scopes, elaboration, official checking, typed erasure, IR and targets.
  Source text is never rewritten and no arbitrary host elaborator is invoked.
- Scope/Binders/section variables elaborate each annotation at the preceding-name
  prefix, following pinned Elab/Binders.lean. Group origin metadata preserves
  receipts and selected captures. Three Lean shadowing refusals and paired Core
  comparisons are qualified. The old invalid shadowing positives were corrected
  with unchanged observations.
- Native data/class/instance/deriving syntax reuses shared field and declaration
  owners. Inferred native method parameters use expected class fields.
- Lean/Declarations owns native local where helpers and raw
  decreasing_by tactic sequences, reusing shared Where/PreDefinition/WF.
- Lean/Control owns native do layout, optional/trailing semicolons,
  dangling else and else-if. Selected bindings/returns/actions, pattern matrices,
  expected effects and continuations stay shared. No new effect family is added.
- One paired fixture now has three exports (m3parity, m3data, m3control) and
  existing five-target observers. The qualifiedb95 version has the first two;
  the third and local WF helper are prep-qualified at18fe; runtime gates are pending.

Next actions:
1. Qualify the source component measure/body candidate while main18fe
   integration runs. This reuses the existing retained-source packing fixture;
   no new executable or workflow is added. Build that existing fixture before
   long audits to catch authoring errors early. Exporter source bytes remain
   in complete artifact logs/files; redundant console source dumps are filtered.
   Acceptance checks, runtime lanes and budgets are unchanged.
2. Finish the selected native source adapter audit. Source input parity is broader
   than implementation .lean or oracle .lean coverage. Keep both grammars and all
   assurance boundaries. Once prep passes, promote non-force and retain five gates.
3. Complete source mutual WF with the existing retained-call, fixed-permutation,
   typed PSigma/PSum packing and source-owned measure preparation. Current
   PreDefinitionDispatch deliberately refuses multi-member WF components.
4. Re-elaborate bodies under actual typed dependent callbacks in each branch.
   Infer callback signatures from actual fix; build genuine per-callee injections
   and decrease goals, respecting original captures/arity/returned functions.
   Close public projections and derive exact equations from fix_eq plus checked
   cases/funext. Independently compare retained original bodies; f=f is no runtime
   authority. No temporary global axiom or partialDecl shortcut for total WF.
5. Recover typed public-member execution before erasure. Inspect the complete
   Erasure/WellFounded and Compiler/Api P1 ownership mechanisms before designing
   this boundary; heterogeneous packed result motives cannot simply be assumed
   to have one runtime type. Do not copy a shape-only body rewrite.
6. Reconcile all six M3 exits and qualify one final compiler/test SHA across
   Native, M3, F1, F2 and F3. M3+B remains OPEN. Do not start M4/C5 or relabel
   the historical bounded M2 acceptance as full v7.2 completion.

Pinned source/design references:
docs/PSCV0_M3_NATIVE_INPUT_ROUTING_2026-10-18.md,
docs/PSCV0_M3_RETAINED_CALL_ANALYSIS_2026-10-18.md.
WF study: FixedParams, ArgsPacker, WF/{Main,PackMutual,Rel,Fix,Unfold};
Fix.processSumCasesOn/processPSigmaCasesOn refines callbacks before recursive
replacement. PSC0's existing singleton source re-elaboration preserves the same
branch invariant. The internal source-body component candidate is implemented but not yet qualified.

## Input parity within the existing roadmap

.ps/.lean inputs share selected v7.2 semantics and assurance with their respective
grammars. M3 closes its data/recursion/source capabilities through both inputs;
M4+C/D adds effects/contracts through both; M5+E closes full selected conformance,
readable output and C5. There is no duplicate input-parity roadmap. The source
adapter and historical receipts document implemented and pending distinctions.
