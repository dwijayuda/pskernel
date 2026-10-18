# PSCV0 native implementation roadmap — v7.2 sole target

Updated 18 October 2026. **The forward feature/semantic contract for both `.ps` and `.lean` inputs is [v7.2](../PSCV0_LANGUAGE_REFERENCE_v7.2.md), with their respective source syntax.** No v7/v7.1 compatibility mode, legacy grammar fallback or architectural restart. Apply the user's [stage directive](PSCV0_V72_STAGE_DIRECTIVE_2026-10-16.md) before every new slice. The [migration matrix](PSCV0_V7_TO_V72_MIGRATION_IMPACT_2026-10-16.md) separates actual semantic changes from formatting and specified behavior from implemented/qualified capability.

**M2+A remains COMPLETE for its original `pscv0-v7-native-bounded/73` profile. M3+B is OPEN.** The accepted [M2 exit review](PSCV0_M2_A_EXIT_REVIEW_2026-10-16.md) and [integration receipt](PSCV0_M2_A_INTEGRATION_QUALIFICATION_2026-10-16.md) are unchanged historical evidence, not full v7.2 conformance. Qualified integration2a707206 passed native38832366451, F1 38832366381, F2 38832366374 and F3/F4/platform38832366314; acceptance280e1e4e records its artifact. Do not repeat that integration.

## History and authority

The pre-v7.2 roadmap is preserved byte-for-byte in [pre-v7.2 history](PSCV0_NATIVE_IMPLEMENTATION_ROADMAP_PRE_V72_HISTORY_2026-10-16.md), blob `fe0d2e84f74d1544bfefd6962b1a5c8612c8413e`. Its research and development journals remain separately retained in their dated history files. Historical version selections and pending-run instructions describe their original checkpoints, not current authority. The v7 and v7.1 reference contents and previous adoption manifest are preserved without creating legacy source modes.

## Architecture and trust boundaries

Native portable `.lean`, official Lean4.35.0 `eb6cafb7290e8bd5f2937522d8d804f58f02bafc`. Keep source syntax -> name resolution -> elaboration -> prepared Core -> official checking -> typed erasure -> validated IR -> target emission, retaining the same prepared graph. Study corresponding pinned Lean source/tests before each substantial change. **Input-language contract clarified by the user on18 October:** both `.ps`
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

The approved pinned logical foundation is exactly `propext`, `Quot.sound` and `Classical.choice`, per the user's recorded 18 October authorization in the [M3 exit ledger](PSCV0_M3_LEAN_FOUNDATION_AND_EXIT_LEDGER_2026-10-18.md). Audit exact transitive assumptions; native checked definitions and theorems are not additional axioms. Source admission does not grant unchecked logical authority. No sorry, source axioms, unresolved proof/inference holes in emitted artifacts, unapproved dependency closure, weakened tests or enlarged budgets.

JS/TS share the ECMA lowering; retain Rust and Wasm GC, with linear memory only at explicit Canonical ABI boundaries. No pskernel-core, independent kernel, compiler-source `.ps` migration, self-hosting or immediate C5 execution. GitHub/cloud Linux only; preserve branches/history with expected-HEAD/non-force updates. PR109 remains draft/open on its existing base; never merge for milestone acceptance.

## Established dependency order

| Milestone | Shared architecture and selected exit |
| --- | --- |
| M0 | Accepted selected typed-erasure/IR foundation, not entire language |
| M1 | Accepted selected checked indexing/library foundation; preserve laws and boundaries |
| M2+A | Accepted selected constraints/search/defaults/rollback/replay/source retention and library/registry/module/runtime evidence at original profile |
| M3+B | General data/elimination, recursion strategies and deriving, extended by v7.2 partial P0 and selected fixedpoint P1 requirements |
| M4+C | General effects, operational outcome distinctions, ordinary partial execution and restricted typed runtime boundaries |
| M4+D | Contracts, partial/total/trace proof obligations, safe model/body/refinement and assurance identity |
| M5+E | Whole selected v7.2 conformance, dependency/target evidence, tooling/incremental/validated optimization/performance and C5 correspondence |

Continue **M3+B -> M4+C/D -> M5+E**. Collect final-E evidence and performance data throughout; solve measured shared bottlenecks when relevant, not through isolated backend-specific source semantics.

## M2+A acceptance retained, not reopened

All six original selected criteria are accepted: (1) checked indexing and selected libraries; (2) five selected checked deriving handlers and refusals; (3) common scoped constraints/instance keys/default ordering/fresh replay/rollback and measured scaling; (4) retained source scopes, references, inserted evidence and once-only projection resumption; (5) strict declaration and live-surface registry/assumption/provenance audits; (6) complete source/kernel/IR/module/backend/GC/ABI/native-host measurement and history-preserving exact integration qualification. Exact owners and results remain in the original exit review; this migration changes neither those receipts nor their bounded denominator.

That completion is not full data/recursion/deriving, a general semantic-preservation theorem, complete verification, production-speed acceptance or v7.2 conformance. Additional v7.2 obligations below are tracked separately.

## M3+B detailed exit — v7.2

1. **Data and elimination:** selected heterogeneous/indexed/dependent and recursive type formation, nested/mutual inductives, constructor consistency, strict positivity, independent motives and recursive pattern matrices. Preserve invalid-index and elimination refusals and proof/runtime erasure on supported backends. Expand deriving through shared data mechanisms.
2. **Owned source strategies:** implement §0B/§2/§5 declaration-head/modifier matrix and body -> recursion suffix -> where ordering. Preserve total-only const, nullary function ownership and compatible mutual strategy rules. Invalid prefixes, duplicate/mixed strategies and wrong suffix ownership reject at intended rules, not unrelated parse errors.
3. **Total recursion:** structural and well-founded elaboration with checked decreasing evidence and exact logical equations; no partial/unsafe shortcut around totality promised by the declaration or contract.
4. **Partial P0 ordinary source:** selected partial def/function, inhabited-result admissibility, checked body typing and logical opacity, explicit executable-body/dependency identity and supported backend lowering. A partial body is not a definitional equation for proofs. Source parsing alone does not close this criterion.
5. **Selected partial_fixpoint P1:** pinned construction/monotonicity, independently checked generated equations and transitive assumption audit. Keep unsupported models and dependencies outside the approved pinned foundation unavailable. Equations do not by themselves prove executable termination, source/model correspondence or target refinement.
6. **Cross-stage qualification:** source/kernel/IR, positive/negative phase-correct fixtures, preserved module/API/proof erasure and admitted backend execution. Ordinary execution must not acquire a verified label. Verified use with unavailable model/refinement remains rejected. Update both handoffs and exact evidence for each completed slice; full M3 closure requires all selected v7.2 criteria, not just one runtime optimization.

## M4+C effects and executable behavior

Generalize through checked bind/pure and selected StateT/ReaderT/ExceptT and appropriate instances. Cover typed do, mutable/erased state, for/while, early return and selected throw/try/catch/finally, explicit world/IO/FFI boundaries. Accommodate ordinary partial execution without equating Return, Throw, Trap or Diverge. Define failure/effect semantics independently of JavaScript exceptions.

Bare ordinary while may execute only under explicit ordinary admission with no behavioral certificate. Total verified loops require invariant, measure and checked effect/proof rules. Potentially divergent verified loops stay staged until the selected operational finite-trace model and target correspondence exist. Restricted unsafe needs an exact registered typed runtime capability, never proof-producing authority.

## M4+D contracts and assurance

Produce kernel-checked proof terms for selected rewriting/simp/omega/grind and admitted automation. Implement given/requires/ensures, proof-only assert, invariant/decreasing and selected Std.WP/vcgen/spec-tail obligations with traceable ledgers. Contract-bearing ordinary source may not discard an unimplemented or unproved contract.

Distinguish type correctness, partial correctness, total correctness, finite-prefix safety and separately promised liveness/progress/fairness. Opaque partial/unsafe behavior requires a safe checked operational model and a proved relation to the executable body for verified use. A normal-return postcondition alone does not prove safety of a never-returning service.

Both v7.2 input languages have explicit ordinary checked, closed verified and boundary-qualified verified artifact identities. Every emitted artifact must truthfully identify its assurance. **No verified executable while any applicable specification, effect, assumption, dependency, termination/trace, erasure, executable-refinement or target obligation remains open. Never automatically downgrade a verified request to ordinary.** Boundary assumptions must be precise, immutable, disclosed and permitted; strict closed policy rejects unsupported external assumptions.

## M5+E full selected v7.2 conformance

Close source-rule -> positive/negative fixture -> exact phase -> pinned Lean elaborated-term/semantic correspondence -> checked IR/backend matrix. Separate parsing, kernel acceptance, ordinary execution, verified admission and formal target correspondence. Validate transitive assumption/primitive/erasure safety, environment cryptographic identity, public/private modules, JS/TS/Rust/GC/Wasmtime evidence and reproducible version/SHA/artifact records.

Complete incremental compilation, tooling, validated optimization/performance and C5 source reconstruction/correspondence. Only then declare selected core/essential v7.2 complete; the earlier bounded M2 all-green result is insufficient. Compiler-source migration/bootstrap and independent kernel remain separate future tasks.

## Qualified runtime slice and performance limits

The [M3 runtime receipt](PSCV0_M3_RUNTIME_QUALIFICATION_AND_PAIRED_PERFORMANCE_2026-10-16.md) qualifies compiler133af061 and records paired same-runner study38840337837. Actual-AST suspension analysis and generic lowering passed all native and independent workflows; generic Nat/Bool recursion ran100000/50000 steps. The same-runner study found about9.25–10.11x improvement for List-to-Array conversion and smaller head/array gains, **not a meaningful deep-list lookup or reversal improvement**. Do not relabel old247x–3158x native-Lean ratios as compiler throughput, universal language speed, Rust performance or solved production performance.

Next measured work is actual-IR closure/dictionary specialization and safe recursive/direct-call lowering, preserving generic instantiation, scope, evaluation order, failure behavior, persistent representations and stack safety. No source-name special cases or unchecked Number substitution. Keep original benchmarks and add representative workload evidence rather than hiding a regression with changed iterations or budgets.


## Current M3 checkpoint and remaining dependencies

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

Complete mutual WF source construction, checked decrease evidence, exact retained-body
equations and whole-functional runtime adaptation using the shared PSigma/PSum,
fixed-scope, source-preparation and checked-functional owners. The current call
analysis still needs qualification. No failed slice closes an exit.

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
