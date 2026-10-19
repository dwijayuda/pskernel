import Ps.Elab.CoreBoundary
import Ps.Elab.RecursionParameters
import Ps.Elab.Match
import Ps.Meta.Recursor

-- No body lambda enters the header or the termination clause's lexical scope.
-- Source recursive calls stay ordinary typed peer applications until the
-- compiled match has specialized its alternatives. Decrease goals are created
-- only by this Core pass; the unrestricted peers are absent from their scopes.
structure PsElabWellFoundedCoreRowCallback where
  majors : List PsExpr
  flags : List Bool
  type : PsExpr
  unrefinedType : PsExpr

structure PsElabWellFoundedCoreCall where
  sourceId : Nat
  callback : PsExpr
  recursion : PsElabWellFoundedRecursion
  fixedArguments : List (Nat × PsExpr) := []
  span : PsSourceSpan
  rowCallback? : Option PsElabWellFoundedCoreRowCallback := none
  sourceArity? : Option Nat := none

structure PsElabWellFoundedCoreMinor where
  scope : PsElabSavedScope
  bindersRev : List PsElabTypedBinder
  body : PsExpr
  domain : PsExpr
  callbacks : List PsExpr
  discrIds : List Nat

structure PsElabWellFoundedCoreRecursor where
  context : PsElabContext
  recursorBase : PsExpr
  minors : List PsElabWellFoundedCoreMinor
  indices : List PsExpr
  major : PsExpr
  arguments : List PsExpr

structure PsElabWellFoundedCoreSource where
  outer : PsElabContext
  scope : PsElabSavedScope
  bindersRev : List PsElabTypedBinder
  body : PsExpr
  type : PsExpr
  expected : PsExpr
  arguments : List PsExpr
  callbacks : List PsExpr
  discrIds : List Nat
  rowCallbacks : List PsElabWellFoundedCoreRowCallback

def psElabWellFoundedCoreHasCalls (calls : List PsElabWellFoundedCoreCall)
    (term : PsExpr) : Bool :=
  calls.any fun call => (psExprFVarIds term).contains call.sourceId

-- Instantiate only the actual arguments of an authenticated Core owner.
-- Stop at the owned prefix: a user lambda application in the resulting RHS
-- retains its lexical scope during fixed analysis and decrease-goal creation.
def psElabWellFoundedCoreApplyOwnedPrefix (value : PsExpr) : List PsExpr → PsExpr
  | [] => value
  | argument :: rest =>
    let next := match value with
      | .lam _ _ body _ => psExprInstantiate1 body argument
      | _ => PsExpr.app value argument
    psElabWellFoundedCoreApplyOwnedPrefix next rest

def psElabWellFoundedCoreClose (outer inner : PsElabContext)
    (bindersRev : List PsElabTypedBinder) (body type : PsExpr) :
    Except PsElabError PsElabTermResult :=
  psElabAbstract outer inner (psElabLambdaAbstractions bindersRev) body type

def psElabWellFoundedCoreDeclarationTerms : PsLocalDecl → List PsExpr
  | .binding _ _ type _ => [type]
  | .letDecl _ _ type value => [type, value]

-- Native dependsOnPred also observes an unresolved hole's possible fvar scope.
def psElabWellFoundedCoreCleanupDepends (metaContext : PsMetaContext)
    (used : List Nat) (term : PsExpr) : Bool :=
  let term := psMetaInstantiate metaContext term
  (psExprFVarIds term).any used.contains ||
    (psExprMetaIds term).any (fun id =>
      match psMetaFindDecl metaContext id with
      | none => true
      | some declaration => declaration.localContext.declarations.any
          (fun localDecl => used.contains (psLocalDeclId localDecl)))

-- Each productive pass adds at least one declaration; the source scope bounds it.
def psElabWellFoundedCoreCleanupUsed (fuel : Nat) (metaContext : PsMetaContext)
    (declarations : List (PsLocalDecl × Bool)) (used : List Nat) :
    Except PsElabError (List Nat) := do
  match fuel with
  | 0 => throw .fuelExhausted
  | fuel + 1 =>
    let next := declarations.foldl (fun current entry =>
      let declaration := entry.fst
      let id := psLocalDeclId declaration
      let propDepends := entry.snd && psElabWellFoundedCoreCleanupDepends metaContext
        current (psLocalDeclType declaration)
      let valueDepends := match declaration with
        | .binding .. => false
        | .letDecl _ _ _ value =>
          psElabWellFoundedCoreCleanupDepends metaContext current value
      if current.contains id || propDepends || valueDepends then
        (current ++ [id] ++ (psElabWellFoundedCoreDeclarationTerms declaration).flatMap
          (fun term => psExprFVarIds (psMetaInstantiate metaContext term))).eraseDups
      else current) used
    if next.length == used.length then return next
    psElabWellFoundedCoreCleanupUsed fuel metaContext declarations next

def psElabWellFoundedCoreGoalScope (context : PsElabContext)
    (calls : List PsElabWellFoundedCoreCall) (target : PsExpr) :
    Except PsElabError PsLocalContext := do
  let ids := calls.map (·.sourceId)
  let declarations := context.localContext.declarations.filter fun declaration =>
    !ids.contains (psLocalDeclId declaration)
  -- Preserve the existing refusal before dropping any otherwise-unused declaration.
  for declaration in declarations do
    if (psElabWellFoundedCoreDeclarationTerms declaration).any (fun term =>
        psElabWellFoundedCoreHasCalls calls (psMetaInstantiate context.metaContext term)) then
      throw (.data "PSCV0-WF-CLOSURE: a decrease scope retains an unrestricted source peer")
  let target := psMetaInstantiate context.metaContext target
  if psElabWellFoundedCoreHasCalls calls target then
    throw (.data "PSCV0-WF-CLOSURE: decrease target retains an unrestricted source peer")
  let classified ← declarations.mapM fun declaration => do
    let level ← psElabExpressionSort context (psLocalDeclType declaration)
    return (declaration, psLevelEquivalent level .zero)
  let used ← psElabWellFoundedCoreCleanupUsed (declarations.length + 1)
    context.metaContext classified (psExprFVarIds target).eraseDups
  let locals := { context.localContext with
    declarations := declarations.filter (fun declaration => used.contains (psLocalDeclId declaration))
    nameAliases := context.localContext.nameAliases.filter (fun alias => used.contains alias.id) }
  if !psMetaExprScopeSafe context.metaContext locals target then
    throw (.data "PSCV0-WF-CLOSURE: cleaned decrease target retains a removed local scope")
  for declaration in locals.declarations do
    if (psElabWellFoundedCoreDeclarationTerms declaration).any
        (fun term => !psMetaExprScopeSafe context.metaContext locals term) then
      throw (.data "PSCV0-WF-CLOSURE: cleaned decrease scope retains a removed local dependency")
  return locals

def psElabWellFoundedCoreApply (context : PsElabContext)
    (calls : List PsElabWellFoundedCoreCall) (call : PsElabWellFoundedCoreCall)
    (arguments : List PsExpr) : Except PsElabError PsElabTermResult := do
  let recursion := call.recursion
  if arguments.length < recursion.parameterIds.length then
    throw (.data "PSCV0-WF-ARITY: the recursive call must complete its source header telescope")
  let values := arguments.take recursion.parameterIds.length
  for (id, expected) in call.fixedArguments do
    let some actual := psElabRecursionParameterArgument recursion.parameterIds values id
      | throw (.data "PSCV0-WF-INTERNAL: missing fixed recursive argument")
    if psExprHasUnresolvedMeta (psMetaInstantiate context.metaContext actual) ||
        !psDefEqReadOnlyWithTransparency .reducible context.environment context.metaContext
          context.localContext expected actual then
      throw (.data "PSCV0-WF-FIXED: a compiled recursive call changes a captured fixed parameter")
  let recursiveIds := if recursion.packedIds.isEmpty then
    [recursion.majorId] else recursion.packedIds
  let recursiveArguments ← recursiveIds.mapM fun id =>
    match psElabRecursionParameterArgument recursion.parameterIds values id with
    | some value => pure value
    | none => throw (.data "PSCV0-WF-INTERNAL: missing measured recursive argument")
  let states ← recursion.stateIds.mapM fun id =>
    match psElabRecursionParameterArgument recursion.parameterIds values id with
    | some value => pure value
    | none => throw (.data "PSCV0-WF-INTERNAL: missing recursive state argument")
  let applied ← psElabApplyCore context call.callback recursiveArguments
  let proof ← (psInferEnsureForall applied.context.environment applied.context.metaContext
    applied.context.localContext applied.type).mapError PsElabError.infer
  let locals ← psElabWellFoundedCoreGoalScope applied.context calls proof.domain
  if psElabWellFoundedCoreHasCalls calls proof.domain ||
      !psMetaExprScopeSafe applied.context.metaContext locals proof.domain then
    throw (.data "PSCV0-WF-CLOSURE: decrease target retains an unrestricted source peer")
  let fresh := psMetaFresh applied.context.metaContext locals
    proof.domain .syntheticOpaque { tag := "decrease" }
  let .mvar goal := fresh.expr
    | throw (.data "PSCV0-WF-INTERNAL: invalid decrease goal")
  let context := { applied.context with
    metaContext := fresh.context
    wellFoundedGoalsRev := (goal, call.span) :: applied.context.wellFoundedGoalsRev }
  let result ← psElabApplyCore context applied.term
    (fresh.expr :: states ++ arguments.drop recursion.parameterIds.length)
  return result

-- Ownership is supplied by checked source/primitive descriptors. A source
-- flag only permits a substitution when its actual current argument is a fvar.
-- A completed source header may retain its checked function result for later
-- application. Eta-open only its actual extra operational tail; old incomplete
-- source-header refusals remain unchanged.
def psElabWellFoundedCoreApplyOperational (context : PsElabContext)
    (calls : List PsElabWellFoundedCoreCall) (call : PsElabWellFoundedCoreCall)
    (arguments : List PsExpr) : Except PsElabError PsElabTermResult := do
  let arity := call.recursion.parameterIds.length
  if arguments.length >= arity then
    return ← psElabWellFoundedCoreApply context calls call arguments
  let sourceArity := call.sourceArity?.getD arity
  if sourceArity > arity || arguments.length < sourceArity then
    throw (.data "PSCV0-WF-ARITY: the recursive call must complete its source header telescope")
  let original ← psElabApplyCore context (.fvar call.sourceId) arguments
  let missing := arity - arguments.length
  let opened ← psElabOpenCoreTelescope 4096 original.context original.type (some missing)
  if opened.bindersRev.length != missing then
    throw (.data "PSCV0-WF-ARITY: source result lost its checked operational Pi suffix")
  let extra := psElabBinderArguments opened.bindersRev
  let expected ← psElabApplyCore opened.context original.term extra
  let value ← psElabWellFoundedCoreApply expected.context calls call (arguments ++ extra)
  let value ← psElabResolvedTerm value.context value.term (some expected.type)
  psElabWellFoundedCoreClose original.context value.context
    opened.bindersRev value.term original.type

def psElabWellFoundedCoreReplacements (ids : List Nat)
    (originals currents : List PsExpr) : List (Nat × PsExpr) :=
  (originals.zip currents).reverse.filterMap fun (original, current) =>
    match original with
    | .fvar id => if ids.contains id then some (id, current) else none
    | _ => none

def psElabWellFoundedCoreCallbackBinders (context : PsElabContext)
    (calls : List PsElabWellFoundedCoreCall) (replacements : List (Nat × PsExpr)) :
    Except PsElabError (PsElabContext × List PsElabTypedBinder) :=
  calls.foldlM (fun (state : PsElabContext × List PsElabTypedBinder) call => do
    let type ← (psInferType state.fst.environment state.fst.metaContext
      state.fst.localContext call.callback).mapError PsElabError.infer
    let type := psElabSubstituteLocals replacements
      (psMetaInstantiate state.fst.metaContext type)
    let _ ← psElabExpressionSort state.fst type
    let name := call.recursion.callbackName
    let pushed := psLocalPushBinding state.fst.localContext name type .explicit
    let context := psElabContextWithLocal state.fst pushed.context
    let context := { context with auxiliaryLocalIds := pushed.id :: context.auxiliaryLocalIds }
    return (context, PsElabTypedBinder.mk pushed.id name type .explicit :: state.snd))
    (context, [])

-- The entire ds/Y telescope is opened before the callback domains are formed.
-- Source equation proofs follow these callbacks; they keep their original sides.
def psElabWellFoundedCorePrepareSource (context : PsElabContext)
    (calls : List PsElabWellFoundedCoreCall) (flags : List Bool) (proofCount : Nat)
    (value type : PsExpr) (arguments : List PsExpr) :
    Except PsElabError (Option PsElabWellFoundedCoreSource) := do
  if arguments.length != flags.length + proofCount then
    throw (.data "PSCV0-WF-BOUNDARY: source argument ownership arity mismatch")
  if calls.isEmpty then return none
  let raw := arguments.take flags.length
  let ids := (raw.zip flags).filterMap fun (argument, allowed) =>
    if allowed then
      match argument with | .fvar id => some id | _ => none
    else none
  if ids.isEmpty then return none
  let source ← psElabApplyCore context value arguments
  let majors ← psElabOpenCoreTelescope 4096 source.context type (some flags.length)
  let majorArguments := psElabBinderArguments majors.bindersRev
  let replacements := ((raw.zip flags).zip majorArguments).reverse.filterMap fun entry =>
    let ((original, allowed), current) := entry
    if allowed then
      match original with | .fvar id => some (id, current) | _ => none
    else none
  let (callbackContext, callbackBinders) ←
    psElabWellFoundedCoreCallbackBinders majors.context calls replacements
  let callbacks := psElabBinderArguments callbackBinders
  let proofs ← psElabOpenCoreTelescope 4096 callbackContext majors.body (some proofCount)
  let proofArguments := psElabBinderArguments proofs.bindersRev
  let body := psElabWellFoundedCoreApplyOwnedPrefix value (majorArguments ++ proofArguments)
  let body ← psElabResolvedTerm proofs.context body (some proofs.body)
  let bindersRev := proofs.bindersRev ++ callbackBinders ++ majors.bindersRev
  let domain := psCloseElabForallBinders body.context.metaContext bindersRev body.type
  let closed := psCloseElabLambdaBinders body.context.metaContext bindersRev body.term
  let outer := psElabLeaveScope context body.context
  let closed ← psElabResolvedTerm outer closed (some domain)
  let actual := raw ++ calls.map (·.callback) ++ arguments.drop flags.length
  let applied ← psElabApplyCore closed.context closed.term actual
  let checked ← psElabResolvedTerm applied.context applied.term (some source.type)
  let rowCallbacks ← (calls.zip callbacks).mapM fun (call, callback) => do
    let type ← (psInferType body.context.environment body.context.metaContext
      body.context.localContext callback).mapError PsElabError.infer
    let unrefinedType ← (psInferType body.context.environment body.context.metaContext
      body.context.localContext call.callback).mapError PsElabError.infer
    let effectiveFlags := (raw.zip flags).map fun (argument, allowed) =>
      allowed && (match argument with | .fvar _ => true | _ => false)
    return ({
      majors := majorArguments
      flags := effectiveFlags
      type := psMetaInstantiate body.context.metaContext type
      unrefinedType := psMetaInstantiate body.context.metaContext unrefinedType } :
      PsElabWellFoundedCoreRowCallback)
  let discrIds := replacements.filterMap fun entry =>
    match entry.snd with | .fvar id => some id | _ => none
  return some {
    outer := checked.context
    scope := psElabSaveScope body.context
    bindersRev
    body := body.term
    type := domain
    expected := source.type
    arguments := actual
    callbacks
    discrIds := discrIds.eraseDups
    rowCallbacks }

-- The result-prefix length is actual MatchPlan ownership, not the number of
-- forall binders left by the user's result. Companion motive slots own none.
def psElabWellFoundedCoreMotive (context : PsElabContext)
    (calls : List PsElabWellFoundedCoreCall) (ids : List Nat)
    (view : PsEliminationRecursorApplication) (prefixArguments : List PsExpr)
    (slot : PsInductiveEliminationSlot) (index : Nat) :
    Except PsElabError PsElabTermResult := do
  let some motive := view.fixedArgs[view.info.numParams + index]?
    | throw .matchRecursorUnsupported
  let motiveType ← (psInferType context.environment context.metaContext
    context.localContext motive).mapError PsElabError.infer
  let opened ← psElabOpenCoreTelescope 4096 context motiveType
    (some (slot.family.numIndices + 1))
  let arguments := psElabBinderArguments opened.bindersRev
  let value ← psElabApplyCore opened.context motive arguments
  let count := if index == view.slotIndex then prefixArguments.length else 0
  let result ← psElabOpenCoreTelescope 4096 value.context value.term (some count)
  let resultArguments := psElabBinderArguments result.bindersRev
  let replacements := if index == view.slotIndex then
    psElabWellFoundedCoreReplacements ids
      (view.indices ++ [view.major] ++ prefixArguments)
      (arguments ++ resultArguments)
    else []
  let (inner, callbacks) ←
    psElabWellFoundedCoreCallbackBinders result.context calls replacements
  let body := psCloseElabForallBinders inner.metaContext
    (callbacks ++ result.bindersRev) result.body
  let term := psCloseElabLambdaBinders inner.metaContext opened.bindersRev body
  psElabResolvedTerm (psElabLeaveScope context inner) term none

def psElabWellFoundedCorePrepareRecursor (context : PsElabContext)
    (calls : List PsElabWellFoundedCoreCall) (ids : List Nat)
    (view : PsEliminationRecursorApplication) (prefixArguments : List PsExpr)
    (original : PsExpr) : Except PsElabError (Option PsElabWellFoundedCoreRecursor) := do
  if calls.isEmpty || psEliminationRecursorUsesHypotheses view then return none
  if !view.suffix.isEmpty then
    throw (.data "PSCV0-WF-BOUNDARY: primitive value contains unowned result arguments")
  if (view.fixedArgs.take (view.info.numParams + view.info.numMotives)).any
      (psElabWellFoundedCoreHasCalls calls) then return none
  let (context, motives) ← view.plan.slots.zipIdx.foldlM
    (fun (state : PsElabContext × List PsExpr) (slot, index) => do
      let motive ← psElabWellFoundedCoreMotive state.fst calls ids view prefixArguments slot index
      return (motive.context, state.snd ++ [motive.term])) (context, [])
  let some motive := motives[view.slotIndex]? | throw .matchRecursorUnsupported
  let motiveLevel ← psElabMatchMotiveLevel context motive
  let .constE _ oldLevels := view.head | throw .matchRecursorUnsupported
  let some familyLevels := psInductiveEliminationFamilyLevels view.plan view.info oldLevels
    | throw .matchRecursorLevels
  let some anchor := view.plan.group.members.head? | throw .matchRecursorUnsupported
  let levels ← psElabRecursorLevels anchor view.info familyLevels motiveLevel
  let recursorBase ← psElabApplyCore context (.constE view.info.name levels)
    (view.fixedArgs.take view.info.numParams ++ motives)
  let constructors := view.plan.slots.zipIdx.flatMap fun (slot, owner) =>
    slot.constructors.map fun constructor => (owner, constructor)
  if constructors.length != view.info.numMinors then throw .matchRecursorUnsupported
  let selectedRoot := (view.indices ++ [view.major]).any fun argument =>
    match argument with | .fvar id => ids.contains id | _ => false
  let mut current := recursorBase.context
  let mut cursor := recursorBase.type
  let mut minors : List PsElabWellFoundedCoreMinor := []
  let mut values : List PsExpr := []
  let mut refined := false
  for ((owner, constructor), index) in constructors.zipIdx do
    let pi ← (psInferEnsureForall current.environment current.metaContext
      current.localContext cursor).mapError PsElabError.infer
    let count := constructor.info.numFields + constructor.recursiveFields.length
    let resultCount := if owner == view.slotIndex then prefixArguments.length else 0
    let opened ← psElabOpenCoreTelescope 4096 current pi.domain
      (some (count + resultCount + calls.length))
    let arguments := psElabBinderArguments opened.bindersRev
    let resultArguments := (arguments.drop count).take resultCount
    let callbacks := arguments.drop (count + resultCount)
    if callbacks.length != calls.length then throw .matchRecursorUnsupported
    let callbackIds := callbacks.filterMap fun value =>
      match value with | .fvar id => some id | _ => none
    let inner := { opened.context with
      auxiliaryLocalIds := callbackIds ++ opened.context.auxiliaryLocalIds }
    let some minor := view.fixedArgs[view.info.numParams + view.info.numMotives + index]?
      | throw .matchRecursorUnsupported
    let body := psElabWellFoundedCoreApplyOwnedPrefix minor
      (arguments.take (count + resultCount))
    let checked ← psElabResolvedTerm inner body (some opened.body)
    for (call, callback) in calls.zip callbacks do
      let originalType ← (psInferType checked.context.environment checked.context.metaContext
        checked.context.localContext call.callback).mapError PsElabError.infer
      let currentType ← (psInferType checked.context.environment checked.context.metaContext
        checked.context.localContext callback).mapError PsElabError.infer
      if !psDefEqReadOnlyWithEnv checked.context.environment checked.context.metaContext
          checked.context.localContext originalType currentType then
        refined := true
    -- Further compiler splits may inspect actual constructor fields of an
    -- already authorized source discriminator. Computed-source aliases do not
    -- confer this authority. IHs and arbitrary result suffixes never do either.
    let fieldIds :=
      if owner == view.slotIndex && selectedRoot then
        (arguments.take constructor.info.numFields).filterMap fun argument =>
          match argument with | .fvar id => some id | _ => none
      else []
    let replacements := if owner == view.slotIndex then
      psElabWellFoundedCoreReplacements ids prefixArguments resultArguments else []
    let resultIds := replacements.filterMap fun entry =>
      match entry.snd with | .fvar id => some id | _ => none
    let discrIds := (fieldIds ++ resultIds ++ ids).eraseDups
    let closed := psCloseElabLambdaBinders checked.context.metaContext
      opened.bindersRev checked.term
    let result ← psElabResolvedTerm (psElabLeaveScope current checked.context)
      closed (some pi.domain)
    minors := minors ++ [{
      scope := psElabSaveScope checked.context
      bindersRev := opened.bindersRev
      body := checked.term
      domain := pi.domain
      callbacks
      discrIds }]
    values := values ++ [result.term]
    current := result.context
    cursor := psExprInstantiate1 pi.body result.term
  if !refined then return none
  let originalType ← (psInferType current.environment current.metaContext
    current.localContext original).mapError PsElabError.infer
  let extended := psExprApplyMany recursorBase.term
    (values ++ view.indices ++ [view.major] ++ prefixArguments ++ calls.map (·.callback))
  let checked ← psElabResolvedTerm current extended (some originalType)
  return some {
    context := checked.context
    recursorBase := recursorBase.term
    minors
    indices := view.indices
    major := view.major
    arguments := prefixArguments }

-- A pure preparation walk leaves the typed source peers intact. It can check
-- every completed compiler telescope and report real branch refinement before
-- any decrease metavariable is allocated. Row bodies end compiler ownership.
abbrev PsElabWellFoundedCoreRewriter :=
  Bool → PsElabContext → List PsElabWellFoundedCoreCall → Option (List Nat) → PsExpr →
    Except PsElabError (PsElabTermResult × Bool)

-- Restore the source row's caller scope before opening its generic pattern
-- telescope. Compiler fields and automatic equations are not tactic hypotheses.
def psElabWellFoundedCoreRowScope (context : PsElabContext)
    (calls : List PsElabWellFoundedCoreCall) (row : PsElabCoreRow) :
    Except PsElabError PsElabContext := do
  for value in row.callerValues do
    if !psMetaExprScopeSafe context.metaContext context.localContext value then
      throw (.data "PSCV0-WF-ROW: source caller identity escaped its checked scope")
    let _ ← (psInferType context.environment context.metaContext
      context.localContext value).mapError PsElabError.infer
    pure ()
  let roots := calls.map (·.sourceId) ++ row.callerValues.flatMap (fun value =>
    psExprFVarIds (psMetaInstantiate context.metaContext value))
  let ids := context.localContext.declarations.foldl (fun selected declaration =>
    if selected.contains (psLocalDeclId declaration) then
      let terms := match declaration with
        | .binding _ _ type _ => [type]
        | .letDecl _ _ type value => [type, value]
      selected ++ terms.flatMap (fun term =>
        psExprFVarIds (psMetaInstantiate context.metaContext term))
    else selected) roots
  let localContext := { context.localContext with
    declarations := context.localContext.declarations.filter fun declaration =>
      ids.contains (psLocalDeclId declaration)
    nameAliases := context.localContext.nameAliases.filter fun alias => ids.contains alias.id }
  for declaration in localContext.declarations do
    let terms := match declaration with
      | .binding _ _ type _ => [type]
      | .letDecl _ _ type value => [type, value]
    if terms.any (fun term => !psMetaExprScopeSafe context.metaContext localContext term) then
      throw (.data "PSCV0-WF-ROW: restored caller declaration has an unowned dependency")
  return { context with
    localContext
    auxiliaryLocalIds := context.auxiliaryLocalIds.filter ids.contains }

-- The row callback is formed from the source match's complete ds/Y template,
-- never by reversing constructor values in an already compiled alternative.
-- Check the entire extended row and its actual application before creating
-- any decrease goal. Nested source matches retain their own boundaries.
def psElabWellFoundedCoreRewriteRow (rewrite : PsElabWellFoundedCoreRewriter)
    (preparing : Bool) (context : PsElabContext)
    (calls : List PsElabWellFoundedCoreCall) (compiler : Option (List Nat))
    (row : PsElabCoreRow) (value type : PsExpr) (arguments : List PsExpr) :
    Except PsElabError (PsElabTermResult × Bool) := do
  if arguments.length < row.binderCount then
    throw (.data "PSCV0-WF-ROW: actual row argument arity changed")
  let ownedArguments := arguments.take row.binderCount
  let suffix := arguments.drop row.binderCount
  let original ← psElabApplyCore context value ownedArguments
  let callbackTypes ← calls.mapM fun call =>
    (psInferType original.context.environment original.context.metaContext
      original.context.localContext call.callback).mapError PsElabError.infer
  let caller ← psElabWellFoundedCoreRowScope original.context calls row
  if !psMetaExprScopeSafe caller.metaContext caller.localContext type ||
      !psMetaExprScopeSafe caller.metaContext caller.localContext value then
    throw (.data "PSCV0-WF-ROW: generic row retains a compiler-only local")
  let opened ← psElabOpenCoreTelescope 4096 caller type (some row.binderCount)
  let rowArguments := psElabBinderArguments opened.bindersRev
  let (patternContext, patterns) ← row.patterns.foldlM
    (fun (state : PsElabContext × List PsExpr) pattern => do
      let result ← psElabApplyCore state.fst pattern rowArguments
      return (result.context, state.snd ++ [result.term])) (opened.context, [])
  let mut current := patternContext
  let mut callbacksRev : List PsElabTypedBinder := []
  let mut refined := false
  for (call, originalType) in calls.zip callbackTypes do
    let (callbackType, unrefinedType) ← if compiler.isSome then do
      let some template := call.rowCallback?
        | throw (.data "PSCV0-WF-ROW: source callback template is absent")
      if template.majors.length != patterns.length ||
          template.flags.length != patterns.length then
        throw (.data "PSCV0-WF-ROW: generic LHS changed the complete discriminator telescope")
      let replacements := ((template.majors.zip template.flags).zip patterns).reverse.filterMap
        fun entry =>
          let ((major, allowed), pattern) := entry
          if allowed then
            match major with | .fvar id => some (id, pattern) | _ => none
          else none
      pure (psElabSubstituteLocals replacements template.type, template.unrefinedType)
    else pure (originalType, originalType)
    let callbackType := psMetaInstantiate current.metaContext callbackType
    let unrefinedType := psMetaInstantiate current.metaContext unrefinedType
    if !psMetaExprScopeSafe current.metaContext current.localContext callbackType ||
        !psMetaExprScopeSafe current.metaContext current.localContext unrefinedType then
      throw (.data "PSCV0-WF-ROW: callback type escaped the generic source row")
    let _ ← psElabExpressionSort current callbackType
    if compiler.isSome && !psDefEqReadOnlyWithEnv current.environment current.metaContext
        current.localContext callbackType unrefinedType then
      refined := true
    let name := call.recursion.callbackName
    let pushed := psLocalPushBinding current.localContext name callbackType .explicit
    current := { current with
      localContext := pushed.context
      auxiliaryLocalIds := pushed.id :: current.auxiliaryLocalIds }
    callbacksRev := PsElabTypedBinder.mk pushed.id name callbackType .explicit :: callbacksRev
  for (name, index) in row.aliases do
    let some (.fvar id) := rowArguments[index]?
      | throw (.data "PSCV0-WF-ROW: source alias does not identify a real row binder")
    let some locals := psLocalAddNameAlias current.localContext name id
      | throw (.data "PSCV0-WF-ROW: source alias target is absent")
    current := { current with localContext := locals }
  let generic := psElabWellFoundedCoreApplyOwnedPrefix value rowArguments
  let generic ← psElabResolvedTerm current generic (some opened.body)
  let bindersRev := callbacksRev ++ opened.bindersRev
  let domain := psCloseElabForallBinders generic.context.metaContext bindersRev generic.type
  let closed := psCloseElabLambdaBinders generic.context.metaContext bindersRev generic.term
  let outer := psElabLeaveScope original.context generic.context
  let checked ← psElabResolvedTerm outer closed (some domain)
  let actualArguments := ownedArguments ++ calls.map (·.callback)
  let checked ← psElabApplyCore checked.context checked.term actualArguments
  let checked ← psElabResolvedTerm checked.context checked.term (some original.type)
  let inner := psElabRestoreScope checked.context (psElabSaveScope generic.context)
  let callbacks := psElabBinderArguments callbacksRev
  let rowCalls := (calls.zip callbacks).map fun (call, callback) =>
    { call with callback, rowCallback? := none }
  let (body, _) ← rewrite preparing inner rowCalls none generic.term
  let closed ← psElabWellFoundedCoreClose checked.context body.context
    bindersRev body.term domain
  let applied ← psElabApplyCore closed.context closed.term actualArguments
  let result ← psElabResolvedTerm applied.context applied.term (some original.type)
  let result ← psElabApplyCore result.context result.term suffix
  return (result, refined)

def psElabWellFoundedCoreFinishRecursor (rewrite : PsElabWellFoundedCoreRewriter)
    (preparing : Bool) (calls : List PsElabWellFoundedCoreCall)
    (plan : PsElabWellFoundedCoreRecursor) :
    Except PsElabError (PsElabTermResult × Bool) := do
  let mut current := plan.context
  let mut minors : List PsExpr := []
  for minor in plan.minors do
    let inner := psElabRestoreScope current minor.scope
    let branchCalls := (calls.zip minor.callbacks).map fun (call, callback) =>
      { call with callback }
    let (body, _) ← rewrite preparing inner branchCalls (some minor.discrIds) minor.body
    let closed ← psElabWellFoundedCoreClose current body.context
      minor.bindersRev body.term minor.domain
    current := closed.context
    minors := minors ++ [closed.term]
  let (varyingContext, varying) ← (plan.indices ++ [plan.major]).foldlM
    (fun (state : PsElabContext × List PsExpr) term => do
      let (value, _) ← rewrite preparing state.fst calls none term
      return (value.context, state.snd ++ [value.term])) (current, [])
  let (suffixContext, arguments) ← plan.arguments.foldlM
    (fun (state : PsElabContext × List PsExpr) term => do
      let (value, _) ← rewrite preparing state.fst calls none term
      return (value.context, state.snd ++ [value.term])) (varyingContext, [])
  let result ← psElabResolvedTerm suffixContext
    (psExprApplyMany plan.recursorBase
      (minors ++ varying ++ arguments ++ calls.map (·.callback))) none
  return (result, true)

def psElabWellFoundedCoreProbeSource (rewrite : PsElabWellFoundedCoreRewriter)
    (calls : List PsElabWellFoundedCoreCall) (plan : PsElabWellFoundedCoreSource) :
    Except PsElabError (Option (PsElabWellFoundedCoreSource × PsElabTermResult)) := do
  let inner := psElabRestoreScope plan.outer plan.scope
  if calls.length != plan.callbacks.length || calls.length != plan.rowCallbacks.length then
    throw (.data "PSCV0-WF-ROW: prepared callback ownership arity changed")
  let branchCalls := ((calls.zip plan.callbacks).zip plan.rowCallbacks).map
    fun ((call, callback), rowCallback) =>
      { call with callback, rowCallback? := some rowCallback }
  let (body, refined) ← rewrite true inner branchCalls (some plan.discrIds) plan.body
  if !refined then return none
  let closed ← psElabWellFoundedCoreClose plan.outer body.context
    plan.bindersRev body.term plan.type
  let applied ← psElabApplyCore closed.context closed.term plan.arguments
  let checked ← psElabResolvedTerm applied.context applied.term (some plan.expected)
  return some ({ plan with outer := checked.context }, checked)

-- The native addArg? fallback applies to the complete attempted source matcher.
-- No failed preparation state or proof goal escapes; wrapped resource failures
-- remain visible. A later failure while replacing calls is an actual failure.
def psElabWellFoundedCoreTrySource (rewrite : PsElabWellFoundedCoreRewriter)
    (context : PsElabContext) (calls : List PsElabWellFoundedCoreCall)
    (flags : List Bool) (proofCount : Nat) (value type : PsExpr) (arguments : List PsExpr) :
    Except PsElabError (Option (PsElabWellFoundedCoreSource × PsElabTermResult)) :=
  match (do
    let some plan ← psElabWellFoundedCorePrepareSource context calls flags proofCount
      value type arguments | return none
    psElabWellFoundedCoreProbeSource rewrite calls plan) with
  | .ok result => .ok result
  | .error error => if psElabErrorIsResource error then .error error else .ok none

def psElabWellFoundedCoreFinishSource (rewrite : PsElabWellFoundedCoreRewriter)
    (calls : List PsElabWellFoundedCoreCall) (plan : PsElabWellFoundedCoreSource) :
    Except PsElabError PsElabTermResult := do
  let inner := psElabRestoreScope plan.outer plan.scope
  if calls.length != plan.callbacks.length || calls.length != plan.rowCallbacks.length then
    throw (.data "PSCV0-WF-ROW: prepared callback ownership arity changed")
  let branchCalls := ((calls.zip plan.callbacks).zip plan.rowCallbacks).map
    fun ((call, callback), rowCallback) =>
      { call with callback, rowCallback? := some rowCallback }
  let (body, _) ← rewrite false inner branchCalls (some plan.discrIds) plan.body
  let closed ← psElabWellFoundedCoreClose plan.outer body.context
    plan.bindersRev body.term plan.type
  let applied ← psElabApplyCore closed.context closed.term plan.arguments
  psElabResolvedTerm applied.context applied.term (some plan.expected)

def psElabWellFoundedCoreBoundaryArguments (context : PsElabContext)
    (body : PsExpr) : Except PsElabError (List PsExpr) := do
  let view := psExprAppView body
  let .bvar 0 := view.head
    | throw (.data "PSCV0-WF-BOUNDARY: checked marker is not a direct closure application")
  for argument in view.args do
    -- Inference in the outer scope also rejects any occurrence of the marker
    -- binder or other loose bvars inside its arguments.
    let _ ← (psInferType context.environment context.metaContext
      context.localContext argument).mapError PsElabError.infer
  return view.args

def psElabWellFoundedCoreRewriteArguments (rewrite : PsElabWellFoundedCoreRewriter)
    (preparing : Bool) (context : PsElabContext)
    (calls : List PsElabWellFoundedCoreCall) (compiler : Option (List Nat))
    (arguments : List PsExpr) :
    Except PsElabError (PsElabContext × List PsExpr × Bool) :=
  arguments.foldlM
    (fun (state : PsElabContext × List PsExpr × Bool) argument => do
      let (value, refined) ← rewrite preparing state.fst calls compiler argument
      return (value.context, state.snd.fst ++ [value.term], state.snd.snd || refined))
    (context, [], false)

-- Only the typed source-call capsule owns this exact header-argument let
-- prefix. User-written lets are handled by the ordinary Core visitor.
-- Suffix arguments have already been rewritten in the capsule's outer scope.
-- Read only the already-authenticated capture spine. The terminal peer and
-- original arity are the same checked ownership facts consumed by the rewriter.
def psElabWellFoundedCoreCapturedArity (context : PsElabContext)
    (calls : List PsElabWellFoundedCoreCall) (captureCount sourceArity : Nat)
    (source : PsExpr) : Except PsElabError Nat := do
  let source := psMetaInstantiate context.metaContext source
  match captureCount with
  | 0 =>
    let view := psExprAppView source
    let .fvar id := view.head
      | throw (.data "PSCV0-WF-CAPTURE: checked call capsule lost its source peer")
    let some call := calls.find? (fun call => call.sourceId == id)
      | throw (.data "PSCV0-WF-CAPTURE: checked call capsule has no current recursive owner")
    let wholeArity := call.recursion.parameterIds.length
    if view.args.length != sourceArity || sourceArity > wholeArity ||
        sourceArity != call.sourceArity?.getD wholeArity then
      throw (.data "PSCV0-WF-CAPTURE: checked call capsule changed its source telescope")
    return wholeArity
  | captureCount + 1 =>
    let .letE _ _ _ body := source
      | throw (.data "PSCV0-WF-CAPTURE: checked call capsule lost an owned argument let")
    psElabWellFoundedCoreCapturedArity context calls captureCount sourceArity body

-- Keep the exact goal identities/spans and their original frozen scopes.
-- Nested capsule consumers may reorder their own newly appended segment only.
def psElabWellFoundedCoreGoalSegment
    (initialGoals laterGoals : List (Nat × PsSourceSpan)) :
    Except PsElabError (List (Nat × PsSourceSpan)) := do
  if laterGoals.length < initialGoals.length then
    throw (.data "PSCV0-WF-GOALS: a Core consumer removed an earlier decrease goal")
  let count := laterGoals.length - initialGoals.length
  if (laterGoals.drop count).map Prod.fst != initialGoals.map Prod.fst then
    throw (.data "PSCV0-WF-GOALS: a Core consumer changed an earlier decrease-goal segment")
  return laterGoals.take count

def psElabWellFoundedCoreRewriteCapturedCall
    (rewrite : PsElabWellFoundedCoreRewriter) (preparing : Bool)
    (context : PsElabContext) (calls : List PsElabWellFoundedCoreCall)
    (compiler : Option (List Nat)) (captureCount sourceArity : Nat)
    (source : PsExpr) (suffix : List PsExpr) :
    Except PsElabError (PsElabTermResult × Bool) := do
  let source := psMetaInstantiate context.metaContext source
  match captureCount with
  | 0 =>
    let view := psExprAppView source
    let .fvar id := view.head
      | throw (.data "PSCV0-WF-CAPTURE: checked call capsule lost its source peer")
    let some call := calls.find? (fun call => call.sourceId == id)
      | throw (.data "PSCV0-WF-CAPTURE: checked call capsule has no current recursive owner")
    if view.args.length != sourceArity ||
        sourceArity != call.sourceArity?.getD call.recursion.parameterIds.length then
      throw (.data "PSCV0-WF-CAPTURE: checked call capsule changed its original source arity")
    let (argumentContext, prefixArguments, refined) ←
      psElabWellFoundedCoreRewriteArguments rewrite preparing context calls compiler view.args
    let arguments := prefixArguments ++ suffix
    if preparing then
      return (← psElabApplyCore argumentContext (.fvar id) arguments, refined)
    return (← psElabWellFoundedCoreApplyOperational argumentContext calls call arguments, refined)
  | captureCount + 1 =>
    let .letE name type value body := source
      | throw (.data "PSCV0-WF-CAPTURE: checked call capsule lost an owned argument let")
    let (type, first) ← rewrite preparing context calls compiler type
    let (value, second) ← rewrite preparing type.context calls compiler value
    let value ← psElabResolvedTerm value.context value.term (some type.term)
    let pushed := psLocalPushLet value.context.localContext name type.term value.term
    let inner := psElabContextWithLocal value.context pushed.context
    let (body, third) ← psElabWellFoundedCoreRewriteCapturedCall rewrite preparing
      inner calls compiler captureCount sourceArity
      (psExprInstantiate1 body (.fvar pushed.id)) suffix
    let result ← psElabCloseLetScope value.context body pushed.id name type.term value.term none
    return (result, first || second || third)

def psElabWellFoundedCoreRewrite (fuel : Nat) (preparing : Bool)
    (context : PsElabContext) (calls : List PsElabWellFoundedCoreCall)
    (compiler : Option (List Nat)) (source : PsExpr) :
    Except PsElabError (PsElabTermResult × Bool) := do
  match fuel with
  | 0 => throw .fuelExhausted
  | fuel + 1 =>
    let term := psMetaInstantiate context.metaContext source
    if !psElabWellFoundedCoreHasCalls calls term then
      return (← psElabResolvedTerm context term none, false)
    let rewrite := psElabWellFoundedCoreRewrite fuel
    let view := psExprAppView term
    -- Suffix expressions are checked once in caller scope. Their goal events
    -- are presented in native final-expression order after the owned captures.
    if let .letE boundaryName type value body := view.head then
      if let some boundary ← psElabCoreBoundaryMatch context boundaryName type value then
        if let .recursiveCall captureCount sourceArity := boundary.kind then
          let retainedArguments ← psElabWellFoundedCoreBoundaryArguments context body
          if !retainedArguments.isEmpty then
            throw (.data "PSCV0-WF-CAPTURE: source-call marker body changed its owned application")
          let original ← psElabResolvedTerm context term none
          let wholeArity ← psElabWellFoundedCoreCapturedArity original.context
            calls captureCount sourceArity value
          let opCount := wholeArity - sourceArity
          let initialGoals := original.context.wellFoundedGoalsRev
          let (opContext, opArguments, first) ←
            psElabWellFoundedCoreRewriteArguments rewrite preparing original.context
              calls compiler (view.args.take opCount)
          let opGoals ← psElabWellFoundedCoreGoalSegment
            initialGoals opContext.wellFoundedGoalsRev
          let (argumentContext, residualArguments, second) ←
            psElabWellFoundedCoreRewriteArguments rewrite preparing opContext
              calls compiler (view.args.drop opCount)
          let residualGoals ← psElabWellFoundedCoreGoalSegment
            opContext.wellFoundedGoalsRev argumentContext.wellFoundedGoalsRev
          let (result, third) ← psElabWellFoundedCoreRewriteCapturedCall rewrite preparing
            argumentContext calls compiler captureCount sourceArity value
            (opArguments ++ residualArguments)
          let result ← psElabResolvedTerm result.context result.term (some original.type)
          if preparing then return (result, first || second || third)
          let capturedGoals ← psElabWellFoundedCoreGoalSegment
            argumentContext.wellFoundedGoalsRev result.context.wellFoundedGoalsRev
          let outerGoal :: headerGoals := capturedGoals
            | throw (.data "PSCV0-WF-GOALS: checked recursive application lost its decrease goal")
          let result := { result with context := { result.context with
            wellFoundedGoalsRev := residualGoals ++ [outerGoal] ++
              opGoals ++ headerGoals ++ initialGoals } }
          return (result, first || second || third)
    if let .fvar id := view.head then
      if let some call := calls.find? (fun call => call.sourceId == id) then
        let arity := call.recursion.parameterIds.length
        let (argumentContext, parameterArguments, first) ←
          psElabWellFoundedCoreRewriteArguments rewrite preparing context calls compiler
            (view.args.take arity)
        let result ← if preparing then
          psElabApplyCore argumentContext (.fvar id) parameterArguments
        else
          psElabWellFoundedCoreApplyOperational argumentContext calls call parameterArguments
        let (residualContext, residualArguments, second) ←
          psElabWellFoundedCoreRewriteArguments rewrite preparing result.context calls compiler
            (view.args.drop arity)
        let result ← psElabApplyCore residualContext result.term residualArguments
        return (result, first || second)
    -- Consume authenticated closures before pushing a local let declaration:
    -- their unchecked source peers must never enter a decrease-goal scope.
    if let .letE name type value body := term then
      if let some boundary ← psElabCoreBoundaryMatch context name type value then
        let arguments ← psElabWellFoundedCoreBoundaryArguments context body
        let (argumentContext, arguments, _) ←
          psElabWellFoundedCoreRewriteArguments rewrite preparing context calls none arguments
        let original := psElabWellFoundedCoreApplyOwnedPrefix value arguments
        match boundary.kind with
        | .recursiveCall .. =>
          throw (.data "PSCV0-WF-CAPTURE: recursive capture bypassed its owned consumer")
        | .source flags proofCount =>
          if let some (plan, prepared) ← psElabWellFoundedCoreTrySource rewrite
              argumentContext calls flags proofCount value type arguments then
            if preparing then return (prepared, false)
            return (← psElabWellFoundedCoreFinishSource rewrite calls plan, false)
          -- An ill-typed optional extension or absence of actual alternative
          -- refinement uses the original callback in the original source scope.
          return ← rewrite preparing argumentContext calls none original
        | .row =>
          let some row := boundary.row?
            | throw (.data "PSCV0-WF-ROW: checked source row metadata is absent")
          return ← psElabWellFoundedCoreRewriteRow rewrite preparing argumentContext
            calls compiler row value type arguments
        | .primitive selectedSlot prefixArity =>
          if arguments.length != prefixArity then
            throw (.data "PSCV0-WF-BOUNDARY: primitive result-prefix arity mismatch")
          if let some ids := compiler then
            let some recursor := psEliminationRecursorApplication argumentContext.environment value
              | throw (.data "PSCV0-WF-BOUNDARY: primitive is not its checked canonical recursor")
            if recursor.slotIndex != selectedSlot then
              throw (.data "PSCV0-WF-BOUNDARY: primitive recursor slot changed")
            if let some plan ← psElabWellFoundedCorePrepareRecursor argumentContext calls
                ids recursor arguments original then
              return ← psElabWellFoundedCoreFinishRecursor rewrite preparing calls plan
          return ← rewrite preparing argumentContext calls compiler original
    match term with
    | .app fn argument =>
      let (fn, first) ← rewrite preparing context calls compiler fn
      let (argument, second) ← rewrite preparing fn.context calls compiler argument
      let result ← psElabApplyCore argument.context fn.term [argument.term]
      return (result, first || second)
    | .lam name domain body binder =>
      let (domain, first) ← rewrite preparing context calls compiler domain
      let _ ← psElabExpressionSort domain.context domain.term
      let pushed := psLocalPushBinding domain.context.localContext name domain.term binder
      let inner := psElabContextWithLocal domain.context pushed.context
      let (body, second) ← rewrite preparing inner calls compiler
        (psExprInstantiate1 body (.fvar pushed.id))
      let binders := [PsElabTypedBinder.mk pushed.id name domain.term binder]
      let type ← psElabAbstractType domain.context body.context
        [.forallE pushed.id name domain.term binder] body.type
      let inner := psElabContextWithMeta body.context type.context.metaContext
      let result ← psElabWellFoundedCoreClose domain.context inner binders body.term type.term
      return (result, first || second)
    | .forallE name domain body binder =>
      let (domain, first) ← rewrite preparing context calls compiler domain
      let _ ← psElabExpressionSort domain.context domain.term
      let pushed := psLocalPushBinding domain.context.localContext name domain.term binder
      let inner := psElabContextWithLocal domain.context pushed.context
      let (body, second) ← rewrite preparing inner calls compiler
        (psExprInstantiate1 body (.fvar pushed.id))
      let result ← psElabAbstractType domain.context body.context
        [.forallE pushed.id name domain.term binder] body.term
      return (result, first || second)
    | .letE name type value body =>
      let (type, first) ← rewrite preparing context calls compiler type
      let (value, second) ← rewrite preparing type.context calls compiler value
      let value ← psElabResolvedTerm value.context value.term (some type.term)
      let pushed := psLocalPushLet value.context.localContext name type.term value.term
      let inner := psElabContextWithLocal value.context pushed.context
      let (body, third) ← rewrite preparing inner calls compiler
        (psExprInstantiate1 body (.fvar pushed.id))
      let result ← psElabCloseLetScope value.context body pushed.id name type.term value.term none
      return (result, first || second || third)
    | .proj name index value =>
      let (value, refined) ← rewrite preparing context calls compiler value
      let result ← psElabResolvedTerm value.context (.proj name index value.term) none
      return (result, refined)
    | _ => return (← psElabResolvedTerm context term none, false)

def psElabWellFoundedCoreCalls (context : PsElabContext)
    (calls : List PsElabWellFoundedCoreCall) (body expected : PsExpr) :
    Except PsElabError PsElabTermResult := do
  let body := psMetaInstantiate context.metaContext body
  if psExprHasTermMeta body then
    throw (.data "PSCV0-WF-CLOSURE: source body is unresolved before Core call replacement")
  let ids := calls.map (·.sourceId)
  if ids.eraseDups.length != ids.length then
    throw (.data "PSCV0-WF-INTERNAL: source call peers are not distinct")
  for call in calls do
    if call.sourceArity?.getD call.recursion.parameterIds.length >
        call.recursion.parameterIds.length then
      throw (.data "PSCV0-WF-INTERNAL: original source arity exceeds the operational telescope")
    if call.fixedArguments.map Prod.fst != call.recursion.fixedIds then
      throw (.data "PSCV0-WF-INTERNAL: fixed argument mapping changed its source slots")
    let some source := psLocalFindById context.localContext call.sourceId
      | throw (.data "PSCV0-WF-INTERNAL: source call peer is absent")
    let some sourceType := call.recursion.sourceType
      | throw (.data "PSCV0-WF-INTERNAL: recursive source telescope is absent")
    if !psDefEqReadOnlyWithEnv context.environment context.metaContext context.localContext
        (psLocalDeclType source) sourceType then
      throw (.data "PSCV0-WF-INTERNAL: source call peer changed its checked telescope")
    let _ ← psElabResolvedTerm context call.callback none
  let context := { context with wellFoundedRecursions := [] }
  let (result, _) ← psElabWellFoundedCoreRewrite 4096 false context calls none body
  psElabResolvedTerm result.context result.term (some expected)

