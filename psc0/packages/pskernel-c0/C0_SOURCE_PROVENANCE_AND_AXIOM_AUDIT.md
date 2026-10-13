# PSKernel-C0 — Source Admission Provenance and Audited Assumptions

**Date:** 2026-10-14 · **Lean pin:** 4.35.0 · **Branch:** `perf/pskernel-c0-v7-rust-20261012`

**Status:** implemented source-checked history and explicit ordinary-axiom allowance; the latest
mathematical-membership and publication tests must complete native CI before
that exact executable checkpoint is declared qualified.

## 1. Source admission history

A source-checking receipt must not be fabricated from an arbitrary environment
snapshot. `Architecture/TrustedAdmission.lean` introduces:

* `PsKernelC0SourceAdmissionStep before` — the original certified work, full
  source declaration request, fuel, certified successor work, and a **Lean
  equality proof** that `psKernelC0ArchitectureAdmit` returned precisely the
  certified successor.
* `PsKernelC0SourceEnvironmentHistory env` — an indexed inductive type with
  only canonical empty-environment genesis and exact source-admission step
  constructors.
* `PsKernelC0TrustedSourceWork` — immutable certified indexed store/work
  and a history indexed by the **exact current source environment**.
* `TrustedSourceBegin`, `TrustedSourceAdmit`, and source-authoritative
  WHNF/infer/check/DefEq — advance checking state without weakening or losing
  environment provenance.
* `TrustedSourceStage`, `TrustedSourceCommitChecked` — validate changed
  indexed syntax; return exact owner-bound source checked results only after
  all closed roots satisfy source closure, allowed universes and full checking.

The dependent exact-store and exact-work ownership certificates let the
checked environment proof survive staging without comparing large environments
at runtime. Candidate reduction remains optional, and neither syntax
certification nor type inference alone can admit a declaration.

## 2. Ordinary-axiom audit

A source checker can correctly *admit an axiom* without proving it. Thus
successful source admission is **not** by itself a consistency proof.

`Architecture/AuditedAssumptions.lean` adds an opt-in audited profile:

* Extract ordinary axiom names directly from the immutable source admission
  history, not from guessed environment names.
* Require the **mathematical proposition** `List.Forall (fun name => name ∈
  allowedAxioms) historyOrdinaryAxioms`. Membership uses derived, computable
  structural equality of full source names, including numeric components
  and Unicode string segments.
* Preflight every ordinary axiom declaration against the explicit allowlist;
  source checking still decides whether an allowed declaration is valid.
* Revalidate the whole assumption-history property after admission and
  source-checker state updates; failed authorization produces **no successor**.
* Allow legitimate source definitions and all source-checked queries without
  silently changing the list of assumptions.
* Stage and publish checked source roots only after the original kernel's
  full closed-root checks. An allowlisted assumption cannot authorize an
  ill-typed term.

The audit intentionally **does not** claim full trusted-foundation coverage:
built-in Quot primitives (including their semantic axioms), imported
packages, any special propext treatment, axiom dependency closure and other
trusted external capabilities need separate pinned manifests, explicit review,
and formal assurance. A user-supplied allowlist is an authorization of
assumptions, not a derivation of the associated propositions.

## 3. Native conformance gates

Mandatory source-regression files:

* `test/C0TrustedAdmissionRegression.lean`: empty genesis, two successive
  source-checked declarations, exact admission equation witness, source
  inference/Check/WHNF/DefEq preserving history, syntax stage, valid and
  invalid checked publication, duplicate/ill-typed atomic rejection.
* `test/C0AuditedAssumptionsRegression.lean`: disallow unapproved axiom,
  allow one explicitly named axiom with source checking, preserve exact
  names in the history, reject duplicate and second unapproved axiom, reject
  a nested Unicode/numeric identifier not on the allowlist, refuse narrowed
  policy for already admitted axioms, preserve audit through checked source
  queries and reject unbound staged roots.
* Existing canonical store and certified-work tests: immutable whole-index
  replay validation, mathematical StoreWF properties, provably unique
  canonical IDs, structural cross-store expression equality, exact source
  checker receipts, and all-or-nothing publication.

The latest native workflow must pass Lean 4.35 compilation, official
same-byte positive/negative export replays, these source/assumption tests,
malformed-input and negative conformance, microbenchmarks, and the original
checker comparison. Earlier *bounded* source-history steps passed
[CI 38480177560](https://github.com/dwijayuda/pskernel/actions/runs/38480177560)
and CI integration
[38480283729](https://github.com/dwijayuda/pskernel/actions/runs/38480283729).
Stage/source-judgment provenance passed
[38481180022](https://github.com/dwijayuda/pskernel/actions/runs/38481180022).
The revised exact-name **axiom policy** still requires full current native CI
qualification.

## 4. Critical unfinished acceptance requirements

* Phase C: prove complete persistent/scratch StoreWF, readback/encoding
  refinement and owner-scope invariants for the selected execution engine.
* Phase D/E: independent optimized WHNF/DefEq/inference semantics and one
  fully qualified accepting kernel; the current admission-history receipts
  are still based on the original trusted source checker.
* Phase B: complete Lean 4.35 Init, Std and Mathlib real acceptance, including
  the preserved first false rejection at record 86,383.
* Phase F: matched fully checked corpus benchmarks against Lean, con-leche,
  con-ron and original C0, with time/memory/error metrics.
* Phase G: actual kernel and optimized representation soundness/refinement
  theorems, axiom coverage, assumption transparency and consistency under
  explicit foundations.

No original `pskernel-core`, PSC0 compiler, Rust/Wasm, or self-hosting
implementation is changed by this milestone.
