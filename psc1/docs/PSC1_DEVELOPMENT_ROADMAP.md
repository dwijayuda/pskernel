# PSC1 development roadmap

Updated2026-10-23. [AI_WORK_STATE](../AI_WORK_STATE.md) owns continuation.
The frozen [Practical Core v1 contract](PSC1_PRACTICAL_CORE_V1_CONTRACT.json)
owns14 families/37 finite criteria. [Current compact evidence](PSC1_SELFHOST_PROFILES_QUALIFICATION_2026-10-23.json)
derives from the [canonical CI receipt](PSC1_RUST_TS_SELFHOST_QUALIFICATION_2026-10-23.json).

## Qualified state

Main code5ce2fc74 / mergea61eecf4 / normal39909569028 passes all selected jobs,
47 full steps,37/37 criteria, both grammars, seven backends, four application
categories, official checking, strict IR, negative and installed native package
tests. Main Lean source is unchanged from78fe34b8. Later source remains isolated.

Rust source5e0b548e/request7d8865a0/run39908529181 qualifies G1/G2/G3 and exact
fixed point under1800s:692788/660042ms, RSS668192/668184KiB. Same-run executable
hashes match;240s and independent clean-build repeatability remain unqualified.
The qualified branch stays untouched at83e18fe1.

TypeScript remains G1-only at every completed trial. Token and cursor changes
pass runtime/negative/source gates and reach actual G1, then exceed both240s and
1800s. Current applied-erasure worker long run39964278626 is active; its separate
240s run39965349252 times out240170ms after G1/ten cases. No G3/fixed-point claim.

## Dependency-ordered queue

| Order | Work | Actual evidence | Acceptance |
| --- | --- | --- | --- |
|1|Complete current TS correctness and diagnose late cost|Branch perf/psc1-erasure-applied-workers-20261023; sourceba0d5f29/requestd2bc51fc/run39964278626; native proof run39963603961 passes8 all-input equalities, both85-module source audits and existing gates|Actual emitted G2/G3 independently admitted, built/executed, exact source/closure/admission/original/target IR/ten-case fixed points under1800s|
|2|Reach the original performance target|Independent240s tests remain failed for both targets|Actual performance-240s G1/G2/G3 with unchanged source/checking/negative/resource requirements|
|3|Integrate coherent verified source|Current compiler/backend changes remain isolated|Fresh HEAD/non-force updates, preserve Rust ownership/Drop and TS typed/generic guards, fresh full seven-backend/application qualification|
|4|Clean-build reproducibility and distribution readiness|Rust same-run executable equality; deterministic TS G1 source/executable records|Independent clean builds, readable generated code/declarations/maps, no inference from same-run equality|
|5|Final distribution|Native packages/artifacts remain unpublished|Required final qualification plus explicit merge/publication authorization|

Do not refork the obsolete applied-lookup/Map checkpoint or repeat unchanged
1800s attempts. Read the active run's terminal state first. A pinned1750s actual
G2 diagnostic replay is requested to locate the near-deadline bottleneck; its
output is unadopted and does not supply missing admission or qualification.

## Implemented mechanisms and evidence boundaries

Lazy symbol tokens avoid repeated string-key comparisons while retaining only
the two existing UTF8 views. Cold size requests count bytes without admitting
position arrays. Cached valid-boundary extraction uses slicing; cold/invalid
offsets preserve the original scan. Native run39959279408 passes16000 equality
and95576 extraction comparisons, independent size and extract-only runtime checks.

Current erasure source adds fully applied workers for eight classification and
lookup functions, preserving public types and default fuel. Official Lean proofs
against retained originals cover all inputs; first duplicate, exhaustion and
100001-entry hit/miss cases pass. Actual source and saturated IR workers return
data with zero body lambdas; function-valued partial-application variants remain.

Profiles are bounded windows, not completed-compiler timings. Old StringEqual
61.8% no longer dominates. Cursor profile39961304634 exposes eager erasure weak
map insertion; applied-worker profile39966590664 shows that spike removed in
its220s window. Do not sum nested percentages or infer total speed from these
changed-source samples. Native-invoke/iterator experiments remain unadopted.

Keep source/frontend/elaborator/checked IR/verifier and all7 emitters. No handwritten
compiler or native semantic substitute. Preserve all-input lexer/cursor/codec/
predicate/lookup proofs, scalar closed planning with generic/public ABI fallback,
Rust ownership/private safe Drop and TS result annotations/structured generators.

Performance default240s/15-minute jobs; correctness only G2/G3 extends to1800s,
120-minute jobs/110-minute execution step. G1/corpus/builds240s, checker120s,
cleanup5s, streams32MiB/wire128MiB, semantic fuel/heap/stack and strict validation
remain. Official Lean4.35.0 eb6cafb7290e8bd5f2937522d8d804f58f02bafc remains the
admission authority. DirectJS G1/heap evidence is preserved; ExpressionV2 research
is independent. Frozen contract and passive historical evidence stay unchanged.
