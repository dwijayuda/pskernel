# ProofScript production architecture documents

**Status:** forward architecture guidance. These documents describe the intended long-term production shape of PSC2 and the migration path from the current self-host bootstrap. They are **not** claims that every described boundary, proof, sandbox, artifact format, or release control is implemented today.

## Authority and document roles

Keep these layers distinct:

1. `PSC2_COMPLETE_LANGUAGE_AND_JS_PLATFORM.md` — consolidated language/platform reference; the normative language specification remains the authority named by that document.
2. `ARCHITECTURE.md` — current minimal self-host architecture and bootstrap closure.
3. `docs/SELFHOST_SOURCE_STANDARD.md` — current compiler-source implementation discipline and executable self-host gates.
4. `docs/continuity/PSC2_NEXT_BOOTSTRAP.md` — forward continuity design for the next bootstrap generation and compiler-verification north star.
5. **This directory** — production architecture contracts, trust/security guidance, build/artifact model, and staged migration plan.

If a forward document conflicts with the current executable bootstrap contract, the current executable contract wins until an explicit reviewed migration changes it.

## Current checked-provider policy

For the present production-hardening phase, the default checked provider is `lean434-wasm` from `@proofscript/pskernel-lean-wasm`, pinned to Lean 4.34.0. Native `lean434` remains an explicit reference/oracle alternative and `pskernel-core` remains an explicit experimental alternative.

The long-term architectural target is still an owned `pskernel-core` authority. The provider-neutral checked-session boundary must make that future switch a kernel-provider migration rather than a change to erasure/backend semantics.

## Core rule

> Do not redesign the ProofScript semantic spine merely to gain production features. Harden the existing spine by making authority boundaries typed, versioned, capability-scoped, deterministic, and independently checkable.

The long-term semantic path is:

```text
source (.ps / supported Lean subset)
        |
        v
smart frontend: parse / resolve / Meta / elaboration
        |
        v
CandidateCore
        |
        v
pskernel-core
        |
        v
CheckedCore
        |
        v
erasure
        |
        v
ErasedIR / RuntimeIR
        |
        v
IR validator
        |
        v
VerifiedIR
   /       |         \
  v        v          v
JsIR     WasmIR      adapters
 |         |          Lean / Rust / TS
 v         v
.js       .wasm
```

The host/platform layer surrounds but does not redefine that semantic spine:

```text
InterfaceIR / FFI / capability worlds
package + module interfaces
incremental query graph
content-addressed artifacts
hermetic toolchains
lockfiles
release evidence / provenance
compiler service / LSP
```

## Document index

- [Production Architecture](PRODUCTION_ARCHITECTURE.md) — target package graph, semantic boundaries, backend composition, and production compiler-service shape.
- [Trust and Security Model](TRUST_SECURITY_MODEL.md) — trusted computing base, threat model, capability security, resource limits, kernel bridge, plugin sandboxing, and supply-chain defenses.
- [Build and Artifact Model](BUILD_ARTIFACT_MODEL.md) — canonical artifacts, domain-separated identities, incremental query graph, CAS, hermetic builds, separate compilation, lockfiles, and release evidence.
- [Compatibility and Contracts](COMPATIBILITY_CONTRACTS.md) — independently versioned contracts, runtime semantics/ABI, InterfaceIR, plugin API, package manifest, and fail-closed compatibility rules.
- [Platform and Extensibility Guide](PLATFORM_EXTENSIBILITY_GUIDE.md) — libraries-first growth, Meta/tactics, plugins, InterfaceIR/FFI, capabilities, async/resources, reflection, and solver boundaries.
- [Implementation Roadmap](IMPLEMENTATION_ROADMAP.md) — staged migration from the current architecture to the production shape without destabilizing the proven fixed point.
- [Design References](DESIGN_REFERENCES.md) — external compiler/build/security research and the specific ideas PSC should borrow.
- [GitHub-first Cloud Workflow](GITHUB_CLOUD_WORKFLOW.md) — canonical repository/branch workflow, checkpoint policy, no-force synchronization rules, and noncanonical local-state policy.
- [GitHub-first Migration Checkpoint](../continuity/GITHUB_FIRST_MIGRATION_2026-10-04.md) — audited local-state preservation record and archive-branch inventory for the workstation-to-cloud migration.
- [KernelContract-v1](contracts/KERNEL_CONTRACT_V1.md) — frozen provider-neutral checked-session request/decision/capability contract.
- [VerifiedIR validation v1](contracts/VERIFIED_IR_V1.md) — implemented ErasedIR → validated IR boundary and its current fail-closed runtime-type invariant.
- [RuntimeSemantics-v1](contracts/RUNTIME_SEMANTICS_V1.md) — frozen portable runtime behavior for primitives, arrays, records/ADTs, and closures; separate from target ABIs.
- [Experimental JsIR v0](contracts/JS_IR_EXPERIMENTAL_V0.md) — first direct-JavaScript target slice and TS→tsc differential promotion gates.
- [Architecture Decision Records](adr/README.md) — concise anti-drift decisions that future implementation work should preserve unless explicitly superseded.

## What these documents deliberately do not do

They do not:

- expand the required PSC2 source language merely for tooling convenience;
- make JavaScript, TypeScript, Rust, WIT, WASI, npm, or Lean semantics part of Core;
- move async, FFI, plugin permissions, package metadata, or release signing into the kernel;
- call `AdmissionReadyModule` a checked artifact before a real kernel provider admits it;
- treat a raw `PsVerifiedIrModule` construction value as validated merely because of its historical type name; production code must pass through `PsErasedIrModule -> psValidateErasedIrModule -> PsValidatedIrModule`;
- require every optimizer implementation to be formally proved when a smaller verified validator can establish the required refinement;
- replace existing fixed-point and regression evidence with documentation.

## External design references

These documents intentionally borrow principles rather than entire systems:

- CompCert — pass-by-pass semantic preservation, validators, separate compilation.
- CakeML — multiple semantic IRs, verified compiler bootstrap.
- rustc incremental compilation — dependency queries and red/green result fingerprints.
- Build Systems à la Carte — separate rebuild, scheduling, persistence, and dependency concerns.
- Bazel-style hermetic actions/CAS — explicit inputs, tool identities, cacheable deterministic actions.
- WebAssembly Component Model/WIT/WASI — typed interface contracts and capability-scoped worlds.
- Reproducible Builds — eliminate ambient nondeterminism.
- SLSA / in-toto — source/build provenance.
- Sigstore — public artifact signing/transparency.
- TUF — registry/update compromise resilience.
- Diverse Double-Compiling — trusting-trust provenance evidence.

These references are architectural inputs, not dependencies of PSC semantics.
