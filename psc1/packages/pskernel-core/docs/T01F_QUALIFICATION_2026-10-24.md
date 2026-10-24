# T01F shared closed-expression cache analysis

**Qualified and integrated at the exact source below; B/D remain OPEN and C remains FAIL.**

## Exact qualified source and integration

The qualification source is `0d9f062846d109c362210d441df5fd407ca2cdd7`,
tree `1a1f6054722ab63824251e45a29f99edc3e0dcbc`. Its parent is the complete
Knot-corrected narrow source `e136c06fb378c7882eaa795366e7a781440588f9`.
The final receipts below were executed at 0d9f, attempt 1; earlier narrow or
rejected-source results are not substitutes for them.

Integration branch `integration/psc1-pskernel-expr-v2-lean435-20261021` was
fast-forwarded from `123c41197950b6761be965fd21c57142ee2b0d1c` to the exact
qualified source `0d9f062846d109c362210d441df5fd407ca2cdd7` using `force: false` and
the freshly observed old head as `expected_sha`. Ancestry was ahead 79 /
behind 0 with that old head as merge base. Fresh API verification at
**2026-10-24 05:43:28 UTC** confirmed both branches at the qualified source
and tree. No untested documentation child was integrated.

This checkpoint records **T01F and scoped A qualification at that exact source**.
**B remains OPEN, C remains FAIL, D remains OPEN, and T05 remains OPEN.**
It is not a complete DAG migration, strict Arena parity, general performance
qualification, or a whole-kernel soundness theorem.

## Implementation and preserved behavior

`Runtime/Acceleration/CacheAnalysis.lean` adds the data-result worker
`psKernelExprClosedCacheAnalysis`. It combines the existing free-variable
eligibility scan with expression hashing for indexed caches. Its universal
specification is:

```lean
psKernelExprClosedCacheAnalysis expr =
  if psKernelExprHasFVar expr then (0, true)
  else (psKernelExprHash expr, false)
```

Four semantic map/pair-set helpers and two inference-cache helpers retain
the old guards and cache operations. The small-cache path still uses the old
operations and promotion limit. Indexed lookups use the same hashes, bucket
depth and full collision comparisons. Ineligible insertions return `none`,
allowing callers to retain their original state. Existing indexed pair entries
retain the original set. Inference-only policy, eligibility short-circuit
order, ownership, scope, checker fuel, depth, errors and publication order are
preserved.

Relative to the requested handoff `c775391e13506208a9c7372bd212102b7e9a49e5`,
production changes are exactly the new module and the seven specified files:
`Reduction/WhnfCore.lean`, `Reduction/Whnf.lean`, `Inference/Core.lean`,
`Inference/Helpers.lean`, `DefEq/BinderSpines.lean`, `DefEq/Quick.lean` and
`DefEq/DeltaStep.lean`, all under `Checker/`.

`Cache.lean`, `CachePolicy.lean`, `Core/Expr.lean`, `ScalarHash.lean`, all eleven
scalar-hash proofs, and production `Checker/Knot.lean` are unchanged from that
handoff. In particular, its unconditional pair lookup was not replaced using
an unproved cache invariant.

## Universal proofs and generated matrix

The seven theorems in `psc1/test/PsKernelClosedCacheAnalysisRegression.lean`
quantify over every expression and arbitrary typed cache records, including
raw caches containing ineligible entries. No well-formed-cache hypothesis is
assumed:

- `analysis_eq`
- `semantic_map_get_eq`
- `semantic_map_insert_eq`
- `semantic_pair_contains_eq`
- `semantic_pair_insert_eq`
- `infer_map_get_eq`
- `infer_map_insert_eq`

All seven passed the final native gate. The complete final proof audit checked
**232 exact, unique, ordered reports across sixteen modules**, matching fresh
Git-authenticated `#print axioms` declarations and permitting only the specified
standard Lean axioms. All sixteen original Knot statements and the 102,675-byte
frozen reference-worker region remain unchanged. Four proof scripts use the
new universal lookup equalities; the native-only proof library is built before
the Knot audit and remains outside the portable production closure.

Both final producers executed the exact **1,884-assertion** matrix: twenty
expressions, both small and indexed representations, raw open entries, actual
hash collisions, and semantic/inference map and pair operations. Its count is
40 analysis assertions, 4 representation assertions, 80 map assertions,
160 inference assertions and 1,600 pair assertions.

The native-first narrow prerequisite ran the new proofs, matrix and strict
bounded generated-body checks before the expensive complete build/runtime.
At the final source, both complete producer bodies were independently inspected:
one worker export, eleven structural recursive sites, no calls to the old
expression-hash/free-variable workers, and no recurry or result wrapper. The
bounded workflow guard executed in the narrow prerequisite; the final full-body
inspection is static artifact inspection, not an additional executed workflow
guard. These checks do not claim that all structural generator or scalar calls
have disappeared.

## Complete final routes

| Route | Exact run, attempt | Required complete result |
| --- | --- | --- |
| Generated integration | [40061694631](https://github.com/dwijayuda/pskernel/actions/runs/40061694631), 1 | Six samples, 1,400 assertions each, strict aggregate 8,400 PASS |
| Canonical PSC1 portability | [40061694623](https://github.com/dwijayuda/pskernel/actions/runs/40061694623), 1 | Six samples, 1,400 assertions each, strict aggregate 8,400 PASS |

Each route includes exactly `""`, `"a"`, `"é"`, `"€"`, `"😀"` and `"Aé€😀"`.
Every shard independently admits the complete 294-request closure from empty,
compares all 377 metadata records, and runs its selected sample, singleton
sequence and original negative controls. Corrupt-definition rejection and the
original malformed-input sentinels remain required.

Each shard executes 1,228 setup/admission/metadata assertions, 170 selected-sample
assertions and two final assertions. Thus **8,400 per route and 16,800 across the
two routes are executed counts, explicitly including repeated prefixes**.
Neither unique-assertion counting nor a partial mixed receipt is substituted.

Both original strict `PSC1_T01F_FULL_STRING_SHARDED_JS: PASS` log records match
their archived qualification JSON. The aggregates reauthenticate producer
bytes, all six raw receipt/log/memory digests, exact source/run/attempt identity,
workflow route, kernel, fixture, harness, orchestrator and provider manifest.
Missing/duplicate samples and source/attempt mixing are rejected.

| Route | Sample | Assertions | Timed process, s | Whole job, s | Peak RSS, KiB | Cap margin, s |
| --- | --- | ---: | ---: | ---: | ---: | ---: |
| Generated | `""` | 1,400 | 294.49 | 323 | 742,740 | 1,177 |
| Generated | `a` | 1,400 | 414.22 | 453 | 815,012 | 1,047 |
| Generated | `é` | 1,400 | 520.68 | 552 | 825,552 | 948 |
| Generated | `€` | 1,400 | 618.51 | 651 | 848,620 | 849 |
| Generated | `😀` | 1,400 | 641.66 | 668 | 939,816 | 832 |
| Generated | `Aé€😀` | 1,400 | 1,251.58 | 1,283 | 1,142,340 | 217 |
| Canonical | `""` | 1,400 | 219.59 | 245 | 900,516 | 1,255 |
| Canonical | `a` | 1,400 | 403.40 | 442 | 851,336 | 1,058 |
| Canonical | `é` | 1,400 | 399.75 | 431 | 758,284 | 1,069 |
| Canonical | `€` | 1,400 | 592.34 | 628 | 851,636 | 872 |
| Canonical | `😀` | 1,400 | 672.28 | 704 | 911,572 | 796 |
| Canonical | `Aé€😀` | 1,400 | 1,000.24 | 1,027 | 1,194,780 | 473 |

The generated mixed process completed in **1,251.58 seconds**, with peak RSS
**1,142,340 KiB**. Its whole job took **1,283 seconds**, leaving **217 seconds**
before the unchanged cap. The canonical mixed process completed in **1,000.24 seconds**, with peak RSS **1,194,780 KiB**; its whole job took **1,027 seconds**, leaving **473 seconds**. These are source- and
attempt-specific observations, not a controlled general speedup result.

The generated primary kernel is 9,986,116 bytes, SHA-256
`7e71b0dbbd62405744454aab66413ccbcd5e797996a9cd68f80a2219c5ebe528`.
The canonical primary kernel is 9,986,123 bytes, SHA-256
`740c85aa160056546342853da81b6b86440081cd4e1ce857c0257be49e245d28`.
Each equals its own packaged provider kernel. Their shared authentic fixture is
2,791,525 bytes, SHA-256
`563d6ef138271a13039764257407ee8b66190bca02c8057489d3b1c45f51e71d`.

The canonical producer independently reconstructs/checks the complete source,
then builds PSC1 -> TypeScript -> JavaScript. All **140 reconstructed source
modules plus the manifest** were read and closure-hashed from the archived
source tar. The closure digest is
`1685d131e4be21e44cb05fb637e9f62debd81890592e1b105c695175ceb265f1`.
Both provider suites passed **24 CLI and eight API cases**, with detached
working directories and empty `PATH`.
The separate full-kernel DirectJS capability remains explicitly **UNSUPPORTED**;
this qualification uses the pinned TypeScript production route.

## Retained gates and separate C/D findings

The current source also passed the native safety controls, all retained
generated semantic/owner/cache controls, and the frozen owner experiment's
**32 ordered workers / 384 complete calls**. Every raw worker stdout receipt
was checked and all eight summary rows were independently recomputed.

[Research run 40061694661](https://github.com/dwijayuda/pskernel/actions/runs/40061694661),
attempt 1, passed all six jobs. All six artifacts and all eight archived files
were inspected, including the 38-module research canonical closure's actual
validation/check/build/smoke log gates and the original ill-typed rejection.

[Full Arena run 40061694705](https://github.com/dwijayuda/pskernel/actions/runs/40061694705),
attempt 1, completed and **FAILED C**. The unchanged official corpus has
122 accepted and 71 rejected cases. Current-source generated results are:

| Classification | Cases |
| --- | ---: |
| Matched acceptance | 105 |
| Matched kernel rejection | 60 |
| Matched metadata rejection | 1 |
| Matched transport rejection | 7 |
| Timeout | 17 |
| Reduction-budget resource exhaustion | 1 |
| Separate unsafe/partial contract-difference agreements | 2 |

This is **173 strict matches out of 193**. The two contract agreements are not
counted as matches. All original bodies, case outcomes and 199 official plus
586 generated artifact files were independently checked. There were zero
observed false-accept/false-reject classifications in this receipt; this does
not establish their global absence. Only after current-source verification was
complete was the unchanged classification vector compared with the separately
recorded rejected ce574 source.

[Profile run 40061694607](https://github.com/dwijayuda/pskernel/actions/runs/40061694607),
attempt 1, completed diagnostic collection. All 58 files, 49 manifest entries,
four copied inputs/raw outcomes and 96,842 V8 ticks were verified. Both profiled
and unprofiled outcomes preserve repeated-subproblem acceptance, Church
resource exhaustion, Init.Prelude timeout at the fixed 60-second diagnostic
limit, and stuck-proposition projection rejection. **D remains OPEN.**

Within this same final kernel, DAG/legacy checker mean ratios across 32 cells
range from 0.150 to 1.352. All six safe-definition admission cells are slower
through DAG, with ratios 1.055 to 2.580. The separate frozen-baseline owner
comparison has warm ratios 0.853 to 1.064 and cold ratios 0.821 to 1.182.
These are different finite comparisons; no source-wide performance or
hard-memory-limit claim follows from them.

## Pins, evidence limits and continuation

Lean 4.35.0 commit `eb6cafb7290e8bd5f2937522d8d804f58f02bafc`, TypeScript 7.0.2,
Node 22, fuel 4096, old-space 2048 MiB, empty `PATH`, max-parallel two and the
25-minute mixed/shard job cap remain unchanged. **Old-space is not a hard RSS
limit.** All builds, Lean/compiler/JavaScript/kernel execution and project tests
ran on GitHub Actions Linux. Local work was source editing and static
source/log/JSON/ZIP/tar/digest inspection.

The native fixture exporter's binary is not archived, so its recorded binary
hash is not independently recomputed from the native ZIP. Its source, actual
fixture and outputs are archived/verified. The research artifact does not
archive its hidden bootstrap manifest; its executed required closure gates are
verified from terminal logs. The profile archive verifies its manifest header
and 140-module list but not all reconstructed source bytes. The full canonical
route separately archives and independently verifies its own complete source
tar and manifest. None of these narrower archive observations are inflated
into unperformed byte checks.

- [2026-10-24-t01f-0d9f0628-canonical-final.json](evidence/2026-10-24-t01f-0d9f0628-canonical-final.json) — 166,321 bytes; SHA-256 `ec2a3538682c62571342366c6158d1e08b7ce346be065ee03c884150df76a328`.

- [2026-10-24-t01f-0d9f0628-canonical-native.json](evidence/2026-10-24-t01f-0d9f0628-canonical-native.json) — 9,092 bytes; SHA-256 `d3426fc5b5e97a60c276316e789386ea2933ed6b33743c69ea99dfa9106d5460`.

- [2026-10-24-t01f-0d9f0628-canonical-producer.json](evidence/2026-10-24-t01f-0d9f0628-canonical-producer.json) — 92,387 bytes; SHA-256 `30b241d8e16fecfb2fe52c9fb00f08d755a884cc8b8d9fd803f9bc1ce4fa7f2c`.

- [2026-10-24-t01f-closed-cache-final-0d9f-generated-producer.json](evidence/2026-10-24-t01f-closed-cache-final-0d9f-generated-producer.json) — 368,796 bytes; SHA-256 `b7c6f79cba83b01c641f934cfd771f12b29836dd4dab9fd0a98f7340af483425`.

- [2026-10-24-t01f-closed-cache-final-0d9f-generated-route.json](evidence/2026-10-24-t01f-closed-cache-final-0d9f-generated-route.json) — 924,883 bytes; SHA-256 `91f3dcaa66d217d1ad6e6ce39756cf7c78a59ff93c5b9f69d97276aad1a9fb1a`.

- [2026-10-24-t01f-closed-cache-final-0d9f-native.json](evidence/2026-10-24-t01f-closed-cache-final-0d9f-native.json) — 212,790 bytes; SHA-256 `7558d9cc2322f195d50756506bf21d93c131e9ee07f220bc71e7f29acc97cfb7`.

- [2026-10-24-t01f-closed-cache-final-0d9f-owner.json](evidence/2026-10-24-t01f-closed-cache-final-0d9f-owner.json) — 632,268 bytes; SHA-256 `366e8de9097d59d31db0bf57952d770393d3f804ca4ca130d041742b334e4387`.

- [2026-10-24-t01f-final-0d9f0628-integration.json](evidence/2026-10-24-t01f-final-0d9f0628-integration.json) — 1,545 bytes; SHA-256 `f6ea3764e0ce8d3d11af9fd5ebb0844bcd1c7e90ce488093034214e91fd4556e`.

- [2026-10-24-t01f-final-0d9f0628-reconciliation.json](evidence/2026-10-24-t01f-final-0d9f0628-reconciliation.json) — 54,404 bytes; SHA-256 `1198951a5c1e6fcd434d3d6bded743fff774739967d951d525b51c37b058478e`.

- [2026-10-24-t01f-final-0d9f0628-requested-scope.json](evidence/2026-10-24-t01f-final-0d9f0628-requested-scope.json) — 6,534 bytes; SHA-256 `673ea101015eb202dba88b9637c4b007fe62523a666749f354d6748ab55871de`.

- [2026-10-24-t01f-final-0d9f0628-retained-arena.json](evidence/2026-10-24-t01f-final-0d9f0628-retained-arena.json) — 632,983 bytes; SHA-256 `36c60bd71c962c27de0636b1fe9fe3b51d0f2ce031f167df92041bdfae5fc65e`.

- [2026-10-24-t01f-final-0d9f0628-retained-profile.json](evidence/2026-10-24-t01f-final-0d9f0628-retained-profile.json) — 117,964 bytes; SHA-256 `782b566350c82f70230a0a1b9495d93b4d1bf354431356cc31474b187495268c`.

- [2026-10-24-t01f-final-0d9f0628-retained-research.json](evidence/2026-10-24-t01f-final-0d9f0628-retained-research.json) — 295,966 bytes; SHA-256 `a95147b3c267eb77df1b56fe8bd6566853b4844906999046daebd86398bdf92d`.

- [2026-10-24-t01f-final-0d9f0628-root-review.json](evidence/2026-10-24-t01f-final-0d9f0628-root-review.json) — 1,274 bytes; SHA-256 `d54c10cd24e7ddc6293c63f848584b9a91a0a3813c9a1bdd2b0ad36de4069254`.

After exact-source integration, continue **T05 ordinary DAG inductive admission**.
The first bounded slice is ID-native uniform-occurrence and header/parameter/
index analysis, preserving guard order, mandatory WHNF, complete callback-returned
owners and the deliberate parameter-owner/index-owner fork. Keep generated IDs
private and retain whole-admission fallback until constructor, recursor type,
rule validation and atomic publication have qualified replacements. Mutual/
nested migration remains T06. No T05 completion is claimed by this T01F record.

The subsequent documentation/evidence checkpoint pauses the five full
work-branch triggers and keeps the saved integration draft synchronized, so
the next implementation batch can start with its native-first narrow gate.
Its trigger-only changes do not acquire the final source's qualification.
