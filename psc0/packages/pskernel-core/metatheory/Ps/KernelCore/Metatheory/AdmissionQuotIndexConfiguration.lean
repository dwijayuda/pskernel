import Ps.KernelCore.Admission.Quot.Admission
import Ps.KernelCore.Metatheory.AdmissionIndexConfiguration

/-
Quot bootstrap installs four reserved declarations and then flips the
computation-initialized flag.  The index invariant must be preserved in each
inserted intermediate environment, not simply at the final API boundary.

Unlike constructor admission, this batch has a fixed four-entry history.
No new trust assumptions are introduced.
-/

theorem psKernelEnvironmentMarkQuotInitialized_index_refines
    (environment : PsKernelEnvironment)
    (hIndex : PsKernelEnvironmentIndexRefines environment) :
    PsKernelEnvironmentIndexRefines
      (psKernelEnvironmentMarkQuotInitialized environment) := by
  cases hFlag : environment.quotInitialized with
  | false =>
      simpa [
        psKernelEnvironmentMarkQuotInitialized,
        hFlag, PsKernelEnvironmentIndexRefines
      ] using hIndex
  | true =>
      simpa [
        psKernelEnvironmentMarkQuotInitialized,
        hFlag
      ] using hIndex


theorem psKernelAddQuot_success_index_refines
    (environment result : PsKernelEnvironment)
    (hIndex : PsKernelEnvironmentIndexRefines environment)
    (hRun :
      psKernelAddQuot environment = Except.ok result) :
    PsKernelEnvironmentIndexRefines result := by
  cases hInit : environment.quotInitialized with
  | true =>
      simp [psKernelAddQuot, hInit] at hRun
      subst result
      exact hIndex
  | false =>
      cases hEq : psKernelCheckEqForQuot environment with
      | error error =>
          simp [psKernelAddQuot, hInit, hEq] at hRun
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
                psKernelAddQuot, hInit, hEq, hReserved
              ] at hRun
          | ok reservedResult =>
              cases reservedResult
              simp [
                psKernelAddQuot, hInit, hEq, hReserved
              ] at hRun
              subst result
              apply psKernelEnvironmentMarkQuotInitialized_index_refines
              apply psKernelEnvironmentAddUnchecked_index_refines
              apply psKernelEnvironmentAddUnchecked_index_refines
              apply psKernelEnvironmentAddUnchecked_index_refines
              apply psKernelEnvironmentAddUnchecked_index_refines
              exact hIndex
