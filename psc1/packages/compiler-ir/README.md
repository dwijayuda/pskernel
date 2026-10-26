# compiler-ir

Executable IR, validation and transformations. Start at [src/Ps/CompilerIr/Validate.lean](src/Ps/CompilerIr/Validate.lean).

- Representation: Original/transformed IR → strict verdict.
- Boundary: Data wrappers are not certificates; validate both stages.
- Focused guard: [scripts/check-ir-neutrality.mjs](../../scripts/check-ir-neutrality.mjs). This guard alone is not release qualification.
- Refusal/resources: preserve explicit fuel, error order, source/body identities,
  and negative cases. See [pass contracts](../../docs/reference/pass-contracts.md).

For a change, locate the responsible operation here, preserve both grammars/shared
semantics, and run the focused guard plus selected source/package gates from
[the contributor guide](../../CONTRIBUTING.md). Source imports/Lake roots and the
[generated map](../../docs/reference/repository-map.md) determine exact dependencies.
Do not infer installed capability or independent admission from this package's presence.
