import Ps.Environment.SelfHostProd
import Ps.Host.KernelCoreProvider.Convert

namespace PsKernelCoreProvider

def kernelErrorMessage : PsKernelError -> String
  | .rejectedInvalid message => message
  | .declinedUnsupported message => message
  | .resourceExhausted _ message => message
  | .internalError message => message

def preludeMismatch (message : String) : PsKernelCoreProviderError :=
  { kind := .preludeMismatch, message := message }

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
    Except PsKernelCoreProviderError PsKernelSimpleConstructorDecl := do
  let some info := findConstructorInfo allDeclarations constructorName
    | throw (preludeMismatch "missing constructor metadata")
  if !psNameEq info.inductiveName inductiveName then
    throw (preludeMismatch "constructor belongs to a different inductive")
  let type ← toCoreExpr info.type
  pure { name := toCoreName info.name, type := type }

def convertConstructors
    (allDeclarations : List PsDeclaration)
    (inductiveName : PsName) :
    List PsName -> Except PsKernelCoreProviderError (List PsKernelSimpleConstructorDecl)
  | [] => .ok []
  | constructorName :: rest => do
      let converted ← convertConstructor allDeclarations inductiveName constructorName
      let convertedRest ← convertConstructors allDeclarations inductiveName rest
      pure (converted :: convertedRest)

def toCorePreludeDeclaration
    (allDeclarations : List PsDeclaration) :
    PsDeclaration -> Except PsKernelCoreProviderError (Option PsKernelDeclarationRequest)
  | .axiomDecl name levelParams type => do
      let convertedType ← toCoreExpr type
      pure <| some <| .axiomDecl {
        base := { name := toCoreName name, levelParams := toCoreNames levelParams, type := convertedType }
        isUnsafe := false
      }
  | .definitionDecl name levelParams type value => do
      let convertedType ← toCoreExpr type
      let convertedValue ← toCoreExpr value
      pure <| some <| .definitionDecl {
        base := { name := toCoreName name, levelParams := toCoreNames levelParams, type := convertedType }
        value := convertedValue
        hints := .regular 0
        safety := .safe
      }
  | .theoremDecl name levelParams type value => do
      let convertedType ← toCoreExpr type
      let convertedValue ← toCoreExpr value
      pure <| some <| .theoremDecl {
        base := { name := toCoreName name, levelParams := toCoreNames levelParams, type := convertedType }
        value := convertedValue
      }
  | .opaqueDecl name levelParams type value => do
      let convertedType ← toCoreExpr type
      let convertedValue ← toCoreExpr value
      pure <| some <| .opaqueDecl {
        base := { name := toCoreName name, levelParams := toCoreNames levelParams, type := convertedType }
        value := convertedValue
        isUnsafe := false
      }
  | .partialDecl _ _ _ _ =>
      .error (unsupportedCore "partial declaration in provider prelude")
  | .inductiveDecl info => do
      let convertedType ← toCoreExpr info.type
      let convertedConstructors ←
        convertConstructors allDeclarations info.name info.constructors
      pure <| some <| .ordinaryInductive {
        levelParams := toCoreNames info.levelParams
        numParams := info.numParams
        name := toCoreName info.name
        type := convertedType
        ctors := convertedConstructors
        isUnsafe := false
      }
  | .constructorDecl _ => .ok none
  | .recursorDecl _ => .ok none

inductive PreludeAdmissionAttempt where
  | admitted (env : PsKernelKernelSession)
  | deferred

def tryPreludeDeclaration
    (allDeclarations : List PsDeclaration)
    (env : PsKernelKernelSession)
    (declaration : PsDeclaration) :
    Except PsKernelCoreProviderError PreludeAdmissionAttempt := do
  let converted? ← toCorePreludeDeclaration allDeclarations declaration
  match converted? with
  | none => pure (.admitted env)
  | some converted =>
      match psKernelV1AdmitDeclaration env converted with
      | .ok next => pure (.admitted next.session)
      | .error (.rejectedInvalid "unknown constant") => pure .deferred
      | .error error =>
          throw (preludeMismatch
            ("PSKernel Core rejected PSC2 provider prelude declaration " ++
              psNameToString (psDeclarationName declaration) ++
              " (" ++ kernelErrorMessage error ++ ")"))

def replayPreludePass
    (allDeclarations : List PsDeclaration) :
    List PsDeclaration -> PsKernelKernelSession ->
    Except PsKernelCoreProviderError (PsKernelKernelSession × List PsDeclaration)
  | [], env => .ok (env, [])
  | declaration :: rest, env => do
      let attempt ← tryPreludeDeclaration allDeclarations env declaration
      match attempt with
      | .admitted next =>
          replayPreludePass allDeclarations rest next
      | .deferred =>
          let (next, deferred) ← replayPreludePass allDeclarations rest env
          pure (next, declaration :: deferred)

def replayPreludeDeclarations
    (fuel : Nat)
    (allDeclarations pending : List PsDeclaration)
    (env : PsKernelKernelSession) :
    Except PsKernelCoreProviderError PsKernelKernelSession := do
  let fuel + 1 := fuel | throw (preludeMismatch "prelude dependency pass bound exceeded")
  let (next, deferred) ← replayPreludePass allDeclarations pending env
  match deferred with
  | [] => pure next
  | first :: _ =>
      if deferred.length == pending.length then
        throw (preludeMismatch
          ("unresolved PSC2 provider prelude dependencies; first pending declaration: " ++
            psNameToString (psDeclarationName first)))
      else
        replayPreludeDeclarations fuel allDeclarations deferred next

def buildCorePreludeSession : Except PsKernelCoreProviderError PsKernelKernelSession := do
  let env ← match psKernelKernelSessionEmpty psKernelResourcePolicyDefault psKernelProviderDefault with
    | .ok value => pure value
    | .error error => throw (preludeMismatch (kernelErrorMessage error))
  let declarations := psSelfHostProdPreludeEnvironment.declarations
  replayPreludeDeclarations (declarations.length + 1) declarations declarations.reverse env

end PsKernelCoreProvider
