# PSC1 active work state

Updated 2026-10-23. Draft [PR #172](https://github.com/dwijayuda/pskernel/pull/172);
active branch `fix/psc1-closure-normalization-20261021`.
Use connected GitHub tools and Linux Actions only. Fetch latest remote HEAD
before non-force expected-HEAD updates. Preserve history; no merge or npm
publication is authorized.

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
[Profiles](docs/PSC1_SELFHOST_QUALIFICATION_PROFILES.md) and
[the profile receipt](docs/PSC1_SELFHOST_PROFILES_2026-10-23.json) distinguish
correctness from performance. A long-profile pass does not qualify 240 seconds.

## Verified integrated checkpoint

Branch HEAD `78fe34b8d08d3f01dcc06ca9592668c958526849`, tested merge
`9fc3bade30bb0dc2ab4535e17319af52bee62250`, passes
[Linux run 39894605462](https://github.com/dwijayuda/pskernel/actions/runs/39894605462):
every selected job, all 47 full-job steps, and all 37 finite Practical Core
criteria. Benchmark is dependency-skipped. Both grammars, all seven targets,
applications, official admission, strict IR, negatives, host boundaries,
compiler closures, minimum Python and installed native package remain qualified.
This repeats the source qualification at d0bef34d / run 39887884270; that complete
receipt and all previous successful/failed evidence remain preserved.

The frozen authority is [PSC1_PRACTICAL_CORE_V1_CONTRACT.json](docs/PSC1_PRACTICAL_CORE_V1_CONTRACT.json):
14 families, 37 finite criteria, both grammars, seven targets, four application
categories. This is scoped qualification, not unrestricted language completeness
or a formal backend preservation theorem. The native package is unpublished:
tarball SHA256 `30d5333a7311335809eb28be4b130acf0e73b2a1bdd408915a7d4b20ec3bef7b`.
Full artifact 12477371933 expires 2026-11-06T03:56:45Z; digest and all exact
identities/steps are in [the machine receipt](docs/PSC1_RUST_TS_SELFHOST_QUALIFICATION_2026-10-23.json).

## One compiler; independently executing targets

Rust native execution and readable npm-compatible TypeScript lead self-hosting.
`Ps.Compiler.Service` shares the existing source/frontend/elaborator, original
checked IR, target planning, admissions and origins. Thin target facades invoke
existing emitters. There is no handwritten target compiler. A single native seed
is followed by actual emitted compilers; native compiler executables are removed
before generated work. A separate host admits exact canonical graphs with official
Lean 4.35.0 commit `eb6cafb7290e8bd5f2937522d8d804f58f02bafc`.

Both targets genuinely pass the same five positive/five refusal G1 cases across
both grammars. Integrated TypeScript result annotations resolve the strict checker
contextual-inference stall. All 489 PSC1 Lean blobs match its actual G1-tested
a0a0a92f source; the source-tree witness is retained. DirectJS G1 remains the
qualified reference/regression; its original
[G2 heap defect](docs/PSC1_G2_PERFORMANCE_DEFECT_2026-10-21.md) remains open,
without prioritizing DirectJS-specific G2 work.

Neither target has qualified G2/G3, a fixed point or repeated clean target binary
builds. A diagnostic job passing is not a generation pass.

## Measured isolated engineering

Rust ownership changes avoid measured full String copies using scope-aware
last-use and unique tail transfers. Changing arguments evaluate before moves;
capture/duplicate/shadow/error/fuel guards remain. Retained-old/current runtime
comparisons cover Unicode and 100000 steps. Safe iterative Drop applies only to
private regular last-field linear inductives with an empty sentinel. Shared
tails and original destruction order are compared; 500000-node destruction passes.
Public enum pattern ABI is unchanged; no unsafe code, leak or stack increase.

The shared cursor accumulator/reverse correction has an official all-input
fuel/source/raw-offset equality proof, 306 evaluated cases and a 100000-character
case. The explicit lexer-length wrapper also has all-type/list/count equality.
Both branches pass both complete source grammar audits and actual G1 cases.

Exact diagnosis [39896155384](https://github.com/dwijayuda/pskernel/actions/runs/39896155384)
at `f3e9caea62882242a1040ebca51f1ec7f1f9381f` finds the broader class:
14 recursive polymorphic curried helpers survive unchanged in original and
transformed IR. The explicit source length wrapper does not change its synthesized
recursive helper. Closed worker fusion deliberately skips generic declarations.
Do not repeatedly rewrite individual wrappers or simply remove that guard:
generic companion signatures, instantiated capture types and call spines need
coherent treatment.

The next experiment reuses existing strictly checked closed specialization and
worker fusion for nongeneric primitive-only public interfaces, including the
compiler's String -> String interface. Other APIs retain the generic route;
planning refusal falls back to that existing route. Original/post-plan public
API and strict IR checks remain. Native eligibility/specialization/generic-ABI
regressions pass. Both targets use identical shared service/cursor/lexer source.

- Rust branch `fix/psc1-rust-owned-string-moves-20261023`: source
  `734f01ea364c543547eb3755697a651329502a07`, request
  `b7e33cddd169bc5ccc937d6ada0c41a8718cffbb`,
  [run 39898205150](https://github.com/dwijayuda/pskernel/actions/runs/39898205150),
  job 120233440695. The actual compiler has 2691 declarations, zero open generics;
  G1 build and all ten cases pass. G2 fails with stack overflow at 36175 ms.
  Experimental Rust optimization level 0 is recorded, while integrated main
  remains level 1. Its small requests were slower than earlier candidates with different plans;
  the later same-input level-1 comparison below is the controlled profile evidence. Artifact 12478265373, digest
  `1f385e61b5e139f34d925a659f2cad41a3ac076e7b775d70f9c4ce4606a8b40a`,
  expires 2027-01-21T04:02:46Z.
- TypeScript branch `fix/psc1-ts-generator-result-types-20261023`: source
  `eeba9fadcee74bdcd6f98a74db71d81eea03fa56`, request
  `b279eea5d899a7d039f2a7c1cb099e8dbaf52206`,
  [run 39898459655](https://github.com/dwijayuda/pskernel/actions/runs/39898459655),
  job 120234241165. Strict build, all ten G1 cases and zero open generics in 2604 declarations pass; G2 times out at 240162 ms. G3/fixed point are not run. Artifact 12478440283 expires 2027-01-21T04:05:37Z; exact digest is in the machine receipt.

Exact closed Rust replay [39898770508](https://github.com/dwijayuda/pskernel/actions/runs/39898770508), job 120235233000, identifies repeated
psLexAllWorker$worker frames at 37068 ms. It independently confirms that
closed specialization/fusion removed the generic-helper barrier.

The follow-up changes both grammar token-stream workers to accumulate/reverse
while preserving original bounds, errors, spans, token order and exported
wrappers. All-input inputBound/fuel/cursor/accumulator equality proofs against
retained original workers and 320 finite comparisons plus 100001 tokens per
grammar pass before expensive generations. Native tests, old proofs, DirectJS
G1 regressions and both complete grammar audits also pass.

Current source requests are Rust source 64e497ff407f802445d234726fa4ca2ccb4068a0,
request e91e39e44774747650e7a80e12e01887c2b34b42,
run 39899597934/job 120237851825; TypeScript source
39cc17b3d0bae945df932da9ffccacacfb45d1ca, request
da837f82f580e9f49be9bacb4961d57c9e93021d,
run 39899843170/job 120238644855. Both are terminal failures after all ten G1 cases: Rust level 0 G2 times out
at 240041 ms; TypeScript G2 at 240106 ms. No G2 candidate is admitted; G3 and
fixed point are not run.

The same Rust compiler-input closure was then built at established level 1:
source e9a457c25f2005cabae4ce1d844259b7779ede3f, request
709562694133433234bf222a1d012a53766607c2,
[run 39900513422](https://github.com/dwijayuda/pskernel/actions/runs/39900513422),
job 120240781146. All native proofs/regressions, audits and ten G1 cases pass;
G2 times out at 240038 ms. Artifact 12478079568 expires 2027-01-21T04:28:33Z.
The five positive G1 requests total 5853 ms at level 0 and 2303 ms at level 1;
all ten total 6849/3220 ms. Inputs match exactly, runs use separate hosted
machines and wall times include runner startup. Both full G2 observations are
hard-deadline censored; no full-compiler throughput ranking is established.

Current exact TS late profile:
[39900956833](https://github.com/dwijayuda/pskernel/actions/runs/39900956833),
job 120242169870, diagnostic source
67041d9b7d32183c514a032e957ab172b6697925. A 220-second bounded replay analyzes
the final 30 seconds (26766 selected ticks). Hot work includes canonical codec/
JSON encoding, psJsonEscapeStringWithFuel, text-builder/concat/quote operations
and generator dispatch. Shared Node samples are 61.7%; flat counts alone cannot
attribute inclusive phase cost. No candidate response, adoption or admission.
This supersedes the old generic frontend-only profile for choosing TS work.

The isolated TypeScript structured-generator emitter preserves ordinary typed/fuel
preflight and legacy pure output by induction; 264 legacy/current comparisons
remain. It refuses unsafe alias/shadow cases. The exact late profile
39890014989 reaches instantiation, meta/inference, string/name/environment
lookup and generator dispatch. Earlier generic G2 timed out at 240113 ms;
JSON-only early profiles do not explain the whole workload.

These later backend/shared changes remain **isolated, not integrated or normally
qualified on PR #172**. G1/native proofs alone do not justify promotion.

## Ordered execution and boundaries

Use [the roadmap](docs/PSC1_DEVELOPMENT_ROADMAP.md) and
[executable continuation](docs/PSC1_RUST_TS_SELFHOST_CONTINUATION.md).
Fix the actual next closed-workload blocker, then independently admit/build/execute
G2/G3 and exact closure/source/canonical-admission/original-IR/transformed-IR/ten-case
fixed points for each target. Compare actual compiler workloads, not synthetic
tests alone. Then establish repeated clean target build-product identities,
readable code and distribution. Source/IR identity is distinct from native binary
bit equality. Promote coherent validated changes with fresh full seven-backend,
application and regression qualification on the integrated source.

No strictness, unsupported ABI refusals, negatives, semantic/resource policies or
official checking are relaxed. Performance jobs retain 15 minutes and 240000 ms process-tree
deadlines; the explicit correctness profile above extends only G2/G3 requests, with 32 MiB per stream and 128 MiB request/response limits; 245000 ms is
supervisor cleanup only. Failures retain terminal incremental receipts/artifacts.
Expensive generations stay in manual/release workflows. PSKernel Expression V2
research remains independent and does not replace official Lean admission.

Freeze the passive historical/defect JSON snapshots created at 78fe34b8; changing
them conservatively selects policy/full CI. Subsequent evidence updates belong
in the existing recognized machine receipt and these active Markdown documents,
without weakening dependency selection or repeating full CI for unchanged source.
