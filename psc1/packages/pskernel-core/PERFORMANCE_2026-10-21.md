# PSKernel-Core performance receipts — 2026-10-21

## Subsequent full-corpus receipt: f483 allocation runtime

Full run [39564831733](https://github.com/dwijayuda/pskernel/actions/runs/39564831733/job/119105347671)
is terminal FAIL qualification: 193 records,170 matching outcomes (103accepted,
59kernel rejections,1metadata rejection,7transport rejections),2safety-contract
agreements,20host timeouts,1explicit unsupported nested-recursion case.
Three previous bad-case timeouts now finish with the correct rejection; the fourth
now reports unsupported and is not counted as a rejection/parity pass.
The remaining timeout cases are24,73,79–88,91–97,99. No budget or host limit changed.
This source-bound result supersedes pending f483 corpus wording in the dated
entries below; the new Delta successor still needs its own gates.
Artifact12329788354 ZIP SHA-256
`b66dd329573eee116890d0d9bac5e55d55db5ac1ec055be757808716944dc6a1`.

## 2026-10-21 08:12 UTC — qualified allocation change at e015

Source: **`e015839e0cdf29b1e4f2d4a750fed8956c0afe17`**.
Native [119106602099](https://github.com/dwijayuda/pskernel/actions/runs/39565480601/job/119106602099)
and generated [119106602375](https://github.com/dwijayuda/pskernel/actions/runs/39565480601/job/119106602375)
are terminal PASS. The canonical-source and provider gates also passed.
These are same-source, same-runner V1-versus-transitional-DAG comparisons.
Warm means runtime warm-up; every public operation retains fresh semantic state.
Input construction is reported separately, and admission assertions are separate
from the measured admission interval. All resource policies are unchanged.

The change delays recursive closure construction in the two expression equalities
and fifteen fuel-indexed workers. All four equality and fifteen worker-equivalence
theorems passed the native proof gate. Both variants use those changed helpers;
the old 8–16x DAG admission ratios are historical and do not describe this source.
Comparing timings across earlier Actions machines would not be a controlled
before/after experiment.

### Complete native operations

All 114 observations over 19 workloads were correct. Mean V1/DAG warm ratios range
0.523–6.737x. For fn-collision depth32, 40 calls take 14.536ms V1 and 27.806ms DAG
(official Lean 7.310ms): a real DAG regression. For fn-shared depth128, ten calls
take 15.811ms V1 and 2.347ms DAG (official Lean 0.505ms). Observed worker peak RSS
ranges 68,644–71,352KiB. These selected results are not a whole-kernel claim.

### Complete generated operations

All 128 observations over 32 workloads were correct. Mean V1/DAG warm ratios range
0.677–6.102x. Times below are milliseconds for the logged call count; RSS is the
mean of isolated worker peak observations, not retained-heap size.

| Operation / shape / depth | Calls | V1 warm | DAG warm | V1 cold | DAG cold | V1 / DAG construction | V1 / DAG peak RSS KiB |
| --- | ---: | ---: | ---: | ---: | ---: | --- | --- |
| whnf:projection-field:8:1 | 3 | 22.575 | 33.356 | 15.684 | 20.880 | 0.061 / 3.313 | 137026 / 138102 |
| whnf:projection-field:32:1 | 1 | 20.097 | 21.392 | 22.416 | 32.561 | 0.098 / 3.944 | 155716 / 164242 |
| whnf:projection-field:96:1 | 1 | 57.462 | 73.275 | 67.804 | 89.892 | 0.207 / 6.794 | 210268 / 208218 |
| whnf:fn-unique:128:1 | 1 | 863.352 | 499.426 | 1000.717 | 560.044 | 1.681 / 60.831 | 234324 / 233400 |
| whnf:fn-collision:128:1 | 1 | 2531.296 | 2204.804 | 2589.195 | 2187.865 | 1.760 / 60.985 | 247216 / 235244 |

The three projection-field workloads regress. DAG construction for the two
depth128 function workloads is roughly 35–36x the recursive input construction.
Retained-heap deltas are also mixed: fn-unique128 averages 37,976B V1 / 48,808B DAG;
fn-collision128 31,604B / 57,624B. GC deltas are observations, not exact ownership
sizes or a promise of monotonic retained memory.

### Complete safe-definition admission

All 24 observations across six workloads passed exact admitted-environment and
negative type-mismatch controls. Every batch starts from an independent empty
session. The untimed DAG dispatcher diagnostics confirm the selected direct path
without instrumenting the timed run.

| Shape / declarations | Calls | V1 warm ms | DAG warm ms | V1/DAG | V1 cold ms | DAG cold ms | V1 / DAG construction ms | V1 / DAG peak RSS KiB | V1 / DAG retained heap B |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | --- | --- | --- |
| chain:8 | 3 | 85.732 | 99.117 | 0.865x | 41.271 | 49.003 | 0.097 / 8.175 | 166054 / 167104 | 35136 / 57328 |
| chain:32 | 2 | 185.943 | 243.646 | 0.763x | 119.377 | 155.104 | 0.200 / 51.672 | 211934 / 226034 | 6432 / 19592 |
| metadata:8 | 3 | 287.179 | 154.935 | 1.854x | 133.091 | 66.115 | 0.277 / 17.815 | 213926 / 187922 | 63632 / 25372 |
| metadata:32 | 2 | 768.408 | 372.819 | 2.061x | 436.418 | 227.771 | 0.776 / 76.831 | 225022 / 224804 | 16388 / 30980 |
| binder:8 | 2 | 79.763 | 143.357 | 0.556x | 64.239 | 96.522 | 0.154 / 13.050 | 166922 / 204758 | 31800 / 31816 |
| binder:32 | 1 | 141.080 | 244.794 | 0.576x | 185.822 | 297.965 | 0.401 / 51.790 | 254060 / 229624 | 20344 / 46696 |

Chain and binder admission are slower through the transitional DAG path at this
source. Metadata admission is faster, while metadata32 construction is much more
expensive (0.776ms V1 / 76.831ms DAG). V1 remains the production provider/default.
This evidence does not justify switching a partially migrated V2 to the default
or asserting a generally improved memory contract.

Raw native artifact [12329830825](https://github.com/dwijayuda/pskernel/actions/runs/39565480601/artifacts/12329830825),
ZIP SHA-256 `56cd991ad2f5d9572cab9ec9ca614d106e9157cbd2b3bd1006d8c91f1c7af2c6`.
Raw generated artifact [12330606437](https://github.com/dwijayuda/pskernel/actions/runs/39565480601/artifacts/12330606437),
ZIP SHA-256 `aec4002f33b6b6427d9ffd85cc864265d68561a1ed3f29788aa43522e5bb29fb`.

Full Arena e015 run39565480377 and runtime-equivalent f483 run39564831733 are still
in progress at this update. Authentic four-case profile39564831855 has completed at f483: repeated-subproblem,
church-numerals and init-prelude still time out in both unprofiled and V8-profiled
runs, while bugs/proj-of-stuck-prop now completes with the expected rejection in
both runs. Sampled VmHWM lower bounds in the profiled processes are respectively
290,456 / 557,588 / 1,326,848 / 374,464KiB. Admission-entry times were respectively
274.016 / 280.535 / 3,050.367 / 542.081ms. These are progress/diagnostic observations,
not total completion latency, and a censored timeout has no numeric speedup.
The first case's hot JS functions include psKernelExprHasFVar; logical call-site
tracing is the next diagnostic step. Full-corpus counts await terminal comparison.
Profile artifact12330238456 has ZIP SHA-256
`d72ec722055e6f52ef5e8d6af1b53ab5b18c7355d1384536124033bd7f128322`.
This new correct whole-checker rejection is source-bound to f483; proof-only e015
has an identical runtime source but must retain its own qualification receipts. Kernel fuel remains4096 and host bounds60s/2GiB.

## Earlier immutable measurement receipts

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
