# PSKernel-C0 — Arena 2026-09 replay against pinned Lean 4.35

**Scope:** `psc0/packages/pskernel-c0` (native Lean 4.35.0, Lean git `eb6cafb7290e8bd5f2937522d8d804f58f02bafc`). The active PSKernel-C0 branch remains the host for this test. This is an independently checked *historical-export compatibility test*, **not** a genuine source compilation under Lean 4.35 and not the September Arena leaderboard score.

## Why the September archive was previously always declined

The original September 2026 Lean Kernel Arena archive contains **193** NDJSON cases built against an older Lean pin, typically 4.29.1. The C0 importer explicitly demands 4.35.0 and rejects mismatched metadata before semantic checking. The original untouched-archive gate [38994521898](https://github.com/dwijayuda/pskernel/actions/runs/38994521898) therefore reported **193 declines, zero qualified verdicts**, while proving intact archive identity and seven separate native controls.

**Do not silently disable version checking in the production kernel.** The archived exports came from an older toolchain and may express behavior that has changed. Nor may the historical case label substitute for an actual 4.35 official verdict.

## Exact test-only transport

`test/arena_lean435_compat.py` checks the pinned original round archive SHA-256 `98a69742b538296c5f413d0527dfeef8c4d1815fe64b12c8623cd33de63bee0d`, exact **193** entries, and export **wire format 3.1.0**. It preserves the original archive completely. For *each case* it produces a separate test-only temporary file in which ONLY first-line `meta.lean.version` and `meta.lean.githash` are replaced with `4.35.0` and the exact official Lean Git commit. The original exporter `name` and `version` stay unchanged, including authentic handcrafted sources; the entire NDJSON body suffix is compared byte for byte to the untouched file. Every original/adapted file and body SHA-256 is recorded.

**Important:** the adapted header states the *target checking environment*, not the true version of source generation. The new file must never be distributed as a genuine 4.35 exporter output or substituted for a native 4.35-source-reexport corpus.

The runner asks **both** the actual official Lean 4.35 `leanchecker --from-export` and native C0 `c0OfficialReplay` to judge **the identical adapted bytes**. It separately stores the historical old good/bad label; official **4.35** decides the target verdict. Distinguish matching accept/reject from false accept/reject, unsupported import, malformed input, fuel exhaustion, host timeout and official reference-driver failure. Fail closed on mismatched checked outcomes and transport errors.

## Coverage and concrete evidence

First complete legacy-body pass at [workflow 39006816117](https://github.com/dwijayuda/pskernel/actions/runs/39006816117) (before sparse importer improvements):

| Classification | Count |
| --- | ---: |
| Matching checked official/C0 verdicts | **150** |
| Incorrect acceptance or rejection (actual matching official verdict compared) | **0** |
| C0 unsupported | 20 |
| C0 timeout | 13 |
| C0 resource exhausted | 2 |
| C0 malformed | 1 |
| Official driver error (duplicates and similar) | 6 |
| Official timeout | 1 |
| Total | **193** |

Of 150 verified matches, 105 were official+C0 acceptances and 45 were official+C0 rejections. The historical labels differed from official 4.35 in **7** cases; this must be recorded as version-semantic drift, not assigned to C0 automatically. The first full run deliberately FAILED strict qualification because of unresolved cases. No evidence of false acceptance was observed among qualified official reference verdicts.

There are two notable **valid handcrafted sparse-table** cases `other/level-index-out-of-order.ndjson` and `other/sparse-name-index.ndjson`. Their 3.1.0 wire format is valid even though the exporter producer is `handcrafted 0.1.0` rather than `lean4export 3.1.0`. The importer now has a narrowly recognized handcrafted source envelope and dedicated sparse ID paths for names, levels and expressions, retaining dense persistent-array operations for normal exports. Both formerly unqualified legitimate sparse-index cases have now been independently **accepted** by official Lean 4.35 and the changed C0 importer in [native CI 39007503159](https://github.com/dwijayuda/pskernel/actions/runs/39007503159), and that status was retained in the exact PR-head dual-verdict qualification. No ordinary source checker, reduction or declaration admission rule is altered.

The same run identified 18 unsupported **negative** recursor/inductive/safety metadata cases, plus other performance and host failures. A parser-level refusal is **not** a semantic rejection, and must remain classified as unsupported until source-level negative validation justifies a true rejection.

## Four-way sharded qualification

`.github/workflows/pskernel-c0-arena-lean435-compat.yml` checks all **193 cases** on four deterministic shards selected by input order modulo four. The aggregate job requires all four unique shard reports, no duplicate or missing case, intact source-body byte equality for each of 193, and zero confirmed false acceptance/rejection or transport errors. Each shard uploads its per-case evidence including original bytes SHA, adapted SHA, source metadata, official verdict, C0 verdict, resources, and old-label drift; aggregation never replaces the underlying artifacts.

**Performance classification:** The first full sequential run reported 13 C0 timeouts; the exact PR-head four-shard comparison still recorded 12 C0 timeouts and two source-fuel exhaustions. These are open throughput/resource work, not false rejection. The two official-source reference timeouts are unqualified oracle results. Do not increase kernel fuel or omit checking merely to improve nominal coverage. Profile and fix repeated checked inference/WHNF/DefEq and substitutions under identical real corpus evidence.

## Next acceptance milestones

1. **Genuine 4.35 source re-export:** Rebuild upstream test sources with explicitly recorded Lean 4.35 API adaptations and pinned exporter; retain original source identity and do not relabel historical exports as genuine native builds. Selected real negative exploit classes are already independently qualified under [PRs #110](https://github.com/dwijayuda/pskernel/pull/110) and [#111](https://github.com/dwijayuda/pskernel/pull/111).
2. **Format coverage:** Resolve all *valid* wire-format gaps, preserving the producer/semantic-trust distinction and rejecting invalid or duplicate handles; add deterministic negative tests for sparse and overlapping IDs.
3. **Semantic negative cases:** Independently prove/validate malformed recursor/inductive metadata rather than converting a generic unsupported result to a fake rejection.
4. **Full safe acceptance:** Work through real Lean 4.35 Init/Std/Mathlib without weakening resource and axiom boundaries; archived small-case compatibility is not a replacement for whole-library acceptance.
5. **Throughput:** Address the real Array lambda/Pi/repeated inference hotspot with source-/state-/fuel-equivalent checked DAG reuse. Same-runner accepted workload A/B is required; local hash-bucket tuning alone has not provided material gains.

This scope does not establish kernel mathematical soundness, model consistency, original archived same-byte parity, complete native 4.35 source conformance, or performance equality with official Lean.

## Qualified bounded milestone — 17 October 2026, merged PR #112

**Merged change:** [PR #112](https://github.com/dwijayuda/pskernel/pull/112), merge commit [`e63183ba`](https://github.com/dwijayuda/pskernel/commit/e63183ba215720b3c7221b9b874450b8667497d0). The following checks passed on exact PR HEAD `9f6ff4d232950440b96b775076302e9192dd51e5`: [four-way native 4.35 compatibility 39008026715](https://github.com/dwijayuda/pskernel/actions/runs/39008026715), [native Arena exploits 39008026729](https://github.com/dwijayuda/pskernel/actions/runs/39008026729), and [immutable archived source-provenance 39008027473](https://github.com/dwijayuda/pskernel/actions/runs/39008027473).

The full aggregate completed with the following **strictly limited** result:

| Target-4.35 verdict classification | Count | What it establishes |
| --- | ---: | --- |
| Official/C0 matching real acceptance or rejection | **152** | Independent same-adapted-byte target-4.35 verdict agreement |
| C0 unsupported, chiefly explicitly malformed negative metadata | 18 | No semantic C0 invalidity verdict; pending research |
| C0 malformed for the negative orphan constructor | 1 | Fail-closed parse outcome, not equivalent to semantic rejection |
| C0 timeout | 12 | No qualified verdict; priority performance debt |
| C0 source fuel exhausted | 2 | No qualified verdict; cannot turn into acceptance by waiving budget |
| Official source driver error (duplicate declaration cases) | 6 | Independent reference could not produce an ordinary accept/reject label |
| Official timeout | 2 | No independent reference result; must not count C0's response as proven correct |
| **Total** | **193** | **Every original Arena identity and declaration-body byte accounted for** |

The aggregate verifies **193/193 unchanged declaration-body bytes**, unique case identities, all four shards and **zero observed false acceptance/false rejection among independently compared verdicts**. The 41 outstanding entries appear explicitly in `test/arena_435_known_gaps.json` with frozen permitted **unqualified** classifications; this is an assurance-debt ledger, *not* a set of passed tests. Each shard and the aggregate reject newly observed false acceptance/rejection, source byte mismatch, previously passing sparse-input declines, new unqualified outcomes or unlisted case names. The strict `--require-complete` path remains unsatisfied.

**The original historic archive no longer results in 193 meaningless version declines:** `.github/workflows/pskernel-c0-external-arena.yml` validates historical archival provenance without generating kernel verdict claims, while `.github/workflows/pskernel-c0-arena-lean435-compat.yml` evaluates the complete collection under an explicitly labeled test-only compatibility adaptation using **the actual official 4.35 and native C0 checker**. These are distinct from the 4.35-source-rebuilt external Arena tests under `pskernel-c0-arena-adversarial435.yml`.

Next work: remediate only genuine documented defects, finish separate validity witnesses for unsupported negative recursor metadata (without fabricated rejection), investigate official duplicate-name driver exceptions, and improve checked repeated inference, beta/WHNF, and binder substitution enough to remove timeouts at unchanged kernel fuel. Completion of *native generated* Arena, full Init/Std/Mathlib, formal consistency and PSC0 v7.2 self-hostability remain separate milestones.
