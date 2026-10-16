# M3 runtime slice qualification and same-runner performance

16 October 2026. **The suspension-aware generic ECMA runtime slice is qualified; full M3+B and production performance are not complete.** This receipt supersedes pending-run wording in the original runtime-slice design note without rewriting its historical evidence.

## Exact qualified compiler

Implementation77627e5c plus required portable Lake-root registration produced **133af061d6aaff0eb6ed990abd341ca2a44d15e9**. Native run **38838737641**, job116773647886, completed SUCCESS with all33 reported steps, including setup/cleanup and no skipped stage. Independent F1 **38838737640**, F2 **38838737549**, F3/F4/platform **38838737558** also passed for that compiler. Native artifact **12021280966**, digest `sha256:348ae066891161c8f1a3c9470a546e9b0c48e0b28c991d763f8e5fd368b7dae3`.

The native log reports 1069 shared observations for each JS/TS/Rust, existing source/Standard/module/GC/component/native-Wasmtime checks, focused uniform-tail/alias/type-changing-fallback/callback-suspension/budget/direct-lambda checks, and the checked generic m3Keep fixture with Nat/Bool payloads at100000/50000 steps. No runtime layout, ABI, primitive, logical foundation or test expectation was weakened. This is not full v7.2 conformance.

## Paired comparison

Read-only study **38840337837**, job116778720109, at **cb000664841d3f1ee4738bdf0bd68f390e3fd9e8**, compared the accepted M2 artifact12018546813/compiler2a707206 with candidate artifact12021280966/compiler133af061 on the **same runner and Node22.23.3 process**. Dynamic checksums, eight warmup batches, seven alternated samples, shared adaptive batch counts and separately collected profiler samples were used. Original short benchmark operations/counts/expectations were retained unchanged in native CI.

Study artifact **12021226623** contains30 files/85973bytes, digest `sha256:c4827e325f8d2265832ecd1d579ca91a2ba2a55ecb45229ebdc81ab653a20ec4`. Unlike the first baseline-only study38837301337, publication succeeded. The initial hidden-directory upload had skipped its files; that older study has logs, not a published artifact.

Times below are median **microseconds per call**, rounded from the study's nanoseconds-per-call values. Speedup is baseline/candidate, so values below1 mean slower in this run. These are measured workloads, not a universal language-speed ratio or statistical confidence interval.

| Size | Operation | Baseline us/call | Candidate us/call | Speedup |
| --- | --- | ---: | ---: | ---: |
| 256 | listHead | 16.047 | 9.803 | 1.64x |
| 256 | listTail | 1164.484 | 1216.415 | 0.96x |
| 256 | arrayHead | 17.080 | 10.798 | 1.58x |
| 256 | arrayTail | 12.466 | 9.980 | 1.25x |
| 256 | fromList | 827.293 | 81.867 | 10.11x |
| 256 | toList | 907.076 | 891.087 | 1.02x |
| 8192 | listHead | 13.113 | 11.723 | 1.12x |
| 8192 | listTail | 44963.331 | 45935.054 | 0.98x |
| 8192 | arrayHead | 16.981 | 8.805 | 1.93x |
| 8192 | arrayTail | 14.306 | 10.536 | 1.36x |
| 8192 | fromList | 26960.191 | 2915.434 | 9.25x |
| 8192 | toList | 33408.333 | 33599.775 | 0.99x |

Generated support closure changed from285437 to258986 characters, and1135 to552 generator functions; scheduler-helper occurrences remain608. These counts cover generated support, not just user functions. Same-runner results establish a substantial fromList improvement and smaller indexing-head/array improvements, **not a general deep-list or reversal improvement**. Deep list lookup and toList remain expensive; do not claim the warning is solved or a no-regression/performance-parity result.

## Remaining root-cause work

Actual generated indexing still constructs/selects dictionaries and curried closures around GetElem, OfNat and Option. The deep listGetWorker and reverseAux paths remain suspended; inspect their actual typed IR and closure/recursion shape before extending optimization. Next candidates are scoped beta/eta normalization, exact dictionary specialization and safe direct-call analysis, not arbitrary source-name fast paths. Preserve argument order, once-only evaluation, generic instantiation, error behavior and stack safety.

TypeScript's emitter is useful for idiomatic JS/type erasure, not a mechanism that removes PSC0's explicitly emitted scheduler. Keep exact Nat/Int semantics; do not switch to JS Number or mutate persistent arrays without a proved representation/ownership argument. Broader application workloads and Rust/GC-specific measurements remain necessary before production-performance acceptance. v7.2 migration preserves this evidence and continues M3+B rather than restarting the benchmark or compiler architecture.
