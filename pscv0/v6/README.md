# PSCV V6 — Lean-native compiler packages

**Status:** Initial Lean-native implementation foundation. Not a conformant PSCV compiler, a PSCV-certified executable, or a publicly published npm suite.

All compiler implementation and extension policy is written in **Lean 4**. A pinned Lean 4.35.0-rc3 compiler builds the native P0 tool. npm transports source modules and, later, per-platform prebuilt native tools. npm does not implement the compiler in JavaScript.

## References

- [Lean-native reuse research and migration](LEAN_NATIVE_REUSE_RESEARCH.md): existing Lean code inventory, reuse plan, package design, version tradeoffs and soundness risks.
- [V6 target compiler reference](../THE_PSCV_COMPILER_REFERENCE_VERSION_6.md).
- [Normative PSCV language reference](../PROOFSCRIPT_PSCV_LANGUAGE_REFERENCE.md): specifies .ps syntax and verified profiles. Lean is the implementation language, not the .ps grammar.
- [Core architecture and security criteria](CORE_NPM_ARCHITECTURE.md).

## Active Lean source packages

| Candidate npm package | Source | P0 capability |
|---|---|---|
| @proofscript/pscv-core | packages/core/src/Pscv/Core | typed candidate Core model using Lean.Declaration |
| @proofscript/pscv-extensions | packages/extensions/src/Pscv/Extensions | E0–E6 policy in Lean; no plugin code execution |
| @proofscript/pscv-kernel | packages/kernel/src/Pscv/Kernel | Lean 4.35 build-host kernel admission |
| @proofscript/pscv-cli | packages/cli/src | native development executable |

All four are **private development npm manifests** and ship Lean sources rather than handwritten compiler .mjs implementations. A future release will package compiled native executables and platform libraries. Node is optional for npm tooling, not necessary to run the native executable.

### Native build

From pscv0/v6 with the pinned Lean toolchain installed:

    lake build PscvCore PscvExtensions PscvKernel pscv_v6_dev pscv_v6_native_tests
    lake exe pscv_v6_native_tests
    lake exe pscv_v6_dev --version

Tests check a real logical identity theorem and reject an incorrect proof body, and enforce extension restrictions. Separate CI calls existing native/Wasm pskernel-lean 4.34 npm packages as **independent oracles**; their identities are not silently treated as the 4.35-rc3 checker.

### Not implemented yet

.ps frontend, source-to-Core fidelity, normative Standard manifest, .proof.ps/.proof.lean proof closure, PSCV-CERT, erasure, four backend packages, extension sandbox, release packaging, semantic preservation. The native development CLI rejects unsupported compilation.

There is no requirement to keep old PSC1/self-host source restrictions. Reuse existing Lean code selectively when it materially reduces work and preserves explicit correctness boundaries.
