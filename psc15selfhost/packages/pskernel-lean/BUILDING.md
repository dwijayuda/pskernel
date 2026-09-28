# Building and using the PSC2 Lean 4.34 kernel provider

This document covers the **current native provider** in `psc15selfhost/packages/pskernel-lean`.

The current provider is built with the pinned official Lean 4.34 toolchain and calls the real Lean kernel through `Lean.Environment.addDeclCore`. The copied `kernel/`, `runtime/`, and `util/` source trees are retained for the later standalone C++/WASM provider; they are not yet compiled directly by this build.

## 1. Required versions

Provider identity is pinned by `LEAN_SOURCE_PIN.json`:

```text
Lean:      4.34.0
Tag:       v4.34.0
Commit:    293d5d0c0c3f3dded4688b3ccd6a33939ac5102b
Protocol:  pskernel-lean/1
Profile:   lean4.34-core
```

Do not substitute another Lean release when validating this provider profile.

For the host scripts use a current Node.js release; CI uses Node 22.

TypeScript is needed only when exercising a `psc build ...` path that continues from kernel admission into TS/JS generation. The workspace pins TypeScript `5.8.3`.

## 2. Install Lean

With `elan` installed, entering `psc15selfhost/` should select the toolchain from `lean-toolchain` automatically.

If the toolchain is not already installed:

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

## 3. Build the native provider

From `psc15selfhost/`:

```text
npm run build:kernel:lean434
```

Equivalent Lake command:

```text
lake build psc2_lean_kernel_provider
```

Typical output location:

```text
.lake/build/bin/psc2_lean_kernel_provider
```

On Windows:

```text
.lake/build/bin/psc2_lean_kernel_provider.exe
```

The Node adapter handles the platform suffix automatically.

## 4. Run provider tests

```text
npm run test:kernel:lean434
```

This covers the Lean-side semantic tests and the Node host adapter.

For only the Lean executable tests:

```text
npm run test:kernel:lean434:lean
```

Expected terminal marker:

```text
PSC2_LEAN_KERNEL_PROVIDER_TESTS: PASS
```

## 5. Inspect provider identity

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

## 6. Check canonical admissions directly

If `admissions.json` contains PSC canonical checked-admissions v2:

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

## 7. Use it from the generated PSC2 compiler

The CLI host layer consumes canonical admissions produced by the generated PSC2 compiler.

If the standard bootstrap compiler already exists at:

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

The host does this:

```text
project sources
  -> generated PSC2 compiler
  -> canonical admissions v2
  -> pskernel-lean process
  -> Lean 4.34 kernel
  -> accept / reject
```

Lean parser/elaborator input is not generated as part of this path.

## 8. Kernel-gated build

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

A build without `--kernel lean434` preserves the existing self-host/bootstrap behavior. This is intentional: the first fixed-point closure must remain independent of this provider.

### TypeScript for gated JS builds

The workspace pins `typescript@5.8.3`. If `tsc` is not available on your machine, install/use that exact version before testing JS output. One simple isolated option is:

```text
npm install --global typescript@5.8.3
```

Then verify:

```text
tsc --version
```

Expected:

```text
Version 5.8.3
```

This TypeScript requirement is for the final TS -> JS build stage, not for Lean kernel admission itself.

## 9. Provider binary override

The Node adapter normally discovers the Lake-built binary automatically.

To use another native build:

Linux/macOS:

```text
export PSC_LEAN_KERNEL_PROVIDER_BIN=/absolute/path/to/psc2_lean_kernel_provider
```

PowerShell:

```text
$env:PSC_LEAN_KERNEL_PROVIDER_BIN = "C:\absolute\path\psc2_lean_kernel_provider.exe"
```

The adapter still validates the provider protocol, Lean version, exact Lean source commit, and result shape.

## 10. Troubleshooting

### Provider binary is missing

Build it first:

```text
npm run build:kernel:lean434
```

or set `PSC_LEAN_KERNEL_PROVIDER_BIN` to an already-built provider.

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

Kernel admission already succeeded; diagnose the TypeScript/backend stage separately. Confirm `tsc --version` is `5.8.3` and then inspect the emitted TypeScript/compiler diagnostic.

## 11. What still requires separate work

The following are intentionally not part of this native-provider milestone:

- compiling the copied Lean `kernel/`, `runtime/`, and `util/` sources as a standalone C++ library,
- a stable C ABI over that standalone build,
- an Emscripten/WebAssembly build of the standalone provider,
- PSC self-host kernel vs Lean 4.34 differential/dual checking,
- promoting accepted modules into a provider-neutral `CheckedModule` / `CheckedCore` compiler type.

Those should reuse the same canonical admissions/provider-response boundary rather than changing PSC compiler semantics for each execution mechanism.
