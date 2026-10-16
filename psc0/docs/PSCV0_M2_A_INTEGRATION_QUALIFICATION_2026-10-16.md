# M2+A final integration qualification — accepted 16 October 2026

## Acceptance decision and exact scope

**The selected M2 + Phase A milestone is COMPLETE for `pscv0-v7-native-bounded/73`.** The existing [exit review](PSCV0_M2_A_EXIT_REVIEW_2026-10-16.md) and [roadmap](PSCV0_NATIVE_IMPLEMENTATION_ROADMAP.md) are satisfied by the implementation, research qualification, history-preserving integration, all four exact integration workflows, and the final artifact evidence below. This records the existing selected acceptance boundary; it does not widen or narrow the language profile to obtain completion.

Qualified integration: **`2a7072064974cb0d051a1773a26caf15fc59838b`**, tree `66cbc32bfce861a199d4d9455a03df6dc0bdb8de`, on development `psc0/pscv0-v7-native-lean-v1`. Official Lean **4.35.0**, commit **`eb6cafb7290e8bd5f2937522d8d804f58f02bafc`**. The only approved logical assumptions remain `propext` and `Quot.sound`.

This is not full v7, all Lean extensions, a general compiler semantic-preservation theorem, complete recursive/dependent deriving, C5, self-hosting, an independent kernel, or production-performance acceptance. No M3+B/M4+C-D/M5-E implementation is part of this closure.

## Same-commit qualification receipts

All four required checks were read from GitHub for the exact integration SHA above. Every check completed successfully; success was not inherited from an earlier research run.

| Required gate | Workflow run | Job | Result |
| --- | --- | --- | --- |
| Full native Linux pipeline | [38832366451](https://github.com/dwijayuda/pskernel/actions/runs/38832366451) | 116753779387 | SUCCESS; all 33 reported steps, including setup/cleanup, no skipped step |
| F1 canonical model/constructors | [38832366381](https://github.com/dwijayuda/pskernel/actions/runs/38832366381) | 116753778925 | SUCCESS |
| F2 logical operations | [38832366374](https://github.com/dwijayuda/pskernel/actions/runs/38832366374) | 116753778916 | SUCCESS |
| F3/F4/platform logical replay | [38832366314](https://github.com/dwijayuda/pskernel/actions/runs/38832366314) | 116753778799 | SUCCESS |

The native job completed at **2026-10-16T01:16:49Z / 08:16:49 Jakarta**. Compilation, parser/native checks, independent logical-asset regeneration, checked source and Standard, project emission, GC runtime/component formats, TypeScript and Rust application execution, repeated native Wasmtime embedding/post-return, measurements and artifact upload all passed. The 33-step number includes workflow setup and cleanup; it is not a claim of 33 independent semantic test suites.

A read-only [compact diagnostic38835057984](https://github.com/dwijayuda/pskernel/actions/runs/38835057984), job116762208483, at research `54575d2a7246d907dffb851865f75c7619292548`, extracted the completed integration job's actual logs and artifact data. It printed `RUN 38832366451 HEAD 2a7072064974cb0d051a1773a26caf15fc59838b completed success`. The diagnostic's success is evidence extraction, not an additional or substitute qualification gate. Its only workflow changes were the two default run IDs; permissions, commands, timeout and all qualification gates were unchanged.

## Exact published native artifact

- ID: **12018546813**.
- Name: `pscv0-v7-native-2a7072064974cb0d051a1773a26caf15fc59838b`.
- GitHub artifact digest: **`sha256:6eb7d1fbe2bcb3ee8c95613406f24e4ec7d42d7c1314c9beacd43e8035b67dbe`**.
- Size: **6,734,075 bytes**.
- Created: `2026-10-16T01:16:02Z`; reported expiry: `2026-11-15T01:16:00Z`.
- The artifact was present and unexpired when inspected. Expiry is a hosting retention boundary, not a permanent-download guarantee. The durable receipt preserves its identifiers and observed results.

The diagnostic selected this exact artifact by the run's head SHA and extracted `standard-surface.json` and `m1-performance/comparison.json`. The performance JSON's `sourceSha` is the qualified integration SHA, not the research or diagnostic commit. Earlier research results remain separately identified in the [research qualification](PSCV0_M2_A_RESEARCH_QUALIFICATION_2026-10-16.md).

## Actual integration observations

| Area | Observed result |
| --- | --- |
| Source semantics | PASS 4 checked programs, 92 phase-specific refusals and shared-prelude isolation; separately 8 do refusals, 2 comparison-syntax refusals and 1 opaque definitional-opacity refusal |
| Instance growth | Edges 1/8/32: 2 generators and 3 candidates in each fixture; transitions 7/21/69 |
| Shared search and replay | PASS cycle/diamond/conversion, captured-scope isolation, evidence replay, independent resource limits, mandatory defaults, quiescence and rollback |
| Generalized answers | 6 answers, 1 generalized, 1 freshened, 6 generators |
| Selected deriving and retained source | PASS dictionary/refusal boundaries; ordered binders, references, insertions and scoped resumption |
| Direct JavaScript | PASS **1,069** shared runtime observations |
| TypeScript | PASS **1,069** shared runtime observations |
| Rust | PASS **1,069** shared runtime observations and linked three-module application |
| Explicit target words | PASS **35 probes per 32/64 profile** in ECMAScript, Rust and Wasm qualification, including V8 GC core and Wasmtime component lanes |
| Linked application | PASS `App.compute(7)=18`, entry exports and three-file provenance in the selected JS/TS/Rust pipelines |
| Direct-JS artifacts | PASS **1,239 declaration mappings**, **52 generated-parent origins**, Unicode UTF-16 source boundaries and declaration-consumer preparation |
| GC project | PASS four-module checked execution under V8 and Wasmtime with one entry-only Bool export |
| Native component embedding | PASS shared observations, aggregates, normalization, indirect parameters, repeated calls and post-return cleanup |

The common **1,069** count belongs to JS/TS/Rust; it must not be relabeled as 1,069 identical Wasm exports. GC/core/component/native-host checks have their own inspected shared and ABI cases. Measured instance fixtures are not a global complexity proof. Source retention is not C5 source reconstruction or round-trip correctness. Functional observations do not replace a global backend-preservation theorem.

## Exact selected environment

| Field | Integration artifact value |
| --- | --- |
| Declarations | 3,599 |
| Classes | 39 |
| Ordered ordinary instances | 355 |
| Ordered default instances | 13 |
| Selected deriving | Inhabited, BEq, DecidableEq, Repr, Hashable |
| Approved assumptions | propext; Quot.sound |
| Declaration FNV | `fnv1a64:10704736494700616048` |
| Declaration SHA256 | `sha256:a7a45451faa0d1724642590262bda91d12ff49b6f711abd2f6255f883a5a8b1f` |
| Selected surface-v3 SHA256 | `sha256:117f2692ea15046020e113cd0454c5befa73479ec43e9923cafcbfc1e2031ed8` |

The declaration hashes and separate live-surface hash remain unchanged. The selected audit also covers notation/precedence, parser/deriving/tactic/effect dispatch, class keys, ordinary/default ordering, registered axioms, assumptions, proof prerequisites and actual compiled-interface provenance. A declaration count or digest alone is not the whole environment specification.

## Measured integration performance — limitation retained

The unchanged benchmark completed and output-equality checks passed. It measures native compiler phases and generated-JS collections against native Lean; it **does not measure Rust runtime performance or enforce a production-speed target**. Integration prelude measurement: **5,668 ms**.

| Definitions | Indexed | Parse ms | Prepare ms | Elaborate ms | Kernel ms | Erase ms | Emit ms |
| --- | --- | --- | --- | --- | --- | --- | --- |
| 16 | no | 1 | 2 | 27 | 3 | 58 | 75 |
| 16 | yes | 1 | 4 | 35 | 3 | 60 | 78 |
| 128 | no | 22 | 14 | 31 | 15 | 72 | 88 |
| 128 | yes | 26 | 30 | 88 | 28 | 91 | 100 |

Generated-JS/native-Lean runtime ratios from this integration's artifact, rounded to two decimals:

| Operation | size256 ratio | size8192 ratio |
| --- | --- | --- |
| listHead | 247.09x | 613.75x |
| listTail | 3157.89x | 1428.00x |
| arrayHead | 2258.08x | 2324.17x |
| arrayTail | 1519.17x | 1241.73x |
| fromList | 516.57x | 342.24x |
| toList | 430.28x | 344.85x |

The approximately **247x–3158x** range remains a substantial measured limitation. These workflow-specific microbenchmarks are not universal language-speed ratios. Differences from the earlier research measurements do not establish an optimization improvement or a no-regression result. No timing threshold was raised or removed; this is completion of the existing measurement/output gate, not satisfactory production performance. Measured optimization remains in the existing later roadmap.

## History, corrective changes and maintenance boundary

The integration has both ordered parents: development `e6183db9ddeeb532cdad3c3aae8c3396c99574b9` and research `8cd3b9fe4a29da36f8fde96f1771d0198f356cc9`. Concurrent reference/README/audit/scalar documents and both historical roadmap journals were preserved. The final acceptance commit is a documentation-only child: qualification belongs to the exact integration SHA above, not falsely to an untested new compiler implementation.

Qualified corrections include generic `Subtype Nat` platform-result erasure, WIT percent-escaped identifier handling without relaxing signatures, and Rust intrinsic result typing using the existing instantiated IR signature. Tactic-owned synthesis, independent pinned default-instance checking and source/negative assertions remain intact. Prior failed experiments and historical receipts remain in Git history.

No compiler/proof/test/qualification-gate changes were needed for this final closure. No new logical assumptions, weaker assertions, larger budgets, `pskernel-core`, self-hosting, compiler-source `.ps` migration or C5 execution were introduced. PR109 remains draft/open on `psc0/pscv0-v7-m1-parser-ownership-v1` and must not be merged as part of milestone acceptance. Subsequent work follows M3+B -> M4+C/D -> M5/E only when requested; this acceptance does not declare those milestones complete.
