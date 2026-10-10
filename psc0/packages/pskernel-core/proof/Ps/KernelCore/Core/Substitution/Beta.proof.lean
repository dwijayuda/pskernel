import Ps.KernelCore.Core.Substitution.Beta
import Ps.KernelCore.Metatheory.Judgments

theorem psKernelExprApplyArgsCheap_nil
    (fn : PsKernelExpr) :
    psKernelExprApplyArgsCheap fn List.nil = fn := by
  rfl

theorem psKernelExprApplyArgsCheap_cons
    (fn arg : PsKernelExpr)
    (rest : List PsKernelExpr) :
    psKernelExprApplyArgsCheap fn (List.cons arg rest) =
      psKernelExprApplyArgsCheap (PsKernelExpr.app fn arg) rest := by
  rfl

theorem psKernelExprConsumeLambdaSpineWithFuel_zero
    (fn : PsKernelExpr)
    (args : List PsKernelExpr)
    (count : Nat) :
    psKernelExprConsumeLambdaSpineWithFuel 0 fn args count =
      Prod.mk fn count := by
  rfl

theorem psKernelExprCheapBetaReduce_bvar
    (index : Nat) :
    psKernelExprCheapBetaReduce (PsKernelExpr.bvar index) =
      PsKernelExpr.bvar index := by
  rfl

theorem psKernelExprCheapBetaReduce_const
    (name : PsKernelName)
    (levels : List PsKernelLevel) :
    psKernelExprCheapBetaReduce (PsKernelExpr.const name levels) =
      PsKernelExpr.const name levels := by
  rfl

theorem psKernelExprCheapBetaReduce_identity_lambda
    (name : PsKernelName)
    (level : PsKernelLevel)
    (binderInfo : PsKernelBinderInfo)
    (arg : PsKernelExpr) :
    psKernelExprCheapBetaReduce
        (PsKernelExpr.app
          (PsKernelExpr.lam
            name
            (PsKernelExpr.sort level)
            (PsKernelExpr.bvar 0)
            binderInfo)
          arg) =
      arg := by
  rfl

theorem psKernelExprCheapBetaReduce_closed_const_body
    (name constName : PsKernelName)
    (level : PsKernelLevel)
    (levels : List PsKernelLevel)
    (binderInfo : PsKernelBinderInfo)
    (arg : PsKernelExpr) :
    psKernelExprCheapBetaReduce
        (PsKernelExpr.app
          (PsKernelExpr.lam
            name
            (PsKernelExpr.sort level)
            (PsKernelExpr.const constName levels)
            binderInfo)
          arg) =
      PsKernelExpr.const constName levels := by
  rfl


theorem psKernelExprConsumeLambdaSpine_single
    (name : PsKernelName)
    (type body arg : PsKernelExpr)
    (binderInfo : PsKernelBinderInfo) :
    psKernelExprConsumeLambdaSpine
        (PsKernelExpr.lam name type body binderInfo)
        (List.cons arg List.nil)
        0 =
      Prod.mk body 1 := by
  cases body <;> rfl

theorem psKernelExprCheapBetaReduce_closed_body
    (name : PsKernelName)
    (type body arg : PsKernelExpr)
    (binderInfo : PsKernelBinderInfo)
    (h : psKernelExprHasLooseBVar body = false) :
    psKernelExprCheapBetaReduce
        (PsKernelExpr.app
          (PsKernelExpr.lam name type body binderInfo)
          arg) =
      body := by
  simp [
    psKernelExprCheapBetaReduce,
    psKernelExprGetAppFn,
    psKernelExprGetAppArgs,
    psKernelExprGetAppArgsWorker,
    psKernelExprConsumeLambdaSpine_single,
    psKernelExprListDrop,
    psKernelExprApplyArgsCheap,
    psKernelExprApplyArgsCheapWorker,
    h
  ]


theorem psKernelExprCheapBetaReduce_single_refines_beta
    (environment : PsKernelEnvironment)
    (localContext : PsKernelLocalContext)
    (name : PsKernelName)
    (type body arg : PsKernelExpr)
    (binderInfo : PsKernelBinderInfo) :
    let original :=
      PsKernelExpr.app
        (PsKernelExpr.lam name type body binderInfo)
        arg
    let result :=
      psKernelExprCheapBetaReduce original
    result = original ∨
      PsKernelReductionStep
        environment
        localContext
        original
        result := by
  dsimp
  cases hLoose : psKernelExprHasLooseBVar body with
  | false =>
      right
      have hCheap :
          psKernelExprCheapBetaReduce
              (PsKernelExpr.app
                (PsKernelExpr.lam name type body binderInfo)
                arg) =
            body :=
        psKernelExprCheapBetaReduce_closed_body
          name type body arg binderInfo hLoose
      have hInst :
          psKernelExprInstantiate1 body arg = body := by
        simp [psKernelExprInstantiate1, hLoose]
      have hBeta :
          PsKernelReductionStep
            environment
            localContext
            (PsKernelExpr.app
              (PsKernelExpr.lam name type body binderInfo)
              arg)
            (psKernelExprInstantiate1 body arg) :=
        PsKernelReductionStep.beta
          name type body arg binderInfo
      simpa [hCheap, hInst] using hBeta
  | true =>
      cases body with
      | bvar index =>
          cases index with
          | zero =>
              right
              have hCheap :
                  psKernelExprCheapBetaReduce
                      (PsKernelExpr.app
                        (PsKernelExpr.lam
                          name type
                          (PsKernelExpr.bvar 0)
                          binderInfo)
                        arg) =
                    arg := by
                rfl
              have hInst :
                  psKernelExprInstantiate1
                      (PsKernelExpr.bvar 0)
                      arg =
                    arg := by
                change (psKernelExprLiftLooseBVarsChanged arg 0 0).1 = arg
                rw [PsKernelSharing.lift_zero]
              have hBeta :
                  PsKernelReductionStep
                    environment
                    localContext
                    (PsKernelExpr.app
                      (PsKernelExpr.lam
                        name type
                        (PsKernelExpr.bvar 0)
                        binderInfo)
                      arg)
                    (psKernelExprInstantiate1
                      (PsKernelExpr.bvar 0)
                      arg) :=
                PsKernelReductionStep.beta
                  name type
                  (PsKernelExpr.bvar 0)
                  arg binderInfo
              simpa [hCheap, hInst] using hBeta
          | succ index =>
              left
              simp [
                psKernelExprCheapBetaReduce,
                psKernelExprGetAppFn,
                psKernelExprGetAppArgs,
                psKernelExprGetAppArgsWorker,
                psKernelExprConsumeLambdaSpine_single,
                hLoose,
                psKernelNatLt
              ]
      | fvar fvarName =>
          simp [psKernelExprHasLooseBVar, psKernelExprHasLooseAt] at hLoose
      | mvar mvarName =>
          simp [psKernelExprHasLooseBVar, psKernelExprHasLooseAt] at hLoose
      | sort level =>
          simp [psKernelExprHasLooseBVar, psKernelExprHasLooseAt] at hLoose
      | const constName levels =>
          simp [psKernelExprHasLooseBVar, psKernelExprHasLooseAt] at hLoose
      | app fn argBody =>
          left
          simp [
            psKernelExprCheapBetaReduce,
            psKernelExprGetAppFn,
            psKernelExprGetAppArgs,
            psKernelExprGetAppArgsWorker,
            psKernelExprConsumeLambdaSpine_single,
            hLoose
          ]
      | lam bodyName bodyType bodyBody bodyInfo =>
          left
          simp [
            psKernelExprCheapBetaReduce,
            psKernelExprGetAppFn,
            psKernelExprGetAppArgs,
            psKernelExprGetAppArgsWorker,
            psKernelExprConsumeLambdaSpine_single,
            hLoose
          ]
      | forallE bodyName bodyType bodyBody bodyInfo =>
          left
          simp [
            psKernelExprCheapBetaReduce,
            psKernelExprGetAppFn,
            psKernelExprGetAppArgs,
            psKernelExprGetAppArgsWorker,
            psKernelExprConsumeLambdaSpine_single,
            hLoose
          ]
      | letE bodyName bodyType bodyValue bodyBody nondep =>
          left
          simp [
            psKernelExprCheapBetaReduce,
            psKernelExprGetAppFn,
            psKernelExprGetAppArgs,
            psKernelExprGetAppArgsWorker,
            psKernelExprConsumeLambdaSpine_single,
            hLoose
          ]
      | lit literal =>
          simp [psKernelExprHasLooseBVar, psKernelExprHasLooseAt] at hLoose
      | mdata metadata bodyBody =>
          left
          simp [
            psKernelExprCheapBetaReduce,
            psKernelExprGetAppFn,
            psKernelExprGetAppArgs,
            psKernelExprGetAppArgsWorker,
            psKernelExprConsumeLambdaSpine_single,
            hLoose
          ]
      | proj typeName index bodyBody =>
          left
          simp [
            psKernelExprCheapBetaReduce,
            psKernelExprGetAppFn,
            psKernelExprGetAppArgs,
            psKernelExprGetAppArgsWorker,
            psKernelExprConsumeLambdaSpine_single,
            hLoose
          ]
