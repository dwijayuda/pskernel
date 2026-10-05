# PSKernel Performance Baseline

This document records non-semantic performance measurements for
`packages/pskernel-core`.

Current M3 acceptance uses the explicit latency and memory ceilings in
`M3_ACCEPTANCE.md` and `M3_WORKLOAD_BUDGETS.json`. Relative speed against Lean
remains diagnostic. Historical ordinary/indexed/mutual admission timings below
used closed expressions that could be precomputed; they are superseded by the
runtime-input corpus and must not be cited as admission throughput wins.
M3 is complete for the declared bounded profile at
`c13558c6d573ef477fed6f0ffa31a9b7e39650ca`; see the permanent results in
`M3_ACCEPTANCE.md`. This does not close M4 or promote a provider.

These numbers are **engineering baselines**, not semantic evidence and not
release guarantees. Always preserve the Lean-4.34 conformance, PSC1 portable
source, canonical `.ps`, and differential gates before promoting a
performance change. Generated fixed-point proof is optional/manual.

## 1. Benchmark harness

Executable:

```text
lake exe psc1_kernel_core_bench
```

For Phase C promotion, use the bounded reporter after building the executable:

```text
node scripts/psc1kernel-benchmark-report.mjs .lake/build/bin/psc1_kernel_core_bench 3 /tmp/pskernel-core-bench
```

The M3 reporter requires Linux x64 and Node 22, exactly three samples, and GNU
time/timeout for peak RSS and a 30-second process cap. It fails on missing
results or unsuccessful benchmark operations. It saves raw logs, JSON with
median/range timings and matched PSKernel/Lean ratios, and a Markdown summary.
No compiler/kernel fixed-point generation is invoked. The historical log fixture
used to test this reporter is from green commit `33b59ded58aa5ab745ab6b7f729cf487dc608e20`.

Untimed `PSKERNEL_PROFILE` rows inspect the fully checked nested recursor-rule
cache after validation. They distinguish free-variable, sort and constant entries
without instrumenting the semantic checker. The explicit M3 workload ceilings,
successful operation counts and existing conformance checks are hard gates;
historical timing ratios remain advisory.

Source:

```text
test/PsKernelCoreBench.lean
```

Current benchmark shape:

- 2,048 environment constants;
- 2,048 expression-cache entries;
- 2,000 repeated worst-case lookups;
- native Lean 4.34 compiled executable;
- same semantic data used by indexed and direct-linear lookup paths;
- timed loops are sequenced inside `IO`; closed pure expressions can still be
  precomputed, so the repaired admission loops select from sixteen runtime
  inputs and require occupied-environment rejection guards.

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

The historical ordinary/indexed/mutual measurements did not reliably measure
repeated admission work; use the corrected runtime-input corpus for those rows.
Nested admission was split into:

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

### 2.8 Multi-family nested regression and profile

A wider nested fixture was added with two independent outer families and one
user datatype containing recursive occurrences through both families. Official
Lean 4.34 admitted the fixture, while the first PSKernel run rejected every
iteration during restored validation.

The defect was semantic, not a benchmark artifact. Auxiliary-recursors were
restored by a structurally recursive worker whose `families` argument doubled
as both the shrinking pending queue and the restoration lookup universe. By the
time the second family was restored, the first family had been dropped from
that lookup set, leaving a transformed constant such as
`_nested.BenchNestedBox_1` inside the later restored recursor.

The fix separates:

```text
pending families     = structurally decreasing work queue
allFamilies          = invariant restoration lookup registry
```

After the fix, the same wide fixture changed from:

```text
PSKernel: 0 / 50 admissions
Lean 4.34: 50 / 50 admissions
```

to:

```text
PSKernel: 50 / 50 admissions
Lean 4.34: 50 / 50 admissions
```

and every restored main/auxiliary recursor type and rule checked successfully.
A permanent multi-family regression now locks this behavior.

Two post-fix same-run samples measured the complete wide admission at roughly
`3.6x-3.8x` Lean. One representative stage split for 50 iterations was:

```text
preprocess :    489,893 ns
transform  : 39,991,951 ns
restore    :  2,844,111 ns
validate   : 36,398,253 ns
```

The wide validation split was:

```text
templates :    139,821 ns
originals : 13,629,274 ns
auxiliary : 22,083,301 ns
```

Therefore discovery and restoration are not current performance priorities.
Further native optimization should focus on the transformed mutual-admission
path and the fully checked restored auxiliary-recursors, while preserving the
full-family restoration invariant and the new multi-family conformance case.

A follow-up experiment disabled checked constant-inference caching globally.
Across two benchmark samples it improved nested-admission ratios but consistently
regressed the general checked-application and recursive-recursor ratios. The
change was reverted. Keep checked constant caching enabled globally; any future
nested-specific optimization must avoid trading away general checker
performance.

## 2.9 Bounded Phase C experiment — not adopted

The three-sample baseline at package-rename checkpoint
`071a584ec4bbefdd09cb2de3b063ce0db4641469` measured median PSKernel/Lean ratios
of 3.20x for nested admission and 3.74x for the wider fixture. Untimed checked
rule-cache profiles contained 20 entries (13 free variables) and 45 entries
(34 free variables), respectively. Entry counts identify a profiling target;
they do not establish how much execution time it consumes.

An experiment replaced separate bucket lookup and replacement with one index
descent. A 132-update comparison preserved the complete persistent structure,
including collisions and replacement. Its matched insertion microbenchmark
improved by about 13%, but a same-runner comparison did not improve the intended
checker workloads:

| Workload | Single-descent / previous-path ratio |
| --- | ---: |
| Checked application | 1.054 |
| Dependent application | 1.062 |
| Recursor reduction | 0.990 |
| Nested admission | 1.015 |
| Wide nested admission | 1.001 |

Lower is faster. These are three-sample medians normalized to the matched Lean
baseline on one runner; sequential runs still contain measurement noise.
The experiment is **not adopted**: the production source is restored to the
green rename checkpoint, and the experimental worker and comparison-only code
are removed. The ordinary bounded reporter and cache diagnostics remain.

Evidence: [same-runner comparison, run 37288339756](https://github.com/dwijayuda/pskernel/actions/runs/37288339756)
at `27129b244b8648885f6aa81cfdf24b0482d6647c`. That experimental revision failed
the PSC1 gate on a missing local type annotation; it is not a promoted semantic
checkpoint. Adding the annotation was subsequently superseded by the rollback.
The comparison used one extra native build capped at four minutes and three
short samples per variant. Full generated compiler/kernel fixed-point generation
and large proof-library replay were not run.

At that historical checkpoint M3 remained open. Further changes require representative gains; the next useful
work is a bounded profile of fully checked recursor-rule inference and an
affordable current-JavaScript benchmark, not speculative metadata or cache-policy
changes justified only by microbenchmarks.

## 3. Interpretation

The existing runtime-index work is justified.

`Runtime/Acceleration/EnvironmentIndex.lean` and `Runtime/Acceleration/Cache.lean` materially reduce
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

## 5. Cross-runtime scope and acceptance

The cost-bounded Phase C pass uses the native corpus, the small Node corpus
below, and normal portable source/canonical `.ps` checks. Full generated
compiler/kernel reproduction and large proof-library replay are excluded.
Native results alone do not establish JavaScript throughput; the initial Node
measurements do not establish M3/provider readiness.

Continue broadening matched workload coverage across:

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

## 6. Bounded Node cross-runtime harness

`.github/workflows/psc1kernel-cross-runtime.yml` builds the current portable
kernel and a test-only fixture through the native PSC1 compiler's backend-ts,
then pinned TypeScript 5.8.3. It does not regenerate the compiler, prove a
generated fixed point, rebuild WASM, or replay a large proof library.

`test/KernelCore/Bench/CrossRuntime.lean` is compiled unchanged by both Lean and
PSC1. The initial corpus measures 16 beta reductions, definitional equality
through that beta chain, and checked eight-argument application. Sixteen inputs
are prepared outside timing, with exact naturals above 2^53. Each sample uses
100 warmup calls and 1,000 measured calls; every call starts a cold kernel
session. Success checks inspect the result rather than merely counting returns.
Separate guards require rejection of ill-typed terms, fuel exhaustion, and a
definition with an ill-typed body, and distinguish adjacent large naturals.

The reporter runs at most three fresh-process samples, caps each child at 30
seconds, fails on missing/failed operations, and stores medians, ranges, raw
logs, Node identity and the generated artifact SHA-256. Module import and first
workload calls are reported separately; the latter occur after guard checks
and must not be called pristine JIT startup. One bounded CPU profile includes
the entire worker, including setup and guards.

The existing integrity-checked Lean WASM provider is measured separately on
matching batches of one and 128 definitions and a four-definition rejection.
Its full request includes integrity verification, process startup, JSON
decoding, provider prelude setup and checking. The JS column calls shared test
fixtures directly with a smaller environment. These are different integration
boundaries, so the report deliberately provides **no JS/WASM kernel speed
ratio**. A health request is measured separately and is not subtracted from
check times as if it were an exact startup decomposition.

This is initial Node evidence. It does not establish browser performance,
general JS provider parity, or performance of nested admission. Keep M3 and
M4 acceptance separate from this bounded measurement checkpoint.

### 6.1 First measured Node baseline

The first complete checkpoint is `d379472dcd515fceabd2e444a22245f75db4a9e8`:
[three-sample run 37296102555](https://github.com/dwijayuda/pskernel/actions/runs/37296102555).
Node 22.23.3 ran the generated JS; pinned Lean 4.34 compiled the same fixture
functions natively. These ratios compare PSKernel JS with **PSKernel native**,
not with official Lean native or Lean WASM.

| Workload, 1,000 operations | JS median ms | Native median ms | Median paired JS/native |
| --- | ---: | ---: | ---: |
| 16-step beta WHNF | 12,324.900 | 22.577 | 544.26x |
| Beta definitional equality | 1,839.516 | 4.328 | 421.59x |
| Checked eight-argument application | 862.152 | 2.548 | 329.39x |

The large gap is real on these synthetic fixtures; do not infer competitive JS
throughput from the earlier native measurements. The whole-worker profile
attributed 12.24% of samples to garbage collection, 9.89% to runtime dispatch,
and substantial additional samples to expression counting, hashing, equality
and callback construction. These are sampled attributions, not independent
wall-clock stage timings or a proof of a particular optimization's benefit.

The 128-definition JS fixture took 58.121 ms, while the complete Lean WASM
request took 169.116 ms. The boundaries differ as described above; this does
not establish that the JavaScript kernel is faster than the WASM kernel.

### 6.2 Rejected equality scheduling experiment

[Run 37298205029](https://github.com/dwijayuda/pskernel/actions/runs/37298205029)
compared an attempt to delay child-comparator construction with the original
implementation on one runner, alternating fresh-process order over three pairs.
Current/original median ratios were 1.059 for beta WHNF, 0.988 for beta defeq,
and 1.010 for checked application. There was no useful overall improvement, so
the production equality change was reverted. The original and candidate
generated artifact hashes were distinct and are retained in the run artifact.

The new 729-pair equality matrix remains useful: it covers every expression
constructor, ignored binder names/annotations, and significant metadata,
projection and let fields. It runs in generated JS and native code; the native
runner also compares all pairs with the frozen reference implementation.

### 6.3 Accepted zero-lifting shortcut

Checkpoint `11a1e8828b24edace52536444f4f4c848c1a1602` moves the existing
zero-amount return ahead of expression counting in
`psKernelExprLiftLooseBVarsChanged`. The wrapper previously counted the tree,
then passed positive fuel to a worker that already returns `(expr, false)` for
zero. The shortcut returns that same pair; nonzero lifting is unchanged.

[Run 37299796818](https://github.com/dwijayuda/pskernel/actions/runs/37299796818)
compiled both versions on the same runner, changing only the lifting module
back to its pre-optimization source for the baseline. Three paired samples
alternated fresh-process order:

| Generated JS workload | Current/original median | Paired ratio range | Interpretation |
| --- | ---: | ---: | --- |
| 16-step beta WHNF | 0.933x | 0.868-0.958x | About 7% less time |
| Beta definitional equality | 0.620x | 0.585-0.692x | About 38% less time |
| Checked eight-argument application | 0.999x | 0.904-1.011x | Essentially unchanged |

The shortcut is retained. The shared guards additionally check 54 zero lifts:
27 expression forms at two starting indices, requiring the exact expression
under binder-sensitive equality and an unchanged flag. The 729 equality pairs,
rejection/exhaustion/large-natural guards, generated smoke, native conformance,
portable PSC1 gates and native benchmark all passed at this checkpoint.

This is a local improvement, not closure of the runtime gap. In that run the
three JS/native median ratios were still 584.49x, 387.74x and 344.03x respectively.
Do not compare ratios from different runners to estimate the shortcut's benefit;
use the paired current/original results above. M3 remained open at that checkpoint;
its subsequent budget-based acceptance is recorded in `M3_ACCEPTANCE.md`.

The one-off comparison generator and optional reporter path are removed after
this experiment. The ordinary bounded harness, correctness guards and profile
remain in CI. The comparison implementation and raw evidence remain available
at the checkpoint and linked workflow artifact.
