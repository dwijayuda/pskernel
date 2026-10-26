# bridge

Canonical admission and host protocol encoding. Start at [src/Ps/Bridge/CheckedAdmissions.lean](src/Ps/Bridge/CheckedAdmissions.lean).

- Representation: Exact Core graph → canonical admission bytes.
- Boundary: Encoding is not actual checker acceptance.
- Focused guard: [scripts/compiler-host-protocol-tests.mjs](../../scripts/compiler-host-protocol-tests.mjs). This guard alone is not release qualification.
- Refusal/resources: preserve explicit fuel, error order, source/body identities,
  and negative cases. See [pass contracts](../../docs/reference/pass-contracts.md).

For a change, locate the responsible operation here, preserve both grammars/shared
semantics, and run the focused guard plus selected source/package gates from
[the contributor guide](../../CONTRIBUTING.md). Source imports/Lake roots and the
[generated map](../../docs/reference/repository-map.md) determine exact dependencies.
Do not infer installed capability or independent admission from this package's presence.
