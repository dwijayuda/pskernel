# backend-js

JavaScript representation, lowering and emission. Start at [src/Ps/BackendJs/CompilerService.lean](src/Ps/BackendJs/CompilerService.lean).

- Representation: Checked IR/target plan → JavaScript candidate.
- Boundary: Target helpers stay here; no admission/publication authority.
- Focused guard: [scripts/js-statement-tests.mjs](../../scripts/js-statement-tests.mjs). This guard alone is not release qualification.
- Refusal/resources: preserve explicit fuel, error order, source/body identities,
  and negative cases. See [pass contracts](../../docs/reference/pass-contracts.md).

For a change, locate the responsible operation here, preserve both grammars/shared
semantics, and run the focused guard plus selected source/package gates from
[the contributor guide](../../CONTRIBUTING.md). Source imports/Lake roots and the
[generated map](../../docs/reference/repository-map.md) determine exact dependencies.
Do not infer installed capability or independent admission from this package's presence.
