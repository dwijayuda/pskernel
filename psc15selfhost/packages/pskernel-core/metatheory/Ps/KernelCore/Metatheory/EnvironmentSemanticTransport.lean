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

#check PsKernelReductionClosure.rec

/- Joint structural transport follows the semantic derivations themselves;
   no new semantic constructor or assumption is added to the judgments. -/
mutual

theorem PsKernelReductionClosure.environment_weaken
    (sourceEnvironment targetEnvironment : PsKernelEnvironment)
    (hExt : PsKernelEnvironmentSemanticExtends sourceEnvironment targetEnvironment)
    (hSourceIndex : PsKernelEnvironmentIndexRefines sourceEnvironment)
    (hTargetIndex : PsKernelEnvironmentIndexRefines targetEnvironment)
    {localContext : PsKernelLocalContext}
    {left right : PsKernelExpr}
    (h : PsKernelReductionClosure sourceEnvironment localContext left right) :
    PsKernelReductionClosure targetEnvironment localContext left right := by
  cases h
  case refl =>
    apply PsKernelReductionClosure.refl
    all_goals first
      | assumption
      | (apply psKernelEnvironmentIsNonRecStructure_environment_weaken
          sourceEnvironment targetEnvironment hExt hSourceIndex hTargetIndex; assumption)
  case contextWeaken =>
    apply PsKernelReductionClosure.contextWeaken
    all_goals first
      | assumption
      | (apply psKernelEnvironmentIsNonRecStructure_environment_weaken
          sourceEnvironment targetEnvironment hExt hSourceIndex hTargetIndex; assumption)
      | (apply PsKernelReductionClosure.environment_weaken sourceEnvironment targetEnvironment hExt hSourceIndex hTargetIndex; assumption)
  case presentationSource =>
    apply PsKernelReductionClosure.presentationSource
    all_goals first
      | assumption
      | (apply psKernelEnvironmentIsNonRecStructure_environment_weaken
          sourceEnvironment targetEnvironment hExt hSourceIndex hTargetIndex; assumption)
      | (apply PsKernelReductionClosure.environment_weaken sourceEnvironment targetEnvironment hExt hSourceIndex hTargetIndex; assumption)
  case cons =>
    apply PsKernelReductionClosure.cons
    all_goals first
      | assumption
      | (apply psKernelEnvironmentIsNonRecStructure_environment_weaken
          sourceEnvironment targetEnvironment hExt hSourceIndex hTargetIndex; assumption)
      | (apply PsKernelReductionStep.environment_weaken sourceEnvironment targetEnvironment hExt; assumption)
      | (apply PsKernelReductionClosure.environment_weaken sourceEnvironment targetEnvironment hExt hSourceIndex hTargetIndex; assumption)
  case trans =>
    apply PsKernelReductionClosure.trans
    all_goals first
      | assumption
      | (apply psKernelEnvironmentIsNonRecStructure_environment_weaken
          sourceEnvironment targetEnvironment hExt hSourceIndex hTargetIndex; assumption)
      | (apply PsKernelReductionClosure.environment_weaken sourceEnvironment targetEnvironment hExt hSourceIndex hTargetIndex; assumption)
  case appFn =>
    apply PsKernelReductionClosure.appFn
    all_goals first
      | assumption
      | (apply psKernelEnvironmentIsNonRecStructure_environment_weaken
          sourceEnvironment targetEnvironment hExt hSourceIndex hTargetIndex; assumption)
      | (apply PsKernelReductionClosure.environment_weaken sourceEnvironment targetEnvironment hExt hSourceIndex hTargetIndex; assumption)
  case appArg =>
    apply PsKernelReductionClosure.appArg
    all_goals first
      | assumption
      | (apply psKernelEnvironmentIsNonRecStructure_environment_weaken
          sourceEnvironment targetEnvironment hExt hSourceIndex hTargetIndex; assumption)
      | (apply PsKernelReductionClosure.environment_weaken sourceEnvironment targetEnvironment hExt hSourceIndex hTargetIndex; assumption)
  case projectionMajor =>
    apply PsKernelReductionClosure.projectionMajor
    all_goals first
      | assumption
      | (apply psKernelEnvironmentIsNonRecStructure_environment_weaken
          sourceEnvironment targetEnvironment hExt hSourceIndex hTargetIndex; assumption)
      | (apply PsKernelReductionClosure.environment_weaken sourceEnvironment targetEnvironment hExt hSourceIndex hTargetIndex; assumption)
  case quotLift =>
    apply PsKernelReductionClosure.quotLift
    all_goals first
      | assumption
      | (apply psKernelEnvironmentIsNonRecStructure_environment_weaken
          sourceEnvironment targetEnvironment hExt hSourceIndex hTargetIndex; assumption)
      | (apply hExt.2; assumption)
      | (apply PsKernelReductionClosure.environment_weaken sourceEnvironment targetEnvironment hExt hSourceIndex hTargetIndex; assumption)
  case quotInd =>
    apply PsKernelReductionClosure.quotInd
    all_goals first
      | assumption
      | (apply psKernelEnvironmentIsNonRecStructure_environment_weaken
          sourceEnvironment targetEnvironment hExt hSourceIndex hTargetIndex; assumption)
      | (apply hExt.2; assumption)
      | (apply PsKernelReductionClosure.environment_weaken sourceEnvironment targetEnvironment hExt hSourceIndex hTargetIndex; assumption)
  case recursorIota =>
    apply PsKernelReductionClosure.recursorIota
    all_goals first
      | assumption
      | (apply psKernelEnvironmentIsNonRecStructure_environment_weaken
          sourceEnvironment targetEnvironment hExt hSourceIndex hTargetIndex; assumption)
      | (apply hExt.1; assumption)
      | (apply PsKernelReductionClosure.environment_weaken sourceEnvironment targetEnvironment hExt hSourceIndex hTargetIndex; assumption)
      | (apply PsKernelDefEqJudgment.environment_weaken sourceEnvironment targetEnvironment hExt hSourceIndex hTargetIndex; assumption)
termination_by structural h

theorem PsKernelDefEqJudgment.environment_weaken
    (sourceEnvironment targetEnvironment : PsKernelEnvironment)
    (hExt : PsKernelEnvironmentSemanticExtends sourceEnvironment targetEnvironment)
    (hSourceIndex : PsKernelEnvironmentIndexRefines sourceEnvironment)
    (hTargetIndex : PsKernelEnvironmentIndexRefines targetEnvironment)
    {localContext : PsKernelLocalContext}
    {left right : PsKernelExpr}
    (h : PsKernelDefEqJudgment sourceEnvironment localContext left right) :
    PsKernelDefEqJudgment targetEnvironment localContext left right := by
  cases h
  case refl =>
    apply PsKernelDefEqJudgment.refl
    all_goals first
      | assumption
      | (apply psKernelEnvironmentIsNonRecStructure_environment_weaken
          sourceEnvironment targetEnvironment hExt hSourceIndex hTargetIndex; assumption)
  case contextWeaken =>
    apply PsKernelDefEqJudgment.contextWeaken
    all_goals first
      | assumption
      | (apply psKernelEnvironmentIsNonRecStructure_environment_weaken
          sourceEnvironment targetEnvironment hExt hSourceIndex hTargetIndex; assumption)
      | (apply PsKernelDefEqJudgment.environment_weaken sourceEnvironment targetEnvironment hExt hSourceIndex hTargetIndex; assumption)
  case symm =>
    apply PsKernelDefEqJudgment.symm
    all_goals first
      | assumption
      | (apply psKernelEnvironmentIsNonRecStructure_environment_weaken
          sourceEnvironment targetEnvironment hExt hSourceIndex hTargetIndex; assumption)
      | (apply PsKernelDefEqJudgment.environment_weaken sourceEnvironment targetEnvironment hExt hSourceIndex hTargetIndex; assumption)
  case presentation =>
    apply PsKernelDefEqJudgment.presentation
    all_goals first
      | assumption
      | (apply psKernelEnvironmentIsNonRecStructure_environment_weaken
          sourceEnvironment targetEnvironment hExt hSourceIndex hTargetIndex; assumption)
      | (apply PsKernelDefEqJudgment.environment_weaken sourceEnvironment targetEnvironment hExt hSourceIndex hTargetIndex; assumption)
  case structural =>
    apply PsKernelDefEqJudgment.structural
    all_goals first
      | assumption
      | (apply psKernelEnvironmentIsNonRecStructure_environment_weaken
          sourceEnvironment targetEnvironment hExt hSourceIndex hTargetIndex; assumption)
  case reduction =>
    apply PsKernelDefEqJudgment.reduction
    all_goals first
      | assumption
      | (apply psKernelEnvironmentIsNonRecStructure_environment_weaken
          sourceEnvironment targetEnvironment hExt hSourceIndex hTargetIndex; assumption)
      | (apply PsKernelReductionStep.environment_weaken sourceEnvironment targetEnvironment hExt; assumption)
  case reductionClosure =>
    apply PsKernelDefEqJudgment.reductionClosure
    all_goals first
      | assumption
      | (apply psKernelEnvironmentIsNonRecStructure_environment_weaken
          sourceEnvironment targetEnvironment hExt hSourceIndex hTargetIndex; assumption)
      | (apply PsKernelReductionClosure.environment_weaken sourceEnvironment targetEnvironment hExt hSourceIndex hTargetIndex; assumption)
  case sort =>
    apply PsKernelDefEqJudgment.sort
    all_goals first
      | assumption
      | (apply psKernelEnvironmentIsNonRecStructure_environment_weaken
          sourceEnvironment targetEnvironment hExt hSourceIndex hTargetIndex; assumption)
  case literal =>
    apply PsKernelDefEqJudgment.literal
    all_goals first
      | assumption
      | (apply psKernelEnvironmentIsNonRecStructure_environment_weaken
          sourceEnvironment targetEnvironment hExt hSourceIndex hTargetIndex; assumption)
  case app =>
    apply PsKernelDefEqJudgment.app
    all_goals first
      | assumption
      | (apply psKernelEnvironmentIsNonRecStructure_environment_weaken
          sourceEnvironment targetEnvironment hExt hSourceIndex hTargetIndex; assumption)
      | (apply PsKernelDefEqJudgment.environment_weaken sourceEnvironment targetEnvironment hExt hSourceIndex hTargetIndex; assumption)
  case constLevels =>
    apply PsKernelDefEqJudgment.constLevels
    all_goals first
      | assumption
      | (apply psKernelEnvironmentIsNonRecStructure_environment_weaken
          sourceEnvironment targetEnvironment hExt hSourceIndex hTargetIndex; assumption)
  case natSuccessorPred =>
    apply PsKernelDefEqJudgment.natSuccessorPred
    all_goals first
      | assumption
      | (apply psKernelEnvironmentIsNonRecStructure_environment_weaken
          sourceEnvironment targetEnvironment hExt hSourceIndex hTargetIndex; assumption)
      | (apply PsKernelDefEqJudgment.environment_weaken sourceEnvironment targetEnvironment hExt hSourceIndex hTargetIndex; assumption)
  case projection =>
    apply PsKernelDefEqJudgment.projection
    all_goals first
      | assumption
      | (apply psKernelEnvironmentIsNonRecStructure_environment_weaken
          sourceEnvironment targetEnvironment hExt hSourceIndex hTargetIndex; assumption)
      | (apply PsKernelDefEqJudgment.environment_weaken sourceEnvironment targetEnvironment hExt hSourceIndex hTargetIndex; assumption)
  case reduceCompare =>
    apply PsKernelDefEqJudgment.reduceCompare
    all_goals first
      | assumption
      | (apply psKernelEnvironmentIsNonRecStructure_environment_weaken
          sourceEnvironment targetEnvironment hExt hSourceIndex hTargetIndex; assumption)
      | (apply PsKernelReductionClosure.environment_weaken sourceEnvironment targetEnvironment hExt hSourceIndex hTargetIndex; assumption)
      | (apply PsKernelDefEqJudgment.environment_weaken sourceEnvironment targetEnvironment hExt hSourceIndex hTargetIndex; assumption)
  case functionEtaLeft =>
    apply PsKernelDefEqJudgment.functionEtaLeft
    all_goals first
      | assumption
      | (apply psKernelEnvironmentIsNonRecStructure_environment_weaken
          sourceEnvironment targetEnvironment hExt hSourceIndex hTargetIndex; assumption)
      | (apply PsKernelDefEqJudgment.environment_weaken sourceEnvironment targetEnvironment hExt hSourceIndex hTargetIndex; assumption)
  case functionEtaRight =>
    apply PsKernelDefEqJudgment.functionEtaRight
    all_goals first
      | assumption
      | (apply psKernelEnvironmentIsNonRecStructure_environment_weaken
          sourceEnvironment targetEnvironment hExt hSourceIndex hTargetIndex; assumption)
      | (apply PsKernelDefEqJudgment.environment_weaken sourceEnvironment targetEnvironment hExt hSourceIndex hTargetIndex; assumption)
  case proofIrrelevanceAlgorithmic =>
    apply PsKernelDefEqJudgment.proofIrrelevanceAlgorithmic
    all_goals first
      | assumption
      | (apply psKernelEnvironmentIsNonRecStructure_environment_weaken
          sourceEnvironment targetEnvironment hExt hSourceIndex hTargetIndex; assumption)
      | (apply PsKernelReductionClosure.environment_weaken sourceEnvironment targetEnvironment hExt hSourceIndex hTargetIndex; assumption)
      | (apply PsKernelDefEqJudgment.environment_weaken sourceEnvironment targetEnvironment hExt hSourceIndex hTargetIndex; assumption)
  case unitLike =>
    apply PsKernelDefEqJudgment.unitLike
    all_goals first
      | assumption
      | (apply psKernelEnvironmentIsNonRecStructure_environment_weaken
          sourceEnvironment targetEnvironment hExt hSourceIndex hTargetIndex; assumption)
      | (apply hExt.1; assumption)
      | (apply PsKernelReductionClosure.environment_weaken sourceEnvironment targetEnvironment hExt hSourceIndex hTargetIndex; assumption)
      | (apply PsKernelDefEqJudgment.environment_weaken sourceEnvironment targetEnvironment hExt hSourceIndex hTargetIndex; assumption)
  case structureEtaAlgorithmic =>
    apply PsKernelDefEqJudgment.structureEtaAlgorithmic
    all_goals first
      | assumption
      | (apply psKernelEnvironmentIsNonRecStructure_environment_weaken
          sourceEnvironment targetEnvironment hExt hSourceIndex hTargetIndex; assumption)
      | (apply hExt.1; assumption)
      | (apply PsKernelDefEqJudgment.environment_weaken sourceEnvironment targetEnvironment hExt hSourceIndex hTargetIndex; assumption)
      | (apply PsKernelStructureEtaCompareJudgment.environment_weaken sourceEnvironment targetEnvironment hExt hSourceIndex hTargetIndex; assumption)
  case lambdaSpine =>
    apply PsKernelDefEqJudgment.lambdaSpine
    all_goals first
      | assumption
      | (apply psKernelEnvironmentIsNonRecStructure_environment_weaken
          sourceEnvironment targetEnvironment hExt hSourceIndex hTargetIndex; assumption)
      | (apply PsKernelLambdaSpineJudgment.environment_weaken sourceEnvironment targetEnvironment hExt hSourceIndex hTargetIndex; assumption)
  case forallSpine =>
    apply PsKernelDefEqJudgment.forallSpine
    all_goals first
      | assumption
      | (apply psKernelEnvironmentIsNonRecStructure_environment_weaken
          sourceEnvironment targetEnvironment hExt hSourceIndex hTargetIndex; assumption)
      | (apply PsKernelForallSpineJudgment.environment_weaken sourceEnvironment targetEnvironment hExt hSourceIndex hTargetIndex; assumption)
  case recursorKConversion =>
    apply PsKernelDefEqJudgment.recursorKConversion
    all_goals first
      | assumption
      | (apply psKernelEnvironmentIsNonRecStructure_environment_weaken
          sourceEnvironment targetEnvironment hExt hSourceIndex hTargetIndex; assumption)
      | (apply hExt.1; assumption)
      | (apply PsKernelDefEqJudgment.environment_weaken sourceEnvironment targetEnvironment hExt hSourceIndex hTargetIndex; assumption)
  case recursorStructureEta =>
    apply PsKernelDefEqJudgment.recursorStructureEta
    all_goals first
      | assumption
      | (apply psKernelEnvironmentIsNonRecStructure_environment_weaken
          sourceEnvironment targetEnvironment hExt hSourceIndex hTargetIndex; assumption)
      | (apply hExt.1; assumption)
  case proofIrrelevance =>
    apply PsKernelDefEqJudgment.proofIrrelevance
    all_goals first
      | assumption
      | (apply psKernelEnvironmentIsNonRecStructure_environment_weaken
          sourceEnvironment targetEnvironment hExt hSourceIndex hTargetIndex; assumption)
      | (apply PsKernelDefEqJudgment.environment_weaken sourceEnvironment targetEnvironment hExt hSourceIndex hTargetIndex; assumption)
      | (apply PsKernelTypingJudgment.environment_weaken sourceEnvironment targetEnvironment hExt hSourceIndex hTargetIndex; assumption)
  case structureEta =>
    apply PsKernelDefEqJudgment.structureEta
    all_goals first
      | assumption
      | (apply psKernelEnvironmentIsNonRecStructure_environment_weaken
          sourceEnvironment targetEnvironment hExt hSourceIndex hTargetIndex; assumption)
      | (apply hExt.1; assumption)
      | (apply PsKernelTypingJudgment.environment_weaken sourceEnvironment targetEnvironment hExt hSourceIndex hTargetIndex; assumption)
  case metadataLeft =>
    apply PsKernelDefEqJudgment.metadataLeft
    all_goals first
      | assumption
      | (apply psKernelEnvironmentIsNonRecStructure_environment_weaken
          sourceEnvironment targetEnvironment hExt hSourceIndex hTargetIndex; assumption)
      | (apply PsKernelDefEqJudgment.environment_weaken sourceEnvironment targetEnvironment hExt hSourceIndex hTargetIndex; assumption)
  case metadataRight =>
    apply PsKernelDefEqJudgment.metadataRight
    all_goals first
      | assumption
      | (apply psKernelEnvironmentIsNonRecStructure_environment_weaken
          sourceEnvironment targetEnvironment hExt hSourceIndex hTargetIndex; assumption)
      | (apply PsKernelDefEqJudgment.environment_weaken sourceEnvironment targetEnvironment hExt hSourceIndex hTargetIndex; assumption)
termination_by structural h

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
  cases h
  case done =>
    apply PsKernelStructureEtaCompareJudgment.done
    all_goals first
      | assumption
      | (apply psKernelEnvironmentIsNonRecStructure_environment_weaken
          sourceEnvironment targetEnvironment hExt hSourceIndex hTargetIndex; assumption)
  case step =>
    apply PsKernelStructureEtaCompareJudgment.step
    all_goals first
      | assumption
      | (apply psKernelEnvironmentIsNonRecStructure_environment_weaken
          sourceEnvironment targetEnvironment hExt hSourceIndex hTargetIndex; assumption)
      | (apply PsKernelDefEqJudgment.environment_weaken sourceEnvironment targetEnvironment hExt hSourceIndex hTargetIndex; assumption)
      | (apply PsKernelStructureEtaCompareJudgment.environment_weaken sourceEnvironment targetEnvironment hExt hSourceIndex hTargetIndex; assumption)
termination_by structural h

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
  cases h
  case structural =>
    apply PsKernelBinderDomainJudgment.structural
    all_goals first
      | assumption
      | (apply psKernelEnvironmentIsNonRecStructure_environment_weaken
          sourceEnvironment targetEnvironment hExt hSourceIndex hTargetIndex; assumption)
  case defeq =>
    apply PsKernelBinderDomainJudgment.defeq
    all_goals first
      | assumption
      | (apply psKernelEnvironmentIsNonRecStructure_environment_weaken
          sourceEnvironment targetEnvironment hExt hSourceIndex hTargetIndex; assumption)
      | (apply PsKernelDefEqJudgment.environment_weaken sourceEnvironment targetEnvironment hExt hSourceIndex hTargetIndex; assumption)
termination_by structural h

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
  cases h
  case terminal =>
    apply PsKernelLambdaSpineJudgment.terminal
    all_goals first
      | assumption
      | (apply psKernelEnvironmentIsNonRecStructure_environment_weaken
          sourceEnvironment targetEnvironment hExt hSourceIndex hTargetIndex; assumption)
      | (apply PsKernelDefEqJudgment.environment_weaken sourceEnvironment targetEnvironment hExt hSourceIndex hTargetIndex; assumption)
  case stepOpen =>
    apply PsKernelLambdaSpineJudgment.stepOpen
    all_goals first
      | assumption
      | (apply psKernelEnvironmentIsNonRecStructure_environment_weaken
          sourceEnvironment targetEnvironment hExt hSourceIndex hTargetIndex; assumption)
      | (apply PsKernelBinderDomainJudgment.environment_weaken sourceEnvironment targetEnvironment hExt hSourceIndex hTargetIndex; assumption)
      | (apply PsKernelLambdaSpineJudgment.environment_weaken sourceEnvironment targetEnvironment hExt hSourceIndex hTargetIndex; assumption)
  case stepClosed =>
    apply PsKernelLambdaSpineJudgment.stepClosed
    all_goals first
      | assumption
      | (apply psKernelEnvironmentIsNonRecStructure_environment_weaken
          sourceEnvironment targetEnvironment hExt hSourceIndex hTargetIndex; assumption)
      | (apply PsKernelBinderDomainJudgment.environment_weaken sourceEnvironment targetEnvironment hExt hSourceIndex hTargetIndex; assumption)
      | (apply PsKernelLambdaSpineJudgment.environment_weaken sourceEnvironment targetEnvironment hExt hSourceIndex hTargetIndex; assumption)
termination_by structural h

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
  cases h
  case terminal =>
    apply PsKernelForallSpineJudgment.terminal
    all_goals first
      | assumption
      | (apply psKernelEnvironmentIsNonRecStructure_environment_weaken
          sourceEnvironment targetEnvironment hExt hSourceIndex hTargetIndex; assumption)
      | (apply PsKernelDefEqJudgment.environment_weaken sourceEnvironment targetEnvironment hExt hSourceIndex hTargetIndex; assumption)
  case stepOpen =>
    apply PsKernelForallSpineJudgment.stepOpen
    all_goals first
      | assumption
      | (apply psKernelEnvironmentIsNonRecStructure_environment_weaken
          sourceEnvironment targetEnvironment hExt hSourceIndex hTargetIndex; assumption)
      | (apply PsKernelBinderDomainJudgment.environment_weaken sourceEnvironment targetEnvironment hExt hSourceIndex hTargetIndex; assumption)
      | (apply PsKernelForallSpineJudgment.environment_weaken sourceEnvironment targetEnvironment hExt hSourceIndex hTargetIndex; assumption)
  case stepClosed =>
    apply PsKernelForallSpineJudgment.stepClosed
    all_goals first
      | assumption
      | (apply psKernelEnvironmentIsNonRecStructure_environment_weaken
          sourceEnvironment targetEnvironment hExt hSourceIndex hTargetIndex; assumption)
      | (apply PsKernelBinderDomainJudgment.environment_weaken sourceEnvironment targetEnvironment hExt hSourceIndex hTargetIndex; assumption)
      | (apply PsKernelForallSpineJudgment.environment_weaken sourceEnvironment targetEnvironment hExt hSourceIndex hTargetIndex; assumption)
termination_by structural h

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
  cases h
  case done =>
    apply PsKernelProjectionApplyParamsJudgment.done
    all_goals first
      | assumption
      | (apply psKernelEnvironmentIsNonRecStructure_environment_weaken
          sourceEnvironment targetEnvironment hExt hSourceIndex hTargetIndex; assumption)
  case step =>
    apply PsKernelProjectionApplyParamsJudgment.step
    all_goals first
      | assumption
      | (apply psKernelEnvironmentIsNonRecStructure_environment_weaken
          sourceEnvironment targetEnvironment hExt hSourceIndex hTargetIndex; assumption)
      | (apply PsKernelReductionClosure.environment_weaken sourceEnvironment targetEnvironment hExt hSourceIndex hTargetIndex; assumption)
      | (apply PsKernelProjectionApplyParamsJudgment.environment_weaken sourceEnvironment targetEnvironment hExt hSourceIndex hTargetIndex; assumption)
termination_by structural h

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
  cases h
  case done =>
    apply PsKernelProjectionSkipFieldsJudgment.done
    all_goals first
      | assumption
      | (apply psKernelEnvironmentIsNonRecStructure_environment_weaken
          sourceEnvironment targetEnvironment hExt hSourceIndex hTargetIndex; assumption)
  case stepClosed =>
    apply PsKernelProjectionSkipFieldsJudgment.stepClosed
    all_goals first
      | assumption
      | (apply psKernelEnvironmentIsNonRecStructure_environment_weaken
          sourceEnvironment targetEnvironment hExt hSourceIndex hTargetIndex; assumption)
      | (apply PsKernelReductionClosure.environment_weaken sourceEnvironment targetEnvironment hExt hSourceIndex hTargetIndex; assumption)
      | (apply PsKernelProjectionSkipFieldsJudgment.environment_weaken sourceEnvironment targetEnvironment hExt hSourceIndex hTargetIndex; assumption)
  case stepDependent =>
    apply PsKernelProjectionSkipFieldsJudgment.stepDependent
    all_goals first
      | assumption
      | (apply psKernelEnvironmentIsNonRecStructure_environment_weaken
          sourceEnvironment targetEnvironment hExt hSourceIndex hTargetIndex; assumption)
      | (apply PsKernelReductionClosure.environment_weaken sourceEnvironment targetEnvironment hExt hSourceIndex hTargetIndex; assumption)
      | (apply PsKernelProjectionSkipFieldsJudgment.environment_weaken sourceEnvironment targetEnvironment hExt hSourceIndex hTargetIndex; assumption)
termination_by structural h

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
  cases h
  case intro =>
    apply PsKernelProjectionResultJudgment.intro
    all_goals first
      | assumption
      | (apply psKernelEnvironmentIsNonRecStructure_environment_weaken
          sourceEnvironment targetEnvironment hExt hSourceIndex hTargetIndex; assumption)
      | (apply hExt.1; assumption)
      | (apply PsKernelReductionClosure.environment_weaken sourceEnvironment targetEnvironment hExt hSourceIndex hTargetIndex; assumption)
      | (apply PsKernelProjectionApplyParamsJudgment.environment_weaken sourceEnvironment targetEnvironment hExt hSourceIndex hTargetIndex; assumption)
      | (apply PsKernelProjectionSkipFieldsJudgment.environment_weaken sourceEnvironment targetEnvironment hExt hSourceIndex hTargetIndex; assumption)
termination_by structural h

theorem PsKernelTypingJudgment.environment_weaken
    (sourceEnvironment targetEnvironment : PsKernelEnvironment)
    (hExt : PsKernelEnvironmentSemanticExtends sourceEnvironment targetEnvironment)
    (hSourceIndex : PsKernelEnvironmentIndexRefines sourceEnvironment)
    (hTargetIndex : PsKernelEnvironmentIndexRefines targetEnvironment)
    {localContext : PsKernelLocalContext}
    {expr type : PsKernelExpr}
    (h : PsKernelTypingJudgment sourceEnvironment localContext expr type) :
    PsKernelTypingJudgment targetEnvironment localContext expr type := by
  cases h
  case presentation =>
    apply PsKernelTypingJudgment.presentation
    all_goals first
      | assumption
      | (apply psKernelEnvironmentIsNonRecStructure_environment_weaken
          sourceEnvironment targetEnvironment hExt hSourceIndex hTargetIndex; assumption)
      | (apply PsKernelTypingJudgment.environment_weaken sourceEnvironment targetEnvironment hExt hSourceIndex hTargetIndex; assumption)
  case contextWeaken =>
    apply PsKernelTypingJudgment.contextWeaken
    all_goals first
      | assumption
      | (apply psKernelEnvironmentIsNonRecStructure_environment_weaken
          sourceEnvironment targetEnvironment hExt hSourceIndex hTargetIndex; assumption)
      | (apply PsKernelTypingJudgment.environment_weaken sourceEnvironment targetEnvironment hExt hSourceIndex hTargetIndex; assumption)
  case convert =>
    apply PsKernelTypingJudgment.convert
    all_goals first
      | assumption
      | (apply psKernelEnvironmentIsNonRecStructure_environment_weaken
          sourceEnvironment targetEnvironment hExt hSourceIndex hTargetIndex; assumption)
      | (apply PsKernelDefEqJudgment.environment_weaken sourceEnvironment targetEnvironment hExt hSourceIndex hTargetIndex; assumption)
      | (apply PsKernelTypingJudgment.environment_weaken sourceEnvironment targetEnvironment hExt hSourceIndex hTargetIndex; assumption)
  case sort =>
    apply PsKernelTypingJudgment.sort
    all_goals first
      | assumption
      | (apply psKernelEnvironmentIsNonRecStructure_environment_weaken
          sourceEnvironment targetEnvironment hExt hSourceIndex hTargetIndex; assumption)
  case natLiteral =>
    apply PsKernelTypingJudgment.natLiteral
    all_goals first
      | assumption
      | (apply psKernelEnvironmentIsNonRecStructure_environment_weaken
          sourceEnvironment targetEnvironment hExt hSourceIndex hTargetIndex; assumption)
  case stringLiteral =>
    apply PsKernelTypingJudgment.stringLiteral
    all_goals first
      | assumption
      | (apply psKernelEnvironmentIsNonRecStructure_environment_weaken
          sourceEnvironment targetEnvironment hExt hSourceIndex hTargetIndex; assumption)
  case fvar =>
    apply PsKernelTypingJudgment.fvar
    all_goals first
      | assumption
      | (apply psKernelEnvironmentIsNonRecStructure_environment_weaken
          sourceEnvironment targetEnvironment hExt hSourceIndex hTargetIndex; assumption)
  case const =>
    apply PsKernelTypingJudgment.const
    all_goals first
      | assumption
      | (apply psKernelEnvironmentIsNonRecStructure_environment_weaken
          sourceEnvironment targetEnvironment hExt hSourceIndex hTargetIndex; assumption)
      | (apply hExt.1; assumption)
  case app =>
    apply PsKernelTypingJudgment.app
    all_goals first
      | assumption
      | (apply psKernelEnvironmentIsNonRecStructure_environment_weaken
          sourceEnvironment targetEnvironment hExt hSourceIndex hTargetIndex; assumption)
      | (apply PsKernelDefEqJudgment.environment_weaken sourceEnvironment targetEnvironment hExt hSourceIndex hTargetIndex; assumption)
      | (apply PsKernelTypingJudgment.environment_weaken sourceEnvironment targetEnvironment hExt hSourceIndex hTargetIndex; assumption)
  case lam =>
    apply PsKernelTypingJudgment.lam
    all_goals first
      | assumption
      | (apply psKernelEnvironmentIsNonRecStructure_environment_weaken
          sourceEnvironment targetEnvironment hExt hSourceIndex hTargetIndex; assumption)
      | (apply PsKernelTypingJudgment.environment_weaken sourceEnvironment targetEnvironment hExt hSourceIndex hTargetIndex; assumption)
  case forallE =>
    apply PsKernelTypingJudgment.forallE
    all_goals first
      | assumption
      | (apply psKernelEnvironmentIsNonRecStructure_environment_weaken
          sourceEnvironment targetEnvironment hExt hSourceIndex hTargetIndex; assumption)
      | (apply PsKernelTypingJudgment.environment_weaken sourceEnvironment targetEnvironment hExt hSourceIndex hTargetIndex; assumption)
  case letE =>
    apply PsKernelTypingJudgment.letE
    all_goals first
      | assumption
      | (apply psKernelEnvironmentIsNonRecStructure_environment_weaken
          sourceEnvironment targetEnvironment hExt hSourceIndex hTargetIndex; assumption)
      | (apply PsKernelDefEqJudgment.environment_weaken sourceEnvironment targetEnvironment hExt hSourceIndex hTargetIndex; assumption)
      | (apply PsKernelTypingJudgment.environment_weaken sourceEnvironment targetEnvironment hExt hSourceIndex hTargetIndex; assumption)
  case mdata =>
    apply PsKernelTypingJudgment.mdata
    all_goals first
      | assumption
      | (apply psKernelEnvironmentIsNonRecStructure_environment_weaken
          sourceEnvironment targetEnvironment hExt hSourceIndex hTargetIndex; assumption)
      | (apply PsKernelTypingJudgment.environment_weaken sourceEnvironment targetEnvironment hExt hSourceIndex hTargetIndex; assumption)
  case proj =>
    apply PsKernelTypingJudgment.proj
    all_goals first
      | assumption
      | (apply psKernelEnvironmentIsNonRecStructure_environment_weaken
          sourceEnvironment targetEnvironment hExt hSourceIndex hTargetIndex; assumption)
      | (apply PsKernelProjectionResultJudgment.environment_weaken sourceEnvironment targetEnvironment hExt hSourceIndex hTargetIndex; assumption)
      | (apply PsKernelTypingJudgment.environment_weaken sourceEnvironment targetEnvironment hExt hSourceIndex hTargetIndex; assumption)
termination_by structural h

end


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
