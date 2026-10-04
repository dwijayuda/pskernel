# PSKernel Performance Baseline

This document records non-semantic performance measurements for
`packages/pskernel-selfhost`.

These numbers are **engineering baselines**, not semantic evidence and not
release guarantees. Always preserve the Lean-4.34 conformance/fixed-point gates
before promoting a performance change.

## 1. Benchmark harness

Executable:

```text
lake exe psc1_kernel_selfhost_bench
```

Source:

```text
test/PsKernelSelfHostBench.lean
```

Current benchmark shape:

- 2,048 environment constants;
- 2,048 expression-cache entries;
- 2,000 repeated worst-case lookups;
- native Lean 4.34 compiled executable;
- same semantic data used by indexed and direct-linear lookup paths;
- timed loops are sequenced inside `IO` so optimizer code motion cannot move
  the measured work outside the timing interval.

## 2. Baseline — 2026-10-04

Measured locally on the authorized Windows development machine at commit
`32e509820248ee59e257353258cb53c431f3ee0f`.

```text
environment indexed :   4,333,200 ns
environment linear  : 125,717,800 ns

cache indexed       :   4,480,400 ns
cache linear        : 164,341,900 ns
```

Approximate speedups:

```text
environment lookup: 29.0x
expression cache:   36.7x
```

Both paths returned exactly 2,000/2,000 hits.

## 2.1 Checker-path baseline

Measured at commit `5e5e4475a1f46cc0fc07657989500fb7bd8d6d9e`
with 1,000 repeated checks of a delta-reducible Nat definition:

```text
WHNF cold session :  2,675,200 ns
WHNF warm cache   :    826,700 ns

DefEq cold session: 13,727,400 ns
DefEq warm cache  :    519,200 ns
```

Approximate warm-state speedups:

```text
WHNF :  3.2x
DefEq: 26.4x
```

The same run measured:

```text
environment indexed :  6,222,300 ns
environment linear  : 79,917,200 ns

cache indexed       :  4,534,900 ns
cache linear        : 71,044,300 ns
```

These microbenchmarks are intentionally simple and should be interpreted as
evidence that indexing/memoization is valuable, not as end-to-end production
throughput.

## 2.2 Hybrid small-cache baseline

Measured at semantic commit
`9091c02684a5ee96bda86bd553f46b7a861e5399` with promotion-invariant tests at
`c49b079d6b2c9ed07d9e39cbffca66a9d3a888c0`.

The runtime cache keeps up to 8 entries as a direct small list and promotes the
9th distinct entry to the existing persistent hash trie.

Matched 1,000-check delta workload:

```text
PSKernel WHNF cold : 1,637,300 ns
PSKernel WHNF warm :   295,700 ns
Lean 4.34 WHNF     :   406,400 ns

PSKernel DefEq cold: 4,032,900 ns
PSKernel DefEq warm:   263,400 ns
Lean 4.34 DefEq    :   975,600 ns
```

Approximate cold-call ratios on this microcase:

```text
PSKernel / Lean WHNF : 4.0x
PSKernel / Lean DefEq: 4.1x
```

Compared with the pre-promotion representative baseline:

```text
WHNF cold : 3,810,200 -> 1,637,300 ns  (~2.3x faster)
DefEq cold: 11,677,100 -> 4,032,900 ns (~2.9x faster)
```

Warm PSKernel state remains much faster than its cold path because inference,
WHNF, unfolding and defeq pair caches are reused. The official public kernel API
benchmark is cold-call only, so warm-vs-Lean numbers are not treated as an
apples-to-apples product claim.

The promotion invariant is tested directly:

- 8 entries remain in the small representation;
- the 9th distinct entry promotes to the trie;
- expression-map lookup remains correct;
- symmetric pair-set lookup remains correct.

The full portable gate passed for this representation:

- PSC1 source check;
- Lean build;
- frozen-reference differential;
- canonical `.ps` recheck.

The generated fixed-point gate must also remain green before the semantic
closure is promoted as the new self-host checkpoint.

## 2.3 Hybrid small-environment baseline

Measured after semantic commit
`0b2641e48b9b714c0580c0440ae81e26a81524a1`
with promotion/collision test hardening through
`9bdcd8f3e5605d44a4bcecdecaea596da5864740`.

The environment index now mirrors the cache strategy:

```text
0-8 declarations
    -> direct small list

9th distinct declaration
    -> promote once
    -> persistent name-hash trie
```

This removes hash/trie overhead from small checker environments while preserving
the ordered `Environment.constants` list as the semantic source of truth.

A representative local run on the same authorized Windows machine produced:

```text
PSKernel WHNF cold : 1,260,900 ns
PSKernel WHNF warm :   466,700 ns
Lean 4.34 WHNF     :   939,300 ns

PSKernel DefEq cold: 5,925,200 ns
PSKernel DefEq warm:   477,500 ns
Lean 4.34 DefEq    : 1,970,900 ns
```

Approximate cold-call ratios on this microcase:

```text
PSKernel / Lean WHNF : 1.34x
PSKernel / Lean DefEq: 3.01x
```

Compared with the immediately preceding representative run on the same machine:

```text
WHNF cold : 2,280,800 -> 1,260,900 ns  (~1.8x faster)
DefEq cold: 13,555,700 -> 5,925,200 ns (~2.3x faster)
```

The benchmark also isolates core rules:

```text
beta WHNF:
  PSKernel : 1,668,200 ns
  Lean     : 1,176,900 ns
  ratio    : ~1.42x

structural DefEq of identical sorts:
  PSKernel :   355,900 ns
  Lean     :   800,400 ns
```

The structural-defeq microcase is faster in PSKernel, while the complete cold
DefEq path remains slower. This strongly suggests the next performance work
should profile integration costs (inference, WHNF, environment access, state
construction/publication) rather than changing the equality rules themselves.

The large-environment/index measurements in the same run remained strongly in
favor of indexing:

```text
environment indexed :  5,437,300 ns
environment linear  : 97,990,500 ns

cache indexed       :  4,420,700 ns
cache linear        : 87,698,700 ns
```

The first intermediate environment-promotion commit did not yet route
`Environment.find` through the small representation and failed the Linux
special-defeq differential. That intermediate commit is **not** a valid
checkpoint. The corrected semantic commit is `0b2641e48...`, which passes the
full local frozen-reference differential; CI/fixed-point promotion remains
required before recording it as the current self-host evidence checkpoint.

## 2.4 Cold DefEq stage profile

Measured with benchmark instrumentation through
`d84f8b0b143d4ba61a8c29bfae4f3941a2cfdeae`.
No semantic kernel change occurred between this instrumentation and the
small-environment semantic checkpoint.

Representative 1,000-iteration run:

```text
cold infer(BenchDelta)        : 1,226,100 ns
cold isProp(Nat)              :   852,900 ns
combined proof probe          : 3,258,100 ns
lazy delta only               : 2,334,300 ns

full PSKernel cold DefEq      : 7,043,900 ns
official Lean 4.34 cold DefEq : 3,742,100 ns
```

Same-run ratio:

```text
PSKernel / Lean cold DefEq: ~1.88x
```

Other same-run rule measurements:

```text
PSKernel cold WHNF : 1,102,500 ns
Lean cold WHNF     :   711,500 ns
ratio              : ~1.55x

PSKernel beta WHNF : 1,560,400 ns
Lean beta WHNF     :   980,500 ns
ratio              : ~1.59x

PSKernel structural DefEq : 371,600 ns
Lean structural DefEq     : 750,700 ns
```

Interpretation:

- the structural equality rule itself is not the bottleneck;
- cold inference / proof detection and lazy-delta integration dominate the
  representative delta-defeq path;
- absolute timings vary between runs, so optimization decisions should use
  within-run ratios and multiple representative workloads;
- this microcase now satisfies the initial ~1.5-2x native target for WHNF and
  DefEq, so the next priority is broader workloads rather than altering the
  observable defeq algorithm.

Next benchmark target: checked application-spine inference.

## 3. Interpretation

The existing runtime-index work is justified.

`Runtime/EnvironmentIndex.lean` and `Runtime/Cache.lean` materially reduce
lookup cost while preserving the semantic structures:

```text
Environment.constants = authoritative ordered declaration history
Environment.index     = non-semantic lookup accelerator

Expr/defeq pair equality = structural semantic equality
cache hash/index          = non-semantic bucket accelerator
```

No algorithmic-defeq ordering changes are needed to get these gains.

## 4. Next performance measurement

Do **not** add cached expression metadata or interning yet.

WHNF and defeq warm/cold paths are now measured.

Next measurement priority:

1. official Lean 4.34 kernel vs PSKernel-native on matched WHNF/defeq cases;
2. inference over application spines;
3. recursor reduction;
4. indexed/nested-inductive admission on representative declarations.

Only optimize expression metadata/hash/sharing if those measurements show
repeated tree traversal is a dominant cost.

## 5. Future cross-runtime benchmark

After native checker microbenchmarks are stable, run the same semantic corpus
through:

```text
official Lean 4.34 kernel
PSKernel Lean-native
PSKernel generated JavaScript
```

The native performance target remains:

- initial production target: approximately <= 1.5-2x Lean where practical;
- longer-term target: around Lean performance on representative checking
  workloads.

JavaScript is optimized for portability and embedding; it is not required to
beat native Lean.
