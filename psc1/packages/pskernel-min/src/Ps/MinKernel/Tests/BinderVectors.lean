import Ps.MinKernel.Profile.LowerUnusedBinder
import Ps.Core.Equality

-- Test-only comparison. The proof establishes exact equality, not just alpha equality.
def psMinBinderName : PsName := PsName.str PsName.anonymous "scope"
def psMinBinderType : PsExpr := PsExpr.sortE PsLevel.zero

def psMinBinderOutcome (depth : Nat) (expression expected : PsExpr) : Nat :=
  match psMinLowerUnusedBinder depth expression with
  | Option.none => 0
  | Option.some result => if psExprAlphaEq result expected then 1 else 2

def psMinBinderVector (index : Nat) : Nat :=
  if Nat.beq index 0 then
    psMinBinderOutcome 0 (PsExpr.bvar 2) (PsExpr.bvar 1)
  else if Nat.beq index 1 then
    psMinBinderOutcome 1 (PsExpr.bvar 0) (PsExpr.bvar 0)
  else if Nat.beq index 2 then
    psMinBinderOutcome 0 psMinBinderType psMinBinderType
  else if Nat.beq index 3 then
    psMinBinderOutcome 0 (PsExpr.fvar 42) (PsExpr.fvar 42)
  else if Nat.beq index 4 then
    psMinBinderOutcome 0 (PsExpr.mvar 17) (PsExpr.mvar 17)
  else if Nat.beq index 5 then
    psMinBinderOutcome 0 (PsExpr.constE psMinBinderName (List.cons (PsLevel.succ PsLevel.zero) List.nil)) (PsExpr.constE psMinBinderName (List.cons (PsLevel.succ PsLevel.zero) List.nil))
  else if Nat.beq index 6 then
    psMinBinderOutcome 0 (PsExpr.lit (PsLiteral.natural 7)) (PsExpr.lit (PsLiteral.natural 7))
  else if Nat.beq index 7 then
    psMinBinderOutcome 0 (PsExpr.lit (PsLiteral.string "é")) (PsExpr.lit (PsLiteral.string "é"))
  else if Nat.beq index 8 then
    psMinBinderOutcome 0 (PsExpr.app (PsExpr.bvar 1) (PsExpr.bvar 2)) (PsExpr.app (PsExpr.bvar 0) (PsExpr.bvar 1))
  else if Nat.beq index 9 then
    psMinBinderOutcome 0 (PsExpr.lam psMinBinderName psMinBinderType (PsExpr.bvar 0) PsBinderInfo.explicit) (PsExpr.lam psMinBinderName psMinBinderType (PsExpr.bvar 0) PsBinderInfo.explicit)
  else if Nat.beq index 10 then
    psMinBinderOutcome 0 (PsExpr.lam psMinBinderName psMinBinderType (PsExpr.bvar 2) PsBinderInfo.explicit) (PsExpr.lam psMinBinderName psMinBinderType (PsExpr.bvar 1) PsBinderInfo.explicit)
  else if Nat.beq index 11 then
    psMinBinderOutcome 0 (PsExpr.lam psMinBinderName (PsExpr.bvar 1) (PsExpr.bvar 0) PsBinderInfo.explicit) (PsExpr.lam psMinBinderName (PsExpr.bvar 0) (PsExpr.bvar 0) PsBinderInfo.explicit)
  else if Nat.beq index 12 then
    psMinBinderOutcome 0 (PsExpr.forallE psMinBinderName (PsExpr.bvar 1) (PsExpr.bvar 2) PsBinderInfo.implicit) (PsExpr.forallE psMinBinderName (PsExpr.bvar 0) (PsExpr.bvar 1) PsBinderInfo.implicit)
  else if Nat.beq index 13 then
    psMinBinderOutcome 0 (PsExpr.forallE psMinBinderName psMinBinderType (PsExpr.bvar 0) PsBinderInfo.implicit) (PsExpr.forallE psMinBinderName psMinBinderType (PsExpr.bvar 0) PsBinderInfo.implicit)
  else if Nat.beq index 14 then
    psMinBinderOutcome 0 (PsExpr.letE psMinBinderName (PsExpr.bvar 1) (PsExpr.bvar 2) (PsExpr.bvar 3)) (PsExpr.letE psMinBinderName (PsExpr.bvar 0) (PsExpr.bvar 1) (PsExpr.bvar 2))
  else if Nat.beq index 15 then
    psMinBinderOutcome 0 (PsExpr.letE psMinBinderName psMinBinderType (PsExpr.lit (PsLiteral.natural 0)) (PsExpr.bvar 0)) (PsExpr.letE psMinBinderName psMinBinderType (PsExpr.lit (PsLiteral.natural 0)) (PsExpr.bvar 0))
  else if Nat.beq index 16 then
    psMinBinderOutcome 0 (PsExpr.proj psMinBinderName 1 (PsExpr.bvar 1)) (PsExpr.proj psMinBinderName 1 (PsExpr.bvar 0))
  else if Nat.beq index 17 then
    psMinBinderOutcome 0 (PsExpr.lam psMinBinderName psMinBinderType (PsExpr.lam psMinBinderName psMinBinderType (PsExpr.bvar 1) PsBinderInfo.explicit) PsBinderInfo.explicit) (PsExpr.lam psMinBinderName psMinBinderType (PsExpr.lam psMinBinderName psMinBinderType (PsExpr.bvar 1) PsBinderInfo.explicit) PsBinderInfo.explicit)
  else if Nat.beq index 18 then
    psMinBinderOutcome 0 (PsExpr.lam psMinBinderName psMinBinderType (PsExpr.lam psMinBinderName psMinBinderType (PsExpr.bvar 3) PsBinderInfo.explicit) PsBinderInfo.explicit) (PsExpr.lam psMinBinderName psMinBinderType (PsExpr.lam psMinBinderName psMinBinderType (PsExpr.bvar 2) PsBinderInfo.explicit) PsBinderInfo.explicit)
  else if Nat.beq index 19 then
    psMinBinderOutcome 3 (PsExpr.bvar 5) (PsExpr.bvar 4)
  else if Nat.beq index 20 then
    psMinBinderOutcome 3 (PsExpr.bvar 2) (PsExpr.bvar 2)
  else if Nat.beq index 21 then
    psMinBinderOutcome 0 (PsExpr.bvar 0) psMinBinderType
  else if Nat.beq index 22 then
    psMinBinderOutcome 3 (PsExpr.bvar 3) psMinBinderType
  else if Nat.beq index 23 then
    psMinBinderOutcome 0 (PsExpr.app (PsExpr.bvar 0) psMinBinderType) psMinBinderType
  else if Nat.beq index 24 then
    psMinBinderOutcome 0 (PsExpr.app psMinBinderType (PsExpr.bvar 0)) psMinBinderType
  else if Nat.beq index 25 then
    psMinBinderOutcome 0 (PsExpr.lam psMinBinderName (PsExpr.bvar 0) (PsExpr.bvar 0) PsBinderInfo.explicit) psMinBinderType
  else if Nat.beq index 26 then
    psMinBinderOutcome 0 (PsExpr.lam psMinBinderName psMinBinderType (PsExpr.bvar 1) PsBinderInfo.explicit) psMinBinderType
  else if Nat.beq index 27 then
    psMinBinderOutcome 0 (PsExpr.forallE psMinBinderName (PsExpr.bvar 0) (PsExpr.bvar 0) PsBinderInfo.implicit) psMinBinderType
  else if Nat.beq index 28 then
    psMinBinderOutcome 0 (PsExpr.forallE psMinBinderName psMinBinderType (PsExpr.bvar 1) PsBinderInfo.implicit) psMinBinderType
  else if Nat.beq index 29 then
    psMinBinderOutcome 0 (PsExpr.letE psMinBinderName (PsExpr.bvar 0) psMinBinderType (PsExpr.bvar 0)) psMinBinderType
  else if Nat.beq index 30 then
    psMinBinderOutcome 0 (PsExpr.letE psMinBinderName psMinBinderType (PsExpr.bvar 0) (PsExpr.bvar 0)) psMinBinderType
  else if Nat.beq index 31 then
    psMinBinderOutcome 0 (PsExpr.letE psMinBinderName psMinBinderType psMinBinderType (PsExpr.bvar 1)) psMinBinderType
  else if Nat.beq index 32 then
    psMinBinderOutcome 0 (PsExpr.proj psMinBinderName 1 (PsExpr.bvar 0)) psMinBinderType
  else if Nat.beq index 33 then
    psMinBinderOutcome 0 (PsExpr.lam psMinBinderName psMinBinderType (PsExpr.lam psMinBinderName psMinBinderType (PsExpr.bvar 2) PsBinderInfo.explicit) PsBinderInfo.explicit) psMinBinderType
  else 3
