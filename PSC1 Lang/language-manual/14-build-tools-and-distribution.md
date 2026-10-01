# 14. Build Tools and Distribution

PSC1 uses `psc` as its normal developer compiler interface and npm as its
primary ecosystem/package substrate.

## Current command surface

```text
psc init
psc check
psc build
psc run
psc translate
psc emit-lean
psc clean
```

See [../reference/cli.md](../reference/cli.md) for exact forms.

## Project configuration

`psconfig.json` controls:

- language track;
- entry;
- source roots;
- runtime dependencies;
- output directory;
- TypeScript/declaration/source-map output.

See [../reference/psconfig.md](../reference/psconfig.md).

## Build output

The primary JS backend can produce:

- generated TypeScript;
- JavaScript;
- `.d.ts`;
- source maps;
- assurance/build metadata.

Canonical Lean/ProofScript translations are separate semantic inspection
artifacts.

## npm integration

PSC1 does not need a second package ecosystem.

A ProofScript package can use:

- `package.json` for npm ecosystem integration;
- `psconfig.json` for ProofScript compilation;
- exact `runtimeDependencies` for bounded FFI roots.

## Rust and Wasm artifacts

The Rust and direct-Wasm backends are separate target lanes consuming
target-neutral VerifiedIR.

Their build metadata must identify the relevant compiler/toolchain/backend
profile without changing source semantics.

## Reproducibility

Useful reproducibility inputs include:

- source/module integrity;
- semantic/kernel version;
- compiler version;
- runtime dependency lock identity;
- target backend/toolchain profile.

## Self-host build

The bootstrap plan maintains a Lean/Lake-hosted path while the compiler becomes
self-hosting.

The intended transition is:

```text
handwritten bounded compiler.lean
-> working compiler
-> canonical compiler.ps
-> parity gates
-> .ps becomes maintained source
```

## Distribution claim ceiling

A package being published to npm or producing a native/Wasm binary says nothing
by itself about proof assurance.

Distribution metadata and proof/trust metadata should remain distinct and
inspectable.
