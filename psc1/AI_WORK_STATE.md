# PSC1 isolated Rust self-host checkpoint

Updated 2026-10-23. This is an isolated development branch, not the integrated
qualified release branch. Use connected GitHub tools and Linux Actions only;
fetch fresh HEAD and use expected-HEAD non-force updates. Preserve history.
No merge or npm publication is authorized.

Exact tested source: e9a457c25f2005cabae4ce1d844259b7779ede3f
Exact request: 709562694133433234bf222a1d012a53766607c2
Linux qualification: https://github.com/dwijayuda/pskernel/actions/runs/39900513422
Job: 120240781146

Native all-input cursor, length and both grammar lexer equivalence proofs pass;
320 lexer comparisons and 100001-token cases per grammar pass. Retain existing
visitor/pure-tail equalities, regression/host/process negative tests, DirectJS
functionality and both complete compiler-source grammar audits. The same existing
frontend/elaborator/checked IR/independent official Lean pipeline is used;
there is no handwritten target compiler.

The emitted compiler genuinely executes all ten frozen G1 cases. G2 times out
at 240038 ms under the unchanged 240000 ms deadline. No G2 candidate is admitted;
G3 and fixed-point qualification remain not-run. Repeated clean target build
products are unqualified. Preserve official Lean4.35.0 commit
eb6cafb7290e8bd5f2937522d8d804f58f02bafc, strict original/transformed IR,
semantic/ABI refusals, negatives, job/fuel/heap/stack/wire limits.

Established optimization level1 is restored. Same compiler-input closure and
requests measure five positive G1 workloads at5853ms(level0)/2303ms(level1),
across separate hosted runs including startup. Both full G2 results are censored;
no full-compiler speed ranking. Capture the current optimized late native call
path before choosing a further source/backend change. Retain ownership guards,
safe private linear destruction, shared-tail/drop-order and500000-node tests.

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
