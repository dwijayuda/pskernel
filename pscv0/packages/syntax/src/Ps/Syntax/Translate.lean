import Ps.Syntax.ParseLean
import Ps.Syntax.ParseProofScript
import Ps.Syntax.PrintLean
import Ps.Syntax.PrintProofScript

inductive PsTranslationError where
  | leanFrontend (error : PsLeanFrontendError)
  | proofScriptFrontend (error : PsProofScriptFrontendError)
  | print (error : PsSourcePrintError)

def psTranslateLeanToProofScript
    (source : String) :
    Except PsTranslationError String :=
  match psParseLeanSource source with
  | Except.error error =>
      Except.error (PsTranslationError.leanFrontend error)
  | Except.ok module =>
      match psPrintProofScriptModule module with
      | Except.error error =>
          Except.error (PsTranslationError.print error)
      | Except.ok output =>
          Except.ok output

def psTranslateProofScriptToLean
    (source : String) :
    Except PsTranslationError String :=
  match psParseProofScriptSource source with
  | Except.error error =>
      Except.error
        (PsTranslationError.proofScriptFrontend error)
  | Except.ok module =>
      match psPrintLeanModule module with
      | Except.error error =>
          Except.error (PsTranslationError.print error)
      | Except.ok output =>
          Except.ok output

def psCanonicalizeLeanSource
    (source : String) :
    Except PsTranslationError String :=
  match psParseLeanSource source with
  | Except.error error =>
      Except.error (PsTranslationError.leanFrontend error)
  | Except.ok module =>
      match psPrintLeanModule module with
      | Except.error error =>
          Except.error (PsTranslationError.print error)
      | Except.ok output =>
          Except.ok output

def psCanonicalizeProofScriptSource
    (source : String) :
    Except PsTranslationError String :=
  match psParseProofScriptSource source with
  | Except.error error =>
      Except.error
        (PsTranslationError.proofScriptFrontend error)
  | Except.ok module =>
      match psPrintProofScriptModule module with
      | Except.error error =>
          Except.error (PsTranslationError.print error)
      | Except.ok output =>
          Except.ok output
