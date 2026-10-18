# PSCV0 native implementation roadmap — v7.2 sole target

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
