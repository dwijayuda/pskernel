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

## Current M3+B implementation checkpoint — bounded result families accepted, 17 October 2026

Accepted compiler/test SHA is `0e2f5c461d30457caee322b8135293597f55ac4b`. All five gates passed
at that exact SHA: Native 34 steps, focused M3 15, and F1/F2/F3-F4-platform
10/9/11. The focused total remains **960 observed comparisons**, and the
engineering estimate stays **78/100**. This containing checkpoint changes
documentation only.

The [result-family receipt](PSCV0_M3_RESULT_FAMILY_QUALIFICATION_2026-10-17.md)
records the exact implementation, source and Native boundary checks, all gate/
job and artifact identities, four failed host-build attempts and bounded repairs.
The [generic P0 receipt](PSCV0_M3_GENERIC_P0_RUNTIME_QUALIFICATION_2026-10-17.md)
retains accepted `82b248a3ee2cd9246756690db23b7dffd612e022` and its 20 added generic
comparisons. The [independent WF receipt](PSCV0_M3_INDEPENDENT_WF_QUALIFICATION_2026-10-17.md)
retains the preceding 940 construction checkpoint.

An omitted result now uses a natural family over the resolved own-binder
telescope, in the enclosing scope, applied to the original arguments. Body and
checked caller constraints reach the same family. Only marked full natural
applications receive the bounded pattern/constant rule, with type/occurs/scope
checks and complete-equality rollback. Pending index scopes are preserved;
blocked families cannot guess their heads through application congruence.
Explicit main holes, own-binder completion, defaults, lexical capture closure,
tactic/record scheduling and official-kernel checks remain.

The source-only fixture compiled 19 pinned native equality examples and checked
19 source theorems, 18 closed total definitions, three original opaque/private
partial pairs and six exact elaborate-phase refusals. Cases include direct and
forward dependent Fin results, a qualified helper without unused parent
capture, caller-selected dictionary and saved tactic, record resumption,
fixed-index matching and an own type-binder dependency. It adds no executable
artifact or runtime export.

Actual Native output confirms checked family/universe assignment, preserved
pending index scope, checked resumption and complete later-failure rollback.
A separate real inference-fuel refusal survives postponement and checked queue
drain; the same continuation succeeds when its default is preassigned.
Concrete resource failures propagate through the migrated instance, synthetic
and elaborator owners before fallback or another default. Legacy compatibility
wrappers and pre-existing low-level fuel policies remain.

The completed focused log retains all 56 runtime PASS markers unchanged from
the P0 baseline: 72 scalar exports / 720 comparisons plus 24 original deriving
exports / 240 comparisons across both flags and all five execution modes.
Generic mutual P0 retains Nat/Bool instantiations, dictionaries/seeds, both
entry directions, Nat 2947/4123 and Bool 12/21 native values, actual opaque/body
identities and both verified-assurance refusals. Ordinary observations grant
no logical partial-body equation or verified backend correspondence.

All 38 WF and 10 Where assumption closures remain approved. Native retains the
Standard and proof assets, 1,069 shared observations in direct JS/compiled TS/
Rust, repeated components/post-return and 100,000/50,000 generic Nat/Bool steps.
The Native/focused logs contain 4,476,633/8,264,521 characters. Their artifacts
are 12103729665 (6,797,268 bytes) and 12103214519 (286 files; 3,038,443 bytes);
the receipt records all matching SHA-256/upload identities.

The engineering source bucket remains 14/15 because general unused-hint
diagnostic parity is still open. The next bounded source cell is a checked
nonrecursive Where helper whose unused unknown measure currently fails before
typed component classification. Pinned Lean handles the nonrecursive component
first, then warns about unused hints without elaborating them. A future repair
must preserve raw suffixes/spans, real header/body dependencies and capture
closure, active recursive checks and original-main strategy compatibility.

Inference remains bounded, with eager checked constant approximation and no
claim of general higher-order completeness or arbitrary application inversion.
Larger changing WF packs, arbitrary measure telescopes, general mutual WF,
broader indexed binary deriving, nested/source induction and the complete P0
matrix remain open. Only propext and Quot.sound are approved; P1 retains its
audited Classical.choice refusal. M3+B, M4 and M5 remain open.

The adoption matrix below is historical policy/owner evidence and does not
override this exact acceptance checkpoint.

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
