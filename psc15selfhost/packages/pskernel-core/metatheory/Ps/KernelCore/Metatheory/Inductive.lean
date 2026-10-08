import Ps.KernelCore.Metatheory.Judgments
import Ps.KernelCore.Metatheory.SessionConcreteRefinement
import Ps.KernelCore.Metatheory.SessionRefinement
import Ps.KernelCore.Admission.Inductive.Common.Occurrence
import Ps.KernelCore.Admission.Inductive.Ordinary.Constructor
import Ps.KernelCore.Admission.Inductive.Common.RecursorValidation

/-
Independent Assurance Plane predicates for simple-inductive occurrence checks.

The executable checker is fuel-bounded.  These predicates are structural and
fuel-free; they express what a successful uniform-occurrence check certifies.
-/

def PsKernelUniformOccurrenceHeadValid
    (declaredNames : List PsKernelName)
    (expectedLevels : List PsKernelLevel)
    (numParams : Nat)
    (expr : PsKernelExpr)
    (offset : Nat) : Prop :=
  ∃
    (name : PsKernelName)
    (levels : List PsKernelLevel)
    (args : List PsKernelExpr),
      psKernelExprGetAppFn expr =
        PsKernelExpr.const name levels ∧
      psKernelExprGetAppArgs expr = args ∧
      psKernelSimpleDeclaredNameMember
          name
          declaredNames =
        true ∧
      psKernelExprListLength args = numParams ∧
      psKernelNatGe offset numParams = true ∧
      psKernelLevelListEq levels expectedLevels = true ∧
      psKernelSimpleUniformParamArgsMatch
          offset
          args
          0 =
        true

def PsKernelUniformOccurrenceSafe
    (declaredNames : List PsKernelName)
    (expectedLevels : List PsKernelLevel)
    (numParams : Nat)
    (expr : PsKernelExpr)
    (offset : Nat) : Prop :=
      match
          psKernelSimpleCheckUniformOccurrenceHead
            declaredNames
            expectedLevels
            numParams
            expr
            offset with
      | Except.error _ =>
          False
      | Except.ok true =>
          PsKernelUniformOccurrenceHeadValid
            declaredNames
            expectedLevels
            numParams
            expr
            offset
      | Except.ok false =>
          match expr with
          | PsKernelExpr.app fn arg =>
              PsKernelUniformOccurrenceSafe
                  declaredNames
                  expectedLevels
                  numParams
                  fn
                  offset ∧
                PsKernelUniformOccurrenceSafe
                  declaredNames
                  expectedLevels
                  numParams
                  arg
                  offset
          | PsKernelExpr.lam _ type body _ =>
              PsKernelUniformOccurrenceSafe
                  declaredNames
                  expectedLevels
                  numParams
                  type
                  offset ∧
                PsKernelUniformOccurrenceSafe
                  declaredNames
                  expectedLevels
                  numParams
                  body
                  (Nat.succ offset)
          | PsKernelExpr.forallE _ type body _ =>
              PsKernelUniformOccurrenceSafe
                  declaredNames
                  expectedLevels
                  numParams
                  type
                  offset ∧
                PsKernelUniformOccurrenceSafe
                  declaredNames
                  expectedLevels
                  numParams
                  body
                  (Nat.succ offset)
          | PsKernelExpr.letE _ type value body _ =>
              PsKernelUniformOccurrenceSafe
                  declaredNames
                  expectedLevels
                  numParams
                  type
                  offset ∧
                PsKernelUniformOccurrenceSafe
                  declaredNames
                  expectedLevels
                  numParams
                  value
                  offset ∧
                PsKernelUniformOccurrenceSafe
                  declaredNames
                  expectedLevels
                  numParams
                  body
                  (Nat.succ offset)
          | PsKernelExpr.mdata _ body =>
              PsKernelUniformOccurrenceSafe
                declaredNames
                expectedLevels
                numParams
                body
                offset
          | PsKernelExpr.proj _ _ body =>
              PsKernelUniformOccurrenceSafe
                declaredNames
                expectedLevels
                numParams
                body
                offset
          | _ =>
              True
termination_by expr

def PsKernelUniformOccurrencesSafe
    (declaredNames : List PsKernelName)
    (expectedLevels : List PsKernelLevel)
    (numParams : Nat)
    (ctorTypes : List PsKernelExpr) : Prop :=
  ∀ expr : PsKernelExpr,
    List.Mem expr ctorTypes ->
      PsKernelUniformOccurrenceSafe
        declaredNames
        expectedLevels
        numParams
        expr
        0


def PsKernelSimpleInductiveAppValid
    (target : PsKernelName)
    (levels : List PsKernelLevel)
    (params : List PsKernelOpenBinder)
    (numIndices : Nat)
    (result : PsKernelExpr)
    (indices : List PsKernelExpr) : Prop :=
  ∃
    (resultName : PsKernelName)
    (resultLevels : List PsKernelLevel),
      psKernelExprGetAppFn result =
        PsKernelExpr.const resultName resultLevels ∧
      psKernelNameEq resultName target = true ∧
      psKernelLevelListEq resultLevels levels = true ∧
      psKernelConsumeSimpleResultParams
          params
          (psKernelExprGetAppArgs result) =
        Option.some indices ∧
      psKernelExprListLength indices = numIndices

def PsKernelSimpleConstructorResultValid
    (target : PsKernelName)
    (levels : List PsKernelLevel)
    (params : List PsKernelOpenBinder)
    (numIndices : Nat)
    (result : PsKernelExpr)
    (indices : List PsKernelExpr) : Prop :=
  PsKernelSimpleInductiveAppValid
      target
      levels
      params
      numIndices
      result
      indices ∧
    psKernelSimpleIndicesContainTarget
        target
        indices =
      false


/--
Independent raw constructor-parameter spine semantics.

A parameter is consumed only when the constructor type is syntactically a
`forallE`.  The domain is compared by ordinary definitional equality, but the
outer binder itself is never manufactured by WHNF.
-/
inductive PsKernelRawConstructorParamSpineValid
    (environment : PsKernelEnvironment)
    (localContext : PsKernelLocalContext) :
    List PsKernelOpenBinder ->
    PsKernelExpr ->
    PsKernelExpr ->
    Prop
  | nil
      (type : PsKernelExpr) :
      PsKernelRawConstructorParamSpineValid
        environment localContext List.nil type type
  | cons
      (param : PsKernelOpenBinder)
      (rest : List PsKernelOpenBinder)
      (userName : PsKernelName)
      (domain body residual : PsKernelExpr)
      (binderInfo : PsKernelBinderInfo)
      (hDomain :
        PsKernelDefEqJudgment
          environment
          localContext
          domain
          param.type)
      (hRest :
        PsKernelRawConstructorParamSpineValid
          environment
          localContext
          rest
          (psKernelExprInstantiate1
            body
            (PsKernelExpr.fvar param.internalName))
          residual) :
      PsKernelRawConstructorParamSpineValid
        environment
        localContext
        (List.cons param rest)
        (PsKernelExpr.forallE
          userName domain body binderInfo)
        residual


def PsKernelRawConstructorPiHead
    (expr : PsKernelExpr) : Bool :=
  match expr with
  | PsKernelExpr.forallE _ _ _ _ => true
  | _ => false


/--
Independent raw field-spine semantics.

Field domains are checked with the ordinary typing judgment and universe rule.
Only a syntactic `forallE` contributes a field.  A non-`forallE` head ends
the spine with the exact residual expression, making the no-WHNF-at-the-outer-
constructor-boundary rule explicit.
-/
inductive PsKernelRawConstructorFieldSpineValid
    (environment : PsKernelEnvironment)
    (resultLevel : PsKernelLevel) :
    PsKernelLocalContext ->
    PsKernelExpr ->
    PsKernelLocalContext ->
    List PsKernelOpenBinder ->
    PsKernelExpr ->
    Prop
  | done
      (localContext : PsKernelLocalContext)
      (type : PsKernelExpr)
      (hTerminal :
        PsKernelRawConstructorPiHead type = false) :
      PsKernelRawConstructorFieldSpineValid
        environment
        resultLevel
        localContext
        type
        localContext
        List.nil
        type
  | cons
      (localContext finalContext : PsKernelLocalContext)
      (fresh userName : PsKernelName)
      (domain body residual : PsKernelExpr)
      (binderInfo : PsKernelBinderInfo)
      (fieldLevel : PsKernelLevel)
      (fields : List PsKernelOpenBinder)
      (hFresh :
        psKernelLocalContextFind localContext fresh =
          Option.none)
      (hDomain :
        PsKernelTypingJudgment
          environment
          localContext
          domain
          (PsKernelExpr.sort fieldLevel))
      (hUniverse :
        psKernelLevelLe fieldLevel resultLevel = true ∨
          psKernelLevelNormalizesToZero resultLevel = true)
      (hRest :
        PsKernelRawConstructorFieldSpineValid
          environment
          resultLevel
          (psKernelLocalContextAddLocal
            localContext
            fresh
            userName
            (psKernelExprConsumeTypeAnnotations domain)
            binderInfo)
          (psKernelExprInstantiate1
            body
            (PsKernelExpr.fvar fresh))
          finalContext
          fields
          residual) :
      PsKernelRawConstructorFieldSpineValid
        environment
        resultLevel
        localContext
        (PsKernelExpr.forallE
          userName domain body binderInfo)
        finalContext
        (List.cons
          (PsKernelOpenBinder.mk
            fresh
            userName
            (psKernelExprConsumeTypeAnnotations domain)
            binderInfo)
          fields)
        residual


def PsKernelSessionCheckSoundAtFuel
    (fuel : Nat) : Prop :=
  ∀
    (session nextSession : PsKernelCheckerSession)
    (expr result : PsKernelExpr),
    psKernelSessionCheck
        fuel
        session
        expr =
      Except.ok (Prod.mk result nextSession) ->
    PsKernelTypingJudgment
      session.context.environment
      session.context.localContext
      expr
      result

def PsKernelSessionDefEqSoundAtFuel
    (fuel : Nat) : Prop :=
  ∀
    (session nextSession : PsKernelCheckerSession)
    (left right : PsKernelExpr),
    psKernelSessionIsDefEq
        fuel
        session
        left
        right =
      Except.ok (Prod.mk true nextSession) ->
    PsKernelDefEqJudgment
      session.context.environment
      session.context.localContext
      left
      right

inductive PsKernelSimpleRecursorRulesValid
    (fuel : Nat)
    (params : List PsKernelOpenBinder)
    (ruleBinders : List PsKernelOpenBinder)
    (motive : PsKernelExpr)
    (levels : List PsKernelLevel) :
    PsKernelCheckerSession ->
    List PsKernelSimpleConstructorShape ->
    List PsKernelRecursorRule ->
    Prop
  | nil
      (session : PsKernelCheckerSession) :
      PsKernelSimpleRecursorRulesValid
        fuel
        params
        ruleBinders
        motive
        levels
        session
        List.nil
        List.nil
  | cons
      (session checkedSession equalSession : PsKernelCheckerSession)
      (shape : PsKernelSimpleConstructorShape)
      (shapeRest : List PsKernelSimpleConstructorShape)
      (rule : PsKernelRecursorRule)
      (ruleRest : List PsKernelRecursorRule)
      (gotType : PsKernelExpr)
      (hCheck :
        psKernelSessionCheck
            fuel
            session
            rule.rhs =
          Except.ok (Prod.mk gotType checkedSession))
      (hTyping :
        PsKernelTypingJudgment
          session.context.environment
          session.context.localContext
          rule.rhs
          gotType)
      (hDefEqRun :
        psKernelSessionIsDefEq
            fuel
            checkedSession
            gotType
            (psKernelCloseOpenBinders
              (psKernelOpenBinderListAppend
                ruleBinders
                shape.fields)
              (psKernelSimpleMotiveApp
                motive
                shape.resultIndices
                (psKernelSimpleCtorApp
                  levels
                  params
                  shape))) =
          Except.ok (Prod.mk true equalSession))
      (hDefEq :
        PsKernelDefEqJudgment
          checkedSession.context.environment
          checkedSession.context.localContext
          gotType
          (psKernelCloseOpenBinders
            (psKernelOpenBinderListAppend
              ruleBinders
              shape.fields)
            (psKernelSimpleMotiveApp
              motive
              shape.resultIndices
              (psKernelSimpleCtorApp
                levels
                params
                shape))))
      (hRest :
        PsKernelSimpleRecursorRulesValid
          fuel
          params
          ruleBinders
          motive
          levels
          equalSession
          shapeRest
          ruleRest) :
      PsKernelSimpleRecursorRulesValid
        fuel
        params
        ruleBinders
        motive
        levels
        session
        (List.cons shape shapeRest)
        (List.cons rule ruleRest)

/--
Concrete recursor rule validation, threading the actual sound configuration
through checked typing and positive DefEq for every rule in order.
The only trust laws are the named native-reduction and StringEq soundness laws.
-/
theorem psKernelValidateSimpleRecursorRulesWorker_configuration_refines
    (shapes : List PsKernelSimpleConstructorShape)
    (fuel : Nat)
    (session : PsKernelCheckerSession)
    (params ruleBinders : List PsKernelOpenBinder)
    (motive : PsKernelExpr)
    (levels : List PsKernelLevel)
    (rules : List PsKernelRecursorRule)
    (hConfig : PsKernelCheckerConfigurationSound
      session.context session.state)
    (hNative : PsKernelNativeReductionSoundLaw)
    (hString : PsKernelStringEqSoundLaw)
    (hRun : psKernelValidateSimpleRecursorRulesWorker
      shapes fuel session params ruleBinders motive levels rules =
        Except.ok ()) :
    PsKernelSimpleRecursorRulesValid
      fuel params ruleBinders motive levels session shapes rules := by
  induction shapes generalizing session rules with
  | nil =>
      cases rules with
      | nil => exact PsKernelSimpleRecursorRulesValid.nil session
      | cons rule rest =>
          simp [psKernelValidateSimpleRecursorRulesWorker] at hRun
  | cons shape shapeRest ih =>
      cases rules with
      | nil =>
          simp [psKernelValidateSimpleRecursorRulesWorker] at hRun
      | cons rule ruleRest =>
          cases hCheck : psKernelSessionCheck fuel session rule.rhs with
          | error message =>
              simp [psKernelValidateSimpleRecursorRulesWorker, hCheck] at hRun
          | ok checked =>
              rcases checked with ⟨gotType, checkedSession⟩
              let expectedType := psKernelCloseOpenBinders
                (psKernelOpenBinderListAppend ruleBinders shape.fields)
                (psKernelSimpleMotiveApp motive shape.resultIndices
                  (psKernelSimpleCtorApp levels params shape))
              cases hCompare : psKernelSessionIsDefEq
                  fuel checkedSession gotType expectedType with
              | error message =>
                  simp [psKernelValidateSimpleRecursorRulesWorker,
                    hCheck, expectedType, hCompare] at hRun
              | ok compared =>
                  rcases compared with ⟨equal, equalSession⟩
                  cases equal with
                  | false =>
                      simp [psKernelValidateSimpleRecursorRulesWorker,
                        hCheck, expectedType, hCompare] at hRun
                  | true =>
                      have hTyping := psKernelSessionCheck_concrete_refines_typing
                        fuel hNative hString session checkedSession
                        rule.rhs gotType hConfig hCheck
                      have hCheckedContext :=
                        psKernelSessionCheck_success_preserves_context_core
                          fuel session checkedSession rule.rhs gotType hCheck
                      have hCheckedConfig : PsKernelCheckerConfigurationSound
                          checkedSession.context checkedSession.state := by
                        simpa [hCheckedContext] using hTyping.2
                      have hEq := psKernelSessionIsDefEq_concrete_refines_defeq
                        fuel hNative hString checkedSession equalSession
                        gotType expectedType hCheckedConfig hCompare
                      have hEqualContext :=
                        psKernelSessionIsDefEq_success_preserves_context_core
                          fuel checkedSession equalSession
                          gotType expectedType true hCompare
                      have hEqualConfig : PsKernelCheckerConfigurationSound
                          equalSession.context equalSession.state := by
                        simpa [hEqualContext] using hEq.2
                      have hTailRun : psKernelValidateSimpleRecursorRulesWorker
                          shapeRest fuel equalSession params ruleBinders
                          motive levels ruleRest = Except.ok () := by
                        simpa [psKernelValidateSimpleRecursorRulesWorker,
                          hCheck, expectedType, hCompare] using hRun
                      exact PsKernelSimpleRecursorRulesValid.cons
                        session checkedSession equalSession shape shapeRest
                        rule ruleRest gotType hCheck hTyping.1
                        (by simpa [expectedType] using hCompare)
                        (by simpa [expectedType] using hEq.1)
                        (ih equalSession ruleRest hEqualConfig hTailRun)

theorem psKernelValidateSimpleRecursorRules_configuration_refines
    (fuel : Nat)
    (session : PsKernelCheckerSession)
    (params ruleBinders : List PsKernelOpenBinder)
    (motive : PsKernelExpr)
    (levels : List PsKernelLevel)
    (shapes : List PsKernelSimpleConstructorShape)
    (rules : List PsKernelRecursorRule)
    (hConfig : PsKernelCheckerConfigurationSound
      session.context session.state)
    (hNative : PsKernelNativeReductionSoundLaw)
    (hString : PsKernelStringEqSoundLaw)
    (hRun : psKernelValidateSimpleRecursorRules
      fuel session params ruleBinders motive levels shapes rules =
        Except.ok ()) :
    PsKernelSimpleRecursorRulesValid
      fuel params ruleBinders motive levels session shapes rules := by
  exact psKernelValidateSimpleRecursorRulesWorker_configuration_refines
    shapes fuel session params ruleBinders motive levels rules
    hConfig hNative hString hRun
