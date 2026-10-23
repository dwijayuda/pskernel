# PSC1 development roadmap

Updated2026-10-23. The frozen [Practical Core v1 contract](PSC1_PRACTICAL_CORE_V1_CONTRACT.json)
owns14 families,37 finite criteria, both grammars, seven targets and four
application categories. [AI_WORK_STATE.md](../AI_WORK_STATE.md) owns continuation.
[Compact results](PSC1_SELFHOST_PROFILES_QUALIFICATION_2026-10-23.json) derive from
[the canonical receipt](PSC1_RUST_TS_SELFHOST_QUALIFICATION_2026-10-23.json).

## Verified state

Integrated5ce2fc74 / mergea61eecf4 / run39909569028 passes all selected jobs,
47 full steps and37/37 criteria; benchmark dependency-skipped. Both grammars,
all7 backends, practical applications, official admission, strict IR, negatives,
minimum Python and unpublished native package remain qualified.

Isolated Rust source5e0b548e/request7d8865a0/run39908529181 genuinely passes
G1/G2/G3 and exact fixed point under correctness-1800s. G2/G3 take692788/660042ms,
maxRSS668192/668184KiB; all three executable hashes match within this pipeline.
The original240s profile remains failed and independent clean repeats unqualified.

Every TS trial passes G1 and ten cases, then times out at1800s. Shared codec,
direct predicate, applied lookup and two-view Map results are separately recorded.
G3/fixed point are not run. The Map passes1458 runtime comparisons and preserves
two views/order but establishes no synthetic or completed-compiler advantage;
it is not selected for promotion. Preserve it as an experiment.

## Dependency-ordered queue

| Order | Work | Evidence | Acceptance |
| --- | --- | --- | --- |
| 1 | Diagnose remaining TS string-comparison cost on preferred applied-lookup baseline | Source0938c895/request10ac556f; proof/native/audit/G1 pass, G2 timeout1800149ms. Saved current profile39918874112 has StringEqual61.8% under psStringEqFromWithFuel | Same-input generated-code/caller/argument-size evidence, then an all-input-equivalent targeted change and actual G2/G3/fixed point under1800s |
| 2 | Optimize toward the unchanged240s target | Rust correctness qualified at about11min/request; TS still blocked | Actual performance-240s G1/G2/G3 with original identity, checking and negative requirements |
| 3 | Promote coherent validated sources | Main integrates host profiles only; later compiler/backend changes stay isolated | Fresh HEAD/non-force updates, preserve TS annotations/all targets, fresh full seven-backend/application qualification |
| 4 | Separate clean-build reproducibility | Rust executable bytes match G1/G2/G3 in one pipeline | Independent clean builds and readable code/TS declarations/maps |
| 5 | Final distribution | Native package and artifacts remain unpublished | Required final qualification and explicit merge/publication authorization |

For TS continue from workflow/docs descendanta10c0162, with compiler code identical
to tested0938c895. Create a fresh experiment branch; do not reset later history.
Do not promote unproven-benefit cache changes or retry unchanged full workloads.

## Mechanisms and limits

All-input proofs preserve codec schemas, the direct escape predicate and fully
applied constructor/height lookup workers. Actual specialized IR confirms the
latter no longer return functions. Source-wrapper fixes that do not change the
actual helper remain insufficient; inspect IR/calls, not source appearance alone.
General lambda floating must preserve effect/trap/evaluation/fuel behavior;
do not simply remove worker guards or replace String equality without proof.

Rust late stack39906025465 reaches strict IR checking and nominal-arity lookup.
Any derived index must prove lookup equality for first binding, duplicates,
Array and structure/inductive priority and preserve report/resource behavior.
Keep existing checked closed planning and generic fallback.

performance-240s retains15-minute jobs/240000ms requests and builds.
correctness-1800s is separate manual/release:120-minute jobs/110-minute step;
only G2-self/G3-self get1800000ms. G1/corpus/builds stay240000ms and independent
checker120000ms. Cleanup5s, streams32MiB, wire128MiB; fuel/heap/stack, strict IR,
negatives, source identities and unsupported ABI refusals stay unchanged.

Use the same compiler/frontend/elaborator/IR/verifier and all7 existing emitters.
Official Lean4.35.0 remains authoritative; no handwritten compiler or native
semantic delegation after the one seed. Preserve qualified G1, DirectJS reference
and its G2 defect. ExpressionV2 research proceeds independently.
Avoid speculative redesign, unchanged full CI and duplicate audits. Passive
history stays frozen; compact evidence is derived, not a new acceptance contract.

## Active measured TS correction

Branch `perf/psc1-ts-utf8-view-tokens-20261023`, code d976ff0b, passes focused Linux39952202237.
Token identities avoid repeated structural equality of cached text while retaining
only the original two views, original eviction, invalid raw offsets and fuel-zero
laziness. Existing source equality and character comparisons remain unchanged.
16000 emitted-runtime comparisons and both85-module source audits pass. G2/G3
and exact fixed point remain pending; the separate240s criterion is unchanged.
Rust qualified reference83e18fe1/source5e0b548e/request7d8865a0 is preserved.

## Current continuation after token-only G2 timeout

The StringEqual path reaches the real compiler with2 lazy tokens and no direct
cache-key comparisons in its equality worker (audits39953924361/39957038006).
Token-only actual G2 still times out1800195ms/3050788KiB (39952593596), and
240202ms/2281004KiB in the preserved short profile39952866650. G3/fixed point
remain unqualified. Bounded profile39953992821 points next to generator/helper
work. Native-invoke and finite-iterator hypotheses remain unadopted diagnostics.

The active branch is `perf/psc1-ts-utf8-size-extract-20261023`: code08b3173e,
focused checkpoint1d4d9cc0/run39959279408. Cold byte-size requests no longer
admit position arrays; extraction uses existing valid UTF8 boundaries and the
exact old fallback for cold/invalid raw offsets. Both85-module source audits,
95576 extraction and16000 equality comparisons plus existing proof/negative
gates pass. Diagnostic real compiler corpus responses match exactly; latency
is10680 vs12589ms across20 fresh-process replays. This does not qualify G2.
Next: genuine fresh-source G1/G2/G3 and fixed point under1800s, then independent
240s performance and coherent full integration. Preserve qualified Rust reference.
