# PSC2 Lean 4.34 kernel provider

This package is the **Lean-backed kernel provider** for the PSC2 self-host work in `psc15selfhost`.

Its job is intentionally narrow:

```text
canonical PSC core admissions
        |
        v
pskernel-lean provider
        |
        v
official Lean 4.34 kernel admission
        |
   accept / reject
```

It is an assurance/bootstrap provider. It is **not** the portable PSC2 compiler core and it is **not** part of the first fixed-point bootstrap closure.

## Semantic target

The provider is pinned to:

- Lean version: `4.34.0`
- Lean tag: `v4.34.0`
- Lean source commit: `293d5d0c0c3f3dded4688b3ccd6a33939ac5102b`
- provider protocol: `pskernel-lean/1`
- provider profile: `lean4.34-core`

The machine-readable pin is `LEAN_SOURCE_PIN.json`. The workspace `lean-toolchain` is also pinned to `leanprover/lean4:v4.34.0`.

Do not silently change any of these values. A newer Lean version is a new provider profile / conformance decision, not a routine dependency upgrade.

## What is implemented now

The current native provider is written in Lean and compiled against the pinned official Lean 4.34 distribution. Semantic admission is performed through `Lean.Environment.addDeclCore` in a trust-level-0 environment.

The provider does **not** generate `.lean` source and does not ask Lean's parser or elaborator to reinterpret PSC programs. The path is semantic:

```text
PSC canonical admissions JSON
  -> PSC canonical decoder
  -> PSC Core values
  -> Lean Name / Level / Expr / Declaration values
  -> Lean kernel environment admission
```

This distinction matters: the provider checks the semantic object produced by PSC rather than checking whether a generated Lean program happens to elaborate.

The self-host CLI now has a host-only integration path:

```text
PSC source
  -> generated PSC2 compiler
  -> canonical admissions
  -> pskernel-lean native provider
  -> Lean 4.34 kernel
  -> accept / reject
```

The provider is invoked by the host process. No Lean-specific module is imported into the portable semantic compiler closure.

## Source directories

```text
packages/pskernel-lean/
  provider/       native Lean provider implementation
  provider-test/  provider semantic tests
  host/           host-side adapters, currently Node.js
  kernel/         pinned Lean kernel source copy / standalone-build input
  runtime/        pinned Lean runtime source copy / standalone-build input
  util/           pinned Lean util source copy / standalone-build input
```

The copied `kernel/`, `runtime/`, and `util/` trees are **not yet built as a separate standalone C++ library** by the current provider target. Today the provider uses the kernel supplied by the pinned official Lean distribution. A future standalone native/WASM provider may compile these pinned sources behind the same protocol boundary.

Do not make compiler packages depend directly on these C++ source trees.

## Prelude ownership

The provider reconstructs the PSC2 self-host prelude into an empty Lean environment with trust level 0.

The PSC prelude contains some forward references. Therefore replay is dependency-aware rather than merely list-order based:

1. Try each pending declaration with the Lean kernel.
2. Admit successful declarations.
3. Defer only `unknownConstant` failures.
4. Fail immediately on every other kernel failure.
5. Repeat while progress is made.
6. Fail closed if unresolved declarations remain with no progress.

This is not an unchecked dependency sorter. Every declaration that enters the environment is still admitted by the Lean kernel.

## Canonical input protocol

`--check` reads one complete canonical admissions document from stdin.

The envelope is the existing PSC bridge format:

```json
{
  "admissions": [],
  "format": "proofscript-checked-admissions",
  "version": 2
}
```

The decoder reuses PSC's canonical name, level, expression, declaration, theorem, and inductive encodings. Unsupported or malformed forms fail closed.

Definition reducibility heights require special care: PSC's codec represents the height as an unbounded natural number, while Lean 4.34 stores a regular reducibility height as `UInt32`. The provider rejects values that do not round-trip exactly through `UInt32`; it never truncates them.

## Native process interface

From `psc15selfhost/`:

```text
npm run check:kernel:lean434:pin
npm run build:kernel:lean434
npm run test:kernel:lean434
```

Direct Lake commands are also available:

```text
lake build psc2_lean_kernel_provider
lake exe psc2_lean_kernel_provider --version
lake exe psc2_lean_kernel_provider --health
cat admissions.json | lake exe psc2_lean_kernel_provider --check
```

On Windows the built executable has the normal `.exe` suffix. The Node adapter resolves the platform-specific default automatically.

Accepted response:

```json
{
  "protocol": "pskernel-lean/1",
  "accepted": true,
  "provider": "lean4-cpp",
  "leanVersion": "4.34.0",
  "leanCommit": "293d5d0c0c3f3dded4688b3ccd6a33939ac5102b",
  "profile": "lean4.34-core"
}
```

Rejected response includes a stable error kind and, when applicable, the declaration index:

```json
{
  "protocol": "pskernel-lean/1",
  "accepted": false,
  "provider": "lean4-cpp",
  "leanVersion": "4.34.0",
  "leanCommit": "293d5d0c0c3f3dded4688b3ccd6a33939ac5102b",
  "profile": "lean4.34-core",
  "errorKind": "kernel-rejection",
  "declarationIndex": 0,
  "message": "..."
}
```

The protocol boundary is text/bytes in and text/bytes out. Host clients must not depend on Lean internal C++ object layouts.

## Self-host CLI integration

After a generated compiler exists, check a project with the Lean provider:

```text
node packages/cli/bin/psc.mjs check path/to/Main.ps \
  --kernel lean434 \
  --compiler dist/bootstrap/packages/compiler/index.js
```

or, through the workspace bin command:

```text
npm run psc -- check path/to/Main.ps --kernel lean434
```

A kernel-gated build is:

```text
node packages/cli/bin/psc.mjs build path/to/Main.ps \
  --out dist/app.js \
  --kernel lean434 \
  --compiler dist/bootstrap/packages/compiler/index.js
```

For `build --kernel lean434` the order is deliberately fail-closed:

```text
flatten project
  -> generated compiler canonical admissions
  -> Lean 4.34 provider check
  -> only if accepted: generated compiler TypeScript output
  -> tsc / JavaScript output
```

If Lean rejects the module, code generation is not started and the requested output is not emitted.

A build **without** `--kernel` retains the existing self-host/bootstrap behavior. This keeps `psc fixed-point` independent of the external Lean provider.

The default compiler path is `dist/bootstrap/packages/compiler/index.js`; pass `--compiler` when testing another generated compiler generation.

## Node host adapter

`host/node-provider.mjs` exposes:

```text
checkCanonicalAdmissions(source, options?)
defaultLeanKernelProviderBinary(options?)
```

The adapter:

- spawns the provider with `--check`,
- sends canonical admissions on stdin,
- parses exactly one JSON response,
- validates protocol, provider identity, Lean version, exact Lean source commit, and `accepted`,
- reports process-start, nonzero-exit, and malformed-output errors as host failures.

`PSC_LEAN_KERNEL_PROVIDER_BIN` may override the binary path. Otherwise the adapter resolves the workspace Lake output automatically and adds `.exe` on Windows.

## Error boundary

Provider errors are classified separately from ordinary kernel rejection. Current stable categories include:

- protocol/version mismatch,
- malformed request,
- unsupported PSC core form,
- prelude mismatch,
- provider version mismatch,
- kernel rejection,
- provider internal error.

A codec-valid declaration can still be rejected by the kernel. Tests explicitly cover this distinction using a definition whose declared type is `Nat` but whose body is `Sort 0`.

## What this does and does not prove

A successful response means the submitted declarations were accepted by this pinned Lean 4.34 kernel-provider path on top of the provider-owned prelude.

It does **not** by itself prove:

- full equivalence between PSC's own kernel and all Lean 4 behavior,
- exhaustive compatibility with the complete Lean environment,
- equivalence of parser/elaborator behavior,
- exact handling of every deprecated native-reduction path,
- that PSC2 is already fully independent from Lean.

Do not label codec validation or `AdmissionReadyModule` as `CheckedCore`. A genuine checked artifact must be produced only after a selected kernel provider has accepted the semantic declarations.

## Intended architecture

The long-term boundary remains:

```text
PSC source
  -> parser / resolver / elaborator
  -> canonical PSC Core
  -> AdmissionReadyModule
  -> selected KernelProvider
  -> CheckedModule / CheckedCore
  -> erasure
  -> VerifiedIR
  -> backend
```

Provider implementations may eventually include:

- `psc`: the self-hosted PSC kernel,
- `lean434`: this Lean 4.34 assurance provider,
- `dual`: require both providers and fail on disagreement.

The compiler should depend on the provider protocol/interface, never on Lean-specific APIs.

## Standalone C++ / WASM next step

The future standalone provider can compile the pinned Lean 4.34 `kernel` plus the required `runtime`/`util` support and a very small PSC bridge. Keep the public ABI independent of C++ types, conceptually:

```text
init()
check(inputBytes) -> outputBytes
free(pointer)
```

The same boundary can be implemented as a native executable/library first and then compiled to WebAssembly. The canonical PSC payload and provider response should remain stable so compiler-side code does not care whether the provider runs as a child process, native library, or WASM module.

## Gates

The branch CI verifies the following provider contract:

- the installed Lean toolchain is exactly `4.34.0` at source commit `293d5d0c0c3f3dded4688b3ccd6a33939ac5102b`,
- the Lean 4.34 provider target builds,
- provider metadata is pinned,
- PSC Core maps directly to Lean semantic objects,
- unsupported metas/free variables fail closed,
- the PSC2 self-host prelude is accepted from a trust-level-0 environment,
- PSC's real canonical encoder is compatible with the provider decoder,
- malformed/version-confused input is rejected,
- a valid definition is accepted by the Lean kernel,
- a codec-valid but ill-typed definition is rejected by the Lean kernel,
- stdin/stdout `--check` behavior matches the protocol,
- the Node host adapter reproduces the same accept/reject results,
- a generated compiler can feed canonical admissions into the real provider,
- `psc check --kernel lean434` exposes the provider at the self-host CLI boundary,
- `psc build --kernel lean434` checks before compilation and a rejected build emits no output.

Keep these gates when integrating or refactoring the provider.
