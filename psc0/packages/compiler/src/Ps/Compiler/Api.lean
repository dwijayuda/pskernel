import Ps.Compiler.Engine
import Ps.Environment.SelfHostProd

-- Compatibility owner for the existing Full API. Core entry points import
-- Ps.Compiler.Engine and supply their own checked profile context instead.
-- This value selects inputs; fingerprint/assumption checks and official kernel
-- admission remain the host's separate obligations.
def psCompilerFullProfileContext : PsCompilerProfileContext := {
  baseEnvironment := psSelfHostProdPreludeEnvironment
  runtimePrelude := fun environment targetWordSize =>
    psSelfHostRuntimePreludeDeclarationsWithProd ++
      (if targetWordSize.isSome then psStandardPlatformRuntimeDeclarations ++
        psStandardOperatorProtocolRuntimeDeclarations environment true else []) }

private def psCompilerFullBindElaborated (elaborated : PsElabModuleResult) :
    PsCompilerEngineElaborated :=
  PsCompilerEngineElaborated.mk elaborated.environment elaborated.declarations
    psCompilerFullProfileContext

private def psCompilerFullElaboratedResult (elaborated : PsCompilerEngineElaborated) :
    PsElabModuleResult :=
  PsElabModuleResult.mk elaborated.environment elaborated.declarations

private def psCompilerFullBindPrepared (prepared : PsCompilerAdmissionReadyModule) :
    PsCompilerEnginePrepared :=
  PsCompilerEnginePrepared.mk prepared.declarations prepared.recursorWorkerGroups
    prepared.noncomputableNames psCompilerFullProfileContext

private def psCompilerFullPreparedResult (prepared : PsCompilerEnginePrepared) :
    PsCompilerAdmissionReadyModule :=
  PsCompilerAdmissionReadyModule.mk prepared.declarations prepared.recursorWorkerGroups
    prepared.noncomputableNames

private def psCompilerFullBindState (state : PsCompilerPreparationState) :
    PsCompilerEnginePreparationState :=
  PsCompilerEnginePreparationState.mk state.sourceKind state.environment
    state.declarationsRev psCompilerFullProfileContext

private def psCompilerFullStateResult (state : PsCompilerEnginePreparationState) :
    PsCompilerPreparationState :=
  PsCompilerPreparationState.mk state.sourceKind state.environment state.declarationsRev

private def psCompilerFullOutputResult (output : PsCompilerEnginePreparationOutput) :
    PsCompilerPreparationOutput :=
  PsCompilerPreparationOutput.mk (psCompilerFullPreparedResult output.prepared)
    output.environment output.admissions output.originParents

private def psCompilerFullStepResult
    (result : PsCompilerEnginePreparationStepWithOriginsResult) :
    PsCompilerPreparationStepWithOriginsResult :=
  PsCompilerPreparationStepWithOriginsResult.mk
    (psCompilerFullStateResult result.state) result.origins

def psCompilerElaborateModule
    (sourceModule : PsSyntaxModule) :
    Except PsCompilerError PsElabModuleResult :=
  (psCompilerEngineElaborateModule psCompilerFullProfileContext sourceModule).map
    psCompilerFullElaboratedResult

def psCompilerElaborateSource
    (sourceKind : PsCompilerSourceKind)
    (source : String) :
    Except PsCompilerError PsElabModuleResult :=
  (psCompilerEngineElaborateSource psCompilerFullProfileContext sourceKind source).map
    psCompilerFullElaboratedResult

def psCompilerPrepareElaboratedWithOutput
    (elaborated : PsElabModuleResult) :
    Except PsCompilerError PsCompilerPreparationOutput :=
  (psCompilerEnginePrepareElaboratedWithOutput
    (psCompilerFullBindElaborated elaborated)).map psCompilerFullOutputResult

def psCompilerPrepareElaborated
    (elaborated : PsElabModuleResult) :
    Except PsCompilerError PsCompilerAdmissionReadyModule :=
  (psCompilerEnginePrepareElaborated
    (psCompilerFullBindElaborated elaborated)).map psCompilerFullPreparedResult

def psCompilerCheckElaborated
    (elaborated : PsElabModuleResult) :
    Except PsCompilerError PsCompilerAdmissionReadyModule :=
  (psCompilerEngineCheckElaborated
    (psCompilerFullBindElaborated elaborated)).map psCompilerFullPreparedResult

def psCompilerPrepareSource
    (sourceKind : PsCompilerSourceKind)
    (source : String) :
    Except PsCompilerError PsCompilerAdmissionReadyModule :=
  (psCompilerEnginePrepareSource psCompilerFullProfileContext sourceKind source).map
    psCompilerFullPreparedResult

def psCompilerPreparationStart
    (sourceKind : PsCompilerSourceKind) : PsCompilerPreparationState :=
  psCompilerFullStateResult
    (psCompilerEnginePreparationStart psCompilerFullProfileContext sourceKind)

def psCompilerPreparationStepParsedWithOrigins
    (state : PsCompilerPreparationState)
    (sourceModule : PsSyntaxModule) :
    Except PsElabOriginError PsCompilerPreparationStepWithOriginsResult :=
  (psCompilerEnginePreparationStepParsedWithOrigins
    (psCompilerFullBindState state) sourceModule).map psCompilerFullStepResult

def psCompilerPreparationStepParsed
    (state : PsCompilerPreparationState)
    (sourceModule : PsSyntaxModule) :
    Except PsCompilerError PsCompilerPreparationState :=
  (psCompilerEnginePreparationStepParsed
    (psCompilerFullBindState state) sourceModule).map psCompilerFullStateResult

def psCompilerPreparationStep
    (state : PsCompilerPreparationState)
    (source : String) :
    Except PsCompilerError PsCompilerPreparationState :=
  (psCompilerEnginePreparationStep (psCompilerFullBindState state) source).map
    psCompilerFullStateResult

def psCompilerPreparationElaborated
    (state : PsCompilerPreparationState) : PsElabModuleResult :=
  psCompilerFullElaboratedResult
    (psCompilerEnginePreparationElaborated (psCompilerFullBindState state))

def psCompilerPreparationFinishWithOutput
    (state : PsCompilerPreparationState) :
    Except PsCompilerError PsCompilerPreparationOutput :=
  (psCompilerEnginePreparationFinishWithOutput
    (psCompilerFullBindState state)).map psCompilerFullOutputResult

def psCompilerPreparationFinish
    (state : PsCompilerPreparationState) :
    Except PsCompilerError PsCompilerAdmissionReadyModule :=
  (psCompilerEnginePreparationFinish
    (psCompilerFullBindState state)).map psCompilerFullPreparedResult

def psCompilerPreparationSourcesWorker
    (sources : List String)
    (state : PsCompilerPreparationState) :
    Except PsCompilerError PsCompilerPreparationState :=
  (psCompilerEnginePreparationSourcesWorker
    sources (psCompilerFullBindState state)).map psCompilerFullStateResult

def psCompilerElaborateSourcesWorker
    (sourceKind : PsCompilerSourceKind) (sources : List String) :
    PsEnvironment -> List PsDeclaration -> Except PsCompilerError PsElabModuleResult :=
  fun (environment : PsEnvironment) (declarationsRev : List PsDeclaration) =>
    (psCompilerEngineElaborateSourcesWorker psCompilerFullProfileContext
      sourceKind sources environment declarationsRev).map psCompilerFullElaboratedResult

def psCompilerPrepareSources
    (sourceKind : PsCompilerSourceKind) (sources : List String) :
    Except PsCompilerError PsCompilerAdmissionReadyModule :=
  (psCompilerEnginePrepareSources psCompilerFullProfileContext sourceKind sources).map
    psCompilerFullPreparedResult

def psCompilerCheckSource
    (sourceKind : PsCompilerSourceKind)
    (source : String) :
    Except PsCompilerError PsCompilerAdmissionReadyModule :=
  (psCompilerEngineCheckSource psCompilerFullProfileContext sourceKind source).map
    psCompilerFullPreparedResult

def psCompilerValidatePrepared
    (prepared : PsCompilerAdmissionReadyModule) :
    Except PsCompilerError Unit :=
  psCompilerEngineValidatePrepared (psCompilerFullBindPrepared prepared)

def psCompilerAdmissionsFromPrepared
    (prepared : PsCompilerAdmissionReadyModule) :
    Except PsCompilerError String :=
  psCompilerEngineAdmissionsFromPrepared (psCompilerFullBindPrepared prepared)

def psCompilerAdmissionsFromElaborated
    (elaborated : PsElabModuleResult) :
    Except PsCompilerError String :=
  psCompilerEngineAdmissionsFromElaborated (psCompilerFullBindElaborated elaborated)

def psCompilerAdmissionsSource
    (sourceKind : PsCompilerSourceKind)
    (source : String) :
    Except PsCompilerError String :=
  psCompilerEngineAdmissionsSource psCompilerFullProfileContext sourceKind source

def psCompilerEnvironmentFromPrepared
    (prepared : PsCompilerAdmissionReadyModule) :
    Except PsCompilerError PsEnvironment :=
  psCompilerEngineEnvironmentFromPrepared (psCompilerFullBindPrepared prepared)

def psCompilerErasePreparedRuntimeView
    (prepared : PsCompilerAdmissionReadyModule)
    (runtimeDeclarations : List PsDeclaration)
    (targetWordSize : Option PsVerifiedIrWordSize := none) :
    Except PsCompilerError PsVerifiedIrModule :=
  psCompilerEngineErasePreparedRuntimeView
    (psCompilerFullBindPrepared prepared) runtimeDeclarations targetWordSize

def psCompilerOrdinaryPartialIrFromCheckedPrepared
    (prepared : PsCompilerAdmissionReadyModule)
    (targetWordSize : Option PsVerifiedIrWordSize := none) :
    Except PsCompilerError PsVerifiedIrModule :=
  psCompilerEngineOrdinaryPartialIrFromCheckedPrepared
    (psCompilerFullBindPrepared prepared) targetWordSize

def psCompilerVerifiedIrFromPrepared
    (prepared : PsCompilerAdmissionReadyModule)
    (targetWordSize : Option PsVerifiedIrWordSize := none) :
    Except PsCompilerError PsVerifiedIrModule :=
  psCompilerEngineVerifiedIrFromPrepared (psCompilerFullBindPrepared prepared) targetWordSize

def psCompilerVerifiedIrFromElaborated
    (elaborated : PsElabModuleResult)
    (targetWordSize : Option PsVerifiedIrWordSize := none) :
    Except PsCompilerError PsVerifiedIrModule :=
  psCompilerEngineVerifiedIrFromElaborated
    (psCompilerFullBindElaborated elaborated) targetWordSize

def psCompilerVerifiedIrSource
    (sourceKind : PsCompilerSourceKind)
    (source : String)
    (targetWordSize : Option PsVerifiedIrWordSize := none) :
    Except PsCompilerError PsVerifiedIrModule :=
  psCompilerEngineVerifiedIrSource
    psCompilerFullProfileContext sourceKind source targetWordSize

