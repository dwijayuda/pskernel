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

def psCompilerPscv0InferError : PsInferError → String
  | .fuelExhausted => "inference budget"
  | .looseBoundVariable index => "loose bound variable " ++ psNatToString index
  | .unknownFreeVariable id => "unknown local " ++ psNatToString id
  | .unknownMetavariable id => "unknown inference variable " ++ psNatToString id
  | .unknownConstant name => "unknown constant " ++ psNameToString name
  | .incorrectUniverseArity name => "universe arity of " ++ psNameToString name
  | .expectedSort => "expected a type"
  | .expectedFunction => "expected a function"
  | .applicationTypeMismatch => "application argument type mismatch"
  | .letTypeMismatch => "let binding type mismatch"
  | .projectionUnsupported => "unsupported projection"

def psCompilerPscv0ElabError : PsElabError → String
  | .atDeclaration name error =>
      psCompilerPscv0ElabError error ++ " (in " ++ psNameToString name ++ ")"
  | .infer error => "PSCV0-ELABORATION: " ++ psCompilerPscv0InferError error
  | .scope message => "PSCV0-SCOPE: " ++ message
  | .data message => "PSCV0-DATA: " ++ message
  | .refinement message => "PSCV0-MATCH: " ++ message
  | .matchNonExhaustive => "PSCV0-MATCH: missing feasible constructor branch"
  | .invalidArgument message => "PSCV0-ARGUMENT: " ++ message
  | .emptyCallUnsupported => "PSCV0-APP-03"
  | .unresolvedMetavariable => "PSCV0-UNSOLVED-INFERENCE"
  | .typeMismatch => "PSCV0-TYPE-MISMATCH"
  | .structuralRecursionInvariantArgument =>
      "PSCV0-RECURSION: argument must equal its child index or invariant value"
  | .structuralRecursionDependentParameter =>
      "PSCV0-RECURSION: invariant parameter depends on a varying index or major"
  | .structuralRecursionNotDecreasing =>
      "PSCV0-RECURSION: recursive major must be a direct recursive field"
  | .unknownName name => "PSCV0-UNKNOWN-NAME: " ++ psNameToString name
  | _ => "PSCV0-ELABORATION-FAILED"

def psCompilerPscv0ErasureError : PsErasureError → String
  | .fuelExhausted => "budget"
  | .binderMismatch => "binder mismatch"
  | .looseBoundVariable => "loose bound variable"
  | .unresolvedMetavariable => "unsolved inference"
  | .unknownLocal id => "unknown local " ++ psNatToString id
  | .erasedLocalUsed id => "runtime use of erased local " ++ psNatToString id
  | .unsupportedRuntimeTerm => "unsupported runtime term"
  | .inDeclaration name cause => psCompilerPscv0ErasureError cause ++ " (in " ++ psNameToString name ++ ")"
  | .unsupportedApplication => "unsupported application"
  | .unknownConstant name => "unknown constant " ++ psNameToString name

def psCompilerPscv0Error : PsCompilerError → String
  | .normalization message => "PSCV0-PREPARATION: " ++ message
  | .translation _ => "PSCV0-TRANSLATION-FAILED"
  | .leanFrontend _ => "PSCV0-LEAN-FRONTEND-FAILED"
  | .proofScriptFrontend _ => "PSCV0-FRONTEND-FAILED"
  | .elaboration error => psCompilerPscv0ElabError error
  | .admission _ => "PSCV0-ADMISSION-CODEC-FAILED"
  | .erasure error => "PSCV0-ERASURE: " ++ psCompilerPscv0ErasureError error
