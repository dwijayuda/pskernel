# PSC1 development roadmap

Updated 2026-10-23. The frozen [Practical Core v1 contract](PSC1_PRACTICAL_CORE_V1_CONTRACT.json)
owns the 14 feature families, 37 finite criteria, both grammars, seven targets and
four application categories. [AI_WORK_STATE.md](../AI_WORK_STATE.md) owns current
continuation; [the canonical receipt](PSC1_RUST_TS_SELFHOST_QUALIFICATION_2026-10-23.json)
owns exact source/tool identities, runs, timings, memory, failures and artifacts.

## Qualified baseline and profile outcomes

Integrated source 5ce2fc74b9f01682832ddc10ec9ef27f26458564, tested merge
a61eecf46ded19eedcdefcb320aa33118cd8f2ad,
[run 39909569028](https://github.com/dwijayuda/pskernel/actions/runs/39909569028):
all selected jobs, 47 full-job steps and 37/37 criteria pass. Benchmark is
dependency-skipped. Both grammars, seven mappings, applications, official
admission, strict IR, negatives and unpublished installed native package remain
qualified. PSC1 Lean source is unchanged from qualified 78fe34b8.

Rust isolated source 5e0b548e6cb3606ee0d3c129e0a829d830e407e4 / request
7d8865a08427a28432e427592dfc4263718c9a2f qualifies actual G1/G2/G3 and the exact
fixed point in [run 39908529181](https://github.com/dwijayuda/pskernel/actions/runs/39908529181).
G2/G3 requests complete in 692788/660042 ms at 668192/668184 KiB maxRSS.
Source/admission/original-IR/transformed-IR/corpus and executable bytes match
across the three generations. Independent clean-build repeats remain distinct.

TypeScript shared-codec source passes G1 and ten cases, then times out at
1800240 ms / 2995304 KiB in run39908439190; G3/fixed point are not run.
Original performance-240s runs still fail G2: Rust240034 ms and TS240141 ms.
A long correctness pass never grants a performance badge.
[Profile policy and commands](PSC1_SELFHOST_QUALIFICATION_PROFILES.md).

## Dependency-ordered remaining queue

| Order | Work | Current evidence | Finite acceptance |
| --- | --- | --- | --- |
| 1 | Finish current TS escape-predicate correction | Source083f900a / requestecd53ad3, run39913434540; all-Char proof, 1114112 native inputs, quote regressions and audits pass; actual generations running | Independently admit/build/execute G2/G3 and exact source/closure/admission/original/transformed IR/ten-case fixed points under correctness-1800s |
| 2 | Optimize both targets toward 240s | Rust correctness qualified but G2/G3 take about11min; TS remains blocked; actual current profiles retained | Actual performance-240s G1/G2/G3 and unchanged fixed-point/negative/identity requirements |
| 3 | Promote coherent validated sources | Main profile/host machinery is qualified; compiler/backend/codec candidates stay isolated | Fetch latest HEAD, reconcile by dependency-coherent files, preserve TS result annotations/all targets, non-force integration and fresh full seven-backend/application qualification |
| 4 | Qualify separate clean-build reproducibility | Rust executable bytes match G1/G2/G3 within one pipeline and pinned tool/lock identities | Repeated clean target builds in independent directories/environments; readable code, TS declarations/maps |
| 5 | Finish practical distribution | Native package and target artifacts remain unpublished | Required final qualification and explicit authorization before any merge or publication |

## Measured engineering direction

Use the same existing Ps.Compiler.Service source, frontend, elaborator, checked
IR, verifier and emitters. Rust leads native execution; TypeScript leads readable
npm-compatible distribution. DirectJS remains the qualified G1 reference; its
tracked G2 heap defect and all previous evidence are retained.

Current TS replay39912539573 covers the final30s of a bounded220s G2 run, not the
end of the 1800s request. It still exposes generator/thunk overhead around the
escape predicate, codec and constructor lookup. The current small correction
replaces lazy Boolean disjunction with explicit branches and retains an official
all-input equality theorem. Measure the actual compiler before declaring a gain.
UTF-8 size/index cache-thrashing and prefix-scanning hypotheses remain unmeasured;
do not expand the two-entry cache or alter raw-offset/Unicode behavior casually.

Rust late stack39906025465 reaches strict transformed-IR checking and nominal
arity lookup. A bounded derived index is a possible measured-class correction,
provided all-input lookup equality preserves first binding, duplicate names,
structure/inductive priority, Array override, misses and report/resource behavior.
Do not skip strict validation or remove generic worker guards. Checked scalar
closed planning already removes open generics from these actual compiler plans.

## Invariants and workstreams

performance-240s retains the existing 15-minute jobs and 240000ms process-tree
deadline. correctness-1800s is a separate manual/release workflow with120-minute
jobs and110-minute execution steps; only G2-self/G3-self receive1800000ms.
G1/corpus/builds remain240000ms, independent checking120000ms, streams32MiB,
wire128MiB and cleanup5s. Fuel, heap/stack, negatives, strict IR, official Lean
4.35.0 admission and unsupported ABI refusals remain unchanged.

Keep all-input lexer/cursor/codec proofs, Rust ownership/private linear Drop,
checked TS generator results and generic ABI fallback. Preserve both grammars
and all seven backend mappings. PSKernel Expression V2 research remains
independent; it cannot block compiler work or replace official Lean admission.

Avoid architectural duplication, unchanged full reruns and repeated audits.
Evidence-only changes belong in the recognized canonical receipt and active
Markdown. Passive historical JSON, including the initial profile-declaration
snapshot, stays historical. No force pushes, merges or registry publication.
