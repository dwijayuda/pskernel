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


/-
Admission publication is not merely list insertion.  When the input
environment index refines the authoritative declaration list, success also
certifies that the added name was previously absent from that list and that
its universe-parameter declaration has no duplicates.
-/
theorem psKernelEnvironmentAdd_success_refines_validated_extension
    (environment result : PsKernelEnvironment)
    (info : PsKernelConstantInfo)
    (hIndex : PsKernelEnvironmentIndexRefines environment)
    (hSuccess :
      psKernelEnvironmentAdd environment info = Except.ok result) :
    PsKernelDeclarationExtension environment result info ∧
      psKernelFindConstantInList
          (psKernelConstantInfoName info)
          environment.constants =
        Option.none ∧
      psKernelNameHasDuplicates
          (psKernelConstantInfoLevelParams info) = false := by
  let name := psKernelConstantInfoName info
  have hExtension :=
    psKernelEnvironmentAdd_success_refines_extension
      environment result info hSuccess
  cases hContains :
      psKernelEnvironmentContains environment name with
  | true =>
      simp [psKernelEnvironmentAdd, name, hContains] at hSuccess
  | false =>
      have hIndexedNone :
          psKernelEnvironmentFind environment name = Option.none := by
        unfold psKernelEnvironmentContains at hContains
        cases hLookup :
            psKernelEnvironmentFind environment name with
        | none =>
            exact hLookup
        | some declaration =>
            simp [hLookup] at hContains
      have hCanonicalNone :
          psKernelFindConstantInList
              name environment.constants = Option.none := by
        calc
          psKernelFindConstantInList name environment.constants =
              psKernelFindConstantInList
                name
                (psKernelEnvironmentIndexFind
                  environment.index name) :=
            (hIndex name).symm
          _ = Option.none := by
            simpa [psKernelEnvironmentFind] using hIndexedNone
      cases hDuplicates :
          psKernelNameHasDuplicates
            (psKernelConstantInfoLevelParams info) with
      | true =>
          simp [
            psKernelEnvironmentAdd, name,
            hContains, hDuplicates
          ] at hSuccess
      | false =>
          exact ⟨hExtension, hCanonicalNone, hDuplicates⟩
