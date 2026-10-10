import Ps.KernelCore.Metatheory.CheckerContracts

/-
Configuration-aware refinement for the kernel-recognized Quot reductions.

The executable helper normalizes only the major using public WHNF, then
recognizes Quot.mk and eliminates Quot.lift / Quot.ind.  The semantic result is
recorded by independent PsKernelReductionClosure constructors rather than by
replaying the helper in the judgment.
-/

theorem psKernelReduceQuotWith_configuration_sound
    (publicWhnf :
      PsKernelCheckerContext ->
      PsKernelCheckerState ->
      PsKernelExpr ->
      Except String (Prod PsKernelExpr PsKernelCheckerState))
    (hWhnf :
      PsKernelWhnfConfigurationSound publicWhnf) :
    PsKernelOptionalReductionConfigurationSound
      (psKernelReduceQuotWith publicWhnf) := by
  intro
    context state nextState expr answer
    hConfig hSuccess
  cases hInitialized :
      context.environment.quotInitialized with
  | false =>
      simp [
        psKernelReduceQuotWith,
        hInitialized
      ] at hSuccess
      rcases hSuccess with ⟨rfl, rfl⟩
      exact ⟨hConfig, trivial⟩
  | true =>
      cases hHead :
          psKernelExprGetAppFn expr with
      | const fnName levels =>
          cases hLift :
              psKernelNameEq
                fnName
                psKernelQuotLiftName with
          | true =>
              let args :=
                psKernelExprGetAppArgs expr
              cases hShort :
                  Nat.ble
                    (psKernelExprListLength args)
                    5 with
              | true =>
                  simp [
                    psKernelReduceQuotWith,
                    hInitialized,
                    hHead,
                    hLift,
                    args,
                    hShort
                  ] at hSuccess
                  rcases hSuccess with ⟨rfl, rfl⟩
                  exact ⟨hConfig, trivial⟩
              | false =>
                  cases hMajor :
                      psKernelExprListGet args 5 with
                  | none =>
                      simp [
                        psKernelReduceQuotWith,
                        hInitialized,
                        hHead,
                        hLift,
                        args,
                        hShort,
                        hMajor
                      ] at hSuccess
                      rcases hSuccess with ⟨rfl, rfl⟩
                      exact ⟨hConfig, trivial⟩
                  | some major =>
                      cases hMajorRun :
                          publicWhnf
                            context state major with
                      | error error =>
                          simp [
                            psKernelReduceQuotWith,
                            hInitialized,
                            hHead,
                            hLift,
                            args,
                            hShort,
                            hMajor,
                            hMajorRun
                          ] at hSuccess
                      | ok majorPair =>
                          rcases majorPair with
                            ⟨majorReduced, state1⟩
                          have hMajorSemantic :=
                            hWhnf
                              context
                              state
                              state1
                              major
                              majorReduced
                              hConfig
                              hMajorRun
                          cases hMkHead :
                              psKernelExprGetAppFn
                                majorReduced with
                          | const mkName mkLevels =>
                              cases hMk :
                                  psKernelNameEq
                                    mkName
                                    psKernelQuotMkName with
                              | false =>
                                  simp [
                                    psKernelReduceQuotWith,
                                    hInitialized,
                                    hHead,
                                    hLift,
                                    args,
                                    hShort,
                                    hMajor,
                                    hMajorRun,
                                    hMkHead,
                                    hMk
                                  ] at hSuccess
                                  rcases hSuccess with
                                    ⟨rfl, rfl⟩
                                  exact
                                    ⟨hMajorSemantic.2, trivial⟩
                              | true =>
                                  cases hArity :
                                      Nat.beq
                                        (psKernelExprGetAppNumArgs
                                          majorReduced)
                                        3 with
                                  | false =>
                                      simp [
                                        psKernelReduceQuotWith,
                                        hInitialized,
                                        hHead,
                                        hLift,
                                        args,
                                        hShort,
                                        hMajor,
                                        hMajorRun,
                                        hMkHead,
                                        hMk,
                                        hArity
                                      ] at hSuccess
                                      rcases hSuccess with
                                        ⟨rfl, rfl⟩
                                      exact
                                        ⟨hMajorSemantic.2, trivial⟩
                                  | true =>
                                      let mkArgs :=
                                        psKernelExprGetAppArgs
                                          majorReduced
                                      cases hRepresentative :
                                          psKernelExprListGet
                                            mkArgs
                                            2 with
                                      | none =>
                                          simp [
                                            psKernelReduceQuotWith,
                                            hInitialized,
                                            hHead,
                                            hLift,
                                            args,
                                            hShort,
                                            hMajor,
                                            hMajorRun,
                                            hMkHead,
                                            hMk,
                                            hArity,
                                            mkArgs,
                                            hRepresentative
                                          ] at hSuccess
                                          rcases hSuccess with
                                            ⟨rfl, rfl⟩
                                          exact
                                            ⟨hMajorSemantic.2, trivial⟩
                                      | some representative =>
                                          cases hFnValue :
                                              psKernelExprListGet
                                                args
                                                3 with
                                          | none =>
                                              simp [
                                                psKernelReduceQuotWith,
                                                hInitialized,
                                                hHead,
                                                hLift,
                                                args,
                                                hShort,
                                                hMajor,
                                                hMajorRun,
                                                hMkHead,
                                                hMk,
                                                hArity,
                                                mkArgs,
                                                hRepresentative,
                                                hFnValue
                                              ] at hSuccess
                                              rcases hSuccess with
                                                ⟨rfl, rfl⟩
                                              exact
                                                ⟨hMajorSemantic.2, trivial⟩
                                          | some fnValue =>
                                              simp [
                                                psKernelReduceQuotWith,
                                                hInitialized,
                                                hHead,
                                                hLift,
                                                args,
                                                hShort,
                                                hMajor,
                                                hMajorRun,
                                                hMkHead,
                                                hMk,
                                                hArity,
                                                mkArgs,
                                                hRepresentative,
                                                hFnValue
                                              ] at hSuccess
                                              rcases hSuccess with
                                                ⟨rfl, rfl⟩
                                              constructor
                                              · exact hMajorSemantic.2
                                              · exact
                                                  PsKernelReductionClosure.quotLift
                                                    expr
                                                    fnName
                                                    mkName
                                                    levels
                                                    mkLevels
                                                    args
                                                    mkArgs
                                                    major
                                                    majorReduced
                                                    representative
                                                    fnValue
                                                    hInitialized
                                                    hHead
                                                    hLift
                                                    rfl
                                                    hMajor
                                                    hMajorSemantic.1
                                                    hMkHead
                                                    hMk
                                                    hArity
                                                    rfl
                                                    hRepresentative
                                                    hFnValue
                          | bvar index =>
                              simp [
                                psKernelReduceQuotWith,
                                hInitialized,
                                hHead,
                                hLift,
                                args,
                                hShort,
                                hMajor,
                                hMajorRun,
                                hMkHead
                              ] at hSuccess
                              rcases hSuccess with ⟨rfl, rfl⟩
                              exact ⟨hMajorSemantic.2, trivial⟩
                          | fvar name =>
                              simp [
                                psKernelReduceQuotWith,
                                hInitialized,
                                hHead,
                                hLift,
                                args,
                                hShort,
                                hMajor,
                                hMajorRun,
                                hMkHead
                              ] at hSuccess
                              rcases hSuccess with ⟨rfl, rfl⟩
                              exact ⟨hMajorSemantic.2, trivial⟩
                          | mvar name =>
                              simp [
                                psKernelReduceQuotWith,
                                hInitialized,
                                hHead,
                                hLift,
                                args,
                                hShort,
                                hMajor,
                                hMajorRun,
                                hMkHead
                              ] at hSuccess
                              rcases hSuccess with ⟨rfl, rfl⟩
                              exact ⟨hMajorSemantic.2, trivial⟩
                          | sort level =>
                              simp [
                                psKernelReduceQuotWith,
                                hInitialized,
                                hHead,
                                hLift,
                                args,
                                hShort,
                                hMajor,
                                hMajorRun,
                                hMkHead
                              ] at hSuccess
                              rcases hSuccess with ⟨rfl, rfl⟩
                              exact ⟨hMajorSemantic.2, trivial⟩
                          | app fn arg =>
                              simp [
                                psKernelReduceQuotWith,
                                hInitialized,
                                hHead,
                                hLift,
                                args,
                                hShort,
                                hMajor,
                                hMajorRun,
                                hMkHead
                              ] at hSuccess
                              rcases hSuccess with ⟨rfl, rfl⟩
                              exact ⟨hMajorSemantic.2, trivial⟩
                          | lam name type body binderInfo =>
                              simp [
                                psKernelReduceQuotWith,
                                hInitialized,
                                hHead,
                                hLift,
                                args,
                                hShort,
                                hMajor,
                                hMajorRun,
                                hMkHead
                              ] at hSuccess
                              rcases hSuccess with ⟨rfl, rfl⟩
                              exact ⟨hMajorSemantic.2, trivial⟩
                          | forallE name type body binderInfo =>
                              simp [
                                psKernelReduceQuotWith,
                                hInitialized,
                                hHead,
                                hLift,
                                args,
                                hShort,
                                hMajor,
                                hMajorRun,
                                hMkHead
                              ] at hSuccess
                              rcases hSuccess with ⟨rfl, rfl⟩
                              exact ⟨hMajorSemantic.2, trivial⟩
                          | letE name type value body nondep =>
                              simp [
                                psKernelReduceQuotWith,
                                hInitialized,
                                hHead,
                                hLift,
                                args,
                                hShort,
                                hMajor,
                                hMajorRun,
                                hMkHead
                              ] at hSuccess
                              rcases hSuccess with ⟨rfl, rfl⟩
                              exact ⟨hMajorSemantic.2, trivial⟩
                          | lit literal =>
                              simp [
                                psKernelReduceQuotWith,
                                hInitialized,
                                hHead,
                                hLift,
                                args,
                                hShort,
                                hMajor,
                                hMajorRun,
                                hMkHead
                              ] at hSuccess
                              rcases hSuccess with ⟨rfl, rfl⟩
                              exact ⟨hMajorSemantic.2, trivial⟩
                          | mdata metadata body =>
                              simp [
                                psKernelReduceQuotWith,
                                hInitialized,
                                hHead,
                                hLift,
                                args,
                                hShort,
                                hMajor,
                                hMajorRun,
                                hMkHead
                              ] at hSuccess
                              rcases hSuccess with ⟨rfl, rfl⟩
                              exact ⟨hMajorSemantic.2, trivial⟩
                          | proj typeName index body =>
                              simp [
                                psKernelReduceQuotWith,
                                hInitialized,
                                hHead,
                                hLift,
                                args,
                                hShort,
                                hMajor,
                                hMajorRun,
                                hMkHead
                              ] at hSuccess
                              rcases hSuccess with ⟨rfl, rfl⟩
                              exact ⟨hMajorSemantic.2, trivial⟩
          | false =>
              cases hInd :
                  psKernelNameEq
                    fnName
                    psKernelQuotIndName with
              | false =>
                  simp [
                    psKernelReduceQuotWith,
                    hInitialized,
                    hHead,
                    hLift,
                    hInd
                  ] at hSuccess
                  rcases hSuccess with ⟨rfl, rfl⟩
                  exact ⟨hConfig, trivial⟩
              | true =>
                  let args :=
                    psKernelExprGetAppArgs expr
                  cases hShort :
                      Nat.ble
                        (psKernelExprListLength args)
                        4 with
                  | true =>
                      simp [
                        psKernelReduceQuotWith,
                        hInitialized,
                        hHead,
                        hLift,
                        hInd,
                        args,
                        hShort
                      ] at hSuccess
                      rcases hSuccess with ⟨rfl, rfl⟩
                      exact ⟨hConfig, trivial⟩
                  | false =>
                      cases hMajor :
                          psKernelExprListGet args 4 with
                      | none =>
                          simp [
                            psKernelReduceQuotWith,
                            hInitialized,
                            hHead,
                            hLift,
                            hInd,
                            args,
                            hShort,
                            hMajor
                          ] at hSuccess
                          rcases hSuccess with ⟨rfl, rfl⟩
                          exact ⟨hConfig, trivial⟩
                      | some major =>
                          cases hMajorRun :
                              publicWhnf
                                context state major with
                          | error error =>
                              simp [
                                psKernelReduceQuotWith,
                                hInitialized,
                                hHead,
                                hLift,
                                hInd,
                                args,
                                hShort,
                                hMajor,
                                hMajorRun
                              ] at hSuccess
                          | ok majorPair =>
                              rcases majorPair with
                                ⟨majorReduced, state1⟩
                              have hMajorSemantic :=
                                hWhnf
                                  context
                                  state
                                  state1
                                  major
                                  majorReduced
                                  hConfig
                                  hMajorRun
                              cases hMkHead :
                                  psKernelExprGetAppFn
                                    majorReduced with
                              | const mkName mkLevels =>
                                  cases hMk :
                                      psKernelNameEq
                                        mkName
                                        psKernelQuotMkName with
                                  | false =>
                                      simp [
                                        psKernelReduceQuotWith,
                                        hInitialized,
                                        hHead,
                                        hLift,
                                        hInd,
                                        args,
                                        hShort,
                                        hMajor,
                                        hMajorRun,
                                        hMkHead,
                                        hMk
                                      ] at hSuccess
                                      rcases hSuccess with
                                        ⟨rfl, rfl⟩
                                      exact
                                        ⟨hMajorSemantic.2, trivial⟩
                                  | true =>
                                      cases hArity :
                                          Nat.beq
                                            (psKernelExprGetAppNumArgs
                                              majorReduced)
                                            3 with
                                      | false =>
                                          simp [
                                            psKernelReduceQuotWith,
                                            hInitialized,
                                            hHead,
                                            hLift,
                                            hInd,
                                            args,
                                            hShort,
                                            hMajor,
                                            hMajorRun,
                                            hMkHead,
                                            hMk,
                                            hArity
                                          ] at hSuccess
                                          rcases hSuccess with
                                            ⟨rfl, rfl⟩
                                          exact
                                            ⟨hMajorSemantic.2, trivial⟩
                                      | true =>
                                          let mkArgs :=
                                            psKernelExprGetAppArgs
                                              majorReduced
                                          cases hRepresentative :
                                              psKernelExprListGet
                                                mkArgs
                                                2 with
                                          | none =>
                                              simp [
                                                psKernelReduceQuotWith,
                                                hInitialized,
                                                hHead,
                                                hLift,
                                                hInd,
                                                args,
                                                hShort,
                                                hMajor,
                                                hMajorRun,
                                                hMkHead,
                                                hMk,
                                                hArity,
                                                mkArgs,
                                                hRepresentative
                                              ] at hSuccess
                                              rcases hSuccess with
                                                ⟨rfl, rfl⟩
                                              exact
                                                ⟨hMajorSemantic.2, trivial⟩
                                          | some representative =>
                                              cases hFnValue :
                                                  psKernelExprListGet
                                                    args
                                                    3 with
                                              | none =>
                                                  simp [
                                                    psKernelReduceQuotWith,
                                                    hInitialized,
                                                    hHead,
                                                    hLift,
                                                    hInd,
                                                    args,
                                                    hShort,
                                                    hMajor,
                                                    hMajorRun,
                                                    hMkHead,
                                                    hMk,
                                                    hArity,
                                                    mkArgs,
                                                    hRepresentative,
                                                    hFnValue
                                                  ] at hSuccess
                                                  rcases hSuccess with
                                                    ⟨rfl, rfl⟩
                                                  exact
                                                    ⟨hMajorSemantic.2, trivial⟩
                                              | some fnValue =>
                                                  simp [
                                                    psKernelReduceQuotWith,
                                                    hInitialized,
                                                    hHead,
                                                    hLift,
                                                    hInd,
                                                    args,
                                                    hShort,
                                                    hMajor,
                                                    hMajorRun,
                                                    hMkHead,
                                                    hMk,
                                                    hArity,
                                                    mkArgs,
                                                    hRepresentative,
                                                    hFnValue
                                                  ] at hSuccess
                                                  rcases hSuccess with
                                                    ⟨rfl, rfl⟩
                                                  constructor
                                                  · exact hMajorSemantic.2
                                                  · exact
                                                      PsKernelReductionClosure.quotInd
                                                        expr
                                                        fnName
                                                        mkName
                                                        levels
                                                        mkLevels
                                                        args
                                                        mkArgs
                                                        major
                                                        majorReduced
                                                        representative
                                                        fnValue
                                                        hInitialized
                                                        hHead
                                                        hInd
                                                        rfl
                                                        hMajor
                                                        hMajorSemantic.1
                                                        hMkHead
                                                        hMk
                                                        hArity
                                                        rfl
                                                        hRepresentative
                                                        hFnValue
                              | bvar index =>
                                  simp [
                                    psKernelReduceQuotWith,
                                    hInitialized,
                                    hHead,
                                    hLift,
                                    hInd,
                                    args,
                                    hShort,
                                    hMajor,
                                    hMajorRun,
                                    hMkHead
                                  ] at hSuccess
                                  rcases hSuccess with ⟨rfl, rfl⟩
                                  exact ⟨hMajorSemantic.2, trivial⟩
                              | fvar name =>
                                  simp [
                                    psKernelReduceQuotWith,
                                    hInitialized,
                                    hHead,
                                    hLift,
                                    hInd,
                                    args,
                                    hShort,
                                    hMajor,
                                    hMajorRun,
                                    hMkHead
                                  ] at hSuccess
                                  rcases hSuccess with ⟨rfl, rfl⟩
                                  exact ⟨hMajorSemantic.2, trivial⟩
                              | mvar name =>
                                  simp [
                                    psKernelReduceQuotWith,
                                    hInitialized,
                                    hHead,
                                    hLift,
                                    hInd,
                                    args,
                                    hShort,
                                    hMajor,
                                    hMajorRun,
                                    hMkHead
                                  ] at hSuccess
                                  rcases hSuccess with ⟨rfl, rfl⟩
                                  exact ⟨hMajorSemantic.2, trivial⟩
                              | sort level =>
                                  simp [
                                    psKernelReduceQuotWith,
                                    hInitialized,
                                    hHead,
                                    hLift,
                                    hInd,
                                    args,
                                    hShort,
                                    hMajor,
                                    hMajorRun,
                                    hMkHead
                                  ] at hSuccess
                                  rcases hSuccess with ⟨rfl, rfl⟩
                                  exact ⟨hMajorSemantic.2, trivial⟩
                              | app fn arg =>
                                  simp [
                                    psKernelReduceQuotWith,
                                    hInitialized,
                                    hHead,
                                    hLift,
                                    hInd,
                                    args,
                                    hShort,
                                    hMajor,
                                    hMajorRun,
                                    hMkHead
                                  ] at hSuccess
                                  rcases hSuccess with ⟨rfl, rfl⟩
                                  exact ⟨hMajorSemantic.2, trivial⟩
                              | lam name type body binderInfo =>
                                  simp [
                                    psKernelReduceQuotWith,
                                    hInitialized,
                                    hHead,
                                    hLift,
                                    hInd,
                                    args,
                                    hShort,
                                    hMajor,
                                    hMajorRun,
                                    hMkHead
                                  ] at hSuccess
                                  rcases hSuccess with ⟨rfl, rfl⟩
                                  exact ⟨hMajorSemantic.2, trivial⟩
                              | forallE name type body binderInfo =>
                                  simp [
                                    psKernelReduceQuotWith,
                                    hInitialized,
                                    hHead,
                                    hLift,
                                    hInd,
                                    args,
                                    hShort,
                                    hMajor,
                                    hMajorRun,
                                    hMkHead
                                  ] at hSuccess
                                  rcases hSuccess with ⟨rfl, rfl⟩
                                  exact ⟨hMajorSemantic.2, trivial⟩
                              | letE name type value body nondep =>
                                  simp [
                                    psKernelReduceQuotWith,
                                    hInitialized,
                                    hHead,
                                    hLift,
                                    hInd,
                                    args,
                                    hShort,
                                    hMajor,
                                    hMajorRun,
                                    hMkHead
                                  ] at hSuccess
                                  rcases hSuccess with ⟨rfl, rfl⟩
                                  exact ⟨hMajorSemantic.2, trivial⟩
                              | lit literal =>
                                  simp [
                                    psKernelReduceQuotWith,
                                    hInitialized,
                                    hHead,
                                    hLift,
                                    hInd,
                                    args,
                                    hShort,
                                    hMajor,
                                    hMajorRun,
                                    hMkHead
                                  ] at hSuccess
                                  rcases hSuccess with ⟨rfl, rfl⟩
                                  exact ⟨hMajorSemantic.2, trivial⟩
                              | mdata metadata body =>
                                  simp [
                                    psKernelReduceQuotWith,
                                    hInitialized,
                                    hHead,
                                    hLift,
                                    hInd,
                                    args,
                                    hShort,
                                    hMajor,
                                    hMajorRun,
                                    hMkHead
                                  ] at hSuccess
                                  rcases hSuccess with ⟨rfl, rfl⟩
                                  exact ⟨hMajorSemantic.2, trivial⟩
                              | proj typeName index body =>
                                  simp [
                                    psKernelReduceQuotWith,
                                    hInitialized,
                                    hHead,
                                    hLift,
                                    hInd,
                                    args,
                                    hShort,
                                    hMajor,
                                    hMajorRun,
                                    hMkHead
                                  ] at hSuccess
                                  rcases hSuccess with ⟨rfl, rfl⟩
                                  exact ⟨hMajorSemantic.2, trivial⟩
      | bvar index =>
          simp [
            psKernelReduceQuotWith,
            hInitialized,
            hHead
          ] at hSuccess
          rcases hSuccess with ⟨rfl, rfl⟩
          exact ⟨hConfig, trivial⟩
      | fvar name =>
          simp [
            psKernelReduceQuotWith,
            hInitialized,
            hHead
          ] at hSuccess
          rcases hSuccess with ⟨rfl, rfl⟩
          exact ⟨hConfig, trivial⟩
      | mvar name =>
          simp [
            psKernelReduceQuotWith,
            hInitialized,
            hHead
          ] at hSuccess
          rcases hSuccess with ⟨rfl, rfl⟩
          exact ⟨hConfig, trivial⟩
      | sort level =>
          simp [
            psKernelReduceQuotWith,
            hInitialized,
            hHead
          ] at hSuccess
          rcases hSuccess with ⟨rfl, rfl⟩
          exact ⟨hConfig, trivial⟩
      | app fn arg =>
          simp [
            psKernelReduceQuotWith,
            hInitialized,
            hHead
          ] at hSuccess
          rcases hSuccess with ⟨rfl, rfl⟩
          exact ⟨hConfig, trivial⟩
      | lam name type body binderInfo =>
          simp [
            psKernelReduceQuotWith,
            hInitialized,
            hHead
          ] at hSuccess
          rcases hSuccess with ⟨rfl, rfl⟩
          exact ⟨hConfig, trivial⟩
      | forallE name type body binderInfo =>
          simp [
            psKernelReduceQuotWith,
            hInitialized,
            hHead
          ] at hSuccess
          rcases hSuccess with ⟨rfl, rfl⟩
          exact ⟨hConfig, trivial⟩
      | letE name type value body nondep =>
          simp [
            psKernelReduceQuotWith,
            hInitialized,
            hHead
          ] at hSuccess
          rcases hSuccess with ⟨rfl, rfl⟩
          exact ⟨hConfig, trivial⟩
      | lit literal =>
          simp [
            psKernelReduceQuotWith,
            hInitialized,
            hHead
          ] at hSuccess
          rcases hSuccess with ⟨rfl, rfl⟩
          exact ⟨hConfig, trivial⟩
      | mdata metadata body =>
          simp [
            psKernelReduceQuotWith,
            hInitialized,
            hHead
          ] at hSuccess
          rcases hSuccess with ⟨rfl, rfl⟩
          exact ⟨hConfig, trivial⟩
      | proj typeName index body =>
          simp [
            psKernelReduceQuotWith,
            hInitialized,
            hHead
          ] at hSuccess
          rcases hSuccess with ⟨rfl, rfl⟩
          exact ⟨hConfig, trivial⟩
