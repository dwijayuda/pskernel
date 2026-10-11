# M4 timing-gate diagnosis

The M4 topic's original cross-runtime run failed at one 5.111-ms admission
against a 5-ms ceiling. A single retry passed that case, but one rejection took
10.652 ms against a 10-ms ceiling. The portable kernel, compiler/backend,
benchmark fixtures and budget file were unchanged from the integration base.
Those two CI runs did not record GC events, so their individual causes cannot
be established retrospectively.

## Bounded diagnostic, 2026-10-06 (Asia/Jakarta)

A current native PSC/backend-ts build generated the shared fixture from
`test/KernelCore/Bench/CrossRuntime.lean`. A local diagnostic on Windows x64,
Node 26.7.0 used Node's `PerformanceObserver` GC entries and timed intervals.
These observations diagnose the measurement boundary; they are not Linux
Node 22 acceptance evidence.

The initial full-workload probe hit its 30-second process limit and produced
no usable measurement. A reduced probe, using 200 calls per shared workload
and twelve repetitions of the three admission cases, finished within the same
limit. Heap usage grew from 14,393,672 to 84,847,488 bytes before admissions.
One four-declaration rejection took 15.0935 ms and overlapped a 9.1251-ms minor
GC, with a net heap decrease of 24,517,736 bytes. Ordinary rejection calls
allocated roughly 1.5 MB. This reproduces earlier-work cleanup contaminating a
later, much smaller request's timing, without subtracting the GC duration.

Nine short, isolated probes (three per case) observed:

| Case | Maximum elapsed | Maximum overlapping GC |
| --- | ---: | ---: |
| Accept one | 2.057 ms | 0 ms |
| Accept 128 | 186.651 ms | 14.013 ms |
| Reject final of four | 8.972 ms | 0.412 ms |

GC during the request still occurs and is fully included. The observation
supports separating unrelated workloads; it does not justify disabling GC,
removing slow samples, weakening budgets or asserting arbitrary-request latency.

## Correction and acceptance

The schema-3 cross-runtime report gives each admission case its own fresh JS
worker, after the same import/semantic guards. No reduction workload or other
admission case runs in that process before the timed request. The shared
checking loops, kernel code and numeric budget file remain unchanged.

All three samples must still satisfy every ceiling. Every worker retains a
30-second process limit. Import and peak-RSS ceilings now cover the maximum
across all four JS workers in each sample. Evidence validation rejects missing
workers, reused process IDs, wrong cases, mixed runtimes and mismatched results.
A subprocess test verifies that an admission worker executes exactly the
selected request and cannot execute the shared checking workload.

The original measurements remain in CI history. Corrected Linux x64 / Node 22
CI results, rather than these local diagnostics, determine acceptance.
