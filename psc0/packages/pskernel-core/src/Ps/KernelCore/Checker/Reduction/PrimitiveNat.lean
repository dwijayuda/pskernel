import Ps.KernelCore.Checker.Reduction.PrimitiveData

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

/-- Match the official kernel's dispatch before evaluating any operands. -/
def psKernelNatBinarySupported (name : PsKernelName) : Bool :=
  if psKernelNameEq name psKernelNatAddName then true
  else if psKernelNameEq name psKernelNatSubName then true
  else if psKernelNameEq name psKernelNatMulName then true
  else if psKernelNameEq name psKernelNatPowName then true
  else if psKernelNameEq name psKernelNatGcdName then true
  else if psKernelNameEq name psKernelNatModName then true
  else if psKernelNameEq name psKernelNatDivName then true
  else if psKernelNameEq name psKernelNatBeqName then true
  else if psKernelNameEq name psKernelNatBleName then true
  else if psKernelNameEq name psKernelNatLandName then true
  else if psKernelNameEq name psKernelNatLorName then true
  else if psKernelNameEq name psKernelNatXorName then true
  else if psKernelNameEq name psKernelNatShiftLeftName then true
  else if psKernelNameEq name psKernelNatShiftRightName then true
  else false
