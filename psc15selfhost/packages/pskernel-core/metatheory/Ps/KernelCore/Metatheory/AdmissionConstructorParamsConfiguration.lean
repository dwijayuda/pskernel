import Ps.KernelCore.Metatheory.AdmissionInductiveHeaderConfiguration
import Ps.KernelCore.Metatheory.Inductive
import Ps.KernelCore.Metatheory.ExprEq
import Ps.KernelCore.Admission.Inductive.Ordinary.Constructor

/-
Raw constructor-parameter spine assurance, with checker configuration.

Successful parameter opening can consume only a syntactic forall binder.
Each domain comparison is a concrete checked-session DefEq computation.
The recursive worker carries the SAME environment and local context, while
its checker state may evolve; this theorem transports both semantic evidence
and configuration through that exact recursion.

Outer WHNF may NOT manufacture a new Pi binder for this admission rule.
-/
theorem psKernelOpenSimpleConstructorParamsWithFuel_raw_spine_refines
    (fuel : Nat) :
    ∀ (session : PsKernelCheckerSession)
      (params : List PsKernelOpenBinder)
      (type : PsKernelExpr)
      (result : PsKernelExprSessionResult),
      PsKernelCheckerConfigurationSound
          session.context session.state ->
      PsKernelNativeReductionSoundLaw ->
      PsKernelStringEqSoundLaw ->
      psKernelOpenSimpleConstructorParamsWithFuel
          fuel session params type =
        Except.ok result ->
      PsKernelRawConstructorParamSpineValid
          session.context.environment
          session.context.localContext
          params type result.result ∧
        result.session.context = session.context ∧
        PsKernelCheckerConfigurationSound
          session.context result.session.state := by
  induction fuel with
  | zero =>
      intro session params type result hConfig hNative hString hRun
      simp [psKernelOpenSimpleConstructorParamsWithFuel] at hRun
  | succ remaining ih =>
      intro session params type result hConfig hNative hString hRun
      cases params with
      | nil =>
          simp [psKernelOpenSimpleConstructorParamsWithFuel] at hRun
          cases hRun
          exact
            ⟨PsKernelRawConstructorParamSpineValid.nil type,
             rfl, hConfig⟩
      | cons param rest =>
          cases type with
          | forallE userName domain body binderInfo =>
              simp only [psKernelOpenSimpleConstructorParamsWithFuel] at hRun
              cases hCompare :
                  psKernelSessionIsDefEq
                    remaining session domain param.type with
              | error message =>
                  simp only [hCompare] at hRun
                  cases hRun
              | ok compared =>
                  simp only [hCompare] at hRun
                  rcases compared with ⟨equal, comparedSession⟩
                  cases equal with
                  | false =>
                      simp at hRun
                  | true =>
                      have hEq :=
                        psKernelSessionIsDefEq_concrete_refines_defeq
                          remaining hNative hString
                          session comparedSession
                          domain param.type
                          hConfig hCompare
                      have hContext :=
                        psKernelSessionIsDefEq_success_preserves_context_core
                          remaining session comparedSession
                          domain param.type true hCompare
                      have hNextConfig :
                          PsKernelCheckerConfigurationSound
                            comparedSession.context
                            comparedSession.state := by
                        simpa [hContext] using hEq.2
                      have hTailRun :
                          psKernelOpenSimpleConstructorParamsWithFuel
                              remaining comparedSession rest
                              (psKernelExprInstantiate1
                                body
                                (PsKernelExpr.fvar param.internalName)) =
                            Except.ok result := by
                        simpa using hRun
                      have hRecursive :=
                        ih comparedSession rest
                          (psKernelExprInstantiate1
                            body
                            (PsKernelExpr.fvar param.internalName))
                          result
                          hNextConfig hNative hString hTailRun
                      have hRest :
                          PsKernelRawConstructorParamSpineValid
                            session.context.environment
                            session.context.localContext
                            rest
                            (psKernelExprInstantiate1
                              body
                              (PsKernelExpr.fvar param.internalName))
                            result.result := by
                        simpa [hContext] using hRecursive.1
                      have hFinalContext :
                          result.session.context = session.context :=
                        Eq.trans hRecursive.2.1 hContext
                      have hFinalConfig :
                          PsKernelCheckerConfigurationSound
                            session.context result.session.state := by
                        simpa [hContext] using hRecursive.2.2
                      exact
                        ⟨PsKernelRawConstructorParamSpineValid.cons
                          param rest userName domain body result.result
                          binderInfo hEq.1 hRest,
                         hFinalContext,
                         hFinalConfig⟩
          | _ =>
              simp [psKernelOpenSimpleConstructorParamsWithFuel] at hRun

theorem psKernelOpenSimpleConstructorParams_raw_spine_refines
    (fuel : Nat)
    (session : PsKernelCheckerSession)
    (params : List PsKernelOpenBinder)
    (type : PsKernelExpr)
    (result : PsKernelExprSessionResult)
    (hConfig :
      PsKernelCheckerConfigurationSound session.context session.state)
    (hNative : PsKernelNativeReductionSoundLaw)
    (hString : PsKernelStringEqSoundLaw)
    (hRun :
      psKernelOpenSimpleConstructorParams
          fuel session params type =
        Except.ok result) :
    PsKernelRawConstructorParamSpineValid
        session.context.environment
        session.context.localContext
        params type result.result ∧
      result.session.context = session.context ∧
      PsKernelCheckerConfigurationSound
        session.context result.session.state := by
  exact
    psKernelOpenSimpleConstructorParamsWithFuel_raw_spine_refines
      (Nat.succ fuel) session params type result
      hConfig hNative hString
      (by simpa [psKernelOpenSimpleConstructorParams] using hRun)

/--
Independent result-parameter prefix evidence. Each accepted argument has
structural expression equality to the corresponding canonical parameter fvar;
the unconsumed suffix is exactly the returned index list.
-/
inductive PsKernelConstructorResultParamPrefix :
    List PsKernelOpenBinder -> List PsKernelExpr ->
    List PsKernelExpr -> Prop
  | nil (indices : List PsKernelExpr) :
      PsKernelConstructorResultParamPrefix [] indices indices
  | cons (param : PsKernelOpenBinder)
      (params : List PsKernelOpenBinder)
      (arg : PsKernelExpr) (args indices : List PsKernelExpr)
      (hArg : PsKernelStructuralExprEq
        arg (PsKernelExpr.fvar param.internalName))
      (hTail : PsKernelConstructorResultParamPrefix params args indices) :
      PsKernelConstructorResultParamPrefix
        (param :: params) (arg :: args) indices

theorem psKernelConsumeSimpleResultParams_success_refines_prefix
    (params : List PsKernelOpenBinder) :
    ∀ (args indices : List PsKernelExpr),
      psKernelConsumeSimpleResultParams params args = some indices ->
      PsKernelConstructorResultParamPrefix params args indices := by
  induction params with
  | nil =>
      intro args indices hRun
      simp only [psKernelConsumeSimpleResultParams] at hRun
      cases hRun
      exact PsKernelConstructorResultParamPrefix.nil args
  | cons param params ih =>
      intro args indices hRun
      cases args with
      | nil =>
          simp [psKernelConsumeSimpleResultParams] at hRun
      | cons arg args =>
          cases hEq :
              psKernelExprEq arg (PsKernelExpr.fvar param.internalName) with
          | false =>
              simp [psKernelConsumeSimpleResultParams, hEq] at hRun
          | true =>
              have hTail :
                  psKernelConsumeSimpleResultParams params args =
                    some indices := by
                simpa [psKernelConsumeSimpleResultParams, hEq] using hRun
              exact PsKernelConstructorResultParamPrefix.cons
                param params arg args indices
                (psKernelExprEq_true_refines_structural
                  arg (PsKernelExpr.fvar param.internalName) hEq)
                (ih args indices hTail)

theorem PsKernelConstructorResultParamPrefix.length
    (params : List PsKernelOpenBinder)
    (args indices : List PsKernelExpr)
    (hPrefix : PsKernelConstructorResultParamPrefix params args indices) :
    args.length = params.length + indices.length := by
  induction hPrefix with
  | nil indices => simp
  | cons param params arg args indices hArg hTail ih =>
      simpa [Nat.succ_add] using congrArg Nat.succ ih

theorem psKernelConsumeSimpleResultParams_success_length
    (params : List PsKernelOpenBinder)
    (args indices : List PsKernelExpr)
    (hRun :
      psKernelConsumeSimpleResultParams params args = some indices) :
    args.length = params.length + indices.length :=
  PsKernelConstructorResultParamPrefix.length params args indices
    (psKernelConsumeSimpleResultParams_success_refines_prefix
      params args indices hRun)


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


/--
Admission uses the checker's global fresh-name source and advances its state.
This gives the same freshness/configuration contract as checker binder opening.
-/
theorem psKernelSessionWithLocal_preserves_configuration
    (session : PsKernelCheckerSession)
    (userName : PsKernelName)
    (type : PsKernelExpr)
    (binderInfo : PsKernelBinderInfo)
    (hString : PsKernelStringEqSoundLaw)
    (hConfig : PsKernelCheckerConfigurationSound
      session.context session.state) :
    PsKernelCheckerConfigurationSound
      (Prod.snd (psKernelSessionWithLocal
        session userName type binderInfo)).context
      (Prod.snd (psKernelSessionWithLocal
        session userName type binderInfo)).state := by
  simpa only [psKernelSessionWithLocal] using
    psKernelCheckerFreshLocal_preserves_configuration
      session.context session.state userName type binderInfo hString hConfig
