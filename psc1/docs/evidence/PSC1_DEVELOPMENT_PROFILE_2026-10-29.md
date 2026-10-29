# Installed compilation profile — 2026-10-29

The qualified .7 root is [PR #215](https://github.com/dwijayuda/pskernel/pull/215).
Its [qualification](../PSC1_SEMANTIC_REUSE_QUALIFICATION_2026-10-29.json)
and [verified ZIP](https://github.com/dwijayuda/pskernel/actions/runs/40871621775/artifacts/12895314098)
preserve exact source/package identities. Root SHA256:
ab0e2ce442f52311f9fad0e96cebc759c9848434ad49e8c06c6e2df9a76c9d79.

## Qualified change

Reuse complete equivalent private immutable semantic/emitter inputs. Structural
sharing avoids scanning unchanged compiler data. Both JS/TS engines pass ten
real-application candidate comparisons (shifted origins, body changes, refusal,
recovery); both grammars/engines pass the focused installed suite. Fresh official
independent checking, original/transformed strict IR and target consumers remain.

Controlled same-runner 11-module PracticalCli.Run comment edits: stable warm mean
7213 → 4566 ms (.6 → .7), 36.7% less time. First requests10147/10037 ms show no
material cold gain. All six application compilations independently admit and
execute Unicode JSON/file processing. This does not claim semantic-body speedup
or a universal latency bound.

## Per-request CPU evidence

[40872463641](https://github.com/dwijayuda/pskernel/actions/runs/40872463641)
passes at diagnostic c86ee1a7c9a69507fb1fa407356f26d213655324.
Its [raw CPU/report artifact](https://github.com/dwijayuda/pskernel/actions/runs/40872463641/artifacts/12896666344)
has ZIP SHA256 eb278aa1c1cf488f1ff978a9fd25287e14f292e180a9cb868125d441e57d18c7.
It executes the exact qualified .7 package, with no compiler-source modification,
and separately samples a first request, an actual body edit and a subsequent comment
edit. The body changes the success result to an equivalent explicit Bool conditional;
all three requests independently check and execute the real application.

On that runner, the body edit takes13.69 s: capture 18.5 ms, preparation 3472 ms,
extra adapter original-IR validation 402 ms, generated build pipeline 8085 ms,
of which printing 1657 ms. Independent kernel 191.5 ms. The following comment edit
reuses preparation/printing but still takes8.43 s. Main-thread 2 ms V8 sampling
attributes substantial work to generated runtime dispatch, Text insertion,
JSON escaping and GC. Sampling/instrumentation and runner differences prevent
cross-runner speedup claims. Text already uses balanced chunks; these samples
do not establish quadratic behavior.

## Isolated encoding evidence

[40874362557](https://github.com/dwijayuda/pskernel/actions/runs/40874362557)
passes at 7c1fc21fe9179ff828dc6995e461cd68f2356437.
[Report artifact](https://github.com/dwijayuda/pskernel/actions/runs/40874362557/artifacts/12897527244)
ZIP SHA256 9f717190aab7e463ccb97f037aa022023f5be51b50a40820602b7106dbf8f794.
The unchanged generated pipeline executes first; isolated calls follow with warm
JIT. Their parsed values equal the actual candidate fields. These are overlapping
observations, not additive stage attribution or new qualification.

| Operation | Isolated time |
| --- | ---: |
| Admission request wrapper | 2129.8 ms |
| Its canonical admission-string quote | 2102.1 ms |
| Printed-source quote | 133.2 ms |
| Original IR encode | 425.8 ms |
| Specialized IR encode | 315.3 ms |
| Native stringify of already-decoded original IR | 1.12 ms |
| Native stringify of already-decoded specialized IR | 0.78 ms |

Admissions of 659,387 bytes become an 898,731-byte wrapper. Original IR 155,498 bytes,
specialized IR 129,682 bytes, printed source 141,447 bytes; complete wire 1,340,824 bytes.
Native measurements exclude typed-IR conversion and checking.

[CompilerHost.lean](../../packages/bridge/src/Ps/Bridge/CompilerHost.lean)
quotes the canonical admission string through the shared
[JSON implementation](../../packages/bridge/src/Ps/Bridge/Json.lean).
[Service.lean](../../packages/compiler/src/Ps/Compiler/Service.lean)
always renders that wrapper and both IR values.
Minimal evidence currently avoids retaining dumps; it still constructs this wire
response. Independent checking remains a separate required operation.

## Dependency-ordered continuation

1. Remove the extra warm-build original-IR pass in
   [prepared-engine.mjs](../../host-tools/prepared-engine.mjs) only after confirming
   the generated build entry point performs that same check before transforms.
   Retain the adapter check for check-only requests, every generated transform
   validator, all negatives and fresh independent admission. Preserve exact
   candidate bytes and actual checked publication. This is not implemented yet.
2. Investigate a small serializer callback boundary in the shared Lean source:
   add an admission-wrapper helper and build entry point parameterized by string
   quoting; preserve current public entry points by applying the original
   psJsonQuote. The private pinned host may supply native JSON string quoting
   after exact Unicode/control/boundary parity and roundtrip tests, with the
   generated quoter as conservative fallback. Project/wire data must never supply
   callbacks. All language semantics, IR validation, admissions and emitters remain
   in the existing generated compiler. This is a design candidate, not qualification.
3. Measure actual body/comment applications before adopting that change. Batch
   source changes; generate and check the new compiler cohort, then qualify its
   exact G1/G2/G3/fixed-point identities before advertising that cohort as self-hosted.
   Keep qualified .7/source identities until the new cohort has its own evidence.
4. If still material, profile target planning/IR checks and remaining runtime/text
   work separately. Persistent target consumers and cold startup follow measured
   benefit. Existing independent checking/resource boundaries remain mandatory.

Reproduce through the manual GitHub Actions diagnostic workflows on branch
diagnostic/psc1-request-cpu-20261029. The diagnostic scripts only reuse pinned
qualified package artifacts and perform measurement; they do not publish a new root.
No local build, force push, merge or npm publication is needed.

Continuation prompt:

> Continue from PR #215 and latest HEAD. Verify final CI first. Read this profile
> and AI_WORK_STATE.md. Remove duplicate warm-build original-IR validation while
> retaining the generated pipeline's check, then implement and measure a shared
> native-quote transport boundary with exact byte parity and fail-closed fallback.
> Preserve qualified .7 and all compiler/kernel/backend evidence. Use GitHub/Linux
> CI only, preserve history, and batch qualification at a verified milestone.
