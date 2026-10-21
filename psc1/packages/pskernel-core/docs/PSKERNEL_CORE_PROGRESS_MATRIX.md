# PSKernel-Core progress matrix

Execution update: **2026-10-22 (Asia/Jakarta)**. The containing candidate implements
T03a and repairs eight evidenced native occurrence-fixture IO errors. It is
**not qualified at creation**. Existing implementation `034999734f2574876a747c967dd03bcc6904b395`
has a terminal native integration failure (job119352848567/run39637759611);
its other original runs are observed without duplication. Read the newest
work-state for exact terminal results. Latest fully qualified scoped A remains
`3aa077cb64ff06f76727decd01c43ad6c33f351d` until the new candidate's own gates pass.
Full Arena C and performance/release D remain separate from scoped A.

Branch: `integration/psc1-pskernel-expr-v2-lean435-20261021`  
Audit baseline: `3aa077cb64ff06f76727decd01c43ad6c33f351d`  
Authority: [completion plan](PSKERNEL_CORE_COMPLETION_PLAN.md), [deep audit](PSKERNEL_CORE_LEAN435_DEEP_AUDIT.md), latest dated `../AI_WORK_STATE.md` and exact-source Actions receipts.

Implementation and qualification are independent columns. `Open` does not negate an already qualified narrower provider. A passing diagnostic job establishes collection, not a passing kernel case. Parent CI never becomes child CI.

| Task | Implementation state | Qualification state | Dependency | Acceptance test | Priority |
| --- | --- | --- | --- | --- | --- |
| T00 Exact source and A receipt | Baseline scoped independent provider implemented | `3aa077c`: integration39622318383, correctness39622318348 and research39622318349 terminal PASS; full193 FAIL separately | None | Same SHA: native, portable `.lean`, checked canonical `.ps`, both generated routes, proofs, 24-provider/eight-API controls and artifacts | P0 |
| Complete seven-field checker owner | Implemented at baseline, including admission/public-WHNF boundary | Baseline native/generated integration PASS | T00 | Original full carrier42/56/540/38/44 and admission8/12/336/public-WHNF168 plus local proofs, both generated routes | P0 retained |
| K and Nat/String/structure recursor-major normalization | Implemented at baseline | Baseline native/generated integration PASS | T00 | Retained major126/504/360/432, K108/432/648/96, private-ID/universe negatives and genuine official checked declarations | P0 retained |
| T01 String-literal projection WHNF | Implemented in containing correction; absent at audit baseline | Native predecessor464 integration PASS; current034 candidate and both generated routes pending | T00 | Direct-path String projection positives/negatives, callback ownership and exact resource results; V1/official controls | P0 |
| T01F Full actual String environment | Complete actual String.ofList declaration environment not exercised by focused fixture | Open | T01, T03a owning references | Genuine complete-environment native/official/generated String.ofList expansion and projection; do not infer from minimal fixture | P1 |
| T02a Explicit-argument cache search worker | Implemented in containing correction | Native464 equations/control/axiom gate PASS; current034 and generated parity pending | T00 | First-match/no-hit/collision/duplicate lookup, proof audit and public operation parity | P0 |
| T02b Scoped exact ID/pair cache index | Open | Not run | T02a, measured probe attribution | Collision and unique lookup matrices, owner/mode/scope controls, ABBA binder/chain/collision timings and memory | P1 |
| T02c Checked app/lam/forall inference reuse | Open architectural gap; do not toggle eligibility alone | Not run | T02b, explicit scope/owner/mode invariant | Checked versus infer-only separation, context changes, scope exit, stale-owner negatives and same-run repeated-subterm cost | P1 |
| T02d cheapRec/projection mode cache isolation | V1/V2 guard and authentic regression implemented | Native464 reproduction and warm/cold controls PASS; current034/generated pending | T00; prerequisite for T02b/T02c | Prime cheap mode then full mode and reverse; fresh-owner reference; both generated routes, resources/errors/state | P0 |
| T03a Mutual/nested generated recursor ownership | Authoritative final-environment new-prefix bridge implemented; old helper ABI retained | Candidate NOT RUN at creation; focused native/official and both generated routes required | T01, T00 | Genuine admitted mutual/nested private type/rule IDs, direct K/iota, official positives/negatives and atomic rollback | P0 |
| T03b Preexisting-session ownership | Same-batch ownership exists; preexisting references incomplete | Open | T00 | Two checked batches, environment/owner mismatch negatives and direct inference/WHNF/DefEq | P1 |
| T04a Graph-native ingress/results | Eager validated whole-arena decode remains | Open | T03, T07; T02 indexing if used | No eager decode on promoted paths; sharing/depth/host-stack tests; demanded outputs exact | P1 |
| T04b Generated-metadata graph import | Recursive-expression import remains; repeated subtrees not memoized | Open | T03 | Unique-node-scaled worklist import, exact IDs, no trusted hash and private failure rollback | P1 |
| T05 Ordinary DAG inductive admission | V1 whole-operation admission remains | Open | T03 | Direct positivity/parameters/universes/constructor/recursor cases; official and V1 differential, both generated routes | P1 |
| T06 Mutual/nested DAG admission | Original implementation plus whole-operation fallback | Open | T05, existing checked nested algorithms | Original mutual controls, authentic nested valid/invalid cases, fresh owners and atomic multi-declaration commit | P1 |
| T07a Checking fallback removal | `API/Dag.lean` restart remains | Open | T01/T03/T05/T06, all supported descendant declines closed | No `psKernelV1CheckExpression` from promoted V2 checking; no new unsupported results | P1 |
| T07b WHNF fallback removal | `API/Dag.lean` restart remains | Open | T01/T03/T05/T06 | No original `psKernelSessionWhnf` from promoted path; exact checked/public/core behavior | P1 |
| T07c DefEq fallback removal | `API/Dag.lean` restart remains | Open | T01/T03/T05/T06 | No original `psKernelSessionIsDefEq` from promoted path; ordered pair/cache/resource controls | P1 |
| T07d Admission fallback removal | `API/DagAdmission.lean` restart remains | Open | T05–T06 | No original `psKernelV1AdmitDeclaration` from promoted path; all supported declarations genuinely checked | P1 |
| T08a Church numerals fuel exhaustion | Native and generated defect reproduced at historical receipts | Open, official accepts | T00, exhausted-worker attribution | Original request accepts at unchanged4096; negative/fuel recurrence controls and both runtimes | P0 |
| T08b Init prelude and remaining full193 timeouts | Exact3aa full193 has17 host timeouts; diagnostic init-prelude times out after kernel entry | Open | T00, source hotspot attribution | Original cases complete correctly under unchanged60s/2048MiB-old-space; no timeout counted rejected | P0 |
| T08c Safe invalid recursor-headed occurrence | Safe-only reduced-target/live-recInfo guard retained; eight native fixture IO application errors repaired | Implementation034 native fixture failed before oracle execution; repaired candidate and unchanged case16 replay require exact-source gates | T00 | Case16 matches official rejection; reducible/nonrecursive/erased/unsafe/nested/resource/publication controls retain correct results; generic unsupported unchanged | P0 |
| T08d Unsafe/partial contract reconciliation | Two explicitly classified safety disagreements | Open, strict gate cannot pass by relabeling | T00 | Documented typed entry contract aligns with official behavior; scoped default restrictions preserved; unchanged gate passes | P0 |
| T09a Whole-operation performance | Reproducible benchmark suites exist; major construction/admission/collision regressions recorded | Open, no general V2 speed qualification | Per-fix; final follows B/C | Frozen-source same-run ABBA, all groups/memory reported, thresholds in completion plan | P1 |
| T09b Build/CI reuse | Exact toolchain installer and source-bound artifacts exist | Partial; optimize only with correct cache identity | T00 | No stale output qualification; focused/final tiers retain every mandatory gate | P2 |
| T10a Local refinement/axiom audits | Selected metadata/cache/scope/fuel/owner lemmas exist | Retained exact-source proof gates; new slices need their own | Per task | Frozen-worker, traversal and callback equations checked with explicit premises and axiom output | P1 |
| T10b Global metatheory/backend preservation | Open global obligations | Not proved | Stable semantic algorithms | Actual checked correspondence/admission/soundness/backend theorems; finite tests are insufficient | P2 |
| T10c Deployment artifacts | Scoped V1 Linux/native and both JS packages exist at qualified predecessors | Requalify final exact source | A; release follows B/C/D as declared | Detached empty-PATH runtime, complete maps/source closure, digests and terminal source-bound receipts | P1 |

## Milestone receipt

| Milestone | State | Completion evidence required |
| --- | --- | --- |
| A Scoped independent provider | Exact3aa077cb64ff06f76727decd01c43ad6c33f351d qualified; a later candidate still needs its own gates | Terminal native, portable/canonical and both generated/provider checks at one source |
| B Complete V2 | Open | T01–T07, no four whole-operation fallbacks or eager/recursive migration adapters |
| C Full Lean 4.35 compatibility | Exact3aa FAIL:172matches/2safety/17timeout/1resource/1unsupported | Unchanged authentic193 gate passes after real semantics/resources/contract reconciliation |
| D Performance and release | Open | Published complete same-run measurements, major regressions resolved, exact-source release artifacts |

Next executable task: qualify the T03a ownership/fixture-repair candidate through focused native and all exact-source mandatory gates after observing the existing034 runs. Then T03b preexisting-session ownership. Do not repeat the broad audit or inherit predecessor qualification.
