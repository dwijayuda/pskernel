# environment

Prelude, declarations, lookup and name resolution. Start at [src/Ps/Environment/Resolve.lean](src/Ps/Environment/Resolve.lean).

- Representation: Core declarations/names → bounded semantic environment.
- Boundary: Shared semantics; no target-specific language behavior.
- Focused guard: [scripts/check-prelude-declaration-parity.mjs](../../scripts/check-prelude-declaration-parity.mjs). This guard alone is not release qualification.
- Refusal/resources: preserve explicit fuel, error order, source/body identities,
  and negative cases. See [pass contracts](../../docs/reference/pass-contracts.md).

For a change, locate the responsible operation here, preserve both grammars/shared
semantics, and run the focused guard plus selected source/package gates from
[the contributor guide](../../CONTRIBUTING.md). Source imports/Lake roots and the
[generated map](../../docs/reference/repository-map.md) determine exact dependencies.
Do not infer installed capability or independent admission from this package's presence.
