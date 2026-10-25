# Empty semantic cache: bounded helper timing protocol v1

## Gate and scope

Execute only after the exact paired leaf gate passes. That gate is now run
40158333460, attempt 1, experiment 80182d1b95894fc3daa5c7fbcfe8b1a7adb687d9:
baseline 20224a295359abb201f56c72395690bf0bfac9fa and candidate
e503972553ae2d41d5ba7a26d7739fb32ee86b96 each passed the unchanged 1884
controls plus 21 empty-map controls. This protocol measures only
psKernelSemanticExprMapGet in the already generated leaves. It neither builds
nor times a full kernel and does not qualify optimization adoption.

Reuse artifact 12585423993 from that run: 5226483 bytes, ZIP SHA256
adf655c16ab115565e3bbeb8204cc2d1d25c8fa98b495d0bd8849926986e4d63.
Before timing, independently enforce its raw ZIP digest, API run/source/attempt,
136 extracted regular-file inventory, actual Git source manifests, both leaf
receipts and source/closure/runtime chains. Preserve the distinction between
official extraction/content verification and an independently implemented ZIP
parser. Reuse the two authenticated JS files without changing their bytes:

- A, baseline: 360259 bytes, SHA256
  47c320361a197b3bfe4eeb16c7a95375ceed26869375d1fd941ed7c2cb34021e.
- B, candidate: 360611 bytes, SHA256
  067b7c540f340ccfc12b730156f5fdee0fa288ec4b784640f788a8e1eec0d554.

The original compiler identity remains
80005bb250a7324772db76d51684d23fbf0fe6ed, binary SHA256
13635a423d1343e9a4770be0b7e02d859a6b845b221a0363d19bfdfab8e3cc1c.
The timing experiment has its own source SHA and must never substitute that SHA
for either kernel source or the compiler source. No held transform production
sources enter either leaf.

## Inputs, built before timing

Use only actual generated constructors and actual public cache insertion. Do not
manufacture host cache records. Assert the published small limit is 8. Define:

- hit: sort(succ(zero)); value: sort(succ(succ(zero))).
- miss: sort(succ(succ(succ(zero)))).
- deep: start at const("EmptyCacheBench.closed", []), then for i = 0..255 replace
  it with app(previous, lit(nat(i mod 7))). This closed left spine has 513 nodes.
- free: fvar("EmptyCacheBench.open").
- early: app(free, deep); late: app(deep, free).

The last two contain the same-sized closed child. The former allows HasFVar to
stop at the head; the latter requires visiting the closed child first. These
are diagnostic shapes, not a reconstruction of the entire Church term.

Build three actual maps, all with the same value payload:

1. empty = the actual psKernelExprMapEmpty; require small=nil and index=none.
2. small = eight distinct raw public insertions, in this order:
   hit, early, late, bvar(100), bvar(101), const("EmptyCacheBench.seed", []),
   lit(nat(5)), lit(str("seed")). Require index=none and small list length 8.
3. indexed = small followed by bvar(1000), bvar(1001), bvar(1002), bvar(1003).
   Require index=some and raw lookup of every inserted key returns value.

The raw early/late entries deliberately retain the open-expression negative
control. Before and after timing, semantic lookup must return none for them
even when raw lookup finds the stored value. Require deep and miss are raw
misses, and require the shallow hit behaves as specified below.

Capture independent deep snapshots with all own string and Symbol keys before
oracle checks, warm-up, or timing. Check cache and query remain unchanged after
the measured loop. Input construction, snapshots, imports, oracle calls and
post-loop validation are outside the measured interval.

## Frozen inventory and call counts

One process executes exactly one row. No calibration or adaptive iterations.

| Case | Map | Query | Expected semantic result | Warm-up calls | Measured calls |
|---|---|---|---|---:|---:|
| empty/shallow | empty | hit | none | 4096 | 1000000 |
| empty/deep | empty | deep | none | 4096 | 10000 |
| empty/early-open | empty | early | none | 4096 | 1000000 |
| empty/late-open | empty | late | none | 4096 | 10000 |
| small/hit | small | hit | some(value) | 4096 | 1000000 |
| small/deep-miss | small | deep | none | 4096 | 10000 |
| small/early-open | small | early | none; raw hit retained | 4096 | 1000000 |
| small/late-open | small | late | none; raw hit retained | 4096 | 10000 |
| indexed/hit | indexed | hit | some(value) | 4096 | 1000000 |
| indexed/deep-miss | indexed | deep | none | 4096 | 10000 |
| indexed/early-open | indexed | early | none; raw hit retained | 4096 | 1000000 |
| indexed/late-open | indexed | late | none; raw hit retained | 4096 | 10000 |
| small/shallow-miss | small | miss | none | 4096 | 1000000 |
| indexed/shallow-miss | indexed | miss | none | 4096 | 1000000 |

For each row, launch A, B, B, A sequentially on one Linux runner. All four are
fresh Node processes; never import both variants into one process. Preserve this
row order and ABBA order: 14 rows, 56 observations, 28 processes per variant.
Do not run timed processes concurrently.

## Runtime and measurement

Use the same captured Node 22 executable for every observation, with an empty
PATH, --max-old-space-size=2048 and a 60-second host timeout. Use --expose-gc
consistently; perform exactly one explicit collection after construction and
semantic prechecks, and one after the fixed warm-up, both outside timing. Do not
collect explicitly inside the measured interval. A 25-minute job limit bounds
the complete experiment; do not raise timeouts or call counts on failure.

Capture node version and binary SHA256 and require the binary matches the
semantic leaf tools receipt. Before timing, run the archived 1884 and 21 harnesses
once per variant, outside all timed processes. The helper has no fuel argument;
this protocol changes no checker or fuel4096 policy.

Time only the fixed loop using process.hrtime.bigint(). Capture process.cpuUsage
around the same interval. Each iteration must execute the actual exported helper,
store its returned object in a preallocated 1024-slot ring, and update a checksum
from its observed Option result. Use a validated actual Option tag/value shape;
do not infer constructors from truthiness or manufacture results. Validate the
ring's complete semantic results after timing and require the exact checksum.
Checksum codes must bind both the actual Option constructor tag and the expected
Some payload identity; invalid outputs contribute a code rejected after timing.

The ring and checksum consume every result and retain observable output objects.
Report the loop-plus-consumption cost honestly; do not subtract a separately
measured empty loop. No result serialization, logging, assertions, expression
construction or cache insertion belongs inside the timed loop.

Record heapUsed and rss immediately before and after the interval, plus process
maxRSS. Label maxRSS as whole-process memory including import and setup; it is
not a measurement of helper allocation alone. Do not use memory deltas as proof
of bounded allocation or freedom from retention.

## Receipts and interpretation

Each observation records experiment/source/run/attempt, sequence position,
variant, actual kernel SHA256 and source SHA, Node identity, row, map shape,
expected result, warm-up count, measured call count, consumed checksum, elapsed
nanoseconds, user/system CPU microseconds, memory readings, timeout status,
semantic controls and input-immutability checks. Bind the executed timing script
and launcher bytes. Retain every raw observation, stdout/stderr and exit status.

The aggregate must require exactly the ordered 56 observations and report both
raw values for A and B, their medians and ranges, and per-row B/A ratios. Do not
pool unlike rows, remove outliers, silently retry samples, rescale counts, or
declare statistical confidence from two observations per variant. Any timeout,
semantic mismatch, mutation or missing observation makes the protocol incomplete.

Even a large cold-closed improvement is only helper evidence. An early-free
Church frame may already short-circuit eligibility, so this experiment cannot
attribute a whole-Church speedup or acceptance change. All semantic errors,
including the recorded owner-fuel exhaustion, remain subject to unchanged
checker policy.

Adoption still requires the original whole-kernel four-case regression
experiment with exact candidate artifacts and preserved fuel4096/60s/emptyPATH/
2048MiB controls, complete fresh correctness qualification, and independent
artifact verification. Full193 Arena compatibility and broad performance remain
separate obligations. Do not restore or adopt the held three-binding transform
optimization as part of this experiment.
