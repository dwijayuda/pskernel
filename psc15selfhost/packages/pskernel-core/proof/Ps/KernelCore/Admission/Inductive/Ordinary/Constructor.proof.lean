import Ps.KernelCore.Admission.Inductive.Ordinary.Constructor
import Ps.KernelCore.Metatheory.Inductive

theorem psKernelOpenBinderListAppend_eq_append
    (left right : List PsKernelOpenBinder) :
    psKernelOpenBinderListAppend left right = List.append left right := by
  induction left with
  | nil =>
      rfl
  | cons head tail ih =>
      simp [psKernelOpenBinderListAppend, ih]

theorem psKernelReverseRecursiveFieldsWorker_eq
    (values acc : List PsKernelSimpleRecursiveField) :
    psKernelReverseRecursiveFieldsWorker values acc =
      List.append (List.reverse values) acc := by
  induction values generalizing acc with
  | nil =>
      simp [psKernelReverseRecursiveFieldsWorker]
  | cons head tail ih =>
      simp [psKernelReverseRecursiveFieldsWorker, ih, List.append_assoc]

theorem psKernelOpenSimpleConstructorParamsWithFuel_zero
    (session : PsKernelCheckerSession)
    (params : List PsKernelOpenBinder)
    (type : PsKernelExpr) :
    psKernelOpenSimpleConstructorParamsWithFuel
        0 session params type =
      Except.error
        "simple inductive constructor parameter budget exhausted" := by
  rfl

theorem psKernelOpenSimpleConstructorParamsWithFuel_app_rejects
    (fuel : Nat)
    (session : PsKernelCheckerSession)
    (param : PsKernelOpenBinder)
    (rest : List PsKernelOpenBinder)
    (fn arg : PsKernelExpr) :
    psKernelOpenSimpleConstructorParamsWithFuel
        (Nat.succ fuel)
        session
        (List.cons param rest)
        (PsKernelExpr.app fn arg) =
      Except.error
        "simple inductive constructor has fewer parameters than the datatype" := by
  rfl

theorem psKernelOpenSimpleConstructorFieldsWithFuel_app_preserves_raw
    (fuel : Nat)
    (session : PsKernelCheckerSession)
    (target : PsKernelName)
    (levels : List PsKernelLevel)
    (params : List PsKernelOpenBinder)
    (numIndices : Nat)
    (resultLevel : PsKernelLevel)
    (fn arg : PsKernelExpr)
    (revFields : List PsKernelOpenBinder)
    (revRecursive : List PsKernelSimpleRecursiveField) :
    psKernelOpenSimpleConstructorFieldsWithFuel
        (Nat.succ fuel)
        session
        target
        levels
        params
        numIndices
        resultLevel
        (PsKernelExpr.app fn arg)
        revFields
        revRecursive =
      Except.ok
        (PsKernelOpenFieldsResult.mk
          session
          (psKernelReverseOpenBinders revFields)
          (psKernelReverseRecursiveFields revRecursive)
          (PsKernelExpr.app fn arg)) := by
  rfl

theorem psKernelOpenSimpleConstructorFieldsWithFuel_zero
    (session : PsKernelCheckerSession)
    (target : PsKernelName)
    (levels : List PsKernelLevel)
    (params : List PsKernelOpenBinder)
    (numIndices : Nat)
    (resultLevel : PsKernelLevel)
    (type : PsKernelExpr)
    (revFields : List PsKernelOpenBinder)
    (revRecursive : List PsKernelSimpleRecursiveField) :
    psKernelOpenSimpleConstructorFieldsWithFuel
        0 session target levels params numIndices resultLevel
        type revFields revRecursive =
      Except.error "simple inductive field budget exhausted" := by
  rfl


theorem psKernelSimpleInductiveAppIndices_success_refines
    (target : PsKernelName)
    (levels : List PsKernelLevel)
    (params : List PsKernelOpenBinder)
    (numIndices : Nat)
    (result : PsKernelExpr)
    (indices : List PsKernelExpr)
    (hSuccess :
      psKernelSimpleInductiveAppIndices
          target
          levels
          params
          numIndices
          result =
        Option.some indices) :
    PsKernelSimpleInductiveAppValid
      target
      levels
      params
      numIndices
      result
      indices := by
  cases hFn : psKernelExprGetAppFn result with
  | const resultName resultLevels =>
      cases hName :
          psKernelNameEq resultName target with
      | false =>
          simp [
            psKernelSimpleInductiveAppIndices,
            hFn,
            hName
          ] at hSuccess
      | true =>
          cases hLevels :
              psKernelLevelListEq
                resultLevels
                levels with
          | false =>
              simp [
                psKernelSimpleInductiveAppIndices,
                hFn,
                hName,
                hLevels
              ] at hSuccess
          | true =>
              cases hParams :
                  psKernelConsumeSimpleResultParams
                    params
                    (psKernelExprGetAppArgs result) with
              | none =>
                  simp [
                    psKernelSimpleInductiveAppIndices,
                    hFn,
                    hName,
                    hLevels,
                    hParams
                  ] at hSuccess
              | some actualIndices =>
                  cases hLength :
                      Nat.beq
                        (psKernelExprListLength actualIndices)
                        numIndices with
                  | false =>
                      simp [
                        psKernelSimpleInductiveAppIndices,
                        hFn,
                        hName,
                        hLevels,
                        hParams,
                        hLength
                      ] at hSuccess
                  | true =>
                      have hLengthEq :
                          psKernelExprListLength actualIndices =
                            numIndices := by
                        simpa using hLength
                      have hIndices :
                          actualIndices = indices := by
                        simpa [
                          psKernelSimpleInductiveAppIndices,
                          hFn,
                          hName,
                          hLevels,
                          hParams,
                          hLength
                        ] using hSuccess
                      subst indices
                      exact
                        ⟨
                          resultName,
                          resultLevels,
                          hFn,
                          hName,
                          hLevels,
                          hParams,
                          hLengthEq
                        ⟩
  | bvar index =>
      simp [psKernelSimpleInductiveAppIndices, hFn] at hSuccess
  | fvar name =>
      simp [psKernelSimpleInductiveAppIndices, hFn] at hSuccess
  | mvar name =>
      simp [psKernelSimpleInductiveAppIndices, hFn] at hSuccess
  | sort level =>
      simp [psKernelSimpleInductiveAppIndices, hFn] at hSuccess
  | app fn arg =>
      simp [psKernelSimpleInductiveAppIndices, hFn] at hSuccess
  | lam name type body binderInfo =>
      simp [psKernelSimpleInductiveAppIndices, hFn] at hSuccess
  | forallE name type body binderInfo =>
      simp [psKernelSimpleInductiveAppIndices, hFn] at hSuccess
  | letE name type value body nondep =>
      simp [psKernelSimpleInductiveAppIndices, hFn] at hSuccess
  | lit literal =>
      simp [psKernelSimpleInductiveAppIndices, hFn] at hSuccess
  | mdata metadata body =>
      simp [psKernelSimpleInductiveAppIndices, hFn] at hSuccess
  | proj typeName index body =>
      simp [psKernelSimpleInductiveAppIndices, hFn] at hSuccess

theorem psKernelValidateSimpleConstructorResult_success_refines
    (target : PsKernelName)
    (levels : List PsKernelLevel)
    (params : List PsKernelOpenBinder)
    (numIndices : Nat)
    (result : PsKernelExpr)
    (indices : List PsKernelExpr)
    (hSuccess :
      psKernelValidateSimpleConstructorResult
          target
          levels
          params
          numIndices
          result =
        Except.ok indices) :
    PsKernelSimpleConstructorResultValid
      target
      levels
      params
      numIndices
      result
      indices := by
  cases hIndices :
      psKernelSimpleInductiveAppIndices
        target
        levels
        params
        numIndices
        result with
  | none =>
      simp [
        psKernelValidateSimpleConstructorResult,
        hIndices
      ] at hSuccess
  | some actualIndices =>
      cases hRecursive :
          psKernelSimpleIndicesContainTarget
            target
            actualIndices with
      | true =>
          simp [
            psKernelValidateSimpleConstructorResult,
            hIndices,
            hRecursive
          ] at hSuccess
      | false =>
          have hEq :
              actualIndices = indices := by
            simpa [
              psKernelValidateSimpleConstructorResult,
              hIndices,
              hRecursive
            ] using hSuccess
          subst indices
          exact
            ⟨
              psKernelSimpleInductiveAppIndices_success_refines
                target
                levels
                params
                numIndices
                result
                actualIndices
                hIndices,
              hRecursive
            ⟩
