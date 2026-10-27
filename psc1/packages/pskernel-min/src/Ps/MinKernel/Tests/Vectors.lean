import Ps.MinKernel.Check

namespace Ps.MinKernel.Tests

def accepted (termFuel declarationFuel : Nat) (declarations : List Declaration) : Bool :=
  match checkEnvironment termFuel declarationFuel declarations with
  | Option.some _ => true
  | Option.none => false

def inferred (fuel : Nat) (expression : Expr) (type : Ty) : Bool :=
  match infer fuel List.nil List.nil expression with
  | Option.some result => tyEq fuel result type
  | Option.none => false

def identityNat : Expr := Expr.lam Ty.nat (Expr.var 0)

def rawVector (index : Nat) : Bool :=
  if Nat.beq index 0 then accepted 16 16 List.nil
  else if Nat.beq index 1 then accepted 16 16 (List.cons (Declaration.mk (Ty.arr Ty.nat Ty.nat) identityNat) List.nil)
  else if Nat.beq index 2 then accepted 16 16
      (List.cons (Declaration.mk Ty.nat (Expr.nat 7)) (List.cons (Declaration.mk Ty.nat (Expr.constant 0)) List.nil))
  else if Nat.beq index 3 then inferred 16 (Expr.lam Ty.empty (Expr.var 0)) (Ty.arr Ty.empty Ty.empty)
  else if Nat.beq index 4 then inferred 16 (Expr.app identityNat (Expr.nat 7)) Ty.nat
  else if Nat.beq index 5 then accepted 16 16 (List.cons (Declaration.mk Ty.nat Expr.unit) List.nil)
  else if Nat.beq index 6 then inferred 16 (Expr.app (Expr.nat 7) Expr.unit) Ty.nat
  else if Nat.beq index 7 then inferred 16 (Expr.var 0) Ty.nat
  else if Nat.beq index 8 then accepted 16 16 (List.cons (Declaration.mk Ty.nat (Expr.constant 0)) List.nil)
  else if Nat.beq index 9 then accepted 16 16 (List.cons (Declaration.mk Ty.empty Expr.unit) List.nil)
  else if Nat.beq index 10 then accepted 0 16 (List.cons (Declaration.mk Ty.nat (Expr.nat 7)) List.nil)
  else if Nat.beq index 11 then accepted 16 0 (List.cons (Declaration.mk Ty.nat (Expr.nat 7)) List.nil)
  else if Nat.beq index 12 then inferred 1 identityNat (Ty.arr Ty.nat Ty.nat)
  else if Nat.beq index 13 then tyEq 1 (Ty.arr Ty.nat Ty.nat) (Ty.arr Ty.nat Ty.nat)
  else if Nat.beq index 14 then accepted 16 16
      (List.cons (Declaration.mk Ty.nat (Expr.nat 7)) (List.cons (Declaration.mk Ty.empty (Expr.constant 0)) List.nil))
  else if Nat.beq index 15 then inferred 16
      (Expr.app (Expr.lam Ty.empty (Expr.var 0)) (Expr.nat 7)) Ty.empty
  else false

end Ps.MinKernel.Tests
