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
run39085518962/job117551185828, completed FAILURE only in the packing build.
The new native reference theorem used decide on an opaque well-founded mutual
definition; reduction stopped at (callFirst 7 6 2).beq 7. Production and all other
retained foundation/WF/P1/noncomputable checks passed. The portable new probe
did not execute. The current child proves the identical expected equality using
simp with Lean's checked generated unfolding equations. No compiler algorithm,
expected result, acceptance condition, assumption or budget changes. Qualification
of this correction and the new portable probe remains pending; do not promote
until the entire preparation passes.

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

## Current native input routing slice — qualification pending

The current preparation child implements explicit v7.2 source-kind ownership
for isolated requests and named module sources. The CLI accepts .ps and .lean
and records the selected kind before reading source. The native adapter emits
PsSyntaxProgram and shares scope commands, binder groups, elaboration, kernel
checking, typed erasure, IR validation and all target emitters with .ps.
No source printing/conversion or host Lean fallback is involved.

A single paired fixture is integrated into the existing Where qualification:
exact checked definition comparison, shadowing multi-name annotations, mixed
module imports in both directions, official-kernel checking, five target
emissions and common assurance/noncomputable refusals. Existing backend observers
receive both source kinds (two native oracle values each); their execution is
pending. Source reconstruction and broad native syntax parity remain open.

Run39086069241/job117552793316 at1b1cb7fe completed FAILURE. The identical native
mutual equation now builds using checked equations, but the portable retained-call
fixture used non-selected braced mutual/native split explicit headers. This
child uses v7.2 mutual/end and comma groups; the second peer's type parameter is
explicit in both source and native control. It retains three reordered slots,
dependent fixed values, nested lambda/let call scope, original source arity,
returned-function exclusion and conservative underapplication assertions.
No acceptance condition or compiler call-analysis algorithm is relaxed.

Inspection also found the focused M3 Rust step wrote the noncomputable harness
before executing the P1 harness. This child executes each harness immediately
after generating it. Prior workflow success remains historical job evidence;
it does not establish the overwritten P1 Rust observations. Requalification
of that runtime lane is required. Main037fda49 remains unchanged.

See PSCV0_M3_NATIVE_INPUT_ROUTING_2026-10-18.md for pinned references,
architecture and remaining native syntax work. M3+B is OPEN.

## Native term and binder-prefix correction — qualification pending

Preparation2f82244c/run39087221158/job117556210481 completed FAILURE. The native
compiler built; packing found a .ps fixture semicolon (the selected separator is
newline), and the new native control rejected the shadowing group {T value : T}.
The fixture also used unavailable Except.isError; the child uses !isOk.

This is a real semantic finding, not just a fixture repair. Pinned Lean
Elab/Binders.lean:136-168,208-235,423-456 expands names into binder views and
elaborates each annotation in the preceding names' context. PSC0's earlier
group-wide annotation cache incorrectly ignored shadowing. Shared Scope and
Binders now process names in order. Group-origin metadata preserves the existing
multi-name source receipt and actual ordered local IDs after scope expansion.
Old successful outputs keep their values using valid non-shadowing names; the
exact rejected shadowing forms remain explicit native/portable negative controls.
The canonical v7.2 ordered telescope rule is unchanged. Earlier bounded M2 job
success does not establish correctness of the contradicted binder interpretation.

The native program now uses an owned rich term reader, sharing v7 literals,
sort/universe nodes, operators, named-call AST, binder groups, projections/indexing
and tactic nodes. Native application checks actual whitespace and indentation
per Parser.Term.argument:885-897. Native conditional, match-row and tactic layout
remain grammar-owned. ProofScript keeps comma calls, braced blocks and newline
term separators. This is not conversion through .ps or a host compiler fallback.

Shared Core comparisons now cover grouped parameters, universe inference,
operators, named arguments and a scientific Float literal; actual native input
proofs reach the official kernel. Five target emissions and two mixed-module
directions remain in the existing paired fixture. Native data/class/instance/
deriving/where/do/full-termination syntax and complete mutual WF remain open.
No foundation, assumption, budget or runtime acceptance is relaxed. Do not
promote until complete preparation and exact-SHA integration qualify the child.

## Binder-view construction and complete prefix ownership — qualification pending

43a91de8 / run39088233267 / job117559220561 failed production compilation:
the new optional source-origin field is an explicit constructor argument in Lean.
Both constructor sites now supply it. No semantic qualification ran on that SHA.

Subsystem review also applies ordered annotation resolution to section-variable
groups, not just declaration/lambda binders. Selected section captures retain only
their selected origin names and IDs. Native tactic termination recognizes the
lexer's explicit EOF token, and native command separation permits EOF without a
final newline. These are shared syntax/scope invariants, not weakened assertions.
The exact native/portable shadowing rejections and prior positive observations
remain required. Main stays 037fda49; the new preparation child must qualify first.

## Native term construction layout — qualification pending

Preparation3897a2e2 / run39088402975 / job117559717894 failed compilation in
the new Lean.Term module at five multiline record expressions. Shared binder,
scope, command and retained semantic modules compiled. AST construction is now
bound before the parse-result record throughout the affected term reader;
no semantic or acceptance change. Qualification of the complete native term
and ordered-binder slice remains pending. Main is still037fda49.

## Native keyword ownership — qualification pending

Preparation8f0950c0 / run39088579549 / job117560230257 built the native compiler
and is continuing retained foundation checks. Do not cancel it. The next child
also applies the existing native keyword table at application boundaries:
native then/deriving/mutual/monotonicity cannot become ordinary arguments.
The common ProofScript table alone does not own these native delimiters.
This follows pinned Parser.Term.ite/argument and Parser.Command; source grammars
remain separate and share semantic AST/elaboration. Full qualification is pending.

## Retained-call checkpoint and native data adapter — 2026-10-18

Preparation8f0950c0/run39088579549/job117560230257 completed with one failure:
native then was consumed as an application argument. The correction is already
in af9a0e31/run39088772197 (in progress). No run was canceled. All retained
call-analysis/PSigma/PSum construction, fixed-scope, primitive/manifest/order,
heterogeneous context, P0/WF, P1 and noncomputable steps apart from the combined
native-input/Where step passed at8f0950c0. Source mutual WF is still refused.

The current child adds the selected native data/class/instance/deriving adapter,
shared field-header construction and attribute registration, plus one data export
in the existing paired five-target fixture. Both handoffs are consolidated.
Qualification is pending; main037fda49 remains unchanged. Historical focused P1
Rust observations were not executed before the harness-order fix and must be
requalified. Full native syntax parity, source mutual WF and M3+B remain OPEN.

## Checked declaration-batch comparison — qualification pending

af9a0e31/run39088772197/job117561623591 completed FAILURE only in the
combined source/Where step: "parity fixture expected ordinary definitions".
The native then boundary is corrected. PreDefinitionNonrecursive deliberately
publishes both each definition and its checked eq_def theorem. The paired fixture
now compares both matching kinds, all names, universe lists, alpha-equal types and
actual value/proof bodies. It does not filter out equations or accept a kind/count
mismatch. This repairs the fixture's incomplete model of the existing compiler
batch contract, without weakening comparison or changing logical declarations.

b8b9bea7/run39089323375/job117562902854 has built the new native data adapter and
is running retained qualification; it still contains the older comparison and
must finish normally. This child also preserves selected registrations in native
mutual members, matching the shared attributed-command owner. No run canceled,
foundation or budget changed. The child still needs full qualification before
main promotion; M3+B and full native syntax parity are OPEN.

## Native where and explicit decrease proofs — qualification pending

b8b9bea7/run39089323375/job117562902854 completed FAILURE only at the known
definition-only fixture comparison; production and native data oracles compiled.
b95c6293/run39089622847/job117564131092 is running with complete definition/
equation comparison. Do not cancel it. The current child adds native where local
definitions, per-helper suffixes and native decreasing_by tactic sequences using
the existing shared scope/capture/recursion/proof/runtime owners. Native by terms
and decrease proofs share one tactic-sequence reader.

The same two-source data fixture now executes a local well-founded identity
helper with explicit Nat.lt_succ_self evidence, retaining native6/9 outputs and
the existing backend matrix. No added workflow or foundation assumption.
Pinned Parser.Term/Extra, Elab.Binders/MutualDef/LetRec and termination_by_where
were studied; upstream illustrative axioms were not imported. Nested local where
and unselected structural/monotonicity forms remain refused.

This is an implemented but unqualified adapter slice, not source mutual-WF
completion. Main037fda49 stays unchanged. Finish preparation and exact-SHA five
gate integration, including the repaired P1 Rust lane, before any completion
claim. Native do and other selected grammar gaps require reconciliation.
