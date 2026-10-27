import Ps.MinKernel.Check


def psMinAccepted (termFuel declarationFuel : Nat) (declarations : List PsMinDeclaration) : Bool :=
  match psMinCheckEnvironment termFuel declarationFuel declarations with
  | Option.some _ => true
  | Option.none => false

def psMinInferred (fuel : Nat) (expression : PsMinExpr) (type : PsMinTy) : Bool :=
  match psMinInfer fuel List.nil List.nil expression with
  | Option.some result => psMinTyEq fuel result type
  | Option.none => false

def psMinIdentityNat : PsMinExpr := PsMinExpr.lam PsMinTy.nat (PsMinExpr.var 0)

def psMinRawVector (index : Nat) : Bool :=
  if Nat.beq index 0 then psMinAccepted 16 16 List.nil
  else if Nat.beq index 1 then psMinAccepted 16 16 (List.cons (PsMinDeclaration.mk (PsMinTy.arr PsMinTy.nat PsMinTy.nat) psMinIdentityNat) List.nil)
  else if Nat.beq index 2 then psMinAccepted 16 16
      (List.cons (PsMinDeclaration.mk PsMinTy.nat (PsMinExpr.nat 7)) (List.cons (PsMinDeclaration.mk PsMinTy.nat (PsMinExpr.constant 0)) List.nil))
  else if Nat.beq index 3 then psMinInferred 16 (PsMinExpr.lam PsMinTy.empty (PsMinExpr.var 0)) (PsMinTy.arr PsMinTy.empty PsMinTy.empty)
  else if Nat.beq index 4 then psMinInferred 16 (PsMinExpr.app psMinIdentityNat (PsMinExpr.nat 7)) PsMinTy.nat
  else if Nat.beq index 5 then psMinAccepted 16 16 (List.cons (PsMinDeclaration.mk PsMinTy.nat PsMinExpr.unit) List.nil)
  else if Nat.beq index 6 then psMinInferred 16 (PsMinExpr.app (PsMinExpr.nat 7) PsMinExpr.unit) PsMinTy.nat
  else if Nat.beq index 7 then psMinInferred 16 (PsMinExpr.var 0) PsMinTy.nat
  else if Nat.beq index 8 then psMinAccepted 16 16 (List.cons (PsMinDeclaration.mk PsMinTy.nat (PsMinExpr.constant 0)) List.nil)
  else if Nat.beq index 9 then psMinAccepted 16 16 (List.cons (PsMinDeclaration.mk PsMinTy.empty PsMinExpr.unit) List.nil)
  else if Nat.beq index 10 then psMinAccepted 0 16 (List.cons (PsMinDeclaration.mk PsMinTy.nat (PsMinExpr.nat 7)) List.nil)
  else if Nat.beq index 11 then psMinAccepted 16 0 (List.cons (PsMinDeclaration.mk PsMinTy.nat (PsMinExpr.nat 7)) List.nil)
  else if Nat.beq index 12 then psMinInferred 1 psMinIdentityNat (PsMinTy.arr PsMinTy.nat PsMinTy.nat)
  else if Nat.beq index 13 then psMinTyEq 1 (PsMinTy.arr PsMinTy.nat PsMinTy.nat) (PsMinTy.arr PsMinTy.nat PsMinTy.nat)
  else if Nat.beq index 14 then psMinAccepted 16 16
      (List.cons (PsMinDeclaration.mk PsMinTy.nat (PsMinExpr.nat 7)) (List.cons (PsMinDeclaration.mk PsMinTy.empty (PsMinExpr.constant 0)) List.nil))
  else if Nat.beq index 15 then psMinInferred 16
      (PsMinExpr.app (PsMinExpr.lam PsMinTy.empty (PsMinExpr.var 0)) (PsMinExpr.nat 7)) PsMinTy.empty
  else false
