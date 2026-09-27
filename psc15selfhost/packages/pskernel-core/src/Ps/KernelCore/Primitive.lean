import Ps.KernelCore.Resource
import Ps.KernelCore.Expr

def psKernelCorePrimitiveNatName : PsKernelCoreName :=
  PsKernelCoreName.str PsKernelCoreName.anonymous "Nat"

def psKernelCorePrimitiveBoolName : PsKernelCoreName :=
  PsKernelCoreName.str PsKernelCoreName.anonymous "Bool"

def psKernelCorePrimitiveBoolTrueName : PsKernelCoreName :=
  PsKernelCoreName.str psKernelCorePrimitiveBoolName "true"

def psKernelCorePrimitiveBoolFalseName : PsKernelCoreName :=
  PsKernelCoreName.str psKernelCorePrimitiveBoolName "false"

def psKernelCorePrimitiveNatZeroName : PsKernelCoreName :=
  PsKernelCoreName.str psKernelCorePrimitiveNatName "zero"

def psKernelCorePrimitiveNatSuccName : PsKernelCoreName :=
  PsKernelCoreName.str psKernelCorePrimitiveNatName "succ"

def psKernelCorePrimitiveNatAddName : PsKernelCoreName :=
  PsKernelCoreName.str psKernelCorePrimitiveNatName "add"

def psKernelCorePrimitiveNatSubName : PsKernelCoreName :=
  PsKernelCoreName.str psKernelCorePrimitiveNatName "sub"

def psKernelCorePrimitiveNatMulName : PsKernelCoreName :=
  PsKernelCoreName.str psKernelCorePrimitiveNatName "mul"

def psKernelCorePrimitiveNatPowName : PsKernelCoreName :=
  PsKernelCoreName.str psKernelCorePrimitiveNatName "pow"

def psKernelCorePrimitiveNatGcdName : PsKernelCoreName :=
  PsKernelCoreName.str psKernelCorePrimitiveNatName "gcd"

def psKernelCorePrimitiveNatModName : PsKernelCoreName :=
  PsKernelCoreName.str psKernelCorePrimitiveNatName "mod"

def psKernelCorePrimitiveNatDivName : PsKernelCoreName :=
  PsKernelCoreName.str psKernelCorePrimitiveNatName "div"

def psKernelCorePrimitiveNatBeqName : PsKernelCoreName :=
  PsKernelCoreName.str psKernelCorePrimitiveNatName "beq"

def psKernelCorePrimitiveNatBleName : PsKernelCoreName :=
  PsKernelCoreName.str psKernelCorePrimitiveNatName "ble"

def psKernelCoreNatLiteralValue?
    (expr : PsKernelCoreExpr) : PsKernelCoreOption Nat :=
  match expr with
  | PsKernelCoreExpr.lit literal =>
      match literal with
      | PsKernelCoreLiteral.nat value => PsKernelCoreOption.some value
      | PsKernelCoreLiteral.str _ => PsKernelCoreOption.none
  | PsKernelCoreExpr.const name levels =>
      match levels with
      | PsKernelCoreList.nil =>
          if psKernelCoreNameEq name psKernelCorePrimitiveNatZeroName then
            PsKernelCoreOption.some 0
          else
            PsKernelCoreOption.none
      | PsKernelCoreList.cons _ _ => PsKernelCoreOption.none
  | _ => PsKernelCoreOption.none

def psKernelCoreBoolExpr (value : Bool) : PsKernelCoreExpr :=
  if value then
    PsKernelCoreExpr.const
      psKernelCorePrimitiveBoolTrueName PsKernelCoreList.nil
  else
    PsKernelCoreExpr.const
      psKernelCorePrimitiveBoolFalseName PsKernelCoreList.nil

def psKernelCoreIsNatZeroExpr (expr : PsKernelCoreExpr) : Bool :=
  match psKernelCoreNatLiteralValue? expr with
  | PsKernelCoreOption.some value => Nat.beq value 0
  | PsKernelCoreOption.none => false

def psKernelCoreNatPredExpr?
    (expr : PsKernelCoreExpr) : PsKernelCoreOption PsKernelCoreExpr :=
  match expr with
  | PsKernelCoreExpr.lit literal =>
      match literal with
      | PsKernelCoreLiteral.nat value =>
          if Nat.beq value 0 then
            PsKernelCoreOption.none
          else
            PsKernelCoreOption.some
              (PsKernelCoreExpr.lit
                (PsKernelCoreLiteral.nat (Nat.sub value 1)))
      | PsKernelCoreLiteral.str _ => PsKernelCoreOption.none
  | PsKernelCoreExpr.app fn arg =>
      match fn with
      | PsKernelCoreExpr.const name levels =>
          match levels with
          | PsKernelCoreList.nil =>
              if psKernelCoreNameEq name psKernelCorePrimitiveNatSuccName then
                PsKernelCoreOption.some arg
              else
                PsKernelCoreOption.none
          | PsKernelCoreList.cons _ _ => PsKernelCoreOption.none
      | _ => PsKernelCoreOption.none
  | _ => PsKernelCoreOption.none

def psKernelCoreNatGcdFuel
    (fuel : Nat) : Nat -> Nat -> Nat :=
  match fuel with
  | Nat.zero =>
      fun (left : Nat) (_right : Nat) => left
  | Nat.succ remaining =>
      let smaller : Nat -> Nat -> Nat :=
        psKernelCoreNatGcdFuel remaining;
      fun (left : Nat) (right : Nat) =>
        if Nat.beq right 0 then
          left
        else
          smaller right (Nat.mod left right)

def psKernelCoreNatGcd (left right : Nat) : Nat :=
  psKernelCoreNatGcdFuel (Nat.succ right) left right

def psKernelCoreNatPowFuel
    (fuel : Nat) : Nat -> Nat -> Nat :=
  match fuel with
  | Nat.zero =>
      fun (_base : Nat) (_exponent : Nat) => 1
  | Nat.succ remaining =>
      let smaller : Nat -> Nat -> Nat :=
        psKernelCoreNatPowFuel remaining;
      fun (base : Nat) (exponent : Nat) =>
        if Nat.beq exponent 0 then
          1
        else
          let squared := Nat.mul base base;
          let half := Nat.div exponent 2;
          if Nat.beq (Nat.mod exponent 2) 0 then
            smaller squared half
          else
            Nat.mul base (smaller squared half)

def psKernelCoreNatPow (base exponent : Nat) : Nat :=
  psKernelCoreNatPowFuel (Nat.succ exponent) base exponent

def psKernelCorePrimitiveSomeNat
    (value : Nat) :
    PsKernelCoreResult String (PsKernelCoreOption PsKernelCoreExpr) :=
  PsKernelCoreResult.ok
    (PsKernelCoreOption.some
      (PsKernelCoreExpr.lit (PsKernelCoreLiteral.nat value)))

def psKernelCorePrimitiveSomeBool
    (value : Bool) :
    PsKernelCoreResult String (PsKernelCoreOption PsKernelCoreExpr) :=
  PsKernelCoreResult.ok (PsKernelCoreOption.some (psKernelCoreBoolExpr value))

def psKernelCorePrimitiveNone :
    PsKernelCoreResult String (PsKernelCoreOption PsKernelCoreExpr) :=
  PsKernelCoreResult.ok PsKernelCoreOption.none

def psKernelCorePrimitiveCheckedNat
    (resources : PsKernelCoreResourceConfig)
    (value : Nat) :
    PsKernelCoreResult String (PsKernelCoreOption PsKernelCoreExpr) :=
  match psKernelCoreCheckNatSize resources value with
  | PsKernelCoreResult.error message => PsKernelCoreResult.error message
  | PsKernelCoreResult.ok _ => psKernelCorePrimitiveSomeNat value

def psKernelCoreReduceNatUnary
    (resources : PsKernelCoreResourceConfig)
    (operation : PsKernelCoreName)
    (value : Nat) :
    PsKernelCoreResult String (PsKernelCoreOption PsKernelCoreExpr) :=
  if psKernelCoreNameEq operation psKernelCorePrimitiveNatSuccName then
    psKernelCorePrimitiveCheckedNat resources (Nat.add value 1)
  else
    psKernelCorePrimitiveNone

def psKernelCoreReduceNatPow
    (resources : PsKernelCoreResourceConfig)
    (left right : Nat) :
    PsKernelCoreResult String (PsKernelCoreOption PsKernelCoreExpr) :=
  match psKernelCoreCheckCountArg "Nat.pow" right with
  | PsKernelCoreResult.error message => PsKernelCoreResult.error message
  | PsKernelCoreResult.ok _ =>
      if Nat.ble 2 left then
        if Nat.beq right 0 then
          psKernelCorePrimitiveSomeNat 1
        else
          let allowed := Nat.div resources.maxNatSize right;
          if Nat.ble (psKernelCoreNatSizeInBytes left) allowed then
            psKernelCorePrimitiveSomeNat
              (psKernelCoreNatPow left right)
          else
            PsKernelCoreResult.error
              "the kernel refused to evaluate Nat.pow because the result would exceed the maximum numeral size"
      else
        psKernelCorePrimitiveSomeNat
          (psKernelCoreNatPow left right)

def psKernelCoreReduceNatBinary
    (resources : PsKernelCoreResourceConfig)
    (operation : PsKernelCoreName)
    (left right : Nat) :
    PsKernelCoreResult String (PsKernelCoreOption PsKernelCoreExpr) :=
  if psKernelCoreNameEq operation psKernelCorePrimitiveNatAddName then
    psKernelCorePrimitiveCheckedNat resources (Nat.add left right)
  else if psKernelCoreNameEq operation psKernelCorePrimitiveNatSubName then
    psKernelCorePrimitiveCheckedNat resources (Nat.sub left right)
  else if psKernelCoreNameEq operation psKernelCorePrimitiveNatMulName then
    psKernelCorePrimitiveCheckedNat resources (Nat.mul left right)
  else if psKernelCoreNameEq operation psKernelCorePrimitiveNatPowName then
    psKernelCoreReduceNatPow resources left right
  else if psKernelCoreNameEq operation psKernelCorePrimitiveNatGcdName then
    psKernelCorePrimitiveSomeNat (psKernelCoreNatGcd left right)
  else if psKernelCoreNameEq operation psKernelCorePrimitiveNatModName then
    if Nat.beq right 0 then
      psKernelCorePrimitiveSomeNat left
    else
      psKernelCorePrimitiveSomeNat (Nat.mod left right)
  else if psKernelCoreNameEq operation psKernelCorePrimitiveNatDivName then
    if Nat.beq right 0 then
      psKernelCorePrimitiveSomeNat 0
    else
      psKernelCorePrimitiveSomeNat (Nat.div left right)
  else if psKernelCoreNameEq operation psKernelCorePrimitiveNatBeqName then
    psKernelCorePrimitiveSomeBool (Nat.beq left right)
  else if psKernelCoreNameEq operation psKernelCorePrimitiveNatBleName then
    psKernelCorePrimitiveSomeBool (Nat.ble left right)
  else
    psKernelCorePrimitiveNone
