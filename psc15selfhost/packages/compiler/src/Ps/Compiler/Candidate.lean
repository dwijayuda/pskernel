import Ps.Compiler.Frontend

-- Canonical preparation produces candidate data, never checked authority.
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

structure PsCompilerSourcePreparationState where
  environment : PsEnvironment
  declarationsRev : List PsDeclaration

def psCompilerSourcePreparationInitial :
    PsCompilerSourcePreparationState :=
  PsCompilerSourcePreparationState.mk
    psSelfHostProdPreludeEnvironment
    List.nil

structure PsCompilerParsedSourceStep where
  state : PsCompilerSourcePreparationState
  sourceModule : PsSyntaxModule

def psCompilerParseSourceStep
    (sourceKind : PsCompilerSourceKind)
    (state : PsCompilerSourcePreparationState)
    (source : String) :
    Except PsCompilerError PsCompilerParsedSourceStep :=
  match psCompilerParseSource sourceKind source with
  | Except.error error =>
      Except.error error
  | Except.ok sourceModule =>
      Except.ok
        (PsCompilerParsedSourceStep.mk
          state
          sourceModule)

def psCompilerElaborateParsedSourceStep
    (parsed : PsCompilerParsedSourceStep) :
    Except PsCompilerError PsCompilerSourcePreparationState :=
  match
      psElabModule
        parsed.state.environment
        parsed.sourceModule with
  | Except.error error =>
      Except.error (PsCompilerError.elaboration error)
  | Except.ok elaborated =>
      Except.ok
        (PsCompilerSourcePreparationState.mk
          elaborated.environment
          (psListAppend
            (psListReverse elaborated.declarations)
            parsed.state.declarationsRev))

def psCompilerPrepareSourceStep
    (sourceKind : PsCompilerSourceKind)
    (state : PsCompilerSourcePreparationState)
    (source : String) :
    Except PsCompilerError PsCompilerSourcePreparationState :=
  match
      psCompilerParseSourceStep
        sourceKind
        state
        source with
  | Except.error error =>
      Except.error error
  | Except.ok parsed =>
      psCompilerElaborateParsedSourceStep parsed

def psCompilerFinishSourcePreparation
    (state : PsCompilerSourcePreparationState) :
    Except PsCompilerError PsCompilerAdmissionReadyModule :=
  psCompilerPrepareElaborated
    (PsElabModuleResult.mk
      state.environment
      (psListReverse state.declarationsRev))

def psCompilerElaborateSourcesWorker
    (sourceKind : PsCompilerSourceKind) (sources : List String) :
    PsEnvironment -> List PsDeclaration -> Except PsCompilerError PsElabModuleResult :=
  match sources with
  | List.nil =>
      fun (environment : PsEnvironment) (declarationsRev : List PsDeclaration) =>
        Except.ok (PsElabModuleResult.mk environment (psListReverse declarationsRev))
  | List.cons source rest =>
      let smaller : PsEnvironment -> List PsDeclaration -> Except PsCompilerError PsElabModuleResult :=
        psCompilerElaborateSourcesWorker sourceKind rest;
      fun (environment : PsEnvironment) (declarationsRev : List PsDeclaration) =>
        match psCompilerParseSource sourceKind source with
        | Except.error error => Except.error error
        | Except.ok sourceModule =>
            match psElabModule environment sourceModule with
            | Except.error error => Except.error (PsCompilerError.elaboration error)
            | Except.ok elaborated =>
                smaller elaborated.environment
                  (psListAppend (psListReverse elaborated.declarations) declarationsRev)

def psCompilerPrepareSources
    (sourceKind : PsCompilerSourceKind) (sources : List String) :
    Except PsCompilerError PsCompilerAdmissionReadyModule :=
  match psCompilerElaborateSourcesWorker sourceKind sources psSelfHostProdPreludeEnvironment List.nil with
  | Except.error error => Except.error error
  | Except.ok elaborated => psCompilerPrepareElaborated elaborated


def psCompilerSelfHostSourceListEmpty : List String :=
  List.nil

def psCompilerSelfHostSourceListCons
    (source : String)
    (rest : List String) : List String :=
  List.cons source rest

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

