# PSCV0 — V6 Lean-native compiler workspace

**Current implementation direction:** All compiler and extension implementation code is written in Lean 4, with npm as a distribution system and Lean 4 native compilation as the initial executable backend.

## Start here

- [V6 Lean-native implementation](v6/) — new Lake build and npm source packages, compiled with pinned Lean 4.35.0-rc3.
- [Source-reuse research](v6/LEAN_NATIVE_REUSE_RESEARCH.md) — detailed audit of old Lean packages and precise reuse/rewrite decisions.
- [Core npm architecture and security policy](v6/CORE_NPM_ARCHITECTURE.md) — source authority, plugin constraints, native toolchain and evidence boundaries.
- [V6 architecture reference](THE_PSCV_COMPILER_REFERENCE_VERSION_6.md).
- [Normative PSCV language reference](PROOFSCRIPT_PSCV_LANGUAGE_REFERENCE.md) — language edition ps-0.9-r3 and verified pscv-v1 requirements.
- [Work state](AI_WORK_STATE.md) — latest implementation checkpoint, CI and open gates.

## Active V6 package implementation

The core, extension manifest policy and kernel candidate checker are Lean source files in v6/packages/{core,extensions,kernel}/src. The development CLI is v6/packages/cli/src/PscvDevMain.lean. Build the Lean-native development executable using the v6/lakefile.lean and version-pinned v6/lean-toolchain. The existing native/Wasm pskernel-lean@4.34 npm packages remain **separately pinned differential oracles**; the V6 semantic/build host uses Lean 4.35.0-rc3 and cannot silently claim compatibility with a 4.34 checker.

## Previous implementation

The original packages/, host/, scripts/ and associated tests remain physically in this source snapshot as reference/extraction material for syntax, erasure, RuntimeIR, target backends, WIT and diagnostics. **None is imported into the new trusted V6 core or CLI**, and none is a compatibility preservation requirement. Separate Lake targets may compile selected old Lean files as research-only reuse probes; those modules do not enter the production V6 executable. Delete replaced code later if desired, without weakening acceptance or rewriting history.

Legacy V1–V5.1 architecture and status documents are in [legacy/](legacy/).

## Current maturity

The native Lean build and small source-level proof/kernel tests work. No arbitrary .ps source compilation, PSCV-CERT, four target backends, verified .proof.lean bridge, isolated feature host or public native npm release is implemented by this P0.
