# @proofscript/pskernel-core

**0.1.0-checker.5 — private experimental dependent term-checker checkpoint.**

Regenerated with the current PSC seed, with all 264 baseline tests passing and
fresh build and reference evidence. See `../../docs/continuity/OWNED_KERNEL_REGENERATION_2026-10-02.md`.

This is the default checker and part of the joint bootstrap source closure.
The host adapter runs the generated semantic machine and fails closed outside
its supported fragment. Full bootstrap currently stops at the first inductive;
the default selection does not imply release readiness or complete Lean parity.

This package now executes an owned checking fragment, rather than data helpers
alone. It is **not the authoritative PSC2 kernel**, a full Lean-compatible
checker, a jointly self-hosted compiler/kernel, or a published npm release.

The public package export is still only immutable `kernelInfo`. The internal
machines check closed monomorphic terms with dependent function types, typed
lambdas, applications, lets and earlier admitted transparent definitions.
Conversion implements beta, zeta, transparent delta and alpha comparison, with
bounded universe normalization. Sequential internal admission starts empty,
rejects forward/self references and duplicates, and returns no environment on a
failed batch. The generated implementation is not edited by hand.

See **CHECKER.md** for supported judgments, critical limitations, the source and
runtime agreement tests, and the inherited defects repaired in this checkpoint.
The target architecture remains in ARCHITECTURE.md. FOUNDATION.md and
BINDING_UNIVERSES.md describe earlier checkpoints, not current release readiness.

## Execute the installed development package

The tarball contains the generated JavaScript, canonical PS, TypeScript, source,
tests and pinned evidence. It has no runtime dependencies or installation hooks.

```sh
npm test
npm run verify:build
npm run verify:evidence
npm run release:check  # Expected to FAIL: this is not a release candidate.
```

Rebuilds and optional external reference tests require **explicitly supplied**
executables matching manifests/TOOLCHAIN.json and TypeScript 5.8.3 on PATH:

```sh
PSC1=/absolute/path/to/pinned/psc1 npm run build
PSC1=/absolute/path/to/pinned/psc1 LEAN_PROVIDER=/absolute/path/to/pinned/provider npm run test:oracle
PSC1=/absolute/path/to/pinned/psc1 LEAN_PROVIDER=/absolute/path/to/pinned/provider npm run test:semantic-oracle
PSC1=/absolute/path/to/pinned/psc1 LEAN_PROVIDER=/absolute/path/to/pinned/provider npm run test:checker-oracle
LEAN_PROVIDER=/absolute/path/to/pinned/provider npm run test:level-differential
LEAN_PROVIDER=/absolute/path/to/pinned/provider npm run test:checker-differential
```

The reference provider is test-only. It never supplies the new implementation's
runtime answers. No seed, toolchain or fallback checker is downloaded by these
commands, installation or verification.

Publication, full compatibility and joint self-hosting gates remain closed.
Do not use this checkpoint as a trusted proof-certification boundary.
