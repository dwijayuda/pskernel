import Ps.MinKernel.Profile.OperationalCheck

def psMinOpMakeSpec (constructors : List (List PsMinRegField)) : PsMinRegSpec :=
  PsMinRegSpec.mk 0 0 0 1 (psMinRegCtorCount constructors) constructors

def psMinOpTypeSpec : PsMinRegSpec := psMinOpMakeSpec (List.cons List.nil (List.cons List.nil (List.cons List.nil (List.cons List.nil (List.cons (List.cons (PsMinRegField.ground PsMinRegTy.nat) List.nil) (List.cons (List.cons PsMinRegField.recursive (List.cons PsMinRegField.recursive List.nil)) (List.cons (List.cons PsMinRegField.recursive List.nil) (List.cons (List.cons PsMinRegField.recursive List.nil) List.nil))))))))
def psMinOpFieldSpec : PsMinRegSpec := psMinOpMakeSpec (List.cons (List.cons (PsMinRegField.ground (PsMinRegTy.data 0)) List.nil) (List.cons List.nil List.nil))
def psMinOpSpecSpec : PsMinRegSpec := psMinOpMakeSpec (List.cons (List.cons (PsMinRegField.ground PsMinRegTy.nat) (List.cons (PsMinRegField.ground PsMinRegTy.nat) (List.cons (PsMinRegField.ground PsMinRegTy.nat) (List.cons (PsMinRegField.ground PsMinRegTy.nat) (List.cons (PsMinRegField.ground PsMinRegTy.nat) (List.cons (PsMinRegField.ground (PsMinRegTy.list (PsMinRegTy.list (PsMinRegTy.data 0)))) List.nil)))))) List.nil)
def psMinOpTermSpec : PsMinRegSpec := psMinOpMakeSpec (List.cons (List.cons (PsMinRegField.ground PsMinRegTy.nat) List.nil) (List.cons (List.cons (PsMinRegField.ground PsMinRegTy.nat) List.nil) (List.cons List.nil (List.cons (List.cons (PsMinRegField.ground PsMinRegTy.nat) List.nil) (List.cons (List.cons (PsMinRegField.ground PsMinRegTy.boolean) List.nil) (List.cons (List.cons (PsMinRegField.ground (PsMinRegTy.data 2)) (List.cons PsMinRegField.recursive List.nil)) (List.cons (List.cons PsMinRegField.recursive (List.cons PsMinRegField.recursive List.nil)) (List.cons (List.cons (PsMinRegField.ground PsMinRegTy.nat) (List.cons (PsMinRegField.ground PsMinRegTy.nat) List.nil)) (List.cons (List.cons (PsMinRegField.ground PsMinRegTy.nat) (List.cons (PsMinRegField.ground PsMinRegTy.nat) (List.cons (PsMinRegField.ground PsMinRegTy.nat) (List.cons (PsMinRegField.ground PsMinRegTy.nat) (List.cons (PsMinRegField.ground PsMinRegTy.nat) (List.cons (PsMinRegField.ground PsMinRegTy.nat) (List.cons (PsMinRegField.ground (PsMinRegTy.data 2)) List.nil))))))) List.nil)))))))))
def psMinOpDeclarationSpec : PsMinRegSpec := psMinOpMakeSpec (List.cons (List.cons (PsMinRegField.ground (PsMinRegTy.data 3)) (List.cons (PsMinRegField.ground (PsMinRegTy.data 0)) List.nil)) List.nil)
def psMinOpRuntimeRegistry : List PsMinRegSpec :=
  (List.cons psMinOpDeclarationSpec (List.cons psMinOpTermSpec (List.cons psMinOpSpecSpec (List.cons psMinOpFieldSpec (List.cons psMinOpTypeSpec List.nil)))))

def psMinOpAutoPrimitive (schema : PsMinOpPrimitive) : PsMinOpTerm :=
  PsMinOpTerm.primitive schema (psMinOpPrimitiveLevel schema) (psMinOpPrimitiveParameters schema)
    0 (psMinOpPrimitiveMotives schema) (psMinOpPrimitiveMinors schema)

def psMinOpAccepted (termFuel declarationFuel : Nat) (specs : List PsMinRegSpec)
    (declarations : List PsMinOpDeclaration) : Bool :=
  match psMinOpCheckEnvironment termFuel declarationFuel specs declarations with
  | Option.none => false
  | Option.some _ => true

def psMinOpClosedCase (specs : List PsMinRegSpec) (type : PsMinRegTy) (term : PsMinOpTerm) : Bool :=
  psMinOpAccepted 256 64 specs (List.cons (PsMinOpDeclaration.mk type term) List.nil)

def psMinOpVector (index : Nat) : Bool :=
  if Nat.beq index 0 then psMinOpAccepted 0 0 List.nil List.nil
  else if Nat.beq index 1 then psMinOpClosedCase List.nil PsMinRegTy.nat (PsMinOpTerm.base (PsMinRegTerm.nat 7))
  else if Nat.beq index 2 then psMinOpClosedCase List.nil PsMinRegTy.nat (PsMinOpTerm.letE PsMinRegTy.nat (PsMinOpTerm.base (PsMinRegTerm.nat 7)) (PsMinOpTerm.base (PsMinRegTerm.var 0)))
  else if Nat.beq index 3 then psMinOpClosedCase List.nil PsMinRegTy.nat (PsMinOpTerm.letE PsMinRegTy.nat (PsMinOpTerm.base (PsMinRegTerm.nat 7)) (PsMinOpTerm.letE PsMinRegTy.boolean (PsMinOpTerm.base (PsMinRegTerm.boolean true)) (PsMinOpTerm.base (PsMinRegTerm.var 1))))
  else if Nat.beq index 4 then psMinOpClosedCase List.nil (PsMinRegTy.arr PsMinRegTy.nat PsMinRegTy.nat) (PsMinOpTerm.lam PsMinRegTy.nat (PsMinOpTerm.letE PsMinRegTy.boolean (PsMinOpTerm.base (PsMinRegTerm.boolean false)) (PsMinOpTerm.base (PsMinRegTerm.var 1))))
  else if Nat.beq index 5 then psMinOpClosedCase psMinOpRuntimeRegistry (PsMinRegTy.arr (PsMinRegTy.data 2) PsMinRegTy.nat) (PsMinOpTerm.projection 2 0)
  else if Nat.beq index 6 then psMinOpClosedCase psMinOpRuntimeRegistry (PsMinRegTy.arr (PsMinRegTy.data 2) PsMinRegTy.nat) (PsMinOpTerm.projection 2 1)
  else if Nat.beq index 7 then psMinOpClosedCase psMinOpRuntimeRegistry (PsMinRegTy.arr (PsMinRegTy.data 2) PsMinRegTy.nat) (PsMinOpTerm.projection 2 2)
  else if Nat.beq index 8 then psMinOpClosedCase psMinOpRuntimeRegistry (PsMinRegTy.arr (PsMinRegTy.data 2) PsMinRegTy.nat) (PsMinOpTerm.projection 2 3)
  else if Nat.beq index 9 then psMinOpClosedCase psMinOpRuntimeRegistry (PsMinRegTy.arr (PsMinRegTy.data 2) PsMinRegTy.nat) (PsMinOpTerm.projection 2 4)
  else if Nat.beq index 10 then psMinOpClosedCase psMinOpRuntimeRegistry (PsMinRegTy.arr (PsMinRegTy.data 2) (PsMinRegTy.list (PsMinRegTy.list (PsMinRegTy.data 3)))) (PsMinOpTerm.projection 2 5)
  else if Nat.beq index 11 then psMinOpClosedCase psMinOpRuntimeRegistry (PsMinRegTy.arr (PsMinRegTy.data 0) (PsMinRegTy.data 4)) (PsMinOpTerm.projection 0 0)
  else if Nat.beq index 12 then psMinOpClosedCase psMinOpRuntimeRegistry (PsMinRegTy.arr (PsMinRegTy.data 0) (PsMinRegTy.data 1)) (PsMinOpTerm.projection 0 1)
  else if Nat.beq index 13 then psMinOpClosedCase psMinOpRuntimeRegistry PsMinRegTy.nat (PsMinOpTerm.app (PsMinOpTerm.projection 2 4) (PsMinOpTerm.app (PsMinOpTerm.app (PsMinOpTerm.app (PsMinOpTerm.app (PsMinOpTerm.app (PsMinOpTerm.app (PsMinOpTerm.base (PsMinRegTerm.ctor 2 0)) (PsMinOpTerm.base (PsMinRegTerm.nat 0))) (PsMinOpTerm.base (PsMinRegTerm.nat 0))) (PsMinOpTerm.base (PsMinRegTerm.nat 0))) (PsMinOpTerm.base (PsMinRegTerm.nat 0))) (PsMinOpTerm.base (PsMinRegTerm.nat 0))) (psMinOpAutoPrimitive (PsMinOpPrimitive.listNil (PsMinRegTy.list (PsMinRegTy.data 3))))))
  else if Nat.beq index 14 then psMinOpClosedCase psMinOpRuntimeRegistry (PsMinRegTy.data 4) (PsMinOpTerm.app (PsMinOpTerm.projection 0 0) (PsMinOpTerm.app (PsMinOpTerm.app (PsMinOpTerm.base (PsMinRegTerm.ctor 0 0)) (PsMinOpTerm.base (PsMinRegTerm.ctor 4 1))) (PsMinOpTerm.base (PsMinRegTerm.ctor 1 2))))
  else if Nat.beq index 15 then psMinOpClosedCase psMinOpRuntimeRegistry (PsMinRegTy.data 1) (PsMinOpTerm.letE (PsMinRegTy.data 0) (PsMinOpTerm.app (PsMinOpTerm.app (PsMinOpTerm.base (PsMinRegTerm.ctor 0 0)) (PsMinOpTerm.base (PsMinRegTerm.ctor 4 1))) (PsMinOpTerm.base (PsMinRegTerm.ctor 1 2))) (PsMinOpTerm.app (PsMinOpTerm.projection 0 1) (PsMinOpTerm.base (PsMinRegTerm.var 0))))
  else if Nat.beq index 16 then psMinOpClosedCase List.nil (PsMinRegTy.arr PsMinRegTy.nat PsMinRegTy.nat) (psMinOpAutoPrimitive PsMinOpPrimitive.natSucc)
  else if Nat.beq index 17 then psMinOpClosedCase List.nil (PsMinRegTy.arr PsMinRegTy.nat PsMinRegTy.nat) (psMinOpAutoPrimitive PsMinOpPrimitive.natPred)
  else if Nat.beq index 18 then psMinOpClosedCase List.nil (PsMinRegTy.arr PsMinRegTy.nat (PsMinRegTy.arr PsMinRegTy.nat PsMinRegTy.nat)) (psMinOpAutoPrimitive PsMinOpPrimitive.natAdd)
  else if Nat.beq index 19 then psMinOpClosedCase List.nil (PsMinRegTy.arr PsMinRegTy.nat (PsMinRegTy.arr PsMinRegTy.nat PsMinRegTy.nat)) (psMinOpAutoPrimitive PsMinOpPrimitive.natSub)
  else if Nat.beq index 20 then psMinOpClosedCase List.nil (PsMinRegTy.arr PsMinRegTy.nat (PsMinRegTy.arr PsMinRegTy.nat PsMinRegTy.boolean)) (psMinOpAutoPrimitive PsMinOpPrimitive.natBeq)
  else if Nat.beq index 21 then psMinOpClosedCase List.nil (PsMinRegTy.arr PsMinRegTy.nat (PsMinRegTy.arr PsMinRegTy.nat PsMinRegTy.boolean)) (psMinOpAutoPrimitive PsMinOpPrimitive.natBlt)
  else if Nat.beq index 22 then psMinOpClosedCase List.nil (PsMinRegTy.arr PsMinRegTy.boolean PsMinRegTy.boolean) (psMinOpAutoPrimitive PsMinOpPrimitive.boolNot)
  else if Nat.beq index 23 then psMinOpClosedCase List.nil (PsMinRegTy.arr PsMinRegTy.boolean (PsMinRegTy.arr PsMinRegTy.boolean PsMinRegTy.boolean)) (psMinOpAutoPrimitive PsMinOpPrimitive.boolBeq)
  else if Nat.beq index 24 then psMinOpClosedCase List.nil PsMinRegTy.nat (PsMinOpTerm.app (PsMinOpTerm.app (psMinOpAutoPrimitive PsMinOpPrimitive.natAdd) (PsMinOpTerm.base (PsMinRegTerm.nat 8))) (PsMinOpTerm.base (PsMinRegTerm.nat 9)))
  else if Nat.beq index 25 then psMinOpClosedCase List.nil PsMinRegTy.nat (PsMinOpTerm.app (PsMinOpTerm.app (PsMinOpTerm.app (psMinOpAutoPrimitive (PsMinOpPrimitive.natRec PsMinRegTy.nat)) (PsMinOpTerm.base (PsMinRegTerm.nat 0))) (PsMinOpTerm.lam PsMinRegTy.nat (PsMinOpTerm.lam PsMinRegTy.nat (PsMinOpTerm.app (psMinOpAutoPrimitive PsMinOpPrimitive.natSucc) (PsMinOpTerm.base (PsMinRegTerm.var 0)))))) (PsMinOpTerm.base (PsMinRegTerm.nat 5)))
  else if Nat.beq index 26 then psMinOpClosedCase List.nil (PsMinRegTy.list PsMinRegTy.nat) (psMinOpAutoPrimitive (PsMinOpPrimitive.listNil PsMinRegTy.nat))
  else if Nat.beq index 27 then psMinOpClosedCase List.nil (PsMinRegTy.list PsMinRegTy.nat) (PsMinOpTerm.app (PsMinOpTerm.app (psMinOpAutoPrimitive (PsMinOpPrimitive.listCons PsMinRegTy.nat)) (PsMinOpTerm.base (PsMinRegTerm.nat 7))) (psMinOpAutoPrimitive (PsMinOpPrimitive.listNil PsMinRegTy.nat)))
  else if Nat.beq index 28 then psMinOpClosedCase List.nil PsMinRegTy.nat (PsMinOpTerm.app (PsMinOpTerm.app (PsMinOpTerm.app (psMinOpAutoPrimitive (PsMinOpPrimitive.listRec PsMinRegTy.nat PsMinRegTy.nat)) (PsMinOpTerm.base (PsMinRegTerm.nat 0))) (PsMinOpTerm.lam PsMinRegTy.nat (PsMinOpTerm.lam (PsMinRegTy.list PsMinRegTy.nat) (PsMinOpTerm.lam PsMinRegTy.nat (PsMinOpTerm.base (PsMinRegTerm.var 2)))))) (PsMinOpTerm.app (PsMinOpTerm.app (psMinOpAutoPrimitive (PsMinOpPrimitive.listCons PsMinRegTy.nat)) (PsMinOpTerm.base (PsMinRegTerm.nat 7))) (psMinOpAutoPrimitive (PsMinOpPrimitive.listNil PsMinRegTy.nat))))
  else if Nat.beq index 29 then psMinOpClosedCase List.nil (PsMinRegTy.option PsMinRegTy.nat) (psMinOpAutoPrimitive (PsMinOpPrimitive.optionNone PsMinRegTy.nat))
  else if Nat.beq index 30 then psMinOpClosedCase List.nil (PsMinRegTy.option PsMinRegTy.nat) (PsMinOpTerm.app (psMinOpAutoPrimitive (PsMinOpPrimitive.optionSome PsMinRegTy.nat)) (PsMinOpTerm.base (PsMinRegTerm.nat 7)))
  else if Nat.beq index 31 then psMinOpClosedCase List.nil PsMinRegTy.nat (PsMinOpTerm.app (PsMinOpTerm.app (PsMinOpTerm.app (psMinOpAutoPrimitive (PsMinOpPrimitive.optionRec PsMinRegTy.nat PsMinRegTy.nat)) (PsMinOpTerm.base (PsMinRegTerm.nat 0))) (PsMinOpTerm.lam PsMinRegTy.nat (PsMinOpTerm.base (PsMinRegTerm.var 0)))) (PsMinOpTerm.app (psMinOpAutoPrimitive (PsMinOpPrimitive.optionSome PsMinRegTy.nat)) (PsMinOpTerm.base (PsMinRegTerm.nat 7))))
  else if Nat.beq index 32 then psMinOpClosedCase List.nil PsMinRegTy.nat (PsMinOpTerm.app (PsMinOpTerm.app (PsMinOpTerm.app (PsMinOpTerm.app (psMinOpAutoPrimitive (PsMinOpPrimitive.boolEqIte PsMinRegTy.nat)) (PsMinOpTerm.base (PsMinRegTerm.boolean true))) (PsMinOpTerm.base (PsMinRegTerm.boolean true))) (PsMinOpTerm.base (PsMinRegTerm.nat 3))) (PsMinOpTerm.base (PsMinRegTerm.nat 4)))
  else if Nat.beq index 33 then psMinOpClosedCase List.nil PsMinRegTy.nat (PsMinOpTerm.app (PsMinOpTerm.app (PsMinOpTerm.app (PsMinOpTerm.app (psMinOpAutoPrimitive (PsMinOpPrimitive.boolEqIte PsMinRegTy.nat)) (PsMinOpTerm.base (PsMinRegTerm.boolean false))) (PsMinOpTerm.base (PsMinRegTerm.boolean true))) (PsMinOpTerm.base (PsMinRegTerm.nat 3))) (PsMinOpTerm.base (PsMinRegTerm.nat 4)))
  else if Nat.beq index 34 then psMinOpClosedCase List.nil (PsMinRegTy.arr PsMinRegTy.boolean PsMinRegTy.nat) (PsMinOpTerm.lam PsMinRegTy.boolean (PsMinOpTerm.app (PsMinOpTerm.app (PsMinOpTerm.app (PsMinOpTerm.app (psMinOpAutoPrimitive (PsMinOpPrimitive.boolEqIte PsMinRegTy.nat)) (PsMinOpTerm.base (PsMinRegTerm.var 0))) (PsMinOpTerm.base (PsMinRegTerm.boolean true))) (PsMinOpTerm.base (PsMinRegTerm.nat 3))) (PsMinOpTerm.base (PsMinRegTerm.nat 4))))
  else if Nat.beq index 35 then psMinOpAccepted 256 64 List.nil (List.cons (PsMinOpDeclaration.mk PsMinRegTy.nat (PsMinOpTerm.letE PsMinRegTy.nat (PsMinOpTerm.base (PsMinRegTerm.nat 7)) (PsMinOpTerm.base (PsMinRegTerm.var 0)))) (List.cons (PsMinOpDeclaration.mk PsMinRegTy.nat (PsMinOpTerm.app (PsMinOpTerm.app (psMinOpAutoPrimitive PsMinOpPrimitive.natAdd) (PsMinOpTerm.base (PsMinRegTerm.constant 0))) (PsMinOpTerm.base (PsMinRegTerm.nat 1)))) List.nil))
  else if Nat.beq index 36 then psMinOpClosedCase List.nil PsMinRegTy.nat (PsMinOpTerm.letE PsMinRegTy.nat (PsMinOpTerm.base (PsMinRegTerm.var 0)) (PsMinOpTerm.base (PsMinRegTerm.var 0)))
  else if Nat.beq index 37 then psMinOpClosedCase List.nil PsMinRegTy.nat (PsMinOpTerm.letE PsMinRegTy.nat (PsMinOpTerm.base (PsMinRegTerm.boolean true)) (PsMinOpTerm.base (PsMinRegTerm.var 0)))
  else if Nat.beq index 38 then psMinOpClosedCase List.nil PsMinRegTy.nat (PsMinOpTerm.letE PsMinRegTy.nat (PsMinOpTerm.base (PsMinRegTerm.nat 7)) (PsMinOpTerm.base (PsMinRegTerm.var 1)))
  else if Nat.beq index 39 then psMinOpClosedCase List.nil (PsMinRegTy.data 0) (PsMinOpTerm.letE (PsMinRegTy.data 0) (PsMinOpTerm.base (PsMinRegTerm.nat 7)) (PsMinOpTerm.base (PsMinRegTerm.var 0)))
  else if Nat.beq index 40 then psMinOpClosedCase List.nil PsMinRegTy.empty (PsMinOpTerm.letE PsMinRegTy.nat (PsMinOpTerm.base (PsMinRegTerm.nat 7)) (PsMinOpTerm.base (PsMinRegTerm.var 0)))
  else if Nat.beq index 41 then psMinOpClosedCase psMinOpRuntimeRegistry PsMinRegTy.nat (PsMinOpTerm.projection 0 2)
  else if Nat.beq index 42 then psMinOpClosedCase psMinOpRuntimeRegistry PsMinRegTy.nat (PsMinOpTerm.projection 2 6)
  else if Nat.beq index 43 then psMinOpClosedCase psMinOpRuntimeRegistry PsMinRegTy.nat (PsMinOpTerm.projection 1 0)
  else if Nat.beq index 44 then psMinOpClosedCase psMinOpRuntimeRegistry PsMinRegTy.nat (PsMinOpTerm.projection 3 0)
  else if Nat.beq index 45 then psMinOpClosedCase psMinOpRuntimeRegistry PsMinRegTy.nat (PsMinOpTerm.projection 4 0)
  else if Nat.beq index 46 then psMinOpClosedCase psMinOpRuntimeRegistry PsMinRegTy.nat (PsMinOpTerm.projection 9 0)
  else if Nat.beq index 47 then psMinOpClosedCase psMinOpRuntimeRegistry PsMinRegTy.nat (PsMinOpTerm.app (PsMinOpTerm.projection 2 0) (PsMinOpTerm.app (PsMinOpTerm.app (PsMinOpTerm.base (PsMinRegTerm.ctor 0 0)) (PsMinOpTerm.base (PsMinRegTerm.ctor 4 1))) (PsMinOpTerm.base (PsMinRegTerm.ctor 1 2))))
  else if Nat.beq index 48 then psMinOpClosedCase psMinOpRuntimeRegistry (PsMinRegTy.arr (PsMinRegTy.data 0) (PsMinRegTy.data 1)) (PsMinOpTerm.projection 0 0)
  else if Nat.beq index 49 then psMinOpClosedCase List.nil PsMinRegTy.nat (PsMinOpTerm.app (PsMinOpTerm.app (psMinOpAutoPrimitive PsMinOpPrimitive.natAdd) (PsMinOpTerm.base (PsMinRegTerm.boolean true))) (PsMinOpTerm.base (PsMinRegTerm.nat 1)))
  else if Nat.beq index 50 then psMinOpClosedCase List.nil (PsMinRegTy.list PsMinRegTy.nat) (PsMinOpTerm.app (PsMinOpTerm.app (psMinOpAutoPrimitive (PsMinOpPrimitive.listCons PsMinRegTy.nat)) (PsMinOpTerm.base (PsMinRegTerm.nat 7))) (PsMinOpTerm.base (PsMinRegTerm.nat 8)))
  else if Nat.beq index 51 then psMinOpClosedCase List.nil (PsMinRegTy.option PsMinRegTy.nat) (PsMinOpTerm.app (psMinOpAutoPrimitive (PsMinOpPrimitive.optionSome PsMinRegTy.nat)) (PsMinOpTerm.base (PsMinRegTerm.boolean true)))
  else if Nat.beq index 52 then psMinOpClosedCase List.nil PsMinRegTy.nat (PsMinOpTerm.app (PsMinOpTerm.app (PsMinOpTerm.app (psMinOpAutoPrimitive (PsMinOpPrimitive.listRec PsMinRegTy.nat PsMinRegTy.nat)) (PsMinOpTerm.base (PsMinRegTerm.nat 0))) (PsMinOpTerm.lam (PsMinRegTy.list PsMinRegTy.nat) (PsMinOpTerm.lam PsMinRegTy.nat (PsMinOpTerm.lam PsMinRegTy.nat (PsMinOpTerm.base (PsMinRegTerm.var 0)))))) (PsMinOpTerm.app (PsMinOpTerm.app (psMinOpAutoPrimitive (PsMinOpPrimitive.listCons PsMinRegTy.nat)) (PsMinOpTerm.base (PsMinRegTerm.nat 7))) (psMinOpAutoPrimitive (PsMinOpPrimitive.listNil PsMinRegTy.nat))))
  else if Nat.beq index 53 then psMinOpClosedCase List.nil PsMinRegTy.nat (PsMinOpTerm.app (PsMinOpTerm.app (PsMinOpTerm.app (psMinOpAutoPrimitive (PsMinOpPrimitive.natRec PsMinRegTy.nat)) (PsMinOpTerm.base (PsMinRegTerm.nat 0))) (PsMinOpTerm.lam PsMinRegTy.nat (PsMinOpTerm.lam PsMinRegTy.nat (PsMinOpTerm.base (PsMinRegTerm.boolean false))))) (PsMinOpTerm.base (PsMinRegTerm.nat 4)))
  else if Nat.beq index 54 then psMinOpClosedCase List.nil PsMinRegTy.nat (PsMinOpTerm.app (PsMinOpTerm.app (PsMinOpTerm.app (psMinOpAutoPrimitive (PsMinOpPrimitive.optionRec PsMinRegTy.nat PsMinRegTy.nat)) (PsMinOpTerm.base (PsMinRegTerm.nat 0))) (PsMinOpTerm.lam PsMinRegTy.boolean (PsMinOpTerm.base (PsMinRegTerm.nat 7)))) (psMinOpAutoPrimitive (PsMinOpPrimitive.optionNone PsMinRegTy.nat)))
  else if Nat.beq index 55 then psMinOpClosedCase List.nil PsMinRegTy.nat (PsMinOpTerm.app (PsMinOpTerm.app (PsMinOpTerm.app (PsMinOpTerm.app (psMinOpAutoPrimitive (PsMinOpPrimitive.boolEqIte PsMinRegTy.nat)) (PsMinOpTerm.base (PsMinRegTerm.nat 0))) (PsMinOpTerm.base (PsMinRegTerm.boolean true))) (PsMinOpTerm.base (PsMinRegTerm.nat 3))) (PsMinOpTerm.base (PsMinRegTerm.nat 4)))
  else if Nat.beq index 56 then psMinOpClosedCase List.nil PsMinRegTy.nat (PsMinOpTerm.app (PsMinOpTerm.app (PsMinOpTerm.app (PsMinOpTerm.app (psMinOpAutoPrimitive (PsMinOpPrimitive.boolEqIte PsMinRegTy.nat)) (PsMinOpTerm.base (PsMinRegTerm.boolean true))) (PsMinOpTerm.base (PsMinRegTerm.boolean true))) (PsMinOpTerm.base (PsMinRegTerm.boolean false))) (PsMinOpTerm.base (PsMinRegTerm.nat 4)))
  else if Nat.beq index 57 then psMinOpClosedCase List.nil PsMinRegTy.empty (psMinOpAutoPrimitive (PsMinOpPrimitive.boolEqIte PsMinRegTy.empty))
  else if Nat.beq index 58 then psMinOpClosedCase List.nil PsMinRegTy.nat (PsMinOpTerm.primitive PsMinOpPrimitive.natSucc 1 0 0 0 0)
  else if Nat.beq index 59 then psMinOpClosedCase List.nil PsMinRegTy.nat (PsMinOpTerm.primitive PsMinOpPrimitive.natSucc 0 1 0 0 0)
  else if Nat.beq index 60 then psMinOpClosedCase List.nil PsMinRegTy.nat (PsMinOpTerm.primitive PsMinOpPrimitive.natSucc 0 0 1 0 0)
  else if Nat.beq index 61 then psMinOpClosedCase List.nil PsMinRegTy.nat (PsMinOpTerm.primitive (PsMinOpPrimitive.natRec PsMinRegTy.nat) 0 0 0 1 2)
  else if Nat.beq index 62 then psMinOpClosedCase List.nil PsMinRegTy.nat (PsMinOpTerm.primitive (PsMinOpPrimitive.natRec PsMinRegTy.nat) 1 0 0 2 2)
  else if Nat.beq index 63 then psMinOpClosedCase List.nil PsMinRegTy.nat (PsMinOpTerm.primitive (PsMinOpPrimitive.natRec PsMinRegTy.nat) 1 0 0 1 3)
  else if Nat.beq index 64 then psMinOpClosedCase List.nil PsMinRegTy.nat (PsMinOpTerm.primitive (PsMinOpPrimitive.listNil PsMinRegTy.nat) 0 0 0 0 0)
  else if Nat.beq index 65 then psMinOpClosedCase List.nil PsMinRegTy.nat (PsMinOpTerm.primitive (PsMinOpPrimitive.listRec PsMinRegTy.nat PsMinRegTy.nat) 1 0 0 1 2)
  else if Nat.beq index 66 then psMinOpClosedCase List.nil PsMinRegTy.nat (PsMinOpTerm.primitive (PsMinOpPrimitive.optionRec PsMinRegTy.nat PsMinRegTy.nat) 1 1 0 1 1)
  else if Nat.beq index 67 then psMinOpClosedCase List.nil PsMinRegTy.nat (PsMinOpTerm.primitive (PsMinOpPrimitive.boolEqIte PsMinRegTy.nat) 1 1 0 1 0)
  else if Nat.beq index 68 then psMinOpClosedCase List.nil PsMinRegTy.nat (PsMinOpTerm.primitive (PsMinOpPrimitive.boolEqIte PsMinRegTy.nat) 1 1 0 0 2)
  else if Nat.beq index 69 then psMinOpClosedCase List.nil PsMinRegTy.nat (PsMinOpTerm.primitive (PsMinOpPrimitive.boolEqIte PsMinRegTy.nat) 0 1 0 0 0)
  else if Nat.beq index 70 then psMinOpClosedCase List.nil (PsMinRegTy.list (PsMinRegTy.data 0)) (psMinOpAutoPrimitive (PsMinOpPrimitive.listNil (PsMinRegTy.data 0)))
  else if Nat.beq index 71 then psMinOpClosedCase List.nil PsMinRegTy.nat (psMinOpAutoPrimitive (PsMinOpPrimitive.optionRec PsMinRegTy.nat (PsMinRegTy.data 0)))
  else if Nat.beq index 72 then psMinOpClosedCase List.nil PsMinRegTy.nat (PsMinOpTerm.base (PsMinRegTerm.constant 0))
  else if Nat.beq index 73 then psMinOpAccepted 0 64 List.nil (List.cons (PsMinOpDeclaration.mk PsMinRegTy.nat (PsMinOpTerm.base (PsMinRegTerm.nat 7))) List.nil)
  else if Nat.beq index 74 then psMinOpAccepted 256 0 List.nil (List.cons (PsMinOpDeclaration.mk PsMinRegTy.nat (PsMinOpTerm.base (PsMinRegTerm.nat 7))) List.nil)
  else if Nat.beq index 75 then psMinOpAccepted 0 64 psMinOpRuntimeRegistry List.nil
  else false
