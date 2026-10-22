# T01F final same-run shards

Scratch preparation only; no local build, repository write or CI launch was performed.

## Files to integrate

- `pskernel-t01f-shards.mjs` → `psc1/scripts/pskernel-t01f-shards.mjs`.
- Fixture agent's `pskernel-expr-v2-string-environment-smoke.mjs` → the existing same-named script under `psc1/scripts/`.
- `psc1-pskernel-expr-v2-integration.yml` and `psc1-pskernel-core-correctness.yml` → their existing `.github/workflows/` paths. These are full replacements based on the root's authoritative `t01f-final-drafts` copies; do not apply older unsharded workflow drafts afterward.

The full replacements retain all original jobs, provider packaging/manifests, native fixture production and provenance, singleton marker checks, proof controls, benchmarks and budgets. Each removes only its newly added monolithic T01F generated runtime step, adds the helper path trigger and appends one six-job matrix plus an aggregate gate. Integration's paired-owner job remains unchanged. Removed runtime text and added job fragments are provided separately for review.

## Shard and aggregate contract

Each route uses its existing producer artifact from the same workflow run. Generated uses `psc1-v2-dag-generated-js` from `generated-dag-integration`; canonical uses `psc1-canonical-kernel-qualification` from `psc1-portability`. `actions/download-artifact@v4` has no external run/token override. Producer provenance must match the current repository, source SHA, run ID, run attempt, route and producer job. Current fixture-producer and runner bytes must match its digests. Kernel/fixture bytes and all provider manifest files are authenticated; the primary and provider kernels must agree. These hashes bind artifacts, never establish kernel truth.

The matrix is exactly indices0–5, `fail-fast:false`, `max-parallel:2`,25minutes per job. Each fresh Node22 process independently readmits all294 requests and compares all377 metadata records from the full six-sample fixture, then runs one entire unchanged sample with its singleton sequence and negatives. The runtime uses empty PATH, `--max-old-space-size=2048`, `--expose-gc`, unchanged kernel fuel4096 and disabled diagnostic tracing. No compiler or Lean is installed in a shard job.

Each successful shard requires exactly one selected CASE_PASS, SINGLETON_PASS and STRING_SHARD_JS PASS; it rejects a full-matrix marker. It records source/run/attempt/route and kernel/fixture/producer/runner/orchestrator/workflow/provider-manifest digests, exact sample/index, full raw-log and memory-file digests, and complete finite sample measurements. A failed process cannot write a success receipt. Detached kernel copies are not redundantly uploaded with every shard; the original producer artifact remains authoritative.

The aggregate runs with `if: always()` and first requires both producer and matrix success. It reauthenticates the original artifact against the current checkout, downloads only this route/current attempt's receipts and requires exactly six unique indices with the expected samples. It rechecks every raw log and memory digest and all marker/count/sample fields. Missing, failed, skipped, duplicate, cross-route, stale-attempt or mixed-source results fail. Successful output is `PSC1_T01F_FULL_STRING_SHARDED_JS: PASS` and an uploaded `qualification.json`; it explicitly keeps `performanceQualified:false`.

Strict attempt matching means a later workflow attempt cannot silently inherit an earlier producer receipt. Any rerun must provide matching producer artifacts and all six receipts for the qualifying attempt.

## Pending verification

Static review is not execution evidence. Final CI must execute the helper and selector on Linux, pass all six shards and the aggregate for each route, and retain every existing required gate at the same final coherent source. The separate authenticated19fb mixed diagnostic estimates the worst sample under the same25-minute job limit; it does not qualify these final workflows or a newer kernel.
