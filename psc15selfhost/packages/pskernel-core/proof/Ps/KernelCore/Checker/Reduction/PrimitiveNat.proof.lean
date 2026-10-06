import Ps.KernelCore.Checker.Reduction.PrimitiveNat
import Ps.KernelCore.Metatheory.Judgments

theorem psKernelNatPowWithFuel_zero
    (base exponent : Nat) :
    psKernelNatPowWithFuel 0 base exponent = 1 := by
  rfl

theorem psKernelNatBitwiseWithFuel_zero
    (op : PsKernelNatBitwiseOp)
    (left right : Nat) :
    psKernelNatBitwiseWithFuel 0 op left right = 0 := by
  rfl

theorem psKernelNatShiftRightWithFuel_zero
    (value count : Nat) :
    psKernelNatShiftRightWithFuel 0 value count = value := by
  rfl

theorem psKernelNatShiftLeft_def
    (value count : Nat) :
    psKernelNatShiftLeft value count =
      Nat.mul value (psKernelNatPow 2 count) := by
  rfl


theorem psKernelReduceNatBinary_add_refines
    (environment : PsKernelEnvironment)
    (localContext : PsKernelLocalContext)
    (maxNatSize left right : Nat)
    (op : PsKernelName)
    (hAdd :
      psKernelNameEq op psKernelNatAddName = true)
    (hSize :
      psKernelCheckNatSize
          maxNatSize
          (Nat.add left right) =
        Except.ok Unit.unit) :
    psKernelReduceNatBinary
        maxNatSize op left right =
      Except.ok
        (Option.some
          (PsKernelExpr.lit
            (PsKernelLiteral.nat
              (Nat.add left right)))) ∧
    PsKernelReductionStep
      environment
      localContext
      (PsKernelExpr.app
        (PsKernelExpr.app
          (PsKernelExpr.const op List.nil)
          (PsKernelExpr.lit (PsKernelLiteral.nat left)))
        (PsKernelExpr.lit (PsKernelLiteral.nat right)))
      (PsKernelExpr.lit
        (PsKernelLiteral.nat (Nat.add left right))) := by
  constructor
  · cases hCheck :
        psKernelCheckNatSize
          maxNatSize
          (left + right) with
    | error error =>
        simp [hCheck] at hSize
    | ok checked =>
        cases checked
        simp [
          psKernelReduceNatBinary,
          hAdd,
          hCheck
        ]
  · exact PsKernelReductionStep.natAdd op left right hAdd

theorem psKernelReduceNatBinary_sub_refines
    (environment : PsKernelEnvironment)
    (localContext : PsKernelLocalContext)
    (maxNatSize left right : Nat)
    (op : PsKernelName)
    (hNotAdd :
      psKernelNameEq op psKernelNatAddName = false)
    (hSub :
      psKernelNameEq op psKernelNatSubName = true)
    (hSize :
      psKernelCheckNatSize
          maxNatSize
          (Nat.sub left right) =
        Except.ok Unit.unit) :
    psKernelReduceNatBinary
        maxNatSize op left right =
      Except.ok
        (Option.some
          (PsKernelExpr.lit
            (PsKernelLiteral.nat
              (Nat.sub left right)))) ∧
    PsKernelReductionStep
      environment
      localContext
      (PsKernelExpr.app
        (PsKernelExpr.app
          (PsKernelExpr.const op List.nil)
          (PsKernelExpr.lit (PsKernelLiteral.nat left)))
        (PsKernelExpr.lit (PsKernelLiteral.nat right)))
      (PsKernelExpr.lit
        (PsKernelLiteral.nat (Nat.sub left right))) := by
  constructor
  · cases hCheck :
        psKernelCheckNatSize
          maxNatSize
          (left - right) with
    | error error =>
        simp [hCheck] at hSize
    | ok checked =>
        cases checked
        simp [
          psKernelReduceNatBinary,
          hNotAdd,
          hSub,
          hCheck
        ]
  · exact PsKernelReductionStep.natSub op left right hSub

theorem psKernelReduceNatBinary_mul_refines
    (environment : PsKernelEnvironment)
    (localContext : PsKernelLocalContext)
    (maxNatSize left right : Nat)
    (op : PsKernelName)
    (hNotAdd :
      psKernelNameEq op psKernelNatAddName = false)
    (hNotSub :
      psKernelNameEq op psKernelNatSubName = false)
    (hMul :
      psKernelNameEq op psKernelNatMulName = true)
    (hSize :
      psKernelCheckNatSize
          maxNatSize
          (Nat.mul left right) =
        Except.ok Unit.unit) :
    psKernelReduceNatBinary
        maxNatSize op left right =
      Except.ok
        (Option.some
          (PsKernelExpr.lit
            (PsKernelLiteral.nat
              (Nat.mul left right)))) ∧
    PsKernelReductionStep
      environment
      localContext
      (PsKernelExpr.app
        (PsKernelExpr.app
          (PsKernelExpr.const op List.nil)
          (PsKernelExpr.lit (PsKernelLiteral.nat left)))
        (PsKernelExpr.lit (PsKernelLiteral.nat right)))
      (PsKernelExpr.lit
        (PsKernelLiteral.nat (Nat.mul left right))) := by
  constructor
  · cases hCheck :
        psKernelCheckNatSize
          maxNatSize
          (left * right) with
    | error error =>
        simp [hCheck] at hSize
    | ok checked =>
        cases checked
        simp [
          psKernelReduceNatBinary,
          hNotAdd,
          hNotSub,
          hMul,
          hCheck
        ]
  · exact PsKernelReductionStep.natMul op left right hMul


theorem psKernelReduceNatBinary_mod_refines
    (environment : PsKernelEnvironment)
    (localContext : PsKernelLocalContext)
    (maxNatSize left right : Nat)
    (op : PsKernelName)
    (hNotAdd : psKernelNameEq op psKernelNatAddName = false)
    (hNotSub : psKernelNameEq op psKernelNatSubName = false)
    (hNotMul : psKernelNameEq op psKernelNatMulName = false)
    (hNotPow : psKernelNameEq op psKernelNatPowName = false)
    (hNotGcd : psKernelNameEq op psKernelNatGcdName = false)
    (hMod : psKernelNameEq op psKernelNatModName = true) :
    let result :=
      if Nat.beq right 0 then left else Nat.mod left right
    psKernelReduceNatBinary maxNatSize op left right =
      Except.ok
        (Option.some
          (PsKernelExpr.lit (PsKernelLiteral.nat result))) ∧
    PsKernelReductionStep
      environment localContext
      (PsKernelExpr.app
        (PsKernelExpr.app
          (PsKernelExpr.const op List.nil)
          (PsKernelExpr.lit (PsKernelLiteral.nat left)))
        (PsKernelExpr.lit (PsKernelLiteral.nat right)))
      (PsKernelExpr.lit (PsKernelLiteral.nat result)) := by
  dsimp
  constructor
  · simp [
      psKernelReduceNatBinary,
      hNotAdd, hNotSub, hNotMul, hNotPow, hNotGcd, hMod
    ]
  · exact PsKernelReductionStep.natMod op left right hMod

theorem psKernelReduceNatBinary_div_refines
    (environment : PsKernelEnvironment)
    (localContext : PsKernelLocalContext)
    (maxNatSize left right : Nat)
    (op : PsKernelName)
    (hNotAdd : psKernelNameEq op psKernelNatAddName = false)
    (hNotSub : psKernelNameEq op psKernelNatSubName = false)
    (hNotMul : psKernelNameEq op psKernelNatMulName = false)
    (hNotPow : psKernelNameEq op psKernelNatPowName = false)
    (hNotGcd : psKernelNameEq op psKernelNatGcdName = false)
    (hNotMod : psKernelNameEq op psKernelNatModName = false)
    (hDiv : psKernelNameEq op psKernelNatDivName = true) :
    let result :=
      if Nat.beq right 0 then 0 else Nat.div left right
    psKernelReduceNatBinary maxNatSize op left right =
      Except.ok
        (Option.some
          (PsKernelExpr.lit (PsKernelLiteral.nat result))) ∧
    PsKernelReductionStep
      environment localContext
      (PsKernelExpr.app
        (PsKernelExpr.app
          (PsKernelExpr.const op List.nil)
          (PsKernelExpr.lit (PsKernelLiteral.nat left)))
        (PsKernelExpr.lit (PsKernelLiteral.nat right)))
      (PsKernelExpr.lit (PsKernelLiteral.nat result)) := by
  dsimp
  constructor
  · simp [
      psKernelReduceNatBinary,
      hNotAdd, hNotSub, hNotMul, hNotPow, hNotGcd, hNotMod, hDiv
    ]
  · exact PsKernelReductionStep.natDiv op left right hDiv

theorem psKernelReduceNatBinary_beq_refines
    (environment : PsKernelEnvironment)
    (localContext : PsKernelLocalContext)
    (maxNatSize left right : Nat)
    (op : PsKernelName)
    (hNotAdd : psKernelNameEq op psKernelNatAddName = false)
    (hNotSub : psKernelNameEq op psKernelNatSubName = false)
    (hNotMul : psKernelNameEq op psKernelNatMulName = false)
    (hNotPow : psKernelNameEq op psKernelNatPowName = false)
    (hNotGcd : psKernelNameEq op psKernelNatGcdName = false)
    (hNotMod : psKernelNameEq op psKernelNatModName = false)
    (hNotDiv : psKernelNameEq op psKernelNatDivName = false)
    (hBeq : psKernelNameEq op psKernelNatBeqName = true) :
    psKernelReduceNatBinary maxNatSize op left right =
      Except.ok
        (Option.some (psKernelBoolExpr (Nat.beq left right))) ∧
    PsKernelReductionStep
      environment localContext
      (PsKernelExpr.app
        (PsKernelExpr.app
          (PsKernelExpr.const op List.nil)
          (PsKernelExpr.lit (PsKernelLiteral.nat left)))
        (PsKernelExpr.lit (PsKernelLiteral.nat right)))
      (psKernelBoolExpr (Nat.beq left right)) := by
  constructor
  · simp [
      psKernelReduceNatBinary,
      hNotAdd, hNotSub, hNotMul, hNotPow, hNotGcd,
      hNotMod, hNotDiv, hBeq
    ]
  · exact PsKernelReductionStep.natBeq op left right hBeq

theorem psKernelReduceNatBinary_ble_refines
    (environment : PsKernelEnvironment)
    (localContext : PsKernelLocalContext)
    (maxNatSize left right : Nat)
    (op : PsKernelName)
    (hNotAdd : psKernelNameEq op psKernelNatAddName = false)
    (hNotSub : psKernelNameEq op psKernelNatSubName = false)
    (hNotMul : psKernelNameEq op psKernelNatMulName = false)
    (hNotPow : psKernelNameEq op psKernelNatPowName = false)
    (hNotGcd : psKernelNameEq op psKernelNatGcdName = false)
    (hNotMod : psKernelNameEq op psKernelNatModName = false)
    (hNotDiv : psKernelNameEq op psKernelNatDivName = false)
    (hNotBeq : psKernelNameEq op psKernelNatBeqName = false)
    (hBle : psKernelNameEq op psKernelNatBleName = true) :
    psKernelReduceNatBinary maxNatSize op left right =
      Except.ok
        (Option.some (psKernelBoolExpr (Nat.ble left right))) ∧
    PsKernelReductionStep
      environment localContext
      (PsKernelExpr.app
        (PsKernelExpr.app
          (PsKernelExpr.const op List.nil)
          (PsKernelExpr.lit (PsKernelLiteral.nat left)))
        (PsKernelExpr.lit (PsKernelLiteral.nat right)))
      (psKernelBoolExpr (Nat.ble left right)) := by
  constructor
  · simp [
      psKernelReduceNatBinary,
      hNotAdd, hNotSub, hNotMul, hNotPow, hNotGcd,
      hNotMod, hNotDiv, hNotBeq, hBle
    ]
  · exact PsKernelReductionStep.natBle op left right hBle
