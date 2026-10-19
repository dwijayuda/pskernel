# Historical TypeScript 7 migration checkpoint

This is the preserved implementation guide for source `99786185f77edf952f11989d4c9bc44028f22f11` and run [37910429506](https://github.com/dwijayuda/pskernel/actions/runs/37910429506). Its two-profile recovery policy and commands describe that historical checkpoint. Current development uses the [TypeScript 7-only policy](TYPESCRIPT7.md); the old commands are retired. The original guide follows unchanged.

# TypeScript 7.0.2 for current PSC0 emission

Status: current PSC0 emission is qualified with exact TypeScript 7.0.2 at
`99786185f77edf952f11989d4c9bc44028f22f11`,
[run 37910429506](https://github.com/dwijayuda/pskernel/actions/runs/37910429506).
Historical S0/A recovery stays on 5.8.3, and A remains the selected authoring
seed. The separate M6 baseline is qualified under 5.8.3 at
`1b5fd12382c920944924c9d03e0851984293caa2`.
The exact published-package check had already passed at
`cb0a9d012c66e3e02e2391562243912a0e8700d4`
([run 37907973917](https://github.com/dwijayuda/pskernel/actions/runs/37907973917)).

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

The first integration run exposed a runner-specific PATH precedence issue:
`GITHUB_PATH` entries are prepended after the configured step environment is
printed. A global current-TypeScript entry therefore displaced the historical
selection used by frozen S0. The repair removes that unnecessary global entry,
supplies an explicit historical child PATH after runner augmentation, and
checks the frozen cwd/PATH lookup against the exact selected 5.8.3 launcher
before building. Conflicting cwd-local installations fail at that boundary.
The effective path, selected launcher and reported version are retained.
This changes tool selection without changing the historical compiler recipe.

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
   rejection and a positional runtime fixture. Verify host syntax and bootstrap
   source restrictions before expensive generation.
2. Verify the historical 5.8.3 identity and actual frozen-host lookup, recover
   or authenticate S0 and A, and replay A's TypeScript under its original profile.
3. Build the current native compiler. Run the
   existing native and replay runtime cases, including the changed CommonJS
   caller and the ESM erasure-index fixture.
4. Run the bounded native development gate: native current-source IR checking,
   same-IR emission parity, generated IR-checker cases and existing language,
   helper, generic-erasure, preparation-session and iteration conformance.
5. Reuse the emitted complete N1 TypeScript and compile those exact bytes once
   under 5.8.3 and once under 7.0.2. Retain every available diagnostic, process
   result, output hash and elapsed-time observation before reporting failure.
6. Build selected-seed C1, then current C2 and C3. Require the existing canonical
   source, canonical admissions, TypeScript and JavaScript product equality
   within the current 7.0.2 profile and all generated semantic gates.
7. Submit the exact resulting admissions to the independently pinned native
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

## Qualification results

The same portable M6 implementation passed its independent TypeScript 5
baseline and the current TypeScript 7 integration. The current integration
also exercised the changed native and generated CLI paths, verified historical
recovery and A replay, checked complete current IR, established current-source
C2/C3 product equality and obtained a separate pinned-provider decision.

| Current TS7 evidence | Result |
| --- | --- |
| Exact qualifying source | `99786185f77edf952f11989d4c9bc44028f22f11` |
| Compiler job | `113753993100` — success |
| Independent provider job | `113775134434` — success |
| Native full original IR | 54,879 expressions; 707,753 visited steps; complete; accepted; zero findings |
| Current C2/C3 original IR | Complete; accepted; zero findings; same original IR checked before emission |
| C2/C3 TypeScript SHA-256 | `f20c9132ae2f8adade08346b0457f6bb02b6e5145097116d2a827121304a8f70` |
| C2/C3 JavaScript SHA-256 | `37ab7de713295b7a2143f1df92b746f97e5a73a8177e906f406fde4a474c0161` |
| Historical S0/A profile | Exact 5.8.3; cold S0 recovery and A TypeScript replay passed |
| Selected authoring seed | A, unchanged |
| Strict SH/1 and profile activation | Remain false |

The TS7 compiler and later provider decisions are retained separately in
[typescript7-qualification.json](typescript7-qualification.json) and
[typescript7-provider.json](typescript7-provider.json). The compiler's original
provider-not-attempted fields remain intact.

Both profiles have their own successful C2/C3 equality result. Their emitted
JavaScript differs: the independently qualified TS5 M6 product is
`eb9768db1a10ca6da40666914e116431646a6fcdeca50c3a2f5e6dd250a031af`;
the current TS7 product is the digest in the table. Neither profile's JavaScript
identity is substituted for the other.

The first integrated run at `956e2c3345d8d634904ff812b31d3b84fc9c23d9`
stopped during frozen recovery because runner PATH augmentation displaced the
historical launcher. It earned no current-source qualification. The repaired
`99786185` run records the actual historical launcher/version before recovery
and completes the required gates. Keep both attempts in
[typescript7-execution.json](typescript7-execution.json).

The current run exercised a **cold S0 recovery** (`cacheHit: false`) under
the verified 5.8.3 launcher and reproduced the original S0 JavaScript SHA-256:

`74dcebb7b296d81924d92987e99146b5d1c5ff9fbe3d8076ca591952d2ef7f76`.

The effective historical cwd/PATH lookup receipt recorded the exact installed
5.8.3 launcher and `passed: true`. A's TypeScript-only replay also passed with
the original arguments and authenticated products:

| Selected A product | SHA-256 |
| --- | --- |
| TypeScript | `b7d57fc37a85d8f75c7bdfcac934d8022399a8543251b172dfaab91cab5e30b1` |
| JavaScript | `9d8a91e890c779c6b377b8a482ae3e997a1630b360eb8d6e7c022b3964510096` |

These are current-run recovery/replay results, not a new selection of A or
a reconstruction claim for the migrated compiler source. Exact command,
launcher, product and timing receipts are retained in
[typescript7-qualification.json](typescript7-qualification.json).

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

## Measured TypeScript phase

The completed current-source run compiled the exact same full emitted compiler
under each profile:

| TypeScript profile | Direct CLI elapsed time |
| --- | ---: |
| 5.8.3 | 9,281.561787 ms |
| 7.0.2 | 2,866.119670 ms |

Input SHA-256:
`f20c9132ae2f8adade08346b0457f6bb02b6e5145097116d2a827121304a8f70`.

The complete logged profile summary is retained in
[typescript7-qualification.json](typescript7-qualification.json).
Its exact per-phase measurements are 9,281.561786999999 ms and 2,866.11967 ms.

The comparison copies one authenticated full-compiler TypeScript input into fresh
profile-specific output directories, then invokes each exact CLI once, 5.8.3
followed by 7.0.2. It includes process startup, type checking and emission. Both
compiler commands, diagnostics, exit results, declaration/map outputs and
product hashes are retained. This is a single sequential observation on one
Linux x64 runner; it does not control for order, filesystem caching or
run-to-run variance.

The output products need not match across compiler versions. Qualification
requires canonical source, admissions, TypeScript and JavaScript equality
between C2 and C3 within the current 7.0.2 profile; their exact hashes are
recorded independently.

This pair gives a **3.238× speed ratio for the direct TypeScript CLI phase**:
7.0.2 used **69.12% less elapsed time**, a reduction of 6.415 seconds for this input.
It is one sequential observation, so the ratio is not a repeated-run average
or a measured speedup for the complete self-host pipeline.

The current TS7 native development gate recorded **106.462 seconds** internally
(`106461.999493 ms`), excluding the preceding `lake build`. Current C1/C2/C3
generation totals were 1,065.963 / 1,111.846 / 1,153.540 seconds. These
single-run stage totals are separate from the direct CLI comparison and do not
attribute all cross-run timing differences to TypeScript.

### Context: full generated self-application

The independently qualified M6/5.8.3 baseline records these phase totals across
C1, C2 and C3. These generation timers exclude the surrounding native gate,
conformance work, setup and provider job.

| Generation phase | Total seconds | Share of recorded generation time |
| --- | ---: | ---: |
| Load and prepare | 2,125.720 | 60.17% |
| Encode admissions | 329.218 | 9.32% |
| Print canonical source | 137.941 | 3.90% |
| Erase, check IR and emit TS | 909.168 | 25.74% |
| Compile TS and write evidence | 30.655 | 0.87% |

Source: [runtime-ir-checker-qualification.json](runtime-ir-checker-qualification.json),
the three complete `PSC0_SH1_GENERATION` receipts.
Their total is 3,532.701 seconds. Even removing their entire `tscAndWrite`
phase would remove only 0.87% of this recorded generation time. That arithmetic
bound does not cover the separate conformance compilations or predict the
complete CI-job speedup. Improvements to frontend preparation and the combined
erasure/checking/emission phase require their own measurements.

PSC parsing, elaboration, normalization, erasure and runtime IR checking have
their own costs. The resident `iterate:sh1` loop prepares PSC and can emit
TypeScript, but does not invoke `tsc`. The new TypeScript compiler therefore
does not directly shorten warm preparation. Generation receipt `tscAndWrite`
includes evidence writes, hashing and identity work in addition to the CLI;
its `emit` phase includes erasure, IR checking and printing. Use the bounded native development gate for a coherent change. A resident
session is useful for repeated unchanged or late-module edits that amortize its
initial whole-closure preparation. Reserve full fixed-point/provider
qualification for semantic promotion checkpoints.

The exact package result is retained in
[typescript7-package-evidence.json](typescript7-package-evidence.json);
[typescript7-execution.json](typescript7-execution.json) preserves both
integration attempts and the final receipt references. Compiler qualification,
bounded IR typing, provider acceptance and strict SH/1 remain separate.
