# syntax

Shared AST and both source grammars. Start at [src/Ps/Syntax/Ast.lean](src/Ps/Syntax/Ast.lean).

- Representation: Exact source text → shared syntax/tokens; printers and lossless capture.
- Boundary: Foundation only; no backend or host publication.
- Focused guard: [scripts/lossless-source-tests.mjs](../../scripts/lossless-source-tests.mjs). This guard alone is not release qualification.
- Refusal/resources: preserve explicit fuel, error order, source/body identities,
  and negative cases. See [pass contracts](../../docs/reference/pass-contracts.md).

For a change, locate the responsible operation here, preserve both grammars/shared
semantics, and run the focused guard plus selected source/package gates from
[the contributor guide](../../CONTRIBUTING.md). Source imports/Lake roots and the
[generated map](../../docs/reference/repository-map.md) determine exact dependencies.
Do not infer installed capability or independent admission from this package's presence.
