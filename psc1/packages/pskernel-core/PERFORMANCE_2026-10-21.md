# PSKernel-Core performance receipts — 2026-10-21

## Exact carrier checkpoint 4894fce (2026-10-21)

Source: `4894fce8c7d048ae188495bc2090fedfddf7fcb4`. The complete [integration run](https://github.com/dwijayuda/pskernel/actions/runs/39614047016) and [canonical-source correctness run](https://github.com/dwijayuda/pskernel/actions/runs/39614046627) are terminal PASS. These are fresh measurements for the complete-state/K/major carrier. They do not qualify a subsequent merge or establish a general performance improvement. Its full Arena comparison was still running when this receipt was committed.

[Raw samples](evidence/2026-10-21-4894fce-performance.json) preserve all 114 native WHNF/DefEq, 90 native isolated-memory, 96 construction, 128 generated public-check and 24 complete-admission records. Timings below are total milliseconds per stated call count, averaged over the two workers per variant; RSS is the maximum per variant, in KiB. Public checks include validation and decoding; construction is separate. Fresh semantic state, negative controls, cold timings and post-GC retained-heap observations are retained in the raw records. Negative retained deltas are not allocation counts. Timed admission paths are not instrumented; the separate direct-path diagnostic remains explicitly untimed. The six complete CPU/allocation profile records remain in the immutable generated job and its artifact. Official Lean timings use its own kernel budget.

### Native complete WHNF and DefEq

| Operation / shape / depth / calls | Official Lean ms | V1 ms | DAG ms | DAG/V1 |
|---|---:|---:|---:|---:|
| whnf / metadata / 96 / 300 | 1.430 | 38.842 | 13.600 | 0.350 |
| whnf / zeta / 32 / 100 | 2.704 | 11.010 | 9.875 | 0.897 |
| whnf / zeta / 96 / 50 | 3.980 | 34.107 | 14.340 | 0.420 |
| whnf / zeta / 192 / 20 | 4.159 | 48.754 | 11.437 | 0.235 |
| whnf / fn-shared / 8 / 100 | 0.632 | 3.164 | 3.151 | 0.996 |
| whnf / fn-shared / 32 / 40 | 0.740 | 5.382 | 3.034 | 0.564 |
| whnf / fn-shared / 128 / 10 | 0.574 | 15.625 | 2.611 | 0.167 |
| whnf / fn-alpha / 8 / 100 | 0.640 | 2.355 | 4.360 | 1.852 |
| whnf / fn-alpha / 32 / 40 | 0.707 | 5.372 | 5.187 | 0.965 |
| whnf / fn-alpha / 128 / 10 | 0.621 | 15.847 | 4.854 | 0.306 |
| whnf / fn-unique / 8 / 100 | 2.074 | 5.068 | 8.808 | 1.738 |
| whnf / fn-unique / 32 / 40 | 8.398 | 11.863 | 14.606 | 1.231 |
| whnf / fn-unique / 128 / 10 | 24.014 | 29.921 | 16.936 | 0.566 |
| whnf / fn-collision / 8 / 100 | 2.099 | 5.398 | 11.003 | 2.038 |
| whnf / fn-collision / 32 / 40 | 7.379 | 15.270 | 27.901 | 1.827 |
| whnf / fn-collision / 128 / 10 | 24.058 | 42.409 | 76.316 | 1.800 |
| defeq / metadata-pair / 32 / 100 | 1.036 | 8.537 | 4.546 | 0.533 |
| defeq / metadata-pair / 96 / 40 | 1.978 | 18.346 | 5.513 | 0.301 |
| defeq / metadata-pair / 192 / 20 | 4.067 | 29.074 | 5.704 | 0.196 |

### Generated complete public checks

| Workload / size / calls | V1 warm ms | DAG warm ms | DAG/V1 | V1 cold ms | DAG cold ms | V1 RSS KiB | DAG RSS KiB | V1 input ms | DAG input ms |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| check / metadata / 32 / 6 / 1 | 113.442 | 43.165 | 0.380 | 28.833 | 15.860 | 151716 | 109044 | 0.148 | 5.460 |
| check / metadata / 96 / 4 / 1 | 237.758 | 65.748 | 0.277 | 97.151 | 26.196 | 216260 | 137192 | 0.657 | 13.382 |
| check / metadata / 192 / 2 / 1 | 325.076 | 63.362 | 0.195 | 235.323 | 43.892 | 250852 | 156620 | 0.846 | 21.753 |
| check / zeta / 8 / 3 / 1 | 41.144 | 39.097 | 0.950 | 28.136 | 31.886 | 119140 | 116784 | 0.103 | 3.764 |
| check / zeta / 24 / 2 / 1 | 70.939 | 58.505 | 0.825 | 55.342 | 57.747 | 157716 | 143028 | 0.190 | 9.633 |
| check / zeta / 48 / 1 / 1 | 83.213 | 58.278 | 0.700 | 113.335 | 96.083 | 228144 | 192636 | 0.696 | 15.996 |
| whnf / metadata / 96 / 4 / 1 | 251.829 | 84.316 | 0.335 | 98.231 | 33.034 | 220764 | 141388 | 0.641 | 13.098 |
| defeq / metadata / 96 / 4 / 1 | 497.275 | 97.702 | 0.196 | 172.308 | 37.420 | 241280 | 147772 | 0.635 | 12.286 |
| batch-check / metadata / 96 / 2 / 8 | 973.240 | 136.803 | 0.141 | 606.100 | 101.802 | 294904 | 215836 | 0.654 | 12.791 |
| defeq / metadata-pair / 32 / 4 / 1 | 215.321 | 117.169 | 0.544 | 81.954 | 49.430 | 196648 | 153180 | 0.247 | 9.927 |
| defeq / metadata-pair / 96 / 2 / 1 | 419.178 | 311.145 | 0.742 | 270.767 | 220.685 | 248080 | 235624 | 1.010 | 21.425 |
| whnf / nat-succ / 8 / 3 / 1 | 73.482 | 75.119 | 1.022 | 36.316 | 43.692 | 167620 | 167844 | 0.147 | 5.013 |
| whnf / nat-succ / 32 / 1 / 1 | 211.857 | 139.593 | 0.659 | 246.868 | 167.264 | 266572 | 246828 | 0.258 | 14.176 |
| whnf / nat-succ / 96 / 1 / 1 | 1370.774 | 803.149 | 0.586 | 1511.729 | 866.106 | 287516 | 290408 | 0.889 | 27.189 |
| whnf / projection-field / 8 / 3 / 1 | 34.584 | 52.454 | 1.517 | 25.495 | 38.657 | 152068 | 155656 | 0.093 | 5.000 |
| whnf / projection-field / 32 / 1 / 1 | 32.724 | 38.525 | 1.177 | 37.311 | 57.853 | 171520 | 180008 | 0.161 | 6.696 |
| whnf / projection-field / 96 / 1 / 1 | 89.096 | 100.251 | 1.125 | 101.852 | 122.798 | 246096 | 246968 | 0.360 | 12.280 |
| whnf / zeta / 8 / 3 / 1 | 47.523 | 44.343 | 0.933 | 42.629 | 39.325 | 120320 | 118920 | 0.096 | 3.841 |
| whnf / zeta / 24 / 2 / 1 | 118.014 | 77.924 | 0.660 | 96.631 | 69.371 | 195496 | 156692 | 0.209 | 9.904 |
| whnf / zeta / 48 / 1 / 1 | 134.384 | 78.147 | 0.582 | 196.431 | 118.037 | 244868 | 212628 | 0.704 | 16.544 |
| whnf / fn-shared / 8 / 2 / 1 | 57.040 | 29.482 | 0.517 | 57.577 | 43.020 | 141200 | 118396 | 0.197 | 4.607 |
| whnf / fn-shared / 32 / 1 / 1 | 97.964 | 31.210 | 0.319 | 142.740 | 71.225 | 233752 | 154776 | 0.253 | 11.166 |
| whnf / fn-shared / 128 / 1 / 1 | 752.501 | 156.881 | 0.208 | 845.792 | 216.448 | 270124 | 222868 | 0.861 | 28.368 |
| whnf / fn-alpha / 8 / 2 / 1 | 54.766 | 34.582 | 0.631 | 57.699 | 51.645 | 141184 | 119028 | 0.423 | 10.678 |
| whnf / fn-alpha / 32 / 1 / 1 | 98.093 | 64.713 | 0.660 | 142.360 | 108.362 | 234908 | 196236 | 0.869 | 28.473 |
| whnf / fn-alpha / 128 / 1 / 1 | 743.118 | 267.226 | 0.360 | 846.734 | 325.151 | 273888 | 258628 | 3.040 | 102.075 |
| whnf / fn-unique / 8 / 2 / 1 | 91.103 | 74.219 | 0.815 | 82.594 | 77.666 | 174660 | 156396 | 0.411 | 11.837 |
| whnf / fn-unique / 32 / 1 / 1 | 209.106 | 168.651 | 0.807 | 286.846 | 227.383 | 263400 | 225956 | 0.863 | 28.475 |
| whnf / fn-unique / 128 / 1 / 1 | 1421.950 | 795.896 | 0.560 | 1563.244 | 885.000 | 276820 | 279008 | 3.086 | 102.345 |
| whnf / fn-collision / 8 / 2 / 1 | 105.035 | 92.701 | 0.883 | 95.399 | 87.325 | 183184 | 167828 | 0.403 | 11.085 |
| whnf / fn-collision / 32 / 1 / 1 | 381.837 | 337.000 | 0.883 | 475.803 | 429.743 | 482500 | 260552 | 0.888 | 27.980 |
| whnf / fn-collision / 128 / 1 / 1 | 3795.809 | 3477.454 | 0.916 | 4118.487 | 3543.798 | 347252 | 280988 | 3.047 | 103.475 |

The last workload field is the batch size.

### Generated complete safe-definition admission

| Workload / size / calls | V1 warm ms | DAG warm ms | DAG/V1 | V1 cold ms | DAG cold ms | V1 RSS KiB | DAG RSS KiB | V1 input ms | DAG input ms |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| chain / 8 / 3 | 123.571 | 172.970 | 1.400 | 71.866 | 84.239 | 205816 | 189840 | 0.164 | 14.230 |
| chain / 32 / 2 | 274.984 | 414.308 | 1.507 | 179.690 | 252.492 | 243564 | 309156 | 0.357 | 60.604 |
| metadata / 8 / 3 | 441.116 | 381.232 | 0.864 | 197.640 | 166.873 | 283260 | 246664 | 0.508 | 28.568 |
| metadata / 32 / 2 | 1145.640 | 1055.127 | 0.921 | 670.519 | 570.331 | 286536 | 277860 | 1.224 | 115.253 |
| binder / 8 / 2 | 119.660 | 268.834 | 2.247 | 99.572 | 188.410 | 189916 | 258224 | 0.290 | 21.200 |
| binder / 32 / 1 | 260.326 | 554.792 | 2.131 | 292.692 | 633.930 | 340360 | 357948 | 0.730 | 87.211 |

Regressions remain material: binder32 admission is 554.792 ms DAG versus 260.326 ms V1 (2.131×), with 87.211 ms versus 0.730 ms input construction and maximum RSS 357948 versus 340360 KiB. Generated projection8 WHNF is 52.455 ms versus 34.584 ms (1.517×); unique and collision-heavy native WHNF also retain slower groups. These measurements do not support making a complete V2 replacement or whole-kernel speedup claim.

## Exact integration checkpoint a2590cc (2026-10-21)

Source: `a2590cc15c764dae9c6abfb941d6c3155ead5c81`. The complete [native and generated integration run](https://github.com/dwijayuda/pskernel/actions/runs/39612691517) finished successfully. The tables below are fresh measurements at that source, not inherited timings from 727. Their PASS markers qualify the asserted outcomes and measurement protocol; they do not mean every workload is faster. The separately measured full 193-case Arena gate failed with 17 host timeouts, one kernel fuel exhaustion and one unsupported input.

All timings are totals for the stated number of calls, in milliseconds. Each cell is the arithmetic mean of the two corresponding isolated workers. The original V1 remains selectable. Semantic state is fresh for each public operation/batch. Validation and decoding are part of the complete public operation; input construction is reported separately. Native official-Lean timing uses its own kernel budget, not PSKernel's 4096 policy. RSS is the maximum of the two variant workers in KiB. These are selected reproducible workloads, not a general speedup claim or a release performance contract.

[Raw source-bound samples](evidence/2026-10-21-a2590cc-performance.json) preserve 114 native WHNF/DefEq records, 90 isolated native memory records, 96 construction records, 128 generated public-check records, and 24 complete admission records. Native legacy integer-ms check rows remain in the immutable job log; they are not mixed into the nanosecond WHNF/DefEq table. Retained post-GC heap deltas, including negative values, are preserved in the raw data; they are not allocation counts. Timed admission does not instrument its direct DAG path: `direct_dag_admission_path_measured:false` remains explicit. Separate untimed path diagnostics cannot prove the exact timed branch. CPU/GC profiles and cache diagnostics remain separate artifact data, with no unsupported precise allocation claim.

### Native complete WHNF and DefEq

| Operation / shape / depth / calls | Official Lean ms | V1 ms | DAG ms | DAG/V1 |
|---|---:|---:|---:|---:|
| whnf / metadata / 96 / 300 | 0.962 | 23.379 | 7.276 | 0.311 |
| whnf / zeta / 32 / 100 | 1.429 | 6.152 | 5.379 | 0.874 |
| whnf / zeta / 96 / 50 | 2.140 | 21.433 | 7.721 | 0.360 |
| whnf / zeta / 192 / 20 | 1.762 | 32.378 | 6.350 | 0.196 |
| whnf / fn-shared / 8 / 100 | 0.379 | 1.268 | 1.566 | 1.235 |
| whnf / fn-shared / 32 / 40 | 0.395 | 2.921 | 1.620 | 0.555 |
| whnf / fn-shared / 128 / 10 | 0.348 | 8.661 | 1.371 | 0.158 |
| whnf / fn-alpha / 8 / 100 | 0.415 | 1.269 | 2.208 | 1.741 |
| whnf / fn-alpha / 32 / 40 | 0.431 | 2.760 | 2.649 | 0.960 |
| whnf / fn-alpha / 128 / 10 | 0.413 | 8.795 | 2.494 | 0.284 |
| whnf / fn-unique / 8 / 100 | 1.208 | 2.797 | 5.056 | 1.807 |
| whnf / fn-unique / 32 / 40 | 4.038 | 6.359 | 11.932 | 1.877 |
| whnf / fn-unique / 128 / 10 | 12.872 | 16.947 | 8.955 | 0.528 |
| whnf / fn-collision / 8 / 100 | 1.192 | 2.879 | 6.037 | 2.097 |
| whnf / fn-collision / 32 / 40 | 4.049 | 7.723 | 15.506 | 2.008 |
| whnf / fn-collision / 128 / 10 | 12.936 | 24.272 | 40.790 | 1.681 |
| defeq / metadata-pair / 32 / 100 | 0.703 | 4.707 | 2.692 | 0.572 |
| defeq / metadata-pair / 96 / 40 | 1.518 | 11.978 | 3.156 | 0.263 |
| defeq / metadata-pair / 192 / 20 | 2.663 | 20.346 | 3.320 | 0.163 |

### Generated complete public operations

| Operation / shape / depth / calls / batch | V1 warm ms | DAG warm ms | DAG/V1 | V1 cold ms | DAG cold ms | V1 RSS KiB | DAG RSS KiB | V1 input ms | DAG input ms |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| check / metadata / 32 / 6 / 1 | 112.063 | 41.660 | 0.372 | 28.652 | 16.154 | 150548 | 109132 | 0.184 | 5.918 |
| check / metadata / 96 / 4 / 1 | 246.614 | 70.962 | 0.288 | 91.673 | 27.723 | 215264 | 136856 | 0.650 | 13.852 |
| check / metadata / 192 / 2 / 1 | 345.639 | 63.056 | 0.182 | 231.989 | 47.262 | 246084 | 154856 | 0.885 | 23.050 |
| check / zeta / 8 / 3 / 1 | 39.101 | 40.544 | 1.037 | 29.358 | 34.274 | 117452 | 117308 | 0.105 | 4.231 |
| check / zeta / 24 / 2 / 1 | 71.053 | 62.462 | 0.879 | 56.879 | 60.297 | 156456 | 142296 | 0.208 | 10.508 |
| check / zeta / 48 / 1 / 1 | 84.236 | 62.873 | 0.746 | 116.649 | 100.303 | 226908 | 191944 | 0.665 | 18.154 |
| whnf / metadata / 96 / 4 / 1 | 246.155 | 87.819 | 0.357 | 98.223 | 34.596 | 218336 | 137600 | 0.639 | 12.645 |
| defeq / metadata / 96 / 4 / 1 | 511.399 | 105.593 | 0.206 | 180.791 | 39.035 | 242672 | 144768 | 0.661 | 14.367 |
| batch-check / metadata / 96 / 2 / 8 | 956.448 | 137.977 | 0.144 | 579.012 | 100.157 | 251244 | 213824 | 0.629 | 13.783 |
| defeq / metadata-pair / 32 / 4 / 1 | 214.861 | 122.500 | 0.570 | 83.909 | 51.544 | 198224 | 158404 | 0.265 | 11.409 |
| defeq / metadata-pair / 96 / 2 / 1 | 401.826 | 301.470 | 0.750 | 270.608 | 216.618 | 245252 | 238152 | 0.957 | 21.962 |
| whnf / nat-succ / 8 / 3 / 1 | 78.996 | 76.612 | 0.970 | 35.534 | 43.058 | 166864 | 166164 | 0.143 | 4.908 |
| whnf / nat-succ / 32 / 1 / 1 | 203.701 | 130.907 | 0.643 | 235.893 | 175.295 | 263920 | 243316 | 0.239 | 14.832 |
| whnf / nat-succ / 96 / 1 / 1 | 1296.339 | 755.551 | 0.583 | 1416.347 | 841.168 | 281216 | 287672 | 1.244 | 29.077 |
| whnf / projection-field / 8 / 3 / 1 | 36.351 | 48.587 | 1.337 | 25.802 | 39.810 | 151792 | 154900 | 0.095 | 6.619 |
| whnf / projection-field / 32 / 1 / 1 | 30.313 | 37.993 | 1.253 | 38.141 | 57.210 | 168828 | 177944 | 0.166 | 7.325 |
| whnf / projection-field / 96 / 1 / 1 | 89.356 | 95.327 | 1.067 | 101.145 | 123.972 | 245368 | 247372 | 0.384 | 12.387 |
| whnf / zeta / 8 / 3 / 1 | 48.475 | 43.161 | 0.890 | 43.764 | 40.632 | 118700 | 119076 | 0.105 | 4.261 |
| whnf / zeta / 24 / 2 / 1 | 116.977 | 70.929 | 0.606 | 97.325 | 70.713 | 194144 | 155332 | 0.206 | 10.780 |
| whnf / zeta / 48 / 1 / 1 | 133.666 | 80.668 | 0.604 | 197.495 | 121.162 | 240456 | 210632 | 0.706 | 17.088 |
| whnf / fn-shared / 8 / 2 / 1 | 55.876 | 29.035 | 0.520 | 58.014 | 44.763 | 140468 | 117324 | 0.210 | 5.342 |
| whnf / fn-shared / 32 / 1 / 1 | 103.700 | 32.251 | 0.311 | 140.666 | 73.706 | 229136 | 153156 | 0.269 | 11.553 |
| whnf / fn-shared / 128 / 1 / 1 | 745.325 | 151.413 | 0.203 | 829.549 | 206.767 | 270312 | 223108 | 0.863 | 29.326 |
| whnf / fn-alpha / 8 / 2 / 1 | 53.971 | 33.161 | 0.614 | 57.901 | 51.364 | 140664 | 119180 | 0.422 | 12.508 |
| whnf / fn-alpha / 32 / 1 / 1 | 107.975 | 61.377 | 0.568 | 142.931 | 110.647 | 230560 | 195244 | 0.929 | 30.839 |
| whnf / fn-alpha / 128 / 1 / 1 | 729.069 | 267.841 | 0.367 | 825.083 | 316.269 | 269664 | 367800 | 3.330 | 123.780 |
| whnf / fn-unique / 8 / 2 / 1 | 86.910 | 69.079 | 0.795 | 83.501 | 79.712 | 172860 | 155196 | 0.421 | 13.142 |
| whnf / fn-unique / 32 / 1 / 1 | 204.147 | 158.611 | 0.777 | 282.520 | 222.562 | 263084 | 224584 | 0.931 | 31.625 |
| whnf / fn-unique / 128 / 1 / 1 | 1370.719 | 791.036 | 0.577 | 1516.509 | 864.918 | 273592 | 274576 | 3.326 | 109.619 |
| whnf / fn-collision / 8 / 2 / 1 | 111.002 | 93.985 | 0.847 | 95.947 | 90.590 | 185348 | 166692 | 0.420 | 11.972 |
| whnf / fn-collision / 32 / 1 / 1 | 376.863 | 324.572 | 0.861 | 478.277 | 442.528 | 335860 | 257300 | 0.968 | 32.202 |
| whnf / fn-collision / 128 / 1 / 1 | 3707.321 | 3285.574 | 0.886 | 3861.284 | 3441.582 | 285900 | 436916 | 3.342 | 109.785 |

### Generated complete safe-definition admission

| Shape / declarations per batch / calls | V1 warm ms | DAG warm ms | DAG/V1 | V1 cold ms | DAG cold ms | V1 RSS KiB | DAG RSS KiB | V1 input ms | DAG input ms |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| chain / 8 / 3 | 126.280 | 168.781 | 1.337 | 66.449 | 82.996 | 181784 | 195356 | 0.175 | 14.847 |
| chain / 32 / 2 | 277.051 | 419.308 | 1.513 | 184.726 | 259.677 | 243300 | 259368 | 0.409 | 60.503 |
| metadata / 8 / 3 | 427.687 | 381.841 | 0.893 | 202.091 | 166.084 | 248824 | 286808 | 0.579 | 29.961 |
| metadata / 32 / 2 | 1148.699 | 1013.334 | 0.882 | 660.346 | 583.413 | 272312 | 271280 | 1.419 | 121.687 |
| binder / 8 / 2 | 114.705 | 264.359 | 2.305 | 101.856 | 196.898 | 189968 | 257272 | 0.322 | 21.423 |
| binder / 32 / 1 | 217.603 | 554.811 | 2.550 | 290.070 | 644.327 | 259732 | 273244 | 0.806 | 87.863 |

Native isolated-worker peak RSS ranges from 69588 to 72936 KiB. Regressions remain material: generated binder32 admission takes 554.811 ms versus 217.603 ms V1 (2.550×), and its input construction takes 87.863 ms versus 0.806 ms. Generated projection-field WHNF and native unique/collision workloads also regress as shown above. Historical 8.57×–16.17× selected admission results cannot be presented as this source's performance.


## 2026-10-21 — source727 complete-operation measurements

Source `727b3dd6df6a1ba02959f9c86596933b06ce0a0a`;
[integration39604699608](https://github.com/dwijayuda/pskernel/actions/runs/39604699608)
is terminal PASS: native119237791103 and generated119237790434. All114 native
public WHNF/DefEq observations,128 generated complete-check observations and24
generated safe-admission observations preserved their exact result assertions.
These tables include every workload from those three groups, including regressions.
They are same-run V1/DAG comparisons, not controlled before/after comparisons
with889 or evidence of whole-corpus performance.

Times are means of two workers per variant. Warm milliseconds are totals for the
listed call count, not per-call or per-declaration latency. Cold milliseconds
are the first measured operation/batch; construction is separate. V1/DAG below1
means a DAG regression. RSS is the maximum of the two worker peak observations,
not retained heap. Two samples are descriptive measurements, not confidence bounds.
Kernel fuel4096 and the existing host policy are unchanged.

### Native public WHNF and DefEq

| Operation / shape / depth | Calls | V1 warm ms | DAG warm ms | V1/DAG | V1/DAG cold ms | Official Lean warm ms |
| --- | ---: | ---: | ---: | ---: | --- | ---: |
| whnf / metadata / 96 | 300 | 29.586 | 9.445 | 3.133 | 0.113/0.048 | 1.162 |
| whnf / zeta / 32 | 100 | 8.523 | 7.315 | 1.165 | 0.109/0.085 | 1.895 |
| whnf / zeta / 96 | 50 | 26.718 | 10.608 | 2.519 | 0.564/0.236 | 2.855 |
| whnf / zeta / 192 | 20 | 38.519 | 8.520 | 4.521 | 1.999/0.452 | 2.315 |
| whnf / fn-shared / 8 | 100 | 1.787 | 2.111 | 0.846 | 0.047/0.060 | 0.434 |
| whnf / fn-shared / 32 | 40 | 4.743 | 2.204 | 2.152 | 0.163/0.098 | 0.407 |
| whnf / fn-shared / 128 | 10 | 11.428 | 1.906 | 5.997 | 1.204/0.243 | 0.374 |
| whnf / fn-alpha / 8 | 100 | 1.767 | 3.044 | 0.580 | 0.046/0.068 | 0.461 |
| whnf / fn-alpha / 32 | 40 | 3.953 | 3.937 | 1.004 | 0.128/0.137 | 0.492 |
| whnf / fn-alpha / 128 | 10 | 11.851 | 3.635 | 3.260 | 1.213/0.422 | 0.424 |
| whnf / fn-unique / 8 | 100 | 3.889 | 6.527 | 0.596 | 0.071/0.130 | 1.506 |
| whnf / fn-unique / 32 | 40 | 9.035 | 10.395 | 0.869 | 0.266/0.335 | 5.623 |
| whnf / fn-unique / 128 | 10 | 22.606 | 12.775 | 1.770 | 2.287/1.330 | 17.943 |
| whnf / fn-collision / 8 | 100 | 4.029 | 8.278 | 0.487 | 0.074/0.127 | 1.490 |
| whnf / fn-collision / 32 | 40 | 10.949 | 22.252 | 0.492 | 0.305/0.596 | 5.705 |
| whnf / fn-collision / 128 | 10 | 32.079 | 61.269 | 0.524 | 3.155/6.125 | 18.827 |
| defeq / metadata-pair / 32 | 100 | 6.040 | 3.324 | 1.817 | 0.088/0.056 | 0.783 |
| defeq / metadata-pair / 96 | 40 | 14.593 | 4.117 | 3.545 | 0.373/0.134 | 1.555 |
| defeq / metadata-pair / 192 | 20 | 25.789 | 4.473 | 5.765 | 1.166/0.275 | 2.485 |

The90 isolated native memory observations span70,132–73,236KiB.
The combined input timing in the old metadata smoke is not a per-variant construction
measurement. Official Lean is a separate control with its own kernel resource accounting.
Native collision-heavy WHNF regresses at all three measured sizes.

### Complete generated checking and WHNF

| Operation / shape / depth | Calls | V1 warm ms | DAG warm ms | V1/DAG | V1/DAG cold ms | V1/DAG construction ms | V1/DAG max RSS KiB |
| --- | ---: | ---: | ---: | ---: | --- | --- | --- |
| check / metadata / 32 | 6 | 116.072 | 42.711 | 2.718 | 28.742/16.306 | 0.145/6.228 | 150628/108832 |
| check / metadata / 96 | 4 | 248.150 | 68.066 | 3.646 | 92.189/27.787 | 0.625/14.241 | 215616/137000 |
| check / metadata / 192 | 2 | 330.200 | 65.285 | 5.058 | 233.395/44.602 | 0.893/22.529 | 247308/154528 |
| check / zeta / 8 | 3 | 38.524 | 37.782 | 1.020 | 29.072/34.455 | 0.107/4.267 | 117300/117340 |
| check / zeta / 24 | 2 | 68.493 | 60.428 | 1.133 | 57.627/60.885 | 0.220/9.868 | 156288/142344 |
| check / zeta / 48 | 1 | 80.008 | 59.587 | 1.343 | 117.575/102.184 | 0.687/17.377 | 226676/191780 |
| whnf / metadata / 96 | 4 | 251.276 | 89.445 | 2.809 | 95.656/40.856 | 0.651/13.622 | 219516/137800 |
| defeq / metadata / 96 | 4 | 494.683 | 98.656 | 5.014 | 175.936/38.188 | 0.649/14.059 | 242144/146832 |
| batch-check / metadata / 96 | 2 | 943.984 | 150.856 | 6.258 | 571.067/100.738 | 0.664/14.123 | 250616/214724 |
| defeq / metadata-pair / 32 | 4 | 207.636 | 114.904 | 1.807 | 82.010/49.391 | 0.286/10.742 | 197908/152240 |
| defeq / metadata-pair / 96 | 2 | 386.424 | 302.524 | 1.277 | 263.221/209.224 | 0.956/22.696 | 245876/236184 |
| whnf / nat-succ / 8 | 3 | 70.184 | 66.185 | 1.060 | 34.646/42.396 | 0.114/5.485 | 166748/165392 |
| whnf / nat-succ / 32 | 1 | 205.022 | 141.022 | 1.454 | 238.139/167.202 | 0.258/14.633 | 267956/243748 |
| whnf / nat-succ / 96 | 1 | 1236.185 | 727.138 | 1.700 | 1373.841/792.770 | 1.230/27.495 | 283512/284196 |
| whnf / projection-field / 8 | 3 | 35.876 | 49.185 | 0.729 | 26.405/39.515 | 0.091/5.472 | 151456/153016 |
| whnf / projection-field / 32 | 1 | 29.818 | 33.619 | 0.887 | 37.344/55.848 | 0.164/7.846 | 168968/177484 |
| whnf / projection-field / 96 | 1 | 84.185 | 97.910 | 0.860 | 95.800/122.594 | 0.404/13.066 | 244604/246344 |
| whnf / zeta / 8 | 3 | 46.861 | 43.302 | 1.082 | 43.948/40.604 | 0.106/4.318 | 119128/119340 |
| whnf / zeta / 24 | 2 | 111.305 | 68.232 | 1.631 | 95.052/70.374 | 0.205/9.539 | 194196/155712 |
| whnf / zeta / 48 | 1 | 137.172 | 79.434 | 1.727 | 200.753/120.295 | 0.718/17.100 | 238176/212296 |
| whnf / fn-shared / 8 | 2 | 55.636 | 30.160 | 1.845 | 58.247/44.743 | 0.211/5.367 | 140840/117344 |
| whnf / fn-shared / 32 | 1 | 93.318 | 31.306 | 2.981 | 138.346/73.492 | 0.274/12.217 | 229644/150536 |
| whnf / fn-shared / 128 | 1 | 731.573 | 150.544 | 4.860 | 803.495/205.072 | 0.865/30.128 | 266640/223264 |
| whnf / fn-alpha / 8 | 2 | 57.048 | 33.177 | 1.720 | 57.221/51.798 | 0.422/12.586 | 140456/118896 |
| whnf / fn-alpha / 32 | 1 | 96.563 | 59.662 | 1.618 | 137.668/112.038 | 0.917/31.767 | 229288/195732 |
| whnf / fn-alpha / 128 | 1 | 727.253 | 265.313 | 2.741 | 829.792/326.536 | 3.306/112.865 | 437344/253532 |
| whnf / fn-unique / 8 | 2 | 84.483 | 70.852 | 1.192 | 82.923/80.160 | 0.404/12.074 | 168896/155084 |
| whnf / fn-unique / 32 | 1 | 205.947 | 159.815 | 1.289 | 291.321/223.928 | 0.936/31.541 | 259196/224100 |
| whnf / fn-unique / 128 | 1 | 1395.293 | 791.784 | 1.762 | 1548.752/862.736 | 3.408/106.796 | 434000/272556 |
| whnf / fn-collision / 8 | 2 | 113.715 | 95.564 | 1.190 | 97.085/92.802 | 0.447/12.288 | 186436/166728 |
| whnf / fn-collision / 32 | 1 | 374.711 | 335.171 | 1.118 | 486.466/435.936 | 0.933/30.391 | 333880/255264 |
| whnf / fn-collision / 128 | 1 | 3708.225 | 3189.909 | 1.162 | 3835.341/3504.568 | 3.328/109.949 | 284596/425704 |

All32 generated groups retain validation/decoding and every checking step in the
invoked public operation. The three projection groups regress. Collision128's
observed maximum RSS is higher through DAG despite its lower checking time.
Construction, validation and retaining the source graph have distinct costs.

### Complete generated safe-definition admission

| Shape / declarations per batch | Calls | V1 warm ms | DAG warm ms | V1/DAG | V1/DAG cold ms | V1/DAG construction ms | V1/DAG max RSS KiB |
| --- | ---: | ---: | ---: | ---: | --- | --- | --- |
| chain / 8 | 3 | 124.588 | 160.072 | 0.778 | 63.285/84.583 | 0.176/13.315 | 177932/192296 |
| chain / 32 | 2 | 267.900 | 399.747 | 0.670 | 177.937/251.152 | 0.391/60.041 | 244024/260260 |
| metadata / 8 | 3 | 436.829 | 372.699 | 1.172 | 200.095/163.253 | 0.535/28.869 | 246328/281204 |
| metadata / 32 | 2 | 1095.442 | 997.667 | 1.098 | 633.272/574.628 | 1.242/120.795 | 270492/279384 |
| binder / 8 | 2 | 114.335 | 270.322 | 0.423 | 101.126/193.708 | 0.303/21.677 | 190148/251680 |
| binder / 32 | 1 | 219.048 | 555.452 | 0.394 | 295.958/635.476 | 0.781/87.977 | 261728/276988 |

Binder32 is2.536times slower through the DAG path in this measured batch.
Post-GC retained deltas remain noisy: binder32 means20,120/57,284bytes V1/DAG;
metadata32 means19,232/-861,548bytes. A negative delta is GC noise, not negative
allocation or a memory-saving proof. Independent result assertions are timed
separately. Untimed dispatcher diagnostics confirm selected direct paths;
`direct_dag_admission_path_measured:false` remains explicit in the raw records.
Historical8–16times admission ratios do not describe this source. V1 remains
the default checked provider; these regressions and unresolved full-corpus
outcomes prevent a general V2 deployment-performance claim.

Raw immutable receipts:
- [Native12348435907](https://github.com/dwijayuda/pskernel/actions/runs/39604699608/artifacts/12348435907),
  ZIP SHA256 `b19d1a32bfd425986c1abc0d20d8e216b18142bd4ce873912d0dc3615be94ca5`.
- [Generated12348852755](https://github.com/dwijayuda/pskernel/actions/runs/39604699608/artifacts/12348852755),
  ZIP SHA256 `20909799750b896e510c6cc2e4306cb0e4dbc5cb72576f18b422a38e4423cb9f`.
  Checked JS SHA256 `40a98ef8829d1eb2c3b3d533de8966dde01894b88cc5669a4bce3f661026eaca`.


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
WHNF remains materially slower: at depth8,100 calls,8.170 ms DAG versus4.033 ms V1;
the ratio is0.494. Shared-function depth128 improves to1.896 ms DAG versus11.711 ms V1.
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
379.529 ms DAG versus215.493 ms V1, with maximum observed worker RSS358,896/249,724KiB
(DAG/V1). Metadata32 admission improves from1108.351 ms V1 to565.654 ms DAG, but DAG
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
Function-unique128 construction is2.372/77.321 ms, cold checking1200.420/671.620 ms;
function-collision128 construction is2.383/79.779 ms. These measurements do not
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
0.523–6.737x. For fn-collision depth32, 40 calls take 14.536 ms V1 and 27.806 ms DAG
(official Lean 7.310 ms): a real DAG regression. For fn-shared depth128, ten calls
take 15.811 ms V1 and 2.347 ms DAG (official Lean 0.505 ms). Observed worker peak RSS
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
expensive (0.776 ms V1 / 76.831 ms DAG). V1 remains the production provider/default.
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
274.016 / 280.535 / 3,050.367 / 542.081 ms. These are progress/diagnostic observations,
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
