# compiler

Semantic compiler API and service preparation. Start at [src/Ps/Compiler/Api.lean](src/Ps/Compiler/Api.lean).

- Representation: Captured source input → prepared Core/admissions/IR candidates.
- Boundary: One frontend/elaborator; external admission/publication stays host-owned.
- Focused guard: [scripts/compiler-m-conformance-tests.mjs](../../scripts/compiler-m-conformance-tests.mjs). This guard alone is not release qualification.
- Refusal/resources: preserve explicit fuel, error order, source/body identities,
  and negative cases. See [pass contracts](../../docs/reference/pass-contracts.md).

For a change, locate the responsible operation here, preserve both grammars/shared
semantics, and run the focused guard plus selected source/package gates from
[the contributor guide](../../CONTRIBUTING.md). Source imports/Lake roots and the
[generated map](../../docs/reference/repository-map.md) determine exact dependencies.
Do not infer installed capability or independent admission from this package's presence.
