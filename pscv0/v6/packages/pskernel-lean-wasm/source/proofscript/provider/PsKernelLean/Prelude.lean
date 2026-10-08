import Lean.Environment
import Ps.Environment.SelfHostProd
import PsKernelLean.Convert

namespace PsKernelLean

def preludeMismatch (message : String) : PsKernelLeanError :=
  { kind := .preludeMismatch, message := message }

def kernelExceptionSummary : Lean.Kernel.Exception -> String
  | .unknownConstant _ name => "unknown-constant:" ++ toString name
  | .alreadyDeclared _ name => "already-declared:" ++ toString name
  | .declTypeMismatch _ _ _ => "declaration-type-mismatch"
  | .declHasMVars _ name _ => "declaration-metavariables:" ++ toString name
  | .declHasFVars _ name _ => "declaration-free-variables:" ++ toString name
  | .funExpected _ _ _ => "function-expected"
  | .typeExpected _ _ _ => "type-expected"
  | .letTypeMismatch _ _ name _ _ => "let-type-mismatch:" ++ toString name
  | .exprTypeMismatch _ _ _ _ => "expression-type-mismatch"
  | .appTypeMismatch _ _ _ _ _ => "application-type-mismatch"
  | .invalidProj _ _ _ => "invalid-projection"
  | .thmTypeIsNotProp _ name _ => "theorem-type-not-prop:" ++ toString name
  | .other message => "other:" ++ message
  | .deterministicTimeout => "deterministic-timeout"
  | .excessiveMemory => "excessive-memory"
  | .deepRecursion => "deep-recursion"
  | .interrupted => "interrupted"

def findConstructorInfo : List PsDeclaration -> PsName -> Option PsConstructorInfo
  | [], _ => none
  | declaration :: rest, name =>
      match declaration with
      | .constructorDecl info =>
          if psNameEq info.name name then some info
          else findConstructorInfo rest name
      | _ => findConstructorInfo rest name

def convertConstructor
    (allDeclarations : List PsDeclaration)
    (inductiveName constructorName : PsName) :
    Except PsKernelLeanError Lean.Constructor := do
  let some info := findConstructorInfo allDeclarations constructorName
    | throw (preludeMismatch "missing constructor metadata")
  if !psNameEq info.inductiveName inductiveName then
    throw (preludeMismatch "constructor belongs to a different inductive")
  let type ← toLeanExpr info.type
  pure { name := toLeanName info.name, type := type }

def convertConstructors
    (allDeclarations : List PsDeclaration)
    (inductiveName : PsName) :
    List PsName -> Except PsKernelLeanError (List Lean.Constructor)
  | [] => .ok []
  | constructorName :: rest => do
      let converted ← convertConstructor allDeclarations inductiveName constructorName
      let convertedRest ← convertConstructors allDeclarations inductiveName rest
      pure (converted :: convertedRest)

def toLeanPreludeDeclaration
    (allDeclarations : List PsDeclaration) :
    PsDeclaration -> Except PsKernelLeanError (Option Lean.Declaration)
  | .axiomDecl name levelParams type => do
      let convertedType ← toLeanExpr type
      pure <| some <| .axiomDecl {
        name := toLeanName name
        levelParams := toLeanNames levelParams
        type := convertedType
        isUnsafe := false
      }
  | .definitionDecl name levelParams type value => do
      let convertedType ← toLeanExpr type
      let convertedValue ← toLeanExpr value
      pure <| some <| .defnDecl {
        name := toLeanName name
        levelParams := toLeanNames levelParams
        type := convertedType
        value := convertedValue
        hints := .regular 0
        safety := .safe
      }
  | .theoremDecl name levelParams type value => do
      let convertedType ← toLeanExpr type
      let convertedValue ← toLeanExpr value
      pure <| some <| .thmDecl {
        name := toLeanName name
        levelParams := toLeanNames levelParams
        type := convertedType
        value := convertedValue
      }
  | .opaqueDecl name levelParams type value => do
      let convertedType ← toLeanExpr type
      let convertedValue ← toLeanExpr value
      pure <| some <| .opaqueDecl {
        name := toLeanName name
        levelParams := toLeanNames levelParams
        type := convertedType
        value := convertedValue
        isUnsafe := false
      }
  | .partialDecl _ _ _ _ =>
      .error (unsupportedCore "partial declaration in provider prelude")
  | .inductiveDecl info => do
      let convertedType ← toLeanExpr info.type
      let convertedConstructors ←
        convertConstructors allDeclarations info.name info.constructors
      pure <| some <| .inductDecl
        (toLeanNames info.levelParams)
        info.numParams
        [{
          name := toLeanName info.name
          type := convertedType
          ctors := convertedConstructors
        }]
        false
  | .constructorDecl _ => .ok none
  | .recursorDecl _ => .ok none

inductive PreludeAdmissionAttempt where
  | admitted (env : Lean.Environment)
  | deferred

def tryPreludeDeclaration
    (allDeclarations : List PsDeclaration)
    (env : Lean.Environment)
    (declaration : PsDeclaration) :
    Except PsKernelLeanError PreludeAdmissionAttempt := do
  let converted? ← toLeanPreludeDeclaration allDeclarations declaration
  match converted? with
  | none => pure (.admitted env)
  | some converted =>
      match env.addDeclCore 2000000 20000 converted none true with
      | .ok next => pure (.admitted next)
      | .error (.unknownConstant _ _) => pure .deferred
      | .error error =>
          throw (preludeMismatch
            ("Lean 4.34 kernel rejected PSC2 provider prelude declaration " ++
              psNameToString (psDeclarationName declaration) ++
              " (" ++ kernelExceptionSummary error ++ ")"))

def replayPreludePass
    (allDeclarations : List PsDeclaration) :
    List PsDeclaration -> Lean.Environment ->
    Except PsKernelLeanError (Lean.Environment × List PsDeclaration)
  | [], env => .ok (env, [])
  | declaration :: rest, env => do
      let attempt ← tryPreludeDeclaration allDeclarations env declaration
      match attempt with
      | .admitted next =>
          replayPreludePass allDeclarations rest next
      | .deferred =>
          let (next, deferred) ← replayPreludePass allDeclarations rest env
          pure (next, declaration :: deferred)

partial def replayPreludeDeclarations
    (allDeclarations pending : List PsDeclaration)
    (env : Lean.Environment) :
    Except PsKernelLeanError Lean.Environment := do
  let (next, deferred) ← replayPreludePass allDeclarations pending env
  match deferred with
  | [] => pure next
  | first :: _ =>
      if deferred.length == pending.length then
        throw (preludeMismatch
          ("unresolved PSC2 provider prelude dependencies; first pending declaration: " ++
            psNameToString (psDeclarationName first)))
      else
        replayPreludeDeclarations allDeclarations deferred next

def buildLeanPreludeEnvironment : IO (Except PsKernelLeanError Lean.Environment) := do
  let env ← Lean.mkEmptyEnvironment 0
  let declarations := psSelfHostProdPreludeEnvironment.declarations
  pure <| replayPreludeDeclarations declarations declarations.reverse env

end PsKernelLean
