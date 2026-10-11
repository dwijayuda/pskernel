import PSKernelFast.Spec.TaggedPropSemantics
import PSKernelFast.Proof.CertifiedPropExamples

/-!
P1g: SOURCE-CERTIFIED REQUALIFICATION against P1f's tagged model.

No executing checker rule changes. All annotations come from the actual
G4.3b declarative rule, with exact symbolic imax and separately established
semantic fibre obligations. Old P1d/P1e denotations do not supply any of the
model equations below. No general term-soundness, model existence, quotient
freshness or proof admission follows from these two concrete examples.
-/

namespace PSKernelFast.Proof

open PSKernelFast.Core
open PSKernelFast.Spec

universe u

/--
General source-backed Prop-valued Pi soundness IF its semantic fibres are
valid, this time in the tagged model. The checked annotation is not
frontend metadata: it reconstructs the actual GeneralPiRule.
-/
theorem checkedTaggedPropAnnotation_pi_model_member
    (V : Type u) [SetTheoryBasis V]
    (params : List KName) (ρ : KName → Nat)
    (ctx : List KExpr) (name : KName)
    (domain body : KExpr) (style : BinderStyle)
    (annotatedDomain annotatedBody : PropInterpTerm)
    (hAnn : CheckedPropAnnotation params ρ ctx
      (.forallE name domain body style)
      (.propPi annotatedDomain annotatedBody))
    (env : Nat → V)
    (hValid : TaggedPropPiFibresValid V env
      annotatedDomain annotatedBody) :
    ∃ domainSort codomainSort : ULevel,
      GeneralPiRule params ctx (.forallE name domain body style)
        (.sort (.imax domainSort codomainSort)) ∧
      ((ULevel.imax domainSort codomainSort).denote ρ = 0) ∧
      SetTheoryBasis.member
        (interpTaggedProp V env (.propPi annotatedDomain annotatedBody))
        (taggedSortSet V
          ((ULevel.imax domainSort codomainSort).denote ρ)) := by
  cases hAnn with
  | pi ctx name domain body style u v annDom annBody
      hDomain hBody hProp hAnnDom hAnnBody =>
      have hResultProp : ((ULevel.imax u v).denote ρ = 0) :=
        (piLevel_isProp_iff_codomain_isProp ρ u v).2 hProp
      refine ⟨u, v, .pi ctx name domain body style u v
        hDomain hBody, hResultProp, ?_⟩
      simpa only [hResultProp] using
        (interpTaggedProp_pi_member V env
          annotatedDomain annotatedBody hValid)

/-- The first actual accepted source has correct tagged-model regime. -/
theorem forallPropProp_tagged_checked_annotation_model
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
    (tagged_forallPropProp_fibres_valid V env)

/-- The nested actual accepted source has correct tagged-model regime. -/
theorem forallPropIdentity_tagged_checked_annotation_model
    (V : Type u) [SetTheoryBasis V]
    (ρ : KName → Nat) (env : Nat → V)
    (propName proofName : KName) :
    ∃ domainSort codomainSort : ULevel,
      GeneralPiRule [] []
        (forallPropIdentitySource propName proofName)
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
    env (tagged_forallPropIdentity_fibres_valid V env)

/--
End-to-end G4.3b success/annotation/erasure and genuinely RECOMPUTED
tagged set denotation of the false proposition. This theorem does not
use the old interpProp result as a shortcut.
-/
theorem forallPropProp_tagged_checked_set_denotation
    (V : Type u) [SetTheoryBasis V]
    (name : KName) (ρ : KName → Nat) (env : Nat → V) :
    inferClosedGeneralPi [] (forallPropPropSource name) =
      .ok forallPropPropSourceType ∧
    CheckedPropAnnotation [] ρ []
      (forallPropPropSource name) forallPropPropTerm ∧
    eraseExpr ρ (forallPropPropSource name) =
      some forallPropPropTerm.forget ∧
    eraseExpr ρ forallPropPropSourceType = some (.sort 0) ∧
    SetTheoryBasis.member
      (interpTaggedProp V env forallPropPropTerm)
      (interpTaggedProp V env (.sort 0)) ∧
    interpTaggedProp V env forallPropPropTerm = taggedPropFalse V := by
  refine ⟨forallPropProp_actual_inference name,
    forallPropProp_checked_annotation ρ name,
    forallPropProp_actual_erasure ρ name,
    forallPropProp_type_erases_to_Prop ρ, ?_, ?_⟩
  · obtain ⟨u, v, _, hProp, hMem⟩ :=
      forallPropProp_tagged_checked_annotation_model V ρ env name
    have hMemProp : SetTheoryBasis.member
        (interpTaggedProp V env forallPropPropTerm)
        (taggedSortSet V 0) := by
      simpa only [hProp] using hMem
    simpa only [interpTaggedProp] using hMemProp
  · exact tagged_forallPropProp_is_false V env

/-- End-to-end nested-implication TRUE denotation in the tagged carrier. -/
theorem forallPropIdentity_tagged_checked_set_denotation
    (V : Type u) [SetTheoryBasis V]
    (propName proofName : KName)
    (ρ : KName → Nat) (env : Nat → V) :
    inferClosedGeneralPi []
      (forallPropIdentitySource propName proofName) =
      .ok forallPropIdentitySourceType ∧
    CheckedPropAnnotation [] ρ []
      (forallPropIdentitySource propName proofName) forallPropIdentityTerm ∧
    eraseExpr ρ
      (forallPropIdentitySource propName proofName) =
      some forallPropIdentityTerm.forget ∧
    eraseExpr ρ forallPropIdentitySourceType = some (.sort 0) ∧
    SetTheoryBasis.member
      (interpTaggedProp V env forallPropIdentityTerm)
      (interpTaggedProp V env (.sort 0)) ∧
    interpTaggedProp V env forallPropIdentityTerm = taggedTrue V := by
  refine ⟨forallPropIdentity_actual_inference propName proofName,
    forallPropIdentity_checked_annotation ρ propName proofName,
    forallPropIdentity_actual_erasure ρ propName proofName,
    forallPropIdentity_type_erases_to_Prop ρ, ?_, ?_⟩
  · obtain ⟨u, v, _, hProp, hMem⟩ :=
      forallPropIdentity_tagged_checked_annotation_model
        V ρ env propName proofName
    have hMemProp : SetTheoryBasis.member
        (interpTaggedProp V env forallPropIdentityTerm)
        (taggedSortSet V 0) := by
      simpa only [hProp] using hMem
    simpa only [interpTaggedProp] using hMemProp
  · exact tagged_forallPropIdentity_is_true V env

#print axioms checkedTaggedPropAnnotation_pi_model_member
#print axioms forallPropProp_tagged_checked_annotation_model
#print axioms forallPropIdentity_tagged_checked_annotation_model
#print axioms forallPropProp_tagged_checked_set_denotation
#print axioms forallPropIdentity_tagged_checked_set_denotation

end PSKernelFast.Proof
