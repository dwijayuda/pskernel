import Ps.KernelCore.Core.Expr
import Lean

private theorem c0_bound_lt_max (o a b : Nat) :
    (o < Nat.max a b) ↔ (o < a ∨ o < b) := by
  change (o < max a b) ↔ (o < a ∨ o < b)
  rcases Nat.le_total a b with hab | hba
  · rw [Nat.max_eq_right hab]
    constructor
    · intro h; exact Or.inr h
    · intro h
      rcases h with ha | hb
      · exact Nat.lt_of_lt_of_le ha hab
      · exact hb
  · rw [Nat.max_eq_left hba]
    constructor
    · intro h; exact Or.inl h
    · intro h
      rcases h with ha | hb
      · exact ha
      · exact Nat.lt_of_lt_of_le hb hba

private theorem c0_bound_lt_pred (o a : Nat) :
    (o < a - 1) ↔ (o + 1 < a) := by omega

private theorem c0_bound_lt_succ (o a : Nat) :
    (o < a + 1) ↔ (o ≤ a) := by omega

private theorem c0_bool_eq_of_true_iff (x y : Bool)
    (h : (x = true) ↔ (y = true)) : x = y := by
  cases x <;> cases y <;> simp_all

private theorem c0_bound_blt_ble (o a : Nat) :
    Nat.blt o (a + 1) = Nat.ble o a := by
  apply c0_bool_eq_of_true_iff
  simpa only [Nat.blt_eq, Nat.ble_eq, Nat.lt_succ_iff]
    using (Iff.rfl : (o ≤ a) ↔ (o ≤ a))

private theorem c0_bound_blt_max (o a b : Nat) :
    Nat.blt o (Nat.max a b) =
      (Nat.blt o a || Nat.blt o b) := by
  apply c0_bool_eq_of_true_iff
  simpa only [Nat.blt_eq, Bool.or_eq_true]
    using c0_bound_lt_max o a b

private theorem c0_bound_blt_pred (o a : Nat) :
    Nat.blt o (a - 1) = Nat.blt (o + 1) a := by
  apply c0_bool_eq_of_true_iff
  simpa only [Nat.blt_eq] using c0_bound_lt_pred o a

private theorem c0_bound_blt_zero (n : Nat) : Nat.blt n 0 = false := by
  cases h : Nat.blt n 0 with
  | false => rfl
  | true =>
      have impossible : n < 0 := (Nat.blt_eq).mp h
      omega

/-- All-input complete equivalence to the original recursive source
    algorithm, including every binding-depth and let-domain case.
    This proof is checked by Lean 4.35.0, not runtime metadata. -/
theorem c0LooseBVarBound_source (expr : PsKernelExpr) (offset : Nat) :
    psKernelC0HasLooseBVarFast expr offset =
      psKernelExprHasLooseAt expr offset := by
  induction expr generalizing offset with
  | app fn arg ihf iha =>
      simp only [psKernelC0HasLooseBVarFast,
        PsKernelExpr.psKernelC0LooseBVarBound, psKernelExprHasLooseAt]
      simp only [psKernelC0HasLooseBVarFast] at ihf iha
      rw [c0_bound_blt_max, ihf offset, iha offset]
      cases psKernelExprHasLooseAt fn offset <;> rfl
  | lam name ty body bi iht ihb =>
      simp only [psKernelC0HasLooseBVarFast,
        PsKernelExpr.psKernelC0LooseBVarBound, psKernelExprHasLooseAt]
      simp only [psKernelC0HasLooseBVarFast] at iht ihb
      rw [c0_bound_blt_max, c0_bound_blt_pred,
        iht offset, ihb (offset + 1)]
      simp only [Nat.succ_eq_add_one]
      cases psKernelExprHasLooseAt ty offset <;> rfl
  | forallE name ty body bi iht ihb =>
      simp only [psKernelC0HasLooseBVarFast,
        PsKernelExpr.psKernelC0LooseBVarBound, psKernelExprHasLooseAt]
      simp only [psKernelC0HasLooseBVarFast] at iht ihb
      rw [c0_bound_blt_max, c0_bound_blt_pred,
        iht offset, ihb (offset + 1)]
      simp only [Nat.succ_eq_add_one]
      cases psKernelExprHasLooseAt ty offset <;> rfl
  | letE name ty value body nondep iht ihv ihb =>
      simp only [psKernelC0HasLooseBVarFast,
        PsKernelExpr.psKernelC0LooseBVarBound, psKernelExprHasLooseAt]
      simp only [psKernelC0HasLooseBVarFast] at iht ihv ihb
      rw [c0_bound_blt_max, c0_bound_blt_max, c0_bound_blt_pred,
        iht offset, ihv offset, ihb (offset + 1)]
      simp only [Nat.succ_eq_add_one]
      cases psKernelExprHasLooseAt ty offset <;>
        cases psKernelExprHasLooseAt value offset <;> rfl
  | mdata _ body ih =>
      simpa [psKernelC0HasLooseBVarFast,
        PsKernelExpr.psKernelC0LooseBVarBound, psKernelExprHasLooseAt]
        using ih offset
  | proj _ _ body ih =>
      simpa [psKernelC0HasLooseBVarFast,
        PsKernelExpr.psKernelC0LooseBVarBound, psKernelExprHasLooseAt]
        using ih offset
  | _ =>
      simp [psKernelC0HasLooseBVarFast,
        PsKernelExpr.psKernelC0LooseBVarBound,
        psKernelExprHasLooseAt, c0_bound_blt_ble, c0_bound_blt_zero]

/-- Native compiler-only refinement of the existing syntactic loose-variable
    query. Neither this compiler rewrite nor cached metadata confers theorem,
    type, definitional equality, admission or fuel authority. -/
def psKernelC0HasLooseBVarFast0 (expr : PsKernelExpr) : Bool :=
  psKernelC0HasLooseBVarFast expr 0

@[csimp] theorem psKernelExprHasLooseBVar_csimp :
    @psKernelExprHasLooseBVar =
      @psKernelC0HasLooseBVarFast0 := by
  funext expr
  simpa only [psKernelExprHasLooseBVar,
    psKernelC0HasLooseBVarFast0] using
    (c0LooseBVarBound_source expr 0).symm
