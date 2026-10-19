# PSC1 PSKernel-Core Cross-Branch Correctness Port — 2026-10-20

## Scope and provenance

This branch is based on `psc1/direct-multibackend-v1` at `479f4c8b4d57a4f151f3b68a79a47779226b968e`, not on main.
It updates only `psc1/packages/pskernel-core` and kernel-specific qualification assets.
Lean pin is preserved at `leanprover/lean4:v4.34.0`; no target/backend policy is changed.

Source of the 17 changed core Lean modules:
`pscv/prove-pskernel-core-v1` at `85ccb4e1103d77ed77c09c5795fc48ae4ea8ea62`,
under `psc15selfhost/packages/pskernel-core/src/`.
The target and source had the same 79 Lean module paths; exactly 17 differing source
blobs were copied intact, so the executable kernel source now matches that dedicated
metatheory branch without mixing partial implementations.

## Confirmed and transferred corrections

- Binder-local scope exit restores parent semantic caches and preserves monotone
  fresh-name allocation; infer, WHNF, unfolding and DefEq caches cannot silently
  publish binder-local facts into the parent.
- FVar-dependent terms are excluded from unscoped semantic cache lookup and
  insertion, including positive and negative equality pairs.
- Universe normalization shifts every `max` arm before reconstruction instead
  of shifting the aggregate, avoiding non-Lean-equivalent offset handling.
- Constructor-field analysis and parameter checking preserve raw Pi binders
  instead of WHNF-erasing a constructor telescope.
- Mutual recursive-argument validation separates traversal budget from checker
  evaluation budget.
- Full-shape equality's structural cases are organized after the compatible
  binder/eta handling path rather than preempting it.
- String-position primitives and root environment-index bucket preservation
  follow the source branch fixes.

## C0 and additional branch findings / boundaries

Reviewed `perf/pskernel-c0-v7-rust-20261012`, its
`C0_PROOF_FINDINGS_AUDIT.md` and `C0_ARENA_NEGATIVE_RULES_2026-10-17.md`,
plus proof-guided `psc0/pskernel-core-lean435-arena-v1`.
C0's cache-scope findings agree with this port. C0's redesigned
Lean 4.35 implementation and its arena importer are **not** copied into
the Lean 4.34 PSC1 kernel: different APIs and safety/verification boundaries
make a file-level replacement unjustified. C0's extended constructor fuel
separation and recursor/unsafe-provenance changes remain individually reviewable,
not claimed to be transferred or qualified by this commit.

The historical metatheory `proofIrrelevanceAlgorithmic` judgment omits
typing premises. That defect belongs to the formal proof relation, **not**
a demonstrated false acceptance in this executable kernel; it is NOT imported.

## Validation and assurance policy

Source provenance is verified by exact blob SHA and subtree comparison.
Do not equate transplanting previously proved/tested corrections with
re-qualifying this exact PSC1 integration. Native PSC1 Linux CI must compile
the full source and run targeted positive and negative regressions before
this branch can be promoted. No unchecked admission, extra axiom, increased
fuel, or removal of a negative gate is authorized.
