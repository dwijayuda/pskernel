import PSKernelFast.Spec.GraphUniverseClosure

/-!
P1k: same-universe image and graph closure, DERIVED rather than assumed.

1. Construct separation using image, singleton, empty and union.
2. Diagonalize to prove that no member A of a universe U can surject onto U.
3. Apply the existing Tarski size alternative to the image of A. Its
   equinumerous-with-U branch would compose to the impossible surjection.
4. Thus the image, and the actual Kuratowski graph, belong to U ITSELF.

This closes the successor-stage limitation of P1j without changing the
SetTheoryBasis interface, adding a global axiom, or assuming a model exists.
All conclusions remain conditional on a supplied [SetTheoryBasis V].
No full dependent function-space, application/beta/eta model, checked
source-soundness or relative-consistency capstone is asserted here.
-/

namespace PSKernelFast.Spec

universe u
variable {V : Type u} [SetTheoryBasis V]

/-- Separation is a construction from already-supplied operations, not a law. -/
noncomputable def modelSeparation (A : V) (p : V → Prop) : V := by
  classical
  exact SetTheoryBasis.union (SetTheoryBasis.image
    (fun x => if p x then modelSingleton x else SetTheoryBasis.emptySet V) A)

/-- Exact membership for the constructed separating subset. -/
theorem member_modelSeparation (A : V) (p : V → Prop) (z : V) :
    SetTheoryBasis.member z (modelSeparation A p) ↔
      SetTheoryBasis.member z A ∧ p z := by
  classical
  constructor
  · intro hz
    obtain ⟨Y, hY, hzY⟩ := (SetTheoryBasis.member_union).mp hz
    obtain ⟨x, hx, hYx⟩ := (SetTheoryBasis.member_image).mp hY
    by_cases hp : p x
    · have hSingleton : Y = modelSingleton x := by
        simpa only [hp, ite_true] using hYx
      have hzSingleton : SetTheoryBasis.member z (modelSingleton x) := by
        simpa only [hSingleton] using hzY
      have hzx : z = x := (member_modelSingleton z x).mp hzSingleton
      subst z
      exact ⟨hx, hp⟩
    · have hEmpty : Y = SetTheoryBasis.emptySet V := by
        simpa only [hp, ite_false] using hYx
      have hzEmpty : SetTheoryBasis.member z (SetTheoryBasis.emptySet V) := by
        simpa only [hEmpty] using hzY
      exact False.elim (SetTheoryBasis.not_member_empty V z hzEmpty)
  · rintro ⟨hz, hp⟩
    apply (SetTheoryBasis.member_union).mpr
    refine ⟨modelSingleton z, ?_, modelSingleton_member z⟩
    apply (SetTheoryBasis.member_image).mpr
    refine ⟨z, hz, ?_⟩
    simp only [hp, ite_true]

/-- Every constructed subset of a universe member remains a member. -/
theorem universe_separation_closed (V : Type u) [SetTheoryBasis V]
    (n : Nat) (A : V) (p : V → Prop)
    (hA : SetTheoryBasis.member A (SetTheoryBasis.univ n)) :
    SetTheoryBasis.member (modelSeparation A p) (SetTheoryBasis.univ n) := by
  apply SetTheoryBasis.universe_subset_closed (V := V) n A
    (modelSeparation A p) hA
  intro z hz
  exact ((member_modelSeparation A p z).mp hz).1

/--
Diagonal obstruction. A function from a member A of U cannot cover U,
because the separating subset {x in A | x notin g(x)} is itself in U.
No ordinal/cardinality library, model-closing axiom or injectivity premise.
-/
theorem universe_no_surjection_from_member (V : Type u) [SetTheoryBasis V]
    (n : Nat) (A : V) (g : V → V)
    (hA : SetTheoryBasis.member A (SetTheoryBasis.univ n)) :
    ¬ (∀ z : V, SetTheoryBasis.member z (SetTheoryBasis.univ n) →
      ∃ x : V, SetTheoryBasis.member x A ∧ g x = z) := by
  intro onto
  let D : V := modelSeparation A (fun x => ¬ SetTheoryBasis.member x (g x))
  have hD : SetTheoryBasis.member D (SetTheoryBasis.univ n) :=
    universe_separation_closed V n A _ hA
  obtain ⟨x, hxA, hg⟩ := onto D hD
  have hCharacter : SetTheoryBasis.member x D ↔
      SetTheoryBasis.member x A ∧ ¬ SetTheoryBasis.member x (g x) :=
    member_modelSeparation A _ x
  have hDiagonal : SetTheoryBasis.member x D ↔
      ¬ SetTheoryBasis.member x D := by
    simpa only [hg, hxA, true_and] using hCharacter
  have hn : ¬ SetTheoryBasis.member x D :=
    fun hx => (hDiagonal.mp hx) hx
  exact hn (hDiagonal.mpr hn)

/--
SAME-STAGE image closure follows from the EXISTING Tarski size alternative.
The image need only map members of A into U; no restrictions off A and
no image-closure field are added to the mathematical model interface.
-/
theorem universe_image_closed (V : Type u) [SetTheoryBasis V]
    (n : Nat) (A : V) (F : V → V)
    (hA : SetTheoryBasis.member A (SetTheoryBasis.univ n))
    (hValues : ∀ x : V, SetTheoryBasis.member x A →
      SetTheoryBasis.member (F x) (SetTheoryBasis.univ n)) :
    SetTheoryBasis.member (SetTheoryBasis.image F A) (SetTheoryBasis.univ n) := by
  have hSubset : ∀ y : V, SetTheoryBasis.member y (SetTheoryBasis.image F A) →
      SetTheoryBasis.member y (SetTheoryBasis.univ n) := by
    intro y hy
    obtain ⟨x, hx, hyx⟩ := (SetTheoryBasis.member_image).mp hy
    simpa only [hyx] using hValues x hx
  rcases (SetTheoryBasis.univ_groth n).2.2.2
      (SetTheoryBasis.image F A) hSubset with hEquinumerous | hSmall
  · obtain ⟨g, _, _, onto⟩ := hEquinumerous
    exfalso
    apply universe_no_surjection_from_member V n A (fun x => g (F x)) hA
    intro z hz
    obtain ⟨y, hy, hgy⟩ := onto z hz
    obtain ⟨x, hx, hyx⟩ := (SetTheoryBasis.member_image).mp hy
    exact ⟨x, hx, (congrArg g hyx).symm.trans hgy⟩
  · exact hSmall

/-- The precise P1f function-graph encoding now belongs to the SAME stage. -/
theorem modelGraph_member_same_univ (V : Type u) [SetTheoryBasis V]
    (n : Nat) (A : V) (F : V → V)
    (hA : SetTheoryBasis.member A (SetTheoryBasis.univ n))
    (hValues : ∀ x : V, SetTheoryBasis.member x A →
      SetTheoryBasis.member (F x) (SetTheoryBasis.univ n)) :
    SetTheoryBasis.member (modelGraph F A) (SetTheoryBasis.univ n) := by
  apply universe_image_closed V n A
    (fun x => modelOrderedPair x (F x)) hA
  intro x hx
  have hX : SetTheoryBasis.member x (SetTheoryBasis.univ n) :=
    SetTheoryBasis.universe_transitive (V := V) n A x hA hx
  exact modelOrderedPair_member_univ V n A x (F x) hA hX (hValues x hx)

#print axioms member_modelSeparation
#print axioms universe_separation_closed
#print axioms universe_no_surjection_from_member
#print axioms universe_image_closed
#print axioms modelGraph_member_same_univ

end PSKernelFast.Spec
