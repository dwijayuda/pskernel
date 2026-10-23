# PSC1 active work state

Updated 2026-10-23. Draft [PR #172](https://github.com/dwijayuda/pskernel/pull/172);
active branch `fix/psc1-closure-normalization-20261021`.
Use connected GitHub tools and Linux Actions only. Fetch fresh HEAD before
expected-HEAD non-force updates. Preserve history. No merge or npm publication.

Read [the compact derived result projection](docs/PSC1_SELFHOST_PROFILES_QUALIFICATION_2026-10-23.json)
first. [The canonical receipt](docs/PSC1_RUST_TS_SELFHOST_QUALIFICATION_2026-10-23.json)
retains full source inventories, requests, tools, graphs, cases, jobs and artifacts.
The projection derives from that receipt; it is not a second acceptance authority.

## Qualified integrated baseline

Code `5ce2fc74b9f01682832ddc10ec9ef27f26458564`, tested merge
`a61eecf46ded19eedcdefcb320aa33118cd8f2ad`, passes
[normal Linux run39909569028](https://github.com/dwijayuda/pskernel/actions/runs/39909569028):
all selected jobs, all47 full-job steps and37/37 Practical Core criteria.
Benchmark is dependency-skipped. Both grammars, seven targets, four application
categories, typed IO/control/order/collections, strict IR, official checking,
negatives, minimum Python and installed native package remain qualified.
PSC1 Lean source is unchanged from qualified78fe34b8; only profile/host machinery
has been integrated. Later compiler/backend candidates remain isolated.

The frozen [Practical Core v1 contract](docs/PSC1_PRACTICAL_CORE_V1_CONTRACT.json)
contains14 families and37 finite criteria. This is scoped qualification, not
unrestricted language completeness or a formal backend preservation theorem.
Native package remains unpublished: tarball SHA256
`7b301ae944841aeda15b846a165e2d540a50846c36b1ded1e9daf07de0e6335b`;
native executable `60555378ce40e97d0bba8b4f8689031a98410d317911146cd369a41b75462ee7`.
Full artifact12483409585 expires2026-11-06T06:45:00Z. Previous work and successful/
failed evidence remain in Git and the canonical receipt.

## Implemented and exercised profiles

[Profile contract](docs/PSC1_SELFHOST_QUALIFICATION_PROFILES.md):
default performance-240s retains240000ms requests/builds and15-minute jobs.
Opt-in correctness-1800s changes only actual G2-self/G3-self requests to1800000ms.
G1, all corpus requests and target builds stay240000ms; independent checking stays
120000ms. Long jobs120min/step110min, cleanup5s, streams32MiB/wire128MiB.
Fuel, heap/stack, strict IR, negatives, source identities and ABI refusals remain.
Linux tests cover unknown/out-of-profile limits, malformed-wire refusal, output
caps and cleanup of nested process sessions.

| Target / source / profile | Actual result | Self-request time | Peak RSS KiB |
| --- | --- | --- | --- |
| Rust qualified source /1800s | G1/G2/G3 admitted, built and executed; exact fixed point passed | G2 692788ms; G3 660042ms | 668192 /668184 |
| Rust same compiler source /240s | G1 ten cases passed; G2 deadline failure | 240034ms | original failure RSS unavailable |
| TS shared codec /1800s | G1 ten cases passed; G2 timeout; G3 not run | 1800240ms | 2995304 |
| TS shared codec /240s | G1 ten cases passed; G2 timeout | 240141ms | 2747248 |
| TS direct predicate /1800s | G1 ten cases passed; G2 timeout | 1800199ms | 2878304 |
| TS applied lookups /1800s | G1 ten cases passed; G2 timeout | 1800149ms | 1630836 |
| TS bounded-map experiment /1800s | Runtime differential tests and G1 ten cases passed; G2 timeout | 1800169ms | 1787220 |

Every TS trial is terminal. None produces an admitted G2 candidate, G3 or fixed
point. No240s badge is granted by longer-profile success. Elapsed measurements
include startup/cleanup; sampled tree RSS is separate and may count shared pages.

## Qualified Rust reference

Source `5e0b548e6cb3606ee0d3c129e0a829d830e407e4`, request
`7d8865a08427a28432e427592dfc4263718c9a2f`,
[run39908529181](https://github.com/dwijayuda/pskernel/actions/runs/39908529181),
job120265913272. This isolated source genuinely passes G1/G2/G3 and exact source
closure/source/canonical-admission/original/transformed IR/ten-case fixed points.
G1/G2/G3 executable bytes also match:
`d55a8435a157f021e5a7c073037303429b9787729c963af3842a04b9fb009017`.
Its92-module closure is
`e43c16b5c7c2d908576dc05ce0d2ac89a60bac1bfd116e486af6550453fbbf5e`.
Source correctness and same-run executable equality are established;240s and
independent clean-build repeatability remain unqualified. Preserve the reference.

## TypeScript remaining blocker and preferred continuation

Prefer the proven applied-lookup source, without the unproven-benefit Map:
source `0938c895a9ff007a36df72dc49c836dc7443cef3`, tested request
`10ac556f28782c4efeaa72c168f3969aba68ccca`,
[run39914906360](https://github.com/dwijayuda/pskernel/actions/runs/39914906360).
Workflow/documentation descendant `a10c0162805d0e3e39375d1be55ae38d77ff67d9`
has the same compiler code and keeps the separate240s proof lane. Fork a fresh
experiment from this immutable base; never force-reset the later experiment.

Shared codec schemas retain official all-input equality against old encoders.
The escape predicate has all-Char equality and1114112 native inputs. Constructor/
height lookups have all-list/name/fuel/index/hash equality and first-duplicate/
100001-entry miss checks. Audited specialized IR shows constructor/height list
workers now have two parameters, data/scalar results and no lambda in the body;
the predicate emits as a plain function. These changes reach actual IR/code.

Current saved profile:
[run39918874112](https://github.com/dwijayuda/pskernel/actions/runs/39918874112),
diagnostic source `a5011506a4d1bad2700802f9ef611616fc439ca9`.
It samples the final30s of a220s replay, not the final30s of the1800s request.
StringEqual takes17099/27684 ticks(61.8%),17090 under psStringEqFromWithFuel.
Interpret inlining and actual caller/argument sizes before another change.
The source compares character codes; runtime cache text equality can be inlined
there. Do not assume a primitive replacement is sound without all-input proof.
Profile artifact12485957720 expires2027-01-21T07:36:19Z.

The later two-view Map prototype is preserved on
`perf/psc1-bridge-lookup-workers-20261023`: source
`aae4aac442154bb0c95fedb35f19fdb1552cc271`, request
`9f39ab515a3a0c88979ac7f8902aea731975bbcc`,
[run39920694158](https://github.com/dwijayuda/pskernel/actions/runs/39920694158).
1458 retained/current runtime comparisons pass, with exactly two views and
unchanged eviction, Unicode and invalid raw-position behavior. Its single
synthetic prefix timing is10.215ms old/10.496ms indexed; no advantage is asserted.
The actual compiler still times out. Do not select this extra cache complexity
for promotion without demonstrated benefit. Do not infer full-workload memory
or throughput gains from different-source censored runs.

## Next actions and boundaries

Use [the roadmap](docs/PSC1_DEVELOPMENT_ROADMAP.md) and
[executable continuation](docs/PSC1_RUST_TS_SELFHOST_CONTINUATION.md).
Diagnose the current TS StringEqual call context on the preferred baseline,
then make a dependency-coherent, equivalence-tested change before another
expensive generation run. Do not repeat unchanged1800s attempts or expand
cache/fuel/heap/stack bounds. Rust's measured strict-IR nominal-arity lookup is
a later optimization candidate; preserve first binding, duplicates, Array,
structure/inductive priority, findings and resource counters.

Both targets retain Ps.Compiler.Service, the existing frontend/elaborator,
checked IR, original and transformed validation, existing emitters and official
Lean4.35.0 admission(commit eb6cafb7290e8bd5f2937522d8d804f58f02bafc).
One native seed is followed by generated compilers; native compiler executables
are removed before generated work. No handwritten compiler or host substitute.

Preserve checked scalar closed planning/generic fallback, Rust ownership/private
linear Drop, TS checked generator results/structured output and all-input lexer/
cursor/codec proofs. Promote only coherent validated source changes, retaining
already integrated TS annotations, followed by fresh full seven-backend and
application qualification. Current isolated G1 is not that integration gate.
DirectJS G1 and its tracked G2 heap defect remain; ExpressionV2 research stays
independent of compiler progress and does not replace official checking.

Audits39910276762/39912095877/39917944529/39918849858/39925093205 verify immutable
source inventories, requests, target files and selected IR without new compiler
execution. One evidence-only audit syntax failure is recorded and repaired.
Freeze passive historical/declaration JSON; current compact results derive from
the canonical receipt. Evidence-only checkpoints use static CI; no merge or
package publication is authorized.
