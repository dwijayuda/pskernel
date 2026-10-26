# compiler-unified

Four-engine composition root. Start at [src/Ps/CompilerUnified/Service.lean](src/Ps/CompilerUnified/Service.lean).

- Representation: Unified service request → backend-neutral checked candidate response.
- Boundary: Same compiler source across JS/TS/Rust/Wasm; no handwritten alternate compiler.
- Focused guard: [scripts/unified-selfhost-request-tests.mjs](../../scripts/unified-selfhost-request-tests.mjs). This guard alone is not release qualification.
- Refusal/resources: preserve explicit fuel, error order, source/body identities,
  and negative cases. See [pass contracts](../../docs/reference/pass-contracts.md).

For a change, locate the responsible operation here, preserve both grammars/shared
semantics, and run the focused guard plus selected source/package gates from
[the contributor guide](../../CONTRIBUTING.md). Source imports/Lake roots and the
[generated map](../../docs/reference/repository-map.md) determine exact dependencies.
Do not infer installed capability or independent admission from this package's presence.
