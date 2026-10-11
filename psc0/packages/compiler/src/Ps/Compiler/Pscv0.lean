import Ps.Compiler.Api
import Ps.Syntax.Pscv0.Module

-- Source-owned v7 entry point. No generated frontend or host elaborator fallback.
-- Project import/exposure semantics are a later language milestone; never silently
-- flatten or ignore imports in this bounded single-module development entry point.
def psCompilerParsePscv0 (source : String) : Except String PsSyntaxModule := do
  let surface ← psPscv0ParseSource true source
  let parsed ← psPscv0LowerModule surface
  if parsed.imports.isEmpty then
    pure parsed
  else
    throw "PSCV0-NATIVE-MODULE-IMPORTS-PENDING"

def psCompilerPscv0Error : PsCompilerError → String
  | .translation _ => "PSCV0-TRANSLATION-FAILED"
  | .leanFrontend _ => "PSCV0-LEAN-FRONTEND-FAILED"
  | .proofScriptFrontend _ => "PSCV0-FRONTEND-FAILED"
  | .elaboration (.invalidArgument message) => "PSCV0-ARGUMENT: " ++ message
  | .elaboration .emptyCallUnsupported => "PSCV0-APP-03"
  | .elaboration .unresolvedMetavariable => "PSCV0-UNSOLVED-INFERENCE"
  | .elaboration .typeMismatch => "PSCV0-TYPE-MISMATCH"
  | .elaboration _ => "PSCV0-ELABORATION-FAILED"
  | .admission _ => "PSCV0-ADMISSION-CODEC-FAILED"
  | .erasure _ => "PSCV0-ERASURE-FAILED"
