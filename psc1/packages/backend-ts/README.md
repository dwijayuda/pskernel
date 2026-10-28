# backend-ts

TypeScript emission and runtime support. Start at [src/Ps/BackendTs/Module.ps](src/Ps/BackendTs/Module.ps).

- Representation: Checked IR → readable typed candidate plus existing runtime.
- Boundary: RuntimeSupport.lean owns stack/UTF-8 strings; no changed semantics.
- Focused guard: [scripts/check-stack-safe-ts-source.mjs](../../scripts/check-stack-safe-ts-source.mjs). This guard alone is not release qualification.
- Refusal/resources: preserve explicit fuel, error order, source/body identities,
  and negative cases. See [pass contracts](../../docs/reference/pass-contracts.md).

For a change, locate the responsible operation here, preserve both grammars/shared
semantics, and run the focused guard plus selected source/package gates from
[the contributor guide](../../CONTRIBUTING.md). Source imports/Lake roots and the
[generated map](../../docs/reference/repository-map.md) determine exact dependencies.
Do not infer installed capability or independent admission from this package's presence.

## npm package build

This package provides transparent adapters to the existing checked proofscript API and verified source snapshots. Backend compile adapters select their declared output target; the ./compiler entry retains the full existing API. No separately compiled internal compiler implementation or new self-hosting qualification is claimed.

Build from this directory with npm run build, clean generated dist with npm run clean,
and create a tarball with npm pack. Builds use the pinned qualified inputs and the
workspace scripts; installation has no build or download hooks. Registry publication
is not authorized. See [the package guide](../../docs/guides/npm-packages.md).
