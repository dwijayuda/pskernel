import Ps.KernelCore.Metatheory.AdmissionConstructorSemanticHistoryConfiguration
import Ps.KernelCore.Metatheory.AdmissionEliminationConfiguration
import Ps.KernelCore.Metatheory.AdmissionRecursorSemanticConfiguration

/--
Exact post-constructor ordinary admission suffix, stated in metatheory.
This projects executable control flow; independent semantic contracts must
separately justify its successful publication.
-/
def psKernelOrdinaryFinishAdmission
    (fuel : Nat) (environment : PsKernelEnvironment)
    (decl : PsKernelSimpleInductiveDecl) (maxRecDepth maxNatSize : Nat)
    (paramResult indexResult : PsKernelOpenBindersResult)
    (resultLevel : PsKernelLevel) (ctorResult : PsKernelAddConstructorsResult) :
    Except String PsKernelEnvironment :=
  let recName := psKernelSimpleRecName decl.name;
  let safety := if decl.isUnsafe then PsKernelDefinitionSafety.unsafeDef else PsKernelDefinitionSafety.safe;
  let params :=
    paramResult.binders;
  let indices :=
    indexResult.binders;
  let levels :=
    psKernelLevelParamsToLevels
      decl.levelParams;
  let paramArgs :=
    psKernelSimpleParamArgs params;
  let indexArgs :=
    psKernelOpenBinderExprs indices;
  let inductExpr :=
    psKernelApplyArgs
      (PsKernelExpr.const
        decl.name
        levels)
      (psKernelExprListAppend
        paramArgs
        indexArgs);
  let initialInfo :=
    PsKernelInductiveInfo.mk
      (PsKernelConstantBase.mk
        decl.name
        decl.levelParams
        decl.type)
      decl.numParams
      (psKernelOpenBinderListLength
        indices)
      (List.cons
        decl.name
        List.nil)
      (psKernelSimpleCtorNames
        decl.ctors)
      0
      false
      false
      decl.isUnsafe;
  let shapes :=
    ctorResult.shapes;
  let finalInfo :=
    PsKernelInductiveInfo.mk
      initialInfo.base
      initialInfo.numParams
      initialInfo.numIndices
      initialInfo.all
      initialInfo.ctors
      initialInfo.numNested
      (psKernelSimpleHasRecursiveFields
        shapes)
      (psKernelSimpleHasReflexiveFields
        shapes)
      initialInfo.isUnsafe;
  let work1 :=
    psKernelEnvironmentReplaceUnchecked
      ctorResult.environment
      (PsKernelConstantInfo.inductInfo
        finalInfo);
  let elimSession :=
    psKernelSessionWithEnvironment
      paramResult.session
      work1;
  match
      psKernelSimpleElimOnlyAtZero
        fuel
        elimSession
        params
        resultLevel
        decl.ctors with
  | Except.error error =>
      Except.error error
  | Except.ok elimOnlyAtZero =>
      let kTarget :=
        psKernelSimpleKTarget
          resultLevel
          shapes;
      let elimName :=
        psKernelSimpleFreshElimName
          decl.levelParams;
      let elimLevel :=
        if elimOnlyAtZero then
          PsKernelLevel.zero
        else
          PsKernelLevel.param
            elimName;
      let recLevelParams :=
        if elimOnlyAtZero then
          decl.levelParams
        else
          List.cons
            elimName
            decl.levelParams;
      let motiveInternal :=
        psKernelSimpleInternalName
          "motive";
      let motive :=
        PsKernelExpr.fvar
          motiveInternal;
      let motiveBinder :=
        PsKernelOpenBinder.mk
          motiveInternal
          (PsKernelName.str
            PsKernelName.anonymous
            "motive")
          (psKernelCloseOpenBinders
            indices
            (psKernelMkArrow
              inductExpr
              (PsKernelExpr.sort
                elimLevel)))
          PsKernelBinderInfo.default;
      let minorBinders :=
        psKernelMakeSimpleMinorBinders
          motive
          levels
          params
          shapes;
      let majorInternal :=
        psKernelSimpleInternalName
          "major";
      let major :=
        PsKernelExpr.fvar
          majorInternal;
      let majorBinder :=
        PsKernelOpenBinder.mk
          majorInternal
          (PsKernelName.str
            PsKernelName.anonymous
            "t")
          inductExpr
          PsKernelBinderInfo.default;
      let coreRuleBinders :=
        List.cons
          motiveBinder
          minorBinders;
      let ruleBinders :=
        psKernelOpenBinderListAppend
          params
          coreRuleBinders;
      let recBinders :=
        psKernelOpenBinderListAppend
          ruleBinders
          (psKernelOpenBinderListAppend
            indices
            (List.cons
              majorBinder
              List.nil));
      let recTypeRaw :=
        psKernelCloseOpenBinders
          recBinders
          (psKernelSimpleMotiveApp
            motive
            indexArgs
            major);
      let recType :=
        psKernelExprInferImplicitAll
          recTypeRaw
          true;
      let recLevels :=
        psKernelLevelParamsToLevels
          recLevelParams;
      let rules :=
        psKernelMakeSimpleRecursorRules
          recName
          recLevels
          params
          motive
          minorBinders
          ruleBinders
          shapes
          minorBinders;
      let recInfo :=
        PsKernelRecursorInfo.mk
          (PsKernelConstantBase.mk
            recName
            recLevelParams
            recType)
          (List.cons
            decl.name
            List.nil)
          decl.numParams
          (psKernelOpenBinderListLength indices)
          1
          (psKernelOpenBinderListLength
            minorBinders)
          rules
          kTarget
          decl.isUnsafe;
      let recSession :=
        psKernelMkCheckerSession
          work1
          recLevelParams
          safety
          maxRecDepth
          maxNatSize;
      match
          psKernelSessionCheck
            fuel
            recSession
            recType with
      | Except.error error =>
          Except.error error
      | Except.ok recTypeType =>
          match
              psKernelSessionEnsureSort
                fuel
                (Prod.snd recTypeType)
                (Prod.fst recTypeType) with
          | Except.error error =>
              Except.error error
          | Except.ok _ =>
              let work2 :=
                psKernelEnvironmentAddUnchecked
                  work1
                  (PsKernelConstantInfo.recInfo
                    recInfo);
              let ruleSession :=
                psKernelMkCheckerSession
                  work2
                  recLevelParams
                  safety
                  maxRecDepth
                  maxNatSize;
              match
                  psKernelValidateSimpleRecursorRules
                    fuel
                    ruleSession
                    params
                    ruleBinders
                    motive
                    levels
                    shapes
                    rules with
              | Except.error error =>
                  Except.error error
              | Except.ok _ =>
                  Except.ok work2


/-- Pure generated recursor data before checked publication. -/
structure PsKernelOrdinaryRecursorPreparation where
  environment : PsKernelEnvironment
  info : PsKernelRecursorInfo
  motive : PsKernelExpr
  ruleBinders : List PsKernelOpenBinder

def psKernelOrdinaryConstructorFinalEnvironment
    (decl : PsKernelSimpleInductiveDecl)
    (paramResult indexResult : PsKernelOpenBindersResult)
    (ctorResult : PsKernelAddConstructorsResult) : PsKernelEnvironment :=
  let params :=
    paramResult.binders;
  let indices :=
    indexResult.binders;
  let levels :=
    psKernelLevelParamsToLevels
      decl.levelParams;
  let paramArgs :=
    psKernelSimpleParamArgs params;
  let indexArgs :=
    psKernelOpenBinderExprs indices;
  let inductExpr :=
    psKernelApplyArgs
      (PsKernelExpr.const
        decl.name
        levels)
      (psKernelExprListAppend
        paramArgs
        indexArgs);
  let initialInfo :=
    PsKernelInductiveInfo.mk
      (PsKernelConstantBase.mk
        decl.name
        decl.levelParams
        decl.type)
      decl.numParams
      (psKernelOpenBinderListLength
        indices)
      (List.cons
        decl.name
        List.nil)
      (psKernelSimpleCtorNames
        decl.ctors)
      0
      false
      false
      decl.isUnsafe;
  let shapes :=
    ctorResult.shapes;
  let finalInfo :=
    PsKernelInductiveInfo.mk
      initialInfo.base
      initialInfo.numParams
      initialInfo.numIndices
      initialInfo.all
      initialInfo.ctors
      initialInfo.numNested
      (psKernelSimpleHasRecursiveFields
        shapes)
      (psKernelSimpleHasReflexiveFields
        shapes)
      initialInfo.isUnsafe;
  let work1 :=
    psKernelEnvironmentReplaceUnchecked
      ctorResult.environment
      (PsKernelConstantInfo.inductInfo
        finalInfo);
  work1

def psKernelOrdinaryPrepareRecursor
    (decl : PsKernelSimpleInductiveDecl)
    (paramResult indexResult : PsKernelOpenBindersResult)
    (resultLevel : PsKernelLevel) (ctorResult : PsKernelAddConstructorsResult)
    (elimOnlyAtZero : Bool) : PsKernelOrdinaryRecursorPreparation :=
  let recName := psKernelSimpleRecName decl.name;
  let params :=
    paramResult.binders;
  let indices :=
    indexResult.binders;
  let levels :=
    psKernelLevelParamsToLevels
      decl.levelParams;
  let paramArgs :=
    psKernelSimpleParamArgs params;
  let indexArgs :=
    psKernelOpenBinderExprs indices;
  let inductExpr :=
    psKernelApplyArgs
      (PsKernelExpr.const
        decl.name
        levels)
      (psKernelExprListAppend
        paramArgs
        indexArgs);
  let initialInfo :=
    PsKernelInductiveInfo.mk
      (PsKernelConstantBase.mk
        decl.name
        decl.levelParams
        decl.type)
      decl.numParams
      (psKernelOpenBinderListLength
        indices)
      (List.cons
        decl.name
        List.nil)
      (psKernelSimpleCtorNames
        decl.ctors)
      0
      false
      false
      decl.isUnsafe;
  let shapes :=
    ctorResult.shapes;
  let finalInfo :=
    PsKernelInductiveInfo.mk
      initialInfo.base
      initialInfo.numParams
      initialInfo.numIndices
      initialInfo.all
      initialInfo.ctors
      initialInfo.numNested
      (psKernelSimpleHasRecursiveFields
        shapes)
      (psKernelSimpleHasReflexiveFields
        shapes)
      initialInfo.isUnsafe;
  let work1 :=
    psKernelEnvironmentReplaceUnchecked
      ctorResult.environment
      (PsKernelConstantInfo.inductInfo
        finalInfo);
  let kTarget :=
    psKernelSimpleKTarget
      resultLevel
      shapes;
  let elimName :=
    psKernelSimpleFreshElimName
      decl.levelParams;
  let elimLevel :=
    if elimOnlyAtZero then
      PsKernelLevel.zero
    else
      PsKernelLevel.param
        elimName;
  let recLevelParams :=
    if elimOnlyAtZero then
      decl.levelParams
    else
      List.cons
        elimName
        decl.levelParams;
  let motiveInternal :=
    psKernelSimpleInternalName
      "motive";
  let motive :=
    PsKernelExpr.fvar
      motiveInternal;
  let motiveBinder :=
    PsKernelOpenBinder.mk
      motiveInternal
      (PsKernelName.str
        PsKernelName.anonymous
        "motive")
      (psKernelCloseOpenBinders
        indices
        (psKernelMkArrow
          inductExpr
          (PsKernelExpr.sort
            elimLevel)))
      PsKernelBinderInfo.default;
  let minorBinders :=
    psKernelMakeSimpleMinorBinders
      motive
      levels
      params
      shapes;
  let majorInternal :=
    psKernelSimpleInternalName
      "major";
  let major :=
    PsKernelExpr.fvar
      majorInternal;
  let majorBinder :=
    PsKernelOpenBinder.mk
      majorInternal
      (PsKernelName.str
        PsKernelName.anonymous
        "t")
      inductExpr
      PsKernelBinderInfo.default;
  let coreRuleBinders :=
    List.cons
      motiveBinder
      minorBinders;
  let ruleBinders :=
    psKernelOpenBinderListAppend
      params
      coreRuleBinders;
  let recBinders :=
    psKernelOpenBinderListAppend
      ruleBinders
      (psKernelOpenBinderListAppend
        indices
        (List.cons
          majorBinder
          List.nil));
  let recTypeRaw :=
    psKernelCloseOpenBinders
      recBinders
      (psKernelSimpleMotiveApp
        motive
        indexArgs
        major);
  let recType :=
    psKernelExprInferImplicitAll
      recTypeRaw
      true;
  let recLevels :=
    psKernelLevelParamsToLevels
      recLevelParams;
  let rules :=
    psKernelMakeSimpleRecursorRules
      recName
      recLevels
      params
      motive
      minorBinders
      ruleBinders
      shapes
      minorBinders;
  let recInfo :=
    PsKernelRecursorInfo.mk
      (PsKernelConstantBase.mk
        recName
        recLevelParams
        recType)
      (List.cons
        decl.name
        List.nil)
      decl.numParams
      (psKernelOpenBinderListLength indices)
      1
      (psKernelOpenBinderListLength
        minorBinders)
      rules
      kTarget
      decl.isUnsafe;
  PsKernelOrdinaryRecursorPreparation.mk work1 recInfo motive ruleBinders

theorem psKernelOrdinaryPrepareRecursor_environment
    (decl : PsKernelSimpleInductiveDecl)
    (paramResult indexResult : PsKernelOpenBindersResult)
    (resultLevel : PsKernelLevel) (ctorResult : PsKernelAddConstructorsResult)
    (elimOnlyAtZero : Bool) :
    (psKernelOrdinaryPrepareRecursor decl paramResult indexResult resultLevel ctorResult
      elimOnlyAtZero).environment =
    psKernelOrdinaryConstructorFinalEnvironment decl paramResult indexResult ctorResult := rfl

theorem psKernelOrdinaryFinishAdmission_eq
    (fuel : Nat) (environment : PsKernelEnvironment)
    (decl : PsKernelSimpleInductiveDecl) (maxRecDepth maxNatSize : Nat)
    (paramResult indexResult : PsKernelOpenBindersResult)
    (resultLevel : PsKernelLevel) (ctorResult : PsKernelAddConstructorsResult) :
    psKernelOrdinaryFinishAdmission fuel environment decl maxRecDepth maxNatSize
      paramResult indexResult resultLevel ctorResult =
    match psKernelSimpleElimOnlyAtZero fuel
      (psKernelSessionWithEnvironment paramResult.session
        (psKernelOrdinaryConstructorFinalEnvironment decl paramResult indexResult ctorResult))
      paramResult.binders resultLevel decl.ctors with
    | Except.error error => Except.error error
    | Except.ok elimOnlyAtZero =>
        let prepared := psKernelOrdinaryPrepareRecursor decl paramResult indexResult
          resultLevel ctorResult elimOnlyAtZero;
        let safety := if decl.isUnsafe then PsKernelDefinitionSafety.unsafeDef
          else PsKernelDefinitionSafety.safe;
        let recSession := psKernelMkCheckerSession prepared.environment
          prepared.info.base.levelParams safety maxRecDepth maxNatSize;
        match psKernelSessionCheck fuel recSession prepared.info.base.type with
        | Except.error error => Except.error error
        | Except.ok checked =>
            match psKernelSessionEnsureSort fuel checked.2 checked.1 with
            | Except.error error => Except.error error
            | Except.ok _ =>
                let work2 := psKernelEnvironmentAddUnchecked prepared.environment
                  (PsKernelConstantInfo.recInfo prepared.info);
                let ruleSession := psKernelMkCheckerSession work2
                  prepared.info.base.levelParams safety maxRecDepth maxNatSize;
                match psKernelValidateSimpleRecursorRules fuel ruleSession paramResult.binders
                  prepared.ruleBinders prepared.motive (psKernelLevelParamsToLevels decl.levelParams)
                  ctorResult.shapes prepared.info.rules with
                | Except.error error => Except.error error
                | Except.ok _ => Except.ok work2 := rfl

def PsKernelOrdinaryRecursorSuffixValid
    (decl : PsKernelSimpleInductiveDecl) (params : List PsKernelOpenBinder)
    (shapes : List PsKernelSimpleConstructorShape)
    (prepared : PsKernelOrdinaryRecursorPreparation) (result : PsKernelEnvironment) : Prop :=
  result = psKernelEnvironmentAddUnchecked prepared.environment
    (PsKernelConstantInfo.recInfo prepared.info) ∧
  (∃ level : PsKernelLevel, PsKernelTypingJudgment prepared.environment psKernelLocalContextEmpty
    prepared.info.base.type (PsKernelExpr.sort level)) ∧
  PsKernelSimpleRecursorRulesTyped result psKernelLocalContextEmpty params
    prepared.ruleBinders prepared.motive (psKernelLevelParamsToLevels decl.levelParams)
    shapes prepared.info.rules ∧
  PsKernelSimpleRecursorRuleMetadataMatches shapes prepared.info.rules ∧
  PsKernelEnvironmentIndexRefines result

theorem psKernelOrdinaryPrepareRecursor_rule_metadata
    (decl : PsKernelSimpleInductiveDecl)
    (paramResult indexResult : PsKernelOpenBindersResult)
    (resultLevel : PsKernelLevel) (ctorResult : PsKernelAddConstructorsResult)
    (elimOnlyAtZero : Bool) :
    let prepared := psKernelOrdinaryPrepareRecursor decl paramResult indexResult
      resultLevel ctorResult elimOnlyAtZero;
    PsKernelSimpleRecursorRuleMetadataMatches ctorResult.shapes prepared.info.rules := by
  let prepared := psKernelOrdinaryPrepareRecursor decl paramResult indexResult
    resultLevel ctorResult elimOnlyAtZero
  have hMetadata := psKernelMakeSimpleRecursorRules_generated_minor_metadata
    (psKernelSimpleRecName decl.name) (psKernelLevelParamsToLevels prepared.info.base.levelParams)
    paramResult.binders prepared.motive (psKernelLevelParamsToLevels decl.levelParams)
    prepared.ruleBinders ctorResult.shapes
  simpa [prepared, psKernelOrdinaryPrepareRecursor] using hMetadata

/--
Checked recursor type and rule publication from the exact successful suffix.
The incoming work-index premise is discharged by constructor-history metadata
replacement when composing the full ordinary transaction.
-/
theorem psKernelOrdinaryFinishAdmission_success_recursor_semantics
    (fuel : Nat) (environment result : PsKernelEnvironment)
    (decl : PsKernelSimpleInductiveDecl) (maxRecDepth maxNatSize : Nat)
    (paramResult indexResult : PsKernelOpenBindersResult)
    (resultLevel : PsKernelLevel) (ctorResult : PsKernelAddConstructorsResult)
    (hIndex : PsKernelEnvironmentIndexRefines
      (psKernelOrdinaryConstructorFinalEnvironment decl paramResult indexResult ctorResult))
    (hNative : PsKernelNativeReductionSoundLaw)
    (hString : PsKernelStringEqSoundLaw)
    (hRun : psKernelOrdinaryFinishAdmission fuel environment decl maxRecDepth maxNatSize
      paramResult indexResult resultLevel ctorResult = Except.ok result) :
    ∃ elimOnlyAtZero : Bool,
      psKernelSimpleElimOnlyAtZero fuel
        (psKernelSessionWithEnvironment paramResult.session
          (psKernelOrdinaryConstructorFinalEnvironment decl paramResult indexResult ctorResult))
        paramResult.binders resultLevel decl.ctors = Except.ok elimOnlyAtZero ∧
      PsKernelOrdinaryRecursorSuffixValid decl paramResult.binders ctorResult.shapes
        (psKernelOrdinaryPrepareRecursor decl paramResult indexResult resultLevel ctorResult
          elimOnlyAtZero) result := by
  rw [psKernelOrdinaryFinishAdmission_eq] at hRun
  cases hElim : psKernelSimpleElimOnlyAtZero fuel
      (psKernelSessionWithEnvironment paramResult.session
        (psKernelOrdinaryConstructorFinalEnvironment decl paramResult indexResult ctorResult))
      paramResult.binders resultLevel decl.ctors with
  | error message => simp only [hElim] at hRun; cases hRun
  | ok elimOnlyAtZero =>
      simp only [hElim] at hRun
      let prepared := psKernelOrdinaryPrepareRecursor decl paramResult indexResult
        resultLevel ctorResult elimOnlyAtZero
      let safety := if decl.isUnsafe then PsKernelDefinitionSafety.unsafeDef
        else PsKernelDefinitionSafety.safe
      let recSession := psKernelMkCheckerSession prepared.environment
        prepared.info.base.levelParams safety maxRecDepth maxNatSize
      have hPreparedIndex : PsKernelEnvironmentIndexRefines prepared.environment := by
        simpa [prepared, psKernelOrdinaryPrepareRecursor_environment] using hIndex
      have hInitial := psKernelMkCheckerSession_configuration_sound prepared.environment
        prepared.info.base.levelParams safety maxRecDepth maxNatSize hPreparedIndex
      change (match psKernelSessionCheck fuel recSession prepared.info.base.type with
        | Except.error error => Except.error error
        | Except.ok checked =>
            match psKernelSessionEnsureSort fuel checked.2 checked.1 with
            | Except.error error => Except.error error
            | Except.ok _ =>
                let work2 := psKernelEnvironmentAddUnchecked prepared.environment
                  (PsKernelConstantInfo.recInfo prepared.info);
                let ruleSession := psKernelMkCheckerSession work2
                  prepared.info.base.levelParams safety maxRecDepth maxNatSize;
                match psKernelValidateSimpleRecursorRules fuel ruleSession paramResult.binders
                  prepared.ruleBinders prepared.motive (psKernelLevelParamsToLevels decl.levelParams)
                  ctorResult.shapes prepared.info.rules with
                | Except.error error => Except.error error
                | Except.ok _ => Except.ok work2) = Except.ok result at hRun
      cases hCheck : psKernelSessionCheck fuel recSession prepared.info.base.type with
      | error message => simp only [hCheck] at hRun; cases hRun
      | ok checked =>
          simp only [hCheck] at hRun
          have hTyped := psKernelSessionCheck_concrete_refines_typing
            fuel hNative hString recSession checked.2 prepared.info.base.type checked.1 hInitial hCheck
          have hContext := psKernelSessionCheck_success_preserves_context_core
            fuel recSession checked.2 prepared.info.base.type checked.1 hCheck
          have hCheckedConfig : PsKernelCheckerConfigurationSound checked.2.context checked.2.state := by
            simpa [hContext] using hTyped.2
          cases hSort : psKernelSessionEnsureSort fuel checked.2 checked.1 with
          | error message => simp only [hSort] at hRun; cases hRun
          | ok sorted =>
              simp only [hSort] at hRun
              have hReduced := psKernelSessionEnsureSort_concrete_refines_reduction
                fuel hNative hString checked.2 sorted.2 checked.1 sorted.1 hCheckedConfig hSort
              let work2 := psKernelEnvironmentAddUnchecked prepared.environment
                (PsKernelConstantInfo.recInfo prepared.info)
              let ruleSession := psKernelMkCheckerSession work2
                prepared.info.base.levelParams safety maxRecDepth maxNatSize
              have hWorkIndex := psKernelEnvironmentAddUnchecked_index_refines
                prepared.environment (PsKernelConstantInfo.recInfo prepared.info) hPreparedIndex
              have hRuleConfig := psKernelMkCheckerSession_configuration_sound work2
                prepared.info.base.levelParams safety maxRecDepth maxNatSize hWorkIndex
              cases hRules : psKernelValidateSimpleRecursorRules fuel ruleSession
                  paramResult.binders prepared.ruleBinders prepared.motive
                  (psKernelLevelParamsToLevels decl.levelParams) ctorResult.shapes prepared.info.rules with
              | error message => simp only [hRules] at hRun; cases hRun
              | ok checkedRules =>
                  cases checkedRules
                  simp only [hRules] at hRun
                  have hPublication : result = work2 := (Except.ok.inj hRun).symm
                  subst result
                  refine ⟨elimOnlyAtZero, hElim, rfl, ⟨sorted.1, ?_⟩, ?_,
                    psKernelOrdinaryPrepareRecursor_rule_metadata decl paramResult indexResult
                      resultLevel ctorResult elimOnlyAtZero, hWorkIndex⟩
                  · apply PsKernelTypingJudgment.convert prepared.info.base.type checked.1
                      (PsKernelExpr.sort sorted.1)
                    · simpa [recSession, psKernelMkCheckerSession,
                        psKernelCheckerContextEmpty] using hTyped.1
                    · apply PsKernelDefEqJudgment.reductionClosure
                      simpa [hContext, recSession, psKernelMkCheckerSession,
                        psKernelCheckerContextEmpty] using hReduced.1
                  · have hRuleTyped := psKernelValidateSimpleRecursorRules_independent_typing
                      fuel ruleSession paramResult.binders prepared.ruleBinders prepared.motive
                      (psKernelLevelParamsToLevels decl.levelParams) ctorResult.shapes prepared.info.rules
                      hRuleConfig hNative hString hRules
                    simpa [ruleSession, psKernelMkCheckerSession,
                      psKernelCheckerContextEmpty] using hRuleTyped
