# Same-runner generated-kernel comparison

Baseline: f9e9b20f92ce2ffa4a666acaf55aa8852949f589.
Candidate: 34126793178021a9cd1bdb37aa6fe17c0fab41c6.

Both immutable generated bundles run with the same Node executable, sequential ABBA source order, fresh processes and empty PATH. Each process has a 60-second deadline and a 2048 MiB V8 old-space limit. This is not a hard RSS cap; measured process RSS includes memory outside old space.

The complete-admission worker includes real independent acceptance/refusal checks. Each timed batch starts a fresh session. The worker's untimed direct-DAG diagnostic is retained and is not included in its admission timer. Whole-process RSS and elapsed time include all setup and diagnostics.

The legacy entry is psKernelV1AdmitDeclaration. The DAG-batch and authentic replay entry is psKernelV1RunDag, which uses the transitional DAG checker with acknowledged whole-operation V1 fallbacks. Names alone do not identify a separate complete V1 or V2 architecture.

## Complete public admission

| Fixture | Representation | Warm ms/batch baseline | Candidate | Baseline / candidate | Cold ms baseline / candidate | Process peak RSS KiB baseline / candidate | Retained heap delta bytes baseline / candidate |
| --- | --- | ---: | ---: | ---: | ---: | ---: | ---: |
| chain 8 | legacy | 46.623 | 28.204 | 1.653 | 65.275 / 55.352 | 174870.000 / 169114.000 | 35008.000 / 30544.000 |
| chain 8 | dag | 63.708 | 44.946 | 1.417 | 94.339 / 71.775 | 192432.000 / 195732.000 | 35388.000 / 30188.000 |
| chain 32 | legacy | 158.264 | 116.201 | 1.362 | 199.901 / 166.553 | 283000.000 / 243142.000 | 9916.000 / 22288.000 |
| chain 32 | dag | 229.263 | 193.883 | 1.182 | 290.992 / 237.837 | 259338.000 / 248218.000 | 15276.000 / 25392.000 |
| metadata 8 | legacy | 155.909 | 141.756 | 1.100 | 215.365 / 203.025 | 252668.000 / 247822.000 | 62632.000 / 59064.000 |
| metadata 8 | dag | 142.323 | 125.865 | 1.131 | 190.893 / 170.085 | 266652.000 / 241088.000 | 34336.000 / 30440.000 |
| metadata 32 | legacy | 621.663 | 577.196 | 1.077 | 735.504 / 700.147 | 279826.000 / 268576.000 | 19120.000 / 29724.000 |
| metadata 32 | dag | 562.625 | 512.450 | 1.098 | 630.578 / 594.703 | 274868.000 / 272798.000 | -860976.000 / -850344.000 |
| binder 8 | legacy | 63.168 | 51.818 | 1.219 | 109.011 / 90.768 | 190128.000 / 174334.000 | 31840.000 / 39920.000 |
| binder 8 | dag | 142.363 | 132.912 | 1.071 | 217.950 / 186.755 | 254224.000 / 225916.000 | 36512.000 / 44552.000 |
| binder 32 | legacy | 224.882 | 203.921 | 1.103 | 314.022 / 271.617 | 259476.000 / 256492.000 | 20232.000 / 20896.000 |
| binder 32 | dag | 591.084 | 522.421 | 1.131 | 671.050 / 627.731 | 274078.000 / 270964.000 | 64340.000 / 45916.000 |

## Four authenticated Arena bodies

The existing header adapter and full replay/metadata-validation protocol are unchanged. The immutable official reference covers all 193 bodies, but this performance subset contains only the four listed identities. A timeout or resource error is incomplete and never enters an accepted/rejected latency ratio.

| Case | Baseline classifications | Candidate classifications | Baseline / candidate elapsed ratio |
| --- | --- | --- | ---: |
| good/perf/repeated-subproblem.ndjson | matched_acceptance, matched_acceptance | matched_acceptance, matched_acceptance | 1.039 |
| good/perf/church-numerals.ndjson | pskernel_resource_exhausted, pskernel_resource_exhausted | pskernel_resource_exhausted, pskernel_resource_exhausted | unavailable |
| good/init-prelude.ndjson | pskernel_timeout, pskernel_timeout | pskernel_timeout, pskernel_timeout | unavailable |
| bad/bugs/proj-of-stuck-prop.ndjson | matched_kernel_rejection, matched_kernel_rejection | matched_kernel_rejection, matched_kernel_rejection | 1.084 |

All individual observations, construction, retained heap after GC, CPU/RSS measurements, exact body hashes, source-file differences, controls, errors and artifact identities are in report.json and the retained logs. Two samples per side are descriptive measurements, without a statistical significance or universal speedup claim. This collection does not establish full V2 replacement, a global soundness proof, canonical-source requalification, or full 193-case conformance.
