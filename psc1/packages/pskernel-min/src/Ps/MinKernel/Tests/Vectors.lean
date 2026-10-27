import Ps.MinKernel.Check

namespace Ps.MinKernel.Tests

open Ps.MinKernel

def accepted (termFuel declarationFuel : Nat) (declarations : List Declaration) : Bool :=
  match checkEnvironment termFuel declarationFuel declarations with
  | some _ => true
  | none => false

def inferred (fuel : Nat) (expression : Expr) (type : Ty) : Bool :=
  match infer fuel [] [] expression with
  | some result => tyEq fuel result type
  | none => false

def identityNat : Expr := Expr.lam Ty.nat (Expr.var 0)

def rawVector (index : Nat) : Bool :=
  match index with
  | 0 => accepted 16 16 []
  | 1 => accepted 16 16 [Declaration.mk (Ty.arr Ty.nat Ty.nat) identityNat]
  | 2 => accepted 16 16
      [Declaration.mk Ty.nat (Expr.nat 7), Declaration.mk Ty.nat (Expr.constant 0)]
  | 3 => inferred 16 (Expr.lam Ty.empty (Expr.var 0)) (Ty.arr Ty.empty Ty.empty)
  | 4 => inferred 16 (Expr.app identityNat (Expr.nat 7)) Ty.nat
  | 5 => accepted 16 16 [Declaration.mk Ty.nat Expr.unit]
  | 6 => inferred 16 (Expr.app (Expr.nat 7) Expr.unit) Ty.nat
  | 7 => inferred 16 (Expr.var 0) Ty.nat
  | 8 => accepted 16 16 [Declaration.mk Ty.nat (Expr.constant 0)]
  | 9 => accepted 16 16 [Declaration.mk Ty.empty Expr.unit]
  | 10 => accepted 0 16 [Declaration.mk Ty.nat (Expr.nat 7)]
  | 11 => accepted 16 0 [Declaration.mk Ty.nat (Expr.nat 7)]
  | 12 => inferred 1 identityNat (Ty.arr Ty.nat Ty.nat)
  | 13 => tyEq 1 (Ty.arr Ty.nat Ty.nat) (Ty.arr Ty.nat Ty.nat)
  | 14 => accepted 16 16
      [Declaration.mk Ty.nat (Expr.nat 7), Declaration.mk Ty.empty (Expr.constant 0)]
  | 15 => inferred 16
      (Expr.app (Expr.lam Ty.empty (Expr.var 0)) (Expr.nat 7)) Ty.empty
  | _ => false

end Ps.MinKernel.Tests
