# PSC1 active work state

Updated 2026-10-23. Draft [PR #172](https://github.com/dwijayuda/pskernel/pull/172);
active branch `fix/psc1-closure-normalization-20261021`.
Use connected GitHub tools and Linux Actions only. Fetch fresh HEAD before
expected-HEAD, non-force updates. Preserve history; no merge or npm publication.

## Qualified integrated baseline

Source `5ce2fc74b9f01682832ddc10ec9ef27f26458564`, tested merge
`a61eecf46ded19eedcdefcb320aa33118cd8f2ad`, passes
[normal Linux run 39909569028](https://github.com/dwijayuda/pskernel/actions/runs/39909569028):
all selected jobs, all 47 full-job steps and 37/37 Practical Core criteria.
Benchmark is dependency-skipped. Both grammars, seven targets, four application
categories, typed IO/control/order/collections, strict IR, official admission,
negative tests, minimum Python and installed native package remain qualified.
No PSC1 Lean source differs from the previous qualified 78fe34b8 source.
This integration changes host qualification profiles and refusal supervision;
the later compiler/backend candidates remain isolated.

The frozen authority is [PSC1_PRACTICAL_CORE_V1_CONTRACT.json](docs/PSC1_PRACTICAL_CORE_V1_CONTRACT.json):
14 families and 37 finite criteria. This is scoped qualification, not unrestricted
language completeness or a formal backend preservation theorem. The new native
package is unpublished; tarball SHA256
`7b301ae944841aeda15b846a165e2d540a50846c36b1ded1e9daf07de0e6335b`.
Its native executable still hashes to
`60555378ce40e97d0bba8b4f8689031a98410d317911146cd369a41b75462ee7`.
Full artifact 12483409585 expires 2026-11-06T06:45:00Z. Every previous successful
and failed checkpoint remains in Git and [the canonical receipt](docs/PSC1_RUST_TS_SELFHOST_QUALIFICATION_2026-10-23.json).

## Separate correctness and performance profiles

[The profile contract](docs/PSC1_SELFHOST_QUALIFICATION_PROFILES.md) is implemented.
Default `performance-240s` retains the original 240000 ms request/build limits and
15-minute performance jobs. Opt-in `correctness-1800s` extends only actual
`G2-self` and `G3-self` requests to 1800000 ms each. G1, every corpus request
and target builds retain 240000 ms. The independent official checker retains
120000 ms. Long jobs allow 120 minutes, with a 110-minute execution step and
five seconds of per-request supervisor cleanup. Profile names, limits and
malformed wire are covered by Linux regression tests; nested process sessions
are killed at deadline. Stream/wire caps remain 32 MiB/128 MiB.

| Target / profile | Actual result | Self-request time | Peak RSS KiB |
| --- | --- | --- | --- |
| Rust / correctness-1800s | G1/G2/G3 admitted and executed; exact fixed point passed | G2 692788 ms; G3 660042 ms | 668192 / 668184 |
| Rust / performance-240s | G1 and ten cases passed; G2 deadline failure | 240034 ms | original failure RSS unavailable |
| TypeScript / correctness-1800s | G1 and ten cases passed; G2 deadline failure; G3 not run | 1800240 ms | 2995304 |
| TypeScript / performance-240s | G1 and ten cases passed; G2 deadline failure | 240141 ms | 2747248 |

Rust source `5e0b548e6cb3606ee0d3c129e0a829d830e407e4`, request
`7d8865a08427a28432e427592dfc4263718c9a2f`,
[run 39908529181](https://github.com/dwijayuda/pskernel/actions/runs/39908529181),
job 120265913272, is the qualified isolated self-host source.
Its 92-module closure is
`e43c16b5c7c2d908576dc05ce0d2ac89a60bac1bfd116e486af6550453fbbf5e`.
G1/G2/G3 have identical source, canonical admissions, original/transformed IR,
ten-case observations and executable bytes. Executable SHA256:
`d55a8435a157f021e5a7c073037303429b9787729c963af3842a04b9fb009017`.
Same-run executable equality is observed; separate clean-build reproducibility
is not yet qualified. Correctness qualification does not grant the 240s badge.

TypeScript shared-codec source `29e871eae0df41a2f782a501fc4110b928fafa2e`,
request `b5ba1452196c2a64932310f0bc828beb617650ae`,
[run 39908439190](https://github.com/dwijayuda/pskernel/actions/runs/39908439190),
job 120265634367, reaches only G1. Performance run 39909753534 uses the same
85-module closure, request and compiled executable bytes. Neither run produces
an admitted G2 candidate. Linux audits 39910276762 and 39912095877 independently
verify retained source inventories, requests and target file hashes, without
re-executing compiler semantics. Full timings, memory scopes, errors, source/tool
identities, artifact digests and expiry are in the canonical receipt.
Reported elapsed time includes startup and deadline cleanup; sampled tree RSS
can count shared pages twice and is separate from service maxRSS.

## Current performance correction and next work

Current TS shared-codec profile
[39912539573](https://github.com/dwijayuda/pskernel/actions/runs/39912539573)
samples the final 30 seconds of a bounded 220-second replay of the exact current
G2 workload. It grants no candidate/admission/qualification. Generator/thunk
paths remain prominent under psJsonCharNeedsEscape, escape workers, codec and
constructor lookup. Shared Node samples are 67.4%; flat counts alone are not
phase-cost proof. UTF-8 cache/index hypotheses remain unproven; cache capacity
and policies have not changed.

A small shared-source candidate replaces the escape predicate's lazy Boolean
disjunction with explicit branches. Source
`083f900a60f6df3ad32f2d4e1c4afac2c53cf12a`, request
`ecd53ad3f7ea96e07b53c7ece405b0f97c67dbf1`,
[run 39913434540](https://github.com/dwijayuda/pskernel/actions/runs/39913434540)
passes its all-Char official equality proof, 1114112 native code-point
comparisons, quote regressions and both source audits. Actual target generations
are still running; no new generation qualification is claimed yet.
Do not infer G1/G2/G3 success for this new source from the earlier source.

Preserve the qualified Rust reference while finishing that TS trial, then
optimize measured costs toward 240 seconds. Earlier exact Rust late stack
39906025465 reaches strict transformed IR checking and nominal-arity lookup;
this is a measured call path, not a proved total CPU attribution. Any derived
index must preserve exact lookup, duplicate/first-binding/Array behavior,
strict validation, findings and resource counters.

## Architecture and boundaries

Both targets use the same Ps.Compiler.Service source, frontend, elaborator,
original checked IR, target planning, official Lean 4.35.0 admission
(commit eb6cafb7290e8bd5f2937522d8d804f58f02bafc) and existing emitters.
One native seed is followed by actual generated compilers; native compiler
executables are removed before generated work. No handwritten compiler or
host semantic substitute is introduced.

Keep checked scalar closed planning and generic fallback, Rust String ownership
and safe private linear destruction, all-input cursor/lexer equalities and
TypeScript checked generator annotations/structured output. Shared codec schemas
have all-input equality proofs against retained encoders; fixed keys/tags are
definitionally identical shared values, not unproved literal pre-evaluation.
The old literal proof attempts failed and remain preserved in history.

Use [the roadmap](docs/PSC1_DEVELOPMENT_ROADMAP.md) and
[executable continuation](docs/PSC1_RUST_TS_SELFHOST_CONTINUATION.md).
Promote only coherent validated changes, preserving existing TS annotations and
all seven targets, then run fresh full normal qualification on the integrated
source. Independent PSKernel Expression V2 research does not replace official
Lean admission. DirectJS G1 and its tracked G2 heap defect remain retained.

No changes to semantic fuel, heap/stack policies, source identities, negative
tests, strict IR, unsupported-ABI refusals or independent checking are allowed.
The initial PSC1_SELFHOST_PROFILES_2026-10-23.json is a historical declaration
snapshot; current results live in the canonical qualification receipt.
Update that recognized receipt and active Markdown for evidence-only changes;
freeze passive historical/defect JSON and avoid unchanged full reruns.
