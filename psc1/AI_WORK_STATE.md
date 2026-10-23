# PSC1 isolated TypeScript self-host checkpoint

Updated 2026-10-23. This is an isolated development branch, not the integrated
qualified release branch. Use connected GitHub tools and Linux Actions only;
fetch fresh HEAD and use expected-HEAD non-force updates. Preserve history.
No merge or npm publication is authorized.

Exact tested source: 39cc17b3d0bae945df932da9ffccacacfb45d1ca
Exact request: da837f82f580e9f49be9bacb4961d57c9e93021d
Linux qualification: https://github.com/dwijayuda/pskernel/actions/runs/39899843170
Job: 120238644855

Native all-input cursor, length and both grammar lexer equivalence proofs pass;
320 lexer comparisons and 100001-token cases per grammar pass. Retain existing
visitor/pure-tail equalities, regression/host/process negative tests, DirectJS
functionality and both complete compiler-source grammar audits. The same existing
frontend/elaborator/checked IR/independent official Lean pipeline is used;
there is no handwritten target compiler.

The emitted compiler genuinely executes all ten frozen G1 cases. G2 times out
at 240106 ms under the unchanged 240000 ms deadline. No G2 candidate is admitted;
G3 and fixed-point qualification remain not-run. Repeated clean target build
products are unqualified. Preserve official Lean4.35.0 commit
eb6cafb7290e8bd5f2937522d8d804f58f02bafc, strict original/transformed IR,
semantic/ABI refusals, negatives, job/fuel/heap/stack/wire limits.

Current exact late profile39900956833 at67041d9b7d32183c514a032e957ab172b6697925
samples220 seconds/final30 seconds. Hot work includes canonical codec/JSON
encoding, string escaping, text-builder/concat/quote and generator dispatch.
Shared Node samples need inclusive/native-stack interpretation before deciding
an optimization. No response/adoption/admission. Preserve strict TS checking,
checked result annotations, ordinary fuel/error preflight and legacy proofs.

The authoritative integrated checkpoint, roadmap, machine receipt and executable
continuation are on branch fix/psc1-closure-normalization-20261021:
https://github.com/dwijayuda/pskernel/blob/fix/psc1-closure-normalization-20261021/psc1/AI_WORK_STATE.md
https://github.com/dwijayuda/pskernel/blob/fix/psc1-closure-normalization-20261021/psc1/docs/PSC1_RUST_TS_SELFHOST_CONTINUATION.md
Its last full source qualification is78fe34b8 / run39894605462:37/37 finite
Practical Core criteria, all seven targets, both grammars and real applications.
Later source/backend candidates on these isolated branches need coherent
promotion and fresh integrated seven-backend qualification.

Continue actual measured throughput engineering, then independently admit/build/
execute G2/G3 and exact closure/source/admission/original/transformed IR/corpus
fixed points for both targets. Keep DirectJS G1 as reference and its original
G2 heap defect tracked; do not return to DirectJS-first optimization.
This documentation-only commit does not extend the tested-source claim.
