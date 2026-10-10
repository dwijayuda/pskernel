# PSC0 npm distribution — AI work state

Repository: https://github.com/dwijayuda/pskernel
Branch: psc0/npm-modular-packages-v1
Base: psc0/selfhost-compiler-kernel-js-bundle-v1 @ 230a69d038c238347d3fe0de5de72f979fb98205
Historical source baseline on main: 748ee630e43ee1a89643cbc8cec3e31087788b08

## User intent
All maintained psc0/packages/* packages become publicly installable npm packages with the @proofscript scope, without -next suffixes.
Create umbrella npm package proofscript containing psc executable and every compiler/kernel module,
and two complete ZIP distributions: .ps sources and original .lean sources.
User controls proofscript and @proofscript on npm. Do not publish automatically.

User subsequently directs: use generated JS PSKernel Core as the sole default checker;
Lean-WASM is an optional independent comparison provider, not an automatic fallback.
Fail closed on rejection, malformed terms, unsupported input, resource exhaustion, timeout, wrong identity and missing artifact.

## Implemented source structure
- 19 npm package manifests normalized to @proofscript names and public package metadata.
- packages/proofscript adds proofscript metapackage and global CLI metadata.
- npm-cli/psc.js supplies init, check, build, version and packages commands.
- npm-runtime/generated-core-provider.mjs processes canonical admission requests with explicit unsupported refusals.
- npm-runtime/core-cli.mjs runs the generated core behind a bounded, separate Node process.
- npm-runtime/core-checker.mjs validates exact generated JS, prelude and adapter SHA-256 values and refuses a mismatch.
- scripts/JointClosureInventory.lean exports structured canonical prelude types and names.
- scripts/npm-core-qualification.mjs compares positive and negative decisions with the independently pinned Lean-WASM checker.
- scripts/npm-distribution.mjs produces both npm source editions, generates scoped tarballs and a bundled umbrella tarball,
  runs offline global installation, positive and negative compiler tests, and produces SHA-256 manifests.
- .github/workflows/psc0-npm-distribution.yml is the cloud-only release workflow.

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
2. Twenty packages per edition, including proofscript global CLI.
3. Two ZIP archives with all scoped npm tarballs and the installable proofscript tarball.
4. Offline global tarball installation, actual psc check/build and a rejected ill-typed source in each edition.
5. Source-variant integrity and exact hashes recorded.

## Process
GitHub is canonical; inspect live HEAD and CI before any change. Preserve history and concurrent changes.
No local checkout or local builds. Do not automatically publish to npm. Keep this document synchronized with actual evidence.
