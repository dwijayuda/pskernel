import ConLeche.SetModel.Ops
import Ps.KernelCore.Metatheory.SemanticDomain

/-!
A relative set model for PSKernel's semantic interfaces.

The only external foundation is the explicit parameter [ConLeche.SetTheory V].
No instance is postulated here. Its universe chain, replacement and regularity
are mathematical assumptions, not checker-soundness assumptions. We import the
pinned pure set-theory library, not Con Leche's checker or its soundness theorem.
PSKernel's inference, equality, cache and admission bridges remain obligations.
-/

namespace PsKernelSemantics.SetModel

open ConLeche ConLeche.SetTheory ConLeche.SetModel

universe u
variable {V : Type u} [SetTheory V]

/-- A semantic type must belong to some universe of the actual set tower. -/
def IsType (A : V) : Prop := ∃ n : Nat, A ∈ˢ univ n

/-- Instantiation of the earlier domain interface with actual sets.
Every field is derived from the explicit mathematical foundation. -/
noncomputable def domain : ProofDomain V where
  mem := Mem
  isType := IsType
  propSort := univ 0
  propSort_isType := ⟨1, univ_mem_univ 0⟩
  prop_isType := fun h => ⟨0, h⟩
  proof_irrel := fun hp ha hb => (mem_univ_zero hp ha).trans (mem_univ_zero hp hb).symm
  empty := empty
  empty_isProp := empty_mem_univ 0
  empty_elim := fun {a} ha => not_mem_empty a ha

theorem sort_isType (n : Nat) : IsType (univ n : V) :=
  ⟨n + 1, univ_mem_univ n⟩

theorem sort_not_self (n : Nat) : ¬ (univ n : V) ∈ˢ univ n :=
  not_mem_self _

/-- Lean's impredicative universe operation, on semantic universe levels. -/
def imax (a b : Nat) : Nat := if b = 0 then 0 else max a b

/-- Full dependent-product closure, including the impredicative Prop case. -/
theorem pi_mem_sort {a b : Nat} {A : V} {B : V → V}
    (hA : A ∈ˢ univ a)
    (hB : ∀ x, x ∈ˢ A → B x ∈ˢ univ b) :
    piR b A B ∈ˢ univ (imax a b) := by
  by_cases hb : b = 0
  · subst b
    exact piR_zero_mem_univZero
  · have hm : max a b ≠ 0 := by omega
    rw [imax, if_neg hb, piR_pos hb]
    exact (univ_isTGUniverse hm).piSet_mem
      (univ_mono (Nat.le_max_left a b) _ hA)
      (fun x hx => univ_mono (Nat.le_max_right a b) _ (hB x hx))

theorem pi_isType {a b : Nat} {A : V} {B : V → V}
    (hA : A ∈ˢ univ a)
    (hB : ∀ x, x ∈ˢ A → B x ∈ˢ univ b) :
    IsType (piR b A B) :=
  ⟨imax a b, pi_mem_sort hA hB⟩

theorem application_mem {b : Nat} {A f x : V} {B : V → V}
    (hf : f ∈ˢ piR b A B) (hx : x ∈ˢ A)
    (hB : ∀ y, y ∈ˢ A → B y ∈ˢ univ b) :
    app f x ∈ˢ B x :=
  app_mem_piR hf hx (fun h0 y hy => by simpa [h0, univ_zero] using hB y hy)

/-- Beta requires an on-domain argument and genuinely typed fibres.
In particular this does not assert unrestricted subject reduction. -/
theorem beta {b : Nat} {A x : V} {B F : V → V}
    (hx : x ∈ˢ A)
    (hF : ∀ y, y ∈ˢ A → F y ∈ˢ B y)
    (hB : ∀ y, y ∈ˢ A → B y ∈ˢ univ b) :
    app (lamR b A F) x = F x :=
  app_lamR hx hF (fun h0 y hy => by simpa [h0, univ_zero] using hB y hy)

theorem eta {b : Nat} {A f : V} {B : V → V}
    (hf : f ∈ˢ piR b A B) :
    lamR b A (fun x => app f x) = f :=
  lamR_eta hf

/-- The nonempty semantic context needed to avoid vacuous consistency claims. -/
theorem empty_type_uninhabited : ¬ ∃ x : V, x ∈ˢ empty := by
  rintro ⟨x, hx⟩
  exact not_mem_empty x hx

/-- The usual closed contradiction type Π p : Prop, p is empty in this model. -/
theorem no_proof_of_all_props :
    ¬ ∃ f : V, f ∈ˢ piR 0 (univ 0) (fun p => p) := by
  rintro ⟨f, hf⟩
  have he : app f (empty : V) ∈ˢ empty :=
    application_mem hf (empty_mem_univ 0) (fun _ hp => hp)
  exact not_mem_empty _ he

end PsKernelSemantics.SetModel
