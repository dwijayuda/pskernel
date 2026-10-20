import Ps.CompilerIr.Validate
import Ps.Bridge.Json

/-! A small administrative-normal-form plan for statement-oriented direct backends.
    This is not a new source language or a VM. Every operand is evaluated once,
    left to right; every lexical binder receives a fresh target identity. Logical
    admission stays in the host. The input and specialization output are rechecked.
    This transformation is tested, not claimed to be formally proved. -/

structure PsScriptBinding where
  source : String
  emitted : String
  global : Bool := false

inductive PsScriptStatement where
  | literal (destination : String) (value : PsVerifiedIrLiteral)
  | copy (destination source : String)
  | intrinsic (destination : String) (operation : PsVerifiedIrIntrinsic) (arguments : List String)
  | call (destination functionName : String) (arguments : List String)
  | record (destination owner : String) (fields : List (String × String))
  | projection (destination target field : String)
  | constructor (destination owner constructorName : String) (fields : List (String × String))
  | branch (destination condition : String)
      (thenBody : List PsScriptStatement) (thenValue : String)
      (elseBody : List PsScriptStatement) (elseValue : String)
  | matchE (destination scrutinee : String)
      (alternatives : List (String × List (String × String) × List PsScriptStatement × String))
  | function (destination : String) (parameters : List String)
      (captures : List PsScriptBinding) (body : List PsScriptStatement) (result : String)

structure PsScriptDeclaration where
  original : PsVerifiedIrDeclaration
  name : String
  parameters : List String
  captures : List PsScriptBinding
  body : List PsScriptStatement
  result : String

structure PsScriptLowerState where
  nextName : Nat := 0
  remainingNodes : Nat := 1000000

abbrev PsScriptLowerM := StateT PsScriptLowerState (Except String)

def psScriptStem (name : String) : String :=
  String.ofList (name.toList.map fun c =>
    if c.isAlphanum && c.toNat < 128 || c == '_' then c else '_')

def psScriptFresh (hint : String) : PsScriptLowerM String := do
  let state ← get
  set { state with nextName := state.nextName + 1 }
  return "_psc1_" ++ psScriptStem hint ++ "_" ++ toString state.nextName

def psScriptLookup (scope : List PsScriptBinding) (name : String) : Except String PsScriptBinding :=
  match scope.find? (fun binding => binding.source == name) with
  | some binding => .ok binding
  | none => .error ("PSC1_SCRIPT_UNBOUND_VALUE: " ++ name)

partial def psScriptFreeNames (expression : PsVerifiedIrExpr) (bound : List String := []) : List String :=
  let visit := fun e => psScriptFreeNames e bound
  match expression with
  | .literal _ => []
  | .var name => if bound.contains name then [] else [name]
  | .intrinsic _ _ arguments => arguments.flatMap visit
  | .call function _ arguments => visit function ++ arguments.flatMap visit
  | .lambda parameters _ body => psScriptFreeNames body (parameters.map (·.name) ++ bound)
  | .letE name _ value body => visit value ++ psScriptFreeNames body (name :: bound)
  | .ifE condition yes no => visit condition ++ visit yes ++ visit no
  | .record _ _ fields | .constructor _ _ _ fields => fields.flatMap (fun field => visit field.2)
  | .projection _ _ target _ => visit target
  | .matchE _ _ scrutinee alternatives => visit scrutinee ++ alternatives.flatMap (fun (_, bindings, body) =>
      psScriptFreeNames body (bindings.map (·.name) ++ bound))

def psScriptCaptures (scope : List PsScriptBinding) (body : PsVerifiedIrExpr)
    (parameters : List String) : Except String (List PsScriptBinding) := do
  (psScriptFreeNames body parameters).eraseDups.mapM (psScriptLookup scope)

def psScriptParameters (parameters : List PsVerifiedIrParameter) : PsScriptLowerM (List PsScriptBinding) :=
  parameters.mapM fun parameter => do
    let emitted ← psScriptFresh parameter.name
    return { source := parameter.name, emitted := emitted }

partial def psScriptLower (scope : List PsScriptBinding) (expression : PsVerifiedIrExpr) :
    PsScriptLowerM (List PsScriptStatement × String) := do
  let state ← get
  if state.remainingNodes == 0 then throw "PSC1_SCRIPT_LOWERING_BUDGET_EXHAUSTED"
  set { state with remainingNodes := state.remainingNodes - 1 }
  match expression with
  | .var name => return ([], (← psScriptLookup scope name).emitted)
  | .literal value =>
    let destination ← psScriptFresh "literal"
    return ([.literal destination value], destination)
  | .intrinsic operation _ arguments =>
    let lowered ← arguments.mapM (psScriptLower scope)
    let destination ← psScriptFresh "value"
    return (lowered.flatMap (·.1) ++ [.intrinsic destination operation (lowered.map (·.2))], destination)
  | .call function _ arguments =>
    let (functionBody, functionName) ← psScriptLower scope function
    let lowered ← arguments.mapM (psScriptLower scope)
    let destination ← psScriptFresh "call"
    return (functionBody ++ lowered.flatMap (·.1) ++ [.call destination functionName (lowered.map (·.2))], destination)
  | .letE name _ value body =>
    let (valueBody, valueName) ← psScriptLower scope value
    let emitted ← psScriptFresh name
    let (bodyStatements, result) ← psScriptLower ({ source := name, emitted := emitted } :: scope) body
    return (valueBody ++ [.copy emitted valueName] ++ bodyStatements, result)
  | .ifE condition yes no =>
    let (conditionBody, conditionName) ← psScriptLower scope condition
    let (thenBody, thenValue) ← psScriptLower scope yes
    let (elseBody, elseValue) ← psScriptLower scope no
    let destination ← psScriptFresh "branch"
    return (conditionBody ++ [.branch destination conditionName thenBody thenValue elseBody elseValue], destination)
  | .lambda parameters _ body =>
    let captures ← psScriptCaptures scope body (parameters.map (·.name))
    let renamed ← psScriptParameters parameters
    let (statements, result) ← psScriptLower (renamed ++ scope) body
    let destination ← psScriptFresh "closure"
    return ([.function destination (renamed.map (·.emitted)) captures statements result], destination)
  | .record owner _ fields =>
    let lowered ← fields.mapM fun (field, value) => do
      let (statements, result) ← psScriptLower scope value
      return (field, statements, result)
    let destination ← psScriptFresh "record"
    return (lowered.flatMap (fun (_, statements, _) => statements) ++
      [.record destination owner (lowered.map (fun (field, _, value) => (field, value)))], destination)
  | .projection _ _ target field =>
    let (statements, result) ← psScriptLower scope target
    let destination ← psScriptFresh "field"
    return (statements ++ [.projection destination result field], destination)
  | .constructor owner constructorName _ fields =>
    let lowered ← fields.mapM fun (field, value) => do
      let (statements, result) ← psScriptLower scope value
      return (field, statements, result)
    let destination ← psScriptFresh "constructor"
    return (lowered.flatMap (fun (_, statements, _) => statements) ++
      [.constructor destination owner constructorName (lowered.map (fun (field, _, value) => (field, value)))], destination)
  | .matchE _ _ scrutinee alternatives =>
    let (scrutineeBody, scrutineeName) ← psScriptLower scope scrutinee
    let lowered ← alternatives.mapM fun (constructorName, bindings, body) => do
      let renamed ← bindings.mapM fun binding => do
        let emitted ← psScriptFresh binding.name
        return (binding.field, { source := binding.name, emitted := emitted : PsScriptBinding })
      let (statements, result) ← psScriptLower (renamed.map (·.2) ++ scope) body
      return (constructorName, renamed.map (fun (field, binding) => (field, binding.emitted)), statements, result)
    let destination ← psScriptFresh "match"
    return (scrutineeBody ++ [.matchE destination scrutineeName lowered], destination)

/-- Public ABI v1 is deliberately primitive-only, independently of internal ADTs. -/
def psScriptPublicType : PsVerifiedIrType → Except String Unit
  | .primitive type => match psIrCheckPrimitive type with
    | .ok _ => .ok ()
    | .error _ => .error "PSC1_SCRIPT_PUBLIC_SCALAR_UNQUALIFIED"
  | _ => .error "PSC1_SCRIPT_PUBLIC_NONSCALAR_UNQUALIFIED"

structure PsScriptPlan where
  private mk ::
  source : PsValidatedIrModule
  globals : List PsScriptBinding
  declarations : List PsScriptDeclaration
  publicNames : List String

/-- An emitter plan is not a kernel-admission token. Only the host-owned admitted
    session may authorize artifact publication. Reject forged raw wrappers here. -/
def psBuildScriptPlan (input : PsValidatedIrModule) (publicNames : List String) : Except String PsScriptPlan := do
  let checked ← (psStrictValidateModule input.raw).mapError (fun _ => "PSC1_SCRIPT_INPUT_INVALID")
  if !checked.raw.imports.isEmpty then throw "PSC1_SCRIPT_FOREIGN_IMPORT_UNQUALIFIED"
  if publicNames.eraseDups.length != publicNames.length then throw "PSC1_SCRIPT_DUPLICATE_EXPORT"
  for name in publicNames do
    let some declaration := checked.raw.declarations.find? (fun declaration => declaration.name == name)
      | throw ("PSC1_SCRIPT_EXPORT_UNKNOWN: " ++ name)
    if !declaration.typeParameters.isEmpty then throw "PSC1_SCRIPT_PUBLIC_GENERIC_UNQUALIFIED"
    psScriptPublicType declaration.resultType
    for parameter in declaration.parameters do psScriptPublicType parameter.type
  let specialized ← (psIrSpecializeValidatedModule checked).mapError (fun _ => "PSC1_SCRIPT_SPECIALIZATION_FAILED")
  let validated ← (psStrictValidateModule specialized.raw).mapError (fun _ => "PSC1_SCRIPT_SPECIALIZATION_INVALID")
  let globals := validated.raw.declarations.zipIdx.map fun (declaration, index) =>
    { source := declaration.name, emitted := "_psc1_global_" ++ psScriptStem declaration.name ++ "_" ++ toString index,
      global := true : PsScriptBinding }
  let action : PsScriptLowerM (List PsScriptDeclaration) := validated.raw.declarations.mapM fun declaration => do
    let parameters ← psScriptParameters declaration.parameters
    let captures ← psScriptCaptures globals declaration.body (declaration.parameters.map (·.name))
    let (body, result) ← psScriptLower (parameters ++ globals) declaration.body
    return { original := declaration, name := (← psScriptLookup globals declaration.name).emitted,
      parameters := parameters.map (·.emitted), captures := captures, body := body, result := result }
  let (declarations, _) ← action.run {}
  for name in publicNames do
    if !declarations.any (fun declaration => declaration.original.name == name) then
      throw ("PSC1_SCRIPT_EXPORT_LOST: " ++ name)
  return { source := validated, globals := globals, declarations := declarations, publicNames := publicNames }

structure PsScriptOutput where
  source : String
  declarations : String := ""
  runtimeHelpers : List String := []
  extensions : List String := []
  /-- Original runtime declaration name, first and last generated line (1-based). -/
  spans : List (String × Nat × Nat) := []

def psScriptIndent (level : Nat) : String := String.ofList (List.replicate (level * 4) ' ')
def psScriptLines (lines : List String) : String := String.intercalate "\n" lines ++ "\n"
