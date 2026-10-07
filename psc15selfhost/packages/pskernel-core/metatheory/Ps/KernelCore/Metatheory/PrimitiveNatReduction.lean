import Ps.KernelCore.Metatheory.CheckerContracts
import Ps.KernelCore.Metatheory.ReductionCongruence

/-
Semantic refinement for the primitive Nat reduction pipeline used by public
WHNF.  This module deliberately proves the executable primitive table rather
than postulating it as a soundness assumption.
-/

theorem psKernelReduceNatBinary_some_refines_step
    (environment : PsKernelEnvironment)
    (localContext : PsKernelLocalContext)
    (maxNatSize : Nat)
    (op : PsKernelName)
    (left right : Nat)
    (result : PsKernelExpr)
    (hSuccess :
      psKernelReduceNatBinary
          maxNatSize
          op
          left
          right =
        Except.ok (Option.some result)) :
    PsKernelReductionStep
      environment
      localContext
      (PsKernelExpr.app
        (PsKernelExpr.app
          (PsKernelExpr.const op List.nil)
          (PsKernelExpr.lit (PsKernelLiteral.nat left)))
        (PsKernelExpr.lit (PsKernelLiteral.nat right)))
      result := by
  cases hAdd :
      psKernelNameEq op psKernelNatAddName with
  | true =>
      cases hSize :
          psKernelCheckNatSize
            maxNatSize
            (Nat.add left right) with
      | error error =>
          simp_all [psKernelReduceNatBinary]
      | ok checked =>
          simp_all [psKernelReduceNatBinary]
          exact
            PsKernelReductionStep.natAdd
              op left right hAdd
  | false =>
      cases hSub :
          psKernelNameEq op psKernelNatSubName with
      | true =>
          cases hSize :
              psKernelCheckNatSize
                maxNatSize
                (Nat.sub left right) with
          | error error =>
              simp_all [psKernelReduceNatBinary]
          | ok checked =>
              simp_all [psKernelReduceNatBinary]
              exact
                PsKernelReductionStep.natSub
                  op left right hSub
      | false =>
          cases hMul :
              psKernelNameEq op psKernelNatMulName with
          | true =>
              cases hSize :
                  psKernelCheckNatSize
                    maxNatSize
                    (Nat.mul left right) with
              | error error =>
                  simp_all [psKernelReduceNatBinary]
              | ok checked =>
                  simp_all [psKernelReduceNatBinary]
                  exact
                    PsKernelReductionStep.natMul
                      op left right hMul
          | false =>
              cases hPow :
                  psKernelNameEq op psKernelNatPowName with
              | true =>
                  cases hCount :
                      psKernelCheckCountArg
                        "Nat.pow"
                        right with
                  | error error =>
                      simp_all [psKernelReduceNatBinary]
                  | ok checked =>
                      cases hGt :
                          psKernelNatGt left 1 with
                      | false =>
                          simp_all [psKernelReduceNatBinary]
                          exact
                            PsKernelReductionStep.natPow
                              op left right hPow
                      | true =>
                          cases hZero :
                              Nat.beq right 0 with
                          | true =>
                              simp_all [psKernelReduceNatBinary]
                              exact
                                PsKernelReductionStep.natPowZero
                                  op left right hPow hZero
                          | false =>
                              cases hTooBig :
                                  psKernelNatGt
                                    (psKernelNatSizeInBytes left)
                                    (Nat.div maxNatSize right) with
                              | true =>
                                  simp_all [psKernelReduceNatBinary]
                              | false =>
                                  simp_all [psKernelReduceNatBinary]
                                  exact
                                    PsKernelReductionStep.natPow
                                      op left right hPow
              | false =>
                  cases hGcd :
                      psKernelNameEq op psKernelNatGcdName with
                  | true =>
                      simp_all [psKernelReduceNatBinary]
                      exact
                        PsKernelReductionStep.natGcd
                          op left right hGcd
                  | false =>
                      cases hMod :
                          psKernelNameEq op psKernelNatModName with
                      | true =>
                          simp_all [psKernelReduceNatBinary]
                          exact
                            PsKernelReductionStep.natMod
                              op left right hMod
                      | false =>
                          cases hDiv :
                              psKernelNameEq op psKernelNatDivName with
                          | true =>
                              simp_all [psKernelReduceNatBinary]
                              exact
                                PsKernelReductionStep.natDiv
                                  op left right hDiv
                          | false =>
                              cases hBeq :
                                  psKernelNameEq op psKernelNatBeqName with
                              | true =>
                                  simp_all [psKernelReduceNatBinary]
                                  exact
                                    PsKernelReductionStep.natBeq
                                      op left right hBeq
                              | false =>
                                  cases hBle :
                                      psKernelNameEq op psKernelNatBleName with
                                  | true =>
                                      simp_all [psKernelReduceNatBinary]
                                      exact
                                        PsKernelReductionStep.natBle
                                          op left right hBle
                                  | false =>
                                      cases hLand :
                                          psKernelNameEq op psKernelNatLandName with
                                      | true =>
                                          simp_all [psKernelReduceNatBinary]
                                          exact
                                            PsKernelReductionStep.natLand
                                              op left right hLand
                                      | false =>
                                          cases hLor :
                                              psKernelNameEq op psKernelNatLorName with
                                          | true =>
                                              simp_all [psKernelReduceNatBinary]
                                              exact
                                                PsKernelReductionStep.natLor
                                                  op left right hLor
                                          | false =>
                                              cases hXor :
                                                  psKernelNameEq op psKernelNatXorName with
                                              | true =>
                                                  simp_all [psKernelReduceNatBinary]
                                                  exact
                                                    PsKernelReductionStep.natXor
                                                      op left right hXor
                                              | false =>
                                                  cases hShiftLeft :
                                                      psKernelNameEq op psKernelNatShiftLeftName with
                                                  | true =>
                                                      cases hLeftZero :
                                                          Nat.beq left 0 with
                                                      | true =>
                                                          simp_all [psKernelReduceNatBinary]
                                                          exact
                                                            PsKernelReductionStep.natShiftLeftZero
                                                              op left right hShiftLeft hLeftZero
                                                      | false =>
                                                          cases hCount :
                                                              psKernelCheckCountArg
                                                                "Nat.shiftLeft"
                                                                right with
                                                          | error error =>
                                                              simp_all [psKernelReduceNatBinary]
                                                          | ok checked =>
                                                              cases hTooBig :
                                                                  psKernelNatGt
                                                                    (Nat.add
                                                                      (Nat.add
                                                                        (psKernelNatSizeInBytes left)
                                                                        (Nat.div right 8))
                                                                      1)
                                                                    maxNatSize with
                                                              | true =>
                                                                  simp_all [psKernelReduceNatBinary]
                                                              | false =>
                                                                  simp_all [psKernelReduceNatBinary]
                                                                  exact
                                                                    PsKernelReductionStep.natShiftLeft
                                                                      op left right hShiftLeft
                                                  | false =>
                                                      cases hShiftRight :
                                                          psKernelNameEq op psKernelNatShiftRightName with
                                                      | true =>
                                                          simp_all [psKernelReduceNatBinary]
                                                          exact
                                                            PsKernelReductionStep.natShiftRight
                                                              op left right hShiftRight
                                                      | false =>
                                                          simp_all [psKernelReduceNatBinary]


theorem psKernelReduceNatBinary_some_refines
    (environment : PsKernelEnvironment)
    (localContext : PsKernelLocalContext)
    (maxNatSize : Nat)
    (op : PsKernelName)
    (left right : Nat)
    (result : PsKernelExpr)
    (hSuccess :
      psKernelReduceNatBinary
          maxNatSize
          op
          left
          right =
        Except.ok (Option.some result)) :
    PsKernelReductionClosure
      environment
      localContext
      (PsKernelExpr.app
        (PsKernelExpr.app
          (PsKernelExpr.const op List.nil)
          (PsKernelExpr.lit (PsKernelLiteral.nat left)))
        (PsKernelExpr.lit (PsKernelLiteral.nat right)))
      result :=
  PsKernelReductionClosure.cons
    (PsKernelExpr.app
      (PsKernelExpr.app
        (PsKernelExpr.const op List.nil)
        (PsKernelExpr.lit (PsKernelLiteral.nat left)))
      (PsKernelExpr.lit (PsKernelLiteral.nat right)))
    result
    result
    (psKernelReduceNatBinary_some_refines_step
      environment
      localContext
      maxNatSize
      op
      left
      right
      result
      hSuccess)
    (PsKernelReductionClosure.refl result)
