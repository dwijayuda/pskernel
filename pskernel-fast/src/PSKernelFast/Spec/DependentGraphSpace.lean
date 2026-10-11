import PSKernelFast.Spec.UniverseImageClosure

/-!
P1k: universe-closed dependent graph spaces from the UNCHANGED set basis.

Union closure is derived: if union(A) were equinumerous with U, imaging
its covering pieces gives a family C in U covering U. A preimage of C
then gives a forbidden two-cycle C in D in C. Regularity rules it out.

The dependent sum is the union of graphs of each fibre. The dependent
function-space carrier is a separating subset of its powerset consisting
EXACTLY of graphs of functions with values in their corresponding fibres.
All these sets remain in the SAME universe as A and the fibre sets.

This is a mathematical carrier and membership theorem, NOT the full Lean
Pi interpretation. Graph application/uniqueness, beta/eta, source binder
annotations, imax/Prop distinction, quotient rules and source semantic
soundness are still separate obligations. [SetTheoryBasis V] remains an
explicit substantial assumption; no instance or consistency capstone.
-/

namespace PSKernelFast.Spec

universe u
variable {V : Type u} [SetTheoryBasis V]

/-- Regularity forbids the two-cycle used in the union-closure diagonal. -/
theorem model_no_membership_cycle (a b : V)
    (hab : SetTheoryBasis.member a b) (hba : SetTheoryBasis.member b a) : False := by
  have ha : SetTheoryBasis.member a (SetTheoryBasis.pair a b) :=
    (SetTheoryBasis.member_pair).mpr (Or.inl rfl)
  obtain ⟨c, hc, hMinimal⟩ :=
    SetTheoryBasis.regularity (SetTheoryBasis.pair a b) ⟨a, ha⟩
  rcases (SetTheoryBasis.member_pair).mp hc with hca | hcb
  · subst c
    exact hMinimal ⟨b, hba, (SetTheoryBasis.member_pair).mpr (Or.inr rfl)⟩
  · subst c
    exact hMinimal ⟨a, hab, (SetTheoryBasis.member_pair).mpr (Or.inl rfl)⟩

/-- SAME-STAGE union closure, not an added model field. -/
theorem universe_union_closed (V : Type u) [SetTheoryBasis V]
    (n : Nat) (A : V)
    (hA : SetTheoryBasis.member A (SetTheoryBasis.univ n)) :
    SetTheoryBasis.member (SetTheoryBasis.union A) (SetTheoryBasis.univ n) := by
  have hSubset : ∀ z : V, SetTheoryBasis.member z (SetTheoryBasis.union A) →
      SetTheoryBasis.member z (SetTheoryBasis.univ n) := by
    intro z hz
    obtain ⟨B, hBA, hzB⟩ := (SetTheoryBasis.member_union).mp hz
    have hB : SetTheoryBasis.member B (SetTheoryBasis.univ n) :=
      SetTheoryBasis.universe_transitive (V := V) n A B hA hBA
    exact SetTheoryBasis.universe_transitive (V := V) n B z hB hzB
  rcases (SetTheoryBasis.univ_groth n).2.2.2
      (SetTheoryBasis.union A) hSubset with hEquinumerous | hSmall
  · obtain ⟨F, hMap, _, onto⟩ := hEquinumerous
    let C : V := SetTheoryBasis.image (fun B => SetTheoryBasis.image F B) A
    have hC : SetTheoryBasis.member C (SetTheoryBasis.univ n) := by
      apply universe_image_closed V n A
        (fun B => SetTheoryBasis.image F B) hA
      intro B hBA
      have hB : SetTheoryBasis.member B (SetTheoryBasis.univ n) :=
        SetTheoryBasis.universe_transitive (V := V) n A B hA hBA
      apply universe_image_closed V n B F hB
      intro x hxB
      exact hMap x ((SetTheoryBasis.member_union).mpr ⟨B, hBA, hxB⟩)
    obtain ⟨x, hx, hFx⟩ := onto C hC
    obtain ⟨B, hBA, hxB⟩ := (SetTheoryBasis.member_union).mp hx
    have hDC : SetTheoryBasis.member (SetTheoryBasis.image F B) C :=
      (SetTheoryBasis.member_image).mpr ⟨B, hBA, rfl⟩
    have hCD : SetTheoryBasis.member C (SetTheoryBasis.image F B) :=
      (SetTheoryBasis.member_image).mpr ⟨x, hxB, hFx.symm⟩
    exact False.elim (model_no_membership_cycle C (SetTheoryBasis.image F B) hCD hDC)
  · exact hSmall

/-- Exact set of dependent pairs (x,y) with x in A and y in B(x). -/
noncomputable def modelDependentSum (A : V) (B : V → V) : V :=
  SetTheoryBasis.union (SetTheoryBasis.image
    (fun x => SetTheoryBasis.image (fun y => modelOrderedPair x y) (B x)) A)

theorem member_modelDependentSum (A : V) (B : V → V) (z : V) :
    SetTheoryBasis.member z (modelDependentSum A B) ↔
      ∃ x : V, SetTheoryBasis.member x A ∧
        ∃ y : V, SetTheoryBasis.member y (B x) ∧ z = modelOrderedPair x y := by
  constructor
  · intro hz
    obtain ⟨fiber, hFiber, hzFiber⟩ := (SetTheoryBasis.member_union).mp hz
    obtain ⟨x, hxA, hFiberEq⟩ := (SetTheoryBasis.member_image).mp hFiber
    have hzImage : SetTheoryBasis.member z
        (SetTheoryBasis.image (fun y => modelOrderedPair x y) (B x)) := by
      simpa only [hFiberEq] using hzFiber
    obtain ⟨y, hyB, hPair⟩ := (SetTheoryBasis.member_image).mp hzImage
    exact ⟨x, hxA, y, hyB, hPair⟩
  · rintro ⟨x, hxA, y, hyB, hPair⟩
    apply (SetTheoryBasis.member_union).mpr
    refine ⟨SetTheoryBasis.image (fun y => modelOrderedPair x y) (B x), ?_, ?_⟩
    · exact (SetTheoryBasis.member_image).mpr ⟨x, hxA, rfl⟩
    · exact (SetTheoryBasis.member_image).mpr ⟨y, hyB, hPair⟩

/-- Dependent pair carrier stays at the original universe stage. -/
theorem modelDependentSum_member_univ (V : Type u) [SetTheoryBasis V]
    (n : Nat) (A : V) (B : V → V)
    (hA : SetTheoryBasis.member A (SetTheoryBasis.univ n))
    (hB : ∀ x : V, SetTheoryBasis.member x A →
      SetTheoryBasis.member (B x) (SetTheoryBasis.univ n)) :
    SetTheoryBasis.member (modelDependentSum A B) (SetTheoryBasis.univ n) := by
  apply universe_union_closed V n
  apply universe_image_closed V n A _ hA
  intro x hx
  have hX : SetTheoryBasis.member x (SetTheoryBasis.univ n) :=
    SetTheoryBasis.universe_transitive (V := V) n A x hA hx
  apply universe_image_closed V n (B x) (fun y => modelOrderedPair x y) (hB x hx)
  intro y hy
  have hY : SetTheoryBasis.member y (SetTheoryBasis.univ n) :=
    SetTheoryBasis.universe_transitive (V := V) n (B x) y (hB x hx) hy
  exact modelOrderedPair_member_univ V n A x y hA hX hY

/-- Mathematical dependent function-space carrier, not runtime Lean Pi yet. -/
noncomputable def modelGraphPi (A : V) (B : V → V) : V :=
  modelSeparation (SetTheoryBasis.powerset (modelDependentSum A B))
    (fun graph => ∃ F : V → V,
      (∀ x : V, SetTheoryBasis.member x A → SetTheoryBasis.member (F x) (B x)) ∧
      graph = modelGraph F A)

/-- Exact characterization: all and only graphs of fibre-respecting functions. -/
theorem member_modelGraphPi (A : V) (B : V → V) (graph : V) :
    SetTheoryBasis.member graph (modelGraphPi A B) ↔
      ∃ F : V → V,
        (∀ x : V, SetTheoryBasis.member x A → SetTheoryBasis.member (F x) (B x)) ∧
        graph = modelGraph F A := by
  constructor
  · intro h
    exact ((member_modelSeparation _ _ graph).mp h).2
  · rintro ⟨F, hF, hGraph⟩
    apply (member_modelSeparation _ _ graph).mpr
    constructor
    · apply (SetTheoryBasis.member_powerset).mpr
      intro z hz
      have hzGraph : SetTheoryBasis.member z (modelGraph F A) := by
        simpa only [hGraph] using hz
      obtain ⟨x, hx, hPair⟩ := (member_modelGraph F A z).mp hzGraph
      exact (member_modelDependentSum A B z).mpr ⟨x, hx, F x, hF x hx, hPair⟩
    · exact ⟨F, hF, hGraph⟩

/-- Full graph-space carrier is in the SAME stage as the domain/fibre sets. -/
theorem modelGraphPi_member_univ (V : Type u) [SetTheoryBasis V]
    (n : Nat) (A : V) (B : V → V)
    (hA : SetTheoryBasis.member A (SetTheoryBasis.univ n))
    (hB : ∀ x : V, SetTheoryBasis.member x A →
      SetTheoryBasis.member (B x) (SetTheoryBasis.univ n)) :
    SetTheoryBasis.member (modelGraphPi A B) (SetTheoryBasis.univ n) := by
  apply universe_separation_closed V n (SetTheoryBasis.powerset (modelDependentSum A B))
  exact SetTheoryBasis.universe_powerset_closed (V := V) n
    (modelDependentSum A B) (modelDependentSum_member_univ V n A B hA hB)

#print axioms model_no_membership_cycle
#print axioms universe_union_closed
#print axioms member_modelDependentSum
#print axioms modelDependentSum_member_univ
#print axioms member_modelGraphPi
#print axioms modelGraphPi_member_univ

end PSKernelFast.Spec
