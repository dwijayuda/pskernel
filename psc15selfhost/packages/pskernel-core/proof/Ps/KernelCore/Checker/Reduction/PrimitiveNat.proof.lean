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
  · simp [psKernelReduceNatBinary, hAdd]
    rw [hSize]
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
  · simp [
      psKernelReduceNatBinary,
      hNotAdd,
      hSub
    ]
    rw [hSize]
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
  · simp [
      psKernelReduceNatBinary,
      hNotAdd,
      hNotSub,
      hMul
    ]
    rw [hSize]
  · exact PsKernelReductionStep.natMul op left right hMul
