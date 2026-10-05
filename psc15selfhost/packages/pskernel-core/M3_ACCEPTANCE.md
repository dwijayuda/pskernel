# M3: explicit workload budgets

Status: **M3 COMPLETE for the declared bounded profile**, verified 2026-10-05 at
`c13558c6d573ef477fed6f0ffa31a9b7e39650ca`. The execution decision prioritizes
native PSKernel for CLI/server deployment and bounds JavaScript work. The native
budget job, cross-runtime budget job, and portable semantic gates passed for that
same checkpoint. M4 provider promotion remains separate and open.

## Scope and decision

`M3_WORKLOAD_BUDGETS.json` is the executable acceptance contract. The profile is
Original acceptance evidence: Linux x64, Ubuntu 24.04 CI, pinned Lean 4.34.0 and TypeScript 5.8.3, Node 22.
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

The corrected schema-3 harness runs each JS admission case in a separate fresh
process after module import and the same semantic guards. The original mixed
worker ran tiny admissions after allocation-heavy checking loops and after the
128-declaration batch; a GC-overlap diagnostic reproduced cleanup from earlier
work inside a later request's timing. See `M4_TIMING_DIAGNOSIS.md`.
No elapsed time is subtracted, no GC is forced or disabled, and no sample is
discarded. Natural GC during the isolated request remains inside its timing.
Import and peak-RSS gates take the maximum across the workload worker and all
three admission workers per sample. The numerical ceilings and three-sample
maximum rule are unchanged. This measures isolated requests after guards;
legacy mixed-workload tail timings are not directly comparable.

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

The budgets were declared at `76ad547e29c2812d9c1deeb2dc4a052cc4d9c7b0`, before
measuring the corrected admission corpus. A fixture initializer syntax repair
produced `c13558c6d573ef477fed6f0ffa31a9b7e39650ca`; no ceiling was raised.

All three workflows passed at that commit:

- [Native budgets](https://github.com/dwijayuda/pskernel/actions/runs/37305671515):
  all 13 checks passed, including all occupied-input guards.
- [Cross-runtime budgets](https://github.com/dwijayuda/pskernel/actions/runs/37305671495):
  all 15 checks passed, including JS correctness guards and WASM verdicts.
- [Portable semantic gates](https://github.com/dwijayuda/pskernel/actions/runs/37305671494):
  architecture/compatibility/conformance audits, differential tests, PSC1 checking
  and canonical translation passed.

Maximum observations across the three samples (time rows are complete batches):

| Workload | Maximum observed | Ceiling |
| --- | ---: | ---: |
| Native ordinary admission, 100 | 5.040 ms | 100 ms |
| Native indexed admission, 100 | 4.299 ms | 100 ms |
| Native mutual admission, 100 | 17.049 ms | 200 ms |
| Native nested admission, 100 | 36.896 ms | 300 ms |
| Native wider nested admission, 50 | 65.430 ms | 250 ms |
| Native recursor reduction, 1,000 | 10.297 ms | 50 ms |
| Native shared beta WHNF, 1,000 | 26.895 ms | 50 ms |
| Native shared beta defeq, 1,000 | 4.627 ms | 20 ms |
| Native shared checked application, 1,000 | 3.571 ms | 20 ms |
| Native full benchmark peak RSS | 72.910 MiB | 256 MiB |
| Native shared-fixture peak RSS | 10.094 MiB | 256 MiB |
| JS shared beta WHNF, 1,000 | 15,476.217 ms | 20,000 ms |
| JS shared beta defeq, 1,000 | 1,595.455 ms | 3,000 ms |
| JS shared checked application, 1,000 | 1,192.520 ms | 2,000 ms |
| JS module import | 92.318 ms | 500 ms |
| JS slowest first call | 34.017 ms | 100 ms per workload |
| JS accept one definition | 0.919 ms | 5 ms |
| JS accept 128 definitions | 78.502 ms | 250 ms |
| JS reject final definition of four | 2.940 ms | 10 ms |
| JS peak RSS | 190.719 MiB | 512 MiB |

The other six native checking ceilings also passed (maximum 2.819 ms per 1,000
operations, against 20 ms for each). The reports retain every measurement,
median/range, identity, and budget hash; no successful median hides a failed
sample. Twenty local evidence-validation tests passed, including injected
over-budget, incomplete, invalid-memory, wrong-profile and wrong-work-count cases.

Corrected ordinary/indexed/mutual PSKernel/Lean median ratios were 2.11x, 1.46x,
and 2.43x. These replace the misleading historical constant-input ratios. M3
acceptance is the absolute-budget result, not a claim of native parity or broad
JS competitiveness. Production kernel source and the archived core were unchanged
through this M3 closure; only benchmarks, budget enforcement and documentation
changed.

After M3, prioritize the canonical adapter, dual checking and parity required by
M4. Until M4 is explicitly accepted, `lean434-wasm` remains the trusted default.
Continue all semantic, architecture, PSC1 and canonical ProofScript gates.

## Integration validation

PR #72 reconciles the current integration compiler and package layout. The integration
workflows use the existing TypeScript 7.0.2 compiler pin and rerun the unchanged M3
workload budgets. The original measurements above remain historical evidence for
their recorded commits; current integration results are attached to
[PR #72](https://github.com/dwijayuda/pskernel/pull/72). M4 remains open, and
`lean434-wasm` remains the trusted default.
