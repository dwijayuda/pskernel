# meta

Inference, reduction, unification and instances. Start at [src/Ps/Meta/Infer.lean](src/Ps/Meta/Infer.lean).

- Representation: Core terms/environment → inferred or refused semantic result.
- Boundary: No target or host authority.
- Focused guard: [scripts/check-infer-selfhost-source-syntax.mjs](../../scripts/check-infer-selfhost-source-syntax.mjs). This guard alone is not release qualification.
- Refusal/resources: preserve explicit fuel, error order, source/body identities,
  and negative cases. See [pass contracts](../../docs/reference/pass-contracts.md).

For a change, locate the responsible operation here, preserve both grammars/shared
semantics, and run the focused guard plus selected source/package gates from
[the contributor guide](../../CONTRIBUTING.md). Source imports/Lake roots and the
[generated map](../../docs/reference/repository-map.md) determine exact dependencies.
Do not infer installed capability or independent admission from this package's presence.
