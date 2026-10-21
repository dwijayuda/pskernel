# PSKernel-Core performance receipts — 2026-10-21


## 2026-10-21 — source889 native and generated full-operation measurements

Source `88924063a5d9761f52a130c6a581cac6901ad407`;
[integration run39595204321](https://github.com/dwijayuda/pskernel/actions/runs/39595204321)
is terminal PASS, including native119205679872 and generated119205679479.
All114 native warm/cold observations,128 generated complete-check observations
and24 generated admission observations preserved their exact result assertions.
The tables contain every workload in those three measured groups, not a
whole-corpus performance claim. Each warm/cold value is the mean of two
observations per variant on the same runner. Warm times are totals for the
listed call count, not per-call latency. Input construction is separately shown.

The V1/DAG ratio is V1 time divided by DAG time; below1 means a DAG regression.
The two-sample measurements are descriptive, not confidence bounds. Native
official-Lean measurements are included as a separate control; its kernel
resource accounting is not the PSKernel fuel counter.

### Native public WHNF and DefEq

| Operation / shape / depth | Calls | V1 warm ms | DAG warm ms | V1/DAG | V1/DAG cold ms | Official Lean warm ms |
| --- | ---: | ---: | ---: | ---: | --- | ---: |
| whnf / metadata / 96 | 300 | 29.173 | 9.364 | 3.115 | 0.112/0.046 | 1.171 |
| whnf / zeta / 32 | 100 | 8.573 | 7.316 | 1.172 | 0.103/0.087 | 1.848 |
| whnf / zeta / 96 | 50 | 26.783 | 10.700 | 2.503 | 0.566/0.228 | 2.792 |
| whnf / zeta / 192 | 20 | 39.514 | 8.445 | 4.679 | 2.030/0.452 | 2.823 |
| whnf / fn-shared / 8 | 100 | 1.806 | 2.084 | 0.867 | 0.047/0.059 | 0.422 |
| whnf / fn-shared / 32 | 40 | 3.964 | 2.189 | 1.811 | 0.128/0.094 | 0.428 |
| whnf / fn-shared / 128 | 10 | 11.711 | 1.896 | 6.178 | 1.205/0.239 | 0.401 |
| whnf / fn-alpha / 8 | 100 | 1.753 | 3.232 | 0.542 | 0.047/0.069 | 0.466 |
| whnf / fn-alpha / 32 | 40 | 3.985 | 3.946 | 1.010 | 0.138/0.148 | 0.499 |
| whnf / fn-alpha / 128 | 10 | 11.745 | 3.827 | 3.069 | 1.190/0.423 | 0.446 |
| whnf / fn-unique / 8 | 100 | 3.711 | 6.524 | 0.569 | 0.071/0.107 | 1.509 |
| whnf / fn-unique / 32 | 40 | 8.889 | 10.485 | 0.848 | 0.284/0.311 | 5.519 |
| whnf / fn-unique / 128 | 10 | 22.357 | 12.891 | 1.734 | 2.242/1.345 | 18.251 |
| whnf / fn-collision / 8 | 100 | 4.033 | 8.170 | 0.494 | 0.074/0.137 | 1.478 |
| whnf / fn-collision / 32 | 40 | 11.098 | 21.913 | 0.506 | 0.305/0.622 | 5.600 |
| whnf / fn-collision / 128 | 10 | 32.336 | 59.816 | 0.541 | 3.160/5.970 | 18.133 |
| defeq / metadata-pair / 32 | 100 | 6.029 | 3.364 | 1.792 | 0.091/0.055 | 0.790 |
| defeq / metadata-pair / 96 | 40 | 14.156 | 4.121 | 3.435 | 0.359/0.135 | 1.542 |
| defeq / metadata-pair / 192 | 20 | 25.952 | 4.451 | 5.831 | 1.153/0.272 | 2.512 |

The90 isolated-worker process-memory records span69,156–72,216KiB peak RSS.
There are96 separate input-construction records. Native collision-heavy function
WHNF remains materially slower: at depth8,100 calls,8.170ms DAG versus4.033ms V1;
the ratio is0.494. Shared-function depth128 improves to1.896ms DAG versus11.711ms V1.
These selected shapes do not establish an acceptable universal deployment bound.

### Generated complete public checking

These128 observations cover32 operation/shape/batch combinations. All public
validation/decoding/checking in the invoked operation is included. The RSS column
is the maximum observed worker peak across each variant's two samples; retained
heap is the mean post-GC delta. It is not an allocator-allocation count.

| Operation / shape / depth / batch | Calls | V1 warm ms | DAG warm ms | V1/DAG | V1/DAG cold ms | V1/DAG build ms | V1/DAG max RSS KiB | V1/DAG retained bytes |
| --- | ---: | ---: | ---: | ---: | --- | --- | --- | --- |
| check / metadata / 32 / 1 | 6 | 111.713 | 41.726 | 2.677 | 29.053/15.791 | 0.141/5.976 | 150764/108460 | 390464/105476 |
| check / metadata / 96 / 1 | 4 | 252.298 | 70.307 | 3.589 | 97.547/27.029 | 0.661/13.679 | 216416/137160 | 45448/208608 |
| check / metadata / 192 / 1 | 2 | 338.337 | 61.870 | 5.469 | 228.967/44.456 | 0.899/22.580 | 246192/154680 | 26768/52000 |
| check / zeta / 8 / 1 | 3 | 38.676 | 38.502 | 1.005 | 29.443/33.722 | 0.128/4.237 | 116764/116744 | 75328/74028 |
| check / zeta / 24 / 1 | 2 | 72.014 | 60.852 | 1.183 | 57.483/59.895 | 0.203/10.380 | 155084/141920 | 19976/36424 |
| check / zeta / 48 / 1 | 1 | 85.364 | 61.470 | 1.389 | 117.305/103.674 | 0.686/16.601 | 224272/191048 | 47632/23848 |
| whnf / metadata / 96 / 1 | 4 | 246.324 | 85.745 | 2.873 | 97.589/33.453 | 0.627/13.324 | 220156/136628 | 53696/239208 |
| defeq / metadata / 96 / 1 | 4 | 491.630 | 97.796 | 5.027 | 170.536/38.863 | 0.633/13.510 | 240028/144384 | 51256/130080 |
| batch-check / metadata / 96 / 8 | 2 | 954.704 | 138.190 | 6.909 | 577.473/102.003 | 0.653/13.485 | 251920/213956 | 15016/16480 |
| defeq / metadata-pair / 32 / 1 | 4 | 201.376 | 123.831 | 1.626 | 82.487/50.035 | 0.281/10.878 | 196920/151980 | 36168/77624 |
| defeq / metadata-pair / 96 / 1 | 2 | 385.745 | 301.171 | 1.281 | 262.975/212.850 | 0.954/23.655 | 245632/238632 | 35216/85320 |
| whnf / nat-succ / 8 / 1 | 3 | 69.888 | 65.656 | 1.064 | 34.072/37.382 | 0.148/8.139 | 166456/165060 | 37056/116780 |
| whnf / nat-succ / 32 / 1 | 1 | 200.663 | 127.792 | 1.570 | 237.059/151.712 | 0.236/14.681 | 264904/240928 | 19248/24708 |
| whnf / nat-succ / 96 / 1 | 1 | 1311.512 | 714.128 | 1.837 | 1391.957/833.639 | 0.904/27.840 | 280292/283932 | 35548/51040 |
| whnf / projection-field / 8 / 1 | 3 | 36.879 | 47.937 | 0.769 | 26.454/37.541 | 0.091/5.517 | 151636/154400 | 116816/303880 |
| whnf / projection-field / 32 / 1 | 1 | 33.094 | 33.567 | 0.986 | 38.028/54.626 | 0.200/7.118 | 168952/178464 | 54744/75488 |
| whnf / projection-field / 96 / 1 | 1 | 85.114 | 100.971 | 0.843 | 100.991/119.551 | 0.356/13.061 | 241336/239908 | 45784/109536 |
| whnf / zeta / 8 / 1 | 3 | 46.501 | 43.108 | 1.079 | 43.498/40.088 | 0.105/4.319 | 118720/117732 | 220840/116544 |
| whnf / zeta / 24 / 1 | 2 | 113.747 | 70.198 | 1.620 | 96.590/70.572 | 0.200/10.500 | 193888/155244 | 78792/66320 |
| whnf / zeta / 48 / 1 | 1 | 134.113 | 75.172 | 1.784 | 196.017/119.134 | 0.704/17.056 | 235264/211432 | 31032/33544 |
| whnf / fn-shared / 8 / 1 | 2 | 52.121 | 29.907 | 1.743 | 58.166/43.611 | 0.208/5.402 | 137720/116572 | 108568/152880 |
| whnf / fn-shared / 32 / 1 | 1 | 87.460 | 30.803 | 2.839 | 139.673/71.463 | 0.261/12.242 | 227184/153008 | 68344/83160 |
| whnf / fn-shared / 128 / 1 | 1 | 724.839 | 144.429 | 5.019 | 802.341/205.337 | 0.829/28.913 | 268192/222684 | 81380/62336 |
| whnf / fn-alpha / 8 / 1 | 2 | 55.085 | 34.518 | 1.596 | 57.903/50.627 | 0.402/13.027 | 138444/118964 | 108552/122392 |
| whnf / fn-alpha / 32 / 1 | 1 | 92.864 | 61.817 | 1.502 | 139.035/108.721 | 0.940/31.209 | 228092/195180 | 56284/88776 |
| whnf / fn-alpha / 128 / 1 | 1 | 710.177 | 258.507 | 2.747 | 807.984/319.327 | 3.243/110.608 | 268380/253024 | 77912/-22816 |
| whnf / fn-unique / 8 / 1 | 2 | 86.069 | 69.373 | 1.241 | 83.436/79.592 | 0.441/12.550 | 171440/154164 | 49836/66456 |
| whnf / fn-unique / 32 / 1 | 1 | 206.076 | 163.618 | 1.259 | 284.458/218.200 | 0.932/31.151 | 257792/222764 | 46504/50976 |
| whnf / fn-unique / 128 / 1 | 1 | 1371.300 | 776.511 | 1.766 | 1507.349/837.564 | 3.311/109.076 | 271876/272800 | 39860/-1808 |
| whnf / fn-collision / 8 / 1 | 2 | 101.531 | 90.424 | 1.123 | 93.620/89.385 | 0.399/12.465 | 186080/165816 | 57768/59088 |
| whnf / fn-collision / 32 / 1 | 1 | 361.482 | 314.684 | 1.149 | 479.426/432.099 | 0.927/30.768 | 327748/254564 | 48212/134664 |
| whnf / fn-collision / 128 / 1 | 1 | 3606.035 | 3108.742 | 1.160 | 3678.591/3263.522 | 3.300/108.103 | 283848/274940 | 31632/62488 |

### Generated complete declaration admission

| Shape / declarations per batch | Calls | V1 warm ms | DAG warm ms | V1/DAG | V1/DAG cold ms | V1/DAG build ms | V1/DAG max RSS KiB | V1/DAG retained bytes |
| --- | ---: | ---: | ---: | ---: | --- | --- | --- | --- |
| chain / 8 | 3 | 129.890 | 150.069 | 0.866 | 64.902/78.750 | 0.185/14.891 | 170508/176024 | 35008/57304 |
| chain / 32 | 2 | 272.125 | 338.964 | 0.803 | 183.267/228.586 | 0.409/58.666 | 239676/367820 | 9856/15960 |
| metadata / 8 | 3 | 418.209 | 223.431 | 1.872 | 202.734/112.261 | 0.568/29.939 | 249248/201860 | 61960/25692 |
| metadata / 32 | 2 | 1108.351 | 565.654 | 1.959 | 652.048/336.722 | 1.336/119.738 | 269980/299872 | 18056/30840 |
| binder / 8 | 2 | 115.210 | 194.654 | 0.592 | 98.856/149.303 | 0.329/24.266 | 192912/221124 | 31768/30988 |
| binder / 32 | 1 | 215.493 | 379.529 | 0.568 | 290.479/444.699 | 0.822/90.070 | 249724/358896 | 20128/52384 |

Admission timings include the public batch checker. Independent result assertions
are timed separately in the raw records; graph construction is not hidden inside
the reported admission interval. An untimed corresponding slot0 diagnostic
verifies direct positive attempts, original-ID entries, exact negative type
mismatch and dispatcher/environment parity. It does not instrument every timed
path and the raw flag remains `direct_dag_admission_path_measured:false`.

Projection WHNF and binder/chain admission regressions remain. Binder32 takes
379.529ms DAG versus215.493ms V1, with maximum observed worker RSS358,896/249,724KiB
(DAG/V1). Metadata32 admission improves from1108.351ms V1 to565.654ms DAG, but DAG
input construction and retained memory still cost more in several workloads.
The historical8.57–16.17× selected-admission figures below apply only to their
older sources and inputs; they are not a description of source889.

### Reproduction, memory policy and qualification limits

Use the integration workflow's pinned Lean4.35, TypeScript7.0.2 and Node22,
unchanged4096 kernel fuel, fresh per-operation semantic state, fixed input pools
and A-B-B-A workers. Raw source-anchored logs/manifests are in:
- [native artifact12343257329](https://github.com/dwijayuda/pskernel/actions/runs/39595204321/artifacts/12343257329),
  ZIP SHA256 `a4db9ab6bae642fb8ae217ba2be17e0781683d8c68ff29846ba993dd4b837151`;
- [generated artifact12344847028](https://github.com/dwijayuda/pskernel/actions/runs/39595204321/artifacts/12344847028),
  ZIP SHA256 `cbf433ace671102ee86226243818dd79f35f21fc6addd2aef48219b1676520e0`.

The Arena driver retains its60-second per-case wall limit and
`--max-old-space-size=2048`. The latter is a V8 old-space heap cap; it is not an
operating-system2GiB RSS cap. Child VmHWM samples from profiling are sampled lower
bounds on the eventual peak unless the process report explicitly says otherwise.
This wording corrects older shorthand without changing any execution limit.

The full Arena at source889 is a separate failed qualification run:
193 cases =170 matches,2 safety agreements,20 host timeouts and1 unsupported.
See AI_WORK_STATE.md for its exact job and artifact receipts. Successful benchmark jobs do not imply zero Arena timeouts, acceptable worst-case
performance, full DAG-native operation coverage, or global soundness. V1 remains
the default checked provider; V2 promotion is still gated on correctness,
fallback retirement and an acceptable full-workload performance contract.


## 2026-10-21 09:18 UTC — qualified lazy-delta source480

Source `480d875d5be7a9e656e7ccd1fa76cc7409a81c90`;
[integration39572301149](https://github.com/dwijayuda/pskernel/actions/runs/39572301149)
and [canonical/correctness39572301275](https://github.com/dwijayuda/pskernel/actions/runs/39572301275)
are terminal PASS.128 generated complete-check observations across32 workloads
and24 admission observations across6 workloads preserved all exact assertions.
V1/DAG warm ratios range0.703–7.437 on the32 selected workloads, not a global
speedup. Values below average two observations per variant from same-run
A-B-B-A workers. Input construction is separate; complete public checking
includes validation/decoding. Policies are unchanged.

| Operation/shape/depth | Calls | V1 warm ms | DAG warm ms | V1/DAG | V1/DAG mean peak RSS KiB | V1/DAG mean retained heap bytes |
| --- | ---: | ---: | ---: | ---: | --- | --- |
| whnf/projection-field/8 | 3 | 27.751 | 39.449 | 0.703 | 136886/139380 | 116448/295944 |
| whnf/projection-field/32 | 1 | 24.984 | 26.009 | 0.961 | 154770/164016 | 54760/75488 |
| whnf/projection-field/96 | 1 | 66.369 | 80.563 | 0.824 | 210922/213166 | 35100/90836 |
| whnf/fn-shared/128 | 1 | 575.377 | 116.209 | 4.951 | 227784/209176 | 75040/64072 |
| whnf/fn-unique/128 | 1 | 1094.475 | 612.572 | 1.787 | 232802/232206 | 42080/66172 |
| whnf/fn-collision/128 | 1 | 2995.528 | 2583.842 | 1.159 | 248572/249398 | 31648/55292 |

| Safe admission batch | Calls | V1 warm ms | DAG warm ms | V1/DAG | V1/DAG cold ms | V1/DAG build ms |
| --- | ---: | ---: | ---: | ---: | --- | --- |
| chain/8 | 3 | 103.931 | 122.698 | 0.847 | 51.417/62.501 | 0.137/11.469 |
| chain/32 | 2 | 222.289 | 292.213 | 0.761 | 146.329/189.831 | 0.274/46.192 |
| metadata/8 | 3 | 358.832 | 185.250 | 1.937 | 160.042/86.538 | 0.390/23.128 |
| metadata/32 | 2 | 931.449 | 470.895 | 1.978 | 533.982/270.521 | 1.088/95.164 |
| binder/8 | 2 | 94.837 | 149.814 | 0.633 | 75.048/115.284 | 0.213/17.377 |
| binder/32 | 1 | 176.850 | 306.901 | 0.576 | 233.559/367.199 | 0.609/69.580 |

Projection and binder/chain-admission regressions remain. Binder32 mean peak RSS
is218322/232574KiB and retained heap20488/47212bytes (V1/DAG).
Function-unique128 construction is2.372/77.321ms, cold checking1200.420/671.620ms;
function-collision128 construction is2.383/79.779ms. These measurements do not
establish acceptable full-corpus performance or justify historical8–16x claims.

The full480 [Arena run39572301156](https://github.com/dwijayuda/pskernel/actions/runs/39572301156)
failed qualification:193=170 matches+2 safety agreements+20 timeouts+1 unsupported.
The corrected logical diagnostic
[39569335308](https://github.com/dwijayuda/pskernel/actions/runs/39569335308)
uses e015 runtime, not480; it locates V1 HasFVar/cache-eligibility and
argument-list/equality costs in the two original performance cases. All original
body digests and60s/2GiB limits remain intact. Sampling data is attribution only;
timeouts remain unresolved outcomes.

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
