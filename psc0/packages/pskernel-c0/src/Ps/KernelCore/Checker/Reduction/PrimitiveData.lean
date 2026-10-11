import Ps.KernelCore.Checker.Context

def psKernelNatGcdWithFuel
    (fuel : Nat) :
    Nat -> Nat -> Nat :=
  match fuel with
  | Nat.zero =>
      fun
        (left : Nat)
        (_right : Nat) =>
        left
  | Nat.succ remaining =>
      let smaller :
          Nat -> Nat -> Nat :=
        psKernelNatGcdWithFuel remaining;
      fun
        (left : Nat)
        (right : Nat) =>
        if Nat.beq right 0 then
          left
        else
          smaller
            right
            (Nat.mod left right)

def psKernelNatGcd
    (left : Nat)
    (right : Nat) : Nat :=
  psKernelNatGcdWithFuel
    (Nat.succ right)
    left
    right

def psKernelNatWordBase : Nat :=
  18446744073709551616

def psKernelNatHeapWordCountWithFuel
    (fuel : Nat) :
    Nat -> Nat :=
  match fuel with
  | Nat.zero =>
      fun (_value : Nat) =>
        0
  | Nat.succ remaining =>
      let smaller : Nat -> Nat :=
        psKernelNatHeapWordCountWithFuel remaining;
      fun (value : Nat) =>
        if Nat.beq value 0 then
          0
        else
          Nat.succ
            (smaller
              (Nat.div
                value
                psKernelNatWordBase))

def psKernelNatHeapWordCount
    (value : Nat) : Nat :=
  psKernelNatHeapWordCountWithFuel
    (Nat.succ value)
    value

def psKernelNatSizeInBytes
    (value : Nat) : Nat :=
  if
      Nat.ble
        value
        psKernelLeanMaxSmallNat then
    8
  else
    Nat.mul
      (psKernelNatHeapWordCount value)
      8

def psKernelCheckNatSize
    (maxNatSize : Nat)
    (value : Nat) :
    Except String Unit :=
  if
      psKernelNatGt
        (psKernelNatSizeInBytes value)
        maxNatSize then
    Except.error
      "the kernel refused a Nat numeral because its size exceeds the maximum"
  else
    Except.ok Unit.unit

def psKernelCheckCountArg
    (op : String)
    (count : Nat) :
    Except String Unit :=
  if
      psKernelNatGt
        count
        psKernelLeanUInt32Max then
    Except.error
      (String.Internal.append
        (String.Internal.append
          "the kernel refused to evaluate "
          op)
        " because its second argument does not fit in a 32-bit unsigned integer")
  else
    Except.ok Unit.unit

def psKernelBoolExpr
    (value : Bool) :
    PsKernelExpr :=
  if value then
    PsKernelExpr.const
      psKernelBoolTrueName
      List.nil
  else
    PsKernelExpr.const
      psKernelBoolFalseName
      List.nil

def psKernelStringConstructorDataWithFuel
    (fuel : Nat) :
    String ->
    Nat ->
    PsKernelExpr ->
    PsKernelExpr ->
    PsKernelExpr ->
    PsKernelExpr :=
  match fuel with
  | Nat.zero =>
      fun
        (_value : String)
        (_position : Nat)
        (listNil : PsKernelExpr)
        (_listCons : PsKernelExpr)
        (_charOfNat : PsKernelExpr) =>
        listNil
  | Nat.succ remaining =>
      let smaller :
          String ->
          Nat ->
          PsKernelExpr ->
          PsKernelExpr ->
          PsKernelExpr ->
          PsKernelExpr :=
        psKernelStringConstructorDataWithFuel remaining;
      fun
        (value : String)
        (position : Nat)
        (listNil : PsKernelExpr)
        (listCons : PsKernelExpr)
        (charOfNat : PsKernelExpr) =>
        if
            String.Internal.atEnd
              value
              (String.Pos.Raw.mk position) then
          listNil
        else
          let char :=
            String.Internal.get
              value
              (String.Pos.Raw.mk position);
          let nextPosition :=
            String.Pos.Raw.byteIdx
              (String.Internal.next
                value
                (String.Pos.Raw.mk position));
          let charExpr :=
            PsKernelExpr.app
              charOfNat
              (PsKernelExpr.lit
                (PsKernelLiteral.nat
                  (Char.toNat char)));
          let rest :=
            smaller
              value
              nextPosition
              listNil
              listCons
              charOfNat;
          PsKernelExpr.app
            (PsKernelExpr.app
              listCons
              charExpr)
            rest

def psKernelStringLitToConstructor
    (value : String) :
    PsKernelExpr :=
  let charType :=
    PsKernelExpr.const
      psKernelCharName
      List.nil;
  let zeroLevels :=
    List.cons
      PsKernelLevel.zero
      List.nil;
  let listNil :=
    PsKernelExpr.app
      (PsKernelExpr.const
        psKernelListNilName
        zeroLevels)
      charType;
  let listCons :=
    PsKernelExpr.app
      (PsKernelExpr.const
        psKernelListConsName
        zeroLevels)
      charType;
  let charOfNat :=
    PsKernelExpr.const
      psKernelCharOfNatName
      List.nil;
  let data :=
    psKernelStringConstructorDataWithFuel
      (Nat.succ
        (String.utf8ByteSize value))
      value
      0
      listNil
      listCons
      charOfNat;
  PsKernelExpr.app
    (PsKernelExpr.const
      psKernelStringOfListName
      List.nil)
    data

def psKernelExprIsStringOfListApp
    (expr : PsKernelExpr) : Bool :=
  match expr with
  | PsKernelExpr.app fn _ =>
      match fn with
      | PsKernelExpr.const name levels =>
          match levels with
          | List.nil =>
              psKernelNameEq
                name
                psKernelStringOfListName
          | List.cons _ _ =>
              false
      | _ =>
          false
  | _ =>
      false
