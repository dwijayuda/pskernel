# M2+A research qualification — completed 16 October 2026

## Exact evidence and scope

Selected profile **pscv0-v7-native-bounded/73**, compiler **71489890970049293e78f33f9f9dc3826a0074b2**, official Lean **4.35.0 / eb6cafb7290e8bd5f2937522d8d804f58f02bafc**. Complete research qualification passed; final milestone acceptance additionally requires exact integration qualification. This is not full v7, all Lean extensions, global compiler preservation or release-performance acceptance.

| Gate | Exact run / job | Result |
| --- | --- | --- |
| Full native pipeline | [38830077352](https://github.com/dwijayuda/pskernel/actions/runs/38830077352) / 116746591841, compiler7148989 | SUCCESS; all33 reported steps, including setup/cleanup; no skipped step. |
| Independent F3/F4/platform | [38830077384](https://github.com/dwijayuda/pskernel/actions/runs/38830077384) / 116746591874, compiler7148989 | SUCCESS |
| Independent F1 canonical model/constructors | [38831491203](https://github.com/dwijayuda/pskernel/actions/runs/38831491203) / 116751050169,8fc8154 | SUCCESS |
| Independent F2 logical operations | [38831491147](https://github.com/dwijayuda/pskernel/actions/runs/38831491147) / 116751050177,8fc8154 | SUCCESS |

8fc8154f43f1cd88923044d6af72be9eb7467b40 has identical executable/proof sources to7148989; its intervening changes are documentation and one branch-filter line in each F1/F2 workflow. Their commands, proof inputs, comparisons, pins and budgets did not change. Final integration must independently run all four workflows at one exact commit.

The read-only cloud diagnostic [38832102110](https://github.com/dwijayuda/pskernel/actions/runs/38832102110), job116752955444, at8cd3b9fe4a29da36f8fde96f1771d0198f356cc9 extracted original native logs and artifact data. Its own success is not qualification. Native artifact **12017362168**, `pscv0-v7-native-71489890970049293e78f33f9f9dc3826a0074b2`, digest **sha256:d56700d7e7164aa234bf561d5a07215f21e543f956a19319a41657475a90862f**.

## Actual functional observations

All compiler/parser/official-kernel/frozen-asset/source/Standard gates passed. Source semantics: **4 checked programs and92 phase-specific refusals**, plus separate typed-do/comparison/opaque boundaries. Selected deriving, source-info containment and once-only scoped resumption, synthetic freshening/rollback/quiescence, ordinary/default instances, transparency and module interfaces passed.

Instance growth at1/8/32 edges retained **2 generators and3 candidates**, with7/21/69 transitions. Generalized replay reported **6 answers,1 generalized,1 freshened,6 generators**. These measured fixtures establish their tested invariants, not a global asymptotic bound or complete Lean elaborator equivalence.

**1,069 shared observations passed independently for direct JavaScript, TypeScript and Rust.** Both32/64 target-word profiles passed **35 probes each** across JS/TS/Rust, V8 GC core and Wasmtime components. Scalar signed/unsigned ABI echoes, WIT signatures, WAT/binary correspondence and explicit no-linear-memory scalar-core checks passed. GC validation also ran the checked4-module entry-only Bool application under V8 and Wasmtime.

The real3-module application passed linked `App.compute(7)=18` and entry/export/provenance checks in JS/TS/Rust. Direct-JS artifacts reported **1,239 declaration mappings and52 generated-parent origins**, Unicode UTF-16 source boundaries and declaration-consumer preparation. Repeated native Wasmtime embedding passed shared observations, aggregates, normalization, indirect parameters, repeated calls and post-return cleanup.

The1069 number is the common JS/TS/Rust observation family; it must not be relabeled as1069 identical Wasm exports. Wasm/component/native-host qualification has its own inspected shared and ABI fixtures.

## Exact selected environment

| Field | Observed value |
| --- | --- |
| Declarations | 3,599 |
| Classes | 39 |
| Ordered ordinary instances | 355 |
| Ordered defaults | 13 |
| Selected deriving | Inhabited, BEq, DecidableEq, Repr, Hashable |
| Approved logical assumptions | propext; Quot.sound |
| Declaration FNV | fnv1a64:10704736494700616048 |
| Declaration SHA256 | sha256:a7a45451faa0d1724642590262bda91d12ff49b6f711abd2f6255f883a5a8b1f |
| Surface-v3 SHA256 | sha256:117f2692ea15046020e113cd0454c5befa73479ec43e9923cafcbfc1e2031ed8 |

F1 canonical-model export SHA256 **aa427f06d0645a1e1a360710103766d1043fbb9875ae10d2a4104545baf6029179**. Constructor export SHA256 **a3b176361dcdc411a1110c4ceb308c6793d01fa0f9a2182a81959a766fe4b9b00d**;317 checked declarations in a347-declaration export closure. F1 artifact12021637160 has digest sha256:f73887dc3d7c9e3b2662051dd53e0165a8bdcce87f07234524f6ef3d005f37d0.

## Measured performance — not a speed-target pass

The unchanged benchmark completed and its output-equality checks passed. It records native compiler phase medians and generated-JS collection timings versus native Lean; it does **not** benchmark Rust runtime performance or enforce a new end-to-end speed target. Prelude measurement was **7,900ms**.

| Definitions | Indexed | Parse ms | Prepare ms | Elaborate ms | Kernel ms | Erase ms | Emit ms |
| --- | --- | --- | --- | --- | --- | --- | --- |
| 16 | no | 1 | 2 | 38 | 3 | 75 | 82 |
| 16 | yes | 0 | 5 | 49 | 4 | 78 | 86 |
| 128 | no | 24 | 26 | 45 | 15 | 99 | 107 |
| 128 | yes | 29 | 52 | 125 | 29 | 131 | 141 |

Reported generated-JS/native-Lean ratios are substantial and remain a limitation, not an optimization success:

| Operation | size256 ratio | size8192 ratio |
| --- | --- | --- |
| listHead | 370.73x | 565.92x |
| listTail | 3412.48x | 1755.41x |
| arrayHead | 2803.00x | 3072.10x |
| arrayTail | 1432.61x | 1223.77x |
| fromList | 593.04x | 457.47x |
| toList | 366.16x | 364.33x |

These are this workflow's measured microbenchmarks, not a universal language-speed comparison. No budgets or thresholds were raised or removed. Measured optimization/performance work remains in the roadmap's existing later milestones; do not describe this selected correctness qualification as production performance, no regression or parity with native Lean.

## Corrections covered and remaining acceptance

WIT signature checking now accepts valid percent-escaped identifiers while preserving exact export/arity/signedness/width requirements. Generic Subtype Nat getNumBits lowering preserves abstract logical width and explicit target profiles. Rust intrinsic emission preserves its instantiated result type via the existing IR signature owner; its first API-misreading attempt failed compilation and the correction is the qualified7148989. No test expectations, source fixtures, logical assumptions or budgets were weakened to obtain green.

Research exits are reconciled in M2_A_EXIT_REVIEW. Preserve all concurrent documentation and both parent histories during integration, retain newer language design separately from selected executable admission, qualify the exact integration commit, then issue the final M2+A receipt. General recursive/dependent deriving, general effects/proof automation, C5, complete-v7 and global backend semantic preservation remain later work.
