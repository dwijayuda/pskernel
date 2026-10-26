# foundation

Positions, names, lists, text and diagnostics. Start at [src/Ps/Foundation/List.lean](src/Ps/Foundation/List.lean).

- Representation: Portable primitive data → portable helpers.
- Boundary: Remain below semantic and backend layers.
- Focused guard: [scripts/check-semantic-boundaries.mjs](../../scripts/check-semantic-boundaries.mjs). This guard alone is not release qualification.
- Refusal/resources: preserve explicit fuel, error order, source/body identities,
  and negative cases. See [pass contracts](../../docs/reference/pass-contracts.md).

For a change, locate the responsible operation here, preserve both grammars/shared
semantics, and run the focused guard plus selected source/package gates from
[the contributor guide](../../CONTRIBUTING.md). Source imports/Lake roots and the
[generated map](../../docs/reference/repository-map.md) determine exact dependencies.
Do not infer installed capability or independent admission from this package's presence.
