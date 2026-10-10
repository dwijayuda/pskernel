import PSKernelFast.Level

/-!
# G8: universe-level arithmetic semantics for the new kernel

This is a mathematical valuation function, NOT Lean's checker algorithm.
For a valuation, imax u v is zero if v denotes zero; otherwise it denotes
max(u,v). The sound identities below are deliberately local.
No custom axioms or assumptions about the old PSKernel proof work are used.

The valuation maps raw metavariables too, but checked admission must reject
all level mvars independently, as the current syntax preflight does.
-/

namespace PSKernelFast

/-- Evaluates raw universe syntax under one assignment of natural levels. -/
def Level.evalAt (ρ : Name → Nat) : Level → Nat
  | .zero => 0
  | .succ a => Nat.succ (a.evalAt ρ)
  | .max a b => Nat.max (a.evalAt ρ) (b.evalAt ρ)
  | .imax a b =>
      if b.evalAt ρ = 0 then 0 else Nat.max (a.evalAt ρ) (b.evalAt ρ)
  | .param n => ρ n
  | .mvar n => ρ n

@[simp] theorem Level.evalAt_max_zero_right
    (ρ : Name → Nat) (u : Level) :
    (Level.max u .zero).evalAt ρ = u.evalAt ρ := by
  simp [Level.evalAt]

@[simp] theorem Level.evalAt_max_zero_left
    (ρ : Name → Nat) (u : Level) :
    (Level.max .zero u).evalAt ρ = u.evalAt ρ := by
  simp [Level.evalAt]

@[simp] theorem Level.evalAt_imax_zero_right
    (ρ : Name → Nat) (u : Level) :
    (Level.imax u .zero).evalAt ρ = 0 := by
  simp [Level.evalAt]

@[simp] theorem Level.evalAt_imax_zero_left
    (ρ : Name → Nat) (u : Level) :
    (Level.imax .zero u).evalAt ρ = u.evalAt ρ := by
  by_cases h : u.evalAt ρ = 0
  · simp [Level.evalAt, h]
  · simp [Level.evalAt, h]

@[simp] theorem Level.evalAt_imax_succ_right
    (ρ : Name → Nat) (u v : Level) :
    (Level.imax u (.succ v)).evalAt ρ =
      Nat.max (u.evalAt ρ) (Nat.succ (v.evalAt ρ)) := by
  simp [Level.evalAt]

theorem Level.evalAt_max_comm
    (ρ : Name → Nat) (u v : Level) :
    (Level.max u v).evalAt ρ =
      (Level.max v u).evalAt ρ := by
  simp [Level.evalAt, Nat.max_comm]

/-- Every root rewrite preserves universe arithmetic for every valuation. -/
theorem Level.simplifyTop_evalAt
    (ρ : Name → Nat) (l : Level) :
    l.simplifyTop.evalAt ρ = l.evalAt ρ := by
  cases l with
  | zero => rfl
  | succ _ => rfl
  | param _ => rfl
  | mvar _ => rfl
  | max a b =>
      cases a <;> cases b <;> simp [Level.simplifyTop, Level.evalAt]
  | imax a b =>
      cases a <;> cases b <;> simp [Level.simplifyTop, Level.evalAt]

/--
An affirmative quick comparison implies equal numeric valuations universally.
Negative results do NOT imply nonequivalence; full Lean completeness is open.
-/
theorem Level.quickEquivalent_sound
    (ρ : Name → Nat) (a b : Level)
    (h : a.quickEquivalent b = true) :
    a.evalAt ρ = b.evalAt ρ := by
  have hEq : a.simplifyTop = b.simplifyTop := by
    by_cases hSame : a.simplifyTop = b.simplifyTop
    · exact hSame
    · have hFalse : a.quickEquivalent b = false := by
        simp [Level.quickEquivalent, hSame]
      rw [hFalse] at h
      cases h
  calc
    a.evalAt ρ = a.simplifyTop.evalAt ρ := (Level.simplifyTop_evalAt ρ a).symm
    _ = b.simplifyTop.evalAt ρ := by rw [hEq]
    _ = b.evalAt ρ := Level.simplifyTop_evalAt ρ b

end PSKernelFast
