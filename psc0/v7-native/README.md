# Native PSCV0 v7 development

Develop the portable compiler in `.lean` and run the current sources through the
official Lean native compiler. The native host checks compiler-produced declarations
with the official RC4 kernel before emitting TypeScript. It does not use Lean's
frontend as a fallback for unsupported PSCV0 syntax or semantics.

## Fast loop

From this directory on the Linux development runner:

```sh
lake build pscv0_native
.lake/build/bin/pscv0_native --check path/to/Application.ps
.lake/build/bin/pscv0_native --emit path/to/Application.ps path/to/Application.ts
```

`--check` accepts several independent input files in one process. It initializes
the checked prelude once and isolates each input from all earlier inputs, including
failed ones. It does not implement project imports yet: imports fail explicitly
with `PSCV0-NATIVE-MODULE-IMPORTS-PENDING`. This is the existing bounded v7 frontend
connected to the existing portable semantics, not complete v7 language coverage.

The emitted TypeScript uses the existing backend and pinned TypeScript 7.0.2
profile. The CLI emits TypeScript; use the pinned target compiler for JavaScript.
An input is an application fixture, never generated compiler source.

## Boundaries

- Implementation authority is shared `.lean` source during language growth.
- `packages/compiler/src/Ps/Compiler/Pscv0.lean` owns the portable v7 frontend entry.
- `host/src/Ps/Host/NativeV7.lean` owns native IO/timing and official kernel checks.
- `packages/pskernel-core` is excluded from source resolution, CI checkout,
  targets and tests. `Ps.Core` remains the compiler's expression data model.
- The separate RC4 toolchain does not change the parent 4.34 bootstrap pin or
  published provider identities. The historical provider's canonical decoder and
  prelude builder are reused as implementation code; its 4.34 metadata is not
  used as this host's identity.
- Canonical bridge normalization is preserved, including nested recursion.
  The same immutable prepared value survives checking and emission.
- No compiler `.ps` generation, generated frontend rebuild, full fixed point,
  independent kernel test suite, or Windows tests belong to this fast loop.

## Small checks and evidence

```sh
node ../scripts/pscv0-native-profile.mjs
lake build pscv0_native pscv0_native_checks
.lake/build/bin/pscv0_native_checks
```

The source inventory walks imports rather than a hand-maintained module list.
It rejects host dependencies and partial/unsafe definitions in the selected
portable roots. This is an initial import/source guard, not a complete authoring
profile verifier or a final runtime-library manifest.

The executable reuses the existing 28 M1 parser cases and adds a small semantic
batch: typed local/application, selected Except do, parse/type/import refusals,
and request isolation. The Linux workflow additionally checks CLI output and
runs one small emitted application. Phase times and source hashes are artifacts.
A successful result claims official-kernel acceptance under the current PSC
prelude; it does not claim full v7 conformance or verified runtime behavior.

Ordinary edits use incremental Lake builds with toolchain/configuration-specific
cache keys. The old M1 generation and closure workflows are manual-only here.
No timing claim is made until the new job actually completes.

## Next semantic milestones

1. Rich source representation and shared parser category ownership.
2. Shared scopes, ordered applications, expected types and small proof goals.
3. Dependent data/patterns, classes and structural/WF recursion.
4. General typed do/control and exact runtime/library semantics.
5. Selected proof automation, contracts and verified-effect closure.
6. Complete the concrete Standard/P1 environment and capability ledger.
7. Only then translate the actual implementation closure to readable v7 `.ps`
   and perform final source/semantic and compiler-generation qualification.

Keep native-only kernel/host services outside that final portable closure.
Never imply that native Lean elaborator availability proves portable coverage.
