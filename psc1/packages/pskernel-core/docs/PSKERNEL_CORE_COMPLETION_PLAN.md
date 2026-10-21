# PSKernel-Core completion plan — Lean 4.35.0

Execution receipt: **2026-10-21T18:48:58Z**. T03a and the retained bounded corrections are qualified for scoped A at exact `7b14affc854e7bc99e4778ac155ae805dd273226`: integration39645765038, correctness39645764867 and all six research39645765012 jobs PASS. Original034 qualification is terminal and remains failed because of native fixture elaboration; its corrected334 successor is preserved separately. See [T03a source-bound receipt](../evidence/2026-10-22-t03a-terminal-qualification.json), the current matrix and newest work state. A later documentation-only HEAD does not change this exact qualified source. Full Arena C remains FAIL: 173 matches / 2 safety agreements / 17 timeouts / 1 resource exhaustion / 0 unsupported, and performance/release D remains open. The immediate next task is completing the existing exact `deb18b9c87a5d21a406c6e5b852afb4d44785fe5` combined-source qualification; the next implementation task is **T03b preexisting-session ownership**.


Concurrent source note: live integration also contains the name/string workers from341 in exact `deb18b9c87a5d21a406c6e5b852afb4d44785fe5`. Its own native and six research jobs passed; generated integration, canonical, independent Arena and profiles were active at2026-10-21T18:48:12Z. Keep it unqualified until its own required gates finish. Preserve its existing source/paired evidence and the latest work-state history; do not duplicate those runs.

Repository: `dwijayuda/pskernel`  
Integration branch: `integration/psc1-pskernel-expr-v2-lean435-20261021`  
Research baseline: `3aa077cb64ff06f76727decd01c43ad6c33f351d`  
Lean: `leanprover/lean4:v4.35.0`, commit `eb6cafb7290e8bd5f2937522d8d804f58f02bafc`  
Generated pipeline: authentic PSC1 → TypeScript 7.0.2 → Node 22.

This plan executes the findings in [PSKERNEL_CORE_LEAN435_DEEP_AUDIT.md](PSKERNEL_CORE_LEAN435_DEEP_AUDIT.md). [PSKERNEL_CORE_PROGRESS_MATRIX.md](PSKERNEL_CORE_PROGRESS_MATRIX.md) is the finite queue; `../AI_WORK_STATE.md` records exact implementation and qualification receipts. Read the newest dated evidence before updating a row. A source file, passing parent, diagnostic artifact or local equation does not qualify a later source revision.

## Objective and independent milestones

Produce an independently executing native and generated-JavaScript kernel, preserve the checked supported contract, finish its DAG representation migration, resolve authentic Lean 4.35 compatibility discrepancies, and qualify performance and deployment. These are distinct results.

| Milestone | Definition of done | Current boundary |
| --- | --- | --- |
| A — working independent kernel | The same exact source passes native checked semantics, complete portable `.lean` source checking, independently reconstructed/rechecked canonical `.ps`, both detached generated routes, positive/negative provider controls and artifact packaging | Exact `7b14affc854e7bc99e4778ac155ae805dd273226`: integration39645765038(native119380795456/generated119380794907), correctness39645764867(native119380794896/canonical119380794398), all six research39645765012 jobs PASS. Full Arena and complete V2 remain separate |
| B — complete Expression V2 | Every operation promoted by KernelContract-v1 executes through canonical IDs and checked owning metadata, with no four public whole-operation V1 restarts; no eager whole-arena decode or recursive generated-metadata import in the promoted checking path | Open. V1 remains separately selectable and remains the default provider until explicit promotion qualification |
| C — Lean 4.35 compatibility | The unchanged authentic 193-record gate passes, with official controls, zero timeout/resource/unsupported/mismatch escapes, and explicit resolution of the two safety-contract disagreements | Open. Diagnostic success and intended safety restrictions are not exact semantic parity |
| D — performance and release qualification | Frozen baseline/candidate measurements are reproducible, the major recorded regressions are resolved, all final-source release checks pass, and deployable artifacts/provenance are complete | Open. No npm publication or main merge is authorized by this plan |

Keep A usable while B–D progress. PSC1 compiler development must not wait for unfinished independent kernel research. Full-kernel DirectJS remains an explicitly unsupported compiler capability and is not silently substituted for the qualified TS pipeline.

## Settled architecture and constraints

1. Keep one recursive DAG owner in `Checker/ExprV2/DefEq.lean` and `Checker/ExprV2/Knot.lean`. WHNF, inference, recursors, proof irrelevance and conversion return the complete seven-field CheckState. Never rebuild it from the four-field compatibility WhnfState after a stateful callback.
2. Keep checked-inference and infer-only judgments distinct. An inferred proposition or proof-irrelevance success cannot publish a checked-body judgment. Scope exit restores semantic caches; fresh-name progression and appended arena follow the existing explicit rules.
3. Preserve ordered semantics and resource placement during migration. Default fuel stays 4096; published depth, numeral and host limits stay fixed. Unsupported internal attempts request a complete original operation while fallbacks exist; an inner error is propagated, never retried as success.
4. Use exact scoped IDs for indexing. Hashes select candidates, then compare exact keys/metadata; they never authorize equality or admission. Retain bounded DefEq pair-cache semantics rather than introducing transitive union-find closure.
5. Publish declaration owners only after complete checked admission. Generated recursors come from the admitted private environment, never caller metadata. Multi-declaration publication is atomic. Immutable sessions returned by checked APIs remain the authority under the documented in-process API discipline.
6. Keep V1 available as a differential reference. Removing its whole-operation fallback means implementing the supported operation, not turning previously accepted inputs into unsupported outcomes.
7. Preserve the authentic Arena archive bodies, official reference, negative tests, safety classifications and outcome taxonomy. A timeout is incomplete execution; fuel exhaustion is a resource result; neither is an invalid-proof verdict.
8. Use connected GitHub tools and Linux Actions only. No local builds, Desktop Commander, force-push, main merge, unchecked axioms, trusted hash/receipt shortcuts, resource inflation or npm publication.

All paths below are relative to `psc1/`; kernel source abbreviations start at `packages/pskernel-core/src/Ps/KernelCore/`.

## Dependency-ordered implementation queue

### T00 — bind the current checkpoint and retain A

The containing four corrections—focused String projection, explicit-argument pair search, cheapRec cache-publication isolation and safe invalid recursor-headed occurrence—and T03a final-prefix ownership passed their own scoped A gates at exact `7b14affc854e7bc99e4778ac155ae805dd273226`. Preserve their terminal receipt and failures in history. T01F full String environment remains open. Finish the existing combined-source gates before T03b; the T03a recipe below remains the authoritative specification for its implemented bridge.

Fetch branch HEAD and all required workflow jobs before any write. Inspect the exact commit and artifact manifests. Record implementation SHA, terminal job IDs, protocol/source-closure results and open Arena classification counts. If HEAD changed concurrently, inspect the change and rebase the intended edit with a non-force expected-SHA update; never overwrite another chat's work.

Required existing workflows are `.github/workflows/psc1-pskernel-core-correctness.yml`, `psc1-pskernel-expr-v2-integration.yml`, the Expression V2 research workflow, full Lean Arena workflow and authentic timeout-diagnostic workflow. Resolve their actual names from the checked workflow directory rather than inventing a dispatch endpoint. Use an existing push trigger or supported dispatch capability. A documentation-only child is not a new qualified executable revision unless its own required jobs run.

Acceptance: A's exact-source table is populated with terminal evidence, including separate native, `.lean` source, canonical `.ps`, generated runtime, local-proof and provider columns. Preserve failure receipts. This administrative task must not launch duplicate expensive workflows while the required source's existing runs are active.

### T01 — finish the bounded String-literal projection slice

Owners: `Checker/ExprV2/Projection.lean`, `WhnfOwned.lean`, `Whnf.lean`, `String.lean`; reference semantics in `Checker/Reduction/WhnfCore.lean` and `PrimitiveData.lean`. Implement the isolated missing String projection path only through the existing canonical String constructor and current owning callbacks. Preserve cheap/public WHNF distinctions, fixed callback fuel, depth entry and state propagation. Do not expand unrelated projection semantics.

Acceptance for the focused slice: native and both generated routes exercise direct success without outer fallback in the documented minimal fixture environment; valid empty/nonempty/Unicode String cases agree with the applicable V1/official controls; invalid field/family/ill-typed controls fail correctly; zero/near-bound fuel, depth, callback errors and state-marker probes preserve exact results. Existing String/recursor, private-ID and universe-negative suites remain unchanged. Record before/after public-operation timing; do not describe a coverage addition as a whole-kernel speedup.

**T01F — full String environment follow-up:** the focused fixture does not install the complete actual `String.ofList` implementation and dependencies. Test genuine `String.ofList` expansion with an independently checked complete declaration environment, including actual constructor/list/character reduction and public checking. Preserve this as open until native and both generated routes execute it correctly. Minimal fixture success must not be presented as complete full-environment String qualification. T03a ownership can proceed after the focused slice; T01F is required before B/C completion.

Dependency: T00. If the containing implementation already completed T01, inspect its receipt, update the matrix and begin T02 rather than reimplementing it. The additional cheapRec/public-WHNF cache-isolation defect discovered during implementation must retain its reproducer and dedicated negative mode-crossing controls; follow the containing audit/work-state for its exact source receipt.

### T02 — remove avoidable cache traversal and establish scoped lookup costs

Owners: `Core/ExprV2/PairMemo.lean`, `Checker/ExprV2/WhnfState.lean`, `CheckState.lean`, `DefEqPair.lean`, `Environment.lean`; `Runtime/Acceleration/Cache.lean` and `EnvironmentIndex.lean` supply existing design examples.

**T02a — explicit-argument search:** first qualify any reviewed semantics-preserving explicit-argument pair-search worker. Freeze the old predicate/worker in the proof fixture and prove extensional equality, including first matching entry, ordered keys, duplicate/collision behavior and no-hit. Then add counters in a diagnostic-only build to distinguish entries scanned from equality calls; do not time an instrumented path. Measure binder32/chain32 admission and collision128 alongside unique cases.

**T02b — exact index:** next replace only the measured linear lookup with a bounded persistent bucket/page index keyed by exact node ID or ordered node-ID pair. Include judgment mode and owner/scope identity where relevant. Keep immutable states and collision equality; validate index consistency against the authoritative entry list during qualification. Do not simultaneously enable caches for new expression classes.

**T02c — checked inference reuse:** checked app/lam/forall caching is a separate subsequent slice: Lean caches these, while `CheckState.lean` currently excludes them. Establish a scope/owner/mode invariant before broadening eligibility. A cache toggle alone is not an implementation. Bound insertion/lookup work without evicting semantic facts in a way that changes existing failure order unnoticed.

**T02d — cheapRec/projection mode isolation:** qualify the newly discovered cross-mode WHNF-cache correction before any cache widening. Retain a reproducer that primes the cache through the cheap-recursion/projection mode and then calls the full owning path; compare against a fresh full-mode run and the original semantic reference. A cache lookup must respect the exact reduction mode, and a restricted result must not suppress a required reduction. Cover both call orders, public/core mode differences, state ownership, checked invalid inputs and exact resource failures in native and both generated runtimes. The correction passed the same-source native, both generated, frozen-parent and local-proof controls at `7b14affc854e7bc99e4778ac155ae805dd273226`; this establishes the bounded correction, not a cache-performance qualification. T02b/T02c depend on this invariant.

Acceptance: native/generated lookup differential matrices, hostile collision cases, scope-exit and checked/infer-only separation, frozen-worker equivalence lemmas and unchanged public result/error comparisons. Same-run baseline/candidate ABBA results must show reduced cost on the selected hotspot without new supported-input failures or unacceptable retained-memory growth. Preserve existing local proof audits.

Dependency: T00; independent of T01 semantics, but integrate one source batch at a time.

### T03 — own all post-admission recursors and preexisting-session references

Owners: `API/DagGenerated.lean`, `DagDeclaration.lean`, `Dag.lean`, `Checker/ExprV2/Environment.lean`, `Constant.lean`, `Recursor.lean`, `RecursorK.lean`.

**T03a — mutual/nested family ownership:** extend the existing post-success bridge from ordinary inductives to actual mutually generated and nested-restored recursors and auxiliaries. Enumerate names from checked admission results/environment ownership; confirm family, constructor, parameters, universes, rule arities and type/body IDs. Do not infer an authoritative recursor by a caller-provided name suffix. Use one private staged owner and publish it only when every required reference imports successfully. Implemented and scoped-qualified at `7b14affc854e7bc99e4778ac155ae805dd273226` using the final-environment new-prefix recipe below. Native and both generated routes retain 24new declarations,7recursors,6direct cases and3private-ID controls; native official controls cover5families/6positive/7negative, and all21recursor proof equations are audited. T03b remains separate.

**T03b — preexisting-session ownership:** for a preexisting checked session, establish batch-owned references from the session's admitted declarations before use; never accept an input-supplied reference table. Choose a single owner boundary and keep immutable environment identity attached to indexes/caches. This is an adapter for checked state, not a second admission mechanism. Keep unsupported low-level forged-session behavior within the documented trusted integration boundary rather than pretending record constructors are sealed.

Acceptance: ordinary/mutual/nested generated owners exercised directly at nonzero IDs, across two batches and after an unrelated appended declaration; authentic recursor positive/negative and K/major cases; absent/mismatched owner and malformed-universe sentinels; full state retention and atomic rollback on a late import failure. Native official Lean controls for every new declaration family, plus both authentic generated routes. No silent fallback may satisfy a direct-path assertion.

Dependency: T01 and T00; T02 can improve cost but is not semantic authority.

### T04 — finish graph-native ingress/results after supported fallbacks close

Owners: `API/Dag.lean`, `DagTypes.lean`, `DagDeclaration.lean`, `Core/ExprV2/Decode.lean`, `Validation.lean`, `Transform*.lean`, `API/DagGenerated.lean`.

**T04a — ingress/results:** after T07 removes supported-operation restarts, remove the initial whole-arena recursive-expression decode from supported DAG checking. Validate/replay the untrusted graph once. Carry IDs through requests, checking, admission and metadata ownership. Decode only demanded public recursive-expression results and the explicitly selected V1 reference boundary. Preserve physical sharing of decoded results through an operation-owned table. Do not repeatedly decode the original graph for each command. Do not remove the adapter before its remaining fallback consumers have a qualified replacement.

**T04b — metadata import:** replace recursive generated-metadata import with an explicit worklist and memoized old-expression/node ownership. Smart constructors alone do not deduplicate repeated source subtrees; measure visited unique nodes, appended nodes and retained state. Keep exact source/canonical metadata validation and never trust an object hash as expression equality.

Acceptance: direct-path counters show zero full graph decode and no V1 operation restart on the promoted corpus; large shared diamonds scale with unique reachable nodes; deep linear terms avoid host stack overflow; append/reuse and root-ID mappings remain exact; malformed references fail before publication. Recheck all public return values and source-map/artifact packaging. Existing recursive public return types may require final result decoding; record it separately rather than renaming it away.

Dependency: T03 and T07 for final ingress removal; T02's exact indexing is reused if qualified. The metadata-import worklist can be developed earlier as its own qualified slice after T03, without pretending the eager decode is already gone.

### T05 — replace ordinary inductive admission on DAG IDs

Owners: `Admission/Inductive/Ordinary/{Admission,Constructor,ConstructorAdmission,Recursor}.lean`, `Common/{Parameters,Occurrence,Elimination,RecursorValidation}.lean`, `API/DagAdmission.lean` and owning ExprV2 checker modules.

Translate the current checked ordinary admission phases to ID-based workers. Preserve strict positivity, parameter/index equality, universe restrictions, constructor Π-spines, elimination/K policy, generated type/rule validation and failure order. Header/type/body checks retain one complete owner where the current contract shares it. Allocate provisional generated IDs privately and commit only after every check succeeds.

Acceptance: direct ordinary-inductive admission with generated recursor type/rule IDs; authentic legal recursion and indexed/universe examples; invalid positivity, wrong parameters, missing IH, forged recursor, invalid field and eliminator negatives; zero/boundary resource matrix; official native declaration checks; V1 differential and both generated routes. No unchecked generated recursor installation.

Dependency: T03. Requests already carry original IDs; retain the transitional adapter until its consumers are replaced. This is the first semantic-heavy B admission step; do not combine mutual/nested migration in the same patch.

### T06 — finish mutual/nested admission and all remaining supported variants

Owners: `Admission/Inductive/Mutual/*`, `Nested/*`, `Admission/Quot/*`, `API/DagAdmission.lean`, `DagGenerated.lean`.

Migrate mutual constructor/IH construction, nested discovery/flattening/rebasing/restoration and reserved-name checks through the same checked ID owner. Retain private work environments, exact constructor types and atomic generated-declaration publication. Preserve unsupported outcomes separately from semantic rejection. Keep genuine unsupported nested occurrences distinct from invalid positivity. T08c corrects the safe recursor-headed residual in the ordinary worker; authentic case16 must reject and genuine valid nested controls must accept. Finish any non-inductive admission branch and Quot setup still reaching the original operation.

Acceptance: native/generated direct admission over all supported request constructors; original mutual280/eight-official controls plus authentic nested positive/negative cases; fresh-member state, generated-name collisions, failed-last-member rollback, proposition/universe elimination and resource-order tests. Full canonical closure must still check independently.

Dependency: T05 and the existing checked nested admission algorithms. T08c addresses a narrow safe-positivity rejection in the existing ordinary worker; it does not provide a missing general nested algorithm.

### T07 — remove the four public whole-operation fallbacks

Owners and original sites:

| Site | Original restart |
| --- | --- |
| T07a `API/Dag.lean: psKernelDagCheckTerminalOrOriginal` | `psKernelV1CheckExpression` |
| T07b `API/Dag.lean: psKernelDagWhnfExpression` | `psKernelSessionWhnf` |
| T07c `API/Dag.lean: psKernelDagIsDefEq` | `psKernelSessionIsDefEq` |
| T07d `API/DagAdmission.lean: psKernelDagAdmitDeclaration` | `psKernelV1AdmitDeclaration` |

Before removal, make every supported descendant decline observable in a diagnostic build and partition it by operation/rule/owning metadata. Close the finite list through T01/T03/T05/T06 and the remaining owning checker rules. Do not interpret every internal `none` as a missing semantic rule: distinguish rule nonapplicability from a complete worker decline. Convert impossible internal declines to a distinct invariant failure only after their preconditions are established and tested.

Acceptance: a static call-site inventory and dynamic supported-contract coverage show no original whole-operation call from the promoted V2 path. V1 is still separately callable for comparison. The full positive, negative, resource and outcome corpus retains its results, with correct supported outcomes rather than new unsupported exits. Finish T04 after this gate so the remaining initial decode and recursive metadata adapter costs are also removed. T07 plus T04 establishes B completion, not C/D completion or a soundness theorem.

Dependency: T01, T03, T05–T06 and resolution of all observed supported declines. T02 is a separately measured optimization, not a semantic prerequisite; T04 follows the fallback-free gate.

### T08 — close the finite authentic Arena discrepancy queue

Owners: source rule identified by each case; harnesses `scripts/pskernel-arena-replay.mjs`, authentic profile/compare scripts and pinned official-reference fixtures. Preserve archive hashes and original bodies. Start each defect from the exact request/declaration index at which production diverges, with native V1, DAG and generated observations separated.

The exact baseline full run39622318341/generated119299676175 is terminal FAIL:193 recorded,172 matching outcomes(105 acceptance,59 kernel rejection,one metadata rejection,seven transport rejection),two separately classified safety agreements,17 host timeouts,one resource exhaustion and one unsupported case. Zero-based timeout IDs are23,72,78,80,82–87,90–94,96,98; Church is81 and the currently unsupported safe recursor-headed occurrence is16. These are distinct from one-based console case numbering. No false-accept/false-reject classification occurred in this receipt; that observation does not prove their global absence.

| Work item | Required experiment and correction |
| --- | --- |
| T08a Church numerals resource exhaustion | Replay the exact original request natively and generated at4096. The existing pinned369bee native receipt fails request3's theorem admission in0.689667534s, so this is not only generated-host overhead. First add a host-only staged probe for header/isProp/body-check/final-DefEq through existing unchanged APIs, threading actual returned sessions, and assert its outcome equals unmodified admission. Trace only the first failing stage. Then replace the demonstrated repeated reduction/substitution/DefEq work with a sharing-aware algorithm and prove/compare its recurrence and correctness. Do not increase fuel or special-case the fixture |
| T08b Init prelude and other timeouts | Use exact timeout indices from the newest terminal 193-case receipt. Measure kernel-entry versus transport time, unique nodes, lookups and fallback counts. Resolve one common source hotspot at a time and test all affected original cases under the existing 60-second/2048-MiB-old-space limits |
| T08c Safe invalid recursor-headed occurrence | Qualify the narrow safe-only guard in `Admission/Inductive/Ordinary/Constructor.lean` and its precise `rejectedInvalid` diagnostic. Apply after the existing full-WHNF/direct-recursive/Π sequence, requiring target in the reduced term and live returned-session `recInfo` head. Require unchanged authenticated case16 to match official rejection. Preserve valid reducible/nonrecursive/nested controls and existing unsafe/erased-original-only outcomes. Do not reroute singleton numNested0 inputs or reclassify generic unsupported diagnostics |
| T08d Two unsafe/partial contract disagreements | Compare exact official outcome, exported declaration safety and adapter policy. Preserve the scoped default provider's explicit restrictions. Align the broader Arena entry contract with the official checked semantics through an explicit documented typed capability if justified; otherwise keep C blocked. Do not relabel agreements as matches, change the denominator or weaken the existing gate |
| Any new mismatch | First separate transport, kernel rejection, unsupported, resource and host failure. Fix production semantics or a demonstrated protocol defect with an independent official control |

Acceptance: all 193 original records execute, official reference remains 122 accepted/71 rejected unless a demonstrated upstream input/reference correction is separately documented, and the unchanged full comparison gate passes. Preserve case-level outcomes and evidence. Two intentional safety disagreements remain blockers to strict parity until resolved explicitly. Faster diagnosis alone does not resolve a case.

Dependency: T00; run in parallel with B only when the fix has a separate owner and a clear source dependency. Default runtime currently uses V1, so a DAG microbenchmark improvement does not by itself solve a provider/Arena V1 timeout.

### T09 — qualify performance and build reuse

Owners: `scripts/pskernel-expr-v2-dag-bench.mjs`, `pskernel-expr-v2-admission-bench.mjs`, whole-JS/memory/profile scripts, relevant Linux workflows, `../PERFORMANCE_2026-10-21.md`.

**T09a — performance:** freeze baseline and candidate generated bundles by source SHA; run them on the same runner in isolated ABBA order with the same Node/Lean/compiler/toolchain and fixtures. Keep assertions outside timed windows, fresh sessions where specified, construction separate, cold and warm observations separate, and memory accounting labelled (RSS, retained heap, old-space cap and cgroup charge differ). Report all groups, failed runs and dispersion, not only gains. Repeat only if a new change, failed check or unresolved variance justifies it.

Known historical hotspots are binder32 admission, chain32 admission, projection8 WHNF, unique/collision128 cache paths and DAG construction/metadata import. At carrier4894, binder32 is 554.792 ms DAG versus 260.326 ms V1 and construction 87.211 versus 0.730 ms; these are same-run architecture comparisons, not causal before/after results. Use the latest complete source-bound receipt for actual release decisions.

Acceptance thresholds for D: zero functional/resource-regression failures; zero Arena timeout/resource/unsupported escapes; the recorded >1.5× whole-operation regressions must be removed or explicitly retain D as open; no new median >10% slowdown or peak-RSS/retained-heap >15% growth across the published comparable groups without a documented, reviewed correctness tradeoff. For noisy samples, keep the result inconclusive and rerun one controlled same-run batch rather than adjusting thresholds. Construction cost must be reported and must not grow superlinearly in unique DAG nodes. Approaching official Lean is a measured goal, not a fixed promised ratio.

**T09b — CI reuse:** build optimization comes after usable cache identity exists: key Lean/compiler/TypeScript caches by exact toolchain, lockfiles, build graph and relevant source digest; never restore outputs as qualification for a different source. Separate native focused regressions from the full generated/canonical/final Arena qualification. Reuse immutable build artifacts within the same exact run; never replace proof checking with a cache receipt.

Dependency: baseline T00; per-fix measurements accompany every implemented item; final D follows B/C.

### T10 — formal obligations and release handoff

Owners: existing `test/PsKernel*Proofs.lean`, new focused proof fixtures, `PROVIDER.md`, artifact manifest and packaging scripts, the four handoff documents and `AI_WORK_STATE.md`.

**T10a — local refinements:** retain the checked local metadata, scope, equality, fuel-worker, ownership and cache lemmas with axiom audits. Add refinement statements for new lookup workers, unique-node traversal and stateful callbacks.

**T10b — global obligations:** open global obligations are validated-arena/source-expression correspondence, substitution/lifting refinement, checked/infer-only and context soundness, WHNF/DefEq semantic preservation, inductive/admission correctness and generated-backend preservation. Finite differential tests and local equations do not discharge them. Do not add unchecked axioms to turn open obligations into theorems. These open theorems must be reported honestly; they do not retroactively invalidate the narrower test-qualified A contract.

**T10c — artifacts and handoff:** package native Linux executable, readable generated `.ts`/`.js`, declarations, maps and referenced map sources, strict wire adapter/runtime closure and complete canonical `.ps` sources. Detached empty-PATH execution must require neither Lean nor a compiler at runtime. Manifest hashes bind source/run/artifact identity, never kernel truth. Recheck moved artifacts and exact toolchain hashes.

Acceptance: exact final implementation SHA has terminal mandatory gates, reproducible artifacts and case-level/performance receipts; A/B/C/D are reported separately; open formal theorems are listed honestly; continuation queue has a single next task. Main merge and npm publication require separate authorization.

## Efficient development cycle

Use one integration owner, one coherent source batch and one exact final full qualification per batch. Independent source reading, test design and proof review may run in parallel. Do not run competing large rewrites on the same owner modules.

1. Read the next open row and the named source; fetch HEAD and existing CI.
2. Reproduce on the original authentic fixture; state one falsifiable root cause.
3. Implement the smallest coherent slice, native/generated positive and negative controls, and any local refinement proof.
4. Run the narrow native/portable gate first. Correct real failures without weakening assertions.
5. Run both generated routes, canonical reconstruction, existing provider controls and full proof gates at the candidate SHA. Compare the fixed authentic cases and same-run performance.
6. Run/observe the final full193 gate once on the complete candidate; retain every outcome. Do not launch an overlapping full run merely to check status.
7. Record exact source and terminal job IDs in the matrix/work state, then move to the next dependent row. A measured failing gate remains open.

If the chat cannot finish, commit a coherent source checkpoint, preserve any last qualified SHA, mark unqualified implementation independently from evidence, list the precise failing command/case and next experiment, and update the ready-to-copy continuation. Do not claim background work continues after the chat ends.

## Concrete T03a implementation recipe


Read-only implementation recipe at source `4f6303fd90742ccc5e3d4f56b65dc658a7fb0eb5`. Paths below start at `psc1/packages/pskernel-core/src/Ps/KernelCore/`. This preserved recipe now specifies the implemented T03a bridge at `7b14affc854e7bc99e4778ac155ae805dd273226`. It does not claim an admission rewrite, eager-decode removal, persistent-session importer or performance qualification.

## Decision and source invariant

Use the **new prefix of the successfully admitted final environment**, with the exact previous environment as its boundary. Do not derive mutual/nested auxiliary names from request names.

`Environment/Operations.lean::psKernelEnvironmentAddUnchecked` prepends every added constant. Mutual admission validates fresh names and returns `work2` built by new headers, constructors and `psKernelAddMutualRecursorInfos` (`Admission/Inductive/Mutual/Admission.lean`, final success). Nested admission restores from the **original** base environment: `Nested/Restore.lean::psKernelSimpleNestedAddOriginals` receives `base`, its workers prepend restored family types/constructors/recursors, and `psKernelSimpleNestedAddAuxRecursorsWorker` prepends the final renamed auxiliary recursors. Flattening-only families are excluded. `Nested/Admission.lean` validates that final environment before returning it.

Therefore, for these three successful command kinds, final constants are a prefix of newly admitted names followed by the old constants. Scan that prefix until the first name present in the previous environment. Use `psKernelEnvironmentContains previous name`: `Environment/Lookup.lean` uses the exact name comparison after the existing indexed candidate lookup. Neither hash equality nor name shape authorizes admission. Stop immediately at the first old entry; do not call `psKernelEnvironmentSize`, compare complete environment tails, scan all constants for each command, or compare pointer identity. An initially empty environment scans exactly the new set.

This invariant is supplied by the existing checked admission algorithms, not by caller-supplied metadata. Keep the bridge internal to the successful `RunCommandsWithSource` branch. A general arbitrary-environment diff API is not required. Future admission changes that replace existing declarations must update this invariant rather than silently reusing the prefix worker.

## Exact code changes

1. Add an explicit-argument structural worker in `API/DagGenerated.lean` with the following intended signature (names are proposed):

```lean
psKernelDagGeneratedInstallNewPrefix
  (remaining : List PsKernelConstantInfo)
  (previous : PsKernelEnvironment)
  (inputRefs : List PsKernelExprV2DeclarationRef)
  (state : PsKernelDagGeneratedState) :
  Except String PsKernelDagGeneratedState
```

On `[]`, return `state`. On `info :: rest`, stop if its exact name is already in `previous`; otherwise install that final checked `info`, thread the resulting state, and continue. This walks O(new declarations) entries, with existing environment-index probes. Existing hash collisions can add bucket work, but there is no O(total environment) walk. Preserve sequential import order. No new fuel parameter, prebuilt recursive closure, depth allowance or trusted path is needed.

2. Add `psKernelDagGeneratedInstallNewInfo info inputRefs state`. Handle final `recInfo` by the existing `psKernelDagGeneratedInstallRecursor`, which imports the actual final type and every actual final rule RHS and prepends the `recursorDecl` owner. Handle `inductInfo` and `ctorInfo` by reusing a matching current-command input ref or importing their final `base.type` through `psKernelDagGeneratedImport`, then constructing `inductiveDecl`/`constructorDecl` with no delta body. An unexpected new declaration kind in the selected inductive transaction is a distinct internal invariant error, not successful skipping or an invalid-proof verdict.

Reuse lookup must inspect only `inputRefs`, **not the full accumulated state.declarations list**. Construct it with `psKernelDagDeclarationsAfterAdmission request []`. For ordinary/mutual requests the existing source explicitly guarantees original family/constructor types are installed unchanged; their original IDs are already published into the private `nextExecution.declarations`. Validate name/levelParams/kind using `psKernelExprV2DeclarationRefMatches` before reuse. This predicate does not itself establish type equality: the successful admission plus unchanged-type source invariant does. No new caller authority is introduced.

For `nestedInductive`, that existing helper intentionally returns no original refs, so import all final restored family/constructor types and recursor metadata. Do not add raw nested input types to `DagDeclaration.lean`: restoration may have changed their representation. Likewise, never expose flattened auxiliary-family IDs that are absent from the final environment. Missing final types and renamed auxiliary recursors are found automatically by the prefix, without inventing suffix conventions.

3. Add the production entry:

```lean
psKernelDagGeneratedAfterCommandWithPrevious
  (command : PsKernelDagCommand)
  (previous current : PsKernelEnvironment)
  (state : PsKernelDagGeneratedState) :
  Except String PsKernelDagGeneratedState
```

For admitted ordinary/mutual/nested inductives, derive command-local `inputRefs` and call the prefix worker on `current.constants`. For every other command, return state unchanged. Leave Quot, definitions and T03b preexisting-session import outside this slice. Preserve the existing `psKernelDagGeneratedAfterCommand command environment state` signature and its current bounded ordinary behavior as the compatibility helper; do not attempt to fake a previous environment from the new one.

4. Change only the production call in `API/Dag.lean::psKernelDagRunCommandsWithSource` to pass `execution.session.environment` as `previous` and `nextExecution.session.environment` as `current`. Retain the initial `input` table unchanged. `generated` still starts with the current working arena/built table and already admitted current-command refs. Successful import returns an appended arena/built table and all owners; recursive commands continue through that working state while external IDs are checked only against the original `input` namespace. Do not change any public command/RunDag ABI.

Import failure returns the existing `internalError` branch before recursive publication. Admission results and staged refs are local values; neither a receipt nor partial session escapes when a later import or command fails. Do not turn an import failure into a V1 acceptance or silently publish only the first family.

## Focused qualification fixtures

Extend `test/PsKernelExprV2RecursorRegression.lean`, its JS smoke script, and the existing recursor proof fixture/workflow targets; preserve all old counts/controls and add distinct new markers.

| Fixture | Required observations |
| --- | --- |
| Two-family genuine mutual inductive | Admit the existing checked mutual fixture, install both final recursors, retain every original family/constructor input ID, and directly execute each recursor/iota plus check/DefEq without an outer fallback. Compare official Lean and V1 |
| Genuine accepted nested inductive | Reuse an existing checked nested fixture or independently admit List plus a Tree/List Tree nested family. Require final restored family/constructor refs and every final renamed auxiliary-rec type/rule owner; no flattening-only owners. Execute an authentic nested recursor reduction and type check |
| Nested request with no discovered auxiliary family | Exercise the dispatcher's ordinary/mutual fast branch; final owners still complete and no duplicate imported input IDs are claimed |
| Names/universes | Structured namespaces, numeric name components, nonzero initial arena IDs, multiple universe parameters and constructor families with overlapping suffixes. Final checked metadata decides membership; mismatch/absence probes cannot authorize direct reduction |
| Namespace and atomicity | After generated nodes append, a later external command using a private appended ID remains invalid. A late invalid command/admission returns no partial batch. Internal late-import failure test returns internalError with no published partial owners |
| Delta cost and boundary | Install a substantial old checked environment plus a tiny new mutual/nested batch. Diagnostic visit count equals the new prefix and stops at first old name. Existing declarations/owners are unchanged; no scan of the old tail and no `EnvironmentSize` prepass |

Run native, both authentic generated routes, canonical source reconstruction/checking, retained K/major/state/resource negatives and local proof/axiom audits on the exact candidate. Keep this ownership bridge explicitly transitional: inductive checking still uses V1, generated-expression import remains recursive, and B is still open. The initial existing-session constants remain T03b, not an implicit side effect of this delta.

## Preserved earlier status snapshot

The following dated snapshot is historical; the current execution receipt above supersedes its pending-run instructions. Its source-bound failures and observations remain in the work-state and evidence history.

Handoff snapshot: **2026-10-21T16:50:08.474Z**. Executable implementation: `034999734f2574876a747c967dd03bcc6904b395`; **not yet fully qualified**. Latest fully qualified scoped A: `3aa077cb64ff06f76727decd01c43ad6c33f351d`. Native predecessor464 passed integration119339896857 and correctness119339896783; its generated/canonical and one research job were still active. The candidate's official Arena reference119352847788 passed; its native/generated/canonical/research comparison jobs were queued. See [final source-bound receipt](../evidence/2026-10-21-final-handoff.json), newest work-state, and live Actions before promotion. Full Arena C and performance/release D remain separate from scoped A.
