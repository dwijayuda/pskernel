# M1 completion and qualification — 13 October 2026

M1 is complete for its declared selected-language scope. Full M2, Phase A,
v7 completeness, high-performance parity and compiler semantic-preservation
proofs are not complete.

- Executable: `c00e146bd5c97788a4a6a39221849973aeafda84`.
- [Linux qualification 38388627512](https://github.com/dwijayuda/pskernel/actions/runs/38388627512).
- Official Lean 4.35.0-rc4: `c29b6dda4f7c20e3eeaa717c4e565663c5cfa364`.
- Selected Standard: 292 declarations / 14 classes / 52 ordered instances.
- Native profile: `pscv0-v7-native-bounded/48`; 175 portable / 183 native modules.
- Frozen FNV: `fnv1a64:5949916575031563783`.
- Frozen SHA-256: `sha256:f33d923e45baf8aa5dfa6755819737acabc09daf6d60934eb232133acaad069f`.

## Acceptance evidence

| Required capability | Implementation and qualified evidence |
| --- | --- |
| Checked order and bounds | Nat.leProp recursor and checked zero/successor/transitivity/inversion lemmas; Nat.ble reflection; actual Decidable Nat.decLe/decLt. Runtime Bool never becomes proof without reflection. |
| List indexing | List.get proof worker, optimized single-traversal optional access, bang panic, exact GetElem/GetElem?/LawfulGetElem dictionaries and both laws. Zero, middle, last, empty and oversized indices covered. |
| Array indexing | Checked List-backed logical model, actual size bounds, proof/optional/bang access, lawful exact dictionaries; efficient intrinsic representation remains explicit. Persistent aliases, large indices and Fin adapters covered. |
| Fin adaptation | Bound proof erased and value retained; adapter preserves collection validity. Fin 10 value 1 does not authorize singleton or empty access. Lawfulness transfers only for the exact underlying optional dictionary. |
| Universe closure | Option, constructors, recursors, map/bind, Inhabited/BEq, GetElem? and generic Fin/lawfulness adapters have the required universe parameters. Selected List and Array remain Type 0. Option do fixes one universe, as RC4 does; explicit bind may change it. |
| Proof automation | Actual proof terms from assumptions, normalization, constructors, concrete reflection, successor/zero reasoning and bounded local transitivity. Unsupported arithmetic fails closed; this is not full omega. |
| Dictionary coherence | Explicit high-priority optional instances beat the generic low-priority default. Direct and Fin-adapted LawfulGetElem refuse an intentionally unlawful selected dictionary. Independent RC4 positive/negative cases passed. |
| Erasure boundary | One family-parameter classifier distinguishes type parameters from erased indices; ordinary computational Nat arguments survive. Strict IR has no proof consumption or unknown types. Partial Array conversions and Array elimination passed. |
| Runtime boundary | 250 shared observations on direct JS, strict TS, Rust, V8 Wasm GC and Wasmtime component host. All original 198 observations retained. Four shared panic cases on JS/TS/Rust and V8/Wasmtime core/component execution. |
| Frozen closure and trust | Reviewed FNV/SHA guards passed. Primitive-audit schema /2 retains checked definitions whose runtime is replaced by intrinsics, with exact selected-model entries. Official kernel acceptance and runtime correspondence are separate evidence. |

All source declarations were admitted through the official Lean checker before
erasure. Existing project/linking, readable output, declarations/maps, Rust and
Wasm/component qualification also passed. No pskernel-core or self-hosting was run.

## Model and runtime separation

Array is logically a one-field List structure. The seven old selected Array
primitive axioms now have checked logical definitions. The runtime catalog keeps
public wrappers/dictionaries while the backend intrinsics own efficient storage.
Array.mk/List.toArray use a typed sized builder with prepared List metadata and
one private allocation; no backend hardcodes List tags. Array.toList uses a fold
and checked reverse. Both conversions are linear algorithms; toList's additional
reverse traversal remains explicit.

Primitive signatures, kernel-admitted models, runtime tests and compiler
semantic preservation are different claims. The first three are qualified here.
There is no new proof of runtime or compiler semantic preservation, nor a claim
that the whole selected Standard is axiom-free.

## Measured compiler and runtime boundaries

Artifact directory: `m1-performance/` in the qualification run. Prelude admission
was 7 ms. Compiler samples compare identical Array/proof binder telescopes,
direct index return versus checked lookup, within one compiler process.
Three measurements follow warmup; each compilation phase is retained.

| Declarations | Body | Parse ms | Elaborate ms | Prepare ms | Kernel ms | Erase ms | Emit ms |
| --- | --- | ---: | ---: | ---: | ---: | ---: | ---: |
| 16 | Direct return | 0 | 1 | 0 | 1 | 6 | 6 |
| 16 | Checked lookup | 1 | 2 | 2 | 2 | 7 | 7 |
| 128 | Direct return | 15 | 2 | 6 | 9 | 12 | 11 |
| 128 | Checked lookup | 17 | 13 | 16 | 19 | 23 | 17 |

Runtime setup is excluded. Five measurements follow warmup; matching native
Lean and generated JS workloads check their results. Times below are median
batch microseconds, not per operation. Small native timings amplify ratios;
these runtimes and standard-library implementations differ.

| Operation | Size | Iterations | JS us | Native Lean us |
| --- | ---: | ---: | ---: | ---: |
| listHead | 256 | 128 | 1350.521 | 1.412 |
| listTail | 256 | 16 | 13035.346 | 3.886 |
| arrayHead | 256 | 128 | 1715.310 | 0.511 |
| arrayTail | 256 | 128 | 994.165 | 0.701 |
| fromList | 256 | 8 | 3411.061 | 6.520 |
| toList | 256 | 8 | 8934.458 | 11.087 |
| listHead | 8192 | 128 | 1109.158 | 1.302 |
| listTail | 8192 | 16 | 501430.294 | 248.995 |
| arrayHead | 8192 | 128 | 1544.623 | 0.581 |
| arrayTail | 8192 | 128 | 851.571 | 0.711 |
| fromList | 8192 | 8 | 148183.273 | 300.922 |
| toList | 8192 | 8 | 283752.424 | 429.476 |

Generated JS is roughly 492–3357 times slower in these small batch comparisons.
Array and List-head lookup are roughly size independent; List-tail lookup and
conversions grow with collection size. This is observed scaling, not a formal
complexity theorem. Rust/Wasm have functional qualification, not performance
measurements in this harness.

M5 must reduce shared call/dictionary/closure/allocation costs using profiling
and validated general transformations. Those are candidate cost sources from
source inspection, not a measured attribution. Do not introduce Standard-name
shortcuts or claim high-performance/native Lean parity from M1 acceptance.
No flaky wall-time acceptance threshold replaces correctness.

## Accepted continuation

Finish M1 first (now qualified), then interleave M2 with remaining A, M3 with B,
M4 with C/D and final M5/E qualification. Collect E evidence at every slice;
apply measured M5 improvements when dependencies and measurements justify them.
M2 starts with generator/consumer instance search, snapshot ownership and checked
answer replay, followed by elaboration integration and Phase A deriving/API work.
M2 remains incomplete until its full architecture and acceptance gates pass.
