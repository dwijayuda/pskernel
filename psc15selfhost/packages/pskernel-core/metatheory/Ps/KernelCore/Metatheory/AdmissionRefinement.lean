import Ps.KernelCore.Metatheory.Admission
import Ps.KernelCore.Environment.Operations

theorem psKernelEnvironmentAddUnchecked_refines_extension
    (environment : PsKernelEnvironment)
    (info : PsKernelConstantInfo) :
    PsKernelDeclarationExtension
      environment
      (psKernelEnvironmentAddUnchecked environment info)
      info := by
  unfold PsKernelDeclarationExtension
  unfold PsKernelEnvironmentExtendsOne
  unfold PsKernelEnvironmentExtendsBy
  simp [psKernelEnvironmentAddUnchecked]

theorem psKernelEnvironmentAdd_success_refines_extension
    (environment result : PsKernelEnvironment)
    (info : PsKernelConstantInfo)
    (hSuccess :
      psKernelEnvironmentAdd environment info = Except.ok result) :
    PsKernelDeclarationExtension environment result info := by
  cases hContains :
      psKernelEnvironmentContains
        environment
        (psKernelConstantInfoName info) with
  | true =>
      simp [psKernelEnvironmentAdd, hContains] at hSuccess
  | false =>
      cases hDuplicates :
          psKernelNameHasDuplicates
            (psKernelConstantInfoLevelParams info) with
      | true =>
          simp [psKernelEnvironmentAdd, hContains, hDuplicates] at hSuccess
      | false =>
          simp [psKernelEnvironmentAdd, hContains, hDuplicates] at hSuccess
          subst result
          exact psKernelEnvironmentAddUnchecked_refines_extension environment info
