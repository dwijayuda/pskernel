import Ps.Syntax.Translate
import Ps.Bridge.CheckedAdmissions
import Ps.Environment.SelfHostProd
import Ps.Elab.Declaration
import Ps.Erasure.Definition

inductive PsCompilerSourceKind where
  | lean
  | proofScript

inductive PsCompilerError where
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

def psCompilerPrepareElaborated
    (elaborated : PsElabModuleResult) :
    Except PsCompilerError PsCompilerAdmissionReadyModule :=
  match
      psEncodeCheckedAdmissionsCanonical
        elaborated.declarations with
  | Except.error error =>
      Except.error (PsCompilerError.admission error)
  | Except.ok _ =>
      Except.ok (PsCompilerAdmissionReadyModule.mk elaborated.declarations)

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

def psCompilerPreparationStepParsed
    (state : PsCompilerPreparationState)
    (sourceModule : PsSyntaxModule) :
    Except PsCompilerError PsCompilerPreparationState :=
  match psElabModule state.environment sourceModule with
  | Except.error error =>
      Except.error (PsCompilerError.elaboration error)
  | Except.ok elaborated =>
      Except.ok
        (PsCompilerPreparationState.mk
          state.sourceKind elaborated.environment
          (psListAppend (psListReverse elaborated.declarations) state.declarationsRev))

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

def psCompilerPreparationFinish
    (state : PsCompilerPreparationState) :
    Except PsCompilerError PsCompilerAdmissionReadyModule :=
  psCompilerPrepareElaborated (psCompilerPreparationElaborated state)

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
        prepared.declarations with
  | Except.error error =>
      Except.error (PsCompilerError.admission error)
  | Except.ok _ =>
      Except.ok Unit.unit

def psCompilerAdmissionsFromPrepared
    (prepared : PsCompilerAdmissionReadyModule) :
    Except PsCompilerError String :=
  match psEncodeCheckedAdmissionsCanonical prepared.declarations with
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
    (prepared : PsCompilerAdmissionReadyModule) :
    Except PsCompilerError PsVerifiedIrModule :=
  match psCompilerEnvironmentFromPrepared prepared with
  | Except.error error =>
      Except.error error
  | Except.ok environment =>
      match
          psEraseCoreModuleWithRuntimePrelude
            environment
            psSelfHostRuntimePreludeDeclarationsWithProd
            prepared.declarations with
      | Except.error error =>
          Except.error (PsCompilerError.erasure error)
      | Except.ok ir =>
          Except.ok ir

def psCompilerVerifiedIrFromElaborated
    (elaborated : PsElabModuleResult) :
    Except PsCompilerError PsVerifiedIrModule :=
  match psCompilerPrepareElaborated elaborated with
  | Except.error error =>
      Except.error error
  | Except.ok prepared =>
      psCompilerVerifiedIrFromPrepared prepared

def psCompilerVerifiedIrSource
    (sourceKind : PsCompilerSourceKind)
    (source : String) :
    Except PsCompilerError PsVerifiedIrModule :=
  match psCompilerPrepareSource sourceKind source with
  | Except.error error =>
      Except.error error
  | Except.ok prepared =>
      psCompilerVerifiedIrFromPrepared prepared


-- Project preparation retains source ownership beside the ordinary declaration
-- stream. These are preparation facts, never kernel admission capabilities.
structure PsCompilerProjectSource where
  sourceId : String
  source : String
  exports : List String

structure PsCompilerProjectOwner where
  sourceId : String
  declarations : List PsName
  exports : List PsName

structure PsCompilerAdmissionReadyProject where
  prepared : PsCompilerAdmissionReadyModule
  owners : List PsCompilerProjectOwner

inductive PsCompilerProjectError where
  | compiler (error : PsCompilerError)
  | invalidExport (detail : String)

def psCompilerMakeProjectSource
    (sourceId source : String) (exports : List String) : PsCompilerProjectSource :=
  PsCompilerProjectSource.mk sourceId source exports

def psCompilerProjectAuthoredName (declaration : PsSyntaxDeclaration) : Option PsName :=
  let syntaxName : PsSyntaxName :=
    match declaration with
    | PsSyntaxDeclaration.definition name _ _ _ _ => name
    | PsSyntaxDeclaration.partialDefinition name _ _ _ _ => name
    | PsSyntaxDeclaration.theoremDecl name _ _ _ _ => name
    | PsSyntaxDeclaration.inductiveDecl name _ _ _ _ => name
    | PsSyntaxDeclaration.structureDecl name _ _ _ => name;
  psSyntaxNameToName syntaxName

def psCompilerProjectAuthoredNames
    (declarations : List PsSyntaxDeclaration) : List PsName :=
  match declarations with
  | List.nil => List.nil
  | List.cons declaration rest =>
      match psCompilerProjectAuthoredName declaration with
      | Option.none => psCompilerProjectAuthoredNames rest
      | Option.some name => List.cons name (psCompilerProjectAuthoredNames rest)

def psCompilerProjectFindName (names : List PsName) : String -> Option PsName :=
  match names with
  | List.nil => fun (_target : String) => Option.none
  | List.cons name rest =>
      let smaller : String -> Option PsName := psCompilerProjectFindName rest;
      fun (target : String) =>
        if psStringEq (psNameToString name) target then Option.some name
        else smaller target

def psCompilerProjectIdentifierTail (chars : List Char) : Bool :=
  match chars with
  | List.nil => true
  | List.cons char rest =>
      if psErasureAsciiAlpha char then psCompilerProjectIdentifierTail rest
      else if psErasureNatBetween 48 (Char.toNat char) 57 then psCompilerProjectIdentifierTail rest
      else if Nat.beq (Char.toNat char) 95 then psCompilerProjectIdentifierTail rest
      else if Nat.beq (Char.toNat char) 36 then psCompilerProjectIdentifierTail rest
      else false

def psCompilerProjectIdentifier (name : String) : Bool :=
  let reserved : List String :=
    ["await", "break", "case", "catch", "class", "const", "continue",
     "debugger", "default", "delete", "do", "else", "enum", "export",
     "extends", "false", "finally", "for", "function", "if", "import",
     "in", "instanceof", "let", "new", "null", "return", "super",
     "switch", "this", "throw", "true", "try", "typeof", "var",
     "void", "while", "with", "yield", "implements", "interface",
     "package", "private", "protected", "public", "static"];
  let same : String -> Bool := fun (value : String) => psStringEq name value;
  if psListAny same reserved then false
  else
    match psJsonStringToChars name with
    | List.nil => false
    | List.cons first rest =>
        if psErasureAsciiAlpha first then psCompilerProjectIdentifierTail rest
        else if Nat.beq (Char.toNat first) 95 then psCompilerProjectIdentifierTail rest
        else if Nat.beq (Char.toNat first) 36 then psCompilerProjectIdentifierTail rest
        else false

def psCompilerProjectSelectExports
    (authored declared : List PsName)
    (requested : List String) : Except PsCompilerProjectError (List PsName) :=
  match requested with
  | List.nil => Except.ok List.nil
  | List.cons name rest =>
      let duplicate : String -> Bool := fun (other : String) => psStringEq name other;
      if psListAny duplicate rest then Except.error (PsCompilerProjectError.invalidExport name)
      else if psCompilerProjectIdentifier name then
        match psCompilerProjectFindName authored name with
        | Option.none => Except.error (PsCompilerProjectError.invalidExport name)
        | Option.some coreName =>
            match psCompilerProjectFindName declared name with
            | Option.none => Except.error (PsCompilerProjectError.invalidExport name)
            | Option.some _ =>
                match psCompilerProjectSelectExports authored declared rest with
                | Except.error error => Except.error error
                | Except.ok selected => Except.ok (List.cons coreName selected)
      else Except.error (PsCompilerProjectError.invalidExport name)

def psCompilerPrepareProjectWorker
    (sources : List PsCompilerProjectSource)
    (state : PsCompilerPreparationState)
    (ownersRev : List PsCompilerProjectOwner) :
    Except PsCompilerProjectError PsCompilerAdmissionReadyProject :=
  match sources with
  | List.nil =>
      match psCompilerPreparationFinish state with
      | Except.error error => Except.error (PsCompilerProjectError.compiler error)
      | Except.ok prepared =>
          Except.ok (PsCompilerAdmissionReadyProject.mk prepared (psListReverse ownersRev))
  | List.cons source rest =>
      let duplicate : PsCompilerProjectOwner -> Bool :=
        fun (owner : PsCompilerProjectOwner) => psStringEq owner.sourceId source.sourceId;
      if psStringEq source.sourceId "" then
        Except.error (PsCompilerProjectError.invalidExport source.sourceId)
      else if psListAny duplicate ownersRev then
        Except.error (PsCompilerProjectError.invalidExport source.sourceId)
      else
        match psCompilerParseSource state.sourceKind source.source with
        | Except.error error => Except.error (PsCompilerProjectError.compiler error)
        | Except.ok parsed =>
            match psElabModule state.environment parsed with
            | Except.error error =>
                Except.error (PsCompilerProjectError.compiler (PsCompilerError.elaboration error))
            | Except.ok elaborated =>
                let declarations := psListMap psDeclarationName elaborated.declarations;
                let authored := psCompilerProjectAuthoredNames parsed.declarations;
                match psCompilerProjectSelectExports authored declarations source.exports with
                | Except.error error => Except.error error
                | Except.ok selected =>
                    let next := PsCompilerPreparationState.mk
                      state.sourceKind elaborated.environment
                      (psListAppend (psListReverse elaborated.declarations) state.declarationsRev);
                    let owner := PsCompilerProjectOwner.mk source.sourceId declarations selected;
                    psCompilerPrepareProjectWorker rest next (List.cons owner ownersRev)

def psCompilerPrepareProject
    (sourceKind : PsCompilerSourceKind)
    (sources : List PsCompilerProjectSource) :
    Except PsCompilerProjectError PsCompilerAdmissionReadyProject :=
  psCompilerPrepareProjectWorker sources (psCompilerPreparationStart sourceKind) List.nil

def psCompilerProjectAdmissionsFromPrepared
    (project : PsCompilerAdmissionReadyProject) : Except PsCompilerError String :=
  psCompilerAdmissionsFromPrepared project.prepared
