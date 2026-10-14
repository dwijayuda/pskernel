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
    Nat -> List Lean.Declaration -> Lean.Kernel.Environment ->
    Except PsKernelLeanError Lean.Kernel.Environment
  | _, [], env => .ok env
  | declarationIndex, original :: rest, env =>
      -- The reusable provider owns the same checked definition-height policy.
      let declaration := psKernelWithDefinitionHeight env original
      match env.addDeclCore 2000000 20000 declaration none with
      | .ok next =>
          admitDeclarationList (declarationIndex + 1) rest next
      | .error error =>
          .error (kernelRejection declarationIndex error)

def admitDeclarations
    (env : Lean.Kernel.Environment)
    (declarations : Array Lean.Declaration) :
    Except PsKernelLeanError Lean.Kernel.Environment :=
  admitDeclarationList 0 declarations.toList env

def admitCanonicalAdmissions
    (source : String) : IO (Except PsKernelLeanError Lean.Kernel.Environment) := do
  match decodeCanonicalAdmissions source with
  | .error error => pure (.error error)
  | .ok declarations =>
      let preludeResult ← buildLeanPreludeEnvironment
      match preludeResult with
      | .error error => pure (.error error)
      | .ok env => pure (admitDeclarations env declarations)

end PsKernelLean
