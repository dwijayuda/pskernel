# M3+B execution and performance investigation

16 October 2026. M2+A remains accepted at 2a707206; its documentation receipt is 280e1e4e. The user now authorizes M3+B AND investigating/fixing the measured performance warning. This is not M3 completion.

## Two connected workstreams

1. Implement the existing M3+B exit: indexed/dependent/recursive/nested/mutual data, independently checked elimination motives, structural/well-founded total recursion, broader deriving and cross-backend erasure. Start with shared data/runtime mechanisms, not one-off handlers. Existing Data.lean already builds single-family indexed motives and direct recursive hypotheses; nested recognition is restricted to List/Option/Array/Prod and mutual family construction still needs an inventory. Do not claim these as newly completed.
2. Diagnose the runtime warning before adopting a different compiler. Preserve the original benchmark and its historical receipts. Add a same-runner, dynamic/checksummed study of the already qualified generated code, with longer batches, warmup, absolute times and separate CPU profiles. Then compare a qualified candidate artifact against that exact baseline on the same runner. No speedup claim from separate CI machines or reduced test work.

## Inspected implementation evidence

At accepted source: `test/Pscv0M1Performance.lean` and `scripts/pscv0-native-m1-performance.mjs` perform 8,16,128 calls per sample, one warmup and five samples. The warning is about generated-JS collection operations versus native Lean, not native compiler throughput. It does not measure Rust.

`Ps.BackendEcma.Lower.lower` lowers every general call to `yield* __ps$invoke`; `Runtime.stackRuntime` dispatches with a pending generator stack, WeakMap and Reflect.apply. `declaration` already recognizes count loops and conservative direct/tail bodies, but the latter explicitly excludes declarations with type parameters. Thus small generic helpers and polymorphic recursive workers can pay generator/scheduler overhead. This is a concrete code path, not yet a measured attribution of the entire ratio.

The current tail-purity predicate is separate from intrinsic lowering; any extension must check all callback-bearing intrinsic lowerings, not assume 'not arrayMap' means suspension-free. Preserve call/argument evaluation order, lexical scope, once-only evaluation, failure behavior, generic instantiations and stack safety. Recursive calls changing type arguments cannot simply assign into a fixed typed loop. Higher-order and non-tail recursion retain the trampoline unless a whole mechanism proves otherwise.

## External reference study

- Pinned Lean 4.35.0 eb6cafb7290e8bd5f2937522d8d804f58f02bafc: `src/Lean/Compiler/LCNF/ToLCNF.lean`, including pre-join-point promotion, scoped substitution and argument preservation. Study the corresponding additional source/tests before each substantial implementation.
- TypeScript design goals: https://github.com/microsoft/TypeScript/wiki/TypeScript-Design-Goals . Type erasure, idiomatic JavaScript and no added runtime overhead are useful emission principles; aggressive runtime optimization and introducing a replacement runtime are non-goals. TypeScript's compiler alone cannot remove PSC0's explicit runtime scheduler or safely replace arbitrary-precision Nat with JS Number.
- V8 execution tiers: https://v8.dev/blog/maglev . Tiering means tiny samples after one warmup do not establish steady state.
- V8 measurement: https://v8.dev/blog/real-world-performance . Retain microbenchmarks but add representative workloads before claiming application-level speed.
- Lean runtime: https://lean-lang.org/doc/reference/latest/Run-Time-Code/ and Reference-Counting/ . Optimized primitive representations, specialization and ownership are relevant; no mutation without an ownership argument.

## Current action and acceptance

The read-only cloud workflow `.github/workflows/psc0-m3-performance-study.yml` extracts the exact accepted native artifact, prints relevant generated helpers and runs checked/profiling measurements under pinned Node22.23.3. It does not replace any existing gate or test, change compiler code, or certify M3. It accepts an optional completed successful candidate native run for the same-runner comparison.

Next: inspect results, implement conservative shared generic/direct/tail lowering and focused qualification, then continue data/elimination/termination/deriving owners. Avoid speculative rewrite, wholesale TS adoption, unsafe Number substitution, or mutable persistent arrays. M3+B remains OPEN; production performance remains unqualified until supported by measurements and representative workloads.
