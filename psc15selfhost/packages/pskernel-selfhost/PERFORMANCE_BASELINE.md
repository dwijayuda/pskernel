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

Next benchmark actual checker operations:

1. WHNF beta/zeta/delta cases;
2. algorithmic defeq with successful/failed pair cache reuse;
3. inference over application spines;
4. recursor reduction;
5. indexed/nested-inductive admission on representative declarations.

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
