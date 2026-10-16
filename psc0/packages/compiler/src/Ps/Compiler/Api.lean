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

-- The official checker sees the public independently inhabited opaque
-- declaration, and the private actual source body through a separately
-- checked opaque implementation marker. For *ordinary execution only*,
-- connect that actual body to the public runtime name. This transformation
-- is not a new proof equation and must never replace the canonical checked
-- Core graph or be called to authorize verified emission.
def psCompilerOrdinaryPartialRuntimeDeclarations
    (declarations : List PsDeclaration) :
    Except PsCompilerError (List PsDeclaration) := do
  let implementations := declarations.filter fun declaration =>
    match declaration with | .partialDecl .. => true | _ => false
  for implementation in implementations do
    let .partialDecl privateName levels type _ := implementation
      | throw (.normalization "PSCV0-PARTIAL: malformed implementation marker")
    let owners := declarations.filter fun declaration =>
      match declaration with
      | .opaqueDecl name .. => psNameEq (PsName.num name 0) privateName
      | _ => false
    match owners with
    | [.opaqueDecl _ publicLevels publicType _] =>
        if levels.length != publicLevels.length ||
            !(levels.zip publicLevels).all (fun pair =>
              psNameEq pair.fst pair.snd) ||
            !psExprAlphaEq type publicType then
          throw (.normalization "PSCV0-PARTIAL: private implementation/type mismatch")
    | _ => throw (.normalization "PSCV0-PARTIAL: missing unique opaque logical owner")
  return declarations.filterMap fun declaration =>
    match declaration with
    | .partialDecl .. => none
    | .opaqueDecl name levels type _ =>
        let candidate := implementations.find? fun implementation =>
          match implementation with
          | .partialDecl privateName .. =>
              psNameEq (PsName.num name 0) privateName
          | _ => false
        match candidate with
        | some (.partialDecl _ _ _ body) =>
            some (.definitionDecl name levels type body)
        | _ => some declaration
    | _ => some declaration

-- Host-owned execution may erase a runtime representation ONLY after it
-- checked the ORIGINAL canonical logical admissions with Lean 4.35.0.
-- Keep the source logical environment; change only the runtime declaration
-- bodies/identities passed to erasure. The resulting IR still requires the
-- full typed validator and backend capability checks.
def psCompilerErasePreparedRuntimeView
    (prepared : PsCompilerAdmissionReadyModule)
    (runtimeDeclarations : List PsDeclaration)
    (targetWordSize : Option PsVerifiedIrWordSize := none) :
    Except PsCompilerError PsVerifiedIrModule := do
  let environment ← psCompilerEnvironmentFromPrepared prepared
  let runtimePrelude := psSelfHostRuntimePreludeDeclarationsWithProd ++
    (if targetWordSize.isSome then psStandardPlatformRuntimeDeclarations ++
      psStandardOperatorProtocolRuntimeDeclarations environment true else [])
  (psEraseCoreModuleWithRuntimePrelude
    environment
    runtimePrelude
    runtimeDeclarations
    (runtimePrelude.map psDeclarationName) targetWordSize).mapError
      PsCompilerError.erasure

-- Ordinary partial execution only. The native host must have already
-- independently kernel-accepted psCompilerLogicalCheckingView on the exact
-- original prepared graph. A caller cannot mint proof authority via this API.
def psCompilerOrdinaryPartialIrFromCheckedPrepared
    (prepared : PsCompilerAdmissionReadyModule)
    (targetWordSize : Option PsVerifiedIrWordSize := none) :
    Except PsCompilerError PsVerifiedIrModule := do
  let runtime ← psCompilerOrdinaryPartialRuntimeDeclarations prepared.declarations
  psCompilerErasePreparedRuntimeView prepared runtime targetWordSize

def psCompilerVerifiedIrFromPrepared
    (prepared : PsCompilerAdmissionReadyModule)
    (targetWordSize : Option PsVerifiedIrWordSize := none) :
    Except PsCompilerError PsVerifiedIrModule := do
  -- The general source/library API must remain fail-closed for partial
  -- implementations. Only the native host's explicitly ordinary runtime
  -- path may lower the paired body, after real official kernel admission.
  if prepared.declarations.any (fun declaration =>
      match declaration with | .partialDecl .. => true | _ => false) then
    throw (.normalization "PSCV0-PARTIAL-RUNTIME-PENDING: partial logical checking does not admit executable output")
  psCompilerErasePreparedRuntimeView prepared prepared.declarations targetWordSize

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
