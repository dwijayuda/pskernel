import PSKernelFast.Spec.UniverseSemantics
import PSKernelFast.GeneralPiFormation

/-!
P1d bridge between *actual successful checker rules* and the independent
set-universe/Prop regime specification.

The Pi rule certifies its CODOMAIN sort from a recursive checked inference;
the model may use that certificate when deciding impredicative Prop versus
ordinary dependent function-space semantics. No unchecked metadata hint
can manufacture this witness.

This establishes a genuine Sort membership under an explicit model and a
sound binder-regime observation for Pi. It does NOT construct a dependent
function set (piR), prove Pi membership or establish semantic typing/
checker soundness/relative consistency.
-/

namespace PSKernelFast.Proof

open PSKernelFast.Core
open PSKernelFast.Spec

universe u

/-- The only rule for a Sort subject returns exactly the successor sort. -/
theorem checked_sort_exact_result (params : List KName)
    (ctx : List KExpr) (level : ULevel) (inferred : KExpr)
    (h : GeneralPiRule params ctx (.sort level) inferred) :
    inferred = .sort (.succ level) := by
  cases h with
  | sort _ _ _ => rfl

/--
A FULLY EXECUTED successful closed G4.3b Sort inference has precisely the
expected successor sort. It cannot return a fabricated alternative sort.
-/
theorem inferred_sort_exact_result (params : List KName)
    (level : ULevel) (inferred : KExpr)
    (h : inferClosedGeneralPi params (.sort level) = .ok inferred) :
    inferred = .sort (.succ level) :=
  checked_sort_exact_result params [] level inferred
    (inferClosedGeneralPi_sound params (.sort level) inferred h).2

/--
The first **conditional set-model interpretation of a checked rule**:
the actual G4.3b algorithm returning a type for Sort u ensures that,
under any supplied omega-Grothendieck set-theory model, the denotation
of Sort u is a member of the denotation of its exact checked type,
for EVERY valuation of symbolic universe parameters.

No SetTheoryBasis instance is constructed. Membership is conditional on
the stated mathematical model, and no other typing rule is proved here.
-/
theorem inferred_sort_model_member
    (V : Type u) [SetTheoryBasis V] (params : List KName)
    (level : ULevel) (inferred : KExpr)
    (h : inferClosedGeneralPi params (.sort level) = .ok inferred) :
    inferred = .sort (.succ level) ∧
      ∀ ρ : KName → Nat,
        SetTheoryBasis.Mem
          (sortSet V (level.denote ρ))
          (sortSet V ((ULevel.succ level).denote ρ)) := by
  constructor
  · exact inferred_sort_exact_result params level inferred h
  · intro ρ
    exact sort_member_succ V ρ level

/--
Only the Pi rule can derive a type for a syntactic dependent Pi.
Its exact CODOMAIN level comes from a checked recursive typing premise.
The existential witnesses are *derived*, not annotations supplied by a
frontend or a lemma assumption.
-/
theorem checked_pi_extract_sorts (params : List KName)
    (ctx : List KExpr) (name : KName) (domain body : KExpr)
    (style : BinderStyle) (inferredLevel : ULevel)
    (h : GeneralPiRule params ctx
      (.forallE name domain body style) (.sort inferredLevel)) :
    ∃ domainSort codomainSort : ULevel,
      inferredLevel = .imax domainSort codomainSort ∧
      GeneralPiRule params ctx domain (.sort domainSort) ∧
      GeneralPiRule params (domain :: ctx) body (.sort codomainSort) := by
  cases h with
  | pi _ _ _ _ _ u v hDomain hBody =>
      exact ⟨u, v, rfl, hDomain, hBody⟩

/--
Every checked Pi's impredicative proposition classification is governed
ONLY by the actual checked codomain sort at all universe valuations,
never by the binder domain level or untrusted metadata.
-/
theorem checked_pi_prop_regime (params : List KName)
    (ctx : List KExpr) (name : KName) (domain body : KExpr)
    (style : BinderStyle) (resultLevel : ULevel)
    (h : GeneralPiRule params ctx
      (.forallE name domain body style) (.sort resultLevel)) :
    ∃ codomainSort : ULevel,
      GeneralPiRule params (domain :: ctx) body (.sort codomainSort) ∧
      ∀ ρ : KName → Nat,
        (resultLevel.denote ρ = 0 ↔ codomainSort.denote ρ = 0) := by
  obtain ⟨u, v, hLevel, _hDomain, hBody⟩ :=
    checked_pi_extract_sorts params ctx name domain body style resultLevel h
  refine ⟨v, hBody, ?_⟩
  intro ρ
  rw [hLevel]
  exact piLevel_isProp_iff_codomain_isProp ρ u v

/--
The **executable** closed Pi inferencer produces the same validated
codomain Prop-regime certificate, with no new trusted runtime path.
-/
theorem inferred_closed_pi_prop_regime (params : List KName)
    (name : KName) (domain body : KExpr)
    (style : BinderStyle) (resultLevel : ULevel)
    (h : inferClosedGeneralPi params (.forallE name domain body style) =
      .ok (.sort resultLevel)) :
    ∃ codomainSort : ULevel,
      GeneralPiRule params [domain] body (.sort codomainSort) ∧
      ∀ ρ : KName → Nat,
        (resultLevel.denote ρ = 0 ↔ codomainSort.denote ρ = 0) :=
  checked_pi_prop_regime params [] name domain body style resultLevel
    (inferClosedGeneralPi_sound params
      (.forallE name domain body style) (.sort resultLevel) h).2

#print axioms checked_sort_exact_result
#print axioms inferred_sort_model_member
#print axioms checked_pi_extract_sorts
#print axioms checked_pi_prop_regime
#print axioms inferred_closed_pi_prop_regime

end PSKernelFast.Proof
