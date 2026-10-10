import Std

/-!
# Lean 4.35 raw universe syntax, not equivalence

Preserves syntactic imax and successor structure without any unsound
normalization or assumptions about Prop. Universe metavariables are raw
syntax and must be rejected by a future fully checked kernel admission path.
-/

namespace PSKernelFast

inductive Level where
  | zero
  | succ (inner : Level)
  | max (left right : Level)
  | imax (left right : Level)
  | param (name : String)
  | mvar (name : String)
deriving Repr, BEq, Hashable, Inhabited

/-- Syntactic inspection only; not level equality or cumulativity. -/
def Level.hasMVar : Level → Bool
  | .mvar _ => true
  | .succ a => a.hasMVar
  | .max a b | .imax a b => a.hasMVar || b.hasMVar
  | _ => false

end PSKernelFast
