# PSC1 development roadmap

Updated 2026-10-23. Release authority:
[PSC1_PRACTICAL_CORE_V1_CONTRACT.json](PSC1_PRACTICAL_CORE_V1_CONTRACT.json)
(14 frozen families, 37 finite criteria, both grammars, seven targets, four
application categories). Preserve working features. [AI_WORK_STATE.md](../AI_WORK_STATE.md)
owns continuation state; [the machine receipt](PSC1_RUST_TS_SELFHOST_QUALIFICATION_2026-10-23.json)
owns exact evidence.

## Verified finite release baseline

Source `d0bef34de7d5d3c495f2a4a73af7eccd892d0d74`, tested merge
`6cc6c55b4785eebf70f27331610f9e949a3a84e5`, passes
[39887884270](https://github.com/dwijayuda/pskernel/actions/runs/39887884270).
All selected jobs, all 47 full steps and readiness 37/37 pass. Both grammars,
all seven mappings, typed IO, control/ordering/collections, real applications,
ABI/negative boundaries, official admission and strict IR remain qualified.
Native package installation is qualified for its scoped platform, unpublished.
This does not imply unrestricted feature completeness or formal backend preservation.

## Dependency-ordered remaining work

| Order | Work | Current evidence | Finite acceptance |
| --- | --- | --- | --- |
| 1 | Resolve post-cursor full-workload blockers | Shared cursor all-input proof, 306 offset/fuel cases, 100000 chars, both grammar audits and G1 pass for both targets; Rust G2 next stack failure at 14116 ms, TS G2 timeout at 240086 ms | Inspect exact next Rust crash path and late TS profile; fix measured classes, preserving all guards and original bounds |
| 2 | Finish Rust native compiler workloads | Ownership/copy corrections, safe private linear destruction and ten G1 cases pass; cursor recursion is normalized; the next full-workload stack path is under diagnosis | Fix measured failure class, independently admit and execute G2/G3, match closure/source/admission/original/transformed IR and all ten observations |
| 3 | Finish TypeScript compiler workloads | Result annotations resolve strict checking; structured generators pass G1 and reduce observed small-request cost; late G2 profile reaches frontend elaboration | Use the measured late runtime profile, retain strict/noEmitOnError and source/legacy proofs; execute independently admitted G2/G3 and fixed points |
| 4 | Promote coherent validated source/backend changes | Later Rust/TS/shared cursor changes are isolated; integrated annotation source is fully qualified | Review exact results, preserve current/concurrent history, integrate without force/merge, pass fresh full seven-backend and real-application qualification |
| 5 | Reproducible readable compiler distribution | Exact source/tool/lock and hash-bound executable artifacts implemented; neither fixed point complete | Record actual source/IR fixed points and repeated clean target build products; account for build-path identities; preserve readable large output and package typing; no publication without authorization |

Use the same compiler source/frontend/elaborator/checked IR and existing emitters
through `Ps.Compiler.Service`. Target facades and file transport contain no
independent handwritten compiler. Rust leads native performance; TypeScript
leads readable npm-compatible distribution. Complete all applicable mappings
before declaring new language features finished.

## Scope and evidence boundaries

Keep one fixed Practical Core contract and dependency-ordered queue. Defer new
optional families beyond v1 without deleting working functionality. Compiler/
backend engineering, language maintenance and PSKernel-Core research proceed
independently; Expression V2 research never replaces official Lean 4.35.0 admission.

The user resumed expensive self-host qualification after v1 freeze. G2/G3 are
manual/release jobs and do not block normal development. DirectJS remains G1
reference/regression; its original G2 heap defect and artifacts are retained,
without returning to DirectJS-first optimization.

Compare actual generated compiler workloads. Rust and TS execute the identical
frozen positive/refusal requests, with wall time/RSS recorded separately from
target compilation. Different candidate sources and runner startup limit
cross-run timing claims; neither completed full G2 at the last terminal checkpoint.
Mechanism benchmarks, diagnostics, source equivalence, G1 execution and full
self-host/reproducibility qualification are distinct statuses.

Tiered static/focused/integration/full Linux CI, dependency-aware selection,
pinned dependency/source caching and request concurrency remain. Avoid duplicate
full runs without changed source or a concrete unresolved concern. Do not
suppress diagnostics, remove negatives, skip independent admission, relax
strict original/transformed IR or raise fuel/heap/stack/time limits.

Every source promotion needs appropriate fresh qualification. Preserve all
previous commits, successful G1 evidence, failed attempts and exact artifact
identities/expiry. No force pushes, PR merges or registry publication.
