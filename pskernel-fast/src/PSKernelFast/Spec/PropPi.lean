import PSKernelFast.Spec.UniverseSemantics

/-!
P1d mathematical semantic operator for PROPOSITION-valued dependent Pi,
under the explicitly supplied set-theory model assumption.

The arguments are ALREADY-INTERPRETED semantic set values:
  A : V            -- domain set
  B : V -> V       -- set interpreting each codomain proposition

If all domain points have true fibres, the Pi proposition is true,
otherwise false. The output is one of the two constructed truth values.
No source expression is interpreted here, and proof irrelevance,
lambda/application membership, and positive Type-valued Pi remain open.
This may be used as a candidate component of an eventual genuine model,
but it is NOT a model for the whole six-rule PSKernel-Fast calculus.
-/

namespace PSKernelFast.Spec

universe u

/-- False and true truth values, built inside the supplied set theory. -/
noncomputable def propFalse (V : Type u) [SetTheoryBasis V] : V :=
  SetTheoryBasis.emptySet V

noncomputable def propTrue (V : Type u) [SetTheoryBasis V] : V :=
  SetTheoryBasis.powerset (SetTheoryBasis.emptySet V)

/--
A pure set-theoretic interpretation of IMPREDICATIVE proposition-valued
dependent products. Only this mathematical operator is defined; it
accepts no unchecked ProofScript/Lean syntax, frontend hints or axioms.
-/
noncomputable def propPi (V : Type u) [SetTheoryBasis V]
    (A : V) (B : V → V) : V := by
  classical
  exact if ∀ x : V, SetTheoryBasis.Mem x A → B x = propTrue V
    then propTrue V
    else propFalse V

/--
IMPREDICATIVE PROP-VALUED Π MEMBERSHIP: the product of ANY set-valued
domain and a family of semantic proposition results is still in Prop,
regardless of the domain's universe rank. This is derived by cases
from the explicitly constructed two-valued carrier; not an extra
set-model axiom.

For a meaningful *typed* term interpretation, the caller must later
prove A and every relevant B x denote the checked source domain/body.
-/
theorem propPi_member_prop (V : Type u) [SetTheoryBasis V]
    (A : V) (B : V → V) :
    SetTheoryBasis.Mem (propPi V A B) (sortSet V 0) := by
  classical
  by_cases hAll :
      ∀ x : V, SetTheoryBasis.Mem x A → B x = propTrue V
  · simpa [propPi, hAll, propTrue, sortSet] using (propTrue_mem V)
  · simpa [propPi, hAll, propFalse, sortSet] using (propFalse_mem V)

/--
Truth condition: the semantic Pi proposition is true IFF every
inhabitant of the semantic domain has a true proposition-valued fibre.
This is a genuine all-domain quantifier, not a sampled valuation.
-/
theorem propPi_true_iff (V : Type u) [SetTheoryBasis V]
    (A : V) (B : V → V) :
    propPi V A B = propTrue V ↔
      ∀ x : V, SetTheoryBasis.Mem x A → B x = propTrue V := by
  classical
  constructor
  · intro hProduct
    by_cases hAll :
        ∀ x : V, SetTheoryBasis.Mem x A → B x = propTrue V
    · exact hAll
    · have hFalse : propPi V A B = propFalse V := by
        simp [propPi, hAll]
      have hImpossible : propFalse V = propTrue V :=
        hFalse.symm.trans hProduct
      exact False.elim (propFalse_ne_true V hImpossible)
  · intro hAll
    simp [propPi, hAll]

/-- One false fibre at an inhabitant makes the whole Pi proposition false. -/
theorem propPi_false_of_counterexample (V : Type u) [SetTheoryBasis V]
    (A : V) (B : V → V) (x : V)
    (hDomain : SetTheoryBasis.Mem x A)
    (hFalse : B x ≠ propTrue V) :
    propPi V A B = propFalse V := by
  have hNotAll :
      ¬ ∀ y : V, SetTheoryBasis.Mem y A → B y = propTrue V :=
    fun hall => hFalse (hall x hDomain)
  simp [propPi, hNotAll]

/-- No third truth value can arise from the proposition-valued Pi. -/
theorem propPi_exact_truth_range (V : Type u) [SetTheoryBasis V]
    (A : V) (B : V → V) :
    propPi V A B = propFalse V ∨
      propPi V A B = propTrue V := by
  have h := (propUniverse_exactly_two V (propPi V A B)).mp
    (by simpa [sortSet] using (propPi_member_prop V A B))
  simpa [propFalse, propTrue] using h

#print axioms propPi_member_prop
#print axioms propPi_true_iff
#print axioms propPi_false_of_counterexample
#print axioms propPi_exact_truth_range

end PSKernelFast.Spec
