# M3 recursor kernel signature correspondence — retained source annotations

Updated 2026-10-18. This is an unselected authoring correction awaiting its own
GitHub Linux evidence. M3+B and five-gate integration remain open.

## Fresh evidence supersedes the attached handoff

Fresh main is `33676076bcda7b0de5ec1f9803f49b8b1d28a058`, with Native
39099546592, M3 39099546513, F1 39099546493, F2 39099546574 and F3
39099546446 successful at that one SHA. PR #109 remains draft/open/unmerged
on its original base. Preparation was freshly `a8151133504f382096acc2720945635d583b8d96`.

For preparation run 39130764541, job 117685265070, fresh decoded logs report
all five source-copy positives and eight refusals passing, then
`regenerated metadata signature differs: Std.Format.rec`.
The current run-artifact API identifies artifact 12138202529, 2756552 bytes,
SHA256 `a3f17ab1d5ec43e465b3f79c5b7a54659b0ef6c06db822ffc22e3a8a1cd31333`.
The upload log matches these records and exact source SHA.

Those current records contradict the attached handoff's third-helper failure
and artifact 12138497681. Do not assert that the current helper drops a wrapper,
or invent a compiler/do-notation defect. The original helper's reconstruction
and its failure-only preservation guard are unchanged. A read-only Linux
inspection now authenticates the current archive bytes, exact job/attempt and
complete bounded recursor log; until observed, its independent hash check is
pending. The resolved earlier d0146eaf archive investigation remains historical
evidence and is not repeated.

## Pinned cause and correction

Lean 4.35.0 at `eb6cafb7290e8bd5f2937522d8d804f58f02bafc`:

- [kernel/inductive.cpp](https://github.com/leanprover/lean4/blob/eb6cafb7290e8bd5f2937522d8d804f58f02bafc/src/kernel/inductive.cpp):
  `mk_local_decl` and `mk_local_decl_for` consume head type annotations;
  constructor minor generation uses those locals to rebuild its Pi telescope.
- [Lean/Expr.lean](https://github.com/leanprover/lean4/blob/eb6cafb7290e8bd5f2937522d8d804f58f02bafc/src/Lean/Expr.lean):
  `consumeTypeAnnotations` removes head annotations and does not recursively
  normalize arbitrary logical terms.
- [Init/Prelude.lean](https://github.com/leanprover/lean4/blob/eb6cafb7290e8bd5f2937522d8d804f58f02bafc/src/Init/Prelude.lean):
  `optParam` is a safe identity definition with a retained source default.

The selected Std.Format recursor intentionally retains an optional minor-field
domain; the fresh official kernel's recursor contains its underlying type.
The previous generated-signature comparison required their raw alpha identity,
which cannot hold while preserving the selected wrapper.

A separate native-only comparison now requires BOTH:

1. Candidate type is alpha-identical to its frozen selected original, including
   every optional wrapper, default, bound index, constant and universe level.
   This check runs even when a stripped candidate would already equal the kernel.
2. The frozen original's checked optional-domain view is alpha-identical to the
   actual fresh kernel-generated signature.

Only head `optParam` wrappers of corresponding forall domains may be viewed
through. Their actual safe definition in the fresh replay environment must
beta-reduce exactly to the selected underlying type. Where both domains still
carry the annotation, defaults and levels compare as-is. No dictionary
projection normalization, arbitrary definitional equality, result/lambda-domain
erasure, other type-annotation admission or universe-profile expansion is added.

The view never changes exported expressions. Source annotation transfer,
its `annotated == selected` guard and exact binder-metadata tests remain.
Only `exportRecursorSurfaceCandidate` opts into this comparison with its
already fingerprint-checked frozen base. Every other Standard exporter retains
its original literal signature equality. Missing retained identities and
changed level-parameter lists refuse.

## Required controls and boundaries

The original two native rfl witnesses, five copy positives and eight refusals
remain unchanged. Three new signature positives and twelve refusals cover
nested minor domains, retained annotations, removed/changed wrappers/defaults/
levels, generated universes/indices/projections, unrelated types, forbidden
projection-defeq fallback and result/lambda-domain erasure.

Fresh trust-zero replay, complete layout, all generated signatures, symbolic
iota rules, proof/assumption closure, complete source metadata, 109-recursors/
24-public-differences inventory, six private formatter recursors and independent
digests all remain mandatory. A failure-only generated-signature JSON retains
the exact compared trees. No selected asset or fingerprint is changed.

The reviewed pending commit `5b9a2ecb292926d6503f51372632dd5cab559541` is
retained as the parent of this correction. Both its preparation jobs must pass
at the correction SHA. The archive-inspection workflow separately checks inert
evidence and grants no compiler qualification.

## Continuation

After both preparation jobs pass, review the entire emitted candidate and its
independently measured identities. Select only reviewed exact bytes at the final
frozen stage, preserving earlier authoring boundaries, Except's Type-0 profile
and the six compiler-owned helpers. Qualify real Nat/Except/Empty/False calls
through both input grammars and applicable runtime lanes. Then continue the
retained named/generalizing match design and the six M3+B exits. Main promotion
requires its own complete exact-SHA integration evidence.
