import PSKernelFast.Spec.SetEncoding

/-!
P1f: FINITE SET PAIR CLOSURE, derived from the precise Tarski-size law
in SetTheoryBasis. This is NOT introduced as an extra model assumption.

Method:
1. An inhabited Grothendieck universe contains three distinct sets:
   empty, {empty}, {{empty}}. Derive their membership by subset closure
   and singleton closure (power and subset), not external axioms.
2. Any two-element unordered pair S of members is a subset of U.
3. If S were equinumerous with U, surjectivity from at most TWO
   preimages would cover all three distinct members. Contradiction.
4. The remaining Tarski size disjunct forces S itself to belong to U.

This is a small, self-contained finite Cantor/pigeonhole argument.
It avoids adding a "pair closure" field to the trusted model interface
and will support proving the tagged Prop carrier belongs to Type 1.
-/

namespace PSKernelFast.Spec

universe u
variable {V : Type u} [SetTheoryBasis V]

/-- Empty and its singleton are provably distinct. -/
theorem empty_ne_modelSingleton_empty (V : Type u)
    [SetTheoryBasis V] :
    SetTheoryBasis.emptySet V ≠
      modelSingleton (SetTheoryBasis.emptySet V) := by
  intro h
  have hm : SetTheoryBasis.member (SetTheoryBasis.emptySet V)
      (modelSingleton (SetTheoryBasis.emptySet V)) :=
    modelSingleton_member (SetTheoryBasis.emptySet V)
  have hSelf : SetTheoryBasis.member
      (SetTheoryBasis.emptySet V) (SetTheoryBasis.emptySet V) :=
    Eq.mp (congrArg
      (fun x : V => SetTheoryBasis.member (SetTheoryBasis.emptySet V) x)
      h.symm) hm
  exact SetTheoryBasis.not_member_empty V _ hSelf

/-- Empty also differs from the double singleton. -/
theorem empty_ne_doubleSingleton_empty (V : Type u)
    [SetTheoryBasis V] :
    SetTheoryBasis.emptySet V ≠
      modelSingleton (modelSingleton (SetTheoryBasis.emptySet V)) := by
  intro h
  let s : V := modelSingleton (SetTheoryBasis.emptySet V)
  have hm : SetTheoryBasis.member s
      (modelSingleton s) := modelSingleton_member s
  have hSelf : SetTheoryBasis.member s
      (SetTheoryBasis.emptySet V) :=
    Eq.mp (congrArg (fun x : V => SetTheoryBasis.member s x)
      h.symm) hm
  exact SetTheoryBasis.not_member_empty V s hSelf

/-- The singleton and double singleton cannot agree. -/
theorem singleton_ne_doubleSingleton_empty (V : Type u)
    [SetTheoryBasis V] :
    modelSingleton (SetTheoryBasis.emptySet V) ≠
      modelSingleton (modelSingleton (SetTheoryBasis.emptySet V)) := by
  intro h
  exact empty_ne_modelSingleton_empty V (modelSingleton_inj h)

/--
The FINITE pair closure law follows from the size-alternative clause
of the already assumed Grothendieck-universe matrix. An existing
inhabitant 'seed ∈ U' suffices to derive the three distinct witnesses.
No pair-closure axiom or arbitrary cardinality claim is added.
-/
theorem universe_modelPair_closed (V : Type u)
    [SetTheoryBasis V] (n : Nat) (seed a b : V)
    (hSeed : SetTheoryBasis.member seed (SetTheoryBasis.univ n))
    (ha : SetTheoryBasis.member a (SetTheoryBasis.univ n))
    (hb : SetTheoryBasis.member b (SetTheoryBasis.univ n)) :
    SetTheoryBasis.member (SetTheoryBasis.pair a b)
      (SetTheoryBasis.univ n) := by
  let e : V := SetTheoryBasis.emptySet V
  let s : V := modelSingleton e
  let t : V := modelSingleton s
  have he : SetTheoryBasis.member e (SetTheoryBasis.univ n) :=
    SetTheoryBasis.universe_subset_closed (V := V) n seed e
      hSeed (fun z hz =>
        False.elim (SetTheoryBasis.not_member_empty V z hz))
  have hs : SetTheoryBasis.member s (SetTheoryBasis.univ n) :=
    universe_modelSingleton_closed V n e he
  have ht : SetTheoryBasis.member t (SetTheoryBasis.univ n) :=
    universe_modelSingleton_closed V n s hs
  have hes : e ≠ s := empty_ne_modelSingleton_empty V
  have het : e ≠ t := empty_ne_doubleSingleton_empty V
  have hst : s ≠ t := singleton_ne_doubleSingleton_empty V
  have hSubset : ∀ z : V,
      SetTheoryBasis.member z (SetTheoryBasis.pair a b) →
      SetTheoryBasis.member z (SetTheoryBasis.univ n) := by
    intro z hz
    rcases (SetTheoryBasis.member_pair).mp hz with hz | hz
    · subst z
      exact ha
    · subst z
      exact hb
  rcases (SetTheoryBasis.univ_groth n).2.2.2
      (SetTheoryBasis.pair a b) hSubset with ⟨f, _, _, hSurj⟩ | hMem
  · obtain ⟨i, hi, hfi⟩ := hSurj e he
    obtain ⟨j, hj, hfj⟩ := hSurj s hs
    obtain ⟨k, hk, hfk⟩ := hSurj t ht
    have hPigeon : i = j ∨ i = k ∨ j = k := by
      rcases (SetTheoryBasis.member_pair).mp hi with h | h <;>
      rcases (SetTheoryBasis.member_pair).mp hj with h' | h' <;>
      rcases (SetTheoryBasis.member_pair).mp hk with h'' | h'' <;>
      simp [h, h', h'']
    rcases hPigeon with hij | hik | hjk
    · have heq : e = s :=
        hfi.symm.trans ((congrArg f hij).trans hfj)
      exact False.elim (hes heq)
    · have heq : e = t :=
        hfi.symm.trans ((congrArg f hik).trans hfk)
      exact False.elim (het heq)
    · have heq : s = t :=
        hfj.symm.trans ((congrArg f hjk).trans hfk)
      exact False.elim (hst heq)
  · exact hMem

#print axioms empty_ne_modelSingleton_empty
#print axioms empty_ne_doubleSingleton_empty
#print axioms singleton_ne_doubleSingleton_empty
#print axioms universe_modelPair_closed

end PSKernelFast.Spec
