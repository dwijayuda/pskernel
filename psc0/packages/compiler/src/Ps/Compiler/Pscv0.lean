import Ps.Compiler.Api
import Ps.Syntax.Pscv0.Module
import Ps.Elab.Command

-- Source-owned v7 entry point. No generated frontend or host elaborator fallback.
-- Project import/exposure semantics are a later language milestone; never silently
-- flatten or ignore imports in this bounded single-module development entry point.
def psCompilerParsePscv0 (source : String) : Except String PsSyntaxProgram := do
  let parsed ← psPscv0ParseProgram source
  if parsed.imports.isEmpty then
    pure parsed
  else
    throw "PSCV0-NATIVE-MODULE-IMPORTS-PENDING"

def psCompilerElaboratePscv0 (program : PsSyntaxProgram) :
    Except PsCompilerError PsElabModuleResult :=
  (psElabProgram psSelfHostProdPreludeEnvironment program).mapError PsCompilerError.elaboration

def psCompilerPscv0ElabError : PsElabError → String
  | .atDeclaration name error =>
      psCompilerPscv0ElabError error ++ " (in " ++ psNameToString name ++ ")"
  | .scope message => "PSCV0-SCOPE: " ++ message
  | .data message => "PSCV0-DATA: " ++ message
  | .invalidArgument message => "PSCV0-ARGUMENT: " ++ message
  | .emptyCallUnsupported => "PSCV0-APP-03"
  | .unresolvedMetavariable => "PSCV0-UNSOLVED-INFERENCE"
  | .typeMismatch => "PSCV0-TYPE-MISMATCH"
  | .unknownName name => "PSCV0-UNKNOWN-NAME: " ++ psNameToString name
  | _ => "PSCV0-ELABORATION-FAILED"

def psCompilerPscv0Error : PsCompilerError → String
  | .translation _ => "PSCV0-TRANSLATION-FAILED"
  | .leanFrontend _ => "PSCV0-LEAN-FRONTEND-FAILED"
  | .proofScriptFrontend _ => "PSCV0-FRONTEND-FAILED"
  | .elaboration error => psCompilerPscv0ElabError error
  | .admission _ => "PSCV0-ADMISSION-CODEC-FAILED"
  | .erasure _ => "PSCV0-ERASURE-FAILED"
