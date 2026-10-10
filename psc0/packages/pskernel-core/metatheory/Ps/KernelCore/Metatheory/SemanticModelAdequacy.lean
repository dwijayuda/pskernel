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

end PsKernelSemantics.SetModel
