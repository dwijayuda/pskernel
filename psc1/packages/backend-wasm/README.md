# backend-wasm

GC core Wasm and bounded component emission. Start at [src/Ps/BackendWasm/Lower.lean](src/Ps/BackendWasm/Lower.lean).

- Representation: Checked IR/plan → GC core or component candidate.
- Boundary: Compiler-Wasm is GC; the official independent C++ checker is linear memory.
- Focused guard: [scripts/check-wasm-applied-prefixes.mjs](../../scripts/check-wasm-applied-prefixes.mjs). This guard alone is not release qualification.
- Refusal/resources: preserve explicit fuel, error order, source/body identities,
  and negative cases. See [pass contracts](../../docs/reference/pass-contracts.md).

For a change, locate the responsible operation here, preserve both grammars/shared
semantics, and run the focused guard plus selected source/package gates from
[the contributor guide](../../CONTRIBUTING.md). Source imports/Lake roots and the
[generated map](../../docs/reference/repository-map.md) determine exact dependencies.
Do not infer installed capability or independent admission from this package's presence.
