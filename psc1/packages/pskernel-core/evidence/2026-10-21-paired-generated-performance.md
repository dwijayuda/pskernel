# Same-runner generated-kernel comparison

Baseline: f9e9b20f92ce2ffa4a666acaf55aa8852949f589.
Candidate: 5deaf5880c83a76290520fa1176982dab0bf87a5.

Both immutable generated bundles run with the same Node executable, sequential ABBA source order, fresh processes and empty PATH. Each process has a 60-second deadline and a 2048 MiB V8 old-space limit. This is not a hard RSS cap; measured process RSS includes memory outside old space.

The complete-admission worker includes real independent acceptance/refusal checks. Each timed batch starts a fresh session. The worker's untimed direct-DAG diagnostic is retained and is not included in its admission timer. Whole-process RSS and elapsed time include all setup and diagnostics.

The legacy entry is psKernelV1AdmitDeclaration. The DAG-batch and authentic replay entry is psKernelV1RunDag, which uses the transitional DAG checker with acknowledged whole-operation V1 fallbacks. Names alone do not identify a separate complete V1 or V2 architecture.

## Complete public admission

| Fixture | Representation | Warm ms/batch baseline | Candidate | Baseline / candidate | Cold ms baseline / candidate | Process peak RSS KiB baseline / candidate | Retained heap delta bytes baseline / candidate |
| --- | --- | ---: | ---: | ---: | ---: | ---: | ---: |
| chain 8 | legacy | 39.269 | 38.458 | 1.021 | 55.728 / 54.597 | 165972.000 / 165210.000 | 35048.000 / 35056.000 |
| chain 8 | dag | 49.967 | 50.373 | 0.992 | 71.734 / 72.562 | 187992.000 / 185922.000 | 35160.000 / 35128.000 |
| chain 32 | legacy | 125.969 | 137.242 | 0.918 | 165.265 / 162.458 | 244588.000 / 245948.000 | 9932.000 / 9916.000 |
| chain 32 | dag | 191.530 | 194.071 | 0.987 | 234.788 / 237.022 | 287160.000 / 264284.000 | 14828.000 / 16040.000 |
| metadata 8 | legacy | 134.675 | 131.101 | 1.027 | 170.955 / 177.280 | 267688.000 / 250488.000 | 586404.000 / 1110360.000 |
| metadata 8 | dag | 115.412 | 161.458 | 0.715 | 146.841 / 191.060 | 251856.000 / 249206.000 | 34656.000 / 42240.000 |
| metadata 32 | legacy | 526.718 | 532.440 | 0.989 | 613.403 / 616.523 | 285718.000 / 291150.000 | 17020.000 / 19152.000 |
| metadata 32 | dag | 466.784 | 594.628 | 0.785 | 528.978 / 683.325 | 275578.000 / 279440.000 | -862288.000 / 39148.000 |
| binder 8 | legacy | 50.769 | 53.223 | 0.954 | 83.666 / 82.868 | 195506.000 / 193740.000 | 31808.000 / 31712.000 |
| binder 8 | dag | 123.570 | 121.301 | 1.019 | 163.974 / 162.806 | 258370.000 / 251944.000 | 36632.000 / 36384.000 |
| binder 32 | legacy | 193.973 | 195.996 | 0.990 | 266.409 / 258.919 | 255106.000 / 256796.000 | 20032.000 / 20200.000 |
| binder 32 | dag | 490.620 | 503.099 | 0.975 | 568.663 / 573.247 | 272864.000 / 274022.000 | 55716.000 / -386708.000 |

## Four authenticated Arena bodies

The existing header adapter and full replay/metadata-validation protocol are unchanged. The immutable official reference covers all 193 bodies, but this performance subset contains only the four listed identities. A timeout or resource error is incomplete and never enters an accepted/rejected latency ratio.

| Case | Baseline classifications | Candidate classifications | Baseline / candidate elapsed ratio |
| --- | --- | --- | ---: |
| good/perf/repeated-subproblem.ndjson | matched_acceptance, matched_acceptance | matched_acceptance, matched_acceptance | 1.014 |
| good/perf/church-numerals.ndjson | pskernel_resource_exhausted, pskernel_resource_exhausted | pskernel_resource_exhausted, pskernel_resource_exhausted | unavailable |
| good/init-prelude.ndjson | pskernel_timeout, pskernel_timeout | pskernel_timeout, pskernel_timeout | unavailable |
| bad/bugs/proj-of-stuck-prop.ndjson | matched_kernel_rejection, matched_kernel_rejection | matched_kernel_rejection, matched_kernel_rejection | 0.985 |

All individual observations, construction, retained heap after GC, CPU/RSS measurements, exact body hashes, source-file differences, controls, errors and artifact identities are in report.json and the retained logs. Two samples per side are descriptive measurements, without a statistical significance or universal speedup claim. This collection does not establish full V2 replacement, a global soundness proof, canonical-source requalification, or full 193-case conformance.
