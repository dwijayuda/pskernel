# Full compiler support: C1 architecture and evidence guideline

Current operational priority: [actual module qualification](PSC1_MIN_KERNEL_MODULE_GUIDELINE.md).
The fresh matrix establishes 1/124 source closures Min-admitted and finite
Source runtime validation, with 0/124 fully compiler-qualified and no Min generations.
The first List declaration exposes absent parametric type semantics; prove that
model/refinement before enabling acceptance. R7/R8 are scoped-qualified and R9
is parked after the full generated packet timeout. The architecture research
below remains applicable, but its earlier inventory-only work order/counts
are superseded by the actual-module checkpoint.


Research snapshot: 2026-10-28. User target: usable checker, then full compiler
support. U1 is delivered. R7 is adopted at d356da768db4a7f31c3dc3293dab8dfe6dff41d5;
its candidate cff0d8f9fc02662ccff8fd74fa56492a2d2044ee passed
[focused Linux CI](https://github.com/dwijayuda/pskernel/actions/runs/40677181672).
The [completion contract](PSC1_MIN_KERNEL_USABILITY_PLAN.md) defines C1/C2/C3.
This document selects obligations and work order; it does not qualify a new
checker profile or claim that a model implementation exists.

All proof/build/compiler/test/resource execution stays on GitHub Actions Linux.
Continue using the user's GPT-6.1 Sol / High setting. Keep the
[R6 guideline](PSC1_MIN_KERNEL_R6_GUIDELINE.md), exact source identities,
nonforce expected-HEAD updates, protected base and draft/no-publish boundary.

## Current connected graph

The fresh complete Ps.CompilerUnified.Service census is unchanged at 124 modules,
2685282 source bytes, 4743 source Core members / 4748 logical members,
3466 records and 115 prelude declarations. Its source inventory SHA-256 is
2e2e1a9f0bd6bf4f1daf31995273162a5532dcd13a87f51c2cb9dd8fffe65f2e.
The canonical packet is 29889352 bytes. Retained evidence is in
artifact 12811084558 from the R7 candidate run, archive SHA-256
4253204f0dca2a969876457c7e4312b8601fc044bfadecb161f35e455f7af4b0.

The source graph contains 308 inductive groups, 982 constructors, 7167
projections, 12991 forall occurrences, 5955 lets and 8737 literals.
Observed source universe syntax uses parameters, successor and zero; these
counts do not prove dependent-binder or universe soundness. There are 60
foundational axiom declarations, with 35 directly referenced. All five
partial-body pairings remain:
psBackendPublicTypeSupported, psJsNeedsUtf8Runtime, psTsNeedsUtf8Runtime,
Ps.Internal.RustRuntimePlan.typeRequirements and
Ps.Internal.RustRuntimePlan.exprRequirements.

Coverage remains 0/124 and Practical Core 0/37. A later census must replace
these measurements if source identity changes. Test/proof-only roots do not
become compiler runtime roots.

## Upstream evidence and the trust decision

[Lean4Lean's paper, revision 3](https://arxiv.org/abs/2403.14064v3) separates an
executable checker, an abstract type theory and correctness of parts of the
implementation. Its executable coverage is not an end-to-end verification
claim for this project's compiler. The
[pinned Lean4Lean source](https://github.com/digama0/lean4lean/tree/67f63b0c818920dfaed2ad07ccff187a6a8fe1e3)
is a useful comparison, not an imported proof.
The [TYPES 2025 account](https://msp.cis.strath.ac.uk/types2025/abstracts/TYPES2025_paper31.pdf)
also distinguishes metatheory from program verification. Its LeanTT metatheory
includes the standard axioms; it does not discharge our current trust gate.

[ConLeche's maintainer README](https://github.com/leanprover/con-leche/blob/e3fd221f1e43826653e210ff725fb2cc3e0d93f0/README.md)
describes separate parsing, installation and checking phases, a fast parser
refined to a reference parser, and a direct model approach with additional type
comparisons. These are relevant design lessons. It accepts a different input
foundation and is not a drop-in replacement for PSC1's custom prelude.

Its [actual main theorem](https://github.com/leanprover/con-leche/blob/e3fd221f1e43826653e210ff725fb2cc3e0d93f0/ConLeche/MainTheorem.lean)
is conditional on SetTheory V. That file explicitly lists propext,
Classical.choice and Quot.sound as theorem dependencies. This observation is a
source audit; we have not built or independently reproduced its dependency
reports. Its [set-theory interface](https://github.com/leanprover/con-leche/blob/e3fd221f1e43826653e210ff725fb2cc3e0d93f0/ConLeche/SetTheory/Core.lean)
includes an infinite universe chain. The pinned
[toolchain](https://github.com/leanprover/con-leche/blob/e3fd221f1e43826653e210ff725fb2cc3e0d93f0/lean-toolchain)
matches Lean 4.35.0, but toolchain agreement supplies neither an adapter proof
nor compliance with this project's no-choice/no-quotient gate.

Decision: borrow the separation of model, reference algorithm, optimized
implementation and public-byte theorem. Do not import an upstream theorem,
checker or stronger assumption to label C1 complete. All new reports still
must be axiom-free or exactly propext-only. A statement conditional on an
uninhabited or unprovided semantic interface is an open obligation even if its
printed axiom list passes.

## C1 work order

| Stage | Required result | Completion evidence |
| --- | --- | --- |
| C1a representation | Indexed packed bytes, bounded cursor/state and expression/name/declaration arenas, refined to an independent mathematical model | Exact accepted bytes/records agree with the model; full compiler input is handled within the agreed resource limits |
| C1b scope | Ordered environment extension, uniqueness, bound/free reference discipline and capture-avoiding substitution | General invariants for all admitted syntax, with hostile duplicate/forward-reference and capture probes |
| C1c theory | A precisely bounded universe/dependent function model sufficient for the whole current graph | An inhabited semantic model within the existing trust policy, plus sound checking and substitution/conversion results |
| C1d declarations | Regular/mutual/nested carriers as required, constructors, positivity, recursor motives and projections | Model construction and exact implementation correspondence; recursor metadata cannot grant its own authority |
| C1e foundation | Every imported primitive has an explicit denotation and type/value contract | No arbitrary axiom admission; incompatible or missing contracts refuse |
| C1f source bodies | Correct linkage between all five logical declarations and actual partial runtime bodies | Exact pairing plus the required operational semantics; opaque logical admission alone does not qualify execution |
| C1g public closure | Entire current packet through the actual public byte API | No delegation, all records checked, exact graph identities and resource receipts |

Choose any bounds from the required syntax/features, not from a packet hash or
fixture identity. Refuse inputs beyond the proved domain. A finite universe
profile is only a proposal until its model, inhabitance and checker theorem
are implemented; declaring a bound is not a consistency proof.

C1a is a prerequisite for attempting the current 29.9 MB packet in practice.
R4B retains its 2 MiB/512-declaration limits and stable API. Its linked Nat-byte
representation already consumed roughly 300 MiB RSS on the 1.8 MiB connected
runtime. Do not just raise its limits. Select a packed representation with a
Linux decision experiment and prove its refinement before exposing a new
compiler profile. Keep original and checked bytes separate and preserve the
explicit one-final-LF transport rule.

## C2 and C3 connection

R7 handles real recursive literal and erased type/proof-let branches under
explicit eligibility. Its 264 cases are observations, not a general compiler
theorem. R8 is the independent substitution/source-semantics batch. Its fourteen
propext-only reports passed at candidate cf947745; adopted-source qualification
is still pending. Neither changes C1 coverage.

Continue C2 with actual runtime binders and aligned environments, telescope
omission, freshness, closures/calls, carriers and emitted-target semantics.
Syntactic substitution refinement does not establish typed substitution,
classifier soundness or call-by-value preservation. State these separately.

Only after C1 and C2 are satisfied should C3 count actual min-checked G1/G2/G3
and practical installed compiler workflows. Official Lean Wasm remains default.
Production min/dual continue PSC1_MIN_CANONICAL_BRIDGE_UNPROVED. No model-class
premise, external checker verdict, test corpus, fixture hash or producer flag
can substitute for the missing public minimal admission.

## Batch gate

For each semantic change, specify the supported domain and independent model
first; register explicit roots; print each new theorem dependency exactly once.
Preserve all earlier trust guards, 10/10/20 minute focused budgets and 256 MiB
old-space limit. Do not add sorryAx, choice, quotient, new axioms or unsafe
admission. Review the exact production diff before adoption.

Retain native and actual generated evidence, independently check exact source
packets, measure the entire connected graph and rerun selected broader Linux/
installed CLI gates at the final source. Distinguish failed, superseded,
candidate-qualified, adopted-source-qualified and report-only runs. Update
the completion contract and draft PR with the final scope, and keep full
compiler support open until C1, C2 and C3 all satisfy their contracts.
