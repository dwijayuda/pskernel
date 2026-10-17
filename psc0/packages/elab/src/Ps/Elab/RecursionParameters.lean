import Ps.Elab.Binders
import Ps.Elab.Application
import Ps.Elab.FixedParameters

/-
Typed fixed/evolving parameter ownership, following Lean 4.35.0
eb6cafb7290e8bd5f2937522d8d804f58f02bafc:
Lean/Elab/PreDefinition/FixedParams.lean:107-120,180-237,250-268.
Call arguments are compared reducibly, without proof irrelevance, in their
real local contexts. The resulting plan is revalidated on the final body;
it does not supply an equation or permit an unchecked recursive call.
-/

structure PsElabRecursionParameterPlan where
  parameterIds : List Nat
  majorId : Nat
  packedIds : List Nat := []
  fixedIds : List Nat
  stateIds : List Nat

def psElabRecursionParameterArgument (ids : List Nat) (arguments : List PsExpr)
    (id : Nat) : Option PsExpr :=
  ((ids.zip arguments).find? (fun entry => entry.fst == id)).map Prod.snd

def psElabRecursionParameterIsFixed (context : PsElabContext)
    (ids : List Nat) (calls : List PsElabRecursionCall) (id : Nat) : Bool :=
  calls.all fun call =>
    match psElabRecursionParameterArgument ids call.arguments id with
    | none => false
    | some argument =>
      !psExprHasUnresolvedMeta (psMetaInstantiate context.metaContext argument) &&
        psDefEqReadOnlyWithTransparency .reducible context.environment context.metaContext
          call.localContext (.fvar id) argument

-- Local declarations are dependency ordered. A single oldest-first pass
-- closes the transitive dependencies of both binder types and let values.
def psElabRecursionParameterDependencies (context : PsElabContext)
    (roots : List Nat) : List Nat :=
  context.localContext.declarations.reverse.foldl (fun known declaration =>
    let id := psLocalDeclId declaration
    let values := match declaration with
      | .binding _ _ type _ => [type]
      | .letDecl _ _ type value => [type, value]
    let dependencies := values.flatMap fun value =>
      psExprFVarIds (psMetaInstantiate context.metaContext value)
    if known.contains id || !dependencies.any known.contains then known
    else known ++ [id]) roots

-- The singleton consumer uses the same correspondence closure as mutual
-- components. Observations are made in each actual branch scope; dependent
-- header slots become varying through the graph, never through source names.
def psElabRecursionFixedParameterPlan (context : PsElabContext)
    (ids : List Nat) (calls : List PsElabRecursionCall) :
    Except PsElabError PsFixedParameterPlan := do
  let dependencies := ids.zipIdx.map fun (id, index) =>
    let closed := psElabRecursionParameterDependencies context [id]
    ids.zipIdx.filterMap fun (dependent, position) =>
      if position != index && closed.contains dependent then some position else none
  let observations := calls.map fun call => ({
    caller := 0, callee := 0
    arguments := ids.zipIdx.map fun (id, index) =>
      if psElabRecursionParameterIsFixed context ids [call] id then some index else none
  } : PsFixedParameterCall)
  let graph ← (psFixedParameterAnalyze [dependencies] observations).mapError PsElabError.data
  (psFixedParameterPermutation graph).mapError PsElabError.data

def psElabRecursionMeasureParameterPlan (context : PsElabContext)
    (ids : List Nat) (calls : List PsElabRecursionCall) (measure : PsExpr) :
    Except PsElabError PsElabRecursionParameterPlan := do
  if calls.isEmpty then
    throw (.data "PSCV0-WF-NOT-RECURSIVE: termination_by was supplied for a nonrecursive declaration")
  let fixed ← psElabRecursionFixedParameterPlan context ids calls
  let [permutation] := fixed.permutations
    | throw (.data "PSCV0-WF-INTERNAL: singleton parameter analysis lost its owner")
  let varying := (ids.zip permutation).filterMap fun (id, index) =>
    if index.isNone then some id else none
  let dependencies := psExprFVarIds measure
  let measuredVarying := ids.filter fun id => varying.contains id && dependencies.contains id
  -- Constant/same-size candidates still create their genuine impossible
  -- decrease goals, preserving the established DECREASE diagnostic.
  let some majorId := measuredVarying.head? <|>
      (ids.find? varying.contains) <|> (ids.find? dependencies.contains) <|> ids.head?
    | throw (.data "PSCV0-WF-TELESCOPE: the selected slice requires an explicit header parameter")
  let some major := psLocalFindById context.localContext majorId
    | throw (.data "PSCV0-WF-INTERNAL: missing measured parameter binding")
  let majorDependencies := psExprFVarIds
    (psMetaInstantiate context.metaContext (psLocalDeclType major))
  -- A projection-only measure on the second slot need not mention its
  -- dependent domain in Core. Select from actual binder dependencies too,
  -- while leaving a first-only measure on the existing unary/state route.
  let dependentMajor := majorDependencies.any fun id => id != majorId && varying.contains id
  if measuredVarying.length > 1 || dependentMajor then do
    -- Close the measure's changing roots through their actual binder types.
    -- Locals are newest first, so every selected slot is visited before its
    -- older dependencies. Fixed captures do not become packed arguments.
    let packedDependencies := context.localContext.declarations.foldl (fun selected declaration =>
      if selected.contains (psLocalDeclId declaration) then
        selected ++ psExprFVarIds
          (psMetaInstantiate context.metaContext (psLocalDeclType declaration))
      else selected) (majorId :: measuredVarying)
    let packedIds := ids.filter (fun id =>
      varying.contains id && packedDependencies.contains id)
    let firstId :: _ :: _ := packedIds
      | throw (.data "PSCV0-WF-INTERNAL: a dependent pack lost its changing parameter telescope")
    -- Unmeasured changing parameters keep their original curried state order.
    let stateIds := ids.filter fun id => varying.contains id && !packedIds.contains id
    return {
      parameterIds := ids, majorId := firstId, packedIds
      fixedIds := ids.filter (fun id => !varying.contains id), stateIds }

  let changing := psElabRecursionParameterDependencies context (varying ++ [majorId])
  let stateIds := ids.filter fun id => id != majorId && changing.contains id
  if stateIds.any dependencies.contains then
    throw (.data "PSCV0-WF-MEASURE-STATE: the measure depends on evolving state")
  return {
    parameterIds := ids
    majorId := majorId
    fixedIds := ids.filter (fun id => !changing.contains id)
    stateIds := stateIds }

def psElabRecursionValidateFixedParameters (context : PsElabContext)
    (plan : PsElabRecursionParameterPlan) (calls : List PsElabRecursionCall) :
    Except PsElabError Unit := do
  for id in plan.fixedIds do
    if !psElabRecursionParameterIsFixed context plan.parameterIds calls id then
      throw (.data "PSCV0-WF-FIXED: a final typed recursive call changes a captured fixed parameter")

structure PsElabRecursionArguments where
  context : PsElabContext
  values : List PsExpr
  abstractions : List PsMetaAbstraction
  resultType : PsExpr

-- The ordinary application owner supplies every written, implicit, instance
-- and default argument. Its capture mode retains each once before a recursive
-- consumer permutes the complete typed header. The anonymous local is only a
-- type-correct application head; it is removed before the real call is built.
def psElabRecursionCaptureArguments (elaborate : PsElaborator)
    (context : PsElabContext)
    (arguments : List (Option PsSyntaxName × PsSyntaxTerm))
    (sourceType : PsExpr) (parameterCount : Nat) (expected : Option PsExpr) :
    Except PsElabError PsElabRecursionArguments := do
  let head := psLocalPushBinding context.localContext .anonymous sourceType .explicit
  let inner := psElabContextWithLocal context head.context
  let grouped ← psElabCallArguments arguments [] []
  let application ← (psElabApplyOrderedWith elaborate 4096
    { context := inner, term := .fvar head.id, type := sourceType }
    grouped.fst grouped.snd [] true expected (some { remaining := parameterCount })).mapError
      (fun error => match error with
        | .invalidArgument "arguments exceed the owned source telescope" =>
          .data "PSCV0-WF-ARITY: the recursive call exceeds its source header telescope"
        | _ => error)
  let some capture := application.capture
    | throw (.data "PSCV0-WF-INTERNAL: ordinary application lost its argument capture")
  if capture.remaining != 0 || capture.valuesRev.length != parameterCount then
    throw (.data "PSCV0-WF-ARITY: the recursive call must complete its source header telescope")
  -- Expected information has already flowed through the shared worker.
  -- Do not coerce the entire temporary application: only its arguments and
  -- exact declared result type belong to the recursive consumer.
  let resolved ← psElabFinishApplication application none
  let values := capture.valuesRev.reverse
  let expressions := resolved.type :: values ++ capture.abstractionsRev.flatMap
    (fun abstraction => match abstraction with
      | .letE _ _ type value => [type, value]
      | _ => [])
  if expressions.any (fun term =>
      (psExprFVarIds (psMetaInstantiate resolved.context.metaContext term)).contains head.id) then
    throw (.data "PSCV0-WF-INTERNAL: temporary source application escaped into a retained argument")
  let locals := { resolved.context.localContext with
    declarations := resolved.context.localContext.declarations.filter
      (fun declaration => psLocalDeclId declaration != head.id) }
  return {
    context := { resolved.context with localContext := locals }
    values, abstractions := capture.abstractionsRev, resultType := resolved.type }
