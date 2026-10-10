import Ps.KernelCore.Core.Level

/-! Universe valuation, independent of the level-normalization algorithm. -/

namespace PsKernelSemantics

def evalLevel (params metavariables : PsKernelName → Nat) : PsKernelLevel → Nat
  | .zero => 0
  | .succ l => Nat.succ (evalLevel params metavariables l)
  | .max a b => max (evalLevel params metavariables a) (evalLevel params metavariables b)
  | .imax a b =>
      let bv := evalLevel params metavariables b
      if bv = 0 then 0 else max (evalLevel params metavariables a) bv
  | .param n => params n
  | .mvar n => metavariables n

/-- Zero classification is sound for every valuation, including imax. -/
theorem normalizesToZero_eval
    (params metavariables : PsKernelName → Nat) (level : PsKernelLevel) :
    psKernelLevelNormalizesToZero level = true →
      evalLevel params metavariables level = 0 := by
  induction level with
  | zero => intro _; rfl
  | succ level ih => simp [psKernelLevelNormalizesToZero]
  | max a b ia ib =>
      intro h
      cases ha : psKernelLevelNormalizesToZero a with
      | false => simp [psKernelLevelNormalizesToZero, ha] at h
      | true =>
          have hb : psKernelLevelNormalizesToZero b = true := by
            simpa [psKernelLevelNormalizesToZero, ha] using h
          simp [evalLevel, ia ha, ib hb]
  | imax a b ia ib =>
      intro h
      have hb : psKernelLevelNormalizesToZero b = true := h
      simp [evalLevel, ib hb]
  | param n => simp [psKernelLevelNormalizesToZero]
  | mvar n => simp [psKernelLevelNormalizesToZero]

end PsKernelSemantics

#print axioms PsKernelSemantics.normalizesToZero_eval
