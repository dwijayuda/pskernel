# PSKernel-Fast P1j — Bounded Model Function-Graph Successor-Universe Closure

**Qualified proof-only slice; NOT full Type-valued Pi or general same-stage graph closure.**

## Exact verified evidence

- Branch: `research/pskernel-fast-clean-v3-20261011`.
- [Code/proof source `7dd6f175f57b3c091826c6e12391ada5139488dd`](https://github.com/dwijayuda/pskernel/commit/7dd6f175f57b3c091826c6e12391ada5139488dd), [**CI 38138084007**](https://github.com/dwijayuda/pskernel/actions/runs/38138084007), job `114466008004`: **SUCCESS**, official Lean 4.35.0-rc4 upstream `c29b6dda4f7c20e3eeaa717c4e565663c5cfa364`; **109 builds, 51 independent modules, 157 exact reviewed theorem assumption receipts**, no `sorryAx` and no new project set-theory axiom. Only the reviewed `propext`, `Classical.choice`, `Quot.sound` global axioms appear in qualifying prints; **ALL** graph results nevertheless rely on a separately supplied `[SetTheoryBasis V]` mathematical hypothesis.

## Proved from existing P1f set model encodings

[`Spec/GraphUniverseClosure.lean`](src/PSKernelFast/Spec/GraphUniverseClosure.lean):

- `modelOrderedPair_member_univ`: for an inhabited Grothendieck stage `univ n` and `a,b ∈ univ n`, the **specific P1f Kuratowski ordered pair** `{{a},{a,b}}` is in `univ n`. Constructed from the already *derived* model singleton closure and finite unordered pair closure; no trusted library closure axiom added.
- `modelGraph_member_successor_univ`: if `A ∈ univ n` and every value `F x` at an `x∈A` belongs to `univ n`, then `modelGraph F A ∈ univ(n+1)`. The proof first derives stage-n membership of every exact pair `(x,F x)`, hence the graph is a subset of `univ n`, and derives graph membership in the **NEXT** stage from `univ n ∈ univ(n+1)` and the stage's proven subset closure.

The extra rank is not an innocuous syntax artifact: **membership of the graph in `univ n` itself is NOT proved by this theorem**. This distinction matters for exact Lean dependent product universe levels and must not be erased by a "convenient" new model assumption or by falsely reclassifying `Type` ranks.

## What is still missing

- Typed semantic dependent function-space `Pi`, including function-family uniform bounds, Graph beta/app/eta and correct indexed Lean `imax/max` universe placement;
- Lambda interpretation for executable proof terms and source/model substitution, metadata/constant reduction;
- Typed quotient set representatives and writable-slot freshness: unrestricted images can collide with P1f's proof point, and universal quotient freshness is false;
- Constructed `SetTheoryBasis V` instance, model-preserving immutable environment/declaration fold and conditional `no_derived_False` capstone;
- Complete Lean 4.35 WHNF/DefEq, inductive/recursor checking, Mathlib and performance evidence.

**Next step:** study/prove a bounded dependent graph family with explicit source rank/representation, then exact Lean Type-valued Pi universe accounting. Avoid importing con-leche/con-ron results as PSKernel-Fast proofs or freezing runtime storage because the proof representation is convenient.
