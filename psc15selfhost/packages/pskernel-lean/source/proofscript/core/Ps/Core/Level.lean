import Ps.Foundation.Name

inductive PsLevel where
  | zero
  | succ (of : PsLevel)
  | max (left : PsLevel) (right : PsLevel)
  | imax (left : PsLevel) (right : PsLevel)
  | param (name : PsName)
  | mvar (id : Nat)

def psLevelSucc (level : PsLevel) : PsLevel :=
  PsLevel.succ level
