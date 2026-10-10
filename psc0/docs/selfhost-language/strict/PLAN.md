# Strict PSC0-SH/1 implementation plan

Status: implementation and general source reviews complete; final qualification/disposition pending from ed5d00aca0743bde583b45fe7756dd494ac3960f; not yet strict-qualified. The qualified practical checkpoint was merged to main on 2026-10-09 at 16:30:26 UTC. Work proceeds on psc0/strict-sh1-v1. [AI_WORK_STATE.md](../../../AI_WORK_STATE.md) is the continuation authority; [merge-baseline.json](merge-baseline.json) records the verified integration.

## Latest closed-universe inference correction

The [retained-N1 diagnostic](https://github.com/dwijayuda/pskernel/actions/runs/38010024282) successfully reproduced and located the failed generic preparation at **sourceIndex 6, sh1GroupLet, stableDeclaration**. It used the unchanged b3fac compiler/fixture with one parse and one origin-preserving preparation. The diagnostic reports the owner and error; the universe-expression explanation is separately reviewed source analysis.

The [closed-universe correction](reviewed-candidates/closed-universe-inference-repair.json), blob **f71b09c33a574e6868b193afac946355008b4d61**, changes only Meta/Infer.lean from cad2c470d5c7682ffdc4caa111dafb5f076b27b3 to **160a4ae9fb8e5ae00729752463d5c42d4e9f8889**. Three local pure helpers normalize the closed levels freshly constructed by the sort-successor and Pi-imax rules. Every symbolic level is returned unchanged. This resolves the source-derived imax(1,1)-versus-1 construction mismatch without changing equality, unification, kernel/provider, grammar, fixtures or conformance hosts. Complete 106-file construction audit and exact three-guard root/independent review are retained. Finite proper levels and required allocation are explicit premises; no resource-equivalence claim is made.

The enclosing source commit requests one full **[sh1-qualify]** execution. N1/C1/C2/C3, fixed point/native parity, the exact evidence binder and independent provider must pass before the current 33 correspondence rows and 27 stage obligations are discharged. The previous attempt13 failed after six passing N1 conformance stages; it has no completed N1 receipt. Passed cold recovery remains reusable because its seven inputs are unchanged. See [AI_WORK_STATE.md](../../../AI_WORK_STATE.md) for the active continuation and exact evidence identities.

## Prior execution boundary — b3fac request

The practical migration is already merged at **ed5d00aca0743bde583b45fe7756dd494ac3960f**. Continue the authorized strict SH/1 qualification and merge; do not repeat the practical merge or promote a seed.

Latest published source before this enclosing host correction is **fb8f8076df3ed8708f927f88aa2d32febbfa89dc**, root **b93eaa340ff8955596ddc0376835386dd7f7c0d0**, PSC0 tree **30758899192080d3f6ffc5182f53a2c65a6d1c8a**. Production Expr remains **b4af2687c1b94e85014e323e5325385f139d4015**, SHA256 **88afa791aa95c5dfb2000865f58837398131527f3d3dd9f43e939c1d8bc36a15**, 138189 bytes. This correction changes only the source-conformance host and its evidence binder.

[Run 38007714076](https://github.com/dwijayuda/pskernel/actions/runs/38007714076), compiler job **114080256053**, passed steps 18–23 and then the full native strict source, target and original-IR checks: **64 modules, 1705 source declarations, 50 normalizations, 64829 IR expressions, zero findings**, plus all 15 native IR cases. The previous worker self-call arity refusal is cleared. **N1 was generated, TypeScript 7 compiled and loaded.** Step 24 subsequently failed in observeEmptySource at the obsolete assertion `letE !== call`. N1 conformance and its final receipt were not completed; C1/C2/C3 did not start. Provider **114080662313** and cold **38007714034** skipped. Attempt 12 retains exact failure blob **ff69f080d6fa1421e36e7db99a60ea4276d3e701** and full log **0239d0ea507f23f560afd3ca84ec8dda3108c935**; the first eleven attempts remain unchanged.

The frozen sh1EmptyFunction source returns `nomatch value` with result `Nat -> Nat`; it contains no authored application. The current compiler opens only the actual lambda prefix, so the declaration has one runtime parameter `value` and directly returns the typed empty `letE`. Its result arrow must not be converted into a new parameter and call. The [empty source return review](reviewed-candidates/empty-source-return-boundary.json) binds the two exact host changes: gate **fec9c43e4bd792aef81983d1dbf100a5b6b2beaa**, binder **b0b080eea2c353640f12d744e599737d71f9c4f6**. All four empty-source declarations now require direct body identity, exact declaration/local result types and exact runtime parameter lists; Fresh alone retains the second `emptyResult` parameter. The binder authenticates the added declarationResultType/bodyIsTypedEmptyResult observations. There is no wrapper peeling or new compilation. The complete 34-host-script assertion-class audit found this one obsolete computed-result eta assertion. Separate directly authored typed-empty-callee IR, untyped-callee refusal, five empty ABI signatures and computed-scrutinee once/original-fault coverage remain unchanged.

The production correction chain remains frozen: the flat List-pattern packet **e91fcacaa7c5a73c1d1fba8c30d213faee3fda83** maps Expr e3ed to a4d; the callback-local self-prefix packet **4c5d8ecca42e10c6da6f19f6118a829c173c9d4d** maps a4d to b4af. The latter binds the two-parameter recursive result inside the original callback, before the unchanged nested-scope/value application. No computation crosses a lambda and no eager remaining-fuel factory is introduced. Its complete 30-file self-call audit remains valid. The cumulative canonical/recursion inventory stays **46 code files: 30 production Lean and 16 hosts/fixtures**, with the two new host overlays. It is not the entire strict branch diff from main.

The general N/GROUP/ER/EV/TS arguments, ten-interface cross-family review and eleven-stage source/runtime review are complete in their stated domain. The final mapping **697c94b2722a6191537b714f71f629713637b30a**, manifest **419564764abc492816833a643af40b027b0fd897**, correspondence review **20f0116df23d4304e3b7e8f9da5ff39599eaf037** and stage/activation review **f6cc608044094aebe90609cb140d9cd00825ebf4** are attached. All **33 correspondence rows and 27 stage obligations remain open** pending exact successful execution and the supported final disposition. ER-06's stale empty-layout domain sentence must be corrected at disposition. Frozen advisory maps keep their historical pins; the active final record must compose all current source and host transports.

The enclosing commit requests one full **[sh1-qualify]** run. Discover the actual commit and matching Actions head_sha, then continue N1/C1/C2/C3, four fixed-point products/native parity, independent provider, retained evidence, explicit 33/27 dispositions and authorized merge. The three-entry/twelve-observation positive flat-tail block still awaits execution alongside the original 61 IR behaviors and 38 refusals. No extra native-only or cold run is needed; passed cold run 37983663908 and its seven inputs are unchanged.

Compose justified final claims in a separate release-qualification record. Preserve produced narrow false flags, runtime-contract and psconfig recipe bytes, historical proof anchors, selected R and the frozen provider. Keep authoritative handwritten **.lean through the owned frontend**, **ps-0.9-r3/new-only**, **Lean 4.34.0 / Node 22.23.3 / TypeScript 7.0.2**. TypeScript 5 is retired. Bulk refactoring, new syntax/deeper recursion, .ps source-authority migration and seed promotion stay deferred. No machine-checked compiler-wide theorem or measured speed/heap improvement is claimed.

## Goal and scope

Finish the mandatory source/runtime contract already defined by [SPEC.md](../SPEC.md) for the enabled TS→JS compiler lane. Improve authoring through the existing portable frontend, preserve selected R, and keep new-only ps-0.9-r3 and TypeScript 7.0.2. Merging the practical checkpoint removes the old bounded recursion/projection obstacles already repaired there; it does not enable all PSC1 or activate strict SH/1.

The work is a dependency-ordered implementation and evidence project. It does not require rewriting the 226 historical source locators or implementing optional syntax, scalars or targets. New helper modules stay inside the twelve existing compiler packages.

## Assurance policy

Every mandatory obligation needs a semantic rule, admissibility condition, implementation owner and evidence method. Distinguish:

- Core admission: exact declarations accepted by the pinned provider.
- Runtime IR typing: complete accepted report on the particular original IR.
- Compiler qualification: raw source replay, fixed-point products and stated execution checks for exact source/toolchain identities.
- Semantic correspondence: preservation through source normalization, erasure, runtime representation and TS/JS lowering.
- Formal verification: only the exact theorem actually established under its stated assumptions.

The specification does not require one monolithic machine-checked compiler theorem. It also does not permit replacing general preservation with a finite fixture pass. Use executable admission checks, per-compilation correspondence relations and complete rule-level arguments where appropriate; label finite conformance separately. Any enabled row without a defensible disposition remains open. Resource exhaustion never counts as complete evidence.

## Stages and exit conditions

| Stage | Work | Exit condition |
| --- | --- | --- |
| S0 | Freeze the enabled contract and rule ledger | Nine required capability families, eleven IR expression forms, six primitives plus Array and 45 operations have explicit domains and assurance methods |
| S1 | Real portable source boundary | Raw named modules pass the actual lexer/parser, ordered import policy, bounded source checks, existing preparation and exact-IR checked emission; unsupported forms and exhausted budgets refuse |
| S2 | Value and operation admission | Canonical Unicode carriers and valid domains are checked; array guards preserve valid values/evaluation order; operation-complete native/generated conformance retains all observations |
| S3 | Erasure/layout correspondence | Preserve and validate actual binder, proof/type omission, generic, field and constructor mappings associated with the particular prepared source/Core/IR |
| S4 | Evaluation and capture | Every enabled IR/normalization family has an explicit evaluation/demand/capture rule and supported correspondence disposition; initialization and errors are included |
| S5 | TS/JS lowering | Name/freshness/layout assumptions and generator, eta, count-loop and tail-loop routes have complete supported dispositions under exact TS7/Node identities |
| S6 | Qualification and activation | One coherent exact-source native/N1/C1/C2/C3 qualification and separate provider evidence; every enabled mandatory row closed before strict activation |

S1 and S2 form the first substantive implementation checkpoint. Qualifying that checkpoint does not close S3–S5 by implication. The [obligation ledger](obligations.json) and companion correspondence ledger record what remains.

## Source boundary design

Use one source kind for each ordered bundle and retain each module's identity and raw text. Lex and parse exactly that text. Validate imports before preparation discards them. A missing, forward, cyclic, duplicate or out-of-package dependency must not be silently ignored.

Traverse all AST declaration/term constructors with bounded explicit work. Preserve byte spans and owner names for source diagnostics. Reuse installed elaboration and structural-recursion rules; avoid duplicating type inference. Since the Lean parser lowers do immediately, identify the synthetic helper reference using the original do token span, without banning ordinary helper names or fields.

The current atomic entry returns the prepared object, original IR, accepted complete checker report and emitted TS together. The host serializes these exact objects and hashes the exact compiler/raw closure/grammar/options/outputs. It must not supply a freely forgeable “already checked” flag to emission.

The historical selected R does not export APIs being added now. It builds C1 through its existing qualified route. Current native/N1/C1/C2/C3 must exercise the new boundary; API absence on a current compiler is a refusal, not an implicit downgrade.

## Runtime design

Keep the six existing scalar representations and Array arity. The enabled operation contract belongs in ENABLED_RUNTIME.md and enabled-runtime-contract.json. Optional machine/floating/word scalar families remain rejected.

Validate JavaScript strings as Unicode scalar sequences at external carrier boundaries, including identifiers. Reject lone surrogates without replacement or normalization and bound validation work explicitly. Native Lean strings already satisfy their representation invariant.

For proof-required Array get/set, invalid indices produce a deterministic refusal before Number conversion. Preserve array/index/value evaluation exactly once in the original order, and allow in-bounds Unit elements. This is defense against invalid runtime inputs, not reconstruction of proof arguments removed by erasure.

The reference is the pinned Lean 4.34.0 implementation. String length counts scalars; raw string positions use UTF-8 byte offsets. Preserve the pinned behavior of get/next/extract, including explicitly distinguished invalid boundaries. Do not change cache algorithms or demand order speculatively.

Build one finite operation manifest and native reference vector. Compile one checked fixture module per executing compiler and retain its results, operation coverage, negative refusals and hashes. Native examples are independent conformance evidence, not a general lowering proof.

## Correspondence design

Use the existing normalization plans and erasure metadata before they disappear. Keep a companion record keyed by declaration and structural path, bound to source, grammar, compiler, normalization, Core and IR identities. Compare the actual transformation inputs/outputs; do not perform a second full preparation just to generate evidence.

Explicitly cover public wrappers/workers, structural decrease and simultaneous changing-state updates; runtime versus erased binders; constructor/record fields and projections; exact function groups and generic order; first errors and state-on-error behavior; let/capture scope; global initialization; target names and generated-name freshness; and all enabled emitter optimization routes.

Prefer small admission/provenance checks over rewriting unrelated compiler code. Static risks in arbitrary handcrafted IR are not automatically failures in the qualified source closure. Conversely, a source-closure pass does not establish the safety of arbitrary typed IR.

## Historical reviewed integrations before the canonical/recursion batch

The records in this section describe prior source attempts. Their then-current counts and requested runs are historical; the latest execution boundary above controls the next action.

[The current integration manifest](reviewed-candidates/strict-implementation-batch.json)
binds 29 source, fixture and workflow files to their exact bases and final blobs.
This batch combines actual normalization origins, one source-owned canonical
admission encoding and no environment reconstruction, immutable ingress
snapshots, computed Nat/partial-application sequencing, empty inductive
elimination and inhabited zero-field records. The final binder has independent
source review and retains all preceding source/runtime/target gates.

The fourth cloud attempt at `05f37fc04e52bfaed70389291a0fcdeda819f71f`
passed native development and C1, then exhausted the heap in the first C2 build.
[The attempt ledger](qualification-attempts.json) retains that failure and the
successful read-only archive inspection. No C2 files were retained. The new
batch has not inherited the previous run's success.

The reviewed 43-file source/evidence commit is `2b5a4c903ed8a069cde8f08265b28042bcaf5766`.
Its fifth run stopped at seed authentication before compiler work or memory
preflight: recovery still pinned the earlier grammar-conformance helper.
[The reviewed recovery overlay](recovery-profile-isolation.json) isolates its
byte-identical six-field grammar profile into a separately authenticated data
module. All seven runtime recipe dependencies and current callers were audited;
selected R identity, historical manifest metadata and four products stay fixed.
The overlay requests full qualification and a separate isolated native TS7 cold
recovery run in parallel. The old cold receipt does not qualify the revised
recipe. Record the two results separately; neither is a general semantic proof.

The overlay is committed at `047a29f17392fea41ac5d59e7f8cbfc172b20313`.
Its isolated cold run37983663908 passed75commands and reproduced all four
selectedR products; [the exact new receipt and evidence](recovery-profile-cold-evidence.json)
qualify the revised recipe. Its full run37983663904 passed native build and
memory preflight, then source replay refused the untyped match-valued
resultChecked local in psIrCheckMatch. [One explicit PsIrCheckState annotation](match-initializer-annotation-completion.json)
is the only required correction found in the full15-Lean-file changed-span
audit. It requests a new full-source qualification, without repeating the
unchanged cold recipe.

The [final reviewed three-file completion](post-review-source-completion.json)
also includes two findings caught by the semantic source review before another
execution: tail optimization now declines empty matches, and parameter-domain
shadow IDs reserve all original parameter IDs while preserving prefix visibility.
These reuse existing general emission, contexts, gates and fixtures. Their exact
reversible packets are retained; no broader syntax or test-count change is part
of this batch.

The next full run uses a fixed 8192 MiB old-space limit and a measured 12 GiB
available-memory preflight before expensive work. Candidate and fixed-point
processes repeat the preflight before generated compiler loading; they do not
apply a new per-generation availability refusal after a process has allocated
its heap. Scalar-only synchronous phase records survive an abort. The budget
and reduced repeated work do not establish a peak-memory repair.

The source gate remains 2 accepted / 33 refused / 2 carrier refusals; each
positive bundle now has 3 modules, 11 source declarations and 16 Core
declarations. The existing runtime matrix remains 45 operations / 186
observations plus six raw equalities; the shared sequencing fixture adds
12 declarations / 24 native values / 21 host probes. Empty/zero-field evidence
reuses existing source, IR, native and TypeScript invocations.

After exact-source execution, preserve all receipts and the independent
provider result. The reviewed [shared semantic foundation](SEMANTIC_RELATIONS.md) now supplies
the indexed relation, eleven IR rules and nine structural scope facts. Prove
its remaining semantic strengthening while discharging the N/ER/EV/TS families. A complete source argument over actual metadata or a correct checked
association witness can establish correspondence; an extra serialized
certificate format is not a normative requirement. All 33 general rows remain
open until their full arguments and evidence exist.

## Historical first integrated implementation checkpoint

[implementation-checkpoint.json](implementation-checkpoint.json) binds every candidate source, host gate, reference and recipe input by its exact Git blob. The new portable source and atomic backend APIs, target admission, Unicode and array guards, native/current host consumers and actual-file evidence binder are implemented candidates. Cloud execution was pending at that first source checkpoint; later attempts are recorded above and in the attempt ledger.

The finite source gate has two positive raw Lean/PS bundles, twenty-one portable refusals and two host Unicode refusals. Target conformance has nine accepted and twenty refused cases. Runtime conformance covers all forty-five enabled operations with 186 independent native observations, eight bounds failures, nine order/fault probes, five invalid carriers and two Unicode/position families. These counts describe planned assertions until their actual receipts pass.

The workflow's [sh1-qualify] source commit runs native preflight and current C1/C2/C3 qualification in one coordinated run; the frozen provider runs only after the compiler job qualifies. The native reference is executed once. Full-source preparation/IR checking is not repeated just to collect reports. The final binder reads the actual files, verifies executing/producing compiler identities and records exact receipt/product hashes.

The [correspondence guide](CORRESPONDENCE.md) and [33-rule ledger](correspondence-obligations.json) complete the rule inventory, not its general preservation proofs. All nine erasure, four normalization, eleven expression and nine backend/runtime rules retain their specific remaining obligations. S3–S5 stay open even after finite source/runtime/target qualification.

## Qualification workflow and stop rules

All repository execution occurs in GitHub Actions. Review source and related semantic obligations before a native preflight. Add gates and their source identities to the coherent existing qualification recipe. Reuse the prepared module, original IR, returned checker report and compiled native reference.

Retain exact logs and receipts, including failures if any. Do not relabel skipped/exhausted/failed cases as success or keep rerunning passed gates without a concrete remaining risk. After coherent preflight, run the required exact-source full qualification and frozen provider acceptance separately.

Do not select the candidate as a seed. Do not merge unqualified strict source. Documentation-only progress checkpoints may be committed with [skip ci]; they neither invalidate nor re-earn the baseline's source qualifications.

## Source basis

This plan implements existing requirements in SPEC §§2–8 and reconciles their status with CURRENT.md, IMPLEMENTATION.md, qualification-evidence.json, Compiler/Api.lean, BackendTs/Checked.lean, CompilerIr/Check.lean and the original-ir-inventory host boundary. All baseline sources are pinned to ed5d00aca0743bde583b45fe7756dd494ac3960f. New implementation, operation and correspondence evidence must name their own actual source revision.
