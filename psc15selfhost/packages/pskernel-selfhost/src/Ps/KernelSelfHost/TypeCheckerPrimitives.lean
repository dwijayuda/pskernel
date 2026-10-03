import Ps.KernelSelfHost.TypeCheckerBase

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

def psKernelNatPowWithFuel
    (fuel : Nat) :
    Nat -> Nat -> Nat :=
  match fuel with
  | Nat.zero =>
      fun
        (_base : Nat)
        (_exponent : Nat) =>
        1
  | Nat.succ remaining =>
      let smaller :
          Nat -> Nat -> Nat :=
        psKernelNatPowWithFuel remaining;
      fun
        (base : Nat)
        (exponent : Nat) =>
        if Nat.beq exponent 0 then
          1
        else
          let halfExponent :=
            Nat.div exponent 2;
          let half :=
            smaller
              base
              halfExponent;
          let squared :=
            Nat.mul half half;
          if
              Nat.beq
                (Nat.mod exponent 2)
                0 then
            squared
          else
            Nat.mul
              base
              squared

def psKernelNatPow
    (base : Nat)
    (exponent : Nat) : Nat :=
  psKernelNatPowWithFuel
    (Nat.succ exponent)
    base
    exponent

inductive PsKernelNatBitwiseOp where
  | land
  | lor
  | xor

def psKernelNatBitResult
    (op : PsKernelNatBitwiseOp)
    (left : Nat)
    (right : Nat) : Nat :=
  match op with
  | PsKernelNatBitwiseOp.land =>
      if Nat.beq left 1 then
        if Nat.beq right 1 then
          1
        else
          0
      else
        0
  | PsKernelNatBitwiseOp.lor =>
      if Nat.beq left 1 then
        1
      else if Nat.beq right 1 then
        1
      else
        0
  | PsKernelNatBitwiseOp.xor =>
      if Nat.beq left right then
        0
      else
        1

def psKernelNatBitwiseWithFuel
    (fuel : Nat) :
    PsKernelNatBitwiseOp ->
    Nat ->
    Nat ->
    Nat :=
  match fuel with
  | Nat.zero =>
      fun
        (_op : PsKernelNatBitwiseOp)
        (_left : Nat)
        (_right : Nat) =>
        0
  | Nat.succ remaining =>
      let smaller :
          PsKernelNatBitwiseOp ->
          Nat ->
          Nat ->
          Nat :=
        psKernelNatBitwiseWithFuel remaining;
      fun
        (op : PsKernelNatBitwiseOp)
        (left : Nat)
        (right : Nat) =>
        if Nat.beq left 0 then
          if Nat.beq right 0 then
            0
          else
            let low :=
              psKernelNatBitResult
                op
                0
                (Nat.mod right 2);
            let rest :=
              smaller
                op
                0
                (Nat.div right 2);
            Nat.add
              low
              (Nat.mul 2 rest)
        else
          let low :=
            psKernelNatBitResult
              op
              (Nat.mod left 2)
              (Nat.mod right 2);
          let rest :=
            smaller
              op
              (Nat.div left 2)
              (Nat.div right 2);
          Nat.add
            low
            (Nat.mul 2 rest)

def psKernelNatBitwise
    (op : PsKernelNatBitwiseOp)
    (left : Nat)
    (right : Nat) : Nat :=
  psKernelNatBitwiseWithFuel
    (Nat.succ
      (Nat.add left right))
    op
    left
    right

def psKernelNatShiftRightWithFuel
    (fuel : Nat) :
    Nat -> Nat -> Nat :=
  match fuel with
  | Nat.zero =>
      fun
        (value : Nat)
        (_count : Nat) =>
        value
  | Nat.succ remaining =>
      let smaller :
          Nat -> Nat -> Nat :=
        psKernelNatShiftRightWithFuel remaining;
      fun
        (value : Nat)
        (count : Nat) =>
        if Nat.beq count 0 then
          value
        else if Nat.beq value 0 then
          0
        else
          smaller
            (Nat.div value 2)
            (Nat.sub count 1)

def psKernelNatShiftRight
    (value : Nat)
    (count : Nat) : Nat :=
  psKernelNatShiftRightWithFuel
    (Nat.succ value)
    value
    count

def psKernelNatShiftLeft
    (value : Nat)
    (count : Nat) : Nat :=
  Nat.mul
    value
    (psKernelNatPow 2 count)

def psKernelReduceNatBinary
    (maxNatSize : Nat)
    (op : PsKernelName)
    (left : Nat)
    (right : Nat) :
    Except String (Option PsKernelExpr) :=
  if psKernelNameEq op psKernelNatAddName then
    let result :=
      Nat.add left right;
    match
        psKernelCheckNatSize
          maxNatSize
          result with
    | Except.error error =>
        Except.error error
    | Except.ok _ =>
        Except.ok
          (Option.some
            (PsKernelExpr.lit
              (PsKernelLiteral.nat result)))
  else if psKernelNameEq op psKernelNatSubName then
    let result :=
      Nat.sub left right;
    match
        psKernelCheckNatSize
          maxNatSize
          result with
    | Except.error error =>
        Except.error error
    | Except.ok _ =>
        Except.ok
          (Option.some
            (PsKernelExpr.lit
              (PsKernelLiteral.nat result)))
  else if psKernelNameEq op psKernelNatMulName then
    let result :=
      Nat.mul left right;
    match
        psKernelCheckNatSize
          maxNatSize
          result with
    | Except.error error =>
        Except.error error
    | Except.ok _ =>
        Except.ok
          (Option.some
            (PsKernelExpr.lit
              (PsKernelLiteral.nat result)))
  else if psKernelNameEq op psKernelNatPowName then
    match
        psKernelCheckCountArg
          "Nat.pow"
          right with
    | Except.error error =>
        Except.error error
    | Except.ok _ =>
        if psKernelNatGt left 1 then
          if Nat.beq right 0 then
            Except.ok
              (Option.some
                (PsKernelExpr.lit
                  (PsKernelLiteral.nat 1)))
          else
            let rightBytes :=
              Nat.div
                maxNatSize
                right;
            if
                psKernelNatGt
                  (psKernelNatSizeInBytes left)
                  rightBytes then
              Except.error
                "the kernel refused to evaluate Nat.pow because the result would exceed the maximum numeral size"
            else
              Except.ok
                (Option.some
                  (PsKernelExpr.lit
                    (PsKernelLiteral.nat
                      (psKernelNatPow
                        left
                        right))))
        else
          Except.ok
            (Option.some
              (PsKernelExpr.lit
                (PsKernelLiteral.nat
                  (psKernelNatPow
                    left
                    right))))
  else if psKernelNameEq op psKernelNatGcdName then
    Except.ok
      (Option.some
        (PsKernelExpr.lit
          (PsKernelLiteral.nat
            (psKernelNatGcd left right))))
  else if psKernelNameEq op psKernelNatModName then
    let result :=
      if Nat.beq right 0 then
        left
      else
        Nat.mod left right;
    Except.ok
      (Option.some
        (PsKernelExpr.lit
          (PsKernelLiteral.nat result)))
  else if psKernelNameEq op psKernelNatDivName then
    let result :=
      if Nat.beq right 0 then
        0
      else
        Nat.div left right;
    Except.ok
      (Option.some
        (PsKernelExpr.lit
          (PsKernelLiteral.nat result)))
  else if psKernelNameEq op psKernelNatBeqName then
    Except.ok
      (Option.some
        (psKernelBoolExpr
          (Nat.beq left right)))
  else if psKernelNameEq op psKernelNatBleName then
    Except.ok
      (Option.some
        (psKernelBoolExpr
          (Nat.ble left right)))
  else if psKernelNameEq op psKernelNatLandName then
    Except.ok
      (Option.some
        (PsKernelExpr.lit
          (PsKernelLiteral.nat
            (psKernelNatBitwise
              PsKernelNatBitwiseOp.land
              left
              right))))
  else if psKernelNameEq op psKernelNatLorName then
    Except.ok
      (Option.some
        (PsKernelExpr.lit
          (PsKernelLiteral.nat
            (psKernelNatBitwise
              PsKernelNatBitwiseOp.lor
              left
              right))))
  else if psKernelNameEq op psKernelNatXorName then
    Except.ok
      (Option.some
        (PsKernelExpr.lit
          (PsKernelLiteral.nat
            (psKernelNatBitwise
              PsKernelNatBitwiseOp.xor
              left
              right))))
  else if psKernelNameEq op psKernelNatShiftLeftName then
    if Nat.beq left 0 then
      Except.ok
        (Option.some
          (PsKernelExpr.lit
            (PsKernelLiteral.nat 0)))
    else
      match
          psKernelCheckCountArg
            "Nat.shiftLeft"
            right with
      | Except.error error =>
          Except.error error
      | Except.ok _ =>
          let estimated :=
            Nat.add
              (Nat.add
                (psKernelNatSizeInBytes left)
                (Nat.div right 8))
              1;
          if
              psKernelNatGt
                estimated
                maxNatSize then
            Except.error
              "the kernel refused a Nat numeral because its size exceeds the maximum"
          else
            Except.ok
              (Option.some
                (PsKernelExpr.lit
                  (PsKernelLiteral.nat
                    (psKernelNatShiftLeft
                      left
                      right))))
  else if psKernelNameEq op psKernelNatShiftRightName then
    Except.ok
      (Option.some
        (PsKernelExpr.lit
          (PsKernelLiteral.nat
            (psKernelNatShiftRight
              left
              right))))
  else
    Except.ok Option.none
