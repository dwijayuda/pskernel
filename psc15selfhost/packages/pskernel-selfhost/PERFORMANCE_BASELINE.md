# PSKernel Performance Baseline

This document records non-semantic performance measurements for
`packages/pskernel-selfhost`.

These numbers are **engineering baselines**, not semantic evidence and not
release guarantees. Always preserve the Lean-4.34 conformance, PSC1 portable
source, canonical `.ps`, and differential gates before promoting a
performance change. Generated fixed-point proof is optional/manual.

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

The generated fixed-point workflow may be run manually for a bootstrap/release
checkpoint; it is not a normal performance-promotion gate.

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
full local frozen-reference differential. Portable CI promotion is required;
generated fixed-point evidence is optional/manual.

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

## 2.5 Checked application-spine optimization

The checked-application benchmark uses an arity-8 function with non-dependent
`Nat` domains and eight `Nat` literal arguments. Lean 4.34 checks this path
one application node at a time; PSKernel preserves that algorithm.

Measured optimization progression on the authorized Windows development
machine:

```text
representative pre-optimization checked spine : ~19.5 ms / 1000
skip checked-app memo publication              :  ~8.7 ms / 1000
structural domain-equality fast path            :  ~7.1 ms / 1000
non-dependent instantiate1 fast path            :  ~5.5 ms / 1000

same-run Lean 4.34 after instantiate1 fast path :  ~3.8 ms / 1000
PSKernel / Lean ratio                           :  ~1.45x
```

The exact wall-clock values vary between runs, but the direction is stable.

The accepted optimizations preserve Lean's checked-app rule:

```text
infer function
-> expose Pi
-> infer argument
-> compare argument type with Pi domain
-> instantiate codomain
```

They only remove portable-runtime overhead around the rule:

- checked application nodes are not memoized when a cold spine visits them only
  once and hashing the growing trees costs more than the reusable cache value;
- literal inference is not memoized;
- inference cache eligibility is centralized and ineligible nodes skip both
  lookup and publication;
- structurally identical argument/domain types bypass the full defeq
  orchestration because structural equality is already the first successful
  definitional-equality rule;
- `instantiate1` returns a non-dependent codomain unchanged when it has no
  loose bound variable, avoiding the node-count + substitution traversal.

A warm-session application benchmark is retained alongside the cold benchmark.
The no-checked-app-memo policy still leaves warm checking faster than cold
checking through the remaining WHNF/inference/defeq caches, so the cold speedup
does not eliminate useful session reuse.

This workload is now inside the initial native target of approximately
`<= 1.5-2x` Lean. The next application work should use dependent argument
types before introducing any more special cases.

## 2.6 Dependent application-spine check

A second application fixture makes the final result type depend on the first
`Nat` argument. This forces real de Bruijn substitution while keeping the
argument domains simple and comparable with Lean 4.34.

Two representative matched runs after the `instantiate1` non-dependent fast
path gave:

```text
dependent checked spine, run A:
  PSKernel : 7,049,900 ns
  Lean     : 5,866,100 ns
  ratio    : ~1.20x

dependent checked spine, run B:
  PSKernel : 8,420,000 ns
  Lean     : 5,885,600 ns
  ratio    : ~1.43x
```

The dependent path is therefore already inside the initial ~1.5-2x native
target on these microcases.

The non-dependent checked-spine numbers show substantial scheduler/system noise
between runs, including a same-binary repeat moving from a poor outlier to near
parity with Lean. Do not tune further based on one wall-clock sample. The stable
engineering conclusions are:

- removing counterproductive checked-app memoization produced a large repeatable
  improvement from the original ~19.5 ms shape;
- structural argument/domain equality is a worthwhile cheap fast path;
- skipping substitution for non-dependent codomains is semantically simple and
  useful;
- genuinely dependent substitution is not currently an obvious hotspot.

Next performance work should move to recursor reduction and representative
inductive admission rather than adding more application-specific special cases.

## 2.7 Recursor and inductive-admission profile

GitHub-native benchmark work on
`psc2/psc1kernel-selfhost-portable` extended the matched Lean 4.34 harness to
recursor reduction plus ordinary, indexed, mutual and nested-inductive
admission.

The important engineering result is not the absolute nanosecond values, which
vary materially between GitHub runners, but the repeated same-run ratios and
the stage decomposition.

After the one-pass application-spine recursor cleanup and the constructor-major
WHNF fast path, two representative GitHub samples of recursive recursor
reduction measured approximately:

```text
PSKernel / Lean recursor reduction: ~2.08x-2.18x
```

Ordinary, indexed and small mutual-inductive admission are not current
bottlenecks in the benchmark fixture. Nested admission was substantially more
expensive and was therefore split into:

```text
preprocess
transform through ordinary mutual admission
restore user-facing declarations
validate restored declarations
```

Profiling showed that transform and validation dominate; preprocessing and
restoration are comparatively small. Validation was then split further and
identified restored recursor-rule checking as the main cost.

The accepted runtime changes from that profile are non-semantic:

- checked lambda inference results are not memoized when the generated rule
  traversal consumes each growing lambda subtree once;
- checked forall inference results are likewise not memoized on the one-shot
  checked path;
- nested auxiliary comparison uses infer-only **only** for the old transformed
  rule whose full checked validation is already guaranteed by successful
  `psKernelAddSimpleMutualInductive` admission;
- every restored new rule is still fully checked and its restored source type
  must still be definitionally equal to the new inferred type;
- the general nested rule-comparison helper retains its conservative
  fully-checked contract; the faster path is explicitly named for the
  already-validated invariant.

Two GitHub benchmark samples after these changes measured nested admission at:

```text
run A:
  PSKernel nested admission : 39,909,097 ns / 100
  Lean 4.34 nested admission: 12,063,864 ns / 100
  ratio                     : ~3.31x

run B:
  PSKernel nested admission : 54,397,784 ns / 100
  Lean 4.34 nested admission: 18,355,065 ns / 100
  ratio                     : ~2.96x
```

The auxiliary rule-comparison optimization is directly attributable inside the
same runs. Re-checking both old and new rule lists separately cost about
`7.07 ms` and `8.83 ms` per 100 iterations, while the production comparison
path cost about `5.13 ms` and `6.63 ms`, respectively: approximately a
25-27% reduction in that hotspot without weakening restored-rule checking.

The remaining nested cost is still concentrated in:

- transformed mutual-inductive admission;
- fully checked restored original recursor rules;
- fully checked new auxiliary recursor rules.

Do not replace these checks with infer-only shortcuts. Further improvement
should reduce checked-inference runtime overhead while preserving the same
accept/reject judgments and algorithmic ordering.

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

WHNF/defeq, checked application spines, recursor reduction, and representative
ordinary/indexed/mutual/nested admission are now measured.

Next measurement priority:

1. profile fully checked generated recursor-rule inference without weakening
   validation;
2. add a larger nested fixture with multiple nested families/constructors so
   improvements are not tuned only to the smallest representative declaration;
3. remeasure transformed mutual admission after any generic checked-inference
   optimization;
4. compare the stable semantic corpus across official Lean 4.34,
   PSKernel Lean-native, and generated JavaScript.

Only optimize expression metadata/hash/sharing if those measurements show
repeated tree traversal/hash computation is a dominant cost.

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
