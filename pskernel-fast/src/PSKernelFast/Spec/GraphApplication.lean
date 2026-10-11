import PSKernelFast.Spec.DependentGraphSpace

/-!
P1l: application, beta and eta for the ACTUAL P1k dependent graph carrier.

The application operation depends only on a graph value and an argument,
not on its presentation witness, domain, fibre family or a typing proof.
Functionality is derived from Kuratowski injectivity, not assumed.

This module is proof-only. Its total noncomputable application chooses a
related value when one exists, and defaults to the empty set otherwise.
Only membership in modelGraphPi plus domain membership justifies using
its result as a typed application. The fallback is NOT kernel acceptance.
No source checker, reduction rule, set-theory basis or admission changes.
-/

namespace PSKernelFast.Spec

universe u
variable {V : Type u} [SetTheoryBasis V]

private theorem orderedPair_common_member (a b z : V) :
    (∀ t : V, SetTheoryBasis.member t (modelOrderedPair a b) →
      SetTheoryBasis.member z t) ↔ z = a := by
  constructor
  · intro h
    exact (member_modelSingleton z a).mp
      (h (modelSingleton a) ((member_modelOrderedPair _ a b).mpr (Or.inl rfl)))
  · intro h t ht
    subst z
    rcases (member_modelOrderedPair t a b).mp ht with ht | ht
    · subst t
      exact modelSingleton_member a
    · subst t
      exact (SetTheoryBasis.member_pair).mpr (Or.inl rfl)

private theorem union_orderedPair (a b : V) :
    SetTheoryBasis.union (modelOrderedPair a b) = SetTheoryBasis.pair a b := by
  apply SetTheoryBasis.ext
  intro z
  constructor
  · intro hz
    obtain ⟨t, ht, hzt⟩ := (SetTheoryBasis.member_union).mp hz
    rcases (member_modelOrderedPair t a b).mp ht with ht | ht
    · subst t
      exact (SetTheoryBasis.member_pair).mpr
        (Or.inl ((member_modelSingleton z a).mp hzt))
    · subst t
      exact hzt
  · intro hz
    exact (SetTheoryBasis.member_union).mpr
      ⟨SetTheoryBasis.pair a b,
        (member_modelOrderedPair _ a b).mpr (Or.inr rfl), hz⟩

/-- Injectivity of the concrete {{a},{a,b}} encoding, including a=b. -/
theorem modelOrderedPair_inj {a b c d : V}
    (h : modelOrderedPair a b = modelOrderedPair c d) : a = c ∧ b = d := by
  have hac : a = c := (orderedPair_common_member c d a).mp (by
    intro t ht
    exact ((orderedPair_common_member a b a).mpr rfl) t (h.symm ▸ ht))
  subst c
  have hu : SetTheoryBasis.pair a b = SetTheoryBasis.pair a d := by
    simpa only [union_orderedPair] using congrArg SetTheoryBasis.union h
  have hb : b = a ∨ b = d := (SetTheoryBasis.member_pair).mp
    (hu ▸ (SetTheoryBasis.member_pair).mpr (Or.inr (rfl : b = b)))
  have hd : d = a ∨ d = b := (SetTheoryBasis.member_pair).mp
    (hu.symm ▸ (SetTheoryBasis.member_pair).mpr (Or.inr (rfl : d = d)))
  refine ⟨rfl, ?_⟩
  rcases hb with hb | hb
  · rcases hd with hd | hd
    · exact hb.trans hd.symm
    · exact hd.symm
  · exact hb

/-- Pair membership in a graph uniquely identifies argument and result. -/
theorem orderedPair_member_modelGraph (F : V → V) (A x y : V) :
    SetTheoryBasis.member (modelOrderedPair x y) (modelGraph F A) ↔
      SetTheoryBasis.member x A ∧ y = F x := by
  constructor
  · intro h
    obtain ⟨z, hz, hp⟩ := (member_modelGraph F A _).mp h
    obtain ⟨hxz, hy⟩ := modelOrderedPair_inj hp
    subst z
    exact ⟨hz, hy⟩
  · rintro ⟨hx, hy⟩
    exact (member_modelGraph F A _).mpr ⟨x, hx, congrArg (modelOrderedPair x) hy⟩

/-- Equality only ON the domain suffices; off-domain function values do not matter. -/
theorem modelGraph_ext (A : V) (F G : V → V)
    (h : ∀ x : V, SetTheoryBasis.member x A → F x = G x) :
    modelGraph F A = modelGraph G A := by
  apply SetTheoryBasis.ext
  intro z
  constructor
  · intro hz
    obtain ⟨x, hx, hzPair⟩ := (member_modelGraph F A z).mp hz
    exact (member_modelGraph G A z).mpr
      ⟨x, hx, hzPair.trans (congrArg (modelOrderedPair x) (h x hx))⟩
  · intro hz
    obtain ⟨x, hx, hzPair⟩ := (member_modelGraph G A z).mp hz
    exact (member_modelGraph F A z).mpr
      ⟨x, hx, hzPair.trans (congrArg (modelOrderedPair x) (h x hx).symm)⟩

/-- Two outputs related to one argument by the same graph are equal. -/
theorem modelGraph_functional (A : V) (F : V → V) (x y z : V)
    (hy : SetTheoryBasis.member (modelOrderedPair x y) (modelGraph F A))
    (hz : SetTheoryBasis.member (modelOrderedPair x z) (modelGraph F A)) : y = z :=
  ((orderedPair_member_modelGraph F A x y).mp hy).2.trans
    ((orderedPair_member_modelGraph F A x z).mp hz).2.symm

/-- Proof-only graph lookup; never a runtime checker or an admission decision. -/
noncomputable def modelGraphApp (graph x : V) : V := by
  classical
  exact if h : ∃ y : V, SetTheoryBasis.member (modelOrderedPair x y) graph
    then Classical.choose h else SetTheoryBasis.emptySet V

/-- Actual graph application satisfies beta on EVERY argument in the domain. -/
theorem modelGraphApp_beta (A : V) (F : V → V) (x : V)
    (hx : SetTheoryBasis.member x A) :
    modelGraphApp (modelGraph F A) x = F x := by
  classical
  have hex : ∃ y : V,
      SetTheoryBasis.member (modelOrderedPair x y) (modelGraph F A) :=
    ⟨F x, (orderedPair_member_modelGraph F A x (F x)).mpr ⟨hx, rfl⟩⟩
  have hRelated : SetTheoryBasis.member
      (modelOrderedPair x (modelGraphApp (modelGraph F A) x)) (modelGraph F A) := by
    simpa only [modelGraphApp, dif_pos hex] using Classical.choose_spec hex
  exact ((orderedPair_member_modelGraph F A x _).mp hRelated).2

/-- Lambda introduction into the already-defined P1k graph carrier. -/
theorem modelGraphPi_intro (A : V) (B F : V → V)
    (hF : ∀ x : V, SetTheoryBasis.member x A → SetTheoryBasis.member (F x) (B x)) :
    SetTheoryBasis.member (modelGraph F A) (modelGraphPi A B) :=
  (member_modelGraphPi A B _).mpr ⟨F, hF, rfl⟩

/-- Application elimination for all members of the dependent graph carrier. -/
theorem modelGraphPi_app_member (A : V) (B : V → V) (graph x : V)
    (hg : SetTheoryBasis.member graph (modelGraphPi A B))
    (hx : SetTheoryBasis.member x A) :
    SetTheoryBasis.member (modelGraphApp graph x) (B x) := by
  obtain ⟨F, hF, hGraph⟩ := (member_modelGraphPi A B graph).mp hg
  rw [hGraph, modelGraphApp_beta A F x hx]
  exact hF x hx

/-- Eta: reconstructing any typed graph from its application returns that graph. -/
theorem modelGraphPi_eta (A : V) (B : V → V) (graph : V)
    (hg : SetTheoryBasis.member graph (modelGraphPi A B)) :
    modelGraph (fun x => modelGraphApp graph x) A = graph := by
  obtain ⟨F, _, hGraph⟩ := (member_modelGraphPi A B graph).mp hg
  subst graph
  exact modelGraph_ext A _ F (fun x hx => modelGraphApp_beta A F x hx)

/-- Typed graph extensionality is derived from eta, not added as a model law. -/
theorem modelGraphPi_ext (A : V) (B : V → V) (f g : V)
    (hf : SetTheoryBasis.member f (modelGraphPi A B))
    (hg : SetTheoryBasis.member g (modelGraphPi A B))
    (h : ∀ x : V, SetTheoryBasis.member x A → modelGraphApp f x = modelGraphApp g x) :
    f = g := by
  calc
    f = modelGraph (fun x => modelGraphApp f x) A := (modelGraphPi_eta A B f hf).symm
    _ = modelGraph (fun x => modelGraphApp g x) A := modelGraph_ext A _ _ h
    _ = g := modelGraphPi_eta A B g hg

#print axioms modelOrderedPair_inj
#print axioms orderedPair_member_modelGraph
#print axioms modelGraph_ext
#print axioms modelGraph_functional
#print axioms modelGraphApp_beta
#print axioms modelGraphPi_intro
#print axioms modelGraphPi_app_member
#print axioms modelGraphPi_eta
#print axioms modelGraphPi_ext

end PSKernelFast.Spec
