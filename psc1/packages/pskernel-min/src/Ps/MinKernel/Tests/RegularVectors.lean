import Ps.MinKernel.Profile.RegularCheck
import Ps.MinKernel.Profile.RegularNames

-- All these are normalized-profile fixtures, never canonical admission authority.
def psMinRegMakeSpec (constructors : List (List PsMinRegField)) : PsMinRegSpec :=
  PsMinRegSpec.mk 0 0 0 1 (psMinRegCtorCount constructors) constructors

def psMinRegTySpec : PsMinRegSpec := psMinRegMakeSpec (List.cons List.nil (List.cons List.nil (List.cons List.nil (List.cons (List.cons PsMinRegField.recursive (List.cons PsMinRegField.recursive List.nil)) List.nil))))

def psMinRegNatListSpec : PsMinRegSpec := psMinRegMakeSpec (List.cons List.nil (List.cons (List.cons (PsMinRegField.ground PsMinRegTy.nat) (List.cons PsMinRegField.recursive List.nil)) List.nil))

def psMinRegEmptySpec : PsMinRegSpec := psMinRegMakeSpec List.nil

def psMinRegLoopSpec : PsMinRegSpec := psMinRegMakeSpec (List.cons (List.cons PsMinRegField.recursive List.nil) List.nil)

def psMinRegOneSpec : PsMinRegSpec := psMinRegMakeSpec (List.cons List.nil List.nil)

def psMinRegTyArrMinor : PsMinRegTerm := (PsMinRegTerm.lam (PsMinRegTy.data 0) (PsMinRegTerm.lam (PsMinRegTy.data 0) (PsMinRegTerm.lam PsMinRegTy.boolean (PsMinRegTerm.lam PsMinRegTy.boolean (PsMinRegTerm.boolean false)))))

def psMinRegTyInstance : PsMinRegTerm :=
  (PsMinRegTerm.app (PsMinRegTerm.app (PsMinRegTerm.app (PsMinRegTerm.app (PsMinRegTerm.app (PsMinRegTerm.recursor 0 1 0 0 1 4 PsMinRegTy.boolean) (PsMinRegTerm.boolean false)) (PsMinRegTerm.boolean false)) (PsMinRegTerm.boolean true)) psMinRegTyArrMinor) (PsMinRegTerm.var 0))

def psMinRegTyFunction : PsMinRegTerm := (PsMinRegTerm.lam (PsMinRegTy.data 0) psMinRegTyInstance)

def psMinRegAccepted (termFuel declarationFuel : Nat) (specs : List PsMinRegSpec)
    (declarations : List PsMinRegDeclaration) : Bool :=
  match psMinRegCheckEnvironment termFuel declarationFuel specs declarations with
  | Option.none => false
  | Option.some _ => true

def psMinRegClosedCase (specs : List PsMinRegSpec) (type : PsMinRegTy) (expression : PsMinRegTerm) : Bool :=
  psMinRegAccepted 128 64 specs
    (List.cons (PsMinRegDeclaration.mk type expression) List.nil)

def psMinRegVector (index : Nat) : Bool :=
  if Nat.beq index 0 then psMinRegAccepted 0 0 List.nil List.nil
  else if Nat.beq index 1 then psMinRegClosedCase List.nil (PsMinRegTy.arr PsMinRegTy.nat PsMinRegTy.nat) (PsMinRegTerm.lam PsMinRegTy.nat (PsMinRegTerm.var 0))
  else if Nat.beq index 2 then psMinRegClosedCase List.nil PsMinRegTy.boolean (PsMinRegTerm.boolean true)
  else if Nat.beq index 3 then psMinRegClosedCase List.nil PsMinRegTy.unit PsMinRegTerm.unit
  else if Nat.beq index 4 then psMinRegClosedCase (List.cons psMinRegTySpec List.nil) (PsMinRegTy.data 0) (PsMinRegTerm.ctor 0 2)
  else if Nat.beq index 5 then psMinRegClosedCase (List.cons psMinRegTySpec List.nil) (PsMinRegTy.data 0) (PsMinRegTerm.app (PsMinRegTerm.app (PsMinRegTerm.ctor 0 3) (PsMinRegTerm.ctor 0 0)) (PsMinRegTerm.ctor 0 2))
  else if Nat.beq index 6 then psMinRegClosedCase (List.cons psMinRegTySpec List.nil) (PsMinRegTy.arr (PsMinRegTy.data 0) PsMinRegTy.boolean) psMinRegTyFunction
  else if Nat.beq index 7 then psMinRegClosedCase (List.cons psMinRegTySpec List.nil) PsMinRegTy.boolean (PsMinRegTerm.app psMinRegTyFunction (PsMinRegTerm.ctor 0 2))
  else if Nat.beq index 8 then psMinRegClosedCase (List.cons psMinRegTySpec List.nil) PsMinRegTy.boolean (PsMinRegTerm.app psMinRegTyFunction (PsMinRegTerm.app (PsMinRegTerm.app (PsMinRegTerm.ctor 0 3) (PsMinRegTerm.ctor 0 0)) (PsMinRegTerm.ctor 0 1)))
  else if Nat.beq index 9 then psMinRegClosedCase (List.cons psMinRegNatListSpec List.nil) (PsMinRegTy.data 0) (PsMinRegTerm.app (PsMinRegTerm.app (PsMinRegTerm.ctor 0 1) (PsMinRegTerm.nat 7)) (PsMinRegTerm.ctor 0 0))
  else if Nat.beq index 10 then psMinRegClosedCase (List.cons psMinRegNatListSpec List.nil) PsMinRegTy.nat (PsMinRegTerm.app (PsMinRegTerm.app (PsMinRegTerm.app (PsMinRegTerm.recursor 0 1 0 0 1 2 PsMinRegTy.nat) (PsMinRegTerm.nat 0)) (PsMinRegTerm.lam PsMinRegTy.nat (PsMinRegTerm.lam (PsMinRegTy.data 0) (PsMinRegTerm.lam PsMinRegTy.nat (PsMinRegTerm.var 2))))) (PsMinRegTerm.app (PsMinRegTerm.app (PsMinRegTerm.ctor 0 1) (PsMinRegTerm.nat 7)) (PsMinRegTerm.ctor 0 0)))
  else if Nat.beq index 11 then psMinRegClosedCase (List.cons psMinRegEmptySpec List.nil) (PsMinRegTy.arr (PsMinRegTy.data 0) PsMinRegTy.empty) (PsMinRegTerm.recursor 0 1 0 0 1 0 PsMinRegTy.empty)
  else if Nat.beq index 12 then psMinRegClosedCase (List.cons psMinRegLoopSpec List.nil) (PsMinRegTy.arr (PsMinRegTy.data 0) (PsMinRegTy.data 0)) (PsMinRegTerm.ctor 0 0)
  else if Nat.beq index 13 then psMinRegClosedCase (List.cons psMinRegLoopSpec List.nil) (PsMinRegTy.arr (PsMinRegTy.data 0) PsMinRegTy.empty) (PsMinRegTerm.app (PsMinRegTerm.recursor 0 1 0 0 1 1 PsMinRegTy.empty) (PsMinRegTerm.lam (PsMinRegTy.data 0) (PsMinRegTerm.lam PsMinRegTy.empty (PsMinRegTerm.var 0))))
  else if Nat.beq index 14 then psMinRegClosedCase (List.cons (psMinRegMakeSpec (List.cons (List.cons (PsMinRegField.ground (PsMinRegTy.arr (PsMinRegTy.data 0) (PsMinRegTy.data 0))) List.nil) List.nil)) (List.cons psMinRegOneSpec List.nil)) (PsMinRegTy.data 0) (PsMinRegTerm.app (PsMinRegTerm.ctor 0 0) (PsMinRegTerm.lam (PsMinRegTy.data 1) (PsMinRegTerm.var 0)))
  else if Nat.beq index 15 then psMinRegClosedCase (List.cons psMinRegOneSpec (List.cons psMinRegOneSpec List.nil)) (PsMinRegTy.data 1) (PsMinRegTerm.ctor 1 0)
  else if Nat.beq index 16 then psMinRegClosedCase (List.cons psMinRegOneSpec (List.cons psMinRegOneSpec List.nil)) (PsMinRegTy.arr (PsMinRegTy.data 1) (PsMinRegTy.arr (PsMinRegTy.data 1) (PsMinRegTy.data 1))) (PsMinRegTerm.recursor 1 1 0 0 1 1 (PsMinRegTy.data 0))
  else if Nat.beq index 17 then psMinRegAccepted 128 64 List.nil (List.cons (PsMinRegDeclaration.mk PsMinRegTy.nat (PsMinRegTerm.nat 7)) (List.cons (PsMinRegDeclaration.mk PsMinRegTy.nat (PsMinRegTerm.constant 0)) List.nil))
  else if Nat.beq index 18 then psMinRegTyValid 16 1 (PsMinRegTy.list (PsMinRegTy.option (PsMinRegTy.data 0)))
  else if Nat.beq index 19 then psMinRegTyEq 16 (PsMinRegTy.arr (PsMinRegTy.data 0) PsMinRegTy.boolean) (PsMinRegTy.arr (PsMinRegTy.data 0) PsMinRegTy.boolean)
  else if Nat.beq index 20 then psMinRegClosedCase List.nil PsMinRegTy.nat (PsMinRegTerm.constant 0)
  else if Nat.beq index 21 then psMinRegClosedCase (List.cons psMinRegTySpec List.nil) (PsMinRegTy.data 0) (PsMinRegTerm.var 0)
  else if Nat.beq index 22 then psMinRegClosedCase (List.cons psMinRegTySpec List.nil) PsMinRegTy.empty (PsMinRegTerm.ctor 0 0)
  else if Nat.beq index 23 then psMinRegClosedCase (List.cons psMinRegTySpec List.nil) PsMinRegTy.empty (PsMinRegTerm.boolean false)
  else if Nat.beq index 24 then psMinRegClosedCase (List.cons psMinRegTySpec List.nil) (PsMinRegTy.data 0) (PsMinRegTerm.ctor 0 9)
  else if Nat.beq index 25 then psMinRegClosedCase (List.cons psMinRegTySpec List.nil) (PsMinRegTy.data 0) (PsMinRegTerm.ctor 2 0)
  else if Nat.beq index 26 then psMinRegClosedCase (List.cons psMinRegTySpec List.nil) (PsMinRegTy.data 0) (PsMinRegTerm.app (PsMinRegTerm.ctor 0 3) (PsMinRegTerm.ctor 0 0))
  else if Nat.beq index 27 then psMinRegClosedCase (List.cons psMinRegTySpec List.nil) (PsMinRegTy.data 0) (PsMinRegTerm.app (PsMinRegTerm.app (PsMinRegTerm.ctor 0 3) (PsMinRegTerm.nat 0)) (PsMinRegTerm.ctor 0 0))
  else if Nat.beq index 28 then psMinRegClosedCase (List.cons psMinRegTySpec List.nil) (PsMinRegTy.arr (PsMinRegTy.data 0) PsMinRegTy.boolean) (PsMinRegTerm.lam (PsMinRegTy.data 0) (PsMinRegTerm.app (PsMinRegTerm.app (PsMinRegTerm.app (PsMinRegTerm.app (PsMinRegTerm.app (PsMinRegTerm.recursor 0 1 0 0 1 4 PsMinRegTy.boolean) (PsMinRegTerm.nat 0)) (PsMinRegTerm.boolean false)) (PsMinRegTerm.boolean true)) psMinRegTyArrMinor) (PsMinRegTerm.var 0)))
  else if Nat.beq index 29 then psMinRegClosedCase (List.cons psMinRegTySpec List.nil) (PsMinRegTy.arr (PsMinRegTy.data 0) PsMinRegTy.boolean) (PsMinRegTerm.lam (PsMinRegTy.data 0) (PsMinRegTerm.app (PsMinRegTerm.app (PsMinRegTerm.app (PsMinRegTerm.app (PsMinRegTerm.app (PsMinRegTerm.recursor 0 1 0 0 1 4 PsMinRegTy.boolean) (PsMinRegTerm.boolean false)) (PsMinRegTerm.boolean false)) (PsMinRegTerm.boolean true)) (PsMinRegTerm.lam PsMinRegTy.boolean (PsMinRegTerm.lam PsMinRegTy.boolean (PsMinRegTerm.lam (PsMinRegTy.data 0) (PsMinRegTerm.lam (PsMinRegTy.data 0) (PsMinRegTerm.boolean false)))))) (PsMinRegTerm.var 0)))
  else if Nat.beq index 30 then psMinRegClosedCase (List.cons psMinRegTySpec List.nil) (PsMinRegTy.arr (PsMinRegTy.data 0) PsMinRegTy.boolean) (PsMinRegTerm.lam (PsMinRegTy.data 0) (PsMinRegTerm.app (PsMinRegTerm.app (PsMinRegTerm.app (PsMinRegTerm.app (PsMinRegTerm.recursor 0 1 0 0 1 4 PsMinRegTy.boolean) (PsMinRegTerm.boolean false)) (PsMinRegTerm.boolean false)) (PsMinRegTerm.boolean true)) (PsMinRegTerm.var 0)))
  else if Nat.beq index 31 then psMinRegClosedCase (List.cons psMinRegTySpec List.nil) (PsMinRegTy.arr (PsMinRegTy.data 0) PsMinRegTy.boolean) (PsMinRegTerm.lam (PsMinRegTy.data 0) (PsMinRegTerm.app psMinRegTyInstance (PsMinRegTerm.boolean false)))
  else if Nat.beq index 32 then psMinRegClosedCase (List.cons psMinRegTySpec List.nil) PsMinRegTy.boolean (PsMinRegTerm.app (PsMinRegTerm.app (PsMinRegTerm.app (PsMinRegTerm.app (PsMinRegTerm.app (PsMinRegTerm.recursor 0 1 0 0 1 4 PsMinRegTy.boolean) (PsMinRegTerm.boolean false)) (PsMinRegTerm.boolean false)) (PsMinRegTerm.boolean true)) psMinRegTyArrMinor) PsMinRegTerm.unit)
  else if Nat.beq index 33 then psMinRegClosedCase (List.cons psMinRegTySpec List.nil) (PsMinRegTy.arr (PsMinRegTy.data 0) PsMinRegTy.boolean) (PsMinRegTerm.lam (PsMinRegTy.data 0) (PsMinRegTerm.app (PsMinRegTerm.app (PsMinRegTerm.app (PsMinRegTerm.app (PsMinRegTerm.app (PsMinRegTerm.recursor 0 0 0 0 1 4 PsMinRegTy.boolean) (PsMinRegTerm.boolean false)) (PsMinRegTerm.boolean false)) (PsMinRegTerm.boolean true)) psMinRegTyArrMinor) (PsMinRegTerm.var 0)))
  else if Nat.beq index 34 then psMinRegClosedCase (List.cons psMinRegTySpec List.nil) (PsMinRegTy.arr (PsMinRegTy.data 0) PsMinRegTy.boolean) (PsMinRegTerm.lam (PsMinRegTy.data 0) (PsMinRegTerm.app (PsMinRegTerm.app (PsMinRegTerm.app (PsMinRegTerm.app (PsMinRegTerm.app (PsMinRegTerm.recursor 0 2 0 0 1 4 PsMinRegTy.boolean) (PsMinRegTerm.boolean false)) (PsMinRegTerm.boolean false)) (PsMinRegTerm.boolean true)) psMinRegTyArrMinor) (PsMinRegTerm.var 0)))
  else if Nat.beq index 35 then psMinRegClosedCase (List.cons psMinRegTySpec List.nil) (PsMinRegTy.arr (PsMinRegTy.data 0) PsMinRegTy.boolean) (PsMinRegTerm.lam (PsMinRegTy.data 0) (PsMinRegTerm.app (PsMinRegTerm.app (PsMinRegTerm.app (PsMinRegTerm.app (PsMinRegTerm.app (PsMinRegTerm.recursor 0 1 1 0 1 4 PsMinRegTy.boolean) (PsMinRegTerm.boolean false)) (PsMinRegTerm.boolean false)) (PsMinRegTerm.boolean true)) psMinRegTyArrMinor) (PsMinRegTerm.var 0)))
  else if Nat.beq index 36 then psMinRegClosedCase (List.cons psMinRegTySpec List.nil) (PsMinRegTy.arr (PsMinRegTy.data 0) PsMinRegTy.boolean) (PsMinRegTerm.lam (PsMinRegTy.data 0) (PsMinRegTerm.app (PsMinRegTerm.app (PsMinRegTerm.app (PsMinRegTerm.app (PsMinRegTerm.app (PsMinRegTerm.recursor 0 1 0 1 1 4 PsMinRegTy.boolean) (PsMinRegTerm.boolean false)) (PsMinRegTerm.boolean false)) (PsMinRegTerm.boolean true)) psMinRegTyArrMinor) (PsMinRegTerm.var 0)))
  else if Nat.beq index 37 then psMinRegClosedCase (List.cons psMinRegTySpec List.nil) (PsMinRegTy.arr (PsMinRegTy.data 0) PsMinRegTy.boolean) (PsMinRegTerm.lam (PsMinRegTy.data 0) (PsMinRegTerm.app (PsMinRegTerm.app (PsMinRegTerm.app (PsMinRegTerm.app (PsMinRegTerm.app (PsMinRegTerm.recursor 0 1 0 0 2 4 PsMinRegTy.boolean) (PsMinRegTerm.boolean false)) (PsMinRegTerm.boolean false)) (PsMinRegTerm.boolean true)) psMinRegTyArrMinor) (PsMinRegTerm.var 0)))
  else if Nat.beq index 38 then psMinRegClosedCase (List.cons psMinRegTySpec List.nil) (PsMinRegTy.arr (PsMinRegTy.data 0) PsMinRegTy.boolean) (PsMinRegTerm.lam (PsMinRegTy.data 0) (PsMinRegTerm.app (PsMinRegTerm.app (PsMinRegTerm.app (PsMinRegTerm.app (PsMinRegTerm.app (PsMinRegTerm.recursor 0 1 0 0 1 3 PsMinRegTy.boolean) (PsMinRegTerm.boolean false)) (PsMinRegTerm.boolean false)) (PsMinRegTerm.boolean true)) psMinRegTyArrMinor) (PsMinRegTerm.var 0)))
  else if Nat.beq index 39 then psMinRegAccepted 128 64 (List.cons (PsMinRegSpec.mk 1 0 0 1 4 psMinRegTySpec.constructors) List.nil) List.nil
  else if Nat.beq index 40 then psMinRegAccepted 128 64 (List.cons (PsMinRegSpec.mk 0 1 0 1 4 psMinRegTySpec.constructors) List.nil) List.nil
  else if Nat.beq index 41 then psMinRegAccepted 128 64 (List.cons (PsMinRegSpec.mk 0 0 1 1 4 psMinRegTySpec.constructors) List.nil) List.nil
  else if Nat.beq index 42 then psMinRegAccepted 128 64 (List.cons (PsMinRegSpec.mk 0 0 0 2 4 psMinRegTySpec.constructors) List.nil) List.nil
  else if Nat.beq index 43 then psMinRegAccepted 128 64 (List.cons (PsMinRegSpec.mk 0 0 0 1 3 psMinRegTySpec.constructors) List.nil) List.nil
  else if Nat.beq index 44 then psMinRegAccepted 128 64 (List.cons (psMinRegMakeSpec (List.cons (List.cons (PsMinRegField.ground (PsMinRegTy.data 0)) List.nil) List.nil)) List.nil) List.nil
  else if Nat.beq index 45 then psMinRegAccepted 128 64 (List.cons (psMinRegMakeSpec (List.cons (List.cons (PsMinRegField.ground (PsMinRegTy.arr (PsMinRegTy.data 0) PsMinRegTy.nat)) List.nil) List.nil)) List.nil) List.nil
  else if Nat.beq index 46 then psMinRegClosedCase (List.cons psMinRegTySpec List.nil) (PsMinRegTy.arr (PsMinRegTy.data 0) PsMinRegTy.boolean) (PsMinRegTerm.recursor 0 1 0 0 1 4 (PsMinRegTy.data 1))
  else if Nat.beq index 47 then psMinRegClosedCase (List.cons psMinRegTySpec List.nil) (PsMinRegTy.data 1) (PsMinRegTerm.ctor 0 0)
  else if Nat.beq index 48 then psMinRegClosedCase (List.cons psMinRegTySpec List.nil) (PsMinRegTy.arr (PsMinRegTy.data 0) (PsMinRegTy.data 0)) (PsMinRegTerm.lam (PsMinRegTy.data 1) (PsMinRegTerm.var 0))
  else if Nat.beq index 49 then psMinRegClosedCase (List.cons psMinRegLoopSpec List.nil) PsMinRegTy.empty (PsMinRegTerm.app (PsMinRegTerm.app (PsMinRegTerm.recursor 0 1 0 0 1 1 PsMinRegTy.empty) (PsMinRegTerm.lam (PsMinRegTy.data 0) (PsMinRegTerm.lam PsMinRegTy.empty (PsMinRegTerm.var 0)))) (PsMinRegTerm.ctor 0 0))
  else if Nat.beq index 50 then psMinRegClosedCase (List.cons psMinRegNatListSpec List.nil) (PsMinRegTy.data 0) (PsMinRegTerm.app (PsMinRegTerm.app (PsMinRegTerm.ctor 0 1) (PsMinRegTerm.nat 7)) (PsMinRegTerm.nat 8))
  else if Nat.beq index 51 then psMinRegTyEq 1 (PsMinRegTy.arr (PsMinRegTy.data 0) PsMinRegTy.boolean) (PsMinRegTy.arr (PsMinRegTy.data 0) PsMinRegTy.boolean)
  else if Nat.beq index 52 then psMinRegTyValid 0 1 (PsMinRegTy.data 0)
  else if Nat.beq index 53 then psMinRegAccepted 0 64 (List.cons psMinRegTySpec List.nil) List.nil
  else if Nat.beq index 54 then psMinRegAccepted 128 0 (List.cons psMinRegTySpec List.nil) (List.cons (PsMinRegDeclaration.mk (PsMinRegTy.data 0) (PsMinRegTerm.ctor 0 0)) List.nil)
  else if Nat.beq index 55 then psMinRegAccepted 0 64 List.nil (List.cons (PsMinRegDeclaration.mk PsMinRegTy.nat (PsMinRegTerm.nat 7)) List.nil)
  else if Nat.beq index 56 then psMinRegAccepted 128 64 List.nil (List.cons (PsMinRegDeclaration.mk PsMinRegTy.nat (PsMinRegTerm.nat 7)) (List.cons (PsMinRegDeclaration.mk PsMinRegTy.empty (PsMinRegTerm.constant 0)) List.nil))
  else false
