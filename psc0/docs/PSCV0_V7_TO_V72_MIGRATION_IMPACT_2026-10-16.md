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

## Current M3+B implementation checkpoint — independent WF candidate, 17 October 2026

At the latest tested compiler/test SHA `5b87922e40eac81889a78364fa33a34ada2a2c0b`,
the original three independent-WF decrease proofs now elaborate and all three
foundation gates pass. Focused construction advances to exact source-equation
transport for the nested two-coordinate match. This candidate extends its
existing checked constructor cases recursively when branch reflexivity is
blocked by another actual local recursor major; no induction hypothesis
authorizes an equation, and every leaf remains checked reflexivity.
Native qualification also requires the new regression's reserved local-name
correction. No 940-comparison or new score claim is accepted until all five
gates complete at one compiler/test SHA.


The accepted compiler/test baseline is `60586b7e12aee97954d27e698666a8a2531a0db4`
at 78/100 weighted engineering progress. Its
[complete receipt](https://github.com/dwijayuda/pskernel/blob/3e79dab87afe9b0b204307dec4590b2d33600352/psc0/docs/PSCV0_M3_DEPENDENT_WF_INDEXED_QUALIFICATION_2026-10-17.md)
records the completed five-gate qualification, including omitted main result
inference within the selected boundary, indexed Inhabited, nominal empty
dictionaries, generic fixed-codomain WF relations and dependent pair packing.
M3+B is open; these are bounded admissions, not full v7.2 coverage.

The current unqualified candidate addresses the remaining independent
two-changing-argument WF boundary in v7.2 total recursion. It reuses the
actual checked PSigma construction with a constant second family, preserving
exactly two source-ordered distinct changing IDs, capture and codomain
closure, checked decreases and equations, typed erasure and the curried ABI.
New left/right lexicographic programs and three well-typed entry-identity
controls are added. The sum nondecrease refusal retains its source and moves
to PSCV0-WF-DECREASE; the old tuple refusal is replaced by the genuinely
nondecreasing measure Prod.mk(n + acc, 0), also at that rule and elaboration phase.

Qualification still requires all five gates on the same compiler/test SHA.
The planned focused total is 940 comparisons, up from 920; no additional
runtime or progress credit is assigned before observed assertions pass.
Packing more than two changing arguments, arbitrary telescopes,
general mutual WF and the complete P0 matrix remain open. The existing
unary-major route still permits multiple state arguments. Variable measure
codomains remain refused consistently with pinned Lean, and the audited
P1 assumption boundary remains blocked. The v7.2 reference blob and pinned Lean are unchanged.

The implementation descriptions and next-slice recommendations in the
adoption-era matrix below are historical snapshots. This checkpoint and
the current handoffs/roadmap supersede their old pending/blanket-rejection
statements; their specification comparison remains retained as provenance.

### First independent-WF matrix and failure diagnosis

Candidate `fa68104af911aedc7b80bc56906da24bd6a9def9` remains unqualified:
native/F1/F2/F3 completed successfully, while focused run 39026724062 failed
in the portable independentRight decrease proof after native oracles and
portable independentLeft/equation passed. Runtime steps were skipped.
Native run 39026724076 completed all 34 steps before the next branch update.

The current diagnostic wraps the original proof elaborator without changing
its inputs or successful result and adds actual expected types, source spans
and captured goal locals only after failure. It does not replay a proof or
change the source definition/proofs. The accepted baseline remains 78/100
and 920 comparisons; 940 is still planned. Larger packed telescopes remain
unqualified. Variable measure codomains retain pinned-Lean refusal semantics.

### Actual callback trace and application diagnosis

Revision `b27407a3905883e5f4b3aac8a67cc8b6b5e71e02` remains unqualified.
Its focused run 39028057176 failed on the original first proof at bytes
6588..6626, `Prod.Lex.right(0, Nat.lt_succ_self(k))`. The captured
lower and upper pairs, latest refined callback and k are correct; the
three saved goals retain source order. F1/F2/F3 completed successfully.
Native [run 39028057191](https://github.com/dwijayuda/pskernel/actions/runs/39028057191), job 117382850031, completed all 34 steps successfully at 11:34:13 UTC. The full healthy native run finished before the next branch update.

The next diagnostic observes actual application and postponed-check
failure state without changing source proofs or successful elaboration.
An unknown-numeral/packed-projection interaction is a hypothesis until
that trace establishes it. No additional acceptance or progress credit
is assigned. Temporary diagnostics must be removed before final production
qualification, followed by all five completed same-SHA gates.

### Transactional instance-recovery candidate

The completed `cb0b1e85` diagnostic matrix passed F1/F2/F3 and failed focused
WF plus an existing native negative's error classification. The actual retained
independentRight proof inferred Nat.le and equal successor endpoints before
the final expected-term check. The new candidate introduces an opt-in blocked
projection/ordinary-instance recovery inside the existing complete equality
transaction, with checked assignment, saved scopes, full rollback and explicit
resource failure. Application/Postponed/WF temporary wrappers are removed;
original proof order and negative phase expectations remain. Direct native
regressions and all five same-SHA gates must pass before acceptance.
The accepted compiler remains `60586b7e`, 78/100 and 920 comparisons.

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
