import PsKernelLean.Protocol
import PsKernelLean.Prelude

namespace PsKernelLean

def kernelRejection
    (declarationIndex : Nat)
    (error : Lean.Kernel.Exception) : PsKernelLeanError :=
  {
    kind := .kernelRejection
    message :=
      "Lean 4.34 kernel rejected declaration " ++
      toString declarationIndex ++
      " (" ++ kernelExceptionSummary error ++ ")"
    declarationIndex := some declarationIndex
  }

def admitDeclarationList :
    Nat -> List Lean.Declaration -> Lean.Environment ->
    Except PsKernelLeanError Lean.Environment
  | _, [], env => .ok env
  | declarationIndex, declaration :: rest, env =>
      match env.addDeclCore 2000000 20000 declaration none true with
      | .ok next =>
          admitDeclarationList (declarationIndex + 1) rest next
      | .error error =>
          .error (kernelRejection declarationIndex error)

def admitDeclarations
    (env : Lean.Environment)
    (declarations : Array Lean.Declaration) :
    Except PsKernelLeanError Lean.Environment :=
  admitDeclarationList 0 declarations.toList env

def admitCanonicalAdmissions
    (source : String) : IO (Except PsKernelLeanError Lean.Environment) := do
  match decodeCanonicalAdmissions source with
  | .error error => pure (.error error)
  | .ok declarations =>
      let preludeResult ← buildLeanPreludeEnvironment
      match preludeResult with
      | .error error => pure (.error error)
      | .ok env => pure (admitDeclarations env declarations)

end PsKernelLean
