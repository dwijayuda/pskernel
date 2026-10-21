# PSKernel-Core Expression V2 integration work state

Date: 2026-10-21 (Asia/Jakarta; Actions timestamps use UTC)
Status: **IN PROGRESS — independent developer kernel; complete V2 and Arena gates remain open**
Integration branch: `integration/psc1-pskernel-expr-v2-lean435-20261021`
Lean: `leanprover/lean4:v4.35.0`, exact commit `eb6cafb7290e8bd5f2937522d8d804f58f02bafc`
Generated path: authentic PSC1 → TypeScript `7.0.2` → Node `22`. Full-kernel DirectJS is unsupported.
Default kernel fuel: **4096**, unchanged. No new runtime axiom or trusted reduction path.

## Evidence identity and history

This file is the current summary. [The complete earlier work-state](history/AI_WORK_STATE_2026-10-21_BEFORE_PROVIDER.md) is retained verbatim; its historical “pending” sections do not override the receipts below. A manifest or an earlier green source does not qualify a later commit. Final qualification must use terminal Actions results for the exact source SHA.

## Implementation checkpoint being qualified

This revision adds the default-fuel native/generated canonical-admissions provider and deployable artifacts, advances the one DAG DefEq owner through proof irrelevance, threads same-batch declaration IDs into public DAG DefEq, and introduces authentic Arena timeout profiling. The unchanged original checker remains selectable and remains the provider's declared checked algorithm. The new DAG slice does not make V2 the default.

The retained implementation commits are `2df356a48e92a1fa46e59306f913985a83db0f92` (authentic Arena profiles), `ce7a92d8f7206fd05dba33a89930afa4ddb51fef` (DAG proof irrelevance with 1,350 native/generated comparisons), and the containing provider/integration commit. These commits are source identities, not test receipts.

The foundation commit is `0987be5a059fc6698541a5d376cf98c814b6fd80`: exact extraction of the existing wire constructors into a dependency without prelude loading or resource mutation; complete legacy package dependency/integrity maintenance; and source-bound SHA-256 manifests including source-map source files. Native executables are packaged in a tarball to preserve execute permissions. Canonical artifacts include the complete generated .ps workspace.

The provider is implemented in `host/kernel-provider/KernelProviderMain.lean` and `scripts/pskernel-canonical-provider.mjs`, documented in `PROVIDER.md`, and tested by `scripts/pskernel-provider-smoke.mjs`. It starts from an empty checked session and returns no partial environment. The 16 process cases copy the executable/runtime closure into a fresh detached directory and run with PATH empty; process failure or timeout is never a semantic rejection. `test/PsKernelProviderOfficial.lean` checks the exact valid four-declaration batch and four semantic negatives through official Lean with `doCheck=true`. Unknown transport fields (including unsafe/recursor/environment metadata) are declined; missing required fields and invalid numeric encodings are malformed. The transport scope is safe regular definitions, theorems and checked inductive groups.

**New-source qualification is pending terminal CI for the containing integration SHA.** Older PASS rows below are source-specific. The new native and generated proof-irrelevance matrices, strict provider negative tests, canonical full-closure checks, local proof gates, original regressions, full comparison and authentic diagnostic profiles must execute before their respective readiness claims are promoted.

The new profiling workflow is diagnostic only: it preserves original authenticated bodies, default fuel 4096 and the generated host limit of 60 seconds / 2 GiB. Producing a profile or a diagnostic artifact never qualifies an Arena case.

### Execution-tool interruption and recovery

Child-agent GitHub tree writes twice failed to return receipts after approximately 1,013 and 733 seconds. No branch update was attempted by those calls. The calls were interrupted, the complete source was transferred to the parent, and parent-owned GitHub writes returned tree/commit receipts. All repository work remains GitHub-only; no local checkout, build or test was substituted. Future writes use the parent tool path and fresh non-force expected-SHA updates.

## Verified starting checkpoint

The branch was fetched at `49a5df0820216db35c3cbf562172b754b82a03b1`, three commits after the earlier green `38dfe75658a1d723b993904a8d510fb449e6bba0`. The material changes were the ordered DAG DefEq prefix, unsafe/partial mutual admission with fresh per-member owners, and a native test record-layout correction. No newer valid work was reverted.

At `56559c794a93e828cb89ded1b0ed535f93570b69`, [generated integration 39539663203](https://github.com/dwijayuda/pskernel/actions/runs/39539663203/job/119024254755), [both correctness jobs 39539663174](https://github.com/dwijayuda/pskernel/actions/runs/39539663174), and [all six research jobs 39539663281](https://github.com/dwijayuda/pskernel/actions/runs/39539663281) passed. The native integration job failed to parse a test fixture at line 4227; this was a fixture syntax defect, not a passing native qualification. The canonical gate reconstructed **120 modules**, audited **163 portable modules across two roots**, independently checked and compiled the complete .ps closure, and executed its real checker with PATH empty.

At `49a5df0820216db35c3cbf562172b754b82a03b1`, [native integration job 119045258568](https://github.com/dwijayuda/pskernel/actions/runs/39546338992/job/119045258568) passed the full native matrix, including all 280 mutual cases, eight checked official mutual fixtures, fresh-member sentinels, binder/prefix/unsafe/theorem rules, local proofs and benchmarks. The corrected native fixture is the only source difference from 56559c7.

Both jobs in [integration run 39546338992](https://github.com/dwijayuda/pskernel/actions/runs/39546338992) are now **terminal PASS at the same 49a5df0 SHA**. Generated execution passed all semantic markers, 1,008 inference-only comparisons, 128 guarded operation observations, 24 admission observations, strict whole-executable checks and all six profiles. The compiler emitted 5,921,796 bytes of JavaScript plus declarations and maps. Native and generated mutual-definition qualification is no longer pending.

| Exact SHA | Native integration | Authentic portable .lean | Canonical .ps | Generated JS | Local proofs | Full integration benchmarks | Full Arena | New provider |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `56559c794a93e828cb89ded1b0ed535f93570b69` | FAIL (fixture syntax) | PASS | PASS | PASS | NOT RUN (blocked native job) | NOT RUN (native); PASS (JS) | FAIL (24 timeouts) | NOT RUN |
| `49a5df0820216db35c3cbf562172b754b82a03b1` | PASS | PASS | NOT RUN | PASS | PASS | PASS | NOT RUN | NOT RUN |

The 49a5df0 fixture-only commit did not trigger canonical, correctness, research or Arena workflows. Their earlier green results are recorded for their own SHAs, not inherited. The next implementation push explicitly re-runs every required gate.


## Full Arena remains incomplete

[Latest completed full comparison 39539663267](https://github.com/dwijayuda/pskernel/actions/runs/39539663267) at `56559c7` evaluated all **193** cases:

| Recorded outcome | Cases |
| --- | ---: |
| Matched kernel acceptance | 103 |
| Matched kernel rejection | 56 |
| Matched metadata rejection | 1 |
| Matched transport rejection | 7 |
| Explicit unsafe/partial safety-contract agreement | 2 |
| Host timeout (60 seconds, 2 GiB) | 24 |
| Total | 193 |

The timeout set contains **19 official acceptances and five official rejections**. All 24 timeouts reached the public RunDag kernel-admission boundary; snapshots do not distinguish validation, decoding and admission internals. Official Lean's corresponding reference job passed **122 accepted / 71 rejected / zero timeouts**. Body bytes remain authenticated with the historical header adapted to the 4.35 pin. The independent gate correctly failed. Neither the 167 matching outcomes nor the two contract agreements mean 169 independently admitted proofs.

The recorded timeout set is preserved by case number and exact archive entry:

| Case | Archive entry | Official outcome |
| ---: | --- | --- |
| 14 | `bugs/proj-of-stuck-prop.ndjson` | rejected |
| 15 | `bugs/proj-of-subst-prop.ndjson` | rejected |
| 17 | `bugs/rec-missing-ih.ndjson` | rejected |
| 18 | `bugs/rec-of-subst-prop.ndjson` | rejected |
| 24 | `perf/refute-cheap-last.ndjson` | rejected |
| 73 | `init-prelude.ndjson` | accepted |
| 79 | `perf/app-lam.ndjson` | accepted |
| 80 | `perf/args-before-unfold.ndjson` | accepted |
| 81 | `perf/beta-ladder.ndjson` | accepted |
| 82 | `perf/church-numerals.ndjson` | accepted |
| 83 | `perf/discarded-argument-match.ndjson` | accepted |
| 84 | `perf/discarded-argument.ndjson` | accepted |
| 85 | `perf/folded-constant-first.ndjson` | accepted |
| 86 | `perf/folded-constant-last.ndjson` | accepted |
| 87 | `perf/fueled-chain.ndjson` | accepted |
| 88 | `perf/grind-ring-5.ndjson` | accepted |
| 91 | `perf/let-ladder.ndjson` | accepted |
| 92 | `perf/magma-list-deep-n21.ndjson` | accepted |
| 93 | `perf/magma-list-deep-n36.ndjson` | accepted |
| 94 | `perf/magma-list-pair-n21.ndjson` | accepted |
| 95 | `perf/magma-list-pair-n7.ndjson` | accepted |
| 96 | `perf/repeated-subproblem.ndjson` | accepted |
| 97 | `perf/shared-subterm.ndjson` | accepted |
| 99 | `perf/unroll-versus-evaluate.ndjson` | accepted |

## Deployment and architecture gates

- **A — usable developer kernel:** current source/provider changes must pass native, full portable closure, canonical .ps, generated JS and independent provider CI at the same final SHA before this is marked achieved.
- **B — complete DAG replacement:** **NOT ACHIEVED**. Legacy decoding, external-session declaration types, general DefEq continuations, recursor/iota and inductive admission still require work. V1 remains separately available and the default/reference contract.
- **C — complete Arena compatibility:** **NOT ACHIEVED**, with 24 unresolved host timeouts in the latest completed complete comparison.

The native and generated providers must own their sessions, check every supplied declaration, and publish a batch result only after complete checking. Resource exhaustion, unsupported transport and internal errors are distinct from semantic rejection. The old npm-runtime prelude entry that raises fuel to 131072 is not the new provider entry point.

## Performance interpretation

The complete 56559c7 generated integration recorded all **128** guarded operation observations, **24** admission observations and six diagnostic profiles. On the same runner, unique-function WHNF128 was **1375.926–1387.380 ms V1 / 603.417–625.091 ms DAG**, and collision WHNF128 was **3746.170–3763.454 / 2608.680–2626.384 ms**. These supersede the earlier timing regressions for these fixtures only. They do not isolate the scanner refactor's causal effect.

Construction remains more expensive: the five-input unique pool cost **2.393–2.422 ms V1 / 77.926–78.772 ms DAG**; retained heap is mixed. Complete safe-admission warm mean ratios on six selected fixtures range **8.77×–17.58×** in this run. These are workload-specific observations, not a whole-kernel or Arena speedup claim. Preserve the raw run logs and artifact receipts when comparing later changes.

## Remaining whole-operation fallback inventory

There are **four explicit V1 whole-operation fallback sites**, counted as public operation families (not as every internal `Option.none` rule):

| Operation | Owning file and fallback |
| --- | --- |
| Checked expression inference | `API/Dag.lean`: `psKernelDagCheckTerminalOrOriginal` calls `psKernelV1CheckExpression` |
| WHNF | `API/Dag.lean`: `psKernelDagWhnfExpression` calls `psKernelSessionWhnf` |
| DefEq | `API/Dag.lean`: `psKernelDagIsDefEq` calls `psKernelSessionIsDefEq` |
| Declaration admission | `API/DagAdmission.lean`: `psKernelDagAdmitDeclaration` calls `psKernelV1AdmitDeclaration` |

The entry boundary still validates then decodes the complete arena into physically shared recursive expressions; checked inference and WHNF decode new result nodes; declaration requests are decoded before their direct admission attempt. Moving proof irrelevance into the DAG owner removes one unsupported rule family, not these four fallback sites. General lazy delta/full-shape/eta rules, recursor/iota, externally owned environment types and direct inductive admission remain incomplete.

## Formal status and remaining work

Local metadata, scope/cache guard, numeral recurrence and scanner equivalence lemmas pass at the native checkpoint above using the previously approved proof-file dependencies `propext`, `Classical.choice`, and `Quot.sound`. They do not introduce kernel runtime axioms and do not prove global soundness, validated-arena correspondence, full substitution refinement, DefEq or admission.

Continue through the real highest-priority failing gate. Keep complete V1 fallback until each replacement is qualified; preserve exact recursive fuel/depth/callback placement, cache owner scope, failure order and atomic publication. Do not merge, publish npm, increase policy limits or count a timeout as rejection.
