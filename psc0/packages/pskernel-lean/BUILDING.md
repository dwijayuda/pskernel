# Building and using the PSC2 Lean 4.34 kernel provider

This document covers both the bundled native distribution and source development for `psc15selfhost/packages/pskernel-lean`.

The provider uses the pinned official Lean 4.34 toolchain and calls the real Lean kernel through `Lean.Environment.addDeclCore`. The copied `kernel/`, `runtime/`, and `util/` source trees are retained for a later standalone C++/WASM provider; they are not compiled directly by this build.

## 1. Required identity

Provider identity is pinned by `LEAN_SOURCE_PIN.json`:

```text
Lean:      4.34.0
Tag:       v4.34.0
Commit:    293d5d0c0c3f3dded4688b3ccd6a33939ac5102b
Protocol:  pskernel-lean/1
Profile:   lean4.34-core
```

Do not substitute another Lean release when validating this provider profile.

For host scripts, CI uses Node 22. TypeScript is needed only when a `psc build ...` path continues from kernel admission into TS/JS generation; the workspace pins TypeScript `7.0.2` (native Go compiler).

## 2. Normal npm use: no Lean build required

`@proofscript/pskernel-lean@4.34.0` bundles verified providers for:

```text
linux-x64
linux-arm64
darwin-x64
darwin-arm64
win32-x64
```

On those targets, an installed package resolves its bundled provider automatically. The consumer does not need Lean, Lake, a C++ compiler, or an install-time download.

The resolver order is:

```text
1. explicit PSC_LEAN_KERNEL_PROVIDER_BIN / binaryPath override
2. verified bundled provider for process.platform + process.arch
3. source-checkout Lake binary development fallback
4. explicit unsupported/missing-provider failure
```

`PREBUILT_MANIFEST.json` records the exact identity, source commit, size, and SHA-256 of each bundled executable. The selected bundled provider is digest-checked before execution.

Windows ARM64 is not part of this Lean 4.34 native package matrix.

## 3. Install Lean for source development

You only need Lean when rebuilding or modifying the provider itself.

With `elan` installed, entering `psc15selfhost/` should select the toolchain from `lean-toolchain` automatically.

If needed:

```text
elan toolchain install leanprover/lean4:v4.34.0
```

Verify it:

```text
lean --version
lean --githash
```

The git hash must be:

```text
293d5d0c0c3f3dded4688b3ccd6a33939ac5102b
```

The repository gate performs this check automatically:

```text
cd psc15selfhost
npm run check:kernel:lean434:pin
```

## 4. Build the native provider from source

From `psc15selfhost/`:

```text
npm run build:kernel:lean434
```

Equivalent Lake command:

```text
lake build psc2_lean_kernel_provider
```

Development output locations are normally:

```text
.lake/build/bin/psc2_lean_kernel_provider
.lake/build/bin/psc2_lean_kernel_provider.exe   # Windows
```

These source-build paths are development fallbacks. Normal installed-package use prefers the bundled provider.

## 5. Run provider tests

```text
npm run test:kernel:lean434
```

For only the Lean executable tests:

```text
npm run test:kernel:lean434:lean
```

Expected marker:

```text
PSC2_LEAN_KERNEL_PROVIDER_TESTS: PASS
```

The broader package/distribution tests additionally cover npm exports, manifest/digest validation, staging/assembly, packed consumers, generated compiler integration, CLI kernel checks, and bootstrap isolation.

## 6. Inspect provider identity

For a source build:

```text
lake exe psc2_lean_kernel_provider --version
lake exe psc2_lean_kernel_provider --health
```

The response must identify:

```text
provider:     lean4-cpp
leanVersion:  4.34.0
leanCommit:   293d5d0c0c3f3dded4688b3ccd6a33939ac5102b
profile:      lean4.34-core
protocol:     pskernel-lean/1
```

The package's Node adapter validates the same identity for bundled and overridden providers.

## 7. Check canonical admissions directly

If `admissions.json` contains PSC canonical checked-admissions v2, a source build can be exercised directly.

Linux/macOS:

```text
cat admissions.json | lake exe psc2_lean_kernel_provider --check
```

PowerShell:

```text
Get-Content -Raw admissions.json | lake exe psc2_lean_kernel_provider --check
```

A valid request returns JSON with `"accepted": true`.

A malformed request or kernel-invalid declaration returns `"accepted": false` with a stable `errorKind`. A semantic kernel rejection normally also reports `declarationIndex`.

For normal Node/npm use, call `checkCanonicalAdmissions` from `@proofscript/pskernel-lean` instead of spawning an internal package path yourself.

## 8. Use it from the generated PSC2 compiler

The CLI host layer consumes canonical admissions produced by the generated PSC2 compiler.

If the standard bootstrap compiler exists at:

```text
dist/bootstrap/packages/compiler/index.js
```

check a PSC project with:

```text
node packages/cli/bin/psc.mjs check path/to/Main.ps --kernel lean434
```

or:

```text
npm run psc -- check path/to/Main.ps --kernel lean434
```

To select another generated compiler explicitly:

```text
node packages/cli/bin/psc.mjs check path/to/Main.ps \
  --kernel lean434 \
  --compiler path/to/compiler/index.js
```

The host path is:

```text
project sources
  -> generated PSC2 compiler
  -> canonical admissions v2
  -> @proofscript/pskernel-lean
  -> bundled/selected native process
  -> Lean 4.34 kernel
  -> accept / reject
```

Lean parser/elaborator input is not generated as part of this path.

## 9. Kernel-gated build

A build can require Lean kernel acceptance before code generation:

```text
node packages/cli/bin/psc.mjs build path/to/Main.ps \
  --out dist/app.js \
  --kernel lean434
```

The build order is:

```text
kernel check
  -> if accepted: PSC2 TS generation
  -> TypeScript compilation
  -> JS output
```

If the kernel rejects the module, compilation is not launched and the requested output is not emitted.

A build without `--kernel lean434` preserves the existing self-host/bootstrap behavior. This is intentional: the first fixed-point closure remains independent of this provider.

### TypeScript for gated JS builds

The workspace pins `typescript@7.0.2`. If `tsc` is not available on your machine, install/use that exact version before testing JS output:

```text
npm install --global typescript@7.0.2
tsc --version
```

Expected:

```text
Version 7.0.2
```

This TypeScript requirement is for the final TS -> JS build stage, not for Lean kernel admission itself.

## 10. Explicit provider override

Normally no override is required on the five bundled targets.

To deliberately use another compatible native build:

Linux/macOS:

```text
export PSC_LEAN_KERNEL_PROVIDER_BIN=/absolute/path/to/psc2_lean_kernel_provider
```

PowerShell:

```text
$env:PSC_LEAN_KERNEL_PROVIDER_BIN = "C:\absolute\path\psc2_lean_kernel_provider.exe"
```

Programmatic callers may also pass `binaryPath` to `checkCanonicalAdmissions`.

The adapter still validates the provider protocol, profile, Lean version, exact Lean source commit, and result shape. An override changes executable selection, not the semantic identity contract.

## 11. Rebuilding the committed prebuilt matrix

The repository workflow `.github/workflows/psc2-lean-kernel-prebuilt.yml` is manually dispatchable and builds all five targets on native runners.

For every target it:

1. installs the exact Lean toolchain;
2. verifies `lean --githash`;
3. builds the provider;
4. strips release symbols;
5. runs `--health` and positive/negative kernel fixtures **after stripping**;
6. rejects a provider at or above GitHub's 100 MiB per-file repository limit;
7. inspects native dependencies;
8. proves standalone execution with the Lake build tree hidden;
9. stages the provider plus provenance metadata.

The assembly job then requires exactly five mutually consistent artifacts, restores executable mode where needed, recomputes SHA-256, generates `PREBUILT_MANIFEST.json`, runs `npm pack`, installs/executes the packed package, and only then updates the committed distribution.

The workflow is manual-only in its committed form. Do not add an uncontrolled generated-commit loop.

## 12. Troubleshooting

### Bundled provider is reported missing or corrupt

Inspect:

```text
packages/pskernel-lean/PREBUILT_MANIFEST.json
packages/pskernel-lean/prebuilt/<target>/
```

A checksum mismatch is intentionally fatal. Do not bypass digest validation. Rebuild the distribution through the verified prebuilt workflow if package bytes need replacement.

### Unsupported platform/architecture

The first Lean 4.34 package supports only the five target tuples listed above. Unsupported tuples fail closed. A deliberate custom provider may still be supplied through the explicit override.

### Source-checkout provider is missing

If you are intentionally developing without committed prebuilts, build it with:

```text
npm run build:kernel:lean434
```

or set `PSC_LEAN_KERNEL_PROVIDER_BIN` to an already-built compatible provider.

### Lean pin check fails

Run:

```text
lean --version
lean --githash
```

Make sure `lean-toolchain` resolves to `leanprover/lean4:v4.34.0` and the hash is the pinned commit above.

Do not weaken the pin check to make another Lean version pass.

### `psc check` says the generated compiler is missing

Build the PSC2 bootstrap/self-host compiler first, or supply it explicitly with `--compiler`.

### Kernel rejection

A kernel rejection is not the same as a provider crash. Inspect `errorKind`, `declarationIndex`, and `message`. Do not bypass or downgrade a semantic rejection.

### TypeScript build fails after kernel acceptance

Kernel admission already succeeded; diagnose the TypeScript/backend stage separately. Confirm `tsc --version` is `5.8.3` and inspect the emitted TypeScript/compiler diagnostic.

## 13. Separate future work

The following are intentionally separate milestones:

- compiling the copied Lean `kernel/`, `runtime/`, and `util/` sources as a standalone C++ library;
- a stable C ABI over that standalone build;
- `@proofscript/pskernel-lean-wasm@4.34.0` / Emscripten execution;
- PSC self-host kernel vs Lean 4.34 differential/dual checking;
- promoting accepted modules into a provider-neutral `CheckedModule` / `CheckedCore` compiler type;
- native code-signing/notarization for public release artifacts.

Those should reuse the same canonical admissions/provider-response boundary rather than changing PSC compiler semantics for each execution mechanism.
