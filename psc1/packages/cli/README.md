# cli

Native Lean command composition. Start at [src/Main.lean](src/Main.lean).

- Representation: Native arguments → host/compiler workflow.
- Boundary: Installed npm CLI is separate host transport; preserve both entry points.
- Focused guard: [scripts/native-typescript-cli.test.mjs](../../scripts/native-typescript-cli.test.mjs). This guard alone is not release qualification.
- Refusal/resources: preserve explicit fuel, error order, source/body identities,
  and negative cases. See [pass contracts](../../docs/reference/pass-contracts.md).

For a change, locate the responsible operation here, preserve both grammars/shared
semantics, and run the focused guard plus selected source/package gates from
[the contributor guide](../../CONTRIBUTING.md). Source imports/Lake roots and the
[generated map](../../docs/reference/repository-map.md) determine exact dependencies.
Do not infer installed capability or independent admission from this package's presence.
