import Ps.KernelCore.Metatheory.SemanticUniverseSubstitution

/-!
An executable, exact comparison of universe-zero conditions. The design
follows Con Leche's PropWhen boundary, but uses PSKernel's own levels and names,
including metavariables. No upstream checker definitions are imported.

A zero condition is either impossible or a finite conjunction of zero-valued
variables. The comparison ignores list order and multiplicity. Its completeness
theorem quantifies over every valuation, so it does not merely test examples.
This is annotation-comparison infrastructure, not checker soundness.
-/
namespace PsKernelSemantics.UniverseRegime

inductive Atom where
  | param (name : PsKernelName)
  | mvar (name : PsKernelName)
  deriving DecidableEq

inductive Profile where
  | never
  | allZero (variables : List Atom)

def Holds : Profile → (Atom → Nat) → Prop
  | .never, _ => False
  | .allZero xs, ν => ∀ x, x ∈ xs → ν x = 0

def inter : Profile → Profile → Profile
  | .allZero xs, .allZero ys => .allZero (xs ++ ys)
  | _, _ => .never

theorem holds_inter (a b : Profile) (ν : Atom → Nat) :
    Holds (inter a b) ν ↔ Holds a ν ∧ Holds b ν := by
  cases a <;> cases b <;>
    simp only [inter, Holds, false_and, and_false, iff_self, List.mem_append]
  constructor
  · intro h
    exact ⟨fun x hx => h x (.inl hx), fun x hx => h x (.inr hx)⟩
  · rintro ⟨ha, hb⟩ x (hx | hx)
    · exact ha x hx
    · exact hb x hx

def ofLevel : PsKernelLevel → Profile
  | .zero => .allZero []
  | .succ _ => .never
  | .max a b => inter (ofLevel a) (ofLevel b)
  | .imax _ b => ofLevel b
  | .param n => .allZero [.param n]
  | .mvar n => .allZero [.mvar n]

def valuation (params metavariables : PsKernelName → Nat) : Atom → Nat
  | .param n => params n
  | .mvar n => metavariables n

theorem ofLevel_spec (l : PsKernelLevel) (params metavariables : PsKernelName → Nat) :
    Holds (ofLevel l) (valuation params metavariables) ↔
      evalLevel params metavariables l = 0 := by
  induction l with
  | zero => simp [ofLevel, Holds, evalLevel]
  | succ l ih => simp [ofLevel, Holds, evalLevel]
  | param n | mvar n => simp [ofLevel, Holds, valuation, evalLevel]
  | max a b iha ihb =>
      simp only [ofLevel, holds_inter, iha, ihb, evalLevel]
      omega
  | imax a b iha ihb =>
      simp only [ofLevel, ihb, evalLevel]
      split <;> omega

def subset (xs ys : List Atom) : Bool :=
  xs.all (fun x => decide (x ∈ ys))

def compare : Profile → Profile → Bool
  | .never, .never => true
  | .allZero xs, .allZero ys => subset xs ys && subset ys xs
  | _, _ => false

theorem subset_spec (xs ys : List Atom) :
    subset xs ys = true ↔ ∀ x, x ∈ xs → x ∈ ys := by
  simp [subset, List.all_eq_true]

private theorem separating (xs ys : List Atom)
    (h : ∀ ν, Holds (.allZero xs) ν ↔ Holds (.allZero ys) ν) :
    ∀ x, x ∈ xs → x ∈ ys := by
  intro x hx
  by_cases hn : x ∈ ys
  · exact hn
  · let ν : Atom → Nat := fun y => if y = x then 1 else 0
    have hy : Holds (.allZero ys) ν := by
      intro y hy
      have ne : y ≠ x := by intro he; subst y; exact hn hy
      simp [ν, ne]
    have impossible := (h ν).mpr hy x hx
    simp [ν] at impossible

theorem compare_spec (a b : Profile) :
    compare a b = true ↔ ∀ ν, Holds a ν ↔ Holds b ν := by
  cases a with
  | never =>
      cases b with
      | never => simp [compare]
      | allZero ys =>
          simp only [compare, Bool.false_eq_true, false_iff]
          intro h
          have hzero : Holds (.allZero ys) (fun _ => 0) := fun _ _ => rfl
          exact (h _).mpr hzero
  | allZero xs =>
      cases b with
      | never =>
          simp only [compare, Bool.false_eq_true, false_iff]
          intro h
          have hzero : Holds (.allZero xs) (fun _ => 0) := fun _ _ => rfl
          exact (h _).mp hzero
      | allZero ys =>
          rw [compare, Bool.and_eq_true, subset_spec, subset_spec]
          constructor
          · rintro ⟨hxy, hyx⟩ ν
            exact ⟨fun hx y hy => hx y (hyx y hy), fun hy x hx => hy x (hxy x hx)⟩
          · intro h
            exact ⟨separating xs ys h, separating ys xs (fun ν => (h ν).symm)⟩

def check (a b : PsKernelLevel) : Bool := compare (ofLevel a) (ofLevel b)

/-- A successful comparison is exactly uniform Prop/Type-regime agreement.
Parameters and metavariables remain distinct even when they share a name. -/
theorem check_spec (a b : PsKernelLevel) :
    check a b = true ↔ ∀ params metavariables : PsKernelName → Nat,
      (evalLevel params metavariables a = 0 ↔ evalLevel params metavariables b = 0) := by
  rw [check, compare_spec]
  constructor
  · intro h params metavariables
    simpa only [ofLevel_spec] using h (valuation params metavariables)
  · intro h ν
    have hv : valuation (fun n => ν (.param n)) (fun n => ν (.mvar n)) = ν := by
      funext x; cases x <;> rfl
    rw [← hv, ofLevel_spec, ofLevel_spec]
    exact h _ _

theorem check_refl (a : PsKernelLevel) : check a a = true :=
  (check_spec a a).mpr (fun _ _ => Iff.rfl)

theorem check_symm {a b : PsKernelLevel} (h : check a b = true) :
    check b a = true :=
  (check_spec b a).mpr (fun p m => ((check_spec a b).mp h p m).symm)

theorem check_trans {a b c : PsKernelLevel}
    (hab : check a b = true) (hbc : check b c = true) : check a c = true :=
  (check_spec a c).mpr (fun p m =>
    ((check_spec a b).mp hab p m).trans ((check_spec b c).mp hbc p m))

/-- Production universe instantiation preserves a checked agreement, including
duplicate/missing parameter behavior of the actual lookup operation. -/
theorem check_instParams (a b : PsKernelLevel)
    (names : List PsKernelName) (values : List PsKernelLevel)
    (h : check a b = true) :
    check (psKernelLevelInstantiateParams a names values)
      (psKernelLevelInstantiateParams b names values) = true := by
  apply (check_spec _ _).mpr
  intro params metavariables
  rw [instantiateParams_eval, instantiateParams_eval]
  exact (check_spec a b).mp h _ _

theorem check_imax_right (a b : PsKernelLevel) : check (.imax a b) b = true :=
  check_refl b

theorem check_max_comm (a b : PsKernelLevel) : check (.max a b) (.max b a) = true := by
  apply (check_spec _ _).mpr
  intro p m
  simp only [evalLevel, Nat.max_comm]

theorem check_zero_succ (a : PsKernelLevel) : check .zero (.succ a) = false := rfl

theorem check_param_mvar (n : PsKernelName) : check (.param n) (.mvar n) = false := by
  simp [check, compare, subset, ofLevel]

/-- Equal zero conditions do not equate universe levels. This check must only
be used for the semantic regime of binder annotations. -/
theorem same_regime_not_same_level :
    check (.succ .zero) (.succ (.succ .zero)) = true ∧
      ∀ p m, evalLevel p m (.succ .zero) ≠ evalLevel p m (.succ (.succ .zero)) := by
  exact ⟨rfl, fun _ _ => by simp [evalLevel]⟩

def isNever : Profile → Bool
  | .never => true
  | .allZero _ => false

theorem isNever_inter (a b : Profile) :
    isNever (inter a b) = (isNever a || isNever b) := by
  cases a <;> cases b <;> rfl

theorem isNever_ofLevel (l : PsKernelLevel) :
    isNever (ofLevel l) = psKernelLevelIsNotZero l := by
  induction l with
  | zero | succ _ | param _ | mvar _ => rfl
  | imax a b iha ihb => exact ihb
  | max a b iha ihb =>
      rw [ofLevel, isNever_inter, iha, ihb]
      cases ha : psKernelLevelIsNotZero a <;> simp [psKernelLevelIsNotZero, ha]

/-- The existing production test is the exact uniform positive-regime gate.
Failure of this test does not mean zero at every valuation. -/
theorem native_positive_spec (l : PsKernelLevel) :
    psKernelLevelIsNotZero l = true ↔
      ∀ p m : PsKernelName → Nat, evalLevel p m l ≠ 0 := by
  rw [← isNever_ofLevel]
  cases hp : ofLevel l with
  | never =>
      constructor
      · intro _ p m hz
        have impossible := (ofLevel_spec l p m).mpr hz
        simpa only [hp, Holds] using impossible
      · intro _; rfl
  | allZero xs =>
      constructor
      · intro h; cases h
      · intro h
        have zero : evalLevel (fun _ => 0) (fun _ => 0) l = 0 := by
          apply (ofLevel_spec l _ _).mp
          rw [hp]
          intro x _
          cases x <;> rfl
        exact False.elim (h _ _ zero)


end PsKernelSemantics.UniverseRegime
