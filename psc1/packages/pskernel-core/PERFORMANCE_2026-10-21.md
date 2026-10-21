# PSKernel-Core performance receipts — 2026-10-21

## Exact measured source and scope

This report freezes measurements at **`e1b4deb214c3088e64a18f8b15148c7a15be2924`**,
before the subsequent cache-eligibility reorder and DAG Nat extension.
[Integration run 39554691928](https://github.com/dwijayuda/pskernel/actions/runs/39554691928)
finished native job 119071612176 and generated job 119071611694 successfully.
The generated job ran authentic PSC1, TypeScript 7.0.2 and Node 22.23.3 on Linux.
Default kernel fuel was 4096. It recorded 128 public-operation observations,
24 full-admission observations and six separate diagnostic profiles.

These are selected within-run V1-versus-transitional-DAG comparisons, including
public validation and decoding. Input construction is measured separately;
warm results cannot hide that cost. Each measured checking/admission operation
starts with fresh semantic state. Warm describes runtime/process warm-up, not
a cross-operation trusted judgment cache. Generated provider transport currently
selects V1; these DAG comparisons do not claim that every provider request gets
the shown speedups.

Raw logs and machine-readable samples are in
[artifact 12325479399](https://github.com/dwijayuda/pskernel/actions/runs/39554691928/artifacts/12325479399),
zip SHA-256 `4b088c19a837a3ce38cc1980c579d60f166b0ae6ef3c0ab6fcf564d87e5dcee3`.
The artifact manifest binds all runtime sources and maps to the source revision.

## Complete safe-definition admission

Each group uses separate A-B-B-A workers, two observations per variant. Values
below are the mean measured admission time divided by calls, in milliseconds
per whole batch. They exclude the separately measured post-admission assertion
time and construction time. Every sample reported exact positive outcomes and
the independent wrong-type refusal control. These are finite fixtures, not a
statistical guarantee for arbitrary declarations.

| Shape / declarations per batch | V1 warm ms | DAG warm ms | V1 / DAG | V1 peak RSS KiB, worker range | DAG peak RSS KiB, worker range |
| --- | ---: | ---: | ---: | ---: | ---: |
| chain / 8 | 471.405 | 33.036 | 14.269× | 262576–265380 | 166916–167076 |
| chain / 32 | 1898.247 | 113.493 | 16.726× | 267856–269664 | 231680–232340 |
| metadata / 8 | 559.572 | 46.262 | 12.096× | 288340–357324 | 188524–188576 |
| metadata / 32 | 2264.777 | 186.769 | 12.126× | 262308–295824 | 223020–223776 |
| binder / 8 | 476.355 | 60.733 | 7.843× | 251160–275268 | 203804–204388 |
| binder / 32 | 1988.977 | 246.962 | 8.054× | 255588–276652 | 227244–228204 |

The selected warm advantage is **7.843×–16.726×**. It is not a whole-kernel
speedup. Peak RSS includes each process's construction, runtime and checking
lifetime; it is not retained expression bytes or allocator traffic.

Construction and retained heap show a different tradeoff:

| Shape / declarations | V1 input-pool construction ms | DAG input-pool construction ms | V1 retained heap bytes, range | DAG retained heap bytes, range |
| --- | ---: | ---: | ---: | ---: |
| chain / 8 | 0.073 | 8.279 | 33624–33976 | 57320–57320 |
| chain / 32 | 0.169 | 36.025 | 8560–16232 | 18624–18712 |
| metadata / 8 | 0.243 | 17.548 | 65112–65352 | 25336–25408 |
| metadata / 32 | 0.759 | 78.530 | 4296–4304 | 37448–37568 |
| binder / 8 | 0.166 | 12.953 | 27608–27672 | 31696–31768 |
| binder / 32 | 0.433 | 54.597 | -24120–13960 | 40616–40728 |

The input pool contains five fixture variants. Retained heap is the difference
between two explicit-GC observations with pools retained and admitted environments
discarded. Noise, including a negative delta, must not be interpreted as negative
allocation. DAG construction remains substantially more expensive than creating
recursive V1 inputs; the input lifetime and repeated-use pattern matter.

## Complete checking and function WHNF controls

The 128 operation observations form 32 balanced groups. In this exact run their
warm V1/DAG ratios range from 1.226× to 9.643×. No claim is inherited from older
favorable or unfavorable runs. Unique and collision-heavy function WHNF at
depth 128 illustrate both the checking improvement and the construction/memory cost:

| Shape / depth | Warm ms V1 / DAG | First measured check ms V1 / DAG | Input-pool construction ms V1 / DAG | Retained heap bytes V1 / DAG, worker ranges |
| --- | ---: | ---: | ---: | ---: |
| fn-unique / 128 | 1103.210 / 481.137 | 1190.997 / 559.197 | 1.745 / 59.700 | 31128–34848 / 47504–53160 |
| fn-collision / 128 | 2790.384 / 2005.774 | 3007.254 / 2058.954 | 1.843 / 58.074 | 31912–33432 / 46760–48808 |

The untimed cache diagnostics for these depth-128 DAG cases report 256 core
publications and 257 combined core/public entries with no equivalent shadowed
entries. The unique case has 256 hash buckets of maximum length one; the
collision case has 129 buckets and maximum length 128. These observations do
not measure hit/miss/probe counters. Scanner CPU and generator overhead remain
visible in the separate profiles; no exact lookup-cost or allocation-rate
conclusion is manufactured from entry counts.

Historical checkpoints recorded unique/collision WHNF regressions. The later
within-run results above are favorable for these selected controls, while DAG
construction and retained memory remain mixed. Different runner timings across
revisions are not causal estimates of a particular source change.

## Authentic Arena timeout evidence

The older diagnostic source **`e2226eafee06d872f536667e449883d0eafbef5f`**
has an independently retrieved terminal
[profile run 39552920831](https://github.com/dwijayuda/pskernel/actions/runs/39552920831).
It executes original authenticated case bodies, first unprofiled and then with
V8 statistical profiling, in detached directories with PATH empty. Each kernel
process keeps 60 seconds, 2 GiB old-space and fuel 4096. Profile collection
success is explicitly separate from kernel qualification.

| Authentic case | Official verdict | Unprofiled / profiled checker | Transport-to-kernel entry ms under profiling | Sampled VmHWM lower bound KiB |
| --- | --- | --- | ---: | ---: |
| perf/repeated-subproblem.ndjson | accepted | timeout / timeout | 192.409 | 343456 |
| perf/church-numerals.ndjson | accepted | timeout / timeout | 179.376 | 529800 |
| init-prelude.ndjson | accepted | timeout / timeout | 1915.022 | 1048248 |
| bugs/proj-of-stuck-prop.ndjson | rejected | timeout / timeout | 341.144 | 513056 |

The repeated-subproblem profile is dominated by the recursive V1 free-variable
scanner. Its call sites include both admission guards and semantic-cache policy.
The trampoline does not preserve enough logical caller information to assign
all scanner samples to one call site. Other profiles retain V1 expression
equality, recursor, WHNF and DefEq work, plus generator/WeakMap runtime overhead.
The data places the large cost after kernel entry; it does not demonstrate
heap exhaustion.

Full [Arena run 39552920736](https://github.com/dwijayuda/pskernel/actions/runs/39552920736)
at the same older source evaluated every one of 193 records and failed
qualification: 103 matching admissions, 56 matching kernel refusals, one matching
metadata refusal, seven matching transport refusals, two separately classified
unsafe/partial safety-contract agreements and 24 host timeouts. A metadata or
transport refusal is not an independently checked theorem. The timeout identity
set did not change from the previously recorded 24-case baseline.

Profile artifact [12324932888](https://github.com/dwijayuda/pskernel/actions/runs/39552920831/artifacts/12324932888)
zip SHA-256: `a148d87d408981df3ce0f16f717feef8d3386e363a9941ee4cd7420929a836ba`.
Comparison artifact [12325647052](https://github.com/dwijayuda/pskernel/actions/runs/39552920736/artifacts/12325647052)
zip SHA-256: `07f3603ffef2a5df008307bcba291f89c26ed92e47cc6164e6cbdcf38d14d6b5`.
Their per-case records retain original body hashes and adapted transport hashes.

## Deployment performance contract and next measurement

The scoped provider is a developer checker with explicit completion/error
outcomes, not a full-library throughput commitment. Hosts must bound a detached
process and classify a process timeout or crash separately from a kernel refusal.
The provider's input/resource limits are fixed in [PROVIDER.md](PROVIDER.md).
The Arena release gate remains the existing 60-second / 2-GiB case policy and
4096 recursive kernel fuel; none is raised to make measurements pass.

The source following this measured checkpoint skips free-variable scans when
the exact inference-cache policy is already known to reject the outer node kind.
Its universal Boolean equivalence is checked by the native proof gate. The same
candidate also extends the ordered DAG Nat path and hardens provider byte ownership.
No causal speedup is claimed for this combined candidate until its whole-case
results are measured. A timeout followed by a timeout gives no speedup ratio.

If the candidate completes previously timed-out cases, compare frozen baseline
and candidate canonical bundles on the same runner with unprofiled A-B-B-A runs.
Keep body hashes, verdicts, 60-second limits and RSS receipts for all 16 whole
checks over the four cases. Collect CPU profiles separately. If it still
times out without useful whole-checker progress, stop tuning this predicate:
the next structural work is owning recursor references/iota, full DefEq delta
state and removal of recursive-expression fallback, guided by logical caller
attribution.


## Allocation candidate after the repeated full-corpus failure

The subsequent source `54ea3d428d85ba2936a037a5d9decdcab1593990`
completed all 193 comparisons in
[39557632345 / job 119081796230](https://github.com/dwijayuda/pskernel/actions/runs/39557632345/job/119081796230).
Qualification **FAILED** with the same 167 matching outcomes, two separately
classified unsafe/partial safety agreements, and 24 host timeouts. The 167
comprise 103 acceptances, 56 kernel rejections, one metadata rejection and seven
transport rejections. Its outer-kind cache-eligibility reorder did not resolve
any of the 24 timed-out cases.

The four authentic-body diagnostic pairs in
[39557632125 / job 119081026195](https://github.com/dwijayuda/pskernel/actions/runs/39557632125/job/119081026195)
also remained censored at the unchanged 60-second host limit. Collection passed;
the checker cases did not finish. Sampled process high-water marks were
331,888 KiB for repeated-subproblem, 460,760 KiB for church-numerals,
1,269,652 KiB for init-prelude, and 433,344 KiB for proj-of-subst-prop.
These sampled values are lower bounds, not exact process peak RSS. Entry/decode
times were 276.470, 276.216, 3,162.621 and 568.901 milliseconds respectively.
No completion speedup is inferred from a timeout or from profile sample counts.

Inspection of the actual portable source identified eager recursive closures
in both expression-equality functions and fifteen fuel-indexed workers.
The containing candidate moves recursive aliases underneath existing argument
lambdas, preserving their types, arguments, branches, error guards, recursive
fuel and callback placement. Frozen predecessor definitions and universal local
function-equality theorems are added in `PsKernelExprEqualityProofs.lean` and
`PsKernelKnotFuelProofs.lean`; GitHub Actions must check them before promotion.
Native and both generated routes also require immediate mismatches against a
65-node shared expression with an exponentially large unfolded tree.

This is a structural allocation candidate, **not yet a measured corpus fix**.
It changes helpers used by both V1 and the transitional DAG implementation.
Same-revision V1-versus-DAG benchmark results must therefore remain distinct
from before/after comparisons against the authenticated
`854bdb9e0febf4e01fb5ce4b2cc8ea91f61287e4` artifacts. Recursive free-variable
and node-count scans and the four whole-operation
fallback sites are still present. Default kernel fuel remains 4096 and the
Arena host policy remains 60 seconds / 2 GiB.

Raw full-corpus artifact:
[12327273770](https://github.com/dwijayuda/pskernel/actions/runs/39557632345/artifacts/12327273770),
zip SHA-256 `cbbc6546fd0134d17395e43e7716fa62bac4be0e6d1c4b5767e04c5b7dd916e3`.
Authentic profile artifact:
[12327038831](https://github.com/dwijayuda/pskernel/actions/runs/39557632125/artifacts/12327038831),
zip SHA-256 `228783c5f075481fe2be41f91cd9367874884f1caef6e8953a4c0adeb9880d11`.
