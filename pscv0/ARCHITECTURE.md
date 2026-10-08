# PSCV0 V6 — clean core ownership

**Architecture target:** [THE_PSCV_COMPILER_REFERENCE_VERSION_6.md](THE_PSCV_COMPILER_REFERENCE_VERSION_6.md). **Working design and P0 npm implementation:** [v6/CORE_NPM_ARCHITECTURE.md](v6/CORE_NPM_ARCHITECTURE.md).

## Ownership model

~~~text
pscv0/v6/
  packages/extensions  # canonical data-only E0-E4 manifests, no plugin execution
  packages/kernel      # pinned native/Wasm Lean 4.34 provider selection and decision
  packages/core        # source/profile identity and kernel-admission composition
  packages/cli         # psc-core development CLI, not production psc
  test/                 # negative and provider-integration checks
~~~

**Target semantic pipeline (not yet implemented by P0):** .ps -> versioned grammar / elaborator -> typed Core -> exact provider-checked Core -> approved specifications and mandatory .proof.ps / optional .proof.lean obligations -> PSCV-CERT -> erased/validated runtime IR -> TS, direct JS, Wasm or Rust -> typed ArtifactBundle.

**Critical security separation:** untrusted npm feature packages must never import into the kernel/authority process; syntax and proof producers emit candidates for independent validation; semantic E5/E6 changes require explicit audited semantic revisions, not arbitrary npm plugin registration. A kernel-accepted declaration stream is not proof that a source .ps program was elaborated correctly or backend code preserves behavior.

**Toolchain pins:** present npm kernel providers run Lean 4.34.0. Normative PSCV uses Lean 4.35.0-rc3. Verified-profile completion requires a matching provider and standard-environment lock or independently verified compatibility. Self-hosting is not required for initial native releases.

## Previous implementation

Existing packages/, scripts/, host/ and other PSC2 work remain only until replacement/deletion can be done without incorrectly claiming finished functionality. The fresh v6/ implementation makes no imports from that code. The prior codebase is not being preserved as a constraint on parser design, implementation language choices, package structure, user UX or extension APIs. Existing proof/kernel providers are consumed through their **public npm interfaces**, not source-relative imports.

Read [legacy/V5.1](legacy/THE_PSCV_COMPILER_REFERENCE_VERSION_5.1.md) for historical evidence; it is not V6 implementation authority.
