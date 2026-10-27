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

## npm package build

This is a source package. Its default API exposes sourcePackage and readSources; it does not export the compiler's private internal functions or provide a proof checker. The ./compiler entry transparently re-exports the existing checked proofscript API.

Build from this directory with npm run build, clean generated dist with npm run clean,
and create a tarball with npm pack. Builds use the pinned qualified inputs and the
workspace scripts; installation has no build or download hooks. Registry publication
is not authorized. See [the package guide](../../docs/guides/npm-packages.md).
