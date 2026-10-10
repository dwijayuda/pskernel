# PSC0 npm distribution — AI work state

**Architecture design checkpoint (2026-10-11):** [`PSC0-ARCH/1`](docs/PSC0_SOUNDNESS_SECURE_EXTENSIBLE_ARCHITECTURE.md) was committed at `18fae4c991098ea4ffb86c8796a9a97053529b7b` as a *design-only target*. No compiler/kernel implementation or proof acceptance changed. Follow P0/P1/P2 before asserting unified checked-emission or installed npm self-hosting. Preserve separate Lean 4.35 kernel-proof work. 

Repository: https://github.com/dwijayuda/pskernel
Branch: psc0/npm-modular-packages-v1
Base: psc0/selfhost-compiler-kernel-js-bundle-v1 @ 230a69d038c238347d3fe0de5de72f979fb98205
Historical source baseline on main: 748ee630e43ee1a89643cbc8cec3e31087788b08

## User intent
All maintained psc0/packages/* packages become publicly installable npm packages with the @proofscript scope, without -next suffixes.
Create a MINIMAL umbrella npm package proofscript containing psc executable and the qualified compiler closure + necessary JavaScript checker,
and two complete ZIP distributions: .ps sources and original .lean sources. Optional scoped npm tarballs live in each ZIP but are NOT globally installed.
User controls proofscript and @proofscript on npm. Do not publish automatically.

User subsequently directs: use generated JS PSKernel Core as the sole default checker;
Lean-WASM is an optional independent comparison provider, not an automatic fallback.
Fail closed on rejection, malformed terms, unsupported input, resource exhaustion, timeout, wrong identity and missing artifact.

## Implemented source structure
- 19 original npm package manifests normalized to @proofscript names; add experimental @proofscript/stdlib as a 20th optional scoped package.
- packages/proofscript adds minimal proofscript CLI metadata: 12 bounded self-host compiler packages + required JS checker; seven packages stay optional.
- npm-cli/psc.js supplies init, check, build, version and packages commands.
- npm-runtime/generated-core-provider.mjs processes canonical admission requests with explicit unsupported refusals.
- npm-runtime/core-cli.mjs runs the generated core behind a bounded, separate Node process.
- npm-runtime/core-checker.mjs validates exact generated JS, prelude and adapter SHA-256 values and refuses a mismatch.
- scripts/JointClosureInventory.lean exports structured canonical prelude types and names.
- scripts/npm-core-qualification.mjs compares positive and negative decisions with the independently pinned Lean-WASM checker.
- scripts/npm-distribution.mjs produces both npm source editions, all scoped tarballs, a minimal core-bundled root tarball and portable TS7 toolchain tarballs,
  runs isolated-cache offline global installation, Linux and Windows package tests, third-party library canaries and produces SHA-256 manifests.
- .github/workflows/psc0-npm-distribution.yml is the cloud-only release workflow.

## Recent scope change

User explicitly rejected default installation of all optional backends and providers. Core `proofscript` includes the 12 self-host compiler source-ownership packages `foundation`, `syntax`, `core`, `environment`, `meta`, `elab`, `bridge`, `compiler-ir`, `erasure`, `compiler`, `backend-ts`, `bootstrap`, plus the required `pskernel-core` JS checking runtime. This last component has bounded JS admission parity, not independently demonstrated joint self-hosting.

Opt-in packages: backend-js, backend-rust, backend-wasm, cli, pskernel-lean, pskernel-lean-wasm and source-only experimental stdlib.

Windows Node26 error was caused by Linux-bundled TypeScript 7 lacking `@typescript/typescript-win32-x64`. TypeScript is now deliberately UNBUNDLED so npm selects the correct platform binary. Both ZIPs include the exact TypeScript 7.0.2 and Linux x64 / Windows x64 binary tarballs for offline installation. The release includes a Windows Node26 consumer job; do not declare it passed until confirmed from GitHub CI.

Declarative third-party npm libraries are resolved from consumer `package.json` `proofscript.libraries`, with validated source roots, reserved trusted namespace `Ps`, and no execution of third-party JS by source resolution. Cloud end-to-end import canary required.

## Package model
The existing PSC0 bootstrap is monolithic self-hosted JS: @proofscript/compiler owns the compiled runtime.
Other scoped packages contain their original full source ownership tree and an importable JS facade over the shared compiler runtime.
Individual backend-js, backend-rust, and backend-wasm npm facades do NOT establish independent backend implementations.
Portable packages are translated to canonical .ps in the PS edition and retain original .lean source in the Lean edition.
The external pskernel-lean and pskernel-lean-wasm packages retain their actual native-language tooling assets; no invented .ps translations.

## Trust and assurance
JS Core default promotion is operational and qualification-gated. It does not prove formal kernel soundness,
model consistency, general JS backend semantic preservation, full Lean compatibility, or a joint compiler/kernel self-host fixed point.
Do not claim those stronger results or implicitly re-enable Lean-WASM as fallback.
The separate kernel metatheory workstream owns formal proof refinement.

## Acceptance criteria
1. Fully successful cloud build and provider differential gate.
2. Twenty optional/core scoped packages per edition, plus one minimal proofscript root package; only thirteen scoped packages globally installed by default.
3. Two ZIP archives with all scoped npm tarballs and the installable proofscript tarball.
4. Offline global tarball installation on Linux and Windows x64, actual psc check/build and a rejected ill-typed source in each edition, and third-party library imports.
5. Source-variant integrity and exact hashes recorded.

## Process
GitHub is canonical; inspect live HEAD and CI before any change. Preserve history and concurrent changes.
No local checkout or local builds. Do not automatically publish to npm. Keep this document synchronized with actual evidence.
