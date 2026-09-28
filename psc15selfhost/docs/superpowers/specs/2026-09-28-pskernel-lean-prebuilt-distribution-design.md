# PSC2 Lean Kernel Prebuilt Distribution Design

Status: approved conversational design captured for written review before implementation.

Date: 2026-09-28

Branch: `psc2/pskernel-lean-provider`

Base branch: `psc2/minimal-selfhost-psc15`

Package: `@proofscript/pskernel-lean@4.34.0`

## Purpose

Bundle tested native `psc2_lean_kernel_provider` executables for every officially supported Lean 4.34 host platform directly inside the `@proofscript/pskernel-lean` package, so PSC2 users can select the Lean kernel provider without installing Lean, Lake, a C++ toolchain, or running a post-install download.

The package name identifies the provider implementation/transport. The package version identifies the Lean semantic baseline. Therefore Lean 4.34 uses:

```text
@proofscript/pskernel-lean@4.34.0
```

A future WASM transport follows the same naming/version rule:

```text
@proofscript/pskernel-lean-wasm@4.34.0
```

This distribution work must preserve the existing semantic boundary: `pskernel-lean` remains an optional host/runtime provider and must not enter the portable PSC2 compiler fixed-point closure.

## Success criteria

The milestone is complete when:

1. the repository contains tested native provider binaries for all supported target tuples;
2. each binary reports the exact provider protocol, Lean version, and Lean source commit expected by the package;
3. each binary accepts a valid canonical PSC admission request and rejects a codec-valid but semantically invalid request through the real Lean kernel;
4. `@proofscript/pskernel-lean@4.34.0` resolves the correct bundled executable automatically from `process.platform` and `process.arch`;
5. an installed packed npm tarball works on each supported target without Lean/Lake being installed or available at runtime;
6. unsupported target tuples fail closed with an explicit error;
7. bootstrap/fixed-point isolation remains unchanged;
8. the feature branch is synchronized with a GREEN PSC2 self-host base and all merge gates pass.

## Supported native targets

Lean 4.34.0 publishes official host toolchains for the following platform/architecture pairs, which define this package's first native support matrix:

| Node platform | Node arch | Distribution key | Provider executable |
| --- | --- | --- | --- |
| `linux` | `x64` | `linux-x64` | `psc2_lean_kernel_provider` |
| `linux` | `arm64` | `linux-arm64` | `psc2_lean_kernel_provider` |
| `darwin` | `x64` | `darwin-x64` | `psc2_lean_kernel_provider` |
| `darwin` | `arm64` | `darwin-arm64` | `psc2_lean_kernel_provider` |
| `win32` | `x64` | `win32-x64` | `psc2_lean_kernel_provider.exe` |

Windows ARM64 is not included in the first matrix because Lean 4.34.0 does not publish an official Windows ARM64 toolchain. The package must report it as unsupported rather than using an x64 binary implicitly.

No architecture emulation is accepted as evidence for the native matrix. Every committed binary must be built and exercised on its native target runner.

## Package layout

The provider package owns the prebuilt distribution:

```text
psc15selfhost/packages/pskernel-lean/
├── index.mjs
├── package.json
├── LEAN_SOURCE_PIN.json
├── PREBUILT_MANIFEST.json
├── prebuilt/
│   ├── linux-x64/
│   │   └── psc2_lean_kernel_provider
│   ├── linux-arm64/
│   │   └── psc2_lean_kernel_provider
│   ├── darwin-x64/
│   │   └── psc2_lean_kernel_provider
│   ├── darwin-arm64/
│   │   └── psc2_lean_kernel_provider
│   └── win32-x64/
│       └── psc2_lean_kernel_provider.exe
├── host/
│   ├── node-provider.mjs
│   └── ...
├── provider/
├── kernel/
├── runtime/
├── util/
├── README.md
├── BUILDING.md
├── INTEGRATION.md
└── NPM_PACKAGE.md
```

The five binaries are normal repository files and normal npm package files. Do not require Git LFS for the first milestone, because an npm/package checkout must contain the actual executable bytes without an additional LFS fetch step.

If measured repository or npm tarball size becomes operationally unacceptable, platform-specific npm packages may be introduced in a later distribution redesign. That is not part of this milestone.

## Prebuilt manifest

`PREBUILT_MANIFEST.json` is the authoritative package-owned index of bundled native artifacts.

It records at least:

```json
{
  "schema": 1,
  "package": "@proofscript/pskernel-lean",
  "packageVersion": "4.34.0",
  "protocol": "pskernel-lean/1",
  "provider": "lean4-cpp",
  "leanVersion": "4.34.0",
  "leanCommit": "293d5d0c0c3f3dded4688b3ccd6a33939ac5102b",
  "profile": "lean4.34-core",
  "targets": {
    "linux-x64": {
      "path": "prebuilt/linux-x64/psc2_lean_kernel_provider",
      "sha256": "..."
    }
  }
}
```

Every supported target must have exactly one manifest entry. Paths are package-relative and must not escape the package root.

Each target entry must include SHA-256. The build/assembly workflow computes the digest from the produced binary. Package tests recompute and compare the digest before executing the bundled binary.

The manifest's protocol/provider/version/commit/profile fields must agree with both `LEAN_SOURCE_PIN.json` and the binary's `--health` output. A mismatch is a hard packaging failure.

## Binary provenance

Every committed binary must be reproducible from repository source plus the pinned Lean 4.34 toolchain.

For each matrix build, CI records:

- repository source commit used for the provider build;
- target tuple;
- installed Lean version;
- installed Lean `--githash`;
- provider `--health` output;
- provider file SHA-256;
- provider file size.

The exact Lean semantic identity remains:

```text
Lean version: 4.34.0
Lean source commit: 293d5d0c0c3f3dded4688b3ccd6a33939ac5102b
Protocol: pskernel-lean/1
Profile: lean4.34-core
```

CI must verify the installed toolchain's actual `lean --githash` before building a prebuilt artifact. Metadata alone is not sufficient provenance.

## Native build strategy

Use native GitHub Actions matrix jobs, one target per native runner. Do not cross-compile the first distribution matrix.

Conceptual matrix:

```text
linux-x64    -> native Linux x64 hosted runner
linux-arm64  -> native Linux ARM64 hosted runner
darwin-x64   -> native Intel macOS hosted runner
darwin-arm64 -> native Apple Silicon macOS hosted runner
win32-x64    -> native Windows x64 hosted runner
```

Each job:

1. checks out the exact source commit;
2. installs/pins Lean 4.34.0;
3. verifies `lean --version` and `lean --githash`;
4. builds `psc2_lean_kernel_provider` with Lake;
5. locates the native executable;
6. runs `--version` and `--health`;
7. executes the positive and negative canonical-admission fixtures;
8. copies only the provider executable into a deterministic staging directory;
9. computes SHA-256 and file size;
10. uploads the staged binary plus metadata as a workflow artifact.

The build job must not copy the whole Lean toolchain, `.lake` tree, object files, or unrelated compiler executables into the npm package.

## Standalone-runtime requirement

A prebuilt artifact is not accepted merely because it runs on the build machine while the Lean toolchain is present.

Each native matrix job must test the staged binary from a temporary directory with project `.lake` paths absent from resolution and without relying on `lake` to launch it.

The validation must inspect native dynamic dependencies where the platform provides a standard mechanism (`ldd`, `otool -L`, or equivalent Windows inspection) and must directly execute:

```text
provider --health
valid admissions | provider --check
invalid admissions | provider --check
```

The runtime test must prove that normal package use does not require an installed Lean or Lake command. Standard operating-system runtime libraries are allowed; hidden dependencies on repository-local Lean/PSC build outputs are not.

If a target executable requires additional non-system shared libraries, those libraries must either be bundled explicitly under that target directory and resolved package-locally, or the build must be changed so the target is self-contained. The package must never silently depend on a developer's Lean installation.

## Repository assembly workflow

Cross-platform matrix jobs cannot each modify the branch independently. Distribution assembly is therefore a two-phase workflow:

```text
native build matrix
       |
       | workflow artifacts
       v
assembly job
       |
       +-> verify five expected target artifacts
       +-> verify metadata/version/commit/protocol
       +-> recompute SHA-256
       +-> construct PREBUILT_MANIFEST.json
       +-> construct/update prebuilt/* files
       +-> npm pack
       +-> package-surface tests
       v
prebuilt update commit
```

The repository-owned prebuilt update workflow is manually dispatchable for versioned distribution refreshes. It may use `contents: write` only in the final assembly job. Ordinary provider verification workflows remain read-only.

The assembly job must refuse to commit when:

- fewer or more than the five expected targets are present;
- two artifacts claim the same target;
- any toolchain/hash/provider identity differs;
- a SHA-256 does not match;
- a binary does not have the expected executable name;
- package tests fail.

Generated commits use an explicit distribution commit message such as:

```text
build(psc2): bundle pskernel-lean 4.34.0 native providers
```

The workflow must not recursively trigger an uncontrolled prebuilt-update loop on its own generated commit.

## Runtime binary resolution

`defaultLeanKernelProviderBinary()` becomes package-aware and platform/architecture-aware.

Resolution order:

```text
1. PSC_LEAN_KERNEL_PROVIDER_BIN explicit override
2. bundled prebuilt binary for process.platform + process.arch
3. source-checkout Lake binary, development fallback only
4. fail closed with unsupported/missing-provider error
```

The environment override remains first so developers and assurance jobs can deliberately select another provider build.

The bundled path must be derived from `import.meta.url` / package root, not the caller's current working directory.

The source-checkout fallback exists only to preserve development ergonomics before/while generating prebuilts. An installed npm tarball must not rely on this fallback.

Before executing a bundled binary, the Node adapter validates its target manifest entry and SHA-256. If the file is missing or the digest differs, it fails before spawning the executable.

## Unsupported target behavior

An unsupported platform/architecture pair fails explicitly, for example:

```text
@proofscript/pskernel-lean@4.34.0 has no bundled provider for win32-arm64
supported targets: linux-x64, linux-arm64, darwin-x64, darwin-arm64, win32-x64
```

Do not silently run an executable for a different architecture, invoke Rosetta/WOW emulation, download an artifact from the network, or fall back to an unpinned system Lean executable.

The caller may still supply `PSC_LEAN_KERNEL_PROVIDER_BIN` explicitly when intentionally testing a custom provider.

## npm package surface

`package.json` must include the prebuilt manifest and all five prebuilt target directories in its published `files` surface.

The package remains:

```text
name: @proofscript/pskernel-lean
version: 4.34.0
private: false
```

No install/postinstall script downloads or compiles the provider. Installation is side-effect-free.

`npm pack` is the release-reality test. Tests must inspect the generated tarball and prove it contains:

- public JS entry point;
- host adapter files required at runtime;
- `LEAN_SOURCE_PIN.json`;
- `PREBUILT_MANIFEST.json`;
- exactly the five supported native provider binaries;
- no `.lake` build tree;
- no entire Lean toolchain;
- no unintended provider source/build artifacts outside the declared package surface.

## Packed-tarball platform tests

Every supported native runner must test the packed package artifact, not merely the source checkout.

For each target:

1. install the generated `@proofscript/pskernel-lean-4.34.0.tgz` into a fresh temporary Node project;
2. ensure `PSC_LEAN_KERNEL_PROVIDER_BIN` is unset;
3. import `@proofscript/pskernel-lean` by package name;
4. assert the resolver chooses the bundled target path;
5. recompute/validate the binary digest;
6. run `checkCanonicalAdmissions` with a valid request and require `accepted: true`;
7. run the semantic-invalid fixture and require `accepted: false`, `errorKind: kernel-rejection`;
8. prove no `lean` or `lake` invocation is required by the consumer path.

The Linux x64 package test additionally remains integrated with the existing generated PSC2 compiler/CLI smoke.

## Security and trust boundary

Bundling changes distribution, not semantics.

The trusted semantic decision still comes from the same Lean 4.34 checked kernel provider. Prebuilt files do not create a new unchecked admission path.

The package validates:

```text
package metadata
    + PREBUILT_MANIFEST digest
    + provider protocol identity
    + Lean version
    + exact Lean commit
    + provider profile
```

before treating a provider result as valid.

A checksum mismatch, unsupported target, missing binary, process crash, malformed output, version mismatch, or provider-identity mismatch is a hard failure, never an acceptance.

Code signing/notarization may be added later for public distribution. It is not required to merge the first repository-bundled native milestone, but macOS/Windows release documentation must not claim signed/notarized binaries until such signing actually exists.

## Bootstrap isolation

`@proofscript/pskernel-lean` remains a normal npm workspace and optional host dependency, but it remains forbidden from the portable fixed-point closure.

The following remain true:

```text
packages/compiler      -> no dependency on pskernel-lean
packages/backend-ts    -> no dependency on pskernel-lean
packages/bootstrap     -> no dependency on pskernel-lean
packages/cli           -> optional host dependency allowed
```

The binary directories and manifest are distribution assets only. They must not appear in PSC source closure scanning, canonical compiler IR, or fixed-point bootstrap evidence.

## Testing layers

### Resolver unit tests

Test all five supported `(platform, arch)` pairs plus unsupported examples, explicit environment override, missing artifact, corrupted checksum, and source-checkout fallback.

### Manifest contract tests

Require exact target set, exact package/version/protocol/Lean identity, package-relative safe paths, unique artifacts, valid SHA-256 syntax, and digest agreement with repository files.

### Native provider tests

Run health plus positive/negative semantic fixtures independently on all five native runners.

### Packed npm tests

Install and execute the `.tgz` on each native target with no runtime Lean/Lake dependency.

### PSC2 integration tests

On the primary Linux x64 integration runner:

```text
real generated PSC2 compiler
    -> canonical admissions
    -> installed/bundled @proofscript/pskernel-lean
    -> real Lean kernel
    -> accepted
    -> TypeScript emission
```

A kernel-rejected case must stop before emission.

### Bootstrap regression

Existing closure/workspace/bootstrap tests must continue to prove that prebuilt distribution does not become a fixed-point dependency.

## Merge gate

Do not merge `psc2/pskernel-lean-provider` into `psc2/minimal-selfhost-psc15` merely because the provider package or the binary matrix is individually green.

The merge gate is all of the following:

1. native provider semantic tests are green;
2. all five native build jobs are green;
3. all five packed-tarball consumer jobs are green;
4. manifest/digest/package-surface tests are green;
5. `psc check --kernel lean434` works through the bundled package path;
6. accepted `psc build --kernel lean434` emits output and rejected builds do not;
7. bootstrap isolation is green;
8. the real generated PSC2 compiler kernel smoke is green;
9. the feature branch is synchronized with a base revision whose fixed-point/self-host gates are green;
10. no known RED experiment from the moving base is carried into the merge;
11. final branch verification is run after the last synchronization/rebase/merge from the base.

At the time this design was written, the provider/package tests are green but the broader branch workflow is blocked later by the concurrent `psExprAppViewAcc` structural-recursion RED gate in PSC2 self-hosting. That unrelated RED gate must have a corresponding GREEN fix before this provider branch is merge-ready.

WASM is explicitly not a merge prerequisite. `@proofscript/pskernel-lean-wasm@4.34.0` is a separate later milestone using the same provider protocol.

## Release gate

Merging to the PSC2 development/base branch and publishing to npm are separate decisions.

A future npm publish additionally requires:

- verified package ownership/authentication;
- final `npm pack` inspection;
- published-version immutability check;
- release notes identifying supported targets;
- checksums recorded in release metadata;
- no claim of code signing/notarization unless those processes have run.

This design does not publish the package automatically.

## Non-goals

This milestone does not:

- add Windows ARM64 support without an official/pinned Lean 4.34 toolchain path;
- build the WASM provider;
- make the PSC2 compiler core depend on Lean;
- add runtime network downloads;
- compile the native provider during `npm install`;
- introduce platform-specific npm packages;
- add formal equivalence claims between PSC and Lean;
- modify the copied Lean `kernel/`, `runtime/`, or `util/` semantics merely for packaging convenience;
- require merge while the parent PSC2 self-host branch is knowingly RED.

## Future extension: WASM

The later WASM package should preserve the provider contract and Lean-version semver rule:

```text
@proofscript/pskernel-lean-wasm@4.34.0
```

It should consume the same canonical admissions protocol and produce the same result envelope. Native and WASM providers should eventually run a shared conformance corpus and require the same accept/reject decisions.

WASM distribution is not allowed to alter the native package's trust semantics or become a prerequisite for the native provider merge.
