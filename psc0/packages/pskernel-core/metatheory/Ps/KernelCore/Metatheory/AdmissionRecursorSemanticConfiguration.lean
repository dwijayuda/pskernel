import Ps.KernelCore.Metatheory.Inductive
import Ps.KernelCore.Admission.Inductive.Ordinary.Recursor

/--
Independent fuel-free typing of the recursor rule sequence at each constructor's
motive result. Checked inference plus positive algorithmic DefEq yields typing
by one conversion rule; no infer-only typing or DefEq transitivity is used.
-/
inductive PsKernelSimpleRecursorRulesTyped
    (environment : PsKernelEnvironment) (localContext : PsKernelLocalContext)
    (params ruleBinders : List PsKernelOpenBinder)
    (motive : PsKernelExpr) (levels : List PsKernelLevel) :
    List PsKernelSimpleConstructorShape -> List PsKernelRecursorRule -> Prop where
  | nil : PsKernelSimpleRecursorRulesTyped environment localContext params ruleBinders
      motive levels [] []
  | cons (shape : PsKernelSimpleConstructorShape) (shapeRest : List PsKernelSimpleConstructorShape)
      (rule : PsKernelRecursorRule) (ruleRest : List PsKernelRecursorRule)
      (hTyping : PsKernelTypingJudgment environment localContext rule.rhs
        (psKernelCloseOpenBinders
          (psKernelOpenBinderListAppend ruleBinders shape.fields)
          (psKernelSimpleMotiveApp motive shape.resultIndices
            (psKernelSimpleCtorApp levels params shape))))
      (hRest : PsKernelSimpleRecursorRulesTyped environment localContext params ruleBinders
        motive levels shapeRest ruleRest) :
      PsKernelSimpleRecursorRulesTyped environment localContext params ruleBinders
        motive levels (shape :: shapeRest) (rule :: ruleRest)

theorem PsKernelSimpleRecursorRulesValid.independent_typing
    {fuel : Nat} {params ruleBinders : List PsKernelOpenBinder}
    {motive : PsKernelExpr} {levels : List PsKernelLevel}
    {session : PsKernelCheckerSession} {shapes : List PsKernelSimpleConstructorShape}
    {rules : List PsKernelRecursorRule}
    (hValid : PsKernelSimpleRecursorRulesValid fuel params ruleBinders motive levels
      session shapes rules) :
    PsKernelSimpleRecursorRulesTyped session.context.environment session.context.localContext
      params ruleBinders motive levels shapes rules := by
  induction hValid with
  | nil => exact PsKernelSimpleRecursorRulesTyped.nil
  | cons session checkedSession equalSession shape shapeRest rule ruleRest gotType
      hCheck hTyping hDefEqRun hDefEq hRest ih =>
      have hCheckedContext := psKernelSessionCheck_success_preserves_context_core
        fuel session checkedSession rule.rhs gotType hCheck
      have hEqualContext := psKernelSessionIsDefEq_success_preserves_context_core
        fuel checkedSession equalSession gotType
        (psKernelCloseOpenBinders
          (psKernelOpenBinderListAppend ruleBinders shape.fields)
          (psKernelSimpleMotiveApp motive shape.resultIndices
            (psKernelSimpleCtorApp levels params shape))) true hDefEqRun
      refine PsKernelSimpleRecursorRulesTyped.cons shape shapeRest rule ruleRest ?_ ?_
      · exact PsKernelTypingJudgment.convert _ _ _ hTyping
          (by simpa [hCheckedContext] using hDefEq)
      · simpa [hEqualContext, hCheckedContext] using ih

theorem psKernelValidateSimpleRecursorRules_independent_typing
    (fuel : Nat) (session : PsKernelCheckerSession)
    (params ruleBinders : List PsKernelOpenBinder)
    (motive : PsKernelExpr) (levels : List PsKernelLevel)
    (shapes : List PsKernelSimpleConstructorShape) (rules : List PsKernelRecursorRule)
    (hConfig : PsKernelCheckerConfigurationSound session.context session.state)
    (hNative : PsKernelNativeReductionSoundLaw)
    (hString : PsKernelStringEqSoundLaw)
    (hRun : psKernelValidateSimpleRecursorRules fuel session params ruleBinders motive
      levels shapes rules = Except.ok ()) :
    PsKernelSimpleRecursorRulesTyped session.context.environment session.context.localContext
      params ruleBinders motive levels shapes rules :=
  (psKernelValidateSimpleRecursorRules_configuration_refines fuel session params ruleBinders
    motive levels shapes rules hConfig hNative hString hRun).independent_typing

/-- Constructor provenance and field arity of every generated recursor rule. -/
inductive PsKernelSimpleRecursorRuleMetadataMatches :
    List PsKernelSimpleConstructorShape -> List PsKernelRecursorRule -> Prop where
  | nil : PsKernelSimpleRecursorRuleMetadataMatches [] []
  | cons (shape : PsKernelSimpleConstructorShape) (shapes : List PsKernelSimpleConstructorShape)
      (rule : PsKernelRecursorRule) (rules : List PsKernelRecursorRule)
      (hCtor : rule.ctor = shape.ctor.name)
      (hFields : rule.nFields = psKernelOpenBinderListLength shape.fields)
      (hTail : PsKernelSimpleRecursorRuleMetadataMatches shapes rules) :
      PsKernelSimpleRecursorRuleMetadataMatches (shape :: shapes) (rule :: rules)

theorem psKernelMakeSimpleMinorBindersWorker_length
    (shapes : List PsKernelSimpleConstructorShape) :
    ∀ (motive : PsKernelExpr) (levels : List PsKernelLevel)
      (params : List PsKernelOpenBinder) (index : Nat),
      (psKernelMakeSimpleMinorBindersWorker shapes motive levels params index).length =
        shapes.length := by
  induction shapes with
  | nil => intro motive levels params index; rfl
  | cons shape rest ih =>
      intro motive levels params index
      simpa [psKernelMakeSimpleMinorBindersWorker] using
        congrArg Nat.succ (ih motive levels params (Nat.succ index))

theorem psKernelMakeSimpleRecursorRulesWorker_metadata
    (shapes : List PsKernelSimpleConstructorShape) :
    ∀ (recName : PsKernelName) (recLevels : List PsKernelLevel)
      (params : List PsKernelOpenBinder) (motive : PsKernelExpr)
      (allMinors ruleBinders minors : List PsKernelOpenBinder),
      shapes.length ≤ minors.length ->
      PsKernelSimpleRecursorRuleMetadataMatches shapes
        (psKernelMakeSimpleRecursorRulesWorker shapes recName recLevels params motive
          allMinors ruleBinders minors) := by
  induction shapes with
  | nil =>
      intro recName recLevels params motive allMinors ruleBinders minors hLength
      exact PsKernelSimpleRecursorRuleMetadataMatches.nil
  | cons shape rest ih =>
      intro recName recLevels params motive allMinors ruleBinders minors hLength
      cases minors with
      | nil => simp at hLength
      | cons minor minorRest =>
          have hTailLength : rest.length ≤ minorRest.length := by simpa using hLength
          exact PsKernelSimpleRecursorRuleMetadataMatches.cons shape rest _ _ rfl rfl
            (ih recName recLevels params motive allMinors ruleBinders minorRest hTailLength)

theorem psKernelMakeSimpleRecursorRules_generated_minor_metadata
    (recName : PsKernelName) (recLevels : List PsKernelLevel)
    (params : List PsKernelOpenBinder) (motive : PsKernelExpr)
    (levels : List PsKernelLevel) (ruleBinders : List PsKernelOpenBinder)
    (shapes : List PsKernelSimpleConstructorShape) :
    let minors := psKernelMakeSimpleMinorBinders motive levels params shapes;
    PsKernelSimpleRecursorRuleMetadataMatches shapes
      (psKernelMakeSimpleRecursorRules recName recLevels params motive minors
        ruleBinders shapes minors) := by
  dsimp only
  apply psKernelMakeSimpleRecursorRulesWorker_metadata
  have hLength := psKernelMakeSimpleMinorBindersWorker_length shapes motive levels params 0
  simpa [psKernelMakeSimpleMinorBinders, psKernelMakeSimpleMinorBindersWithIndex,
    hLength] using Nat.le_refl shapes.length
