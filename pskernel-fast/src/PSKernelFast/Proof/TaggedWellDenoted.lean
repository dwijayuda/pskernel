import PSKernelFast.Proof.TaggedPropModelBridge

/-!
P1h early hereditary semantic typing, NON-AUTHORITATIVE.

This relation is independent semantic evidence for the tagged model, not a
judgment the G4.3b executable checker is proved to produce in general.
The bound-variable constructor REQUIRES a genuine model-membership witness,
while proposition-valued Pi requires a recursively well-denoted domain and
every semantic fibre. These obligations are not supplied by unchecked
frontend metadata; later soundness work must derive them from source rules.

We prove a membership interpretation theorem and separately extract the
hereditary fibre premise. The two actual checked sources have explicit
closed witnesses. No Type-valued Pi, proof-term admission, quotient or full
model existence is asserted.
-/

namespace PSKernelFast.Proof

open PSKernelFast.Core
open PSKernelFast.Spec

universe u

/-- The tagged universe successor membership at each numeric rank. -/
theorem taggedSort_nat_member_succ (V : Type u)
    [SetTheoryBasis V] (rank : Nat) :
    SetTheoryBasis.member (taggedSortSet V rank)
      (taggedSortSet V (rank + 1)) := by
  cases rank with
  | zero =>
      simpa [taggedSortSet] using (taggedProp_mem_typeOne V)
  | succ n =>
      simpa [taggedSortSet, Nat.add_assoc] using
        (SetTheoryBasis.univ_step (V := V) (n + 2))

/--
HEREDITARY model typing for the deliberately small proposition-term syntax.
A bvar requires model environment membership, rather than an assumed
implicit scope or a frontend-supplied domain guess. For proposition-Pi,
the domain must itself be modeled at some level, and every semantic
fibre is recursively modeled at Prop level.
-/
inductive TaggedWellDenoted (V : Type u) [SetTheoryBasis V] :
    (Nat → V) → PropInterpTerm → Nat → Prop where
  | sort (env : Nat → V) (level : Nat) :
      TaggedWellDenoted V env (.sort level) (level + 1)
  | bvar (env : Nat → V) (index rank : Nat)
      (hMember : SetTheoryBasis.member (env index) (taggedSortSet V rank)) :
      TaggedWellDenoted V env (.bvar index) rank
  | propPi (env : Nat → V)
      (domain body : PropInterpTerm) (domainRank : Nat)
      (domainWellDenoted : TaggedWellDenoted V env domain domainRank)
      (fibresWellDenoted :
        ∀ x : V,
          SetTheoryBasis.member x (interpTaggedProp V env domain) →
            TaggedWellDenoted V (extendSetEnv x env) body 0) :
      TaggedWellDenoted V env (.propPi domain body) 0

/-- All three hereditary constructors have actual tagged set membership. -/
theorem taggedWellDenoted_sound (V : Type u)
    [SetTheoryBasis V] {env : Nat → V}
    {term : PropInterpTerm} {rank : Nat}
    (h : TaggedWellDenoted V env term rank) :
    SetTheoryBasis.member
      (interpTaggedProp V env term) (taggedSortSet V rank) := by
  cases h with
  | sort env level =>
      simpa only [interpTaggedProp] using
        (taggedSort_nat_member_succ V level)
  | bvar env index level hMember =>
      simpa only [interpTaggedProp] using hMember
  | propPi env domain body domainRank hDom hBody =>
      simpa only [interpTaggedProp] using
        (taggedPropPi_member_prop V
          (interpTaggedProp V env domain)
          (fun x => interpTaggedProp V (extendSetEnv x env) body))

/--
A hereditary Prop-Pi witness actually PRODUCES the previously explicit
semantic-fibre-validity premise. The source checker has not yet been
proved to construct such witnesses for arbitrary accepted terms.
-/
theorem taggedWellDenoted_pi_fibres (V : Type u)
    [SetTheoryBasis V] {env : Nat → V}
    {domain body : PropInterpTerm}
    (h : TaggedWellDenoted V env (.propPi domain body) 0) :
    TaggedPropPiFibresValid V env domain body := by
  change ∀ x : V,
    SetTheoryBasis.member x (interpTaggedProp V env domain) →
      SetTheoryBasis.member
        (interpTaggedProp V (extendSetEnv x env) body)
        (taggedSortSet V 0)
  cases h with
  | propPi env domain body domainRank hDom hBody =>
      intro x hx
      exact taggedWellDenoted_sound V (hBody x hx)

/-- Construct the actual first example's hereditary semantic witness. -/
theorem forallPropProp_tagged_wellDenoted (V : Type u)
    [SetTheoryBasis V] (env : Nat → V) :
    TaggedWellDenoted V env forallPropPropTerm 0 := by
  change TaggedWellDenoted V env
    (.propPi (.sort 0) (.bvar 0)) 0
  apply TaggedWellDenoted.propPi (domainRank := 1)
  · exact TaggedWellDenoted.sort env 0
  · intro P hP
    apply TaggedWellDenoted.bvar (extendSetEnv P env) 0 0
    simpa only [interpTaggedProp, extendSetEnv] using hP

/-- Construct BOTH dependent Pi layers, not just the outer binder. -/
theorem forallPropIdentity_tagged_wellDenoted (V : Type u)
    [SetTheoryBasis V] (env : Nat → V) :
    TaggedWellDenoted V env forallPropIdentityTerm 0 := by
  change TaggedWellDenoted V env
    (.propPi (.sort 0) (.propPi (.bvar 0) (.bvar 1))) 0
  apply TaggedWellDenoted.propPi (domainRank := 1)
  · exact TaggedWellDenoted.sort env 0
  · intro P hP
    apply TaggedWellDenoted.propPi (domainRank := 0)
    · apply TaggedWellDenoted.bvar (extendSetEnv P env) 0 0
      simpa only [interpTaggedProp, extendSetEnv] using hP
    · intro x hx
      apply TaggedWellDenoted.bvar
        (extendSetEnv x (extendSetEnv P env)) 1 0
      simpa only [extendSetEnv] using hP

/-- Source-backed tagged Pi typing via HEREDITARY rather than ad hoc fibres. -/
theorem forallPropProp_tagged_checked_via_wellDenoted
    (V : Type u) [SetTheoryBasis V]
    (ρ : KName → Nat) (env : Nat → V) (name : KName) :
    ∃ domainSort codomainSort : ULevel,
      GeneralPiRule [] [] (forallPropPropSource name)
        (.sort (.imax domainSort codomainSort)) ∧
      ((ULevel.imax domainSort codomainSort).denote ρ = 0) ∧
      SetTheoryBasis.member
        (interpTaggedProp V env forallPropPropTerm)
        (taggedSortSet V
          ((ULevel.imax domainSort codomainSort).denote ρ)) := by
  exact checkedTaggedPropAnnotation_pi_model_member
    V [] ρ [] name (.sort .zero) (.bvar 0) .default
    (.sort 0) (.bvar 0)
    (forallPropProp_checked_annotation ρ name) env
    (taggedWellDenoted_pi_fibres V
      (forallPropProp_tagged_wellDenoted V env))

/-- Independently source-backed nested Pi via the same hereditary rule. -/
theorem forallPropIdentity_tagged_checked_via_wellDenoted
    (V : Type u) [SetTheoryBasis V]
    (ρ : KName → Nat) (env : Nat → V)
    (propName proofName : KName) :
    ∃ domainSort codomainSort : ULevel,
      GeneralPiRule [] [] (forallPropIdentitySource propName proofName)
        (.sort (.imax domainSort codomainSort)) ∧
      ((ULevel.imax domainSort codomainSort).denote ρ = 0) ∧
      SetTheoryBasis.member
        (interpTaggedProp V env forallPropIdentityTerm)
        (taggedSortSet V
          ((ULevel.imax domainSort codomainSort).denote ρ)) := by
  exact checkedTaggedPropAnnotation_pi_model_member
    V [] ρ [] propName (.sort .zero)
    (.forallE proofName (.bvar 0) (.bvar 1) .default)
    .default (.sort 0) (.propPi (.bvar 0) (.bvar 1))
    (forallPropIdentity_checked_annotation ρ propName proofName)
    env (taggedWellDenoted_pi_fibres V
      (forallPropIdentity_tagged_wellDenoted V env))

#print axioms taggedSort_nat_member_succ
#print axioms taggedWellDenoted_sound
#print axioms taggedWellDenoted_pi_fibres
#print axioms forallPropProp_tagged_wellDenoted
#print axioms forallPropIdentity_tagged_wellDenoted
#print axioms forallPropProp_tagged_checked_via_wellDenoted
#print axioms forallPropIdentity_tagged_checked_via_wellDenoted

end PSKernelFast.Proof
