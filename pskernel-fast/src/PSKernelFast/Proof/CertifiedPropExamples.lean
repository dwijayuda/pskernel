import PSKernelFast.Proof.CheckedPropAnnotations

/-!
P1e proof-only demonstration: the general checked proposition annotation
relation has ACTUAL witnesses for both source programs previously accepted
by G4.3b. Their semantic fibre-validity premises are derived by separate
set-theoretic proofs, rather than assumed or fabricated by a frontend.

The result is a conditional model of TWO closed checked propositions,
plus a reusable guarded rule for other proposition-valued Pi expressions.
No general source-term denotation, proof-point interpretation or
admission API has been implemented.
-/

namespace PSKernelFast.Proof

open PSKernelFast.Core
open PSKernelFast.Spec

universe u

/-- Fully source-rule-backed semantic annotation of forall(P:Prop),P. -/
theorem forallPropProp_checked_annotation
    (ρ : KName → Nat) (name : KName) :
    CheckedPropAnnotation [] ρ []
      (forallPropPropSource name) forallPropPropTerm := by
  refine .pi [] name (.sort .zero) (.bvar 0) .default
    (.succ .zero) .zero (.sort 0) (.bvar 0) ?_ ?_ ?_ ?_ ?_
  · exact .sort [] .zero trivial
  · exact .bound [(.sort .zero)] 0 (.sort .zero) rfl
  · rfl
  · exact .sort [] .zero trivial
  · exact .bvar [(.sort .zero)] 0 (.sort .zero) rfl

/-- The checked annotation agrees with the real successful execution. -/
theorem forallPropProp_annotated_executed
    (ρ : KName → Nat) (name : KName) :
    inferClosedGeneralPi [] (forallPropPropSource name) =
      .ok forallPropPropSourceType ∧
    CheckedPropAnnotation [] ρ []
      (forallPropPropSource name) forallPropPropTerm :=
  ⟨forallPropProp_actual_inference name,
   forallPropProp_checked_annotation ρ name⟩

/--
General checked-Pi model-membership theorem instantiated with the actual
forall(P:Prop),P source, its *checked* domain and codomain sort levels,
and its independently derived valid model fibres.
-/
theorem forallPropProp_checked_annotation_model
    (V : Type u) [SetTheoryBasis V]
    (ρ : KName → Nat) (env : Nat → V) (name : KName) :
    ∃ domainSort codomainSort : ULevel,
      GeneralPiRule [] []
        (forallPropPropSource name)
        (.sort (.imax domainSort codomainSort)) ∧
      ((ULevel.imax domainSort codomainSort).denote ρ = 0) ∧
      SetTheoryBasis.Mem
        (interpProp V env forallPropPropTerm)
        (sortSet V ((ULevel.imax domainSort codomainSort).denote ρ)) := by
  exact checkedPropAnnotation_pi_model_member
    V [] ρ [] name (.sort .zero) (.bvar 0) .default
    (.sort 0) (.bvar 0)
    (forallPropProp_checked_annotation ρ name) env
    (forallPropProp_fibres_valid V env)

/--
Certified annotations of the nested implication body and its exact
de Bruijn contexts. Both nested Pis are genuinely proposition-valued
under the recursively checked body types; neither Prop regime is
guessed from arbitrary user metadata.
-/
theorem forallPropIdentity_checked_annotation
    (ρ : KName → Nat) (propName proofName : KName) :
    CheckedPropAnnotation [] ρ []
      (forallPropIdentitySource propName proofName)
      forallPropIdentityTerm := by
  have hInnerDomain : GeneralPiRule [] [(.sort .zero)]
      (.bvar 0) (.sort .zero) :=
    .bound [(.sort .zero)] 0 (.sort .zero) rfl
  have hInnerBody : GeneralPiRule [] [(.bvar 0), (.sort .zero)]
      (.bvar 1) (.sort .zero) :=
    .bound [(.bvar 0), (.sort .zero)] 1 (.sort .zero) rfl
  have hInner : GeneralPiRule [] [(.sort .zero)]
      (.forallE proofName (.bvar 0) (.bvar 1) .default)
      (.sort (.imax .zero .zero)) :=
    .pi [(.sort .zero)] proofName (.bvar 0) (.bvar 1)
      .default .zero .zero hInnerDomain hInnerBody
  have hAnnotatedInner : CheckedPropAnnotation [] ρ
      [(.sort .zero)]
      (.forallE proofName (.bvar 0) (.bvar 1) .default)
      (.propPi (.bvar 0) (.bvar 1)) := by
    refine .pi [(.sort .zero)] proofName (.bvar 0) (.bvar 1)
      .default .zero .zero (.bvar 0) (.bvar 1)
      hInnerDomain hInnerBody (by rfl) ?_ ?_
    · exact .bvar [(.sort .zero)] 0 (.sort .zero) rfl
    · exact .bvar [(.bvar 0), (.sort .zero)] 1 (.sort .zero) rfl
  refine .pi [] propName (.sort .zero)
    (.forallE proofName (.bvar 0) (.bvar 1) .default)
    .default (.succ .zero) (.imax .zero .zero)
    (.sort 0) (.propPi (.bvar 0) (.bvar 1))
    (.sort [] .zero trivial) hInner (by rfl)
    (.sort [] .zero trivial) hAnnotatedInner

/-- A second actual executing-success proof paired with a checked annotation. -/
theorem forallPropIdentity_annotated_executed
    (ρ : KName → Nat) (propName proofName : KName) :
    inferClosedGeneralPi []
      (forallPropIdentitySource propName proofName) =
      .ok forallPropIdentitySourceType ∧
    CheckedPropAnnotation [] ρ []
      (forallPropIdentitySource propName proofName)
      forallPropIdentityTerm :=
  ⟨forallPropIdentity_actual_inference propName proofName,
   forallPropIdentity_checked_annotation ρ propName proofName⟩

/--
The reusable general guarded Prop-Pi membership rule applies to the
actually checked NESTED dependent Pi source, not merely to its
manually interpreted erased counterpart. Fibre validity has already
been proved from the two-valued candidate set model.
-/
theorem forallPropIdentity_checked_annotation_model
    (V : Type u) [SetTheoryBasis V]
    (ρ : KName → Nat) (env : Nat → V)
    (propName proofName : KName) :
    ∃ domainSort codomainSort : ULevel,
      GeneralPiRule [] []
        (forallPropIdentitySource propName proofName)
        (.sort (.imax domainSort codomainSort)) ∧
      ((ULevel.imax domainSort codomainSort).denote ρ = 0) ∧
      SetTheoryBasis.Mem
        (interpProp V env forallPropIdentityTerm)
        (sortSet V ((ULevel.imax domainSort codomainSort).denote ρ)) := by
  exact checkedPropAnnotation_pi_model_member
    V [] ρ [] propName (.sort .zero)
    (.forallE proofName (.bvar 0) (.bvar 1) .default)
    .default (.sort 0) (.propPi (.bvar 0) (.bvar 1))
    (forallPropIdentity_checked_annotation ρ propName proofName)
    env (forallPropIdentity_fibres_valid V env)

#print axioms forallPropProp_checked_annotation
#print axioms forallPropProp_annotated_executed
#print axioms forallPropProp_checked_annotation_model
#print axioms forallPropIdentity_checked_annotation
#print axioms forallPropIdentity_annotated_executed
#print axioms forallPropIdentity_checked_annotation_model

end PSKernelFast.Proof
