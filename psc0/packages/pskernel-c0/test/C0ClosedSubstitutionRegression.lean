import Ps.KernelCore.Architecture.CertifiedInstantiateMemo
import Lean

/-!
A structural *no-substitution* certificate, deliberately separate from native
cache implementation. It allows stopping before hash-trie recursion only when
the immutable bound proves all bound-variable indices are below this offset.
-/

private theorem c0NoSubstNatLt {a b : Nat} (h : a < b) :
    psKernelNatLt a b = true := by
  unfold psKernelNatLt
  have ne : a ≠ b := Nat.ne_of_lt h
  have eqFalse : Nat.beq a b = false := by
    cases k : Nat.beq a b with
    | false => rfl
    | true => exact False.elim (ne (Nat.eq_of_beq_eq_true k))
  simp [eqFalse, Nat.ble_eq_true_of_le (Nat.le_of_lt h)]

/-- All-input *proof* of no substitution when the cached bound excludes
    any free de Bruijn index at the required binder offset. The old source
    algorithm remains the independent oracle. This theorem does not claim
    a checked proof/type/DefEq judgment or relax any fuel/admission rule. -/
theorem c0NoSubstitutionFromBound (expr replacement : PsKernelExpr) :
    ∀ (offset : Nat), expr.psKernelC0LooseBVarBound ≤ offset →
      psKernelC0ExprInstantiateOneChanged expr replacement offset =
        (expr, false) := by
  induction expr with
  | bvar index =>
      intro offset h
      have hlt : index < offset := by
        simp only [PsKernelExpr.psKernelC0LooseBVarBound] at h
        omega
      simp [psKernelC0ExprInstantiateOneChanged, c0NoSubstNatLt hlt]
  | app fn arg ihf iha =>
      intro offset h
      have hmax : Nat.max fn.psKernelC0LooseBVarBound
          arg.psKernelC0LooseBVarBound ≤ offset := by
        simpa only [PsKernelExpr.psKernelC0LooseBVarBound] using h
      have hf : fn.psKernelC0LooseBVarBound ≤ offset :=
        Nat.le_trans (Nat.le_max_left ..) hmax
      have ha : arg.psKernelC0LooseBVarBound ≤ offset :=
        Nat.le_trans (Nat.le_max_right ..) hmax
      simp [psKernelC0ExprInstantiateOneChanged, ihf offset hf, iha offset ha]
  | lam name ty body binder iht ihb =>
      intro offset h
      have hmax : Nat.max ty.psKernelC0LooseBVarBound
          (body.psKernelC0LooseBVarBound - 1) ≤ offset := by
        simpa only [PsKernelExpr.psKernelC0LooseBVarBound] using h
      have ht : ty.psKernelC0LooseBVarBound ≤ offset :=
        Nat.le_trans (Nat.le_max_left ..) hmax
      have hb0 : body.psKernelC0LooseBVarBound - 1 ≤ offset :=
        Nat.le_trans (Nat.le_max_right ..) hmax
      have hb : body.psKernelC0LooseBVarBound ≤ offset + 1 := by omega
      simp [psKernelC0ExprInstantiateOneChanged, iht offset ht, ihb (offset+1) hb]
  | forallE name ty body binder iht ihb =>
      intro offset h
      have hmax : Nat.max ty.psKernelC0LooseBVarBound
          (body.psKernelC0LooseBVarBound - 1) ≤ offset := by
        simpa only [PsKernelExpr.psKernelC0LooseBVarBound] using h
      have ht : ty.psKernelC0LooseBVarBound ≤ offset :=
        Nat.le_trans (Nat.le_max_left ..) hmax
      have hb0 : body.psKernelC0LooseBVarBound - 1 ≤ offset :=
        Nat.le_trans (Nat.le_max_right ..) hmax
      have hb : body.psKernelC0LooseBVarBound ≤ offset + 1 := by omega
      simp [psKernelC0ExprInstantiateOneChanged, iht offset ht, ihb (offset+1) hb]
  | letE name ty value body nondep iht ihv ihb =>
      intro offset h
      have hmax : Nat.max ty.psKernelC0LooseBVarBound
          (Nat.max value.psKernelC0LooseBVarBound
            (body.psKernelC0LooseBVarBound - 1)) ≤ offset := by
        simpa only [PsKernelExpr.psKernelC0LooseBVarBound] using h
      have ht : ty.psKernelC0LooseBVarBound ≤ offset :=
        Nat.le_trans (Nat.le_max_left ..) hmax
      have hrest : Nat.max value.psKernelC0LooseBVarBound
          (body.psKernelC0LooseBVarBound - 1) ≤ offset :=
        Nat.le_trans (Nat.le_max_right ..) hmax
      have hv : value.psKernelC0LooseBVarBound ≤ offset :=
        Nat.le_trans (Nat.le_max_left ..) hrest
      have hb0 : body.psKernelC0LooseBVarBound - 1 ≤ offset :=
        Nat.le_trans (Nat.le_max_right ..) hrest
      have hb : body.psKernelC0LooseBVarBound ≤ offset + 1 := by omega
      simp [psKernelC0ExprInstantiateOneChanged, iht offset ht,
        ihv offset hv, ihb (offset+1) hb]
  | mdata md body ih =>
      intro offset h
      have hb : body.psKernelC0LooseBVarBound ≤ offset := by
        simpa only [PsKernelExpr.psKernelC0LooseBVarBound] using h
      simp [psKernelC0ExprInstantiateOneChanged, ih offset hb]
  | proj name index body ih =>
      intro offset h
      have hb : body.psKernelC0LooseBVarBound ≤ offset := by
        simpa only [PsKernelExpr.psKernelC0LooseBVarBound] using h
      simp [psKernelC0ExprInstantiateOneChanged, ih offset hb]
  | _ =>
      intros offset h
      rfl

def c0NoSubstShared : Nat → PsKernelExpr → PsKernelExpr
  | 0, e => e
  | n+1, e => let t := c0NoSubstShared n e; .app t t

def main : IO Unit := do
  let a : PsKernelName := .str .anonymous "closed"
  let closed := c0NoSubstShared 4000 (.const a [])
  let _witness := c0NoSubstitutionFromBound closed (.bvar 0) 0 (by decide)
  let xs : List PsKernelExpr := [
    .bvar 0, .bvar 1, .app (.bvar 0) (.sort .zero),
    .lam a (.sort .zero) (.bvar 0) .default,
    .forallE a (.sort .zero) (.bvar 0) .default,
    .letE a (.sort .zero) (.sort .zero) (.bvar 0) false,
    .mdata 0 (.sort .zero), .proj a 0 (.sort .zero)
  ]
  for expr in xs do
    for offset in [0,1,2,4] do
      if expr.psKernelC0LooseBVarBound ≤ offset then
        let src := psKernelC0ExprInstantiateOneChanged expr (.bvar 5) offset
        if src != (expr,false) then
          throw (IO.userError "source closed-substitution proof mismatch")
  IO.println "C0_NO_SUBST_FROM_BOUND source=Lean_proved all_offsets=true 4000_shared_DAG=proof only no_admission=true"
