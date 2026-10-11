import PSKernelFast.Spec.PropPi

/-!
P1e proof-point REPRESENTATION STUDY, under explicit SetTheoryBasis V.

CRITICAL DISCOVERY: the current P1d candidate true proposition is
powerset(empty) = {empty}. Its unique possible "proof point" is the
empty set, which is ITSELF a member of the old two-valued Prop carrier.
The intended Lean proof-irrelevant model needs the proof point to be
DISTINCT FROM the values interpreting propositions. This file PROVES
the obstruction instead of hiding it.

A second, separate candidate uses a singleton proof point, a singleton
true proposition containing it, and the powerset of that singleton as
Prop. We PROVE the candidate point belongs to True but not to Prop,
and that Prop still has precisely two members and lies in Type1.
This is a necessary but NOT SUFFICIENT condition for full soundness:
the selected simple point may still collide with writable numeral,
pair/graph or quotient encodings. Con-leche uses a more elaborate tag.
We do not change runtime kernel code or promote the second candidate
to the official Sort 0 interpretation at this research checkpoint.
-/

namespace PSKernelFast.Spec

universe u

/--
OLD CARRIER BLOCKER: every member of the P1d "true proposition"
is itself a proposition truth VALUE, because the only member of
powerset(empty) is empty and empty belongs to the old carrier.
Therefore no point outside Prop can inhabit True in that model.
-/
theorem old_true_forces_truth_value (V : Type u) [SetTheoryBasis V]
    (proofPoint : V)
    (hPoint : SetTheoryBasis.Mem proofPoint (propTrue V)) :
    SetTheoryBasis.Mem proofPoint (sortSet V 0) := by
  have hPower : SetTheoryBasis.Mem proofPoint
      (SetTheoryBasis.powerset (SetTheoryBasis.emptySet V)) := by
    simpa [propTrue] using hPoint
  have hEq : proofPoint = SetTheoryBasis.emptySet V :=
    (powerset_empty_exact V proofPoint).1 hPower
  subst proofPoint
  simpa [sortSet] using (propFalse_mem V)

/-- Regularity rules out any set being a member of itself. -/
theorem set_not_member_self (V : Type u) [SetTheoryBasis V] (x : V) :
    ¬ SetTheoryBasis.Mem x x := by
  intro hSelf
  let s : V := SetTheoryBasis.pair x x
  have hIn : SetTheoryBasis.Mem x s :=
    (SetTheoryBasis.member_pair).2 (Or.inl rfl)
  obtain ⟨y, hy, hMinimal⟩ :=
    SetTheoryBasis.regularity s ⟨x, hIn⟩
  have hEq : y = x := by
    rcases (SetTheoryBasis.member_pair).1 hy with ha | hb
    · exact ha
    · exact hb
  subst y
  exact hMinimal ⟨x, hSelf, hIn⟩

/--
A small distinguishable proof point for the SEPARATION experiment.
It is not claimed disjoint from Lean writable tuple/quotient encodings.
-/
noncomputable def proofPointTagV2 (V : Type u)
    [SetTheoryBasis V] : V :=
  SetTheoryBasis.powerset (SetTheoryBasis.emptySet V)

noncomputable def proofPointV2 (V : Type u)
    [SetTheoryBasis V] : V :=
  SetTheoryBasis.pair (proofPointTagV2 V) (proofPointTagV2 V)

noncomputable def propTrueV2 (V : Type u)
    [SetTheoryBasis V] : V :=
  SetTheoryBasis.pair (proofPointV2 V) (proofPointV2 V)

noncomputable def propUniverseV2 (V : Type u)
    [SetTheoryBasis V] : V :=
  SetTheoryBasis.powerset (propTrueV2 V)

/-- The proof point is a member of the new "true" truth value. -/
theorem proofPointV2_mem_true (V : Type u) [SetTheoryBasis V] :
    SetTheoryBasis.Mem (proofPointV2 V) (propTrueV2 V) :=
  (SetTheoryBasis.member_pair).2 (Or.inl rfl)

/--
THE SEPARATION INVARIANT: the point is NOT itself any truth value in
the revised two-valued Prop carrier. If it were a subset of its true
singleton, its own member/tag would equal the point, making the point
a member of itself, contradicting regularity.
-/
theorem proofPointV2_not_prop (V : Type u) [SetTheoryBasis V] :
    ¬ SetTheoryBasis.Mem (proofPointV2 V) (propUniverseV2 V) := by
  intro hPointInProp
  have hSub :=
    (SetTheoryBasis.member_powerset).1 hPointInProp
  have hTagInPoint : SetTheoryBasis.Mem
      (proofPointTagV2 V) (proofPointV2 V) :=
    (SetTheoryBasis.member_pair).2 (Or.inl rfl)
  have hTagInTrue : SetTheoryBasis.Mem
      (proofPointTagV2 V) (propTrueV2 V) :=
    hSub (proofPointTagV2 V) hTagInPoint
  have hTagEqPoint : proofPointTagV2 V = proofPointV2 V := by
    rcases (SetTheoryBasis.member_pair).1 hTagInTrue with ha | hb
    · exact ha
    · exact hb
  rw [hTagEqPoint] at hTagInPoint
  exact set_not_member_self V (proofPointV2 V) hTagInPoint

/-- False belongs to the revised two-truth-value Prop universe. -/
theorem false_mem_propV2 (V : Type u) [SetTheoryBasis V] :
    SetTheoryBasis.Mem (SetTheoryBasis.emptySet V) (propUniverseV2 V) := by
  apply (SetTheoryBasis.member_powerset).2
  intro z hz
  exact False.elim (SetTheoryBasis.not_member_empty V z hz)

/-- True belongs to the revised two-truth-value Prop universe. -/
theorem true_mem_propV2 (V : Type u) [SetTheoryBasis V] :
    SetTheoryBasis.Mem (propTrueV2 V) (propUniverseV2 V) := by
  exact (SetTheoryBasis.member_powerset).2 (fun z hz => hz)

/-- The revised True carrier is not empty, hence the values differ. -/
theorem trueV2_ne_false (V : Type u) [SetTheoryBasis V] :
    propTrueV2 V ≠ SetTheoryBasis.emptySet V := by
  intro h
  have hh : SetTheoryBasis.Mem (proofPointV2 V)
      (SetTheoryBasis.emptySet V) := by
    rw [← h]
    exact proofPointV2_mem_true V
  exact SetTheoryBasis.not_member_empty V (proofPointV2 V) hh

/--
Prove the revised Prop carrier has EXACTLY two truth values, despite
changing the chosen point. This is derived from singleton membership,
set extensionality and empty-set non-membership.
-/
theorem propUniverseV2_exactly_two (V : Type u)
    [SetTheoryBasis V] (x : V) :
    SetTheoryBasis.Mem x (propUniverseV2 V) ↔
      x = SetTheoryBasis.emptySet V ∨ x = propTrueV2 V := by
  constructor
  · intro hx
    have hSub := (SetTheoryBasis.member_powerset).1 hx
    by_cases hHas : ∃ z : V, SetTheoryBasis.Mem z x
    · obtain ⟨z, hz⟩ := hHas
      have hzInTrue := hSub z hz
      have hzPoint : z = proofPointV2 V := by
        rcases (SetTheoryBasis.member_pair).1 hzInTrue with ha | hb
        · exact ha
        · exact hb
      have hPointInX : SetTheoryBasis.Mem (proofPointV2 V) x := by
        simpa only [hzPoint] using hz
      right
      apply SetTheoryBasis.ext
      intro y
      constructor
      · intro hy
        exact hSub y hy
      · intro hy
        have hyPoint : y = proofPointV2 V := by
          rcases (SetTheoryBasis.member_pair).1 hy with ha | hb
          · exact ha
          · exact hb
        have hRaw : SetTheoryBasis.member
            (proofPointV2 V) x := hPointInX
        simpa only [hyPoint] using hRaw
    · left
      apply SetTheoryBasis.ext
      intro z
      constructor
      · intro hz
        exact False.elim (hHas ⟨z, hz⟩)
      · intro hz
        exact False.elim (SetTheoryBasis.not_member_empty V z hz)
  · intro h
    rcases h with hFalse | hTrue
    · subst x
      exact false_mem_propV2 V
    · subst x
      exact true_mem_propV2 V

/-- The singleton of a universe member is again a member of that universe. -/
theorem universe_singleton_closed
    (V : Type u) [SetTheoryBasis V] (n : Nat) (x : V)
    (hx : SetTheoryBasis.Mem x (SetTheoryBasis.univ n)) :
    SetTheoryBasis.Mem (SetTheoryBasis.pair x x)
      (SetTheoryBasis.univ n) := by
  have hPower : SetTheoryBasis.Mem (SetTheoryBasis.powerset x)
      (SetTheoryBasis.univ n) :=
    SetTheoryBasis.universe_powerset_closed (V := V) n x hx
  apply SetTheoryBasis.universe_subset_closed (V := V)
    n (SetTheoryBasis.powerset x) (SetTheoryBasis.pair x x) hPower
  intro z hz
  have hzEq : z = x := by
    rcases (SetTheoryBasis.member_pair).1 hz with ha | hb
    · exact ha
    · exact hb
  subst z
  apply (SetTheoryBasis.member_powerset).2
  intro w hw
  exact hw

/--
The revised Prop carrier is also small enough to belong to Type 1.
This is derived from the supplied universe stage and *three* powerset/
singleton closure steps, not added as a new model axiom.
-/
theorem propUniverseV2_mem_typeOne
    (V : Type u) [SetTheoryBasis V] :
    SetTheoryBasis.Mem (propUniverseV2 V) (SetTheoryBasis.univ 2) := by
  have hChain : SetTheoryBasis.Mem
      (SetTheoryBasis.univ 1 : V) (SetTheoryBasis.univ 2) :=
    SetTheoryBasis.universe_step (V := V) 1
  have hEmpty : SetTheoryBasis.Mem
      (SetTheoryBasis.emptySet V) (SetTheoryBasis.univ 2) :=
    SetTheoryBasis.universe_subset_closed (V := V)
      2 (SetTheoryBasis.univ 1) (SetTheoryBasis.emptySet V) hChain
      (by
        intro z hz
        exact False.elim (SetTheoryBasis.not_member_empty V z hz))
  have hTag : SetTheoryBasis.Mem
      (proofPointTagV2 V) (SetTheoryBasis.univ 2) :=
    SetTheoryBasis.universe_powerset_closed (V := V)
      2 (SetTheoryBasis.emptySet V) hEmpty
  have hPoint : SetTheoryBasis.Mem
      (proofPointV2 V) (SetTheoryBasis.univ 2) :=
    universe_singleton_closed V 2 (proofPointTagV2 V) hTag
  have hTrue : SetTheoryBasis.Mem
      (propTrueV2 V) (SetTheoryBasis.univ 2) :=
    universe_singleton_closed V 2 (proofPointV2 V) hPoint
  exact SetTheoryBasis.universe_powerset_closed (V := V)
    2 (propTrueV2 V) hTrue

#print axioms old_true_forces_truth_value
#print axioms set_not_member_self
#print axioms proofPointV2_mem_true
#print axioms proofPointV2_not_prop
#print axioms false_mem_propV2
#print axioms true_mem_propV2
#print axioms trueV2_ne_false
#print axioms propUniverseV2_exactly_two
#print axioms universe_singleton_closed
#print axioms propUniverseV2_mem_typeOne

end PSKernelFast.Spec
