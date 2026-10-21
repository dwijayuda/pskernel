# Expression V2 complete admission measurements — 2026-10-21

Status: **qualified measurements of limited complete-checker fixtures; overall kernel and performance acceptance remain open**.

Source: [8db7d50e1cf02b7cc83e6d7ce1a8da1ae953c723](https://github.com/dwijayuda/pskernel/commit/8db7d50e1cf02b7cc83e6d7ce1a8da1ae953c723).
[Integration run39535658641](https://github.com/dwijayuda/pskernel/actions/runs/39535658641)
passed both native and generated jobs. Actual completed generated log119011587752
contains24 admission observations,128 complete-operation observations and six
profiles. [Artifact12317687078](https://github.com/dwijayuda/pskernel/actions/runs/39535658641/artifacts/12317687078)
retains the raw observations, exact correctness checks and profiles.

## Method and limits

The authentic PSC1-generated checker compares its original path with public
RunDag in the same executable and run. Lean4.35.0 is pinned to
eb6cafb7290e8bd5f2937522d8d804f58f02bafc; generated TypeScript uses7.0.2 and Node22.
The admission benchmark runs six fixtures in A-B-B-A order, with two independent
worker observations per variant/fixture. Each measured batch starts with fresh
semantic state. Fuel is4096, maximum depth0 and maximum Nat size134217728.
Five input pools remain alive; admitted environments are discarded after
independent exact assertions. The52 measured batches admit896 declarations.
All24 observations passed their positive checks and negative type-mismatch
sentinel. No resource limits or accepted/rejected rules changed.

The figures below divide each worker's admission time by its batch count.
Assertions are timed separately; warm admission time excludes those assertions
and input construction. Cold is the first valid batch after a negative sentinel,
with fresh semantic state, rather than pristine-process cold. The exact raw
worker values and assertion timings remain in the artifact.

All12 DAG observations also passed an untimed diagnostic after timing/heap/RSS
snapshots:8 or32 direct admission attempts, matching original input-ID entries,
exact negative rejection and dispatcher environment equality. Timed paths were
not instrumented; the diagnostic is evidence of supported direct execution,
not a timed cache-hit or fallback counter.

## Complete admission time (milliseconds per batch)

| Fixture | Original warm | DAG warm | Ratio of mean times | Original cold | DAG cold |
| --- | ---: | ---: | ---: | ---: | ---: |
| chain8 | 466.222–525.862 | 30.966–31.507 | 15.88× | 548.356–558.268 | 45.371–45.841 |
| chain32 | 1904.609–1923.634 | 116.244–120.483 | 16.17× | 1994.904–2032.657 | 150.016–204.083 |
| metadata8 | 568.632–587.626 | 47.828–50.145 | 11.80× | 579.915–600.682 | 69.921–75.582 |
| metadata32 | 2290.912–2440.490 | 196.247–203.592 | 11.83× | 2228.244–2381.125 | 222.025–227.033 |
| binder8 | 523.867–572.489 | 61.389–62.300 | 8.86× | 620.526–637.175 | 96.136–97.044 |
| binder32 | 2184.413–2223.690 | 250.328–264.251 | 8.57× | 2194.693–2304.782 | 300.259–301.870 |

## Memory and input construction

| Fixture | Original peak RSS (KiB) | DAG peak RSS (KiB) | Original retained delta (bytes) | DAG retained delta (bytes) | Original pool construction (ms) | DAG pool construction (ms) |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| chain8 | 264232–265872 | 164136–165228 | 34024–34040 | 57320–57320 | 0.070–0.104 | 7.834–8.217 |
| chain32 | 265232–267648 | 214556–230556 | 8664–8664 | 18712–21536 | 0.178–0.284 | 34.599–38.140 |
| metadata8 | 253384–269772 | 187544–190960 | 60656–69432 | 19976–19992 | 0.412–0.441 | 16.975–17.569 |
| metadata32 | 315080–370612 | 221128–222064 | 4688–10944 | 31968–32624 | 0.673–0.690 | 70.296–71.415 |
| binder8 | 271812–349988 | 204492–204824 | 27544–27640 | 31680–31752 | 0.125–0.133 | 13.558–13.804 |
| binder32 | 276716–279460 | 224024–224292 | 13968–15744 | 38624–45200 | 0.380–0.667 | 50.388–52.604 |

Peak RSS covers the complete worker, including setup, warmup and assertions,
before the later direct-path diagnostic. Post-GC retained deltas include live
input pools and discarded admitted environments; they are not allocation counts
or a leak proof. All six DAG RSS ranges are lower in this run. Input construction
is materially higher, and retained deltas are mixed. A warm-time gain alone
does not qualify the replacement's complete memory lifecycle.

## Remaining complete-WHNF regression

The same run still shows worse DAG WHNF times for the two function workloads:

| Fixture | Original warm (ms) | DAG warm (ms) |
| --- | ---: | ---: |
| fn-unique128 | 1,093.949–1,136.326 | 1,579.570–1,622.760 |
| fn-collision128 | 2,778.984–2,955.607 | 3,214.160–3,394.153 |

Sampled allocation profiles estimate1,417,301,856 bytes for the unique DAG
worker and3,082,393,544 for the collision worker. They identify repeated cache
scans as a substantial cost. The later scanner refactor has no qualified
performance measurement yet: its first paired runs are blocked by an unrelated
new binder source-profile failure, and its native equivalence proof needed an
explicit branch-case correction. Admission gains do not erase these regressions.

## Comparison with the earlier baseline

The same fixture definitions and4096 fuel policy were measured at3fb6a3c in
[run39532408632](https://github.com/dwijayuda/pskernel/actions/runs/39532408632).
DAG admission then delegated to original admission. Within-run mean DAG/original
ratios change from approximately0.985–1.039 there to0.062–0.117 at8db7d50.
Absolute cross-run speedup is not controlled: original-path means on8db7 are
only58.5%–74.0% of their3fb6 values. The8.57×–16.17× figures above are
same-run, matched-fixture comparisons, not cross-run kernel-wide speedups.

These fixtures exercise safe definitions with constant chains, metadata and
binders. They do not qualify inductive/recursor admission, the entire Lean Arena
corpus, full DefEq, or removal of the original checker fallback. Canonical .ps
reconstruction is a separate gate and is not inferred from this integration run.

The separate [canonical correctness run39535658534](https://github.com/dwijayuda/pskernel/actions/runs/39535658534)
subsequently passed. Actual log119011587861 derives117 canonical modules and160
portable modules across two roots, runs the detached .ps-derived complete
checker including the admission and inference-only suites, and validates
declarations/maps. DirectJS remains explicitly unsupported. This establishes
canonical qualification for8db7d50 without extending the measured fixture scope.
