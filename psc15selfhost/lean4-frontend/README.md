# PSCV → Lean 4 frontend (M0 experiment)

Status: implemented **Lean-kernel development bridge**, NOT a PSCV-verified frontend
and NOT a release-conformant PSCV compiler.

## Why this exists

The repository already implements a bounded PSC2 ProofScript parser and Lean
printer in packages/syntax/src/Ps/Syntax/Translate.lean and exposes psc emit-lean.
Rather than reproduce Lean's mature proof checker and native compiler, this
experiment uses that translator for the currently supported ProofScript syntax
and delegates native language compilation to exactly Lean 4.35.0-rc3.

This directory is intentionally **outside** the PSC1 self-host fixed-point
closure, the PSCV v5.1 execution workstream, and all owned-kernel packages.
It does not change those components, their interfaces, or their CI gates.

## Pipeline

~~~text
source.ps
  -> preliminary PSCV source-token guard (not a security/proof certificate)
  -> existing PSC2 source parser/Lean printer, hosted by Lean 4.34
  -> generated Lean module
  -> pinned Lean 4.35.0-rc3 parser/elaborator/typechecker/kernel
  -> [check / emit .lean] or [explicit UNVERIFIED development .c]
~~~

Lean 4.35.0-rc3 is pinned to commit:
470d5ce1400764999581fd26d5d72b00d990b0f4.

The mixed tools are intentional for the first experiment: the existing portable
PSC2 translator is currently bootstrapped under Lean 4.34, while the uploaded
PSCV verified profile pins Lean 4.35.0-rc3 as its semantic reference.
This bridge never asserts that 4.34 frontend semantics equal the PSCV profile.

## How to run

Requirements: Node.js 22+, elan, Lean 4.34.0, Lean 4.35.0-rc3, and Lake.

~~~sh
elan toolchain install leanprover/lean4:v4.34.0
elan toolchain install leanprover/lean4:v4.35.0-rc3
cd psc15selfhost
lake build psc
node lean4-frontend/psc-lean.mjs check lean4-frontend/test/Good.ps
node lean4-frontend/psc-lean.mjs emit-lean lean4-frontend/test/Good.ps --out /tmp/Good.lean
node lean4-frontend/psc-lean.mjs emit-c lean4-frontend/test/Good.ps --out /tmp/Good.c --development-unverified
node --test lean4-frontend/test/policy.test.mjs
~~~

The frontend checks that the invoked Lean kernel matches the **exact pinned
commit** using lean --githash. If it does not match, the command fails.
For an externally built PSC2 translator, set PSCV_LEAN_TRANSLATOR_BIN to the
absolute executable path. For a custom Lean executable set PSCV_LEAN_BIN.

A source with a forbidden top-level form, an unsupported PSCV feature, or an
ill-typed Lean lowering fails. The existing translator is permitted to reject
many valid future PSCV programs; there is no fallback to raw Lean source.

## Current feature boundary

Supported in this experiment: only source constructs currently accepted by
the existing PSC2 translator that can also be accepted by the pinned Lean
elaborator. Examples include bounded pure functions, ordinary calls, simple
data declarations, and some total theorems; there is no completeness claim.

Unsupported at this stage: normative PSCV given/requires/ensures contracts,
proof-producing VC generation, call-site VCs, verified effects, ghost state,
loop invariant/decreasing lowering, refined-type syntax, specification
coverage, deterministic frozen Standard registry parity, verified imports,
PSCV-CERT-v1, validated erasure, and compiler preservation proof.

The lexical preflight rejects obvious unsafe/partial/axiom/proof-hole and
unrestricted macro/Meta source spellings, but it **does not inspect imported
declarations or transitive theorem axioms**. Never treat its success as a
security, totality, or soundness guarantee.

## Assurance and emission boundary

- check: Lean has accepted the translated module; not PSCV verified.
- emit-lean: writes the checked Lean *source*; not a verified executable.
- emit-c: emits native compiler C source ONLY with an explicit
  --development-unverified flag; never carries PSCV verified status.
- There is **no** PSCV verified-executable emit command in this adapter.

The uploaded PSCV reference explicitly forbids verified executable emission
without approved specification coverage, exact checked obligations, trust and
effect closure, ghost/erasure safety, and a validated PSCV-CERT-v1. This
experiment preserves that distinction instead of pretending that Lean
typechecking alone proves an application's intended behavior.

Lean's native compiler does not itself provide ProofScript's direct
JavaScript/TypeScript/Rust/WebAssembly compiler backends.


## Direct Lean intrinsic verification reference

The separate test/LeanContractsPositive.lean fixture uses Lean 4.35.0-rc3's
native requires/ensures contract elaboration and auto-generated specification
theorem. The negative fixture demands an impossible postcondition and must
fail. These tests exercise the pinned Lean verification machinery as a
reference for later PSCV-VERIFY-v1 lowering. They do NOT mean the .ps source
frontend supports contracts, verifies imported axiom closure, or issues
PSCV-CERT-v1.

## Follow-on implementation slices

1. Implement PSCV-owned frontend syntax with a closed grammar, AST and exact
   source maps; lower into Lean Syntax/core without replacing Lean's kernel.
2. Reuse the pinned intrinsic Lean contracts/Std.WP/vcgen as proof producers;
   prove observationally equivalent PSCV-VERIFY-v1 lowering for each feature.
3. Enforce PSCV policy on elaborated declaration dependency and axiom closure
   (not just source spelling), including imported module identity.
4. Connect an approved specification identity, generated obligation closure,
   proof replay and explicit PSCV-CERT-v1 capability.
5. Only then enable certified emission, with a separate backend-preservation
   assurance level. Keep the current bridge's development output distinct.

The existing self-host PSCV compiler remains independent. This bridge is an
optional Lean-powered architecture experiment, not a replacement or a merge.
