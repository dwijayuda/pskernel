## Current integration candidate — exact choice foundation and P0 Nonempty fallback

The implementation now adds the exact pinned Lean 4.35.0 Classical.choice axiom and checked Classical.ofNonempty definition, and registers the existing Nonempty class. Nonempty/intro/rec are audited prerequisites, not duplicate new declarations. P0 first searches constructively for Inhabited, then uses independent Nonempty evidence only when required. The actual recursive source body remains separate from the opaque logical inhabitant.

The selected foundation is exactly propext, Quot.sound and Classical.choice. No further axiom, source axiom, proof hole or runtime choice intrinsic is added. Standard is 3635 declarations, 42 classes, 359 ordinary instances and 13 defaults, with explicitly reviewed pins observed in preparation runs 39064740499 and 39065744204.

This compiler/test revision is a candidate awaiting all five same-SHA gates. The new P0 source/body/native controls passed preparatory construction, official-kernel ordinary emission and exact verified refusals; its ten runtime comparisons must still execute in the focused gate. Last full acceptance remains e6b7f11750fdde6e1feacab86cfb32f2a82be8a5 and 960 comparisons. Do not claim 970 or new acceptance before completed logs.

The separate preparation branch now contains commit 5dd8ed9701b215bf808ea1e058e382b3f639710a and cloud run 39067140365: repaired generated-equation privacy, larger WF state, indexed BEq, checked P1 runtime ownership, the retained Order audit and portable monotonicity proof probes. Those changes are not included in this foundation-only integration and remain independently under qualification. Continue them while allowing the healthy Native gate to finish.

See [the current integration receipt](PSCV0_M3_CLASSICAL_P0_INTEGRATION_2026-10-18.md) and the existing six-exit M3+B ledger. M3+B remains open. Keep v7.2, pinned Lean, GitHub/cloud Linux only, fresh expected-HEAD/non-force updates and PR109 draft/open/unmerged on its original base. Historical sections below describe their original compiler identities and are superseded only where this current checkpoint says so.

---

## Approved foundation implementation — 18 October 2026

The user has approved the needed pinned Lean standard logical axioms (`propext`, `Quot.sound`, `Classical.choice`) and continued M3+B implementation. See the [foundation decision and exit ledger](PSCV0_M3_LEAN_FOUNDATION_AND_EXIT_LEDGER_2026-10-18.md). This resolves the earlier two-axiom policy restriction prospectively; actual P1 construction and expanded-foundation qualification remain required.

The v7.2 language authority and adoption identity are unchanged. Earlier compiler qualifications, migration analysis and their original assumption sets are retained verbatim below.

---

# PSC0 v7 to v7.2 migration impact and evidence

16 October 2026. User instruction: **v7.2 is the sole forward `.ps` target; no legacy compatibility modes.** Apply the [stage directive](PSCV0_V72_STAGE_DIRECTIVE_2026-10-16.md) before every new slice. Preserve historical references, qualified code and receipts. This matrix describes specification differences and inspected owners, not completed implementation of every row.

## Exact sources and whole-file comparison

All three complete immutable references were retrieved and byte-checked from implementation checkpoint `cb000664841d3f1ee4738bdf0bd68f390e3fd9e8` by read-only audit [38840967041](https://github.com/dwijayuda/pskernel/actions/runs/38840967041), job116780701452. The review inspected active v7.2 clauses, source-owner code and the complete comparison's changed policy prose. Raw and diagnostic-normalized diffs, original files, heading/rule locations and identities are artifact12021078540, digest `sha256:a96a305d43ffa13cf17daa2f68f0efb43e3f2e1633a266a4391fb699fdec5399`. Normalization is a document-comparison aid, never a language parser or semantic equivalence proof.

| Edition | Bytes / physical lines | Git blob | SHA-256 |
| --- | --- | --- | --- |
| v7 | 309429 / 3203 | `25e1ef788794db175a2183679e37ff8c8e9b6a2e` | `07e505a93806c47faab5bd215e8fe2c76c2998ca48654dda86f0bb5f161ca389` |
| v7.1 | 352097 / 3411 | `a109a0a85d0c4fb0976d8b3ee30c331ef8438231` | `9f9ff109818b4961d693ab7d942f8a2721a2ccb5442ac0682e06d777216a00ec` |
| v7.2 | 337963 / 4347 | `694115223777599ba28ee175e14bb642b7b6aa4b` | `c65487eccbd2829d1d9e5e1be3bc7f4cb37849b841ab3257ea0dd47665b8a30e` |

Stable Lean4.35.0 `eb6cafb7290e8bd5f2937522d8d804f58f02bafc` is unchanged from the qualified compiler. Historical RC prose in the original reference is provenance, not a reason to downgrade the compiler pin. v7.2 §14.10 makes active clauses authoritative and repairs historical C04/C05 wording. Most new recursion/assurance semantics originated in v7.1 and are retained, not introduced anew by Markdown formatting.

## Current M3+B implementation checkpoint — qualified unused termination hints

Accepted compiler/test SHA:
[`e6b7f11750fdde6e1feacab86cfb32f2a82be8a5`](https://github.com/dwijayuda/pskernel/commit/e6b7f11750fdde6e1feacab86cfb32f2a82be8a5).
All five gates pass at that exact revision. The
[complete qualification receipt](PSCV0_M3_UNUSED_HINTS_QUALIFICATION_2026-10-17.md) records source ownership,
native controls, actual portable checks, both failed attempts and repairs,
gate/job/artifact identities, runtime accounting and the next source gap.

The preceding accepted compiler/test was
`0e2f5c461d30457caee322b8135293597f55ac4b`, recorded by documentation
checkpoint `e00f189cd4ce13da8cf37bf503884b339b553ec5`. Its own-binder
result-family and resource-error acceptance remains historical evidence.
This checkpoint retains **960 observed runtime comparisons** and
**78/100**. M3+B, M4 and M5 remain open.

| Gate | Run | Job | Result |
| --- | --- | --- | --- |
| Native Linux | [39051402014](https://github.com/dwijayuda/pskernel/actions/runs/39051402014) | [117450565117](https://github.com/dwijayuda/pskernel/actions/runs/39051402014/job/117450565117) | SUCCESS; 34/34 reported steps |
| Focused M3 | [39051402005](https://github.com/dwijayuda/pskernel/actions/runs/39051402005) | [117450565084](https://github.com/dwijayuda/pskernel/actions/runs/39051402005/job/117450565084) | SUCCESS; 15/15 reported steps |
| F1 | [39051401994](https://github.com/dwijayuda/pskernel/actions/runs/39051401994) | [117450565166](https://github.com/dwijayuda/pskernel/actions/runs/39051401994/job/117450565166) | SUCCESS; 10/10 reported steps |
| F2 | [39051401917](https://github.com/dwijayuda/pskernel/actions/runs/39051401917) | [117450564916](https://github.com/dwijayuda/pskernel/actions/runs/39051401917/job/117450564916) | SUCCESS; 9/9 reported steps |
| F3 | [39051402080](https://github.com/dwijayuda/pskernel/actions/runs/39051402080) | [117450565404](https://github.com/dwijayuda/pskernel/actions/runs/39051402080/job/117450565404) | SUCCESS; 11/11 reported steps |

### Qualified v7.2 behavior

Typed nonrecursive Where/main definitions now ignore unused hint payloads
and emit the pinned single/combined/fixedpoint warning after successful
checked construction. Raw suffix syntax and source spans are retained.
A saved original resolver/header scope defers active hint resolution to
the selected well-founded consumer; hint syntax supplies no capture or
termination evidence. Actual typed SCCs and checked type/body dependencies
remain the recursion and capture authority.

Ordinary value predefinitions receive the full checked section context,
including local dictionaries, before capture pruning. Matching plain and
hinted Where functions select actual dictionaries 41/7 and return 44/10,
retaining the legitimate tag/d type dependency. A separate Type u /
Inhabited A pair keeps complete Nat-to-Nat headers without hint-only type,
instance or universe captures. Theorem include/omit policy is preserved.

Successful batch origins and Native source-only/emitted results carry
source-owned warning diagnostics. JSON preserves source, phase, severity,
exact message and all six start/end byte/line/column coordinates. The
imported-provider test keeps hint-provider.ps even when hint-entry.ps is
the entry filename.

The completed focused gate passes all fifteen steps and 670 build jobs:
five exact native warning guards, eleven matched native/source rfl pairs,
four complete native @ helper controls, thirteen portable definition/eq_def
pairs, two new source-only successes and four phase/rule refusals. The
retained partial/main batches still have six refusals each and now check
two and six warnings respectively. The thirteen unique source warning sites
are distinct from the five new native guards and add no runtime exports.

All fourteen outer fixture commands and fifty-six runtime PASS markers
remain. Actual comparisons are 72 scalar exports × two flags × five lanes
= 720, plus 24 original deriving exports × two × five = 240, totaling 960.
Direct JS, compiled TS, locked Rust, V8 GC core and Wasmtime components all
compare against the corresponding native oracle. The retained nineteen
result-family equations/theorems, 21-request WF fixture with nineteen
refusals, 38 WF and 10 Where approved assumption closures, and generic
P0/P1 boundaries pass again.

Native passes all 34 steps and retains 1,069 observations each in direct
JS, compiled TS and Rust, generic Nat/Bool execution at 100,000/50,000 steps,
the linked three-module application, four-module GC application and repeated
component-host checks. Standard remains 3,633 declarations / 41 classes /
359 instances, FNV 4990397000639020696; exact Standard/surface SHA-256 values
and the matching M1 sourceSha are recorded in the full receipt.
The pinned Wasmtime host still warns that explicit post_return is deprecated
and has no effect; the passing host marker is recorded with that limitation.
F1/F2/F3 checked exports and strict retained assets also pass.

### Failed-candidate history and bounded scope

The initial `9af377a8da017d0ef3440968e353010063fb9481` focused run
[39047098395](https://github.com/dwijayuda/pskernel/actions/runs/39047098395)
failed on reserved local names matches/scoped. The six-line rename repair
`81413f4052ccb0ca89c605d7aec6a99fa35ec3eb` then failed focused
[39048426579](https://github.com/dwijayuda/pskernel/actions/runs/39048426579)
because the new indexed pattern's expected type was unresolved. The final
repair explicitly types the Batch/Nat-index/Option-Except values and patterns.
A pre-push source review also changed four dictionary calls to all-named
tag/d/n arguments; expected values 44/10 and all assertions remain.

Both failed attempts stopped during the host build, before the fourteen
outer fixture commands and portable source/runtime checks, and produced
no focused artifact. Compile-time native controls can run during host
elaboration before a later host error. Every preceding healthy Native
run completed before its successor compiler/test push. No earlier per-gate
pass is substituted into the accepted matrix.

Compiler logic was unchanged after the initial candidate. Relative to the
preceding checkpoint, the complete series changes eight compiler files by
+136/-43 lines and the existing Where fixture by +356/-5. No workflow,
runtime export, runner, resource budget, language authority or Lean pin
changed. Artifact metadata and completed upload receipts agree; archive
contents were not independently reopened or rehashed.

### Remaining source obligation

The next concrete gap is a plain explicit-result ordinary definition with
no Where block or hint. Its legacy psScopeDeclaration route can omit a
body-selected local dictionary whose alias type depends on an otherwise
unmentioned section tag. The hinted equivalent takes typed predefinitions
and sees the full section context. This gap is inferred from source;
the current qualified dictionary pair covers Where/predefinitions only.

Next qualify matching native/portable unregistered ordinary definitions in
a nonempty section through the existing typed owner, with actual
dictionaries 41/7, all-named tag/d/n calls, complete headers and equations.
Preserve private aliases, registered abbrev/attribute/instance behavior,
theorem include/omit and typed recursion ownership.

Warnings are exposed with an overall successful result; parity with Lean's
cumulative log before a later failure is not claimed. Coordinates retain
ProofScript spans, including the whole-declaration main partial_fixpoint
span. No standalone decreasing_by, termination_by? or structural-hint
grammar expansion is established. The prior rollback claim applies to the
public equality/family transaction, not every raw worker return contract.

The rubric remains data 25/30, source 14/15, total recursion 16/20,
P0 13/15, P1 1/10 and integration 9/10. Complete source parity, broader
inference, indexed binary deriving, nested/source induction, larger changing
WF packs, arbitrary measure telescopes, general mutual WF and the full P0
matrix remain open. Only propext and Quot.sound are approved; P1 retains
its audited Classical.choice refusal.

The adoption matrix and language authority below remain unchanged.

## Rule-to-change and implementation matrix

Status baseline below: source inspected at `867d76f992293977ab54e3c7fcb4c87a088e2462`; qualified runtime compiler `133af061d6aaff0eb6ed990abd341ca2a44d15e9`. **Specified** means normative design. **Pending** is not a successful source or artifact admission. Each implementation slice must add its exact tested/qualified commit and phase evidence.

| Clause / rule | v7 requirement | v7.1 material change; final v7.2 | Classification | Affected existing owners and current evidence | Milestone |
| --- | --- | --- | --- | --- | --- |
| §§0A–0B,2,5 `PSCV0-TERM-02` | Partial source rejected | Conditional `partial def`/`partial function`; inhabited result, type checks, logical opacity, independent runtime admission | Breaking admission change/new capability | `Syntax/Pscv0/Commands.lean` and `Module.lean` still blanket-reject; `Elab/Command.lean` scopes partial as unsupported. Existing AST has partialDefinition, not a complete implementation. Specified/pending | M3+B P0; verified model in M4+D |
| §§0B,2,5 `PSCV0-FIXPOINT-01`, `PSCV0-REC-STRATEGY-01` | Selected total termination route | Post-body partial_fixpoint before where; checked construction/monotonicity; no automatic executable adequacy | New strategy | Commands/ProgramRead/TermRead, shared syntax, recursion elaborator, Core preparation/official checking/erasure require coordinated work. Current selected reader has no suffix owner. Specified/pending | M3+B P1; proof/refinement M4+D/M5+E |
| §§0B,2,5 modifier and head matrix | No admitted partial/unsafe prefix | Exactly selected special modifier ownership; no duplicates/mixes; const total-only; incompatible total/fixpoint combinations reject | Breaking grammar/new constraints | Commands and private/attribute handling in ProgramRead; local where reader. Do not turn a prefix token into ordinary def or discard suffix metadata. Specified/pending | M3+B |
| §5 noncomputable | Proof/spec use, no computational dependency | Retains that distinction and clarifies all emitted identities | Clarification/retained requirement | Commands currently does not select prefix; dependency role audit must distinguish logical/erased/computational use. Not newly implemented | M3 metadata, M4/M5 closure |
| §§5,7B `PSCV0-UNSAFE-01` | Blanket source exclusion | Only registered typed runtime capabilities; never logical proof authority; closed refinement or explicitly approved disclosed boundary assumptions | Breaking restricted admission | Source policy, capability registry, compiler requests/provenance, target/runtime owners; unrestricted unsafe remains unavailable. Specified/staged | M4+C/D; final M5+E |
| §§0A,7B assurance identity and no-downgrade rules | Ordinary/verified distinction already present in design | Three explicit machine-readable identities and refined closed/boundary policy | Expanded/clarified assurance requirement | `Host/NativeV7.lean` Request has targets but no assurance selector; CLI origins carries kernel/IR/profile, not a behavioral certificate. Three identities pending | Foundation alongside M3; complete M4+D/M5+E |
| §§5,7B `PSCV0-VERIFY-PARTIAL-01` | Total core route | Separate safe operational model/body correspondence for opaque partial; fixedpoint equations insufficient for target correctness | New proof obligations | Core logical/runtime identity, dependency closure, proof/effect ledger, target correspondence. Runtime observations do not discharge these. Specified/pending | M4+D/M5+E |
| §7 `PSCV0-CONTRACT-SCOPE-01` | Selected intrinsic contract and same-definition spec tail | Contract interpretation conditional on declaration strategy; ordinary contract-bearing source cannot discard an unsupported/unproved contract | Semantic clarification/expanded scope | Contract source reader/elaborator, safe model/refinement, requested artifact gate. Full contract machinery still pending | M4+D |
| §§0B,7,11.7 `PSCV0-LOOP-01`, `PSCV0-DO-SELECT-01` | Selected verified loop rules | Bare ordinary while; total invariant+decreasing; separately staged invariant-only trace model | Expanded grammar/semantic separation | Typed do/effects/VC pipeline; legacy flat Except translator is not a native compiler fallback. Specified/pending | M4+C/D |
| §§5,7B outcome/trace obligations | Total correctness emphasis | Return/Throw/Trap/Diverge differ; finite-prefix safety and separately promised progress/liveness | New/clarified operational obligations | Shared operational/effect model, erasure and backend-refinement evidence; no implemented trace verifier is claimed | M4+C/D/M5+E |
| §7A closed #eval | Pure/total, bounded, effect-limited | Same diagnostic restriction despite new ordinary partial/unsafe source | Retained restriction/clarification | Diagnostic entry and transitive evaluation policy; type inspection is not proof. New source admission must not widen evaluator automatically | M3 dependency policy, M5 tooling |
| §§7B,13 `PSCV0-TRUST-02` | No source axioms, emitted holes/metas or unapproved assumptions | Unchanged across all three assurance identities | Retained trust boundary | Existing source exclusions, Standard audits, official kernel and erasure gates preserved. New role/strategy metadata must extend closure, not bypass it | Every slice |
| §14.10 and historical C04/C05 | Historical total-only correction | Current function psRecursionSuffix versus total-only psConstVal is explicit | Authority/historical clarification | Active reference identity and documentation, not a new Core rule | Adoption slice |
| §14.10 paired examples | HTML/paired-table presentation | 80 HTML comparisons and14 paired Markdown tables converted to labelled fences; fixture cells repaired | Formatting only | Document consumers/examples; no automatic new language or runtime behavior | Documentation only |

## Exact test and acceptance obligations

| Rule family | Positive / negative fixtures from v7.2 | Required acceptance evidence / trust implications |
| --- | --- | --- |
| Partial P0 | P-TERM-02-A, P-V71-MOD-PARTIAL; N-TERM-02-EMPTY/CONST/PROOF/TOTAL | Parse valid heads; check inhabited-result admissibility and body type with no fabricated totality; reject Empty absent sound admissibility; no proof body equation; execute only supported ordinary backend; verified path rejects missing model/refinement. A parser-only slice does not close this row. |
| Strategy ownership | P-V71-CONST-TOTAL/FIX-WHERE/LOCAL-FIX; N-FIXPOINT-01-ORDER/DECREASE; N-V71-CONST-PARTIAL-FIX/MOD-DOUBLE/MOD-MIX/UNSAFE-FIX/PARTIAL-FIX/FIX-DECREASE/FIX-WHERE-ORDER/LOCAL-UNSAFE | Preserve selected head, modifiers, source spans and ordered body/suffix/where ownership. Compare pinned Lean construction, not token acceptance alone. Reject conflicting strategies for the intended rule. |
| Fixedpoint P1 | P-FIXPOINT-01-TAIL/OPTION; N-FIXPOINT-01-NONMONO/UNPROVEN/RUNTIME; N-V71-FIX-ASSUMPTION/FIX-SPEC-GAP | Kernel-check generated equations and required monotonicity. Audit actual transitive dependencies; any Classical.choice or other unapproved assumption keeps that case unavailable. Equations alone do not certify termination, source-body refinement or backend behavior. |
| Unsafe boundary | P-UNSAFE-01-ORDINARY/BOUNDARY; N-UNSAFE-01-UNREGISTERED/PROOF/CLOSED/STRICT; N-V71-UNSAFE-CONTRACT/STRICT-BOUNDARY | Registered exact typed capability and target identity only; no proof-producing shortcut. Closed needs proven refinement; boundary needs explicit immutable allowed assumptions and complete internal evidence. Strict policy rejects unsupported boundary assumptions. |
| Contracts and partiality | N-V71-PARTIAL-CONTRACT/FIX-SPEC-GAP; N-TERM-02-TOTAL | Check required contract even for ordinary contract-bearing source. A separate model needs proved body correspondence. No later arbitrary theorem or opaque body is a replacement for required spec attachment. |
| Loops/outcomes | P-LOOP-01-TOTAL/PARTIAL, P-V71-WHILE-ORD; N-LOOP-01-NOMODEL/VACUOUS/LIVENESS, N-V71-WHILE-ORD-VER/IMPL-TRAP | Type ordinary loop without behavioral label; prove total-loop VCs or all selected finite-prefix safety obligations. Trap/stack overflow is not divergence, successful return or proof of safety. Stage unsupported trace model. |
| Identity and dependency closure | N-ASSURANCE-DOWNGRADE, N-BACKEND-DIVERGENCE, N-V71-OUTPUT-DOWNGRADE/IMPORT-CLOSURE/ERASURE-EFFECT, N-NONCOMP-EXEC | Every emitted bundle needs explicit truthful identity. Verified request with incomplete specification/effect/assumption/erasure/refinement/target evidence produces no executable. Never fallback. Preserve computational versus logical/erased dependency roles. |
| Unchanged trust | N-TRUST-01-AXIOM, N-TRUST-02-SORRY/ERASED, N-HOLE-ORDINARY | No source axiom, unresolved metavariable or sorry/sorryAx in emitted output of any identity; only propext/Quot.sound currently approved. |

Each negative is successful only at its intended rule and phase in an otherwise valid fixture. Distinguish parse, elaboration/kernel, ordinary emission, verified admission, execution and formal target correspondence. Existing tests that encode superseded blanket bans must be deliberately migrated to new phase-specific requirements, not retained as backward-compatibility constraints or weakened to accept arbitrary failure.

## Adoption implementation and next slice

This adoption changes the active JSON manifest to schema3, portable reference constants, exact Node identity guard, and the native workflow's reference path/name. The previous adoption manifest and roadmap are retained by exact Git-blob identity in dated history files. v7/v7.1 reference contents and all M2 acceptance records are unchanged. Branch/directory names containing v7 are identifiers, not alternate source modes.

The identity guard checks independent document bytes/SHA-256/Git identity and agreement with portable constants. `fullV72` remains false. Native qualification must run on the actual adoption commit; earlier green runtime checks do not qualify changed identity wiring automatically.

Next highest-priority coherent source work: introduce owned v7.2 declaration-strategy handling using the shared parser/elaborator, preserving explicit unsupported-feature boundaries until inhabited partial logical/runtime separation and fixedpoint evidence are implemented. Do not emit an ordinary definition by erasing a partial/unsafe modifier. Keep M3+B open until the full selected v7.2 exit passes.
