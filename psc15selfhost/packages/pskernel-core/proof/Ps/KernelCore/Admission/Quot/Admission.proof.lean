import Ps.KernelCore.Admission.Quot.Admission

theorem psKernelAddQuot_idempotent_when_initialized
    (environment : PsKernelEnvironment)
    (h : environment.quotInitialized = true) :
    psKernelAddQuot environment = Except.ok environment := by
  simp [psKernelAddQuot, h]

def psKernelQuotReservedNamesForProof : List PsKernelName :=
  List.cons
    psKernelQuotName
    (List.cons
      psKernelQuotMkName
      (List.cons
        psKernelQuotLiftName
        (List.cons
          psKernelQuotIndName
          List.nil)))

theorem psKernelAddQuot_propagates_eq_failure
    (environment : PsKernelEnvironment)
    (error : String)
    (hInit : environment.quotInitialized = false)
    (hEq :
      psKernelCheckEqForQuot environment =
        Except.error error) :
    psKernelAddQuot environment =
      Except.error error := by
  simp [psKernelAddQuot, hInit, hEq]

theorem psKernelAddQuot_propagates_reserved_failure
    (environment : PsKernelEnvironment)
    (error : String)
    (hInit : environment.quotInitialized = false)
    (hEq :
      psKernelCheckEqForQuot environment =
        Except.ok Unit.unit)
    (hReserved :
      psKernelCheckQuotReservedNames
          environment
          psKernelQuotReservedNamesForProof =
        Except.error error) :
    psKernelAddQuot environment =
      Except.error error := by
  have hReservedConcrete :
      psKernelCheckQuotReservedNames
          environment
          (List.cons
            psKernelQuotName
            (List.cons
              psKernelQuotMkName
              (List.cons
                psKernelQuotLiftName
                (List.cons
                  psKernelQuotIndName
                  List.nil)))) =
        Except.error error := by
    simpa [psKernelQuotReservedNamesForProof] using hReserved
  simp [
    psKernelAddQuot,
    hInit,
    hEq,
    hReservedConcrete
  ]

theorem psKernelAddQuot_success_postconditions
    (environment result : PsKernelEnvironment)
    (hInit : environment.quotInitialized = false)
    (hSuccess :
      psKernelAddQuot environment =
        Except.ok result) :
    result.quotInitialized = true ∧
    result.runtime = environment.runtime ∧
    psKernelConstantListLength result.constants =
      Nat.succ
        (Nat.succ
          (Nat.succ
            (Nat.succ
              (psKernelConstantListLength
                environment.constants)))) := by
  cases hEq : psKernelCheckEqForQuot environment with
  | error error =>
      simp [psKernelAddQuot, hInit, hEq] at hSuccess
  | ok eqResult =>
      cases eqResult
      cases hReserved :
          psKernelCheckQuotReservedNames
            environment
            (List.cons
              psKernelQuotName
              (List.cons
                psKernelQuotMkName
                (List.cons
                  psKernelQuotLiftName
                  (List.cons
                    psKernelQuotIndName
                    List.nil)))) with
      | error error =>
          simp [
            psKernelAddQuot,
            hInit,
            hEq,
            hReserved
          ] at hSuccess
      | ok reservedResult =>
          cases reservedResult
          simp [
            psKernelAddQuot,
            hInit,
            hEq,
            hReserved
          ] at hSuccess
          subst result
          simp [
            psKernelEnvironmentAddUnchecked,
            psKernelEnvironmentMarkQuotInitialized,
            psKernelConstantListLength
          ]
