import Lean
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

-- Keep structured kernel failure context for authoring imported Core assets.
-- This changes diagnostics only; admission still checks every declaration.
def kernelExceptionContext : Lean.Kernel.Exception → String
  | .appTypeMismatch _ _ app functionType argumentType =>
    "\napplication: " ++ app.dbgToString ++ "\nfunction type: " ++
      functionType.dbgToString ++ "\nargument type: " ++ argumentType.dbgToString
  | .declTypeMismatch _ _ type => "\ngiven type: " ++ type.dbgToString
  | _ => ""

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
  | .quotientDecl name _ _ kind =>
      if psNameEq name (psQuotientKindName kind) then pure (some .quotDecl)
      else throw (preludeMismatch "invalid kernel quotient identity")
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
  | admitted (env : Lean.Kernel.Environment)
  | deferred

-- Checking owns a Kernel.Environment, not the elaborator's AsyncConsts index.
-- Full imported private names remain distinct. Every declaration is checked by
-- the official C++ kernel at trust zero; no unchecked insertion API is used.
-- Quotient descriptors validate members of one atomically generated group.
def quotientGroupPresent (env : Lean.Kernel.Environment) : Except PsKernelLeanError Bool := do
  let members : List (Lean.Name × Lean.QuotKind) :=
    [(`Quot, .type), (`Quot.mk, .ctor), (`Quot.lift, .lift), (`Quot.ind, .ind)]
  let mut present := 0
  for (name, kind) in members do
    match env.find? name with
    | none => pure ()
    | some (.quotInfo info) =>
        unless info.name == name && info.kind == kind do
          throw (preludeMismatch "kernel quotient group has inconsistent identities")
        present := present + 1
    | some _ => throw (preludeMismatch "kernel quotient name is already occupied")
  unless present == 0 || present == members.length do
    throw (preludeMismatch "kernel quotient group is incomplete")
  unless env.quotInit == (present != 0) do
    throw (preludeMismatch "kernel quotient initialization flag differs from its group")
  return present != 0

def validateQuotientDescriptor (env : Lean.Kernel.Environment) (declaration : PsDeclaration) :
    Except PsKernelLeanError Unit := do
  if let .quotientDecl name levels type kind := declaration then
    let some (.quotInfo generated) := env.find? (toLeanName name)
      | throw (preludeMismatch "missing regenerated quotient metadata")
    let generatedKind := match generated.kind with
      | .type => PsQuotientKind.type | .ctor => .ctor
      | .lift => .lift | .ind => .ind
    let convertedType ← toLeanExpr type
    unless generated.levelParams == toLeanNames levels &&
        generated.type == convertedType &&
        psQuotientKindTag generatedKind == psQuotientKindTag kind do
      throw (preludeMismatch "regenerated quotient signature or kind differs")

def tryPreludeDeclaration
    (allDeclarations : List PsDeclaration)
    (env : Lean.Kernel.Environment)
    (declaration : PsDeclaration)
    (maxHeartbeats : USize := 2000000)
    (maxRecDepth : USize := 20000) :
    Except PsKernelLeanError PreludeAdmissionAttempt := do
  let converted? ← toLeanPreludeDeclaration allDeclarations declaration
  match converted? with
  | none => pure (.admitted env)
  | some converted =>
      if let .quotientDecl .. := declaration then
        if ← quotientGroupPresent env then
          validateQuotientDescriptor env declaration
          return .admitted env
      match env.addDeclCore maxHeartbeats maxRecDepth converted none with
      | .ok next =>
          validateQuotientDescriptor next declaration
          pure (.admitted next)
      | .error (.unknownConstant _ _) => pure .deferred
      | .error error =>
          throw (preludeMismatch
            ("official Lean kernel rejected portable Standard declaration " ++
              psNameToString (psDeclarationName declaration) ++
              " (" ++ kernelExceptionSummary error ++ ")" ++ kernelExceptionContext error))

-- The frozen, reviewed Standard can use Lean's import-time kernel budget
-- (0/0). Standalone authoring and untrusted submissions keep finite budgets.
-- Every declaration is still checked at trust zero, regardless of budget.
def replayPreludePass
    (allDeclarations : List PsDeclaration)
    (maxHeartbeats : USize := 2000000)
    (maxRecDepth : USize := 20000) :
    List PsDeclaration -> Lean.Kernel.Environment ->
    Except PsKernelLeanError (Lean.Kernel.Environment × List PsDeclaration)
  | [], env => .ok (env, [])
  | declaration :: rest, env => do
      let attempt ← tryPreludeDeclaration allDeclarations env declaration maxHeartbeats maxRecDepth
      match attempt with
      | .admitted next =>
          replayPreludePass allDeclarations maxHeartbeats maxRecDepth rest next
      | .deferred =>
          let (next, deferred) ← replayPreludePass allDeclarations maxHeartbeats maxRecDepth rest env
          pure (next, declaration :: deferred)

partial def replayPreludeDeclarations
    (allDeclarations pending : List PsDeclaration)
    (env : Lean.Kernel.Environment)
    (maxHeartbeats : USize := 2000000)
    (maxRecDepth : USize := 20000) :
    Except PsKernelLeanError Lean.Kernel.Environment := do
  let (next, deferred) ← replayPreludePass allDeclarations maxHeartbeats maxRecDepth pending env
  match deferred with
  | [] => pure next
  | first :: _ =>
      if deferred.length == pending.length then
        throw (preludeMismatch
          ("unresolved portable Standard dependencies; first pending declaration: " ++
            psNameToString (psDeclarationName first)))
      else
        replayPreludeDeclarations allDeclarations deferred next maxHeartbeats maxRecDepth

def buildLeanPreludeEnvironment : IO (Except PsKernelLeanError Lean.Kernel.Environment) := do
  let env := (← Lean.mkEmptyEnvironment 0).toKernelEnv
  let declarations := psSelfHostProdPreludeEnvironment.declarations
  -- Lean 4.35.0 Environment.lean import path checks immutable declarations
  -- with kenv.addDeclCore 0 0. This provider entry is only for the selected,
  -- separately SHA/FNV-guarded Standard. Ordinary source admission retains
  -- 2,000,000 heartbeats and depth 20,000 in NativeV7.check/Admission.
  -- 0 is Lean's import-time resource policy, NOT unchecked insertion.
  pure <| replayPreludeDeclarations declarations declarations.reverse env 0 0

end PsKernelLean
