import PSKernelFast.Spec.FiniteUniverseClosure

/-!
P1j proof-only finite-graph universe closure, independent of runtime G4.4.

The Grothendieck universe laws already imply finite ordered-pair closure
from an inhabited stage. A graph whose source set and all pointwise
codomain values live at stage n consists only of stage-n ordered pairs.
Hence it belongs to the SUCCESSOR universe via subset closure and the
existing univ(n) ∈ univ(n+1) law.

IMPORTANT: this is NOT graph membership in the SAME stage, a Type-valued
dependent Pi/eta/application model, proof irrelevance, or full consistency.
No image-closure axiom has been added. The explicit successor rank is a
real mathematical limit of this small theorem, not a silent Lean universe
shift to be considered harmless.
-/

namespace PSKernelFast.Spec

universe u

/-- Kuratowski ordered pairs of existing stage members remain in the stage. -/
theorem modelOrderedPair_member_univ
    (V : Type u) [SetTheoryBasis V] (n : Nat)
    (seed a b : V)
    (hSeed : SetTheoryBasis.member seed (SetTheoryBasis.univ n))
    (ha : SetTheoryBasis.member a (SetTheoryBasis.univ n))
    (hb : SetTheoryBasis.member b (SetTheoryBasis.univ n)) :
    SetTheoryBasis.member
      (modelOrderedPair a b) (SetTheoryBasis.univ n) := by
  have hSingleton :
      SetTheoryBasis.member (modelSingleton a)
        (SetTheoryBasis.univ n) :=
    universe_modelSingleton_closed V n a ha
  have hInnerPair :
      SetTheoryBasis.member (SetTheoryBasis.pair a b)
        (SetTheoryBasis.univ n) :=
    universe_modelPair_closed V n seed a b hSeed ha hb
  exact universe_modelPair_closed V n seed
    (modelSingleton a) (SetTheoryBasis.pair a b)
    hSeed hSingleton hInnerPair

/--
A bounded graph belongs to the NEXT stage, even without the much stronger
universe image-closure law that would put it in the original stage.
The actual membership subset is proved using the same concrete
Kuratowski graph representation as P1f's noncollision theorem.
-/
theorem modelGraph_member_successor_univ
    (V : Type u) [SetTheoryBasis V] (n : Nat)
    (A : V) (F : V → V)
    (hA : SetTheoryBasis.member A (SetTheoryBasis.univ n))
    (hValues : ∀ x : V,
      SetTheoryBasis.member x A →
        SetTheoryBasis.member (F x) (SetTheoryBasis.univ n)) :
    SetTheoryBasis.member (modelGraph F A)
      (SetTheoryBasis.univ (n + 1)) := by
  have hStage : SetTheoryBasis.member
      (SetTheoryBasis.univ n : V) (SetTheoryBasis.univ (n + 1)) :=
    SetTheoryBasis.universe_step (V := V) n
  apply SetTheoryBasis.universe_subset_closed (V := V) (n + 1)
    (SetTheoryBasis.univ n) (modelGraph F A) hStage
  intro z hz
  obtain ⟨x, hx, hzx⟩ := (member_modelGraph F A z).mp hz
  subst z
  have hX : SetTheoryBasis.member x (SetTheoryBasis.univ n) :=
    SetTheoryBasis.universe_transitive (V := V) n A x hA hx
  exact modelOrderedPair_member_univ V n A x (F x)
    hA hX (hValues x hx)

#print axioms modelOrderedPair_member_univ
#print axioms modelGraph_member_successor_univ

end PSKernelFast.Spec
