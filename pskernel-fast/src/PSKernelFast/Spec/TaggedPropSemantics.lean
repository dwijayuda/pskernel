import PSKernelFast.Spec.TaggedPointUniverse
import PSKernelFast.Spec.PropInterp

/-!
P1g: CANONICAL TAGGED PROPOSITION SEMANTICS (proof-only).

This is one coherent mathematical interpretation of the existing independent
PropInterpTerm language under P1f's proven tagged carrier, not a new runtime
checker or a renaming of the provisional P1d/P1e proposition value.

The older interpProp/sortSet/propPi remain available solely as historical
P1d/P1e witnesses; all NEW model proofs use this tagged interpretation.
The dependent Pi annotation/semantic-fibre boundary stays explicit.
SetTheoryBasis V is an externally supplied mathematical HYPOTHESIS; this
module does not construct such a model or admit any proof declaration.

Important nonclaim: distinguished taggedPoint noncollision is proved only
for the specified pair/graph/numeral/Prop encodings, not arbitrary quotients.
-/

namespace PSKernelFast.Spec

universe u

/-- Canonical P1g false value; its carrier is P1f's taggedProp. -/
noncomputable def taggedPropFalse (V : Type u) [SetTheoryBasis V] : V :=
  SetTheoryBasis.emptySet V

/-- Impredicative proposition-valued Pi over ALREADY DENOTED fibres. -/
noncomputable def taggedPropPi (V : Type u) [SetTheoryBasis V]
    (A : V) (B : V → V) : V := by
  classical
  exact if ∀ x : V, SetTheoryBasis.member x A → B x = taggedTrue V
    then taggedTrue V
    else taggedPropFalse V

/-- No new axiom: the tagged Pi denotes a member of P1f's actual Prop. -/
theorem taggedPropPi_member_prop (V : Type u) [SetTheoryBasis V]
    (A : V) (B : V → V) :
    SetTheoryBasis.member (taggedPropPi V A B) (taggedSortSet V 0) := by
  classical
  by_cases hAll :
      ∀ x : V, SetTheoryBasis.member x A → B x = taggedTrue V
  · have hResult : taggedPropPi V A B = taggedTrue V := by
      simp only [taggedPropPi, if_pos hAll]
    rw [hResult]
    simpa only [taggedSortSet] using taggedTrue_member_prop V
  · have hResult : taggedPropPi V A B = taggedPropFalse V := by
      simp only [taggedPropPi, if_neg hAll]
    rw [hResult]
    simpa only [taggedSortSet, taggedPropFalse] using taggedFalse_member_prop V

/-- The universal truth rule is exact, not a sample of environments. -/
theorem taggedPropPi_true_iff (V : Type u) [SetTheoryBasis V]
    (A : V) (B : V → V) :
    taggedPropPi V A B = taggedTrue V ↔
      ∀ x : V, SetTheoryBasis.member x A → B x = taggedTrue V := by
  classical
  constructor
  · intro hProduct
    by_cases hAll :
        ∀ x : V, SetTheoryBasis.member x A → B x = taggedTrue V
    · exact hAll
    · have hFalse : taggedPropPi V A B = taggedPropFalse V := by
        simp only [taggedPropPi, if_neg hAll]
      have hWrong : taggedPropFalse V = taggedTrue V :=
        hFalse.symm.trans hProduct
      exact False.elim (taggedTrue_ne_empty V hWrong.symm)
  · intro hAll
    simp only [taggedPropPi, if_pos hAll]

/-- An actual false fibre forces false, with no unsafe quotient premise. -/
theorem taggedPropPi_false_of_counterexample
    (V : Type u) [SetTheoryBasis V]
    (A : V) (B : V → V) (x : V)
    (hDomain : SetTheoryBasis.member x A)
    (hFalse : B x ≠ taggedTrue V) :
    taggedPropPi V A B = taggedPropFalse V := by
  have hNotAll :
      ¬ ∀ y : V, SetTheoryBasis.member y A → B y = taggedTrue V :=
    fun hall => hFalse (hall x hDomain)
  simp [taggedPropPi, hNotAll]

/-- Mathematical Pi never returns a third proposition truth value. -/
theorem taggedPropPi_exact_truth_range (V : Type u) [SetTheoryBasis V]
    (A : V) (B : V → V) :
    taggedPropPi V A B = taggedPropFalse V ∨
      taggedPropPi V A B = taggedTrue V := by
  have h := (taggedProp_exactly_two V (taggedPropPi V A B)).mp
    (by simpa only [taggedSortSet] using taggedPropPi_member_prop V A B)
  simpa only [taggedPropFalse] using h

/--
Non-authoritative interpretation of EXACTLY the existing PropInterpTerm.
The source-language annotation checker is a separate required proof.
Only proposition-valued Pi can be expressed by this syntax.
-/
noncomputable def interpTaggedProp (V : Type u) [SetTheoryBasis V] :
    (Nat → V) → PropInterpTerm → V
  | env, .bvar index => env index
  | _, .sort level => taggedSortSet V level
  | env, .propPi domain body =>
      taggedPropPi V (interpTaggedProp V env domain)
        (fun x => interpTaggedProp V (extendSetEnv x env) body)

/-- A semantic obligation; NEVER inferred from an untrusted annotation. -/
def TaggedPropPiFibresValid (V : Type u) [SetTheoryBasis V]
    (env : Nat → V) (domain body : PropInterpTerm) : Prop :=
  ∀ x : V, SetTheoryBasis.member x (interpTaggedProp V env domain) →
    SetTheoryBasis.member
      (interpTaggedProp V (extendSetEnv x env) body)
      (taggedSortSet V 0)

/-- A proposition Pi has model membership conditional on checked fibres. -/
theorem interpTaggedProp_pi_member (V : Type u) [SetTheoryBasis V]
    (env : Nat → V) (domain body : PropInterpTerm)
    (_valid : TaggedPropPiFibresValid V env domain body) :
    SetTheoryBasis.member
      (interpTaggedProp V env (.propPi domain body))
      (taggedSortSet V 0) := by
  simpa only [interpTaggedProp] using
    (taggedPropPi_member_prop V (interpTaggedProp V env domain)
      (fun x => interpTaggedProp V (extendSetEnv x env) body))

/-- Forall P:Prop, P has valid tagged semantic fibres from membership. -/
theorem tagged_forallPropProp_fibres_valid (V : Type u)
    [SetTheoryBasis V] (env : Nat → V) :
    TaggedPropPiFibresValid V env (.sort 0) (.bvar 0) := by
  intro P hP
  simpa [TaggedPropPiFibresValid, interpTaggedProp, extendSetEnv]
    using hP

theorem tagged_forallPropProp_member_prop (V : Type u)
    [SetTheoryBasis V] (env : Nat → V) :
    SetTheoryBasis.member
      (interpTaggedProp V env forallPropPropTerm) (taggedSortSet V 0) :=
  interpTaggedProp_pi_member V env (.sort 0) (.bvar 0)
    (tagged_forallPropProp_fibres_valid V env)

/-- Re-prove actual false denotation with the NEW tagged true point. -/
theorem tagged_forallPropProp_is_false (V : Type u)
    [SetTheoryBasis V] (env : Nat → V) :
    interpTaggedProp V env forallPropPropTerm = taggedPropFalse V := by
  have hNotTrue : taggedPropFalse V ≠ taggedTrue V :=
    fun h => taggedTrue_ne_empty V (by simpa only [taggedPropFalse] using h.symm)
  have hMember : SetTheoryBasis.member
      (taggedPropFalse V) (taggedSortSet V 0) := by
    simpa only [taggedPropFalse, taggedSortSet] using
      (taggedFalse_member_prop V)
  simpa [forallPropPropTerm, interpTaggedProp, extendSetEnv]
    using (taggedPropPi_false_of_counterexample V
      (taggedSortSet V 0) (fun x => x)
      (taggedPropFalse V) hMember hNotTrue)

/-- For every P in tagged Prop, implication P → P has true denotation. -/
theorem tagged_imp_self_true (V : Type u) [SetTheoryBasis V]
    (P : V) (hP : SetTheoryBasis.member P (taggedSortSet V 0)) :
    taggedPropPi V P (fun _ => P) = taggedTrue V := by
  apply (taggedPropPi_true_iff V P (fun _ => P)).2
  intro x hx
  have hCarrier : SetTheoryBasis.member P (taggedProp V) := by
    simpa only [taggedSortSet] using hP
  rcases (taggedProp_exactly_two V P).mp hCarrier with hFalse | hTrue
  · have hEmptyMember : SetTheoryBasis.member x
        (SetTheoryBasis.emptySet V) := by
      simpa only [hFalse] using hx
    exact False.elim (SetTheoryBasis.not_member_empty V x hEmptyMember)
  · exact hTrue

/-- Independently validate BOTH nested Pi fibres under the tagged model. -/
theorem tagged_forallPropIdentity_fibres_valid
    (V : Type u) [SetTheoryBasis V] (env : Nat → V) :
    TaggedPropPiFibresValid V env (.sort 0)
      (.propPi (.bvar 0) (.bvar 1)) := by
  intro P hP
  apply interpTaggedProp_pi_member V
    (extendSetEnv P env) (.bvar 0) (.bvar 1)
  intro x hx
  simpa [interpTaggedProp, extendSetEnv] using hP

theorem tagged_forallPropIdentity_member_prop (V : Type u)
    [SetTheoryBasis V] (env : Nat → V) :
    SetTheoryBasis.member
      (interpTaggedProp V env forallPropIdentityTerm) (taggedSortSet V 0) :=
  interpTaggedProp_pi_member V env (.sort 0)
    (.propPi (.bvar 0) (.bvar 1))
    (tagged_forallPropIdentity_fibres_valid V env)

/-- Re-prove actual true denotation with P1f's true singleton(point). -/
theorem tagged_forallPropIdentity_is_true (V : Type u)
    [SetTheoryBasis V] (env : Nat → V) :
    interpTaggedProp V env forallPropIdentityTerm = taggedTrue V := by
  change taggedPropPi V (taggedSortSet V 0)
    (fun P => taggedPropPi V P (fun _ => P)) = taggedTrue V
  apply (taggedPropPi_true_iff V (taggedSortSet V 0)
    (fun P => taggedPropPi V P (fun _ => P))).2
  intro P hP
  exact tagged_imp_self_true V P hP

/-- False source proposition has no denoting proof value. -/
theorem tagged_forallPropProp_uninhabited (V : Type u)
    [SetTheoryBasis V] (env : Nat → V) (x : V) :
    ¬ SetTheoryBasis.member x
      (interpTaggedProp V env forallPropPropTerm) := by
  rw [tagged_forallPropProp_is_false V env]
  exact SetTheoryBasis.not_member_empty V x

/-- The *true proposition set* contains exactly P1f's distinguished pt.
This is a fact about its mathematical carrier, NOT checked proof terms. -/
theorem tagged_forallPropIdentity_only_point (V : Type u)
    [SetTheoryBasis V] (env : Nat → V) (x : V)
    (hx : SetTheoryBasis.member x
      (interpTaggedProp V env forallPropIdentityTerm)) :
    x = taggedPoint V := by
  rw [tagged_forallPropIdentity_is_true V env] at hx
  exact (member_modelSingleton x (taggedPoint V)).mp hx

#print axioms taggedPropPi_member_prop
#print axioms taggedPropPi_true_iff
#print axioms taggedPropPi_false_of_counterexample
#print axioms taggedPropPi_exact_truth_range
#print axioms interpTaggedProp_pi_member
#print axioms tagged_forallPropProp_fibres_valid
#print axioms tagged_forallPropProp_member_prop
#print axioms tagged_forallPropProp_is_false
#print axioms tagged_imp_self_true
#print axioms tagged_forallPropIdentity_fibres_valid
#print axioms tagged_forallPropIdentity_member_prop
#print axioms tagged_forallPropIdentity_is_true
#print axioms tagged_forallPropProp_uninhabited
#print axioms tagged_forallPropIdentity_only_point

end PSKernelFast.Spec
