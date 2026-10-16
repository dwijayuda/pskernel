import Ps.Syntax.Translate
import Ps.Bridge.CheckedAdmissions
import Ps.Environment.SelfHostProd
import Ps.Elab.Declaration
import Ps.Erasure.Definition
import Ps.Compiler.RecursorLift

inductive PsCompilerSourceKind where
  | lean
  | proofScript

inductive PsCompilerError where
  | normalization (message : String)
  | translation (error : PsTranslationError)
  | leanFrontend (error : PsLeanFrontendError)
  | proofScriptFrontend (error : PsProofScriptFrontendError)
  | elaboration (error : PsElabError)
  | admission (error : PsCheckedAdmissionCodecError)
  | erasure (error : PsErasureError)

structure PsCompilerAdmissionReadyModule where
  declarations : List PsDeclaration

-- A preparation checkpoint is local to one compiler instance. Keep the complete
-- environment and declaration accumulator together; neither is a checked claim.
structure PsCompilerPreparationState where
  sourceKind : PsCompilerSourceKind
  environment : PsEnvironment
  declarationsRev : List PsDeclaration

-- These are retained results, not authority tokens. The source-owned entry
-- point establishes their provenance by constructing and consuming them itself.
structure PsCompilerPreparationOutput where
  prepared : PsCompilerAdmissionReadyModule
  environment : PsEnvironment
  admissions : String
  originParents : List (PsName × PsName) := []

structure PsCompilerPreparationStepWithOriginsResult where
  state : PsCompilerPreparationState
  origins : List PsElabBatchOrigin

-- Check the retained partial implementation as an ordinary opaque body,
-- AFTER its separately inhabited public logical identity. This is a checking
-- view only: retain the original strategy marker in the prepared graph.
-- No body equation, runtime override, unchecked admission or new axiom is
-- introduced. An invalid self-reference is still rejected by the kernel.
def psCompilerLogicalCheckingView (declarations : List PsDeclaration) : List PsDeclaration :=
  declarations.map fun declaration =>
    match declaration with
    | .partialDecl name levels type value => .opaqueDecl name levels type value
    | _ => declaration

def psCompilerTranslateSource
    (sourceKind targetKind : PsCompilerSourceKind)
    (source : String) :
    Except PsCompilerError String :=
  let translated : Except PsTranslationError String :=
    match sourceKind with
    | PsCompilerSourceKind.lean =>
        match targetKind with
        | PsCompilerSourceKind.lean =>
            psCanonicalizeLeanSource source
        | PsCompilerSourceKind.proofScript =>
            psTranslateLeanToProofScript source
    | PsCompilerSourceKind.proofScript =>
        match targetKind with
        | PsCompilerSourceKind.lean =>
            psTranslateProofScriptToLean source
        | PsCompilerSourceKind.proofScript =>
            psCanonicalizeProofScriptSource source;
  match translated with
  | Except.error error =>
      Except.error (PsCompilerError.translation error)
  | Except.ok output =>
      Except.ok output

def psCompilerParseSource
    (sourceKind : PsCompilerSourceKind)
    (source : String) :
    Except PsCompilerError PsSyntaxModule :=
  match sourceKind with
  | PsCompilerSourceKind.lean =>
      match psParseLeanSource source with
      | Except.error error =>
          Except.error (PsCompilerError.leanFrontend error)
      | Except.ok sourceModule =>
          Except.ok sourceModule
  | PsCompilerSourceKind.proofScript =>
      match psParseProofScriptSource source with
      | Except.error error =>
          Except.error (PsCompilerError.proofScriptFrontend error)
      | Except.ok sourceModule =>
          Except.ok sourceModule

def psCompilerElaborateModule
    (sourceModule : PsSyntaxModule) :
    Except PsCompilerError PsElabModuleResult :=
  match psElabModule psSelfHostProdPreludeEnvironment sourceModule with
  | Except.error error =>
      Except.error (PsCompilerError.elaboration error)
  | Except.ok elaborated =>
      Except.ok elaborated

def psCompilerElaborateSource
    (sourceKind : PsCompilerSourceKind)
    (source : String) :
    Except PsCompilerError PsElabModuleResult :=
  match psCompilerParseSource sourceKind source with
  | Except.error error =>
      Except.error error
  | Except.ok sourceModule =>
      psCompilerElaborateModule sourceModule

def psCompilerPrepareElaboratedWithOutput
    (elaborated : PsElabModuleResult) :
    Except PsCompilerError PsCompilerPreparationOutput := do
  let lifted ← (psRecursorLiftDeclarationsWithOrigins elaborated.environment
    elaborated.declarations).mapError PsCompilerError.normalization
  let elaborated := lifted.result
  match
      psEncodeCheckedAdmissionsCanonical
        (psCompilerLogicalCheckingView elaborated.declarations) with
  | Except.error error =>
      Except.error (PsCompilerError.admission error)
  | Except.ok canonicalAdmissions =>
      let prepared : PsCompilerAdmissionReadyModule :=
        PsCompilerAdmissionReadyModule.mk elaborated.declarations;
      let admissions : String := String.Internal.append canonicalAdmissions "\n";
      Except.ok
        (PsCompilerPreparationOutput.mk prepared elaborated.environment admissions lifted.parents)

def psCompilerPrepareElaborated
    (elaborated : PsElabModuleResult) :
    Except PsCompilerError PsCompilerAdmissionReadyModule :=
  match psCompilerPrepareElaboratedWithOutput elaborated with
  | Except.error error => Except.error error
  | Except.ok output => Except.ok output.prepared

def psCompilerCheckElaborated
    (elaborated : PsElabModuleResult) :
    Except PsCompilerError PsCompilerAdmissionReadyModule :=
  psCompilerPrepareElaborated elaborated

def psCompilerPrepareSource
    (sourceKind : PsCompilerSourceKind)
    (source : String) :
    Except PsCompilerError PsCompilerAdmissionReadyModule :=
  match psCompilerElaborateSource sourceKind source with
  | Except.error error =>
      Except.error error
  | Except.ok elaborated =>
      psCompilerPrepareElaborated elaborated

-- Preparation remains pure. Hosts may retain a successful ordered prefix and
-- resume it only when its exact compiler, source kind and source prefix agree.
def psCompilerPreparationStart
    (sourceKind : PsCompilerSourceKind) : PsCompilerPreparationState :=
  PsCompilerPreparationState.mk
    sourceKind psSelfHostProdPreludeEnvironment List.nil

-- One actual elaboration supplies both the next state and source-local origins.
-- The surrounding source-owned caller attaches module identity to these records.
def psCompilerPreparationStepParsedWithOrigins
    (state : PsCompilerPreparationState)
    (sourceModule : PsSyntaxModule) :
    Except PsElabOriginError PsCompilerPreparationStepWithOriginsResult :=
  match psElabModuleWithOrigins state.environment sourceModule with
  | Except.error error => Except.error error
  | Except.ok elaborated =>
      let nextState : PsCompilerPreparationState :=
        PsCompilerPreparationState.mk
          state.sourceKind elaborated.result.environment
          (psListAppend
            (psListReverse elaborated.result.declarations) state.declarationsRev);
      Except.ok
        (PsCompilerPreparationStepWithOriginsResult.mk nextState elaborated.origins)

def psCompilerPreparationStepParsed
    (state : PsCompilerPreparationState)
    (sourceModule : PsSyntaxModule) :
    Except PsCompilerError PsCompilerPreparationState :=
  match psCompilerPreparationStepParsedWithOrigins state sourceModule with
  | Except.error error => Except.error (PsCompilerError.elaboration error.error)
  | Except.ok result => Except.ok result.state

def psCompilerPreparationStep
    (state : PsCompilerPreparationState)
    (source : String) :
    Except PsCompilerError PsCompilerPreparationState :=
  match psCompilerParseSource state.sourceKind source with
  | Except.error error => Except.error error
  | Except.ok sourceModule =>
      psCompilerPreparationStepParsed state sourceModule

def psCompilerPreparationElaborated
    (state : PsCompilerPreparationState) : PsElabModuleResult :=
  PsElabModuleResult.mk state.environment (psListReverse state.declarationsRev)

def psCompilerPreparationFinishWithOutput
    (state : PsCompilerPreparationState) :
    Except PsCompilerError PsCompilerPreparationOutput :=
  psCompilerPrepareElaboratedWithOutput (psCompilerPreparationElaborated state)

def psCompilerPreparationFinish
    (state : PsCompilerPreparationState) :
    Except PsCompilerError PsCompilerAdmissionReadyModule :=
  match psCompilerPreparationFinishWithOutput state with
  | Except.error error => Except.error error
  | Except.ok output => Except.ok output.prepared

def psCompilerPreparationSourcesWorker
    (sources : List String)
    (state : PsCompilerPreparationState) :
    Except PsCompilerError PsCompilerPreparationState :=
  match sources with
  | List.nil =>
      Except.ok state
  | List.cons source rest =>
      match psCompilerPreparationStep state source with
      | Except.error error => Except.error error
      | Except.ok next => psCompilerPreparationSourcesWorker rest next

def psCompilerElaborateSourcesWorker
    (sourceKind : PsCompilerSourceKind) (sources : List String) :
    PsEnvironment -> List PsDeclaration -> Except PsCompilerError PsElabModuleResult :=
  fun (environment : PsEnvironment) (declarationsRev : List PsDeclaration) =>
    match
        psCompilerPreparationSourcesWorker sources
          (PsCompilerPreparationState.mk sourceKind environment declarationsRev) with
    | Except.error error => Except.error error
    | Except.ok state => Except.ok (psCompilerPreparationElaborated state)

def psCompilerPrepareSources
    (sourceKind : PsCompilerSourceKind) (sources : List String) :
    Except PsCompilerError PsCompilerAdmissionReadyModule :=
  match
      psCompilerPreparationSourcesWorker sources
        (psCompilerPreparationStart sourceKind) with
  | Except.error error => Except.error error
  | Except.ok state => psCompilerPreparationFinish state

def psCompilerCheckSource
    (sourceKind : PsCompilerSourceKind)
    (source : String) :
    Except PsCompilerError PsCompilerAdmissionReadyModule :=
  psCompilerPrepareSource sourceKind source

def psCompilerValidatePrepared
    (prepared : PsCompilerAdmissionReadyModule) :
    Except PsCompilerError Unit :=
  match
      psEncodeCheckedAdmissionsCanonical
        (psCompilerLogicalCheckingView prepared.declarations) with
  | Except.error error =>
      Except.error (PsCompilerError.admission error)
  | Except.ok _ =>
      Except.ok Unit.unit

def psCompilerAdmissionsFromPrepared
    (prepared : PsCompilerAdmissionReadyModule) :
    Except PsCompilerError String :=
  match psEncodeCheckedAdmissionsCanonical (psCompilerLogicalCheckingView prepared.declarations) with
  | Except.error error =>
      Except.error (PsCompilerError.admission error)
  | Except.ok canonicalAdmissions =>
      Except.ok (String.Internal.append canonicalAdmissions "\n")

def psCompilerAdmissionsFromElaborated
    (elaborated : PsElabModuleResult) :
    Except PsCompilerError String :=
  match psCompilerPrepareElaborated elaborated with
  | Except.error error =>
      Except.error error
  | Except.ok prepared =>
      psCompilerAdmissionsFromPrepared prepared

def psCompilerAdmissionsSource
    (sourceKind : PsCompilerSourceKind)
    (source : String) :
    Except PsCompilerError String :=
  match psCompilerPrepareSource sourceKind source with
  | Except.error error =>
      Except.error error
  | Except.ok prepared =>
      psCompilerAdmissionsFromPrepared prepared

def psCompilerEnvironmentFromPrepared
    (prepared : PsCompilerAdmissionReadyModule) :
    Except PsCompilerError PsEnvironment :=
  match psCompilerValidatePrepared prepared with
  | Except.error error =>
      Except.error error
  | Except.ok _ =>
      match
          psAddDeclarationList
            psSelfHostProdPreludeEnvironment
            prepared.declarations with
      | Except.error error =>
          Except.error (PsCompilerError.elaboration error)
      | Except.ok environment =>
          Except.ok environment

def psCompilerVerifiedIrFromPrepared
    (prepared : PsCompilerAdmissionReadyModule)
    (targetWordSize : Option PsVerifiedIrWordSize := none) :
    Except PsCompilerError PsVerifiedIrModule := do
  -- All targets and linked modules share this boundary. In this logical-only
  -- slice, even an unused partial body blocks emission conservatively. Never
  -- erase its marker or substitute the public logical inhabitant at runtime.
  if prepared.declarations.any (fun declaration =>
      match declaration with | .partialDecl .. => true | _ => false) then
    throw (.normalization "PSCV0-PARTIAL-RUNTIME-PENDING: partial logical checking does not admit executable output")
  match psCompilerEnvironmentFromPrepared prepared with
  | Except.error error =>
      Except.error error
  | Except.ok environment =>
      let runtimePrelude := psSelfHostRuntimePreludeDeclarationsWithProd ++
        (if targetWordSize.isSome then psStandardPlatformRuntimeDeclarations ++
          psStandardOperatorProtocolRuntimeDeclarations environment true else []);
      match
          psEraseCoreModuleWithRuntimePrelude
            environment
            runtimePrelude
            prepared.declarations
            -- One authoritative runtime prelude also owns its non-exportable
            -- symbol set. A new Standard class, method or instance must never
            -- silently become a public user entry merely because a second
            -- hand-maintained name list was not updated.
            (runtimePrelude.map psDeclarationName) targetWordSize with
      | Except.error error =>
          Except.error (PsCompilerError.erasure error)
      | Except.ok ir =>
          Except.ok ir

def psCompilerVerifiedIrFromElaborated
    (elaborated : PsElabModuleResult)
    (targetWordSize : Option PsVerifiedIrWordSize := none) :
    Except PsCompilerError PsVerifiedIrModule :=
  match psCompilerPrepareElaborated elaborated with
  | Except.error error =>
      Except.error error
  | Except.ok prepared =>
      psCompilerVerifiedIrFromPrepared prepared targetWordSize

def psCompilerVerifiedIrSource
    (sourceKind : PsCompilerSourceKind)
    (source : String)
    (targetWordSize : Option PsVerifiedIrWordSize := none) :
    Except PsCompilerError PsVerifiedIrModule :=
  match psCompilerPrepareSource sourceKind source with
  | Except.error error =>
      Except.error error
  | Except.ok prepared =>
      psCompilerVerifiedIrFromPrepared prepared targetWordSize
