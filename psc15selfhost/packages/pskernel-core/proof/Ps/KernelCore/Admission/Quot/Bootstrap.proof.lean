import Ps.KernelCore.Admission.Quot.Bootstrap
import Ps.KernelCore.Metatheory.Judgments

theorem psKernelCloseOpenBinders_nil
    (body : PsKernelExpr) :
    psKernelCloseOpenBinders List.nil body = body := by
  rfl

theorem psKernelCheckQuotReservedNames_nil
    (environment : PsKernelEnvironment) :
    psKernelCheckQuotReservedNames environment List.nil =
      Except.ok Unit.unit := by
  rfl


theorem psKernelCheckQuotReservedNames_cons_taken
    (environment : PsKernelEnvironment)
    (name : PsKernelName)
    (rest : List PsKernelName)
    (hTaken :
      psKernelEnvironmentContains environment name = true) :
    psKernelCheckQuotReservedNames
        environment
        (List.cons name rest) =
      Except.error
        "failed to initialize quot module, quotient name is already declared" := by
  simp [psKernelCheckQuotReservedNames, hTaken]

theorem psKernelCheckQuotReservedNames_cons_free
    (environment : PsKernelEnvironment)
    (name : PsKernelName)
    (rest : List PsKernelName)
    (hFree :
      psKernelEnvironmentContains environment name = false) :
    psKernelCheckQuotReservedNames
        environment
        (List.cons name rest) =
      psKernelCheckQuotReservedNames environment rest := by
  simp [psKernelCheckQuotReservedNames, hFree]


theorem psKernelCheckQuotReservedNames_success_authoritative_absent
    (environment : PsKernelEnvironment)
    (names : List PsKernelName)
    (hIndex :
      PsKernelEnvironmentIndexRefines environment)
    (hSuccess :
      psKernelCheckQuotReservedNames environment names =
        Except.ok Unit.unit) :
    ∀ name : PsKernelName,
      name ∈ names ->
      psKernelFindConstantInList
          name
          environment.constants =
        Option.none := by
  induction names with
  | nil =>
      intro name hMem
      simp at hMem
  | cons head tail ih =>
      cases hContains :
          psKernelEnvironmentContains environment head with
      | true =>
          simp [
            psKernelCheckQuotReservedNames,
            hContains
          ] at hSuccess
      | false =>
          have hTailSuccess :
              psKernelCheckQuotReservedNames
                  environment
                  tail =
                Except.ok Unit.unit := by
            simpa [
              psKernelCheckQuotReservedNames,
              hContains
            ] using hSuccess
          intro name hMem
          simp only [List.mem_cons] at hMem
          cases hMem with
          | inl hEq =>
              subst name
              cases hFind :
                  psKernelEnvironmentFind
                    environment
                    head with
              | none =>
                  unfold psKernelEnvironmentFind at hFind
                  calc
                    psKernelFindConstantInList
                        head
                        environment.constants =
                      psKernelFindConstantInList
                        head
                        (psKernelEnvironmentIndexFind
                          environment.index
                          head) := (hIndex head).symm
                    _ = Option.none := hFind
              | some info =>
                  have hTaken :
                      psKernelEnvironmentContains
                          environment
                          head =
                        true := by
                    simp [
                      psKernelEnvironmentContains,
                      hFind
                    ]
                  rw [hContains] at hTaken
                  contradiction
          | inr hTail =>
              exact ih hTailSuccess name hTail
