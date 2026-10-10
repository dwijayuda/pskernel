import Ps.KernelCore.Metatheory.Judgments

/-
Independent projection-computation refinement.

The executable helper consults the accelerated environment index.  The semantic
reduction rule below is justified only after transporting that lookup back to
the authoritative declaration history through EnvironmentIndexRefines.
-/

theorem psKernelReduceProjCore_some_refines_reduction
    (context : PsKernelCheckerContext)
    (typeName : PsKernelName)
    (index : Nat)
    (structValue result : PsKernelExpr)
    (hIndexRefines :
      PsKernelEnvironmentIndexRefines context.environment)
    (hSuccess :
      psKernelReduceProjCore
          context
          typeName
          index
          structValue =
        Option.some result) :
    PsKernelReductionStep
      context.environment
      context.localContext
      (PsKernelExpr.proj typeName index structValue)
      result := by
  cases hBound :
      psKernelNatGt index psKernelLeanUInt32Max with
  | true =>
      simp [psKernelReduceProjCore, hBound] at hSuccess
  | false =>
      cases hFn : psKernelExprGetAppFn structValue with
      | const ctorName ctorLevels =>
          cases hFind :
              psKernelEnvironmentFind
                context.environment
                ctorName with
          | none =>
              simp [
                psKernelReduceProjCore,
                hBound,
                hFn,
                hFind
              ] at hSuccess
          | some info =>
              cases info with
              | ctorInfo ctorInfo =>
                  cases hInduct :
                      psKernelNameEq
                        ctorInfo.induct
                        typeName with
                  | false =>
                      simp [
                        psKernelReduceProjCore,
                        hBound,
                        hFn,
                        hFind,
                        hInduct
                      ] at hSuccess
                  | true =>
                      have hLookupSuccess :
                          psKernelExprListGet
                              (psKernelExprGetAppArgs structValue)
                              (Nat.add ctorInfo.numParams index) =
                            Option.some result := by
                        simpa [
                          psKernelReduceProjCore,
                          hBound,
                          hFn,
                          hFind,
                          hInduct
                        ] using hSuccess
                      cases hArg :
                          psKernelExprListGet
                            (psKernelExprGetAppArgs structValue)
                            (Nat.add ctorInfo.numParams index) with
                      | none =>
                          rw [hArg] at hLookupSuccess
                          cases hLookupSuccess
                      | some argument =>
                          have hResult :
                              argument = result := by
                            rw [hArg] at hLookupSuccess
                            simpa using hLookupSuccess
                          have hIndexed :
                              psKernelFindConstantInList
                                  ctorName
                                  (psKernelEnvironmentIndexFind
                                    context.environment.index
                                    ctorName) =
                                Option.some
                                  (PsKernelConstantInfo.ctorInfo ctorInfo) := by
                            simpa [psKernelEnvironmentFind] using hFind
                          have hAuthoritative :
                              psKernelFindConstantInList
                                  ctorName
                                  context.environment.constants =
                                Option.some
                                  (PsKernelConstantInfo.ctorInfo ctorInfo) := by
                            rw [← hIndexRefines ctorName]
                            exact hIndexed
                          subst result
                          exact
                            PsKernelReductionStep.projection
                              typeName
                              ctorName
                              ctorLevels
                              index
                              structValue
                              argument
                              ctorInfo
                              hBound
                              hFn
                              hAuthoritative
                              hInduct
                              hArg
              | axiomInfo info =>
                  simp [psKernelReduceProjCore, hBound, hFn, hFind] at hSuccess
              | defnInfo info =>
                  simp [psKernelReduceProjCore, hBound, hFn, hFind] at hSuccess
              | thmInfo info =>
                  simp [psKernelReduceProjCore, hBound, hFn, hFind] at hSuccess
              | opaqueInfo info =>
                  simp [psKernelReduceProjCore, hBound, hFn, hFind] at hSuccess
              | inductInfo info =>
                  simp [psKernelReduceProjCore, hBound, hFn, hFind] at hSuccess
              | recInfo info =>
                  simp [psKernelReduceProjCore, hBound, hFn, hFind] at hSuccess
              | quotInfo info =>
                  simp [psKernelReduceProjCore, hBound, hFn, hFind] at hSuccess
      | _ =>
          simp [
            psKernelReduceProjCore,
            hBound,
            hFn
          ] at hSuccess


theorem psKernelReduceProjCore_some_refines_closure
    (context : PsKernelCheckerContext)
    (typeName : PsKernelName)
    (index : Nat)
    (structValue result : PsKernelExpr)
    (hIndexRefines :
      PsKernelEnvironmentIndexRefines context.environment)
    (hSuccess :
      psKernelReduceProjCore
          context
          typeName
          index
          structValue =
        Option.some result) :
    PsKernelReductionClosure
      context.environment
      context.localContext
      (PsKernelExpr.proj typeName index structValue)
      result :=
  PsKernelReductionClosure.cons
    (PsKernelExpr.proj typeName index structValue)
    result
    result
    (psKernelReduceProjCore_some_refines_reduction
      context
      typeName
      index
      structValue
      result
      hIndexRefines
      hSuccess)
    (PsKernelReductionClosure.refl result)
