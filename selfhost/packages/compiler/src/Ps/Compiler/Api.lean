import Ps.Syntax.Translate
import Ps.Bridge.CheckedAdmissions
import Ps.Environment.Prelude
import Ps.Elab.Declaration
import Ps.Erasure.Definition
import Ps.BackendTs.Module

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
  | typeScript (error : PsTsEmitError)

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
            psCanonicalizeProofScriptSource source
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
      | Except.ok module =>
          Except.ok module
  | PsCompilerSourceKind.proofScript =>
      match psParseProofScriptSource source with
      | Except.error error =>
          Except.error (PsCompilerError.proofScriptFrontend error)
      | Except.ok module =>
          Except.ok module

def psCompilerElaborateModule
    (module : PsSyntaxModule) :
    Except PsCompilerError PsElabModuleResult :=
  match psElabModule psBootstrapPreludeEnvironment module with
  | Except.error error =>
      Except.error (PsCompilerError.elaboration error)
  | Except.ok elaborated =>
      Except.ok elaborated

def psCompilerCheckElaborated
    (elaborated : PsElabModuleResult) :
    Except PsCompilerError Unit :=
  match
      psEncodeCheckedAdmissionsCanonical
        elaborated.declarations with
  | Except.error error =>
      Except.error (PsCompilerError.admission error)
  | Except.ok _ =>
      Except.ok ()

def psCompilerAdmissionsFromElaborated
    (elaborated : PsElabModuleResult) :
    Except PsCompilerError String :=
  match
      psEncodeCheckedAdmissionsText
        elaborated.declarations with
  | Except.error error =>
      Except.error (PsCompilerError.admission error)
  | Except.ok output =>
      Except.ok output

def psCompilerTypeScriptFromElaborated
    (elaborated : PsElabModuleResult) :
    Except PsCompilerError String :=
  match
      psEraseCoreModule
        elaborated.environment
        elaborated.declarations with
  | Except.error error =>
      Except.error (PsCompilerError.erasure error)
  | Except.ok ir =>
      match psTsEmitModule ir with
      | Except.error error =>
          Except.error (PsCompilerError.typeScript error)
      | Except.ok output =>
          Except.ok output

def psCompilerElaborateSource
    (sourceKind : PsCompilerSourceKind)
    (source : String) :
    Except PsCompilerError PsElabModuleResult :=
  match psCompilerParseSource sourceKind source with
  | Except.error error =>
      Except.error error
  | Except.ok module =>
      psCompilerElaborateModule module

def psCompilerCheckSource
    (sourceKind : PsCompilerSourceKind)
    (source : String) :
    Except PsCompilerError PsElabModuleResult :=
  match psCompilerElaborateSource sourceKind source with
  | Except.error error =>
      Except.error error
  | Except.ok elaborated =>
      match psCompilerCheckElaborated elaborated with
      | Except.error error =>
          Except.error error
      | Except.ok _ =>
          Except.ok elaborated

def psCompilerAdmissionsSource
    (sourceKind : PsCompilerSourceKind)
    (source : String) :
    Except PsCompilerError String :=
  match psCompilerCheckSource sourceKind source with
  | Except.error error =>
      Except.error error
  | Except.ok elaborated =>
      psCompilerAdmissionsFromElaborated elaborated

def psCompilerTypeScriptSource
    (sourceKind : PsCompilerSourceKind)
    (source : String) :
    Except PsCompilerError String :=
  match psCompilerElaborateSource sourceKind source with
  | Except.error error =>
      Except.error error
  | Except.ok elaborated =>
      psCompilerTypeScriptFromElaborated elaborated
