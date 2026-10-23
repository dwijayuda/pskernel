# PSC1 development roadmap

Updated 2026-10-23. Release authority:
[PSC1_PRACTICAL_CORE_V1_CONTRACT.json](PSC1_PRACTICAL_CORE_V1_CONTRACT.json)
(14 frozen families, 37 criteria, both grammars, seven targets, four application
categories). [AI_WORK_STATE.md](../AI_WORK_STATE.md) owns continuation;
[the machine receipt](PSC1_RUST_TS_SELFHOST_QUALIFICATION_2026-10-23.json) owns
exact tested identities and evidence. Preserve working functionality.

## Qualified finite baseline

HEAD 78fe34b8d08d3f01dcc06ca9592668c958526849, tested merge
9fc3bade30bb0dc2ab4535e17319af52bee62250,
[run 39894605462](https://github.com/dwijayuda/pskernel/actions/runs/39894605462):
all selected jobs, 47 full steps and 37/37 criteria pass. Benchmark is
dependency-skipped. Both grammars, seven mappings, typed IO/control/order/
collections, real applications, ABI/negative boundaries, official admission,
strict IR and scoped installed native package remain qualified and unpublished.
All prior source qualifications and failed experiments remain retained.

## Separate correctness and performance profiles

The user explicitly authorized `correctness-1800s`: only generated G2-self and
G3-self requests may run for 1800000 ms each. The default `performance-240s`
profile, existing 15-minute workflows and their acceptance criteria remain.
G1, all corpus requests and target builds remain 240000 ms; every verification,
semantic fuel, memory/stack, 32 MiB stream and 128 MiB wire policy is preserved.
The separate correctness workflow has a 120-minute job, 110-minute execution
step and per-request supervisor bounds; five extra seconds allow cleanup only.

Actual longer-profile attempts are running, independently:
- Rust source `5e0b548e6cb3606ee0d3c129e0a829d830e407e4`, request
  `7d8865a08427a28432e427592dfc4263718c9a2f`,
  [run 39908529181](https://github.com/dwijayuda/pskernel/actions/runs/39908529181).
- TypeScript source `29e871eae0df41a2f782a501fc4110b928fafa2e`, request
  `b5ba1452196c2a64932310f0bc828beb617650ae`,
  [run 39908439190](https://github.com/dwijayuda/pskernel/actions/runs/39908439190).

These remain isolated compiler candidates; this checkpoint integrates the host
profile machinery, not their unqualified compiler/backend changes. The shared
codec candidate has all-input official equality proof gates against retained
encoders; both longer runs still require actual generated G1/G2/G3, independent
admission and exact fixed points. No success is claimed before terminal evidence.
[Profiles](PSC1_SELFHOST_QUALIFICATION_PROFILES.md) and
[the profile receipt](PSC1_SELFHOST_PROFILES_2026-10-23.json) distinguish
correctness from performance. A long-profile pass does not qualify 240 seconds.

## Dependency-ordered remaining queue

| Order | Work | Current evidence | Acceptance |
| --- | --- | --- | --- |
| 1 | Establish independent longer-profile correctness; retain throughput target | Both grammar lexer all-input proofs, 320 comparisons, 100001-token cases and ten G1 cases pass. Rust 2697 / TS 2610 declarations have zero open generics; current G2 timeouts are 240038 / 240106 ms | Finish actual 1800-second Rust/TS G2/G3 and fixed points; then optimize measured classes toward the separate unchanged 240-second profile |
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
