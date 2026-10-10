import Ps.KernelCore.Metatheory.EnvironmentIndexCanonical
import Ps.KernelCore.Metatheory.AdmissionRefinement
import Ps.KernelCore.Admission.Declaration.Admission

/-
Preservation of the authoritative environment/index invariant across all
declaration insertion operations.  The underlying index-insert proof checks
every public root representation, including hash collisions and root buckets;
the proof does not postulate that an index built by callers has a certain shape.
-/

theorem psKernelEnvironmentAddUnchecked_index_refines
    (environment : PsKernelEnvironment)
    (info : PsKernelConstantInfo)
    (hIndex : PsKernelEnvironmentIndexRefines environment) :
    PsKernelEnvironmentIndexRefines
      (psKernelEnvironmentAddUnchecked environment info) := by
  intro query
  change
    psKernelFindConstantInList
        query
        (psKernelEnvironmentIndexFind
          (psKernelEnvironmentIndexInsert environment.index info)
          query) =
      psKernelFindConstantInList
        query
        (List.cons info environment.constants)
  exact
    psKernelEnvironmentIndexInsert_refines_authoritative
      environment.index
      environment.constants
      info
      hIndex
      query


theorem psKernelEnvironmentAdd_success_index_refines
    (environment result : PsKernelEnvironment)
    (info : PsKernelConstantInfo)
    (hIndex : PsKernelEnvironmentIndexRefines environment)
    (hRun :
      psKernelEnvironmentAdd environment info =
        Except.ok result) :
    PsKernelEnvironmentIndexRefines result := by
  cases hExisting :
      psKernelEnvironmentContains
        environment
        (psKernelConstantInfoName info) with
  | true =>
      simp [psKernelEnvironmentAdd, hExisting] at hRun
  | false =>
      cases hDuplicate :
          psKernelNameHasDuplicates
            (psKernelConstantInfoLevelParams info) with
      | true =>
          simp [psKernelEnvironmentAdd, hExisting, hDuplicate] at hRun
      | false =>
          have hResult :
              psKernelEnvironmentAddUnchecked environment info =
                result := by
            simpa [psKernelEnvironmentAdd, hExisting, hDuplicate]
              using hRun
          rw [← hResult]
          exact
            psKernelEnvironmentAddUnchecked_index_refines
              environment info hIndex


theorem psKernelMutualWorkEnvironment_index_refines
    (values : List PsKernelDefinitionInfo)
    (environment : PsKernelEnvironment)
    (hIndex : PsKernelEnvironmentIndexRefines environment) :
    PsKernelEnvironmentIndexRefines
      (psKernelMutualWorkEnvironment values environment) := by
  induction values generalizing environment with
  | nil =>
      simpa [psKernelMutualWorkEnvironment] using hIndex
  | cons value rest ih =>
      have hNext :
          PsKernelEnvironmentIndexRefines
            (psKernelEnvironmentAddUnchecked
              environment
              (PsKernelConstantInfo.defnInfo value)) :=
        psKernelEnvironmentAddUnchecked_index_refines
          environment
          (PsKernelConstantInfo.defnInfo value)
          hIndex
      simpa [psKernelMutualWorkEnvironment] using
        (ih
          (psKernelEnvironmentAddUnchecked
            environment
            (PsKernelConstantInfo.defnInfo value))
          hNext)
