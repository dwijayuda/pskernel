# elab

Shared elaboration and actual source ownership. Start at [src/Ps/Elab/Declaration.lean](src/Ps/Elab/Declaration.ps).

- Representation: Shared syntax/environment → typed Core and origins.
- Boundary: Both grammars share meaning; preserve recursion/refusal/fuel order.
- Focused guard: [scripts/source-binding-integration-tests.mjs](../../scripts/source-binding-integration-tests.mjs). This guard alone is not release qualification.
- Refusal/resources: preserve explicit fuel, error order, source/body identities,
  and negative cases. See [pass contracts](../../docs/reference/pass-contracts.md).

For a change, locate the responsible operation here, preserve both grammars/shared
semantics, and run the focused guard plus selected source/package gates from
[the contributor guide](../../CONTRIBUTING.md). Source imports/Lake roots and the
[generated map](../../docs/reference/repository-map.md) determine exact dependencies.
Do not infer installed capability or independent admission from this package's presence.

## npm package build

This is a source package. Its default API exposes sourcePackage and readSources; it does not export the compiler's private internal functions or provide a proof checker. The ./compiler entry transparently re-exports the existing checked proofscript API.

Build from this directory with npm run build, clean generated dist with npm run clean,
and create a tarball with npm pack. Builds use the pinned qualified inputs and the
workspace scripts; installation has no build or download hooks. Registry publication
is not authorized. See [the package guide](../../docs/guides/npm-packages.md).
