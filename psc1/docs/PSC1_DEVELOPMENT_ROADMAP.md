# PSC1 development roadmap

Updated 2026-10-23. Release authority:
[PSC1_PRACTICAL_CORE_V1_CONTRACT.json](PSC1_PRACTICAL_CORE_V1_CONTRACT.json)
(14 frozen families, 37 criteria, both grammars, seven targets, four application
categories). [AI_WORK_STATE.md](../AI_WORK_STATE.md) owns continuation;
[the machine receipt](PSC1_RUST_TS_SELFHOST_QUALIFICATION_2026-10-23.json) owns
exact tested identities and evidence. Preserve working functionality.

## Explicit longer correctness profile (2026-10-23)

User-authorized separate `correctness-1800s` extends only G2-self/G3-self requests
to 1800000 ms. G1, corpus and build limits stay 240000 ms. Existing performance
workflows and their 240-second failures remain separate and unchanged.
See [profile contract](PSC1_SELFHOST_QUALIFICATION_PROFILES.md).
Longer qualification is pending actual Linux execution. The isolated codec
candidate passes official all-input native proof/regression gates on run
39908086775; actual generated work and full integration remain separate gates.
No G2/G3 or fixed-point success is claimed.

## Qualified finite baseline

HEAD 78fe34b8d08d3f01dcc06ca9592668c958526849, tested merge
9fc3bade30bb0dc2ab4535e17319af52bee62250,
[run 39894605462](https://github.com/dwijayuda/pskernel/actions/runs/39894605462):
all selected jobs, 47 full steps and 37/37 criteria pass. Benchmark is
dependency-skipped. Both grammars, seven mappings, typed IO/control/order/
collections, real applications, ABI/negative boundaries, official admission,
strict IR and scoped installed native package remain qualified and unpublished.
All prior source qualifications and failed experiments remain retained.

## Dependency-ordered remaining queue

| Order | Work | Current evidence | Acceptance |
| --- | --- | --- | --- |
| 1 | Resolve normalized full-workload throughput | Both grammar lexer all-input proofs, 320 comparisons, 100001-token cases and ten G1 cases pass. Rust 2697 / TS 2610 declarations have zero open generics; current G2 timeouts are 240038 / 240106 ms | Inspect current Rust late call path and TS profile 39900956833 (codec/JSON/text builder/generator dispatch); fix measured classes under original limits |
| 2 | Complete independent Rust generations | Ownership, safe private linear destruction, all-input cursor/length/lexer proofs, both grammar audits and level-1 G1 pass; current G2 times out | Independently admit/build/execute G2/G3 and exact closure/source/admission/original/transformed IR/ten-case fixed points |
| 3 | Complete independent TypeScript generations | Strict annotations integrated; isolated structured generator, closed plan and lexer normalization pass G1; current late profile reaches codec/JSON/text operations | Strict/noEmitOnError, same source, actual independent G2/G3 and fixed points; measured late-runtime improvements |
| 4 | Promote coherent validated changes | Main remains fully qualified; later source/backend candidates isolated | Fetch latest HEAD, reconcile concurrent edits, non-force expected-HEAD integration, fresh full seven-backend and application qualification |
| 5 | Reproducible readable target distribution | Exact source/tool/lock and hash-bound artifacts exist; no final binary repeatability claim | Repeated clean target build-product identities, readable output and TS declarations/maps; no npm publication or merge without authorization |

## Architectural direction

Rust leads native performance; TypeScript leads readable npm-compatible
distribution. Both reuse Ps.Compiler.Service and the same existing frontend,
elaborator, checked IR, verification and production emitters. DirectJS remains
a qualified G1 regression/reference; its G2 heap defect/evidence remain preserved
without DirectJS-first optimization. All seven targets remain supported.

The generic route leaves fourteen recursive polymorphic curried workers unchanged.
Source wrapper arity normalization does not change synthesized recursive helpers.
For scalar public interfaces, try the existing checked closed specialization/
worker pipeline before adding generic compiler machinery. Preserve generic,
nominal and callback public API/refusal behavior. If generic fusion becomes
necessary, propagate and instantiate type parameters through companion signatures,
call spines and captured partial applications; do not just remove its guard.

Compare full generated compiler workloads, wall time/RSS, tool build time and
source sizes separately. The same compiler-input closure/request comparison measures five positive Rust
G1 requests at 5853 ms (level 0) versus 2303 ms (level 1), across separate hosted
runs and including startup. Keep established level 1. Both full G2 observations
are deadline-censored; no completed G2 or cross-target full-workload advantage
is established. Diagnostic success, native
proof, G1 and G2/G3/repeated-build qualification are distinct statuses.

Keep the fixed contract; defer optional v1 scope expansion while preserving
working features. Language/compiler/backend work and PSKernel-Core Expression V2
research proceed independently. Official Lean 4.35.0 remains authoritative.

G2/G3 qualification has resumed after Practical Core freeze but stays manual/release.
Tiered static/focused/integration/full Linux CI, dependency-aware selection,
source/dependency caches and request concurrency remain. Preserve strict IR,
independent admission, all negative tests, semantic/resource policies and
unsupported ABI refusals. Avoid rerunning full CI for unchanged source or
repeatedly planning/patching source symptoms of a shared lowering defect.
No force pushes, merges or registry publication.
