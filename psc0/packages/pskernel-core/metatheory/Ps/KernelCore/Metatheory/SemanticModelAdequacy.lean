import Ps.KernelCore.Metatheory.SemanticContext

/-!
Adequacy checks for the new model boundary. These separate a real model of
typed expressions from a mere function assigning values to erased syntax.
-/

namespace PsKernelSemantics.SetModel
open ConLeche ConLeche.SetTheory ConLeche.SetModel
open AnnotatedExpr

universe u
variable {V : Type u} [SetTheory V]

/-- A valid graph-regime identity on propositions. -/
def propIdentity : AnnotatedExpr :=
  .lam .anonymous (.sort .zero) (.bvar 0) .default (.succ .zero)

def propIdentityType : AnnotatedExpr :=
  .forallE .anonymous (.sort .zero) (.sort .zero) .default (.succ .zero)

theorem propIdentity_scoped : propIdentity.Scoped 0 := by
  simp [propIdentity, Scoped]

theorem propIdentity_type (M : Reading V) :
    ModelsType M [] propIdentity propIdentityType := by
  intro ρ _
  exact lamR_mem (fun _ hx => hx)

theorem propIdentityType_sort (M : Reading V) :
    ModelsType M [] propIdentityType (.sort (.succ .zero)) := by
  intro ρ _
  exact pi_mem_sort (univ_mem_univ 0) (fun _ _ => univ_mem_univ 0)

/-- Erasure equality alone is insufficient to choose a model reading.
This is not an executable counterexample: the checker bridge must establish
that binder annotations have the correct regime. -/
theorem erasure_is_not_semantic_coherence (M : Reading V) (ρ : Nat → V) :
    ∃ a b : AnnotatedExpr, a.erase = b.erase ∧ interp M ρ a ≠ interp M ρ b := by
  let a : AnnotatedExpr :=
    .lam .anonymous (.sort .zero) (.sort .zero) .default (.succ .zero)
  let b : AnnotatedExpr :=
    .lam .anonymous (.sort .zero) (.sort .zero) .default .zero
  refine ⟨a, b, rfl, ?_⟩
  change lamR 1 (univ 0 : V) (fun _ => univ 0) ≠
    lamR 0 (univ 0 : V) (fun _ => univ 0)
  rw [lamR_zero]
  exact lamR_ne_pt (by decide)

/-- Even membership and a universe-valued type do not establish annotation
coherence. Both readings below satisfy those semantic facts, but only a
separate checked-annotation invariant can choose the intended binder regime.
This is a counterexample to a proposed proof interface, not to the executable. -/
theorem membership_is_not_annotation_coherence (M : Reading V) (ρ : Nat → V) :
    ∃ a b A B : AnnotatedExpr,
      a.erase = b.erase ∧ A.erase = B.erase ∧
      ModelsType M [] a A ∧ ModelsType M [] b B ∧
      ModelsType M [] A (.sort (.succ .zero)) ∧
      ModelsType M [] B (.sort .zero) ∧
      interp M ρ a ≠ interp M ρ b := by
  let b : AnnotatedExpr :=
    .lam .anonymous (.sort .zero) (.bvar 0) .default .zero
  let B : AnnotatedExpr :=
    .forallE .anonymous (.sort .zero) (.sort .zero) .default .zero
  refine ⟨propIdentity, b, propIdentityType, B, rfl, rfl,
    propIdentity_type M, ?_, propIdentityType_sort M, ?_, ?_⟩
  · intro σ _
    exact lamR_mem (fun _ hx => hx)
  · intro σ _
    change piR 0 (univ 0 : V) (fun _ => univ 0) ∈ˢ univ 0
    rw [univ_zero]
    exact piR_zero_mem_univZero
  · change lamR 1 (univ 0 : V) (fun x => x) ≠
      lamR 0 (univ 0 : V) (fun x => x)
    rw [lamR_zero]
    exact lamR_ne_pt (by decide)

end PsKernelSemantics.SetModel
