# ADR 0007 — Hosted compiler implementation with PSCV source semantics

Status: Accepted by explicit user scope revision, 2026-10-08.

## Decision

The compiler continues toward the Version 5.1 architecture using
`PROOFSCRIPT_PSCV_LANGUAGE_REFERENCE.md` as its language authority. Self-hosting
is no longer an implementation goal. `PSC1-selfhost-stable/1` and
`PSC1-portable-selfhost/1` no longer restrict compiler implementation syntax.

`pscv-hosted-lean/1` is an implementation profile, not an accepted input language
or an assurance claim. The existing pinned Lean 4.34.0 host builds the compiler.
The PSCV reference retains its separate Lean 4.35.0-rc3 semantic pin. This decision
neither upgrades the host toolchain nor claims that the inherited PSC2 frontend
already implements the full PSCV profile.

The machine-readable decision is
`contracts/compiler/COMPILER_EXECUTION_POLICY_V1.json`. Language-authority and
TrustManifest checks bind it to the configuration, pins and architecture.
Compiler implementation may use facilities accepted by its pinned host while
preserving package ownership, production authority and exact artifact boundaries.

## What this supersedes

The prior V3/V5 execution requirement to write every portable compiler module in
PSC1 patterns, recompile changed compiler source with PSC1, and repeatedly
establish self-host fixed points is superseded as an implementation gate.
Historical specifications, profiles, scripts and evidence keep their original
meaning and exact identities. No historical success is silently applied to a
changed closure.

`npm run check` selects the hosted checks. Legacy checks remain explicitly
available through `check:legacy-selfhost`, `check:legacy-compiler-sources` and
the existing self-host commands. The main cloud workflow's manual
`legacy_selfhost` input enables its historical source/profile/whole-compiler
checks. The JS/Wasm fixed-point workflow is manual. The Rust workflow continues
to run its semantic and Cargo checks automatically, with compiler self-application
and fixed points behind the same explicit manual input.

## Preserved correctness requirements

Default validation still checks the pinned language reference, native compilation,
frontend behavior, strict RuntimeIR/target validation, erasure and specialization,
JS differential execution, Wasm execution, Rust compilation/runtime fixtures,
live production boundaries, resource failures and archive reconstruction.
Actual Lean proof slices remain scoped to what Lean checks.

The language reference sections 2, 30 and 32 retain their meanings:
approved specification coverage, mandatory proof closure, totality, permitted
effects/axioms, dependency closure and ghost/erasure safety are all required for
a `pscv-v1` verified executable. A successful host build or the existing
lowercase `pscv-cert/1` admission certificate is not `PSCV-CERT-v1` conformance.
Unsupported PSCV facilities remain unsupported; there is no semantic fallback.

Kernel implementation, provider internals and kernel metatheory remain externally
owned. Stable representations, explicit resources, ClaimSet policies, independent
checking and exact provenance remain V5 obligations. Selected future assurance
policies may require independent bootstrap/DDC evidence, but self-reproduction
is not a mandatory development loop.

## Consequences and next implementation work

This removes repeated compiler-self-application from the normal edit/validation
path without changing program acceptance or backend semantics. Existing good
compiler code is retained; relaxing its coding subset is not a reason to rewrite it.

Continue with real V5 producers and consumers: broader public signatures and
interfaces, complete toolchain input capture, persistent query/hermetic execution,
logical package APIs, isolated extension/AuthorityBroker execution, and real
ClaimSet checker adapters. Extensive formal and independent assurance remains a
separate later phase. Implementation, language conformance, preservation and
assured-release status remain incomplete.
