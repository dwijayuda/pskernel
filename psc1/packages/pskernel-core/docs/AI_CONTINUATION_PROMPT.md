## T01F mixed diagnostic timed out — V1 conversion/reduction bottleneck

Observed 2026-10-23 WIB. Exact harness `9248c474d705ffaa4a1aba8a0aa7a4ce54e4a303`
reused authenticated generated source `19fb4b0b8f52808d6a31705185018d6e60836d8e`
in [run39848120108](https://github.com/dwijayuda/pskernel/actions/runs/39848120108).
Retained controls job120066753317 PASS: DAG115.11s/628496KiB, prefix/session
28.17s/422628KiB,605 prefix assertions and all prior-session owner markers.
Mixed job120066753711 CANCELLED at the unchanged25-minute whole-job cap.
All294 requests and377 metadata comparisons completed. The mixed singleton
sequence passed, but the complete case and later UTF8/validity/negative groups
did not finish. No assertion failure or heap exhaustion was observed; there
is no completed mixed peak-RSS result or qualification receipt.

The347 completed trace calls record913.757s in21 V1 DefEq calls and212.937s
in3 V1 WHNF calls. UTF8 literal DefEq took220.158s; its WHNF127.355s.
The interrupted call348 is V1 DefEq in utf8-literal-left. These are diagnostic
outer-API times, not a controlled speedup or internal hotspot attribution.
Both successful/unfinished artifacts and every completed trace record are
retained in `evidence/2026-10-23-t01f-focused-diagnostic.json`.

The full final-suite drafts were reviewed (old steps preserved, exact source/
run/attempt/provider identities, six unique receipts, clean runtime exit and
raw logs/memory revalidation), but remain INACTIVE because the focused mixed
case cannot finish within its cap. The old focused push trigger is disabled
to avoid an accidental duplicate25-minute run. A separate bounded180-second
V8 profile targets the measured V1 UTF8 literal WHNF after unchanged complete
fixture admission, corrupt-definition control and metadata comparison.
It derives a diagnostic driver only; the full acceptance runner is unchanged.
The new profile workflow is `.github/workflows/psc1-pskernel-t01f-v1-profile.yml`.
Its containing source and terminal result must be fetched; no profile success
or source qualification is claimed in this update.

Production remains19fb. Integration remains123c411; native singleton evidence
remainsa368 and complete scoped A remains9c87. B/C/D remain open. Do not activate
the final suite or start T05 until a genuine hotspot fix lets the complete
unchanged mixed preflight pass under the existing cap. Do not raise limits,
suppress V1 parity or replace real declarations.

---

# Continue PSC1 PSKernel-Core — GPT-6.1 Sol, High reasoning

You are the principal Lean 4 kernel engineer and formal verification researcher continuing the authorized implementation of `dwijayuda/pskernel`.

This is an implementation assignment. Implement, test, fix and qualify coherent changes; do not stop at another architecture audit or research report. Work autonomously within the authorization and constraints below.

## 1. Recover live state before changing anything

- Repository: `dwijayuda/pskernel`.
- Integration branch: `integration/psc1-pskernel-expr-v2-lean435-20261021`.
- Active T01F work branch: `work/psc1-pskernel-t01f-string-20261022`.
- Kernel: `psc1/packages/pskernel-core`.
- Lean: `v4.35.0`, commit `eb6cafb7290e8bd5f2937522d8d804f58f02bafc`.
- Authentic generated qualification: TypeScript 7.0.2 and Node 22.
- Target model for this continuation: GPT-6.1 Sol, High reasoning.

Fetch both live branch HEADs, recent commits, related research branches and existing Actions runs before any write or expensive CI. Identify concurrent completed work. Use non-force, expected-SHA branch updates and preserve concurrent changes.

Read, at the actual live revisions:

1. `psc1/packages/pskernel-core/AI_WORK_STATE.md` — the work-state file is inside the package, not the repository root.
2. `psc1/packages/pskernel-core/docs/AI_CONTINUATION_PROMPT.md`.
3. `docs/PSKERNEL_CORE_COMPLETION_PLAN.md` and `docs/PSKERNEL_CORE_PROGRESS_MATRIX.md`, relative to the package.
4. `docs/T03B_SESSION_OWNERSHIP_QUALIFICATION.md` and `evidence/2026-10-22-t03b-terminal-qualification.json`.
5. `evidence/2026-10-22-t01f-handoff-checkpoint.json`.
6. `docs/drafts/t01f-final-shards/README.md` and the saved draft files described there.

This handoff deliberately saves unfinished work without launching CI. Its containing commit is an **unqualified harness/documentation checkpoint**. Resolve its exact SHA from the live work branch and keep it separate from all tested sources below. The final-suite drafts are ordinary files under docs, not installed workflows.

## 2. Exact checkpoint identities: do not conflate them

Last observed integration HEAD:
`123c41197950b6761be965fd21c57142ee2b0d1c`.

This is a documentation child of the historical qualified source.

Last complete scoped independent-checking qualification:
`9c87f631758862285273ddb0ea0a3987c671022e`.

That is the T03b executable checkpoint. It is not full Arena, performance, architectural or global soundness completion.

Current production lookup-worker source:
`19fb4b0b8f52808d6a31705185018d6e60836d8e`.

Last native-tested singleton harness:
`a36839347269d05f5a79d6103a7a4b0ddab1bdb1`.

The work branch was at a368 immediately before this handoff commit. The handoff adds strict generated sample selection, a prepared artifact-reuse diagnostic workflow, documentation and saved final-suite drafts. These additions have not executed in CI. Production Lean kernel code is unchanged from 19fb.

Never transfer qualification from 9c87 to 19fb, a368 or the handoff. A source hash, authentic artifact, passing native subset or successful compilation does not establish complete qualification.

## 3. T01F implementation already completed

Do not recreate artificial fixtures or duplicate this work.

The genuine fixture is `psc1/test/PsKernelExprV2StringEnvironmentRegression.lean`, with generated runner `psc1/scripts/pskernel-expr-v2-string-environment-smoke.mjs`.

The pinned Lean implementation is the actual byte-array-backed String:

- constructor `String.ofByteArray`;
- fields `toByteArray : ByteArray` and its UTF-8 validity proof;
- `String.ofList data` uses `List.utf8Encode data` and the actual validity constructor/proof.

The native host obtains actual pinned-Init declaration inputs for the transitive closure rooted at `String.ofList`, `Char.ofNat` and `UInt8.ofNat`. Starting from an empty PSKernel session, **294 raw requests produce 377 independently admitted declarations**. All 377 admitted metadata records are compared afterward with the actual source records. Source metadata is untrusted expected output, never installed as checked authority. This closure admitted **zero source axioms**.

Six unchanged samples:
`""`, `"a"`, `"é"`, `"€"`, `"😀"`, `"Aé€😀"`.

Existing tests cover genuine constructor reduction, recursive List/Char expansion, byte and validity-proof projections, nested String→ByteArray→Array projections and exact UTF-8 byte lists. They compare official Lean, V1 and direct DAG behavior, require direct workers not to decline, and exercise public check/WHNF/DefEq.

The a368 harness adds separate singleton check → WHNF → DefEq calls for every sample, threading valid returned sessions and preserving exact environment/index/resources/provider ownership. Batched/reused calls remain.

Negatives include a corrupted actual String.ofList body, invalid field2, wrong List argument, forged validity proof, wrong universe arity, rejection across public operations, a valid call after rejection, unequal strings and isolation of the original empty session. Preserve all negatives and the separate minimal String-environment receipt.

The only production change is an explicit-argument declaration-reference lookup worker in:
`src/Ps/KernelCore/Checker/ExprV2/Environment.lean`.

It retains the exported curried ABI, immutable declaration list, exact Name equality, first matching full record, order and misses. The old implementation already deferred traversal of the tail. This change targets per-visited-entry generated closure/dispatch overhead; it is not an eager importer or indexed-cache experiment.

`psc1/test/PsKernelCacheScopeProofs.lean` contains an exact pre-change specification and:
- `psKernelExprV2DeclarationRefFindWorker_eq_before`;
- `psKernelExprV2DeclarationRefFind_eq_before`.

These are local equivalence theorems, not global kernel soundness or compiler-preservation proofs.

## 4. Exact completed and incomplete qualification

### a368 native singleton preflight: PASS

Run: https://github.com/dwijayuda/pskernel/actions/runs/39829443557
Job: https://github.com/dwijayuda/pskernel/actions/runs/39829443557/job/120001370021

Exact source: `a36839347269d05f5a79d6103a7a4b0ddab1bdb1`.

All six authentic cases and all six singleton sequences passed, with 294 requests/377 metadata records, corrupt-declaration and expression negatives, retained minimal String/public DAG and T03a/T03b native/official controls. There were 74 local theorem reports: 60 CacheScope and 14 Session. Nineteen were axiom-free; the remaining reported assumption union was only propext, Classical.choice and Quot.sound. Both new lookup equations passed; no sorryAx.

Whole native job: 134 seconds. Authentic String execution: 8 seconds. This is native qualification for that exact source and scope only.

### 19fb fresh generated preflight: incomplete, CANCELLED

Run: https://github.com/dwijayuda/pskernel/actions/runs/39827244691
Native job119993677370: PASS.
Generated job119993676851: CANCELLED at the unchanged 25-minute whole-job cap.

Actual complete kernel source checking, fresh TypeScript/JavaScript compilation and authentic fixture production succeeded. Setup/build consumed about 839 seconds; detached runtime ran about 676 seconds before cancellation.

Empty and ASCII cases completed, including their negatives. The third sample, é, was interrupted during V1 WHNF. Later samples and retained generated DAG/prefix steps did not complete. No assertion failure or heap exhaustion was observed. There is no full-matrix PASS and no completed peak-RSS measurement.

Do not describe this as either a semantic failure or successful full qualification.

### Reusable diagnostic artifact

Run39827244691, artifact12447224834:
`psc1-t01f-generated-preflight`.

- Producer source: 19fb above; tree `f229557fc2f6d3b782a319710462dd29bb0c080a`.
- ZIP: 1,110,713 bytes.
- ZIP SHA256: `f899a7704c804d9c48ac54ee2cdd608f69497397b4f1378145e235b65126522b`.
- Exact primary suffix: `psc1/dist/expr-v2/integration/kernel.js`.
- Kernel: 9,953,467 bytes.
- Kernel SHA256: `cd6d03fe2da5b7e76bf40a7e3dba9e8315e2fb1a269f20f3108e29f77c49e5f5`.
- Raw fixture: 2,791,525 bytes.
- Fixture SHA256: `563d6ef138271a13039764257407ee8b66190bca02c8057489d3b1c45f51e71d`.

The prepared focused workflow additionally authenticates producer workflow/source bytes, individual successful source-check/compile/fixture steps, current harness bytes and the enclosing cancellation/skipped stages.

Do not require producer whole-run success for this diagnostic artifact: the run was cancelled after successful production. Do not infer qualification from authenticity. Select the exact primary path; basename kernel.js also matches a provider copy.

## 5. Immediate next action: finish T01F generated execution efficiently

First inspect whether concurrent work has already run the saved preflight or completed T01F.

The handoff installs the prepared:
`.github/workflows/psc1-pskernel-t01f-focus.yml`.

It authenticates and reuses the 19fb compiled artifact without rebuilding. It has separate retained-controls and mixed-Unicode diagnostic jobs:
- retained controls: 10-minute job;
- sample index5, Aé€😀: 25-minute job;
- Node22, empty runtime PATH, fuel4096 and 2048MiB old-space.

The saved generated runner accepts optional strict index0–5. Default invocation still executes all six cases. Each selected run independently admits all 294 requests, checks all 377 metadata records, executes the complete selected case, singleton sequence and negatives, and emits a distinct shard receipt. A shard PASS is never a full-matrix PASS.

Review the focused workflow and strict selector before triggering. They were statically inspected but not executed. Launch one exact-SHA preflight through authorized Actions dispatch if available, otherwise an expected-SHA work-branch push affecting its path filters; do not duplicate an existing run. Keep generated source identity19fb separate from the newer harness SHA.

Fix real source or harness defects. If the heaviest case exceeds its cap, use the trace to identify a concrete bottleneck; preserve semantics, assertions and limits. Do not hide a timeout or replace the genuine declaration environment.

## 6. Saved final-suite drafts: review and activate after preflight

Relative to the kernel package:
`docs/drafts/t01f-final-shards/`.

Prepared files:

- `psc1-pskernel-expr-v2-integration.yml` → existing integration workflow.
- `psc1-pskernel-core-correctness.yml` → existing core-correctness workflow.
- `pskernel-t01f-shards.mjs` → `psc1/scripts/pskernel-t01f-shards.mjs`.
- `paired-owner-job.fragment.yml` — the same proposed job is already included in the integration draft.
- `INTEGRATION_NOTES.md` and `README.md`.

These are complete text drafts, not executed qualification. Reconcile them against live files instead of overwriting concurrent changes. Finish reviewing helper copy/spawn/log/provenance boundaries before activation.

Each authentic route compiles once and adds six runtime-only case jobs:
- exact indices0–5;
- fail-fast false;
- max-parallel2;
- 25 minutes per case job;
- all assertions and negative controls retained;
- complete independent admission and metadata comparison in every shard.

This gives the complete matrix more aggregate CI time while preserving per-case caps and kernel/Node limits. It does not change the separate Arena policy.

Each route has an always-running aggregate gate that requires its producer and all six shards to succeed, reauthenticates source/run/attempt/artifact/harness/provider identities, and rejects missing, skipped, duplicate, cross-route or stale receipts. Require raw logs, singleton markers, timing and memory records. The complete marker is `PSC1_T01F_FULL_STRING_SHARDED_JS: PASS`. Collection does not imply performance qualification.

Routes:
1. Full Lean source → authentic PSC1 source check/build → TypeScript → JS.
2. Canonical .ps reconstruction and independent check → generated JS.

Both must pass on the **same final coherent source checkpoint**, with all existing native, official Lean, proof, negative, detached provider24/API8 and research gates retained.

Before one final full-suite push, inspect the three additional existing research/Arena/profile workflows and add the work branch trigger only where needed:
- `.github/workflows/psc1-pskernel-expr-v2.yml`;
- `.github/workflows/psc1-pskernel-arena435.yml`;
- `.github/workflows/psc1-pskernel-arena435-profile.yml`.

Keep their jobs and policies unchanged. Disable the focused workflow's push trigger for the full-suite checkpoint to avoid duplicate diagnostic work. Do not accidentally reinstall older monolithic drafts.

## 7. Performance and full Arena obligations

The final coherent source needs complete measurements, not selective successful samples:

- all native timing/construction/process-memory records;
- all whole-checker and admission ABBA observations;
- both authentic String routes, all six samples, complete timing/memory;
- retained workloads/profiles and Arena diagnostic collection;
- the unchanged paired initial-owner experiment.

The integration draft includes a 32-worker, 384-validated-call ABBA comparison with historical9c87. It uses the unchanged driver from commit
`4ebfd97b4588f8651e8b7a81bc00b2a05cfe1e3c`,
`psc1/scripts/pskernel-expr-v2-initial-owner-bench.mjs`,
SHA256 `7c8a82758b90958d973623d26e4c4dfbd900126cd737c190adffb76cb1563221`.

Authenticate both bundles, full provider manifests, producer source/run/steps and actual bytes. Use the same current Node runtime for both candidates. Preserve all observations, 60-second worker limits and 2048MiB old-space. No cherry-picking or passing-threshold changes.

The 19fb diagnostic measured first owner derivation4.950s and the first12 empty-sample public calls69.173s total. Historical profiled9c87 measured7.784s and101.039s. Node patch versions and profiler settings differed; this is **not a controlled speedup claim**. ASCII alone took53 V1 DefEq calls144.798s,8 V1 WHNF calls37.680s and29 public calls185.276s. No completed current peak-RSS result exists.

Run the complete unchanged193-case Arena at the final source: **60 seconds per case,2048MiB Node old-space,2workers**, with every original and adapted body hash preserved. Compare all individual cases and hashes, not just totals.

Last complete Arena, at9c87 only:
-173 matching:105 accepted,60 kernel rejections,1 metadata rejection,7 transport rejections;
-2 separate safety-contract agreements, not extra semantic matches;
-17 timeouts;
-1 Church resource exhaustion;
-0 unsupported.

Run: https://github.com/dwijayuda/pskernel/actions/runs/39694087862
Official job119547118244 passed; independent job119547747908 failed.
Official totals:122 accepted/71 rejected/0 timeouts.

Do not reuse those totals as a new-source result. Preserve Church exhaustion, Prelude timeout, Name memory regressions, owned-constant cold overhead and warm-path regressions as open evidence until new comparable results resolve them.

## 8. Non-negotiable trust and execution constraints

Use connected GitHub tools and GitHub Actions Linux runners. Do not run local builds, merge into main, force-push or publish npm packages.

Preserve fuel4096, exact environment ownership and session isolation, immutable admitted-declaration indexing, independent checking, checked/infer-only separation, universes/recursors, atomic successful-command publication, original/private ID separation, T03a/T03b/Quot/Name/proof controls and every rejection test.

No unchecked proof assumptions, hardcoded String recognizers, trusted imported metadata, artificial replacement declarations, weakened rejection behavior, suppressed cases or silent resource-limit increases.

Do not revive the held eager importer or indexed-cache experiment without demonstrated improvements under comparable independent benchmarks.

Full-kernel DirectJS remains unsupported. Never present this TypeScript/Node qualification as DirectJS support.

## 9. A/B/C/D and implementation order

A: historical9c87 has complete scoped independent-checking qualification. Current T01F work has native subset evidence only; complete generated/final-source qualification remains pending.

B: open. T01F must finish first. V1 ordinary/mutual/nested admission, recursive metadata import, eager decode and four public whole-operation fallbacks remain, subject to live verification.

C: open. Historical full193 Arena remains failed with the exact categories above.

D: open. Performance regressions and broader proof obligations remain. Local equations and benchmark collection are not global soundness, refinement or backend-preservation proofs.

Do not broaden into V1 inductive-admission migration until T01F passes its required gates. After that, consult the live plan and select the highest-value coherent dependency. Expected next task is T05 ordinary DAG inductive admission, then T06→T07; final T04a ingress removal depends on T07. T04b import work is a separate potential slice. Verify what concurrent development has already completed.

## 10. Completion and reporting

Continue successive coherent implementation batches while the session allows. Prioritize genuine correctness defects and measured bottlenecks. Keep updates concise and evidence-based.

For each batch, record exact source identity, inspect existing runs before expensive CI, perform narrow preflight, fix real failures, then qualify the final coherent source. Never claim a newer commit inherits an earlier result.

Update the existing work state, completion plan, progress matrix and exact-source receipts without deleting failed attempts or historical evidence. Integrate only through the authorized non-force expected-SHA policy after required qualification; never into main.

End with live branch/HEAD, exact executable and harness SHAs, completed features, passed/failed/incomplete CI links, all Arena counts, complete performance results/regressions, separate A/B/C/D states, concrete blockers and one highest-priority next implementation task.

If unfinished, save another ready-to-copy continuation with actual final refs and durable draft locations. Do not promise work will continue after the session ends.

Primary objective: finish a correct, useful, independently checking PSKernel-Core quickly, without compromising soundness or qualification integrity.
