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
        psKernelExprHasLooseAt, c0_bound_lt_succ, c0_bound_blt_ble]


/-!
The old recursive oracle deliberately runs only on small expressions. The
source theorem proves equality for all inputs; the 4000-node DAG checks
actual native computed-field operation without exponentially expanding it.
-/

def c0LooseBoundShared : Nat → PsKernelExpr → PsKernelExpr
  | 0, v => v
  | n+1, v =>
      let child := c0LooseBoundShared n v
      .app child child

def main : IO Unit := do
  let a : PsKernelName := .str .anonymous "a"
  let xs : List PsKernelExpr := [
    .bvar 0, .bvar 1, .bvar 7, .sort .zero,
    .const a [], .app (.bvar 0) (.bvar 5),
    .lam a (.bvar 0) (.bvar 0) .default,
    .lam a (.sort .zero) (.bvar 1) .default,
    .forallE a (.bvar 2) (.bvar 0) .implicit,
    .letE a (.bvar 2) (.bvar 0) (.bvar 1) false,
    .mdata 3 (.bvar 8), .proj a 0 (.bvar 4),
    .fvar a, .mvar a, .lit (.nat 3)
  ]
  for expr in xs do
    for offset in [0,1,2,3,7,8,12] do
      let original := psKernelExprHasLooseAt expr offset
      let fast := psKernelC0HasLooseBVarFast expr offset
      let _theorem : fast = original :=
        c0LooseBVarBound_source expr offset
      if fast != original then
        throw (IO.userError "native loose-bound metadata differs from source oracle")
  let closed := c0LooseBoundShared 4000 (.const a [])
  let free := c0LooseBoundShared 4000 (.bvar 0)
  let deep := c0LooseBoundShared 4000 (.bvar 128)
  let _closed : psKernelC0HasLooseBVarFast closed 0 =
    psKernelExprHasLooseAt closed 0 :=
    c0LooseBVarBound_source closed 0
  let _free : psKernelC0HasLooseBVarFast free 0 =
    psKernelExprHasLooseAt free 0 :=
    c0LooseBVarBound_source free 0
  let start ← IO.monoNanosNow
  if psKernelC0HasLooseBVarFast closed 0 then
    throw (IO.userError "closed immutable DAG misclassified")
  if !psKernelC0HasLooseBVarFast free 0 then
    throw (IO.userError "free immutable DAG misclassified")
  if !psKernelC0HasLooseBVarFast deep 128 then
    throw (IO.userError "offset-128 loose bound missing")
  if psKernelC0HasLooseBVarFast deep 129 then
    throw (IO.userError "offset-129 loose bound false positive")
  let stop ← IO.monoNanosNow
  IO.println s!"C0_LOOSE_BVAR_BOUND proof=all_inputs native_small_cases=15 offsets=7 shared_depth=4000 exact_offsets=true query_ms={(stop-start)/1000000} no_admission=true"
