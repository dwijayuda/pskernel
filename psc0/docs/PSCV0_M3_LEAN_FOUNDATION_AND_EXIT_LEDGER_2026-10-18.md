# M3+B — approved Lean foundation and completion ledger

## Selected recursor source qualified in preparation

[Preparation 39138442923](https://github.com/dwijayuda/pskernel/actions/runs/39138442923)
completed SUCCESS at **1b7513339f22a5db24750485148603622e5ff018**. Both mandatory jobs passed:
recursor-authoring117707694190 and foundation117707694427. The selected file was
regenerated, compared byte-for-byte, and independently checked against its fixed
source SHA256. All109 pinned public telescopes match, with zero differences and
exactly the six unchanged compiler-owned helpers.

Actual .lean and .ps recursor inputs passed parsing, elaboration, exact checked
declaration comparison, official-kernel checks, eight phase-correct refusals,
and JavaScript/strict TypeScript/Rust/Wasm GC/component execution. All six older
runtime exports remain; m3recursors is251417 for true and241312 for false.
All retained foundation, indexed/HEq, deriving, structural/WF, P0/P1 and ownership
checks passed within preparation scope. No old failure became optional.

[The selection receipt](PSCV0_M3_RECURSOR_SELECTION_2026-10-18.md) records exact
source and artifact identities. Main remains33676076; its five historical gates
are not relabeled. M3+B and complete input parity remain OPEN. Named/generalizing
match implementation and the complete six-exit evidence audit remain in progress.

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

Main `psc0/pscv0-v7-native-lean-v1` and the latest fully qualified compiler/test
SHA are **33676076bcda7b0de5ec1f9803f49b8b1d28a058**. All five required integration
gates succeeded at that exact SHA; no healthy run was cancelled or superseded.

| Gate | Run | Job | Artifact |
| --- | --- | --- | --- |
| Native | 39099546592 | 117592811170 | 12125584016 |
| M3 | 39099546513 | 117592810896 | 12125729084 |
| F1 | 39099546493 | 117592810615 | 12126345791 |
| F2 | 39099546574 | 117592810822 | 12126166657 |
| F3 | 39099546446 | 117592810775 | 12125762304 |

Full artifact digests and scope: docs/PSCV0_M3_INTEGRATION_33676076_2026-10-18.md.
The prep receipt remains docs/PSCV0_M3_SOURCE_MUTUAL_WF_33676076_2026-10-18.md.
Earlier 6cdb and 9b5 receipts retain their original narrower scopes/identities.

## Completed integration slice

Source mutual WF uses the shared PreDefinition construction owner. Both
actual grammars elaborate the same typed components, independently checked
retained equations and ordinary private runtime implementations. Runtime
recovery rederives the actual functional body after owned helper restoration.
Original admissions, graph and assurance boundaries remain intact.

The paired source module covers three mutually well-founded functions,
reordered dependent fixed parameters, a returned function, ordinary partial P0
and selected fixedpoint P1. Checked-Core comparison, total-only IR admission,
combined ordinary admission, mixed modules and assurance refusals passed.
Actual JS/TS/Rust/Wasm-GC/component execution now passed for both input kinds,
including m3parity, m3data, m3control, m3mutual and m3strategies.

The shared ordered application engine retains the untouched suffix beyond an
owned source header. WF constructs the checked call/decrease proof and resumes
ordinary application on its result. Runtime packing specialization uses actual
checked PSum/PSigma definitions and registered iota/projection reduction.
Non-value beta arguments retain real lets; a result let preserves original
returned-function header arity. Independent private-body identity, forged-body
and incomplete-coverage controls remain. No target primitive or budget increase.

## Active preparation — function fields and public source telescopes

Unqualified preparation follows fully qualified main33676076. Fresh refs are
authoritative. At this checkpoint parenta23a0fd440cebfd2cb5395066ad877adf8e47122
(run39103818085) is running. This child adds the existing public-signature group
check to preparation and records the complete remaining match design. Keep at most one active and one pending preparation run.
Do not promote until preparation is green, or supersede a healthy main Native.

Implemented:
- Positive dependent function fields across Data, singleton/mutual structural
  elaboration, deriving and shared typed recursor erasure. Actual applied child
  indices/arguments and full IH types are checked; negative domains reject.
  Deriving distinguishes direct recursive method IHs from function fields,
  which require ordinary dictionaries. No fabricated function dictionary.
- Native namedPriority versus PS positionalPrefix is explicit syntax intent,
  preserved through shared application, WF argument capture and suffix calls.
  Both grammars keep duplicate/unknown name and PS overlap/placement refusals.
- Prop structural components use checked And/True; other components PProd with
  exact inferred sort validation, singleton identity and actual projections.
  No implicit universe lift or assertion of arbitrary Sort-u support.
- Generated public recursors now use pinned motive/motive_1..., constructor
  minor names, t, field_ih and strict implicit inference over the full telescope.
  Existing Core producers keep complete argument layout. Source Vector/V calls
  use named motives. Group tests compare names/kinds against official Lean in
  addition to existing kernel signature witnesses.

Existing paired input module adds m3fields true192013/false232417, explicit
dependent recursor and induction, singleton/mutual function-field recursion,
Hashable via a real function dictionary, dependent proof-valued mutual
functions and positive-function predicate recursion. Internal mutual-data
fixture covers one/zero owned Prop components. Five-target observers retain
all earlier exports. Native explicit recursor is noncomputable with a checked
agreement theorem to an executable structural oracle; PSC0 inputs must execute
the actual primitive recursor. Symbolic node-hash proof keeps default limits.

Qualification history (no assertions removed):
28e6 missing direct import; 5f49 native generator refused primitive recursor
oracle; f379 source PS argument placement and direct-versus-pointwise deriving
classification; f3e9 concrete hash-oracle proof reduction depth; 64ce actual
native argument placement; a25cadb9/run39102542931 built and passed all other
substantive checks but branchByRec still type-mismatched. Source inspection
located generated _motive explicit instead of native public motive inference.
This child fixes that shared owner; do not label it green before CI.

Designs:
docs/PSCV0_M3_POSITIVE_FUNCTION_FIELDS_2026-10-18.md
docs/PSCV0_M3_NAMED_APPLICATION_PLACEMENT_2026-10-18.md
docs/PSCV0_M3_STRUCTURAL_COMPONENT_PACKING_2026-10-18.md
docs/PSCV0_M3_RECURSOR_SOURCE_TELESCOPES_2026-10-18.md

## Selected foundation

3757 declarations, 44 classes, 371 ordinary instances, 13 defaults.
FNV3071911941504503432; snapshot SHA256
364627b451f83a04064643d29f0fa3bb1bda85eab70d588d3e66755ddc67efe1;
surface SHA2569b07ab5dc1ce2e429fb5ebe4dba0e8da5db667d395521718e0a9a65f9e748214.
Approved assumptions exactly propext, Quot.sound, Classical.choice.
Classical.propDecidable is not an automatic runtime instance. Preserve frozen
pre-Order/pre-mutual authoring boundaries. Historical 6cdb/9b5 used3752.

## Next work within M3+B

1. Qualify current preparation, inspect actual failure causes, and only after
   green preparation plus idle main advance exact code for all five integration
   gates. Keep both handoffs, roadmap and exit ledger synchronized each milestone.
2. Audit/reconcile retained Nat.rec's legacy explicit _motive signature against
   native source behavior in an explicit foundation-metadata slice. Its audited
   bytes/fingerprints are unchanged in this generated-recursor slice. Preserve
   frozen authoring boundaries and independently measure any later update.
3. Implement v7.2 selected named/generalizing matches using existing Match,
   PatternMatrix and dependent refinement. AST currently has no metadata.
   Pinned Elab/Match.generalize defaults true, can disable, and ignores let
   declarations; Meta/Match/Match.withEqs binds Eq/HEq original-to-pattern and
   supplies reflexivity at actual application. Named equations must not enter
   the automatically discharged index-constraint queue. Study branch scopes,
   shadowing, irrefutable/computed/multiple discriminants and indexed transport
   before implementation; no copied host elaborator or fresh matcher.
4. Finish the six-exit source-rule/native-owner/evidence audit. M3+B and full
   selected .lean/.ps input parity remain OPEN. Continue M3+B -> M4+C/D -> M5+E.

Canonical v7.2 retains structural-subterm restrictions and pending equation-style
acceptance. Source mutual blocks select definitions/functions, not mutual data
syntax. Native default mutual/nested induction refusal is intentional; explicit
recursors have separate support. Acc.rec large elimination does not authorize
automatic Type-valued predicate recursion.

Pinned references studied include kernel/{inductive,expr}.cpp, util/name.cpp;
Elab/App, Elab/Match, Parser/Term, Meta/Match/{Basic,Match},
Meta/Match/MatcherApp/Basic; PreDefinition/WF/{Main,PackMutual,Rel,Fix,Eqns,Unfold},
Structural/{BRecOn,IndPred,Main,FindRecArg}; Meta/PProdN,
Meta/Constructions/BRecOn; Elab/{Structure,MutualInductive,Inductive};
Compiler/LCNF/ToLCNF, Simp/Main; Deriving/{Hashable,Repr,BEq,DecEq};
tests/elab/{match1,match2,match3,matchGenIssue,matchGenBug,discrRefinement,
discrRefinement2,structuralOverNested,mutualDefThms,indPredRecursion}.lean.
Preserve upstream notices, official kernel, native .lean, GitHub Linux only.

## Recursor surface audit queued

The existing foundation inventory now compares public recursor binder names and
kinds with the pinned Lean environment, without selecting or changing any asset.
This checks whether the retained Nat mismatch is isolated before a foundation
redesign. Actual mutualLeanSource now explicitly uses the named-interleaved WF
call (n := m), in addition to the native oracle, through source header capture
and returned-function application. No new lane, runtime primitive or budget.

Preparation bba4f8b5/run39103375064 stopped before compiler build because the
new Name helper used Lean's reserved keyword prefix as a binder. Renamed to
originalPrefix; no algorithm or acceptance change. This child remains
unqualified pending complete preparation.

Preparation4a2b2ff4/run39103687263 stopped on comment delimiters in the new
Core binder-analysis helpers. Corrected to Lean comments; the full feature and
strict qualification obligations remain unchanged. No semantic result yet.

## Current qualification and next design

Public recursor signature comparison now runs in the existing preparation
indexed-elimination step, using the existing group executable. The selected
foundation inventory also reports unavailable native names and imports the
pinned Order module explicitly; differences are diagnostic, never automatic
asset selection. Strict declaration/surface pins remain unchanged.

Named/generalizing match design is retained in
docs/PSCV0_M3_MATCH_METADATA_DESIGN_2026-10-18.md. A crucial invariant is to
separate named branch equations from structural IH motives. Study remaining
plain-definition routing into the older direct-IH mechanism; the shared typed
PreDefinition/MutualStructural owner already separates source cases from
checked recursion construction. Avoid a form-specific retry or fake child
equality. This work is researched, not implemented or qualified.

## Exact proof-form qualification follow-up

Preparation a23a0fd440cebfd2cb5395066ad877adf8e47122,
run39103818085/job117605350253 completed with one failed source-check step.
Native build, fixedpoint/PSum export and replay, all strict foundation audits,
indexed elimination, deriving, WF, P0/P1 and noncomputable checks passed in
preparation scope. The paired field source passed elaboration through the new
explicit dependent recursors and Prop components, then failed exact checked-Core
comparison at proofObserved: the native input used term rfl, while ProofScript
used tactic by { rfl }. These have different proof construction paths. Both
paired native observations now use by rfl as well; the exact Core comparison,
expected propositions and all negative/runtime obligations remain unchanged.
Do not infer complete paired emission/execution or integration success yet.

The diagnostic selected-foundation inventory compared109 native recursors and
found24 public binder-name/kind differences, including Nat/Except explicit
private motives, Empty/False implicit motives (native explicit), and retained
major/minor names. This is a family of source metadata gaps. Selection and all
three fingerprints are unchanged; correction requires the explicit independent
foundation-metadata slice, preserving frozen authoring bases. Native hygienic
names (Eq.rec/Nat.le.rec) require the pinned source name-resolution policy,
not string-only renaming. The child7eba96e adds the strict generated-public
signature group check and explicit Order inventory import; its preparation is
still running. This follow-up is queued, unqualified, and does not move main.

## Next bounded preparation: complete recursor source metadata candidate

The generated-recursion/function-field correction is at e5f3b75050c1c07af10167cb8bd2c8ce732d98ec,
preparation39104907133/job117611012961, still running. Its parent7eba96e
(run39104089771/job117608270376) passed the new exact public signature group
checks and all other preparation checks except the known proofObserved
term-rfl versus tactic-rfl comparison. E5 aligns both observation proof forms
without relaxing Core equality. Main remains fully qualified33676076.

This child adds an UNSELECTED native recursor-source authoring probe and
freezes the existing PSum-final environment as
psSelfHostProdPreRecursorSurfacePreludeEnvironment. The active Standard is
definitionally unchanged, with3757 declarations and the same three pins.
The probe uses existing StandardExport replay/rendering/rule machinery,
compares complete native types using Expr.equal, preserves logical layouts and
universe parameter positions, and reports independent candidate digests.
The observed public inventory is109 native recursors with24 top-level
differences; six exact $psc0Format helper recursors have no upstream library
identity and retain their existing checked bytes. The full-type replacement
roster is measured separately, not assumed to equal24.

Design: docs/PSCV0_M3_RECURSOR_FOUNDATION_SOURCE_2026-10-18.md.
Do not select candidate bytes or copy candidate hashes into guards before
successful independent evidence and review. Do not mix candidate evidence with
the function-field slice, promote an unqualified candidate, supersede healthy
main Native, or create a second pending preparation. Continue named/generalizing
match work from its retained design after the existing source-metadata gap.
No changed assumptions, runtime primitive, admission budget, PSKernel-Core or
self-hosting. M3+B and full selected input parity remain OPEN.

## Source-negative phase qualification follow-up

E5f3b750/preparation39104907133/job117611012961 passed native build, all
foundation audits and exports, group public signatures, indexed elimination,
deriving, WF/P0/P1 and noncomputable checks. Its paired source declarations
passed exact Core comparisons, including the two corrected proof forms and
the rich native named-argument examples. It then stopped in an existing
negative-control setup: order(y := 2, 1) was correctly rejected by the
ProofScript parser at2:33, while the fixture incorrectly required parsing to
succeed before expecting elaboration failure.

This child preserves both negative cases and makes their obligations precise:
named-then-positional syntax requires the existing parser diagnosis;
positional/name overlap parses and requires the existing telescope diagnosis.
No compiler acceptance, expected value, proof, budget or foundation pin changed.
Paired backend emission/execution and complete integration are still pending.

Fa3bbea/preparation39105883977/job117612424848 is running the independent,
UNSELECTED full recursor-source authoring candidate. Read its actual replay,
rule, complete-type and digest evidence before selection. The phase correction
is queued behind it, with main still33676076; M3+B remains OPEN.

## Recursor authoring design correction and native packaging

Fa3bbea/preparation39105883977/job117612424848 failed the authoring step
BEFORE its new probe ran: standalone lean --run searched for
Ps/Host/StandardExport.olean in the portable package. Use the existing native
Lake executable pattern and explicit host module ownership. Its other failure
was the known parser-versus-elaborator negative-control setup; fcf08c56's
preparation39106336019 now tests that correction.

Source review also found that selected Except is deliberately Type-0, with one
recursor universe versus upstream's three. The revised candidate transfers
binder names/kinds recursively while preserving the exact selected logical
type. Expr BEq guards unchanged semantics; Expr.equal detects complete binder
metadata changes. Strict shape/identity/arity checks remain. Official replay
returns its actual kernel environment for symbolic iota comparison over the
selected profile. Both signature and rule comparisons alpha-rename scoped
universe parameters by position with equal arity.

See the rewritten
docs/PSCV0_M3_RECURSOR_FOUNDATION_SOURCE_2026-10-18.md.
No candidate bytes or hashes have been qualified or selected. Main remains
33676076; the foundation has3757 declarations and its unchanged three pins.
The next preparation includes native packaging and this coherent metadata-only
authoring design. Both source emission and all five integration gates remain
required; M3+B remains OPEN.
