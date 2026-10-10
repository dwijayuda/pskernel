import Ps.KernelCore.Metatheory.ContextState
import Ps.KernelCore.Admission.Inductive.Ordinary.Constructor

/--
Lookup-preserving extension of the authoritative semantic environment.
Previously resolved constants retain exactly their information, and
initialized quotient semantics remain enabled. Replacement of existing
metadata requires a different relation and is not silently allowed here.
-/
def PsKernelEnvironmentSemanticExtends
    (older newer : PsKernelEnvironment) : Prop :=
  (∀ (name : PsKernelName) (info : PsKernelConstantInfo),
    psKernelFindConstantInList name older.constants = some info ->
      psKernelFindConstantInList name newer.constants = some info) ∧
  (older.quotInitialized = true -> newer.quotInitialized = true)

theorem PsKernelEnvironmentSemanticExtends.refl
    (environment : PsKernelEnvironment) :
    PsKernelEnvironmentSemanticExtends environment environment :=
  ⟨fun _ _ h => h, fun h => h⟩

theorem PsKernelEnvironmentSemanticExtends.trans
    (first second third : PsKernelEnvironment)
    (hFirst : PsKernelEnvironmentSemanticExtends first second)
    (hSecond : PsKernelEnvironmentSemanticExtends second third) :
    PsKernelEnvironmentSemanticExtends first third :=
  ⟨fun name info h => hSecond.1 name info (hFirst.1 name info h),
    fun h => hSecond.2 (hFirst.2 h)⟩

theorem PsKernelReductionStep.environment_weaken
    (sourceEnvironment targetEnvironment : PsKernelEnvironment)
    (hExt : PsKernelEnvironmentSemanticExtends sourceEnvironment targetEnvironment)
    {localContext : PsKernelLocalContext}
    {left right : PsKernelExpr}
    (h : PsKernelReductionStep sourceEnvironment localContext left right) :
    PsKernelReductionStep targetEnvironment localContext left right := by
  cases h <;> constructor <;> try assumption
  all_goals
    apply hExt.1 <;> assumption


theorem psKernelEnvironmentIsNonRecStructure_environment_weaken
    (older newer : PsKernelEnvironment)
    (hExt : PsKernelEnvironmentSemanticExtends older newer)
    (hOlderIndex : PsKernelEnvironmentIndexRefines older)
    (hNewerIndex : PsKernelEnvironmentIndexRefines newer)
    (name : PsKernelName)
    (hNonRec : psKernelEnvironmentIsNonRecStructure older name = true) :
    psKernelEnvironmentIsNonRecStructure newer name = true := by
  cases hFind : psKernelEnvironmentFind older name with
  | none =>
      simp [psKernelEnvironmentIsNonRecStructure, hFind] at hNonRec
  | some info =>
      have hCanonical : psKernelFindConstantInList name older.constants = some info := by
        calc
          psKernelFindConstantInList name older.constants =
              psKernelEnvironmentFind older name := by
                simpa [psKernelEnvironmentFind] using (hOlderIndex name).symm
          _ = some info := hFind
      have hNewFind : psKernelEnvironmentFind newer name = some info := by
        calc
          psKernelEnvironmentFind newer name =
              psKernelFindConstantInList name newer.constants := by
                simpa [psKernelEnvironmentFind] using hNewerIndex name
          _ = some info := hExt.1 name info hCanonical
      simpa [psKernelEnvironmentIsNonRecStructure, hFind, hNewFind] using hNonRec

/--
Joint induction over the existing semantic derivations. The tactic packages
all ten recursor motives and their checked constructor reconstructions; it
adds no judgment constructor and no trusted proof premise.
-/
syntax "ps_kernel_environment_transport " term ", " term ", " term ", "
  term ", " term ", " term ", " term : tactic

macro_rules
  | `(tactic| ps_kernel_environment_transport $recursor:term, $source:term,
      $target:term, $extension:term, $sourceIndex:term, $targetIndex:term,
      $major:term) =>
    `(tactic|
      exact $recursor
        (environment := $source)
        (motive_1 := fun localContext left right _ =>
          PsKernelReductionClosure $target localContext left right)
        (motive_2 := fun localContext left right _ =>
          PsKernelDefEqJudgment $target localContext left right)
        (motive_3 := fun localContext name value args index count _ =>
          PsKernelStructureEtaCompareJudgment $target localContext name value args index count)
        (motive_4 := fun localContext left right args _ =>
          PsKernelBinderDomainJudgment $target localContext left right args)
        (motive_5 := fun localContext left right args _ =>
          PsKernelLambdaSpineJudgment $target localContext left right args)
        (motive_6 := fun localContext left right args _ =>
          PsKernelForallSpineJudgment $target localContext left right args)
        (motive_7 := fun localContext args index count type result _ =>
          PsKernelProjectionApplyParamsJudgment $target localContext args index count type result)
        (motive_8 := fun localContext name value index count type result _ =>
          PsKernelProjectionSkipFieldsJudgment $target localContext name value index count type result)
        (motive_9 := fun localContext name index value type result _ =>
          PsKernelProjectionResultJudgment $target localContext name index value type result)
        (motive_10 := fun localContext expr type _ =>
          PsKernelTypingJudgment $target localContext expr type)
        (fun {localContext} expr =>
          PsKernelReductionClosure.refl
            expr)
        (fun {older} {newer} left right hExt hReduction ih_hReduction =>
          PsKernelReductionClosure.contextWeaken
            left right hExt ih_hReduction)
        (fun {localContext} source query result hPresentation hReduction ih_hReduction =>
          PsKernelReductionClosure.presentationSource
            source query result hPresentation ih_hReduction)
        (fun {localContext} left middle right hStep hRest ih_hRest =>
          PsKernelReductionClosure.cons
            left middle right (PsKernelReductionStep.environment_weaken $source $target $extension hStep) ih_hRest)
        (fun {localContext} left middle right hLeft hRight ih_hLeft ih_hRight =>
          PsKernelReductionClosure.trans
            left middle right ih_hLeft ih_hRight)
        (fun {localContext} leftFn rightFn arg hFn ih_hFn =>
          PsKernelReductionClosure.appFn
            leftFn rightFn arg ih_hFn)
        (fun {localContext} fn leftArg rightArg hArg ih_hArg =>
          PsKernelReductionClosure.appArg
            fn leftArg rightArg ih_hArg)
        (fun {localContext} typeName index left right hMajor ih_hMajor =>
          PsKernelReductionClosure.projectionMajor
            typeName index left right ih_hMajor)
        (fun {localContext} expr fnName mkName levels mkLevels args mkArgs major majorReduced representative fnValue hInitialized hHead hLift hArgs hMajor hMajorReduction hMkHead hMk hMkArity hMkArgs hRepresentative hFnValue ih_hMajorReduction =>
          PsKernelReductionClosure.quotLift
            expr fnName mkName levels mkLevels args mkArgs major majorReduced representative fnValue (($extension).2 hInitialized) hHead hLift hArgs hMajor ih_hMajorReduction hMkHead hMk hMkArity hMkArgs hRepresentative hFnValue)
        (fun {localContext} expr fnName mkName levels mkLevels args mkArgs major majorReduced representative fnValue hInitialized hHead hInd hArgs hMajor hMajorReduction hMkHead hMk hMkArity hMkArgs hRepresentative hFnValue ih_hMajorReduction =>
          PsKernelReductionClosure.quotInd
            expr fnName mkName levels mkLevels args mkArgs major majorReduced representative fnValue (($extension).2 hInitialized) hHead hInd hArgs hMajor ih_hMajorReduction hMkHead hMk hMkArity hMkArgs hRepresentative hFnValue)
        (fun {localContext} expr recName ctorName recLevels ctorLevels recArgs majorArgs recursor rule major0 majorK majorReduced semanticReduced major hHead hArgs hFind hMajor hKConversion hMajorReduction hNormalizeConversion hNormalize hCtorHead hMajorArgs hRuleMem hRuleCtor hFields hLevels ih_hKConversion ih_hMajorReduction ih_hNormalizeConversion =>
          PsKernelReductionClosure.recursorIota
            expr recName ctorName recLevels ctorLevels recArgs majorArgs recursor rule major0 majorK majorReduced semanticReduced major hHead hArgs (($extension).1 _ _ hFind) hMajor ih_hKConversion ih_hMajorReduction ih_hNormalizeConversion hNormalize hCtorHead hMajorArgs hRuleMem hRuleCtor hFields hLevels)
        (fun {localContext} expr =>
          PsKernelDefEqJudgment.refl
            expr)
        (fun {older} {newer} left right hExt hDefEq ih_hDefEq =>
          PsKernelDefEqJudgment.contextWeaken
            left right hExt ih_hDefEq)
        (fun {localContext} left right h ih_h =>
          PsKernelDefEqJudgment.symm
            left right ih_h)
        (fun {localContext} storedLeft storedRight queryLeft queryRight hLeft hStored hRight ih_hStored =>
          PsKernelDefEqJudgment.presentation
            storedLeft storedRight queryLeft queryRight hLeft ih_hStored hRight)
        (fun {localContext} left right h =>
          PsKernelDefEqJudgment.structural
            left right h)
        (fun {localContext} left right h =>
          PsKernelDefEqJudgment.reduction
            left right (PsKernelReductionStep.environment_weaken $source $target $extension h))
        (fun {localContext} left right h ih_h =>
          PsKernelDefEqJudgment.reductionClosure
            left right ih_h)
        (fun {localContext} left right h =>
          PsKernelDefEqJudgment.sort
            left right h)
        (fun {localContext} left right h =>
          PsKernelDefEqJudgment.literal
            left right h)
        (fun {localContext} leftFn leftArg rightFn rightArg hFn hArg ih_hFn ih_hArg =>
          PsKernelDefEqJudgment.app
            leftFn leftArg rightFn rightArg ih_hFn ih_hArg)
        (fun {localContext} name leftLevels rightLevels hLevels =>
          PsKernelDefEqJudgment.constLevels
            name leftLevels rightLevels hLevels)
        (fun {localContext} left right leftPred rightPred hLeft hRight hPred ih_hPred =>
          PsKernelDefEqJudgment.natSuccessorPred
            left right leftPred rightPred hLeft hRight ih_hPred)
        (fun {localContext} typeName index left right hMajor ih_hMajor =>
          PsKernelDefEqJudgment.projection
            typeName index left right ih_hMajor)
        (fun {localContext} left right leftReduced rightReduced hLeft hRight hCore ih_hLeft ih_hRight ih_hCore =>
          PsKernelDefEqJudgment.reduceCompare
            left right leftReduced rightReduced ih_hLeft ih_hRight ih_hCore)
        (fun {localContext} lambdaValue other name domain body binderInfo hCompare ih_hCompare =>
          PsKernelDefEqJudgment.functionEtaLeft
            lambdaValue other name domain body binderInfo ih_hCompare)
        (fun {localContext} other lambdaValue name domain body binderInfo hCompare ih_hCompare =>
          PsKernelDefEqJudgment.functionEtaRight
            other lambdaValue name domain body binderInfo ih_hCompare)
        (fun {localContext} left right leftType rightType leftTypeType level hLeftTypeTypeProp hProp hTypes ih_hLeftTypeTypeProp ih_hTypes =>
          PsKernelDefEqJudgment.proofIrrelevanceAlgorithmic
            left right leftType rightType leftTypeType level ih_hLeftTypeTypeProp hProp ih_hTypes)
        (fun {localContext} left right leftType rightType reducedType inductName ctorName inductInfo ctorInfo hTypeReduction hTypeHead hNonRec hInduct hCtors hCtor hNoFields hTypes ih_hTypeReduction ih_hTypes =>
          PsKernelDefEqJudgment.unitLike
            left right leftType rightType reducedType inductName ctorName inductInfo ctorInfo ih_hTypeReduction hTypeHead (psKernelEnvironmentIsNonRecStructure_environment_weaken $source $target $extension $sourceIndex $targetIndex _ hNonRec) (($extension).1 _ _ hInduct) hCtors (($extension).1 _ _ hCtor) hNoFields ih_hTypes)
        (fun {localContext} term structureValue termType structureType ctorName levels ctorInfo hHead hCtor hArity hNonRec hTypes hFields ih_hTypes ih_hFields =>
          PsKernelDefEqJudgment.structureEtaAlgorithmic
            term structureValue termType structureType ctorName levels ctorInfo hHead (($extension).1 _ _ hCtor) hArity (psKernelEnvironmentIsNonRecStructure_environment_weaken $source $target $extension $sourceIndex $targetIndex _ hNonRec) ih_hTypes ih_hFields)
        (fun {localContext} left right h ih_h =>
          PsKernelDefEqJudgment.lambdaSpine
            left right ih_h)
        (fun {localContext} left right h ih_h =>
          PsKernelDefEqJudgment.forallSpine
            left right ih_h)
        (fun {localContext} recursor major appType candidate candidateType majorInduct typeInduct ctorName typeLevels indices params inductInfo ctorRest hK hMajorInduct hTypeHead hTypeInduct hIndices hNoUnresolvedIndex hInduct hCtors hParams hParamCount hCandidate hTypeDefEq ih_hTypeDefEq =>
          PsKernelDefEqJudgment.recursorKConversion
            recursor major appType candidate candidateType majorInduct typeInduct ctorName typeLevels indices params inductInfo ctorRest hK hMajorInduct hTypeHead hTypeInduct hIndices hNoUnresolvedIndex (($extension).1 _ _ hInduct) hCtors hParams hParamCount hCandidate ih_hTypeDefEq)
        (fun {localContext} major majorType etaValue inductName typeName ctorName levels typeArgs params fields inductInfo ctorInfo hNonRecStructure hTypeHead hTypeName hTypeArgs hInduct hCtors hCtor hParamBound hParams hFields hEta =>
          PsKernelDefEqJudgment.recursorStructureEta
            major majorType etaValue inductName typeName ctorName levels typeArgs params fields inductInfo ctorInfo (psKernelEnvironmentIsNonRecStructure_environment_weaken $source $target $extension $sourceIndex $targetIndex _ hNonRecStructure) hTypeHead hTypeName hTypeArgs (($extension).1 _ _ hInduct) hCtors (($extension).1 _ _ hCtor) hParamBound hParams hFields hEta)
        (fun {localContext} left right leftType rightType level hLeft hRight hLeftType hProp hTypes ih_hLeft ih_hRight ih_hLeftType ih_hTypes =>
          PsKernelDefEqJudgment.proofIrrelevance
            left right leftType rightType level ih_hLeft ih_hRight ih_hLeftType hProp ih_hTypes)
        (fun {localContext} value valueType etaValue inductName ctorName levels typeArgs params fields inductInfo ctorInfo hValue hTypeHead hTypeArgs hInduct hNonRec hNoIndices hCtors hCtor hCtorInduct hParams hFields hEta ih_hValue =>
          PsKernelDefEqJudgment.structureEta
            value valueType etaValue inductName ctorName levels typeArgs params fields inductInfo ctorInfo ih_hValue hTypeHead hTypeArgs (($extension).1 _ _ hInduct) hNonRec hNoIndices hCtors (($extension).1 _ _ hCtor) hCtorInduct hParams hFields hEta)
        (fun {localContext} metadata left right h ih_h =>
          PsKernelDefEqJudgment.metadataLeft
            metadata left right ih_h)
        (fun {localContext} metadata left right h ih_h =>
          PsKernelDefEqJudgment.metadataRight
            metadata left right ih_h)
        (fun {localContext} induct term args numParams index hDone =>
          PsKernelStructureEtaCompareJudgment.done
            induct term args numParams index hDone)
        (fun {localContext} induct term args numParams index arg hMore hArg hField hRest ih_hField ih_hRest =>
          PsKernelStructureEtaCompareJudgment.step
            induct term args numParams index arg hMore hArg ih_hField ih_hRest)
        (fun {localContext} leftDomain rightDomain subst hEq =>
          PsKernelBinderDomainJudgment.structural
            leftDomain rightDomain subst hEq)
        (fun {localContext} leftDomain rightDomain subst hDefEq ih_hDefEq =>
          PsKernelBinderDomainJudgment.defeq
            leftDomain rightDomain subst ih_hDefEq)
        (fun {localContext} left right subst hCore ih_hCore =>
          PsKernelLambdaSpineJudgment.terminal
            left right subst ih_hCore)
        (fun {localContext} leftName rightName fresh leftDomain rightDomain leftBody rightBody leftInfo rightInfo subst hDomain hDependent hFresh hRest ih_hDomain ih_hRest =>
          PsKernelLambdaSpineJudgment.stepOpen
            leftName rightName fresh leftDomain rightDomain leftBody rightBody leftInfo rightInfo subst ih_hDomain hDependent hFresh ih_hRest)
        (fun {localContext} leftName rightName leftDomain rightDomain leftBody rightBody leftInfo rightInfo subst hDomain hLeftClosed hRightClosed hRest ih_hDomain ih_hRest =>
          PsKernelLambdaSpineJudgment.stepClosed
            leftName rightName leftDomain rightDomain leftBody rightBody leftInfo rightInfo subst ih_hDomain hLeftClosed hRightClosed ih_hRest)
        (fun {localContext} left right subst hCore ih_hCore =>
          PsKernelForallSpineJudgment.terminal
            left right subst ih_hCore)
        (fun {localContext} leftName rightName fresh leftDomain rightDomain leftBody rightBody leftInfo rightInfo subst hDomain hDependent hFresh hRest ih_hDomain ih_hRest =>
          PsKernelForallSpineJudgment.stepOpen
            leftName rightName fresh leftDomain rightDomain leftBody rightBody leftInfo rightInfo subst ih_hDomain hDependent hFresh ih_hRest)
        (fun {localContext} leftName rightName leftDomain rightDomain leftBody rightBody leftInfo rightInfo subst hDomain hLeftClosed hRightClosed hRest ih_hDomain ih_hRest =>
          PsKernelForallSpineJudgment.stepClosed
            leftName rightName leftDomain rightDomain leftBody rightBody leftInfo rightInfo subst ih_hDomain hLeftClosed hRightClosed ih_hRest)
        (fun {localContext} {args} index numParams current hDone =>
          PsKernelProjectionApplyParamsJudgment.done
            index numParams current hDone)
        (fun {localContext} {args} index numParams current domain body result argument name binderInfo hMore hWhnf hArg hRest ih_hWhnf ih_hRest =>
          PsKernelProjectionApplyParamsJudgment.step
            index numParams current domain body result argument name binderInfo hMore ih_hWhnf hArg ih_hRest)
        (fun {localContext} {inductName} {structValue} {targetIndex} index current hDone =>
          PsKernelProjectionSkipFieldsJudgment.done
            index current hDone)
        (fun {localContext} {inductName} {structValue} {targetIndex} index current domain body result name binderInfo hMore hWhnf hClosed hRest ih_hWhnf ih_hRest =>
          PsKernelProjectionSkipFieldsJudgment.stepClosed
            index current domain body result name binderInfo hMore ih_hWhnf hClosed ih_hRest)
        (fun {localContext} {inductName} {structValue} {targetIndex} index current domain body result name binderInfo hMore hWhnf hDependent hRest ih_hWhnf ih_hRest =>
          PsKernelProjectionSkipFieldsJudgment.stepDependent
            index current domain body result name binderInfo hMore ih_hWhnf hDependent ih_hRest)
        (fun {localContext} typeName inductName ctorName fieldName index structValue structType typeWhnf inductLevels args inductInfo ctorInfo initial afterParams afterFields fieldBody result fieldBinderInfo hTypeWhnf hTypeFn hTypeArgs hIndexBound hTypeName hInduct hCtors hArgsLength hCtor hInitial hParams hFields hFinal ih_hTypeWhnf ih_hParams ih_hFields ih_hFinal =>
          PsKernelProjectionResultJudgment.intro
            typeName inductName ctorName fieldName index structValue structType typeWhnf inductLevels args inductInfo ctorInfo initial afterParams afterFields fieldBody result fieldBinderInfo ih_hTypeWhnf hTypeFn hTypeArgs hIndexBound hTypeName (($extension).1 _ _ hInduct) hCtors hArgsLength (($extension).1 _ _ hCtor) hInitial ih_hParams ih_hFields ih_hFinal)
        (fun {localContext} storedExpr queryExpr result hExpr hStored ih_hStored =>
          PsKernelTypingJudgment.presentation
            storedExpr queryExpr result hExpr ih_hStored)
        (fun {older} {newer} expr result hExt hTyping ih_hTyping =>
          PsKernelTypingJudgment.contextWeaken
            expr result hExt ih_hTyping)
        (fun {localContext} expr inferred expected hTyping hConvert ih_hTyping ih_hConvert =>
          PsKernelTypingJudgment.convert
            expr inferred expected ih_hTyping ih_hConvert)
        (fun {localContext} level =>
          PsKernelTypingJudgment.sort
            level)
        (fun {localContext} value =>
          PsKernelTypingJudgment.natLiteral
            value)
        (fun {localContext} value =>
          PsKernelTypingJudgment.stringLiteral
            value)
        (fun {localContext} name declaration hFind =>
          PsKernelTypingJudgment.fvar
            name declaration hFind)
        (fun {localContext} name levels info hFind hLevels =>
          PsKernelTypingJudgment.const
            name levels info (($extension).1 _ _ hFind) hLevels)
        (fun {localContext} fn arg fnType argType domain body name binderInfo hFn hFnType hArg hArgType ih_hFn ih_hFnType ih_hArg ih_hArgType =>
          PsKernelTypingJudgment.app
            fn arg fnType argType domain body name binderInfo ih_hFn ih_hFnType ih_hArg ih_hArgType)
        (fun {localContext} name fresh domain body bodyType binderInfo domainLevel hFresh hDomain hBody ih_hDomain ih_hBody =>
          PsKernelTypingJudgment.lam
            name fresh domain body bodyType binderInfo domainLevel hFresh ih_hDomain ih_hBody)
        (fun {localContext} name fresh domain body binderInfo domainLevel bodyLevel hFresh hDomain hBody ih_hDomain ih_hBody =>
          PsKernelTypingJudgment.forallE
            name fresh domain body binderInfo domainLevel bodyLevel hFresh ih_hDomain ih_hBody)
        (fun {localContext} name fresh type value body valueType bodyType nondep typeLevel hFresh hType hValue hValueType hBody ih_hType ih_hValue ih_hValueType ih_hBody =>
          PsKernelTypingJudgment.letE
            name fresh type value body valueType bodyType nondep typeLevel hFresh ih_hType ih_hValue ih_hValueType ih_hBody)
        (fun {localContext} metadata body bodyType hBody ih_hBody =>
          PsKernelTypingJudgment.mdata
            metadata body bodyType ih_hBody)
        (fun {localContext} typeName index structValue structType result hStruct hProjection ih_hStruct ih_hProjection =>
          PsKernelTypingJudgment.proj
            typeName index structValue structType result ih_hStruct ih_hProjection)
        $major)


theorem PsKernelReductionClosure.environment_weaken
    (sourceEnvironment targetEnvironment : PsKernelEnvironment)
    (hExt : PsKernelEnvironmentSemanticExtends sourceEnvironment targetEnvironment)
    (hSourceIndex : PsKernelEnvironmentIndexRefines sourceEnvironment)
    (hTargetIndex : PsKernelEnvironmentIndexRefines targetEnvironment)
    {localContext : PsKernelLocalContext}
    {left right : PsKernelExpr}
    (h : PsKernelReductionClosure sourceEnvironment localContext left right) :
    PsKernelReductionClosure targetEnvironment localContext left right := by
  ps_kernel_environment_transport PsKernelReductionClosure.rec, sourceEnvironment, targetEnvironment,
    hExt, hSourceIndex, hTargetIndex, h

theorem PsKernelDefEqJudgment.environment_weaken
    (sourceEnvironment targetEnvironment : PsKernelEnvironment)
    (hExt : PsKernelEnvironmentSemanticExtends sourceEnvironment targetEnvironment)
    (hSourceIndex : PsKernelEnvironmentIndexRefines sourceEnvironment)
    (hTargetIndex : PsKernelEnvironmentIndexRefines targetEnvironment)
    {localContext : PsKernelLocalContext}
    {left right : PsKernelExpr}
    (h : PsKernelDefEqJudgment sourceEnvironment localContext left right) :
    PsKernelDefEqJudgment targetEnvironment localContext left right := by
  ps_kernel_environment_transport PsKernelDefEqJudgment.rec, sourceEnvironment, targetEnvironment,
    hExt, hSourceIndex, hTargetIndex, h

theorem PsKernelStructureEtaCompareJudgment.environment_weaken
    (sourceEnvironment targetEnvironment : PsKernelEnvironment)
    (hExt : PsKernelEnvironmentSemanticExtends sourceEnvironment targetEnvironment)
    (hSourceIndex : PsKernelEnvironmentIndexRefines sourceEnvironment)
    (hTargetIndex : PsKernelEnvironmentIndexRefines targetEnvironment)
    {localContext : PsKernelLocalContext}
    {name : PsKernelName}
    {value : PsKernelExpr}
    {args : List PsKernelExpr}
    {index count : Nat}
    (h : PsKernelStructureEtaCompareJudgment sourceEnvironment localContext name value args index count) :
    PsKernelStructureEtaCompareJudgment targetEnvironment localContext name value args index count := by
  ps_kernel_environment_transport PsKernelStructureEtaCompareJudgment.rec, sourceEnvironment, targetEnvironment,
    hExt, hSourceIndex, hTargetIndex, h

theorem PsKernelBinderDomainJudgment.environment_weaken
    (sourceEnvironment targetEnvironment : PsKernelEnvironment)
    (hExt : PsKernelEnvironmentSemanticExtends sourceEnvironment targetEnvironment)
    (hSourceIndex : PsKernelEnvironmentIndexRefines sourceEnvironment)
    (hTargetIndex : PsKernelEnvironmentIndexRefines targetEnvironment)
    {localContext : PsKernelLocalContext}
    {left right : PsKernelExpr}
    {args : List PsKernelExpr}
    (h : PsKernelBinderDomainJudgment sourceEnvironment localContext left right args) :
    PsKernelBinderDomainJudgment targetEnvironment localContext left right args := by
  ps_kernel_environment_transport PsKernelBinderDomainJudgment.rec, sourceEnvironment, targetEnvironment,
    hExt, hSourceIndex, hTargetIndex, h

theorem PsKernelLambdaSpineJudgment.environment_weaken
    (sourceEnvironment targetEnvironment : PsKernelEnvironment)
    (hExt : PsKernelEnvironmentSemanticExtends sourceEnvironment targetEnvironment)
    (hSourceIndex : PsKernelEnvironmentIndexRefines sourceEnvironment)
    (hTargetIndex : PsKernelEnvironmentIndexRefines targetEnvironment)
    {localContext : PsKernelLocalContext}
    {left right : PsKernelExpr}
    {args : List PsKernelExpr}
    (h : PsKernelLambdaSpineJudgment sourceEnvironment localContext left right args) :
    PsKernelLambdaSpineJudgment targetEnvironment localContext left right args := by
  ps_kernel_environment_transport PsKernelLambdaSpineJudgment.rec, sourceEnvironment, targetEnvironment,
    hExt, hSourceIndex, hTargetIndex, h

theorem PsKernelForallSpineJudgment.environment_weaken
    (sourceEnvironment targetEnvironment : PsKernelEnvironment)
    (hExt : PsKernelEnvironmentSemanticExtends sourceEnvironment targetEnvironment)
    (hSourceIndex : PsKernelEnvironmentIndexRefines sourceEnvironment)
    (hTargetIndex : PsKernelEnvironmentIndexRefines targetEnvironment)
    {localContext : PsKernelLocalContext}
    {left right : PsKernelExpr}
    {args : List PsKernelExpr}
    (h : PsKernelForallSpineJudgment sourceEnvironment localContext left right args) :
    PsKernelForallSpineJudgment targetEnvironment localContext left right args := by
  ps_kernel_environment_transport PsKernelForallSpineJudgment.rec, sourceEnvironment, targetEnvironment,
    hExt, hSourceIndex, hTargetIndex, h

theorem PsKernelProjectionApplyParamsJudgment.environment_weaken
    (sourceEnvironment targetEnvironment : PsKernelEnvironment)
    (hExt : PsKernelEnvironmentSemanticExtends sourceEnvironment targetEnvironment)
    (hSourceIndex : PsKernelEnvironmentIndexRefines sourceEnvironment)
    (hTargetIndex : PsKernelEnvironmentIndexRefines targetEnvironment)
    {localContext : PsKernelLocalContext}
    {args : List PsKernelExpr}
    {index count : Nat}
    {type result : PsKernelExpr}
    (h : PsKernelProjectionApplyParamsJudgment sourceEnvironment localContext args index count type result) :
    PsKernelProjectionApplyParamsJudgment targetEnvironment localContext args index count type result := by
  ps_kernel_environment_transport PsKernelProjectionApplyParamsJudgment.rec, sourceEnvironment, targetEnvironment,
    hExt, hSourceIndex, hTargetIndex, h

theorem PsKernelProjectionSkipFieldsJudgment.environment_weaken
    (sourceEnvironment targetEnvironment : PsKernelEnvironment)
    (hExt : PsKernelEnvironmentSemanticExtends sourceEnvironment targetEnvironment)
    (hSourceIndex : PsKernelEnvironmentIndexRefines sourceEnvironment)
    (hTargetIndex : PsKernelEnvironmentIndexRefines targetEnvironment)
    {localContext : PsKernelLocalContext}
    {name : PsKernelName}
    {value : PsKernelExpr}
    {index count : Nat}
    {type result : PsKernelExpr}
    (h : PsKernelProjectionSkipFieldsJudgment sourceEnvironment localContext name value index count type result) :
    PsKernelProjectionSkipFieldsJudgment targetEnvironment localContext name value index count type result := by
  ps_kernel_environment_transport PsKernelProjectionSkipFieldsJudgment.rec, sourceEnvironment, targetEnvironment,
    hExt, hSourceIndex, hTargetIndex, h

theorem PsKernelProjectionResultJudgment.environment_weaken
    (sourceEnvironment targetEnvironment : PsKernelEnvironment)
    (hExt : PsKernelEnvironmentSemanticExtends sourceEnvironment targetEnvironment)
    (hSourceIndex : PsKernelEnvironmentIndexRefines sourceEnvironment)
    (hTargetIndex : PsKernelEnvironmentIndexRefines targetEnvironment)
    {localContext : PsKernelLocalContext}
    {name : PsKernelName}
    {index : Nat}
    {value type result : PsKernelExpr}
    (h : PsKernelProjectionResultJudgment sourceEnvironment localContext name index value type result) :
    PsKernelProjectionResultJudgment targetEnvironment localContext name index value type result := by
  ps_kernel_environment_transport PsKernelProjectionResultJudgment.rec, sourceEnvironment, targetEnvironment,
    hExt, hSourceIndex, hTargetIndex, h

theorem PsKernelTypingJudgment.environment_weaken
    (sourceEnvironment targetEnvironment : PsKernelEnvironment)
    (hExt : PsKernelEnvironmentSemanticExtends sourceEnvironment targetEnvironment)
    (hSourceIndex : PsKernelEnvironmentIndexRefines sourceEnvironment)
    (hTargetIndex : PsKernelEnvironmentIndexRefines targetEnvironment)
    {localContext : PsKernelLocalContext}
    {expr type : PsKernelExpr}
    (h : PsKernelTypingJudgment sourceEnvironment localContext expr type) :
    PsKernelTypingJudgment targetEnvironment localContext expr type := by
  ps_kernel_environment_transport PsKernelTypingJudgment.rec, sourceEnvironment, targetEnvironment,
    hExt, hSourceIndex, hTargetIndex, h



theorem psKernelEnvironmentAddUnchecked_fresh_semantic_extends
    (environment : PsKernelEnvironment)
    (added : PsKernelConstantInfo)
    (hString : PsKernelStringEqSoundLaw)
    (hFresh : psKernelFindConstantInList
      (psKernelConstantInfoName added) environment.constants = none) :
    PsKernelEnvironmentSemanticExtends environment
      (psKernelEnvironmentAddUnchecked environment added) := by
  refine ⟨?_, fun h => h⟩
  intro name info hFind
  cases hCollision : psKernelNameEq (psKernelConstantInfoName added) name with
  | true =>
      have hName := psKernelNameEq_sound_of_string_law
        hString (psKernelConstantInfoName added) name hCollision
      have hAbsent : psKernelFindConstantInList name environment.constants = none := by
        simpa [hName] using hFresh
      rw [hAbsent] at hFind
      cases hFind
  | false =>
      simpa [psKernelEnvironmentAddUnchecked, psKernelFindConstantInList,
        hCollision] using hFind

theorem PsKernelCheckerStateSemanticSound.environment_weaken
    (older newer : PsKernelEnvironment)
    (localContext : PsKernelLocalContext)
    (state : PsKernelCheckerState)
    (hExt : PsKernelEnvironmentSemanticExtends older newer)
    (hOlderIndex : PsKernelEnvironmentIndexRefines older)
    (hNewerIndex : PsKernelEnvironmentIndexRefines newer)
    (hState : PsKernelCheckerStateSemanticSound older localContext state) :
    PsKernelCheckerStateSemanticSound newer localContext state := by
  rcases hState with ⟨hInferOnly, hChecked, hCore, hWhnf, hUnfold, hSuccess⟩
  refine ⟨True.intro, ?_, ?_, ?_, ?_, ?_⟩
  · intro expr result hGet
    exact PsKernelTypingJudgment.environment_weaken older newer hExt hOlderIndex hNewerIndex
      (hChecked expr result hGet)
  · intro expr result hGet
    exact PsKernelReductionClosure.environment_weaken older newer hExt hOlderIndex hNewerIndex
      (hCore expr result hGet)
  · intro expr result hGet
    exact PsKernelReductionClosure.environment_weaken older newer hExt hOlderIndex hNewerIndex
      (hWhnf expr result hGet)
  · intro expr result hGet
    exact PsKernelReductionClosure.environment_weaken older newer hExt hOlderIndex hNewerIndex
      (hUnfold expr result hGet)
  · intro left right hContains
    exact PsKernelDefEqJudgment.environment_weaken older newer hExt hOlderIndex hNewerIndex
      (hSuccess left right hContains)


/--
Changing admission work environments preserves retained session caches only
when old authoritative lookup information is preserved. Arbitrary environment
replacement is deliberately not certified by this theorem.
-/
theorem psKernelSessionWithEnvironment_configuration_preserves
    (session : PsKernelCheckerSession)
    (environment : PsKernelEnvironment)
    (hIndex : PsKernelEnvironmentIndexRefines environment)
    (hExt : PsKernelEnvironmentSemanticExtends
      session.context.environment environment)
    (hConfig : PsKernelCheckerConfigurationSound session.context session.state) :
    PsKernelCheckerConfigurationSound
      (psKernelSessionWithEnvironment session environment).context
      (psKernelSessionWithEnvironment session environment).state := by
  change PsKernelEnvironmentIndexRefines environment ∧
    PsKernelLocalContextFreshBound session.context.localContext session.state.nextFresh ∧
    PsKernelCheckerStateSemanticSound environment session.context.localContext session.state
  exact ⟨hIndex, hConfig.2.1,
    PsKernelCheckerStateSemanticSound.environment_weaken
      session.context.environment environment session.context.localContext
      session.state hExt hConfig.1 hIndex hConfig.2.2⟩

/--
Replacing metadata for a name introduced by the transaction preserves every
other authoritative lookup. Positive comparator soundness suffices here;
negative occurrence exclusion is not involved.
-/
theorem psKernelReplaceEnvironmentConstant_preserves_other_lookup
    (hString : PsKernelStringEqSoundLaw)
    (replacement : PsKernelConstantInfo)
    (name : PsKernelName)
    (hDifferent : name ≠ psKernelConstantInfoName replacement)
    (constants : List PsKernelConstantInfo) :
    psKernelFindConstantInList name
      (psKernelReplaceEnvironmentConstant
        (psKernelConstantInfoName replacement) replacement constants) =
      psKernelFindConstantInList name constants := by
  induction constants with
  | nil => rfl
  | cons info rest ih =>
      cases hTarget : psKernelNameEq (psKernelConstantInfoName info)
          (psKernelConstantInfoName replacement) with
      | false =>
          simp [psKernelReplaceEnvironmentConstant, hTarget,
            psKernelFindConstantInList, ih]
      | true =>
          have hSame := psKernelNameEq_sound_of_string_law hString
            (psKernelConstantInfoName info) (psKernelConstantInfoName replacement) hTarget
          have hReplacementQuery :
              psKernelNameEq (psKernelConstantInfoName replacement) name = false := by
            cases hEq : psKernelNameEq (psKernelConstantInfoName replacement) name with
            | false => rfl
            | true =>
                exact False.elim (hDifferent
                  (psKernelNameEq_sound_of_string_law hString
                    (psKernelConstantInfoName replacement) name hEq).symm)
          have hInfoQuery : psKernelNameEq (psKernelConstantInfoName info) name = false := by
            simpa [hSame] using hReplacementQuery
          simp [psKernelReplaceEnvironmentConstant, hTarget,
            psKernelFindConstantInList, hReplacementQuery, hInfoQuery]

/--
An inductive transaction can update its newly introduced metadata without
claiming that the provisional metadata itself was preserved. The extension
is relative to the original environment where the transaction name was absent.
-/
theorem psKernelEnvironmentReplaceUnchecked_fresh_origin_semantic_extends
    (older work : PsKernelEnvironment)
    (replacement : PsKernelConstantInfo)
    (hString : PsKernelStringEqSoundLaw)
    (hExt : PsKernelEnvironmentSemanticExtends older work)
    (hFresh : psKernelFindConstantInList
      (psKernelConstantInfoName replacement) older.constants = none) :
    PsKernelEnvironmentSemanticExtends older
      (psKernelEnvironmentReplaceUnchecked work replacement) := by
  refine ⟨?_, fun h => hExt.2 h⟩
  intro name info hFind
  have hDifferent : name ≠ psKernelConstantInfoName replacement := by
    intro hSame
    subst name
    rw [hFresh] at hFind
    cases hFind
  change psKernelFindConstantInList name
    (psKernelReplaceEnvironmentConstant
      (psKernelConstantInfoName replacement) replacement work.constants) = some info
  rw [psKernelReplaceEnvironmentConstant_preserves_other_lookup
    hString replacement name hDifferent work.constants]
  exact hExt.1 name info hFind
