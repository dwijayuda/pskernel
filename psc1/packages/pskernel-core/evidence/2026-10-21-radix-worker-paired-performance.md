# Same-runner generated-kernel comparison

Baseline: f9e9b20f92ce2ffa4a666acaf55aa8852949f589.
Candidate: 384f3395036ba7022e6eea9d3ff77f37aacd62ca.

Both immutable generated bundles run with the same Node executable, sequential ABBA source order, fresh processes and empty PATH. Each process has a 60-second deadline and a 2048 MiB V8 old-space limit. This is not a hard RSS cap; measured process RSS includes memory outside old space.

The complete-admission worker includes real independent acceptance/refusal checks. Each timed batch starts a fresh session. The worker's untimed direct-DAG diagnostic is retained and is not included in its admission timer. Whole-process RSS and elapsed time include all setup and diagnostics.

The legacy entry is psKernelV1AdmitDeclaration. The DAG-batch and authentic replay entry is psKernelV1RunDag, which uses the transitional DAG checker with acknowledged whole-operation V1 fallbacks. Names alone do not identify a separate complete V1 or V2 architecture.

## Complete public admission

| Fixture | Representation | Warm ms/batch baseline | Candidate | Baseline / candidate | Cold ms baseline / candidate | Process peak RSS KiB baseline / candidate | Retained heap delta bytes baseline / candidate |
| --- | --- | ---: | ---: | ---: | ---: | ---: | ---: |
| chain 8 | legacy | 40.731 | 41.485 | 0.982 | 64.906 / 63.975 | 176174.000 / 177100.000 | 35048.000 / 35032.000 |
| chain 8 | dag | 56.577 | 58.434 | 0.968 | 89.435 / 86.508 | 197812.000 / 197140.000 | 35576.000 / 35496.000 |
| chain 32 | legacy | 132.369 | 130.584 | 1.014 | 185.804 / 178.952 | 246424.000 / 243660.000 | 10004.000 / 9928.000 |
| chain 32 | dag | 201.147 | 198.777 | 1.012 | 254.709 / 250.357 | 285500.000 / 261494.000 | 14392.000 / 15640.000 |
| metadata 8 | legacy | 142.709 | 139.183 | 1.025 | 195.278 / 193.085 | 249738.000 / 288110.000 | 1110668.000 / 62628.000 |
| metadata 8 | dag | 131.215 | 161.644 | 0.812 | 164.261 / 212.476 | 246750.000 / 251790.000 | 34320.000 / 41524.000 |
| metadata 32 | legacy | 550.423 | 554.495 | 0.993 | 636.096 / 643.439 | 284018.000 / 278014.000 | 18460.000 / 16416.000 |
| metadata 32 | dag | 506.568 | 621.239 | 0.815 | 553.901 / 702.668 | 273716.000 / 277472.000 | -864552.000 / 38552.000 |
| binder 8 | legacy | 56.724 | 57.695 | 0.983 | 99.147 / 98.082 | 189340.000 / 186368.000 | 31848.000 / 31856.000 |
| binder 8 | dag | 129.126 | 124.989 | 1.033 | 188.292 / 189.416 | 258172.000 / 252972.000 | 36116.000 / 36588.000 |
| binder 32 | legacy | 209.907 | 205.482 | 1.022 | 280.869 / 285.145 | 263394.000 / 262850.000 | 20248.000 / 20224.000 |
| binder 32 | dag | 533.385 | 539.237 | 0.989 | 629.185 / 612.314 | 273668.000 / 272464.000 | 56444.000 / 58340.000 |

## Four authenticated Arena bodies

The existing header adapter and full replay/metadata-validation protocol are unchanged. The immutable official reference covers all 193 bodies, but this performance subset contains only the four listed identities. A timeout or resource error is incomplete and never enters an accepted/rejected latency ratio.

| Case | Baseline classifications | Candidate classifications | Baseline / candidate elapsed ratio |
| --- | --- | --- | ---: |
| good/perf/repeated-subproblem.ndjson | matched_acceptance, matched_acceptance | matched_acceptance, matched_acceptance | 0.990 |
| good/perf/church-numerals.ndjson | pskernel_resource_exhausted, pskernel_resource_exhausted | pskernel_resource_exhausted, pskernel_resource_exhausted | unavailable |
| good/init-prelude.ndjson | pskernel_timeout, pskernel_timeout | pskernel_timeout, pskernel_timeout | unavailable |
| bad/bugs/proj-of-stuck-prop.ndjson | matched_kernel_rejection, matched_kernel_rejection | matched_kernel_rejection, matched_kernel_rejection | 0.974 |

All individual observations, construction, retained heap after GC, CPU/RSS measurements, exact body hashes, source-file differences, controls, errors and artifact identities are in report.json and the retained logs. Two samples per side are descriptive measurements, without a statistical significance or universal speedup claim. This collection does not establish full V2 replacement, a global soundness proof, canonical-source requalification, or full 193-case conformance.
