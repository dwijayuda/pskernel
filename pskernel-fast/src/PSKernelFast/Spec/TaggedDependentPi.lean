import PSKernelFast.Spec.GraphApplication
import PSKernelFast.Spec.TaggedPropSemantics

/-!
P1l: one coherent dependent-Pi/lambda/application SET-MODEL algebra.

A Pi whose codomain sort is Prop uses the existing tagged truth carrier;
its lambda value is the distinguished point. A positive-sort Pi uses the
existing universe-closed graph carrier. Application is UNIFORM: point
maps to point, otherwise perform graph application. It needs no caller
supplied domain, fibre, sort annotation or proof witness. The existing
concrete graph/non-point theorem justifies this distinction.

Formation uses the EXACT numeric imax of the domain/codomain sort ranks,
with the already adopted positive carrier shift U_(rank+1); there is no
additional successor introduced for Pi. Model-level inclusion of carriers
is used only inside this proof, NOT as a new source cumulativity rule.

All results require the unchanged [SetTheoryBasis V]. Fibre/term semantic
membership hypotheses are explicit; deriving them from the actual source
checker, handling substitution and validating annotations remain OPEN.
This is NOT yet a source interpreter, full Lean soundness, consistency,
quotient model, executable conversion rule or accepting API.
-/

namespace PSKernelFast.Spec

open PSKernelFast.Core
universe u
variable {V : Type u} [SetTheoryBasis V]

/-- Codomain sort selects impredicative Prop or the graph-valued carrier. -/
noncomputable def modelPi (V : Type u) [SetTheoryBasis V]
    (codomainLevel : Nat) (A : V) (B : V → V) : V :=
  match codomainLevel with
  | 0 => taggedPropPi V A B
  | _ + 1 => modelGraphPi A B

/-- Proof-valued lambdas collapse to point; data-valued lambdas are graphs. -/
noncomputable def modelLam (V : Type u) [SetTheoryBasis V]
    (codomainLevel : Nat) (A : V) (F : V → V) : V :=
  match codomainLevel with
  | 0 => taggedPoint V
  | _ + 1 => modelGraph F A

/-- Uniform proof-only semantic application. Malformed inputs have no typing law. -/
noncomputable def modelApp (V : Type u) [SetTheoryBasis V] (f x : V) : V := by
  classical
  exact if f = taggedPoint V then taggedPoint V else modelGraphApp f x

theorem modelApp_point (V : Type u) [SetTheoryBasis V] (x : V) :
    modelApp V (taggedPoint V) x = taggedPoint V := by
  simp only [modelApp, ite_true]

theorem modelApp_graph (V : Type u) [SetTheoryBasis V]
    (A : V) (F : V → V) (x : V) :
    modelApp V (modelGraph F A) x = modelGraphApp (modelGraph F A) x := by
  have h : modelGraph F A ≠ taggedPoint V :=
    fun heq => taggedPoint_ne_graph V F A heq.symm
  simp only [modelApp, h, ite_false]

private theorem universe_member_mono (n m : Nat) (x : V)
    (hx : SetTheoryBasis.member x (SetTheoryBasis.univ n)) :
    n ≤ m → SetTheoryBasis.member x (SetTheoryBasis.univ m) := by
  induction m with
  | zero =>
      intro h
      have hn : n = 0 := by omega
      simpa only [hn] using hx
  | succ m ih =>
      intro h
      by_cases hnm : n ≤ m
      · exact SetTheoryBasis.universe_transitive (V := V) (m + 1)
          (SetTheoryBasis.univ m) x (SetTheoryBasis.univ_step m) (ih hnm)
      · have hn : n = m + 1 := by omega
        simpa only [hn] using hx

private theorem taggedSortSet_of_pos (V : Type u) [SetTheoryBasis V]
    (n : Nat) (hn : 0 < n) :
    taggedSortSet V n = SetTheoryBasis.univ (n + 1) := by
  cases n with
  | zero => omega
  | succ n => rfl

/-- Mathematical inclusion only; it does not grant source type conversion. -/
private theorem sort_member_common_univ (V : Type u) [SetTheoryBasis V]
    (rank upper : Nat) (x : V) (hUpper : 0 < upper) (hRank : rank ≤ upper)
    (hx : SetTheoryBasis.member x (taggedSortSet V rank)) :
    SetTheoryBasis.member x (SetTheoryBasis.univ (upper + 1)) := by
  cases rank with
  | zero =>
      have hx2 : SetTheoryBasis.member x (SetTheoryBasis.univ 2) :=
        SetTheoryBasis.universe_transitive (V := V) 2 (taggedProp V) x
          (taggedProp_mem_typeOne V) hx
      exact universe_member_mono 2 (upper + 1) x hx2 (by omega)
  | succ rank =>
      exact universe_member_mono (rank + 2) (upper + 1) x hx (by omega)

/-- Exact imax formation, including impredicativity and mixed Prop/Type domains. -/
theorem modelPi_member_sort (V : Type u) [SetTheoryBasis V]
    (domainLevel codomainLevel : Nat) (A : V) (B : V → V)
    (hA : SetTheoryBasis.member A (taggedSortSet V domainLevel))
    (hB : ∀ x : V, SetTheoryBasis.member x A →
      SetTheoryBasis.member (B x) (taggedSortSet V codomainLevel)) :
    SetTheoryBasis.member (modelPi V codomainLevel A B)
      (taggedSortSet V (numericImax domainLevel codomainLevel)) := by
  cases codomainLevel with
  | zero => exact taggedPropPi_member_prop V A B
  | succ v =>
      have hPos : 0 < Nat.max domainLevel (v + 1) :=
        Nat.lt_of_lt_of_le (Nat.zero_lt_succ v) (Nat.le_max_right _ _)
      change SetTheoryBasis.member (modelGraphPi A B)
        (taggedSortSet V (Nat.max domainLevel (v + 1)))
      rw [taggedSortSet_of_pos V _ hPos]
      apply modelGraphPi_member_univ V (Nat.max domainLevel (v + 1) + 1) A B
      · exact sort_member_common_univ V domainLevel _ A hPos (Nat.le_max_left _ _) hA
      · intro x hx
        exact sort_member_common_univ V (v + 1) _ (B x) hPos
          (Nat.le_max_right _ _) (hB x hx)

/-- One introduction law for both proof-valued and data-valued lambdas. -/
theorem modelLam_intro (V : Type u) [SetTheoryBasis V]
    (v : Nat) (A : V) (B F : V → V)
    (hB : ∀ x : V, SetTheoryBasis.member x A →
      SetTheoryBasis.member (B x) (taggedSortSet V v))
    (hF : ∀ x : V, SetTheoryBasis.member x A → SetTheoryBasis.member (F x) (B x)) :
    SetTheoryBasis.member (modelLam V v A F) (modelPi V v A B) := by
  cases v with
  | zero =>
      have hAll : ∀ x : V, SetTheoryBasis.member x A → B x = taggedTrue V := by
        intro x hx
        exact (taggedProp_inhabited_iff_true V (B x) (hB x hx)).mp ⟨F x, hF x hx⟩
      change SetTheoryBasis.member (taggedPoint V) (taggedPropPi V A B)
      rw [(taggedPropPi_true_iff V A B).mpr hAll]
      exact taggedPoint_member_true V
  | succ v => exact modelGraphPi_intro A B F hF

/-- Uniform application elimination; the result inhabits the actual fibre. -/
theorem modelPi_elim (V : Type u) [SetTheoryBasis V]
    (v : Nat) (A : V) (B : V → V) (f x : V)
    (hf : SetTheoryBasis.member f (modelPi V v A B))
    (hx : SetTheoryBasis.member x A) :
    SetTheoryBasis.member (modelApp V f x) (B x) := by
  cases v with
  | zero =>
      have hp := taggedPropPi_member_prop V A B
      have hPoint : f = taggedPoint V :=
        taggedProp_member_only_point V _ f hp hf
      have hTrue : taggedPropPi V A B = taggedTrue V :=
        (taggedProp_inhabited_iff_true V _ hp).mp ⟨f, hf⟩
      have hBx := (taggedPropPi_true_iff V A B).mp hTrue x hx
      rw [hPoint, modelApp_point, hBx]
      exact taggedPoint_member_true V
  | succ v =>
      obtain ⟨F, hF, hGraph⟩ := (member_modelGraphPi A B f).mp hf
      rw [hGraph, modelApp_graph, modelGraphApp_beta A F x hx]
      exact hF x hx

/-- Beta for both regimes, using derived graph functionality and proof uniqueness. -/
theorem modelPi_beta (V : Type u) [SetTheoryBasis V]
    (v : Nat) (A : V) (B F : V → V) (x : V)
    (hB : ∀ y : V, SetTheoryBasis.member y A →
      SetTheoryBasis.member (B y) (taggedSortSet V v))
    (hF : ∀ y : V, SetTheoryBasis.member y A → SetTheoryBasis.member (F y) (B y))
    (hx : SetTheoryBasis.member x A) :
    modelApp V (modelLam V v A F) x = F x := by
  cases v with
  | zero =>
      change modelApp V (taggedPoint V) x = F x
      rw [modelApp_point]
      exact (taggedProp_member_only_point V (B x) (F x) (hB x hx) (hF x hx)).symm
  | succ v =>
      change modelApp V (modelGraph F A) x = F x
      rw [modelApp_graph, modelGraphApp_beta A F x hx]

/-- Lambda congruence needs body equality only on the domain, even when empty. -/
theorem modelLam_congr (V : Type u) [SetTheoryBasis V]
    (v : Nat) (A : V) (F G : V → V)
    (h : ∀ x : V, SetTheoryBasis.member x A → F x = G x) :
    modelLam V v A F = modelLam V v A G := by
  cases v with
  | zero => rfl
  | succ v => exact modelGraph_ext A F G h

/-- Eta holds for every member of either Pi carrier. -/
theorem modelPi_eta (V : Type u) [SetTheoryBasis V]
    (v : Nat) (A : V) (B : V → V) (f : V)
    (hf : SetTheoryBasis.member f (modelPi V v A B)) :
    modelLam V v A (fun x => modelApp V f x) = f := by
  cases v with
  | zero =>
      exact (taggedProp_member_only_point V _ f (taggedPropPi_member_prop V A B) hf).symm
  | succ v =>
      obtain ⟨F, _, hGraph⟩ := (member_modelGraphPi A B f).mp hf
      subst f
      apply modelGraph_ext A _ F
      intro x hx
      rw [modelApp_graph, modelGraphApp_beta A F x hx]

/-- Extensionality follows from eta and on-domain congruence, without a new law. -/
theorem modelPi_ext (V : Type u) [SetTheoryBasis V]
    (v : Nat) (A : V) (B : V → V) (f g : V)
    (hf : SetTheoryBasis.member f (modelPi V v A B))
    (hg : SetTheoryBasis.member g (modelPi V v A B))
    (h : ∀ x : V, SetTheoryBasis.member x A → modelApp V f x = modelApp V g x) :
    f = g := by
  calc
    f = modelLam V v A (fun x => modelApp V f x) := (modelPi_eta V v A B f hf).symm
    _ = modelLam V v A (fun x => modelApp V g x) := modelLam_congr V v A _ _ h
    _ = g := modelPi_eta V v A B g hg

/-- Pi congruence for families agreeing only on the common domain. -/
theorem modelPi_congr (V : Type u) [SetTheoryBasis V]
    (v : Nat) (A : V) (B C : V → V)
    (h : ∀ x : V, SetTheoryBasis.member x A → B x = C x) :
    modelPi V v A B = modelPi V v A C := by
  classical
  cases v with
  | zero =>
      by_cases hb : ∀ x : V, SetTheoryBasis.member x A → B x = taggedTrue V
      · have hc : ∀ x : V, SetTheoryBasis.member x A → C x = taggedTrue V :=
          fun x hx => (h x hx).symm.trans (hb x hx)
        simp only [modelPi, taggedPropPi, hb, hc, ite_true]
      · have hc : ¬ ∀ x : V, SetTheoryBasis.member x A → C x = taggedTrue V :=
          fun hall => hb (fun x hx => (h x hx).trans (hall x hx))
        simp only [modelPi, taggedPropPi, hb, hc, ite_false]
  | succ v =>
      apply SetTheoryBasis.ext
      intro f
      change SetTheoryBasis.member f (modelGraphPi A B) ↔
        SetTheoryBasis.member f (modelGraphPi A C)
      constructor
      · intro hf
        obtain ⟨F, hF, hGraph⟩ := (member_modelGraphPi A B f).mp hf
        apply (member_modelGraphPi A C f).mpr
        refine ⟨F, ?_, hGraph⟩
        intro x hx
        rw [← h x hx]
        exact hF x hx
      · intro hf
        obtain ⟨F, hF, hGraph⟩ := (member_modelGraphPi A C f).mp hf
        apply (member_modelGraphPi A B f).mpr
        refine ⟨F, ?_, hGraph⟩
        intro x hx
        rw [h x hx]
        exact hF x hx

#print axioms modelApp_point
#print axioms modelApp_graph
#print axioms modelPi_member_sort
#print axioms modelLam_intro
#print axioms modelPi_elim
#print axioms modelPi_beta
#print axioms modelLam_congr
#print axioms modelPi_eta
#print axioms modelPi_ext
#print axioms modelPi_congr

end PSKernelFast.Spec
