# PSCV0 V6 — Lean-native architecture

**Reference:** [THE_PSCV_COMPILER_REFERENCE_VERSION_6.md](THE_PSCV_COMPILER_REFERENCE_VERSION_6.md).
**Current implementation/reuse plan:** [v6/LEAN_NATIVE_REUSE_RESEARCH.md](v6/LEAN_NATIVE_REUSE_RESEARCH.md).

## Native implementation package ownership

| Source owner | Responsibility |
|---|---|
| v6/packages/core/src | Candidate Lean Core representation and immutable semantic contracts |
| v6/packages/extensions/src | Typed E0–E6 extension classes and closed-profile restriction |
| v6/packages/kernel/src | Lean 4.35-rc3 kernel declaration checking and small Lean 4.34 npm provider catalog; admission-only status |
| v6/packages/pskernel-lean | Full copied working Lean 4.34 native kernel npm provider |
| v6/packages/pskernel-lean-wasm | Full copied working Lean 4.34 Wasm kernel npm provider |
| v6/packages/cli/src | Native development executable and explicit unsupported stage errors |
| v6/test/lean | Native proof acceptance/rejection and policy smoke |
| v6/test/provider-oracles.test.mjs | External oracle test tooling for separately packaged Lean 4.34 native/Wasm kernel binaries |
| v6/lakefile.lean | Pinned native build and **research-only** old-source compatibility probes |

**Desired production spine, not yet implemented:** .ps source and profile -> deterministic parsing/name resolution -> typed elaborated Lean Core -> session-bound checked Core -> approved specification and .proof.ps/.proof.lean obligation closure -> PSCV certificate -> erasure -> validated RuntimeIR -> TS/direct JS/Wasm/Rust backend -> ArtifactBundle.

Compiler modules and executable feature implementations are .lean. npm package.json manifests describe their distribution, and compiled native artifacts are produced by Lean 4/Lake. Third-party feature packages cannot execute arbitrary JS or Lean code in the authority process; a future host must isolate native/Wasm workers and validate all outputs.

## Constraints

- Do not transplant old PSC1-selfhost-stable/1 grammar or handwritten low-level source styles as an implementation requirement. Self-host remains later optional work.
- Use Lean.Expr/Declaration/Environment as logical candidate representation; source-to-Core fidelity and execution preservation need separate evidence.
- Do not conflate Lean 4.34 pskernel-lean provider acceptance with the normative Lean 4.35-rc3 PSCV checker.
- No plugin-supplied axioms, unchecked elaborator, unsafe effect or fabricated certificate may make a false theorem valid.
- Import old Lean algorithm packages only after bounded capability extraction, semantic testing and actual value of reuse are demonstrated. Research-only Lake probe imports are not runtime dependencies.
- A native compiler binary need not bundle Lean frontend or Lake for users, but must package and audit its real Lean runtime dependencies.

## Stage boundaries

N0 native compilation and kernel/extension policy checks; N1 .ps source syntax; N2 checked Core; N3 RuntimeIR/erasure; N4 all four backends; N5 mixed proofs/verified certification; N6 native npm distributions and isolated feature runners; N7 assurance/performance and optional self-host. No implementation completeness is asserted before passing each gate.

## Kernel package adoption

V6's complete local copies of `@proofscript/pskernel-lean@4.34.0` and `@proofscript/pskernel-lean-wasm@4.34.0` are accepted as reusable provider implementations, without source refactoring at this checkpoint. Their original npm APIs and binary/source integrity manifests remain intact. The V6 architecture still requires provider-neutral checked-session composition, explicit 4.35 semantic compatibility before PSCV-v1 certification, and no implicit plugin or registry proof authority.

Other existing `.lean` algorithms may be reused selectively, including old parser, RuntimeIR, erasure and backends. The V6 reference rather than the historical self-host layout determines package boundaries.
