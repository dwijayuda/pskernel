import Ps.Syntax.Translate
import Ps.Bridge.CheckedAdmissions
import Ps.Environment.Prelude
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
  | preparedAdmissionMismatch
  | erasure (error : PsErasureError)

structure PsCompilerAdmissionReadyModule where
  declarations : List PsDeclaration
  canonicalAdmissions : String

def psCompilerTranslateSource
    (sourceKind targetKind : PsCompilerSourceKind)
    (source : String) :
    Except PsCompilerError String :=
  let translated :=
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
  match psElabModule psBootstrapPreludeEnvironment sourceModule with
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
  | Except.ok canonicalAdmissions =>
      Except.ok {
        declarations := elaborated.declarations
        canonicalAdmissions := canonicalAdmissions
      }

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
  | Except.ok canonicalAdmissions =>
      if canonicalAdmissions == prepared.canonicalAdmissions then
        Except.ok Unit.unit
      else
        Except.error PsCompilerError.preparedAdmissionMismatch

def psCompilerAdmissionsFromPrepared
    (prepared : PsCompilerAdmissionReadyModule) :
    Except PsCompilerError String :=
  match psCompilerValidatePrepared prepared with
  | Except.error error =>
      Except.error error
  | Except.ok _ =>
      Except.ok (prepared.canonicalAdmissions ++ "\n")

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
            psBootstrapPreludeEnvironment
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
          psEraseCoreModule
            environment
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
