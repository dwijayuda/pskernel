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
