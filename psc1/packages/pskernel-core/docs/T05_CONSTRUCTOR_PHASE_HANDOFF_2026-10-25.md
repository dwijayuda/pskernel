# T05 private constructor phase — 2026-10-25

## Status and exact prerequisite

Constructor parameters, constructor-result analysis and paged model proofs are qualified at042d3a12d902f821c7b0ad8630c18f9d6d8bf639 and integrated. Full run40118532017/attempt1 passed230 native reports and both complete generated routes; artifact audit40118566527/attempt1 authenticated all three archives and returned errors=[].

This next batch adds five private production modules,80 native component/structural proof reports and430 assertions per runtime across the fields, analysis and constructor-loop fixtures. Its full source must pass the expanded310-report native-first workflow and both generated routes before it is qualified. A native/portable diagnostic is only preflight evidence; never reuse the042 qualification for these changed production obligations.

## Production sequence

- API/DagOrdinaryConstructorTypes.lean defines the owning results and ordered field/recursive-field records.
- API/DagOrdinaryRecursiveArgument.lean checks recursive arguments over canonical DAG nodes. It preserves original-versus-reduced occurrence checking, rejects negative occurrences, guards invalid recursor heads in safe contexts, opens only syntactic function binders and preserves the callback owner and predecessor fuel.
- API/DagOrdinaryConstructorFields.lean walks the original syntactic constructor Pi spine. For each field it checks the original domain, requires EnsureSort, enforces universe/Prop restrictions and annotations, opens the field, analyzes recursive function arguments, then restores the field owner while retaining appended nodes and required freshness before substituting the original body. It does not WHNF the outer constructor spine to invent binders.
- API/DagOrdinaryConstructorAnalysis.lean composes one original closed constructor: static mvar/fvar/level guards, fresh independent closed-type checker owner, mandatory EnsureSort, header-owner restoration with only the returned arena, constructor parameters, constructor fields, and original-result validation.

- API/DagOrdinaryConstructorLoop.lean walks constructors in source order using the same raw outer fuel as V1. After a constructor passes DAG analysis, it stages its metadata and original-root declaration reference in a private working environment, resets header locals/freshness/semantic caches for the next constructor, retains appended nodes, and returns ordered shapes only after the complete tail succeeds. Metadata types come from the already checked original-input decoded snapshot, whose prefix relationship with the current owner is an explicit internal precondition.

The closed check is an independent owner fork. Its caches, references, locals and nextFresh are discarded when resuming the header owner, even if closed nextFresh grew. This differs deliberately from recursive-function local-scope exit, where appended arena and required freshness survive. The field and analysis proofs and runtime sentinels cover this distinction.

The analysis helper receives phaseFuel, the predecessor selected by the future outer constructor loop. It adds no outer fuel step. Parameter and field wrappers retain their own existing successor conventions. None/Except failure precedence is preserved at every callback phase.

## Preconditions and trust boundary

These private workers operate on canonical owning DAG arenas and already-established header parameter owners, with matching provisional datatype environment and declaration references supplied by the caller. Native paged layout lemmas state their valid-layout hypotheses explicitly. They do not establish correctness of every untrusted external decoder or a Replay-to-ArenaModel bridge.

Fixture setup creates only provisional target metadata after the retained checked header phase. Synthetic cache/reference sentinels are used only with callback protocol probes, never as evidence of successful independent type checking or public admission.

The field and single-constructor helpers do not install metadata. The constructor loop stages validated constructor metadata and references only in its private result. None of this batch generates or validates recursors, publishes a public admission result, changes the public DAG admission route, or removes the existing safe fallback. Full ordinary-inductive DAG admission remains incomplete.

## Exact proof and runtime inventory

The workflow is .github/workflows/psc1-pskernel-t05-header.yml.

| Native proof component | Reports |
| --- | ---: |
| Retained qualified header, state, scalar, knot, metadata, paged, parameter and result inventory | 230 |
| PsKernelOrdinaryRecursiveArgumentProofs | 24 |
| PsKernelOrdinaryConstructorFieldsProofs | 23 |
| PsKernelOrdinaryConstructorAnalysisProofs | 19 |
| PsKernelExprV2OrdinaryConstructorLoopProofs | 14 |
| Required total | 310 |

Each proof log must list exactly the source-named, ordered, unique declarations. Only the retained standard axioms propext, Classical.choice and Quot.sound are allowed; sorryAx, Lean.ofReduceBool and Lean.trustCompiler are rejected.

Fields runtime:268 assertions = harness1 + fields147 + recursive105 + boundaries8 + recursorGuard7. Twenty-one field rows and fifteen recursive-argument rows cover six fuels0/1/2/3/8/4096 and explicit required outcomes. Positive/negative row counts are16/5 and10/5. The frozen V1 field and recursive workers are the executable reference.

Single-constructor analysis runtime:93 assertions = harness1 + matrix84 + protocol8. Twelve original unopened constructors (six positive and six negative) are compared at six phase fuels against the actual frozen V1 singleton psKernelAddSimpleConstructorsWithFuel(succ phaseFuel), followed by twelve required outcomes. Success comparisons include the original constructor root, decoded field/recursive/index shapes, names, binderInfo, locals, freshness, references and original arena prefix. Protocol probes cover static-before-callback ordering, Check and EnsureSort decline/error paths, mandatory sort, all seven distinct parent/child cache collections, and retention of appended nodes without leaking the independent closed owner.

Constructor-loop runtime:69 assertions = harness1 + matrix56 + protocol12. Eight rows at six raw fuels0/1/2/3/8/4096 compare the real complete loop against frozen V1, then require five successes and three failures. Checks cover exact constructor metadata/cidx order, original roots, parameterized freshness reset, index and recursive-field shapes, earlier-constructor availability in later closed checking, and preserved original inputs after failing or declined tails. Protocol callbacks separately exercise original-snapshot lookup precedence, exact predecessor fuel and discarded child-owner state. Generated mutation controls compare an independently deep-captured original owner and boundary snapshot.

Retained runtime requirements remain native parameters284/results432 and per complete generated route header1992/cache1884/parameters268/results432, plus all retained DAG/prefix/scalar/invalid-recursor controls. Both complete routes must also pass fields268, analysis93 and loop69. Full generated routes are TypeScript-to-JavaScript and canonical .ps reconstruction-to-TypeScript-to-JavaScript, with the existing bounded strict-generation controls retained.

## Source and receipt binding

The expanded workflow copies59 exact source inputs and freezes the original references, including ConstructorAdmission.lean SHA25616cce0a367dfa144a56770f76bcb0605d3a370b360175c4f26583387cf2a1723 (Git blobcd3b659ad1e597b95a4ac7b69a1ebf126cab4a17).

Native receipts form an explicit chain: header172 → constructor230 → fields277 → analysis296 → loop310. Generated receipts form the corresponding header → constructor → fields → analysis → loop chain. Each new receipt authenticates its parent receipt, current source/run/attempt identity, native inventory or exact JSON runtime inventory, harness, log and timing digests. Thirteen detached scripts are recorded. The actual source closure is discovered and archived from imports; do not assume the previous148-module count.

The isolated native-first preflight checks the constructor leaf, whose import closure contains all five new production modules and constructor dependencies. Native preflight435cb30302aa68dc35313138c0189a6de8f64abf/run40136763321/attempt1 passed all80 reports and430 assertions; its portable Loop check is separate diagnostic evidence. The preceding Analysis leaf atc7387bc8715706e71c656c16ca67eae585cac2fe/run40135113480 passed native66/361 and portable PSC2_CHECK1687declarations. Neither diagnostic qualifies the changed work source. The full routes then check the complete SelfHost source; no extra overlapping private-leaf check is added to those routes. All previously qualified bounded checks, complete-source checking, reconstruction, compile paths, negative controls, native limits and generated resource limits are retained.

Do not count a green Actions summary as qualification. Inspect actual native and generated receipts and use the artifact-only audit to authenticate ZIP member CRCs/paths, Git source bytes, proof inventory, actual closure/canonical archives, detached outputs and all receipt/log hashes for the exact source.

## Next implementation

After this constructor phase is qualified, implement generated recursor validation and atomic publication, retaining the staged constructor owner and original boundary identity. Route ordinary admission through the new DAG path only after that complete path and its negative controls qualify. The current private constructor-loop result is not a public admission certificate.

Track separately: A T01F scoped qualified; B broader completion OPEN; C full Arena compatibility FAIL at the historical173/193 strict checkpoint; D performance OPEN. Church exhaustion and Init.Prelude timeout remain unresolved. Keep pinned Lean4.35.0/eb6cafb7290e8bd5f2937522d8d804f58f02bafc, fuel4096, independent checking, Linux Actions only and non-force expected-SHA updates.
