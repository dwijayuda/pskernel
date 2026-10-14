# AI_WORK_STATE — PSKernel-C0 live checkpoint

**This is the current execution state, not the historical milestone log.** The full unabridged, non-deleted history is preserved in [AI_WORK_STATE_HISTORY_2026-10-15.md](AI_WORK_STATE_HISTORY_2026-10-15.md). Consult the [architecture-first CDE plan](C0_ARCHITECTURE_FIRST_CDE_PLAN.md) and its explicit phase exits before changing a trusted rule.

## Target, boundaries and fastest next action

- Repository: `dwijayuda/pskernel`; branch: `perf/pskernel-c0-v7-rust-20261012`; package: `psc0/packages/pskernel-c0/`.
- Pinned upstream: **Lean 4.35.0**; implementation is native `.lean`.
- GitHub is canonical. No Desktop Commander, original `pskernel-core`, PSC0 compiler, Rust/Wasm backend, self-hosting, force-push, or unrelated branch modifications.
- **FIRST ACTION ON RESUME:** Check latest native CI and real Lean 4.35 Init survey after the compiled-first 550,000-record acceptance change. Earlier [survey 38651094299](https://github.com/dwijayuda/pskernel/actions/runs/38651094299) PASSED the 300,000-record official/C0 acceptance gate, but its 420-second full run ended **inconclusive** after processing at least **550,000** records and checking **4,735** declarations. It did NOT return a C0 verdict. Next require a real 550,000-record *positive* official/C0 result, inspect elapsed/interval time per 50k records, then fix the general throughput or next same-byte compatibility blocker. Full 6.45M Init, Std, Mathlib and C/D/E/F/G exits remain open.

## Current fully qualified evidence

- **Phase B: real official Lean 4.35 Init 300,000-record same-byte prefix ACCEPTED** by both official `leanchecker` and the independent native C0 checker at source fuel `4096`, in the completed strict official/C0 300,000-record stage of [survey CI 38651094299](https://github.com/dwijayuda/pskernel/actions/runs/38651094299), source [de98620](https://github.com/dwijayuda/pskernel/commit/de98620def23020810b461f47556a888bfea588e). The overall survey was still in progress at handoff; prior 150,000 acceptance in [38646646864](https://github.com/dwijayuda/pskernel/actions/runs/38646646864) and [38647032997](https://github.com/dwijayuda/pskernel/actions/runs/38647032997). The previously false-rejected record **86,383** theorem `Std.PRange.UpwardEnumerable.succMany?_add` is now source-accepted.
- **Full-corpus bottleneck identified:** [survey 38651094299](https://github.com/dwijayuda/pskernel/actions/runs/38651094299) returned an inconclusive host timeout at 420 seconds with no malformed/rejected/unsupported verdict. Its final progress markers show 550,000 source records / 4,735 independently checked declarations, revealing a throughput decline after 300,000. Those observations are **not whole-prefix acceptance**. The next workflow uses the identical compiled C0 executable for previous interpreted prefixes, tests 550,000 directly and profiles monotonic elapsed/interval milliseconds per 50,000 records; the expensive full probe is explicit rather than repeated on every push.
- **Native replay progress instrumentation:** [de98620](https://github.com/dwijayuda/pskernel/commit/de98620def23020810b461f47556a888bfea588e) passed exact [native CI 38651094240](https://github.com/dwijayuda/pskernel/actions/runs/38651094240), **58 successes, zero failures, four optional skips**. Its replay reports source record and independently checked declaration counts every 50,000 records without changing the kernel verdict. A full-Init timeout cannot qualify acceptance.
- **Lean 4.35 application-vs-lambda η root fix:** [6a1f789](https://github.com/dwijayuda/pskernel/commit/6a1f7898811aaa60b7d3189eb8b56e05ef5ae390); full [native CI 38641430078](https://github.com/dwijayuda/pskernel/actions/runs/38641430078) and exact [real prefix CI 38642655096](https://github.com/dwijayuda/pskernel/actions/runs/38642655096) pass. The source `Checker/DefEq/FullShape.lean` previously omitted η when left was App and right was Lambda.
- **Fast, identical checker as compiled Lean executable:** [758b1fae](https://github.com/dwijayuda/pskernel/commit/758b1faeeb33910a25463e219eb029e94aee4e57) adds `lake build c0OfficialReplay`, compiling exactly `test/C0OfficialNdjsonReplay.lean`. [Full native CI 38647032994](https://github.com/dwijayuda/pskernel/actions/runs/38647032994) passes. Same 150,000-record official prefix: interpreted `lean --run` ~268 seconds; compiled binary ~20 seconds, approximately **13× faster end-to-end checking by execution mode**, not proven kernel-performance supremacy.
- **E.4AI:** independently recursive β/ζ/δ WHNF, [CI 38619929963](https://github.com/dwijayuda/pskernel/actions/runs/38619929963) PASS.
- **E.4AJ:** independently recursive metadata DefEq, [CI 38633622220](https://github.com/dwijayuda/pskernel/actions/runs/38633622220) PASS.
- **E.4AK:** independently WHNF-backed closed Bool.true reflection DefEq, [CI 38635485644](https://github.com/dwijayuda/pskernel/actions/runs/38635485644) PASS.
- Earlier exact source-refined checked inheritance, dependent binders, lets, projections, cache/state receipts, audited publication and original-vs-C0 differential regressions are fully documented in the linked historical log.

## Native commands and exact workflow

- From `psc0/packages/pskernel-c0/`: `lake build PsKernelC0`; `lake build c0OfficialReplay`; `.lake/build/bin/c0OfficialReplay <source.ndjson> 4096`.
- Full native architecture workflow: `.github/workflows/pskernel-c0-lean.yml`. Real pinned Init exporter/acceptance and first-failure workflow: `.github/workflows/pskernel-c0-init-survey.yml`.
- The pinned full real Init export is **6,452,982 NDJSON records** (~345 MB), independently accepted by official Lean. Do not infer C0 whole-Init acceptance from its current 300,000-record verified prefix.
- Test coherent features, source exactness, negatives/resource errors, complete state/cache provenance, verified root publication and original-vs-C0 native checker differences. Avoid excessive full-CI cycles on isolated proof edits. Qualify before marking a milestone complete.
- Whenever CI remains running at chat boundary, record the exact source/run IDs and report them as **pending**, not qualified. Do not claim asynchronous ChatGPT work continues after a message ends.

## Non-waivable remaining phase exits

1. **B** — entire real Init, then separately Std and Mathlib with exact positive/negative source compatibility and resource classification.
2. **C/D/E** — complete independent verified representation, full WHNF/DefEq (including recursors, Quot, Nat, projections, dependent eta/proof irrelevance), complete checking and declaration admission with no unqualified original-source fallback.
3. **F** — matched whole-library checked workloads and resource/throughput/memory comparison against Lean 4, unchanged original C0, con-leche and con-ron; synthetic microbenchmarks are not sufficient.
4. **G** — independent soundness/consistency results under explicit audited trusted foundations. Source refinement does NOT prove original kernel soundness or mathematical consistency.

**Operating rule:** maximum coherent implementation progress per regular ChatGPT Pro response; study pinned Lean 4.35 sources first; no test-fix hunting, no trust weakening, no redundant architecture/docs; commit source-validated checkpoints, update this file concisely and continue along the critical path.
