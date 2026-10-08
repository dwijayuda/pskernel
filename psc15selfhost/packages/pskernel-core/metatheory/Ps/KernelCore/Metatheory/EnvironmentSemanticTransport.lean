import Ps.KernelCore.Metatheory.Judgments

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
  cases h with
  | beta name type body arg binderInfo =>
      exact PsKernelReductionStep.beta name type body arg binderInfo
  | zeta name type value body nondep =>
      exact PsKernelReductionStep.zeta name type value body nondep
  | metadata metadata body =>
      exact PsKernelReductionStep.metadata metadata body
  | localLet name declaration value hFind hValue =>
      exact PsKernelReductionStep.localLet name declaration value hFind hValue
  | stringLiteral value =>
      exact PsKernelReductionStep.stringLiteral value
  | projection typeName ctorName ctorLevels index structValue result ctorInfo hIndex hFn hFind hInduct hArg =>
      exact PsKernelReductionStep.projection typeName ctorName ctorLevels index structValue result ctorInfo hIndex hFn (hExt.1 _ _ hFind) hInduct hArg
  | deltaConst name levels info value hFind hDelta hLevels =>
      exact PsKernelReductionStep.deltaConst name levels info value (hExt.1 _ _ hFind) hDelta hLevels
  | deltaSpine expr name levels info value hFn hFind hDelta hLevels =>
      exact PsKernelReductionStep.deltaSpine expr name levels info value hFn (hExt.1 _ _ hFind) hDelta hLevels
  | natZeroLiteral name hName =>
      exact PsKernelReductionStep.natZeroLiteral name hName
  | natAdd op left right hOp =>
      exact PsKernelReductionStep.natAdd op left right hOp
  | natSub op left right hOp =>
      exact PsKernelReductionStep.natSub op left right hOp
  | natMul op left right hOp =>
      exact PsKernelReductionStep.natMul op left right hOp
  | natSucc op value hOp =>
      exact PsKernelReductionStep.natSucc op value hOp
  | natMod op left right hOp =>
      exact PsKernelReductionStep.natMod op left right hOp
  | natDiv op left right hOp =>
      exact PsKernelReductionStep.natDiv op left right hOp
  | natBeq op left right hOp =>
      exact PsKernelReductionStep.natBeq op left right hOp
  | natBle op left right hOp =>
      exact PsKernelReductionStep.natBle op left right hOp
  | natPow op left right hOp =>
      exact PsKernelReductionStep.natPow op left right hOp
  | natPowZero op left right hOp hZero =>
      exact PsKernelReductionStep.natPowZero op left right hOp hZero
  | natGcd op left right hOp =>
      exact PsKernelReductionStep.natGcd op left right hOp
  | natLand op left right hOp =>
      exact PsKernelReductionStep.natLand op left right hOp
  | natLor op left right hOp =>
      exact PsKernelReductionStep.natLor op left right hOp
  | natXor op left right hOp =>
      exact PsKernelReductionStep.natXor op left right hOp
  | natShiftLeft op left right hOp =>
      exact PsKernelReductionStep.natShiftLeft op left right hOp
  | natShiftLeftZero op left right hOp hZero =>
      exact PsKernelReductionStep.natShiftLeftZero op left right hOp hZero
  | natShiftRight op left right hOp =>
      exact PsKernelReductionStep.natShiftRight op left right hOp

/- Joint structural transport follows the semantic derivations themselves;
   no new semantic constructor or assumption is added to the judgments. -/
mutual

theorem PsKernelReductionClosure.environment_weaken
    (sourceEnvironment targetEnvironment : PsKernelEnvironment)
    (hExt : PsKernelEnvironmentSemanticExtends sourceEnvironment targetEnvironment)
    {localContext : PsKernelLocalContext}
    {left right : PsKernelExpr}
    (h : PsKernelReductionClosure sourceEnvironment localContext left right) :
    PsKernelReductionClosure targetEnvironment localContext left right := by
  cases h
  case refl => apply PsKernelReductionClosure.refl
  case contextWeaken => apply PsKernelReductionClosure.contextWeaken
  case presentationSource => apply PsKernelReductionClosure.presentationSource
  case cons => apply PsKernelReductionClosure.cons
  case trans => apply PsKernelReductionClosure.trans
  case appFn => apply PsKernelReductionClosure.appFn
  case appArg => apply PsKernelReductionClosure.appArg
  case projectionMajor => apply PsKernelReductionClosure.projectionMajor
  case quotLift => apply PsKernelReductionClosure.quotLift
  case quotInd => apply PsKernelReductionClosure.quotInd
  case recursorIota => apply PsKernelReductionClosure.recursorIota
  all_goals first
    | assumption
    | (apply hExt.1; assumption)
    | (apply hExt.2; assumption)
    | (apply PsKernelReductionStep.environment_weaken sourceEnvironment targetEnvironment hExt; assumption)
    | (apply PsKernelReductionClosure.environment_weaken sourceEnvironment targetEnvironment hExt; assumption)
    | (apply PsKernelDefEqJudgment.environment_weaken sourceEnvironment targetEnvironment hExt; assumption)
termination_by structural h

theorem PsKernelDefEqJudgment.environment_weaken
    (sourceEnvironment targetEnvironment : PsKernelEnvironment)
    (hExt : PsKernelEnvironmentSemanticExtends sourceEnvironment targetEnvironment)
    {localContext : PsKernelLocalContext}
    {left right : PsKernelExpr}
    (h : PsKernelDefEqJudgment sourceEnvironment localContext left right) :
    PsKernelDefEqJudgment targetEnvironment localContext left right := by
  cases h
  case refl => apply PsKernelDefEqJudgment.refl
  case contextWeaken => apply PsKernelDefEqJudgment.contextWeaken
  case symm => apply PsKernelDefEqJudgment.symm
  case presentation => apply PsKernelDefEqJudgment.presentation
  case structural => apply PsKernelDefEqJudgment.structural
  case reduction => apply PsKernelDefEqJudgment.reduction
  case reductionClosure => apply PsKernelDefEqJudgment.reductionClosure
  case sort => apply PsKernelDefEqJudgment.sort
  case literal => apply PsKernelDefEqJudgment.literal
  case app => apply PsKernelDefEqJudgment.app
  case constLevels => apply PsKernelDefEqJudgment.constLevels
  case natSuccessorPred => apply PsKernelDefEqJudgment.natSuccessorPred
  case projection => apply PsKernelDefEqJudgment.projection
  case reduceCompare => apply PsKernelDefEqJudgment.reduceCompare
  case functionEtaLeft => apply PsKernelDefEqJudgment.functionEtaLeft
  case functionEtaRight => apply PsKernelDefEqJudgment.functionEtaRight
  case proofIrrelevanceAlgorithmic => apply PsKernelDefEqJudgment.proofIrrelevanceAlgorithmic
  case unitLike => apply PsKernelDefEqJudgment.unitLike
  case structureEtaAlgorithmic => apply PsKernelDefEqJudgment.structureEtaAlgorithmic
  case lambdaSpine => apply PsKernelDefEqJudgment.lambdaSpine
  case forallSpine => apply PsKernelDefEqJudgment.forallSpine
  case recursorKConversion => apply PsKernelDefEqJudgment.recursorKConversion
  case recursorStructureEta => apply PsKernelDefEqJudgment.recursorStructureEta
  case proofIrrelevance => apply PsKernelDefEqJudgment.proofIrrelevance
  case structureEta => apply PsKernelDefEqJudgment.structureEta
  case metadataLeft => apply PsKernelDefEqJudgment.metadataLeft
  case metadataRight => apply PsKernelDefEqJudgment.metadataRight
  all_goals first
    | assumption
    | (apply hExt.1; assumption)
    | (apply hExt.2; assumption)
    | (apply PsKernelReductionStep.environment_weaken sourceEnvironment targetEnvironment hExt; assumption)
    | (apply PsKernelReductionClosure.environment_weaken sourceEnvironment targetEnvironment hExt; assumption)
    | (apply PsKernelDefEqJudgment.environment_weaken sourceEnvironment targetEnvironment hExt; assumption)
    | (apply PsKernelStructureEtaCompareJudgment.environment_weaken sourceEnvironment targetEnvironment hExt; assumption)
    | (apply PsKernelLambdaSpineJudgment.environment_weaken sourceEnvironment targetEnvironment hExt; assumption)
    | (apply PsKernelForallSpineJudgment.environment_weaken sourceEnvironment targetEnvironment hExt; assumption)
    | (apply PsKernelTypingJudgment.environment_weaken sourceEnvironment targetEnvironment hExt; assumption)
termination_by structural h

theorem PsKernelStructureEtaCompareJudgment.environment_weaken
    (sourceEnvironment targetEnvironment : PsKernelEnvironment)
    (hExt : PsKernelEnvironmentSemanticExtends sourceEnvironment targetEnvironment)
    {localContext : PsKernelLocalContext}
    {name : PsKernelName}
    {value : PsKernelExpr}
    {args : List PsKernelExpr}
    {index count : Nat}
    (h : PsKernelStructureEtaCompareJudgment sourceEnvironment localContext name value args index count) :
    PsKernelStructureEtaCompareJudgment targetEnvironment localContext name value args index count := by
  cases h
  case done => apply PsKernelStructureEtaCompareJudgment.done
  case step => apply PsKernelStructureEtaCompareJudgment.step
  all_goals first
    | assumption
    | (apply hExt.1; assumption)
    | (apply hExt.2; assumption)
    | (apply PsKernelDefEqJudgment.environment_weaken sourceEnvironment targetEnvironment hExt; assumption)
    | (apply PsKernelStructureEtaCompareJudgment.environment_weaken sourceEnvironment targetEnvironment hExt; assumption)
termination_by structural h

theorem PsKernelBinderDomainJudgment.environment_weaken
    (sourceEnvironment targetEnvironment : PsKernelEnvironment)
    (hExt : PsKernelEnvironmentSemanticExtends sourceEnvironment targetEnvironment)
    {localContext : PsKernelLocalContext}
    {left right : PsKernelExpr}
    {args : List PsKernelExpr}
    (h : PsKernelBinderDomainJudgment sourceEnvironment localContext left right args) :
    PsKernelBinderDomainJudgment targetEnvironment localContext left right args := by
  cases h
  case structural => apply PsKernelBinderDomainJudgment.structural
  case defeq => apply PsKernelBinderDomainJudgment.defeq
  all_goals first
    | assumption
    | (apply hExt.1; assumption)
    | (apply hExt.2; assumption)
    | (apply PsKernelDefEqJudgment.environment_weaken sourceEnvironment targetEnvironment hExt; assumption)
termination_by structural h

theorem PsKernelLambdaSpineJudgment.environment_weaken
    (sourceEnvironment targetEnvironment : PsKernelEnvironment)
    (hExt : PsKernelEnvironmentSemanticExtends sourceEnvironment targetEnvironment)
    {localContext : PsKernelLocalContext}
    {left right : PsKernelExpr}
    {args : List PsKernelExpr}
    (h : PsKernelLambdaSpineJudgment sourceEnvironment localContext left right args) :
    PsKernelLambdaSpineJudgment targetEnvironment localContext left right args := by
  cases h
  case terminal => apply PsKernelLambdaSpineJudgment.terminal
  case stepOpen => apply PsKernelLambdaSpineJudgment.stepOpen
  case stepClosed => apply PsKernelLambdaSpineJudgment.stepClosed
  all_goals first
    | assumption
    | (apply hExt.1; assumption)
    | (apply hExt.2; assumption)
    | (apply PsKernelDefEqJudgment.environment_weaken sourceEnvironment targetEnvironment hExt; assumption)
    | (apply PsKernelBinderDomainJudgment.environment_weaken sourceEnvironment targetEnvironment hExt; assumption)
    | (apply PsKernelLambdaSpineJudgment.environment_weaken sourceEnvironment targetEnvironment hExt; assumption)
termination_by structural h

theorem PsKernelForallSpineJudgment.environment_weaken
    (sourceEnvironment targetEnvironment : PsKernelEnvironment)
    (hExt : PsKernelEnvironmentSemanticExtends sourceEnvironment targetEnvironment)
    {localContext : PsKernelLocalContext}
    {left right : PsKernelExpr}
    {args : List PsKernelExpr}
    (h : PsKernelForallSpineJudgment sourceEnvironment localContext left right args) :
    PsKernelForallSpineJudgment targetEnvironment localContext left right args := by
  cases h
  case terminal => apply PsKernelForallSpineJudgment.terminal
  case stepOpen => apply PsKernelForallSpineJudgment.stepOpen
  case stepClosed => apply PsKernelForallSpineJudgment.stepClosed
  all_goals first
    | assumption
    | (apply hExt.1; assumption)
    | (apply hExt.2; assumption)
    | (apply PsKernelDefEqJudgment.environment_weaken sourceEnvironment targetEnvironment hExt; assumption)
    | (apply PsKernelBinderDomainJudgment.environment_weaken sourceEnvironment targetEnvironment hExt; assumption)
    | (apply PsKernelForallSpineJudgment.environment_weaken sourceEnvironment targetEnvironment hExt; assumption)
termination_by structural h

theorem PsKernelProjectionApplyParamsJudgment.environment_weaken
    (sourceEnvironment targetEnvironment : PsKernelEnvironment)
    (hExt : PsKernelEnvironmentSemanticExtends sourceEnvironment targetEnvironment)
    {localContext : PsKernelLocalContext}
    {args : List PsKernelExpr}
    {index count : Nat}
    {type result : PsKernelExpr}
    (h : PsKernelProjectionApplyParamsJudgment sourceEnvironment localContext args index count type result) :
    PsKernelProjectionApplyParamsJudgment targetEnvironment localContext args index count type result := by
  cases h
  case done => apply PsKernelProjectionApplyParamsJudgment.done
  case step => apply PsKernelProjectionApplyParamsJudgment.step
  all_goals first
    | assumption
    | (apply hExt.1; assumption)
    | (apply hExt.2; assumption)
    | (apply PsKernelReductionClosure.environment_weaken sourceEnvironment targetEnvironment hExt; assumption)
    | (apply PsKernelProjectionApplyParamsJudgment.environment_weaken sourceEnvironment targetEnvironment hExt; assumption)
termination_by structural h

theorem PsKernelProjectionSkipFieldsJudgment.environment_weaken
    (sourceEnvironment targetEnvironment : PsKernelEnvironment)
    (hExt : PsKernelEnvironmentSemanticExtends sourceEnvironment targetEnvironment)
    {localContext : PsKernelLocalContext}
    {name : PsKernelName}
    {value : PsKernelExpr}
    {index count : Nat}
    {type result : PsKernelExpr}
    (h : PsKernelProjectionSkipFieldsJudgment sourceEnvironment localContext name value index count type result) :
    PsKernelProjectionSkipFieldsJudgment targetEnvironment localContext name value index count type result := by
  cases h
  case done => apply PsKernelProjectionSkipFieldsJudgment.done
  case stepClosed => apply PsKernelProjectionSkipFieldsJudgment.stepClosed
  case stepDependent => apply PsKernelProjectionSkipFieldsJudgment.stepDependent
  all_goals first
    | assumption
    | (apply hExt.1; assumption)
    | (apply hExt.2; assumption)
    | (apply PsKernelReductionClosure.environment_weaken sourceEnvironment targetEnvironment hExt; assumption)
    | (apply PsKernelProjectionSkipFieldsJudgment.environment_weaken sourceEnvironment targetEnvironment hExt; assumption)
termination_by structural h

theorem PsKernelProjectionResultJudgment.environment_weaken
    (sourceEnvironment targetEnvironment : PsKernelEnvironment)
    (hExt : PsKernelEnvironmentSemanticExtends sourceEnvironment targetEnvironment)
    {localContext : PsKernelLocalContext}
    {name : PsKernelName}
    {index : Nat}
    {value type result : PsKernelExpr}
    (h : PsKernelProjectionResultJudgment sourceEnvironment localContext name index value type result) :
    PsKernelProjectionResultJudgment targetEnvironment localContext name index value type result := by
  cases h
  case intro => apply PsKernelProjectionResultJudgment.intro
  all_goals first
    | assumption
    | (apply hExt.1; assumption)
    | (apply hExt.2; assumption)
    | (apply PsKernelReductionClosure.environment_weaken sourceEnvironment targetEnvironment hExt; assumption)
    | (apply PsKernelProjectionApplyParamsJudgment.environment_weaken sourceEnvironment targetEnvironment hExt; assumption)
    | (apply PsKernelProjectionSkipFieldsJudgment.environment_weaken sourceEnvironment targetEnvironment hExt; assumption)
termination_by structural h

theorem PsKernelTypingJudgment.environment_weaken
    (sourceEnvironment targetEnvironment : PsKernelEnvironment)
    (hExt : PsKernelEnvironmentSemanticExtends sourceEnvironment targetEnvironment)
    {localContext : PsKernelLocalContext}
    {expr type : PsKernelExpr}
    (h : PsKernelTypingJudgment sourceEnvironment localContext expr type) :
    PsKernelTypingJudgment targetEnvironment localContext expr type := by
  cases h
  case presentation => apply PsKernelTypingJudgment.presentation
  case contextWeaken => apply PsKernelTypingJudgment.contextWeaken
  case convert => apply PsKernelTypingJudgment.convert
  case sort => apply PsKernelTypingJudgment.sort
  case natLiteral => apply PsKernelTypingJudgment.natLiteral
  case stringLiteral => apply PsKernelTypingJudgment.stringLiteral
  case fvar => apply PsKernelTypingJudgment.fvar
  case const => apply PsKernelTypingJudgment.const
  case app => apply PsKernelTypingJudgment.app
  case lam => apply PsKernelTypingJudgment.lam
  case forallE => apply PsKernelTypingJudgment.forallE
  case letE => apply PsKernelTypingJudgment.letE
  case mdata => apply PsKernelTypingJudgment.mdata
  case proj => apply PsKernelTypingJudgment.proj
  all_goals first
    | assumption
    | (apply hExt.1; assumption)
    | (apply hExt.2; assumption)
    | (apply PsKernelDefEqJudgment.environment_weaken sourceEnvironment targetEnvironment hExt; assumption)
    | (apply PsKernelProjectionResultJudgment.environment_weaken sourceEnvironment targetEnvironment hExt; assumption)
    | (apply PsKernelTypingJudgment.environment_weaken sourceEnvironment targetEnvironment hExt; assumption)
termination_by structural h

end
