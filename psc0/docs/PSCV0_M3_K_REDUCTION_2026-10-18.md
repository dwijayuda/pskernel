# Predicate recursor computation through proof variables

Candidate, not qualified. Primary references at official Lean4.35.0
eb6cafb7290e8bd5f2937522d8d804f58f02bafc:
src/kernel/inductive.cpp init_K_target;
src/kernel/inductive.h to_cnstr_when_K and inductive_reduce_rec;
src/Lean/Meta/WHNF.lean toCtorWhenK and reduceRec.
Related tests: tests/elab/eqRecursors.lean, 2552.lean and
substWithoutExpectedType.lean. Upstream licensing is retained in notices.

The indexed-match change exposed a reduction capability missing from the
shared portable reducer. Equality transport may use an opaque theorem such as
eq_of_heq; the proof need not reduce to Eq.refl. Lean still computes when its
actual indices agree with the unique nullary proof constructor. Avoiding some
unneeded transports is useful, but cannot replace this computation rule,
especially while omitted result families are solved after branch elaboration.

The existing registered elimination plan already contains enough information
to derive the exact K eligibility condition: one public family/slot, Prop
result up to universe normalization, one constructor, and no fields.
No new trusted Boolean, special Eq name dispatch or serialized metadata is
required. For a typed recursor application, instantiate the actual constructor
and compare its resulting family/indices with the application's expected major
type. Reject unresolved indices and differing endpoints without assignment.
The existing read-only elimination equality may conservatively refuse harder
conversions; it never assumes an unproved index equality.

As ordinary iota, this reducer acts on typed Core and is not an alternate type
checker. Complete application inference and official kernel admission remain
mandatory. It does not establish validity of an ill-typed supplied proof.
Try the eligible constructor before reducing the proof, preserving native
computation and avoiding potentially expensive opaque proof unfolding.
All ordinary constructor and registered recursor shape checks remain.

Validation extends the existing match executable: independent native Eq/True
rfl controls; portable proof-variable computation with exact equations admitted
by the official kernel; unequal and unresolved index refusals. The retained
omitted-result riFixedIndexEq source assertion is unchanged. Main Native and
focused backend integration remain required before promotion claims.
