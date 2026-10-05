# M3: explicit workload budgets

Status: **verification pending**. The 2026-10-05 execution decision prioritizes
native PSKernel for CLI/server deployment and bounds JavaScript work. M3 closes
when the native budget job, cross-runtime budget job, and portable semantic gates
pass for the same checkpoint. M4 provider promotion remains separate.

## Scope and decision

`M3_WORKLOAD_BUDGETS.json` is the executable acceptance contract. The profile is
Linux x64, Ubuntu 24.04 CI, pinned Lean 4.34.0 and TypeScript 5.8.3, Node 22.
Reports record the exact commit, runtime identity, budget SHA-256, and (for JS)
generated artifact SHA-256. Runner CPU/image details remain observations rather
than a promise about user hardware.

Every one of **three fresh-process samples** must satisfy every ceiling. The
median is displayed for context; one over-budget sample fails the gate. Missing
results, incorrect success/rejection counts, malformed memory observations, or a
different runtime profile also fail. A fast error is never a performance pass.
Lean and JS/native ratios remain informative comparisons, not acceptance gates.

These are bounded small-workload budgets chosen before measuring the corrected
admission corpus. They express useful response/batch limits with headroom over
the existing measurements. They are not derived from an automatic multiplier of
each new result. Do not silently raise a ceiling to make a failure pass: diagnose
it, fix a measured defect, or make an explicit documented scope/budget decision.

## Native deployment target

| Workload | Timed operations per sample | Ceiling per sample |
| --- | ---: | ---: |
| WHNF, defeq, beta, application, dependent application, structural equality | 1,000 each | 20 ms each |
| Recursor reduction | 1,000 | 50 ms |
| Ordinary / indexed inductive admission | 100 each | 100 ms each |
| Mutual admission | 100 | 200 ms |
| Nested admission | 100 | 300 ms |
| Wider nested admission | 50 | 250 ms |
| Shared 16-step beta WHNF | 1,000 | 50 ms |
| Shared beta defeq / eight-argument application | 1,000 each | 20 ms each |
| Peak resident memory, each native benchmark process | Whole process | 256 MiB |

This bounds the measured native admission batches to an average of 1-5 ms per
operation and the checking loops to tens of microseconds per operation. These
averages are not individual-request tail-latency guarantees. Fixture construction
is outside the timed intervals. The corpus includes ordinary/indexed/mutual/nested
admission, dependent inference, recursors and cold checked sessions; it is not a
large proof-library or arbitrary-input scalability claim.

## JavaScript portability target

| Workload | Timed operations per sample | Ceiling per sample |
| --- | ---: | ---: |
| Shared 16-step beta WHNF | 1,000 | 20,000 ms |
| Shared beta defeq | 1,000 | 3,000 ms |
| Shared eight-argument application | 1,000 | 2,000 ms |
| Module import, including module initializers/guards | Once | 500 ms |
| First call of each shared workload, after guards | Once each | 100 ms each |
| Accept one definition | 1 | 5 ms |
| Accept 128 definitions | 128 | 250 ms |
| Reject the last of four definitions | 4 | 10 ms |
| Peak resident memory | Whole Node worker | 512 MiB |

The shared loops use sixteen prebuilt inputs, 100 warmup calls and a fresh kernel
session per measured call. Naturals above 2^53 remain exact. Guards cover invalid
terms/declarations, exhaustion, 729 expression-equality pairs and 54 zero lifts.

This accepts JS for the named small Node fixtures and preserves the PSC/backend-ts
path. It does not claim browser responsiveness, bulk checking competitiveness,
native-speed JS, a complete JS provider adapter, or npm/browser release readiness.
Large JS optimization work is deferred until an intended deployment requires it.

## Benchmark integrity and cost

The ordinary/indexed/mutual loops now select from sixteen prepared ambient
environments at runtime. Matching Lean environments contain the same ambient
axiom. Each call admits into its selected base, keeping cache/history growth out
of the comparison. The admission expression is no longer closed and eligible for
one-time initialization. Untimed guards feed already occupied environments back
through every loop and require rejection in both implementations. Historical
constant-input timings for those three rows must not be used as throughput wins.

Native peak RSS comes from GNU time around each executable. GNU timeout enforces
30 seconds for the child process group, with a two-second kill grace. JS peak RSS
comes from Node's process resource usage and includes import/guards/warmup. The
profile run is separate from the three samples. RSS is total resident process
memory, not an allocation count or a bound for arbitrary requests.

The existing Lean WASM provider still runs bounded acceptance/rejection requests.
Its full-request timing remains informational because subprocess, decoding,
prelude and verification boundaries differ from direct JS fixtures. Its memory
is not inferred from the parent Node process. No new WASM build, full generated
compiler/kernel fixed point, broad fuzz campaign or large proof-library replay
is part of M3.

## Completion evidence

Pending the first run with these fixed budgets and corrected admission inputs.
All three workflows must pass for one commit before recording completion.

After M3, prioritize the canonical adapter, dual checking and parity required by
M4. Until M4 is explicitly accepted, `lean434-wasm` remains the trusted default.
Continue all semantic, architecture, PSC1 and canonical ProofScript gates.
