# TypeScript 7.0.2 for current PSC0 emission

Status: the exact published package and CLI passed the first cloud availability
check at `cb0a9d012c66e3e02e2391562243912a0e8700d4`,
[run 37907973917](https://github.com/dwijayuda/pskernel/actions/runs/37907973917).
Current PSC0 integration is staged on `psc0/typescript-7-v1`; its complete
native/generated/fixed-point/provider qualification is pending.

## Decision and scope

Upgrade the current `psc0` workspace's TypeScript CLI dependency from 5.8.3 to
exactly 7.0.2. Keep the original S0/A recovery compiler on 5.8.3 and keep A as
the selected authoring seed. Lean 4.34.0 and Node 22.23.3 retain their pins.

The audit covered 277 active source/configuration/script files, all eleven
workflows and 49 nonlegacy Markdown files at the M6 emitter repair checkpoint.
The four production TypeScript invocation paths in PSC0 use its command line:
the native host, checked-build, compile-with-generated and SH1 capability
compilation. PSC0 has no TypeScript compiler-API integration, no active
TypeScript project configuration, and no separate checked-in package lock.

The separate repository-root workspace uses TypeScript's programmatic API in
`packages/backend-ts/src/typescript-compiler.ts`, including program and source
creation and diagnostic handling. Its package and lockfile stay on 5.8.3.
Microsoft's [TypeScript 7 release announcement](https://devblogs.microsoft.com/typescript/announcing-typescript-7-0/)
describes the native compiler and states that 7.0 does not ship the old API.
Moving that independent backend requires its own adapter migration.

This dependency upgrade does not enlarge the PSC language accepted by a seed,
activate a named PSC1 profile, promote a new seed, or establish strict SH/1.

## Explicit compiler profiles

| Profile | Exact TypeScript version | Purpose | Positional CLI configuration |
| --- | --- | --- | --- |
| Current | 7.0.2 | New native and generated PSC0 output, development gate, C1/C2/C3 | Prepend `--ignoreConfig` |
| Historical | 5.8.3 | S0 identity/recovery and exact A reconstruction | Preserve the original arguments |

The JavaScript and native host adapters use the same selection contract:

- `PSC0_TYPESCRIPT_VERSION` selects an exact expected version. The default is
  `7.0.2`; the only other supported value is the historical `5.8.3`.
- `PSC0_TSC`, when supplied, is an authoritative absolute path to the installed
  JavaScript launcher. Empty, relative, missing or unowned launcher selections
  fail. Discovery does not replace an invalid explicit selection.
- Ordinary discovery reads the installed `typescript/package.json` and its
  `bin.tsc` entry, then considers installed launchers on PATH. A shell shim or
  a native platform executable is not a substitute for that package entry.
- Callers verify the launcher's exact reported version before compilation.

Both pinned packages provide JavaScript launchers. TypeScript 7's launcher
starts its separately packaged native executable. Install optional dependencies;
the native platform package is necessary even though npm lifecycle scripts may
be disabled. The package check confirmed the normal `typescript@7.0.2`
package, `bin.tsc = ./bin/tsc`, and exact-version
`@typescript/typescript-<platform>-<architecture>` optional dependencies.

Production output retains explicit ES2022 target and module, bundler resolution,
strict checking, declarations, source maps, no emission on errors, skipped
library checking and plain diagnostics. CommonJS runtime fixtures select
bundler resolution only for 7, keeping the 5 recipe unchanged. The
`--ignoreConfig` flag handles positional builds launched from an unrelated
project directory; the package check exercised that case successfully.
These flags follow the documented
[6.0 transition](https://devblogs.microsoft.com/typescript/announcing-typescript-6-0/)
and [7.0 behavior](https://devblogs.microsoft.com/typescript/announcing-typescript-7-0/).

## Preserve the recoverable seed identity

A's compiler bytes were produced with TypeScript 5.8.3. Executing those
authenticated JavaScript bytes under the recorded Node runtime does not require
new output to be compiled with the same TypeScript version.

Current generation therefore records two facts separately: the seed's original
producer toolchain and the target emission toolchain. Seed execution still
requires the original Node/platform/architecture/Lean identity, and the seed's
JavaScript digest and full manifest remain authoritative. Recovery still checks
the complete original toolchain, including actual TypeScript 5.8.3.

`selfhost-seed.json`, its identity hash, its expected products and its validator
remain unchanged. A verified cache or immutable qualification artifact can
supply A directly. Reconstruction still follows S0(A), then C1(A), under 5.8.3
and compares the original pinned products before accepting the recovered seed.

Cache and artifact hits additionally replay only A's TypeScript compilation
under 5.8.3. That bounded check hashes the copied source, requires the exact
manifest JavaScript digest and retains diagnostics, command details and emitted
declaration/map hashes. A replay failure stops immediately; it does not trigger
source reconstruction. This proves the current historical CLI selection while
avoiding an unnecessary S0(A)/C1(A) rebuild.

CI installs current and historical TypeScript into distinct versioned prefixes.
Recovery steps receive the historical launcher, expected version and PATH.
The frozen S0 native host cannot read the new overrides, so its isolated checkout
must resolve the historical PATH installation without an ancestor installation
of TypeScript 7. Current qualification receives the current launcher/profile.
Installed manifests and package locks are retained with the run evidence.

Qualified current-source products do not automatically become the next seed.
A remains selected. A future seed promotion must explicitly define and qualify
its parent-seed recovery path and its new product/toolchain identities.

## Ordered cloud gates

The isolated package availability check is intentionally short. It verified
installation, reported version, positional compilation with unrelated config,
and nonempty JavaScript/declaration/source-map output. It does not claim PSC0
semantic or self-host qualification. Its exact receipt and artifact identity are
preserved in [typescript7-package-evidence.json](typescript7-package-evidence.json).

The integration workflow then runs these gates in order:

1. Inspect the installed current package, metadata-selected launcher, native
   platform package and actual executable; exercise explicit profile/path
   rejection and a positional runtime fixture.
2. Verify host/source guards and build the current native compiler. Run the
   existing native and replay runtime cases, including the changed CommonJS
   caller and the ESM erasure-index fixture.
3. Run the bounded native development gate: native current-source IR checking,
   same-IR emission parity, generated IR-checker cases and existing language,
   helper, generic-erasure, preparation-session and iteration conformance.
4. Reuse the emitted complete N1 TypeScript and compile those exact bytes once
   under 5.8.3 and once under 7.0.2. Retain every available diagnostic, process
   result, output hash and elapsed-time observation before reporting failure.
5. Build selected-seed C1, then current C2 and C3. Require the existing canonical
   source, canonical admissions, TypeScript and JavaScript product equality
   within the current 7.0.2 profile and all generated semantic gates.
6. Submit the exact resulting admissions to the independently pinned native
   provider. Provider acceptance remains a separate receipt.

Cross-version JavaScript, declaration or source-map byte equality is not required:
TypeScript compiler versions can change those products. Each version's outputs
are recorded, while current-source fixed-point comparisons use the same profile.

The full-source comparison runs even after a failed development gate when its
emitted TypeScript is available. Both profile phases retain their diagnostics;
a failure in the first phase does not hide the other compiler's result. The
comparison has a ten-minute process timeout and a 64 MiB capture bound per
compiler, both recorded explicitly. No smaller manual diagnostic truncation
is applied.

## Development commands

From `psc0`, install the workspace's exact development dependency and use the
existing commands:

```sh
npm install
npm run check:typescript-profile
npm run dev:sh1
```

`dev:sh1` builds both `psc1` and `psc1_ir_check_tests`, then runs the bounded
current-profile gate. A global installed TypeScript 7.0.2 CLI also works when no
workspace package shadows it. Use `PSC0_TSC` when choosing an isolated
installation explicitly.

Recovery commands require a deliberately selected historical installation.
For example, with an absolute versioned installation directory:

```sh
PSC0_HISTORICAL_TOOLS=/absolute/path/to/typescript-5.8.3
PSC0_TSC="$PSC0_HISTORICAL_TOOLS/node_modules/typescript/bin/tsc" \
PSC0_TYPESCRIPT_VERSION=5.8.3 \
PATH="$PSC0_HISTORICAL_TOOLS/node_modules/.bin:$PATH" \
node scripts/sh1-qualify.mjs seed-identity --source ../historical-source/psc0
```

Use the same profile for `recover-seed` and `recover-qualified-seed`.
Current `native-candidate`, `candidate` and `fixed-point` commands require 7.0.2.
Changing PATH alone is insufficient if a current workspace package or explicit
launcher override would otherwise take precedence.

## Performance interpretation

The same-source comparison measures one sequential CLI invocation per version
on one runner. It includes launch, type checking and emission, and records the
actual source and products. It is a useful checkpoint observation, not a broad
benchmark or a claim about all machines.

PSC parsing, elaboration, normalization, erasure and runtime IR checking have
their own costs. The existing resident `iterate:sh1` loop prepares PSC and can
emit TypeScript, but it does not invoke `tsc`. A faster TypeScript compiler
therefore cannot directly shorten its warm preparation stage. Report the
measured TypeScript phase and total workflow costs separately; do not apply
Microsoft's general benchmark multipliers to this compiler without evidence.

No current-source TypeScript 7 performance number or full qualification result
has been earned at this staging checkpoint.
