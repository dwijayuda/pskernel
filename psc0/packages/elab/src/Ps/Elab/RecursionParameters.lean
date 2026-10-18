import Ps.Elab.Binders
import Ps.Elab.Refinement
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

-- An owner carries its actual original header and the observations made
-- while elaborating its body. Numeric local IDs never identify another owner.
structure PsElabRecursionParameterOwner where
  name : PsName
  context : PsElabContext
  parameterIds : List Nat
  calls : List PsElabRecursionCall

-- Typed observations share one correspondence owner for unary and mutual
-- components. Pinned FixedParams compares reducibly without proof
-- irrelevance; equal spellings or equal numeric IDs across owners are not
-- evidence. Every comparison uses the caller's actual captured branch.
def psElabRecursionComponentFixedParameterPlan
    (owners : List PsElabRecursionParameterOwner) :
    Except PsElabError PsFixedParameterPlan := do
  let mut names : List PsName := []
  let mut dependencies := []
  for owner in owners do
    if names.any (psNameEq owner.name) ||
        owner.parameterIds.eraseDups.length != owner.parameterIds.length then
      throw (.data "PSCV0-WF-PARAMETERS: duplicate component or header identity")
    names := names ++ [owner.name]
    if owner.parameterIds.any (fun id =>
        (psLocalFindById owner.context.localContext id).isNone) then
      throw (.data "PSCV0-WF-PARAMETERS: original header binding is unavailable")
    dependencies := dependencies ++ [owner.parameterIds.zipIdx.map fun (id, index) =>
      let closed := psElabRecursionParameterDependencies owner.context [id]
      owner.parameterIds.zipIdx.filterMap fun (dependent, position) =>
        if position != index && closed.contains dependent then some position else none]
  let mut observations := []
  for (owner, caller) in owners.zipIdx do
    for call in owner.calls do
      let some (target, callee) := owners.zipIdx.find? (fun (target, _) =>
          psNameEq target.name call.callee)
        | throw (.data "PSCV0-WF-PARAMETERS: call target is outside the owned component")
      if call.arguments.length > target.parameterIds.length then
        throw (.data "PSCV0-WF-PARAMETERS: call exceeds its original target header")
      -- Native FixedParams treats missing underapplication slots as varying.
      -- This is conservative analysis only; it grants no call/decrease authority.
      let arguments := target.parameterIds.zipIdx.map fun (_, index) => do
        let argument ← call.arguments[index]?
        let argument := psMetaInstantiate owner.context.metaContext argument
        if psExprHasUnresolvedMeta argument then none else
          (owner.parameterIds.zipIdx.find? fun (id, _) =>
            (psLocalFindById call.localContext id).isSome &&
              psDefEqReadOnlyWithTransparency .reducible owner.context.environment
                owner.context.metaContext call.localContext (.fvar id) argument).map Prod.snd
      observations := observations ++ [{ caller, callee, arguments }]
  let graph ← (psFixedParameterAnalyze dependencies observations).mapError PsElabError.data
  (psFixedParameterPermutation graph).mapError PsElabError.data

-- A retained typed peer has a closed source header. Arity includes its
-- actual capture prefix but excludes any function in the result.
structure PsElabRecursionCallTarget where
  peerId : Nat
  name : PsName
  arity : Nat

-- Observe complete application spines once in their actual binder contexts,
-- as pinned FixedParams.getFixedParamsInfo does. The caller rechecks the
-- retained Core before analysis. This visitor constructs no recursive term
-- or proof and never changes the body. Missing arguments become conservative
-- varying observations; overapplication belongs to the returned result.
def psElabRecursionCollectCalls (fuel : Nat) (context : PsElabContext)
    (targets : List PsElabRecursionCallTarget) (span : PsSourceSpan)
    (term : PsExpr) : Except PsElabError (List PsElabRecursionCall) := do
  match fuel with
  | 0 => throw .fuelExhausted
  | fuel + 1 =>
    let view := psExprAppView term
    if let .fvar id := view.head then
      if let some target := targets.find? (fun target => target.peerId == id) then
        let nested ← view.args.mapM
          (psElabRecursionCollectCalls fuel context targets span)
        return {
          callee := target.name
          arguments := view.args.take target.arity
          localContext := context.localContext
          span } :: nested.flatten
    match term with
    | .app .. =>
      let head ← psElabRecursionCollectCalls fuel context targets span view.head
      let arguments ← view.args.mapM
        (psElabRecursionCollectCalls fuel context targets span)
      return head ++ arguments.flatten
    | .lam name domain body binder | .forallE name domain body binder =>
      let domainCalls ← psElabRecursionCollectCalls fuel context targets span domain
      let pushed := psLocalPushBinding context.localContext name domain binder
      let bodyCalls ← psElabRecursionCollectCalls fuel
        (psElabContextWithLocal context pushed.context) targets span
        (psExprInstantiate1 body (.fvar pushed.id))
      return domainCalls ++ bodyCalls
    | .letE name domain value body =>
      let domainCalls ← psElabRecursionCollectCalls fuel context targets span domain
      let valueCalls ← psElabRecursionCollectCalls fuel context targets span value
      let pushed := psLocalPushLet context.localContext name domain value
      let bodyCalls ← psElabRecursionCollectCalls fuel
        (psElabContextWithLocal context pushed.context) targets span
        (psExprInstantiate1 body (.fvar pushed.id))
      return domainCalls ++ valueCalls ++ bodyCalls
    | .proj _ _ value => psElabRecursionCollectCalls fuel context targets span value
    | .bvar _ | .mvar _ =>
      throw (.data "PSCV0-WF-PARAMETERS: retained call analysis found an open de Bruijn variable or unresolved metavariable")
    | _ => return []

-- Fixed correspondence is a complete permutation, never a partial map
-- inferred from source spellings. This contract is shared by scope creation
-- and member specialization.
def psElabRecursionValidatePermutation (permutation : List (Option Nat)) (count : Nat) :
    Except PsElabError Unit := do
  let indices := permutation.filterMap id
  if indices.length != count || indices.eraseDups.length != count ||
      indices.any (fun index => index >= count) then
    throw (.data "PSCV0-WF-PARAMETERS: fixed permutation is not a complete bijection")

structure PsElabRecursionFixedScope where
  context : PsElabContext
  bindersRev : List PsElabTypedBinder

-- The first owned closed header supplies common fixed types in graph order.
-- Its temporary varying locals never enter the resulting scope. Reopening
-- allocates fresh identities after the entire original telescope, so later
-- substitution cannot capture a local from another owner.
def psElabRecursionOpenFixedScope (context : PsElabContext)
    (sourceType : PsExpr) (permutation : List (Option Nat)) (count : Nat) :
    Except PsElabError PsElabRecursionFixedScope := do
  psElabRecursionValidatePermutation permutation count
  let opened ← psElabOpenCoreTelescope 4096 context sourceType (some permutation.length)
  let original := opened.bindersRev.reverse.zip permutation
  let mut current := { context with localContext :=
    { context.localContext with nextId := opened.context.localContext.nextId } }
  let mut replacements : List (Nat × PsExpr) := []
  let mut bindersRev := []
  for index in List.range count do
    let some (binder, _) := original.find? (fun (_, position) => position == some index)
      | throw (.data "PSCV0-WF-PARAMETERS: common fixed parameter has no original owner")
    let type := psElabSubstituteLocals replacements binder.type
    if !psExprFVarsInContext current.localContext type then
      throw (.data "PSCV0-WF-PARAMETERS: fixed parameter type depends on a varying slot")
    let _ ← psElabExpressionSort current type
    let pushed := psLocalPushBinding current.localContext binder.name type binder.binder
    current := psElabContextWithLocal current pushed.context
    replacements := replacements ++ [(binder.id, .fvar pushed.id)]
    bindersRev := PsElabTypedBinder.mk pushed.id binder.name type binder.binder :: bindersRev
  return { context := current, bindersRev }

structure PsElabRecursionSpecializedHeader where
  context : PsElabContext
  -- Only the varying original source parameters, newest first.
  bindersRev : List PsElabTypedBinder
  -- Complete original header order, including common fixed parameters.
  arguments : List PsExpr
  resultType : PsExpr
  type : PsExpr

private def psElabRecursionSpecializeHeaderWorker
    (fixed : List PsExpr) (permutation : List (Option Nat))
    (context : PsElabContext) (cursor : PsExpr)
    (bindersRev : List PsElabTypedBinder) (arguments : List PsExpr) :
    Except PsElabError PsElabRecursionSpecializedHeader := do
  match permutation with
  | [] =>
    return {
      context, bindersRev, arguments, resultType := cursor
      type := psCloseElabForallBinders context.metaContext bindersRev cursor }
  | position :: rest =>
    let parameter ← (psInferEnsureForall context.environment context.metaContext
      context.localContext cursor).mapError PsElabError.infer
    match position with
    | some index =>
      let some value := fixed[index]?
        | throw (.data "PSCV0-WF-PARAMETERS: common fixed argument is missing")
      let checked ← psElabResolvedTerm context value (some parameter.domain)
      psElabRecursionSpecializeHeaderWorker fixed rest checked.context
        (psExprInstantiate1 parameter.body checked.term) bindersRev (arguments ++ [checked.term])
    | none =>
      let pushed := psLocalPushBinding context.localContext parameter.name
        parameter.domain parameter.binder
      let value := PsExpr.fvar pushed.id
      psElabRecursionSpecializeHeaderWorker fixed rest
        (psElabContextWithLocal context pushed.context)
        (psExprInstantiate1 parameter.body value)
        (PsElabTypedBinder.mk pushed.id parameter.name parameter.domain parameter.binder :: bindersRev)
        (arguments ++ [value])

-- Like pinned FixedParamPerm.instantiateForall/buildArgs, stop at the
-- original source arity. A returned function stays in the result. Every
-- selected fixed value is checked against that member's actual domain;
-- reordered parameters do not bypass type or binder ownership.
def psElabRecursionSpecializeHeader (context : PsElabContext)
    (sourceType : PsExpr) (permutation : List (Option Nat)) (fixed : List PsExpr) :
    Except PsElabError PsElabRecursionSpecializedHeader := do
  psElabRecursionValidatePermutation permutation fixed.length
  if !psExprFVarsInContext context.localContext sourceType ||
      fixed.any (fun value => !psExprFVarsInContext context.localContext value) then
    throw (.data "PSCV0-WF-PARAMETERS: fixed specialization contains a foreign local")
  let result ← psElabRecursionSpecializeHeaderWorker fixed permutation context sourceType [] []
  let outer := psElabLeaveScope context result.context
  let _ ← psElabExpressionSort outer result.type
  return result

def psElabRecursionFixedParameterPlan (context : PsElabContext)
    (name : PsName) (ids : List Nat) (calls : List PsElabRecursionCall) :
    Except PsElabError PsFixedParameterPlan :=
  psElabRecursionComponentFixedParameterPlan [{ name, context, parameterIds := ids, calls }]

def psElabRecursionMeasureParameterPlan (context : PsElabContext)
    (name : PsName) (ids : List Nat) (calls : List PsElabRecursionCall) (measure : PsExpr) :
    Except PsElabError PsElabRecursionParameterPlan := do
  if calls.isEmpty then
    throw (.data "PSCV0-WF-NOT-RECURSIVE: termination_by was supplied for a nonrecursive declaration")
  let fixed ← psElabRecursionFixedParameterPlan context name ids calls
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
  remainingPositions : List PsSyntaxTerm := []
  remainingNames : PsElabNamedArguments := []

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
  let application ← psElabApplyOrderedWith elaborate 4096
    { context := inner, term := .fvar head.id, type := sourceType }
    grouped.fst grouped.snd [] true expected (some { remaining := parameterCount })
  let some capture := application.capture
    | throw (.data "PSCV0-WF-INTERNAL: ordinary application lost its argument capture")
  if capture.remaining != 0 || capture.valuesRev.length != parameterCount then
    throw (.data "PSCV0-WF-ARITY: the recursive call must complete its source header telescope")
  -- Expected information has already flowed through the shared worker.
  -- Do not coerce the entire temporary application: only its arguments and
  -- exact declared result type belong to the recursive consumer.
  -- Finish only the captured prefix. The caller retains the untouched
  -- suffix below and resumes it on the actual checked recursive result.
  let resolved ← psElabFinishApplication
    { application with remainingPositions := [], remainingNames := [] } none
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
    values, abstractions := capture.abstractionsRev, resultType := resolved.type
    remainingPositions := application.remainingPositions
    remainingNames := application.remainingNames }
