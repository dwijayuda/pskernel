# Public entry proof evidence — October 10, 2026

This is a narrowly scoped formal-methods proof checkpoint for PSKernel Core's own Lean 4.35.0-rc4 checker.

## Verified source

- Source commit: `63cdc22d339f821be6bdcfa25b5f15e936aafdbf`.
- [Focused GitHub Actions run 38071595259](https://github.com/dwijayuda/pskernel/actions/runs/38071595259), proof job 114269936326: **success**.
- 267 successful build jobs (222 focused), all 84 companion proof files, 323 explicitly audited semantic declarations, 153 model dependency modules (12 approved pure-mathematics modules), zero production-assurance or legacy judgment imports, 1,840 reference policy definitions with zero cached fallbacks, all seven native regression executables passed.
- Cloud proof dependency basis: only Lean host `propext`, `Classical.choice`, `Quot.sound` and explicit set-theoretic *theorem parameters*; no custom checker-soundness axioms.

## Exactly proved

`SemanticPublicEntry.lean` relates the production declaration's no-free-variable guard to numeric fresh-name bounds. It establishes the initial empty local frame and counter of the concrete checker session. First binder frame results for lambda, dependent product and let values retain explicit scope assumptions. The real public `psKernelKernelSessionEmpty` constructor returns the expected empty environment on success; the public checker constructor starts from the verified empty local frame.

These are **syntactic frame facts and conditional binder-entry results**. They do not constitute a model of the full initial environment, full soundness of the recursive checker, full declaration admission or an end-to-end consistency theorem.

## Compatibility and open proof boundary

Pinned official Lean: `c29b6dda4f7c20e3eeaa717c4e565663c5cfa364`.
Pinned Con Leche pure mathematics: `65e74db49e89ad2bbd1e90aa4f784954db41fa3a`.
The checker, source semantics, axiom policy and reference-versus-cached relation remain PSKernel's own proof obligations. The final theorem must be relative to explicitly modeled axioms; normal Lean accepts user-declared axioms as assumptions.

Historical broad [run 38070188607](https://github.com/dwijayuda/pskernel/actions/runs/38070188607) passed builds, proofs and bounded conformance but full Init and Std checker runs timed out; Mathlib was skipped. This is not full Lean parity. The focused proof workflow skipped standalone binary, Arena and fresh-export jobs.

The next proof step is to model the actual initial environment and maintain the same graded frame, selected annotations and semantic validity through the real infer/WHNF/DefEq recursion and complete admission transactions. See [proof-guided plan](PROOF_GUIDED_FULL_SOUNDNESS_AND_LEAN435_COMPATIBILITY.md).
