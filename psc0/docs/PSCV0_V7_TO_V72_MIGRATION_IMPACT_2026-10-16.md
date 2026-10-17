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

## Current M3+B implementation checkpoint — unused-hint candidate, 17 October 2026

The containing compiler/test revision is not yet qualified. Accepted
`0e2f5c461d30457caee322b8135293597f55ac4b` / documentation
`e00f189cd4ce13da8cf37bf503884b339b553ec5` remains the five-gate baseline:
**960 observed runtime comparisons**, **78/100** engineering estimate.

### First qualification failure and bounded repair

Initial candidate `9af377a8da017d0ef3440968e353010063fb9481` failed the focused
host test build in [run 39047098395](https://github.com/dwijayuda/pskernel/actions/runs/39047098395),
job `117437900445`: local identifiers matches (line 736) and scoped (line 830)
are reserved Lean tokens. Its completed 104,970-character log reports the
Pscv0M3Where parse errors before source/runtime fixture execution.
This revision renames those local bindings to matchingDiagnostics and
scopedMain, with their uses. No compiler logic, assertion, source example,
oracle, workflow or budget changes. F1/F2/F3 passed at the first candidate.
The healthy Native run was allowed to complete before this repair was pushed. The repaired revision still requires a fresh five-gate
matrix at one exact SHA; prior per-gate results cannot be mixed into it.

### Second host-test failure and explicit-type/call repair

The next candidate `81413f4052ccb0ca89c605d7aec6a99fa35ec3eb` failed focused
[run 39048426579](https://github.com/dwijayuda/pskernel/actions/runs/39048426579),
job `117441769021`, during host elaboration at line 869. The expected type of
the new lookup's .ok pattern remained unresolved. Its complete
104,783-character log contains those two follow-on pattern errors; the new
source fixtures and runtime comparisons were not executed, and no artifact
was produced. Reaching the final numbered Lake job was not a successful build.

This revision explicitly types Batch, the Nat positive-index list and
Option (Except Diagnostic Result) lookups, with qualified Except patterns.
A further source review caught four mixed named/positional dictionary calls:
captured tag is explicit, so the existing application owner correctly treats
the positional argument and named tag as a duplicate. All four observations
now use named tag, d and n arguments. Their bodies, actual dictionaries and
44/10 expected values are unchanged; no acceptance assertion is weakened.
No compiler logic, workflow or resource budget changes in this repair.

F1/F2/F3 passed at 814; healthy Native was allowed to complete before another
compiler/test push. These are candidate gate results only. The containing
repair still needs all five gates at its own exact SHA.

This candidate corrects eager resolution of unused total hints on typed
nonrecursive Where helpers. Main/local suffixes remain raw with their
original spans; saved header scope is consumed only by active well-founded
elaboration. Full checked section locals/instances are available while
typing value predefinitions, followed by existing real type/body capture
pruning. Hint-only names cannot make a dictionary available to the body or
enlarge a final capture telescope.

After successful checked nonrecursive definition/equation or partial-body
construction, per-member unused-hint warnings travel through source origins
into successful source-only/emitted Native results and JSON. The represented
single-clause/combined warning messages match pinned Lean. Coordinates
faithfully expose retained syntax: main partial_fixpoint currently owns the
whole declaration span. Successful-result diagnostics are transactional;
native cumulative warning logs on later failing inputs are not claimed.

The proposed source fixture includes five exact native warning guards,
eleven matching native/source rfl equations, four complete native helper
headers and thirteen portable ordinary definition/equation headers. The
matched reducible dictionary pair checks actual tag/d captures and two
different dictionaries; hint-only type/instance captures must disappear.
Two positive source-only requests check single-source and provider-module
diagnostic identity and all six JSON coordinates. Four new negative
requests retain exact header/body/active-hint ownership. The former ordinary
unknown-measure refusal becomes a positive; the other six inherited-partial
refusals remain, alongside two successful inherited-partial warnings and six
warnings in the existing five-target emitted result.

No runtime export, workflow, shared runtime runner, trust policy or resource
budget changes. All five gates must pass at one new exact compiler/test SHA;
none of the above candidate assertions is execution evidence until then.

The [result-family receipt](PSCV0_M3_RESULT_FAMILY_QUALIFICATION_2026-10-17.md)
retains the previous exact qualification. Its failed-comparison rollback
claim applies at the public equality/family transaction; a low-level worker
may still return a partial context under its pre-existing API. The
[generic P0](PSCV0_M3_GENERIC_P0_RUNTIME_QUALIFICATION_2026-10-17.md) and
[independent WF](PSCV0_M3_INDEPENDENT_WF_QUALIFICATION_2026-10-17.md) receipts
retain preceding qualified cells.

### Next concrete source-scope boundary

A follow-up source audit identifies a separate legacy ordinary-definition
gap. An explicit-result function with no Where block and no hint still takes
Command's psScopeDeclaration route. Its source-used-key selection can omit
a local dictionary whose alias type depends on a section tag when neither
tag nor the dictionary name occurs in the header/body. The equivalent
hinted definition takes typed predefinitions and sees the full context.
This gap is inferred from current source; it has not been qualified by a new
plain/hinted execution pair in this cell.

The next bounded obligation is ordinary definition section-instance parity
across those routes: matching native/portable plain and hinted definitions,
two nonzero actual dictionaries, complete capture headers and exact
equations, while preserving private aliases, registered abbrev behavior,
theorem include/omit policy and all five gates. The present dictionary
regression is explicitly a Where/predefinition pair. It does not establish
the complete legacy ordinary-definition source exit.

This bounded source repair receives no automatic score increase. Complete
source parity, broader dependent inference, larger changing WF packs,
arbitrary measure telescopes, general mutual WF, broader indexed binary
deriving, nested/source induction and the complete P0 matrix remain open.
Only propext and Quot.sound are approved; P1 retains its audited
Classical.choice refusal. M3+B, M4 and M5 remain open.

The adoption matrix below is historical policy/owner evidence and does not
override this candidate or its preceding exact acceptance checkpoint.

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
