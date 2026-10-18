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

Main `psc0/pscv0-v7-native-lean-v1` is now
**33676076bcda7b0de5ec1f9803f49b8b1d28a058**.
It was advanced non-forcibly after confirming that all previous main runs were
completed. Integration is running at that exact compiler/test SHA:

| Gate | Run |
| --- | --- |
| Native | 39099546592 |
| M3, including actual paired backend execution | 39099546513 |
| F1 | 39099546493 |
| F2 | 39099546574 |
| F3 | 39099546446 |

These outcomes were pending when this checkpoint was written. Inspect live job
steps and complete logs. Never supersede or cancel a healthy main Native run.
The latest **fully qualified five-gate** SHA remains
6cdb9a6ee36b3262b366d80f36c238b50fd9676d until all five new gates pass.
Its receipt is docs/PSCV0_M3_INTEGRATION_6CDB9A6E_2026-10-18.md.

Preparation **33676076** is fully successful:
run 39098870650, job 117590844318, artifact 12125298815,
SHA256 b5fece53772a2634949b1016eca4ec31e7fc6909c769479ce75a962e59fbcc43.
See docs/PSCV0_M3_SOURCE_MUTUAL_WF_33676076_2026-10-18.md.
This documentation child retains that compiler/test tree; fresh refs override
the checkpoint. Historical runtime-ownership 9b5 and exact-component 6cdb
receipts remain valid within their original scopes.

## Completed preparation slice

Source mutual WF now uses the shared PreDefinition construction owner.
Both grammars elaborate the same typed components. Exact retained-source
equations and ordinary private runtime implementations are independently
checked; runtime recovery independently rederives the actual functional body
after owned helper restoration. Original admissions and assurance graphs stay
intact. Header opening is a shared dependency leaf.

The paired input fixture covers three mutually well-founded functions,
reordered dependent fixed parameters, a returned function, ordinary partial P0,
and selected fixedpoint P1. Strict checked-Core comparison, total-only validated
IR admission, combined ordinary admission, five-target emission, mixed modules
and assurance refusals all passed preparation. Actual new target execution is
the separate M3 integration run above, not established by emission.

The ordered application engine now returns the untouched suffix beyond an owned
source header. WF builds the checked call and decrease proof, then resumes the
ordinary engine on that result. This fixes native flat application versus
ProofScript chained calls without another argument elaborator.

Runtime recovery specializes only actual checked PSum/PSigma packing wrappers
through existing recursor/projection reduction. Public definitions and logical
fixedpoints never unfold. Non-value beta arguments retain real lets; a result
let below the original header preserves returned-function entry arity. The
specialized body and closed implementation are checked before the independent
prepared-body identity test. Forged-body and incomplete-coverage controls pass.
No new target primitive, assumption, timeout or budget.

## Selected foundation

Selected Standard: **3757 declarations, 44 classes, 371 ordinary instances,
13 defaults**. FNV 3071911941504503432; snapshot SHA256
364627b451f83a04064643d29f0fa3bb1bda85eab70d588d3e66755ddc67efe1;
surface SHA256
9b07ab5dc1ce2e429fb5ebe4dba0e8da5db667d395521718e0a9a65f9e748214.
Strict selected audit and independent pinned exporter agree at 33676076.
PSum adds five declarations, two rules, zero assumptions and one reducibility
registration. Preserve frozen pre-Order and pre-mutual authoring boundaries.
Approved assumptions remain exactly propext, Quot.sound and Classical.choice;
Classical.propDecidable is not an automatic runtime instance. Old 6cdb/9b5
artifacts retain their earlier 3752-declaration selected identity.

## Next work in the existing M3+B exits

1. Finish the five exact-SHA integration gates. Confirm the paired exports
   m3parity, m3data, m3control, m3mutual and m3strategies actually execute for both
   input kinds in JS/TS/Rust/Wasm GC/components. Record real run/job/artifact
   identities, not only green workflow labels or emitted files.
2. Continue the six-exit source-rule/native-owner/evidence audit. Data and
   elimination, owned strategies, total recursion, P0, P1 and cross-stage
   integration remain the denominator. M3+B and full selected parity are OPEN.
3. Investigate positive function-valued recursive fields as a coherent data
   capability. Pinned kernel/inductive.cpp opens Pi codomains and rejects
   recursive occurrences in domains; Core/InductiveGroup already constructs
   such field targets and IH telescopes. Source Data currently rejects them.
   Any extension must inspect Term, MutualStructural and Erasure/Recursion
   together: all currently assume direct child fields. Use actual checked IH
   telescopes and ordinary typed application/erasure, not invented hypotheses
   or per-target patches. Research and design only; this feature is not yet
   implemented or qualified.
4. Update both handoffs, roadmap and the exit ledger at every completed slice.
   Continue M3+B -> M4+C/D -> M5+E; do not start self-hosting or C5.

## Scope and pinned implementation references

Canonical v7.2 lines 1870/1874/1929 explicitly retain PS structural-subterm
restrictions; arithmetic n-1 is not structural evidence. Lines 1872–1890 select
function-like mutual source blocks, not native mutual inductive commands.
Equation-style source acceptance remains explicitly pending at line 1819.
Both .ps and .lean inputs share the selected semantics; neither accepts arbitrary
host Lean. Internal mutual/nested data APIs have separately scoped evidence.

Pinned Lean Tactic/Induction.lean 817–838 intentionally rejects default induction
over mutual/nested types. Structural/BRecOn.mkBRecOnConst documents the common
component-universe restriction. Do not misclassify these intended refusals as
missing positives. Meta/PProdN and Structural/IndPred distinguish general Sort
and Prop motives; the current Type-valued source structural owner is narrower.
Acc.rec's explicit large elimination does not imply native automatic structural
elimination into Type. Preserve these distinctions in the remaining audit.

Pinned references studied for this slice: Elab/App; PreDefinition/WF/{Main,
PackMutual,Rel,Fix,Eqns,Unfold}; Basic.addAndCompilePartialRec;
Compiler/LCNF/ToLCNF.visitCases and Simp/Main.simpCasesOnCtor?.
Further data research: kernel/inductive.cpp, Structural/{BRecOn,IndPred,Main},
Meta/PProdN, tests/elab/structuralOverNested.lean and structuralRec1/2.lean.
Retain upstream notices. Fresh common fixed IDs must stay disjoint from original
headers because psElabSubstituteLocals is ordered; do not change its semantics.
