import PSKernelFast.Name

/-!
Raw universe syntax matching Lean level constructors.
Syntactic equality is NOT universe equivalence, inequality or cumulativity.
In particular imax u 0 and imax u (succ v) require semantic case handling.
-/
namespace PSKernelFast

inductive Level where
  | zero
  | succ (inner : Level)
  | max (left right : Level)
  | imax (left right : Level)
  | param (name : Name)
  | mvar (name : Name)
deriving Repr, BEq, Hashable, Inhabited, DecidableEq

def Level.hasMVar : Level → Bool
  | .mvar _ => true
  | .succ a => a.hasMVar
  | .max a b | .imax a b => a.hasMVar || b.hasMVar
  | _ => false

/-!
Local, non-recursive algebraic normalization only. Does NOT claim full
universe equivalence. G9 proof module shows preservation under every Nat
valuation before this can justify positive type matches.
-/
def Level.simplifyTop : Level → Level
  | .imax _ .zero => .zero
  | .imax .zero u => u
  | .max .zero u => u
  | .max u .zero => u
  | u => u

def Level.quickEquivalent (a b : Level) : Bool :=
  decide (a.simplifyTop = b.simplifyTop)

end PSKernelFast
