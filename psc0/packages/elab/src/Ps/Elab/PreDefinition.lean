import Ps.Elab.PreDefinition.Basic
import Ps.Elab.RecursionParameters
import Ps.Elab.MutualStructural
import Ps.Elab.PartialFixpoint

-- The source owner closes real local captures before this boundary. This
-- module owns the checked dependency graph and all downstream publication;
-- source spelling and capture labels cannot manufacture a recursive edge,
-- a global peer, or evidence for a different body.
def psElabPreDefinitionError (rule message : String) : PsElabError :=
  .data ("PSCV0-PREDEFINITION-" ++ rule ++ ": " ++ message)

abbrev PsElabPreDefinitionBatchResult := PsElabMutualBatchResult

abbrev PsElabPreDefinitionWellFoundedConsumer :=
  PsEnvironment → List PsName → PsElabPreDefinition →
    Except PsElabError PsElabWellFoundedResult

def psElabPreDefinitionDeclarationHead : PsSyntaxDeclaration → PsSyntaxDeclaration
  | .whereDeclaration parent _ _ => psElabPreDefinitionDeclarationHead parent
  | declaration => declaration

def psElabPreDefinitionExplicitPartial (member : PsElabPreDefinition) : Bool :=
  psElabPreDefinitionSourceExplicitPartial member.source

def psElabPreDefinitionSourceSpan (member : PsElabPreDefinition) : PsSourceSpan :=
  match member.source with
  | .declaration source => (psElabOriginSource source).snd
  | .localDefinition _ source => source.span

def psElabPreDefinitionSourceBinders (member : PsElabPreDefinition) :
    Except PsElabError (List (PsSyntaxBinderHead × PsSyntaxTerm)) := do
  match member.source with
  | .declaration source =>
    match psElabPreDefinitionDeclarationHead source with
    | .definition _ binders _ _ _ | .partialDefinition _ binders _ _ _
      | .noncomputableDefinition _ binders _ _ _
      | .fixedpointDefinition _ binders _ _ _ | .wellFoundedDefinition _ binders _ _ _ _ =>
      return binders
    | _ => throw (psElabPreDefinitionError "SOURCE" "checked predefinition has no def/function source owner")
  | .localDefinition _ source => return source.binders

def psElabPreDefinitionStrategyEq : PsElabPreDefinitionStrategy → PsElabPreDefinitionStrategy → Bool
  | .total, .total | .partial, .partial | .wellFounded, .wellFounded
    | .fixedpoint, .fixedpoint => true
  | _, _ => false

def psElabPreDefinitionSourceStrategy (members : List PsElabPreDefinition)
    (member : PsElabPreDefinition) : Except PsElabError PsElabPreDefinitionStrategy := do
  match member.source with
  | .declaration source =>
    match psElabPreDefinitionDeclarationHead source with
    | .definition .. | .noncomputableDefinition .. => return .total
    | .partialDefinition .. => return .partial
    | .wellFoundedDefinition .. => return .wellFounded
    | .fixedpointDefinition .. => return .fixedpoint
    | _ => throw (psElabPreDefinitionError "SOURCE" "unsupported predefinition source head")
  | .localDefinition parent source =>
    let some owner := members.find? (fun candidate => psNameEq candidate.name parent)
      | throw (psElabPreDefinitionError "SOURCE" "local definition lost its actual parent")
    match owner.source with
    | .declaration _ => pure ()
    | _ => throw (psElabPreDefinitionError "SOURCE" "selected flat where helper has a local helper parent")
    if member.sourceIndex != owner.sourceIndex then
      throw (psElabPreDefinitionError "SOURCE" "helper and parent source indices disagree")
    psElabPreDefinitionLocalStrategy (members.map (·.source)) source

structure PsElabPreDefinitionOpened where
  context : PsElabContext
  bindersRev : List PsElabTypedBinder
  type : PsExpr
  value : PsExpr

-- Consume only the retained raw header lambdas. Normalizing the value here
-- would conflate source parameters with a returned function's own lambdas.
def psElabPreDefinitionOpen (count : Nat) (context : PsElabContext)
    (type value : PsExpr) (bindersRev : List PsElabTypedBinder := []) :
    Except PsElabError PsElabPreDefinitionOpened := do
  match count with
  | 0 => return { context, bindersRev, type, value }
  | count + 1 =>
    let pi ← (psInferEnsureForall context.environment context.metaContext
      context.localContext type).mapError PsElabError.infer
    let .lam _ domain body binder := value
      | throw (psElabPreDefinitionError "HEADER" "retained source header exceeds the actual raw lambda prefix")
    if !psBinderInfoEq binder pi.binder ||
        !psExprFVarsInContext context.localContext domain ||
        !psElabMutualStructuralEqual context domain pi.domain then
      throw (psElabPreDefinitionError "HEADER" "raw lambda binder differs from its checked header domain or kind")
    let pushed := psLocalPushBinding context.localContext pi.name pi.domain pi.binder
    psElabPreDefinitionOpen count (psElabContextWithLocal context pushed.context)
      (psExprInstantiate1 pi.body (.fvar pushed.id))
      (psExprInstantiate1 body (.fvar pushed.id))
      (PsElabTypedBinder.mk pushed.id pi.name pi.domain pi.binder :: bindersRev)

-- Rebuild the peer-only context from the caller's actual environment. No
-- saved metavariable assignment, instance cache, pending job or recursion
-- hook participates in revalidating this already-closed Core boundary.
def psElabPreDefinitionValidate (environment : PsEnvironment)
    (block : PsElabPreDefinitionBlock) : Except PsElabError PsElabContext := do
  if block.members.isEmpty then
    throw (psElabPreDefinitionError "OWNERSHIP" "empty checked block")
  psElabPreDefinitionCheckMainModifiers (block.members.map (·.source))
  for name in block.levelNames do
    if (block.levelNames.filter (psNameEq name)).length != 1 then
      throw (psElabPreDefinitionError "UNIVERSES" "block universe layout repeats a parameter")
  let names := block.members.map (·.name)
  let peerIds := block.members.map (·.peerId)
  if peerIds.eraseDups.length != peerIds.length ||
      block.context.localContext.declarations.length != peerIds.length then
    throw (psElabPreDefinitionError "OWNERSHIP" "peer identities or retained context are incomplete")
  for name in names do
    if (names.filter (psNameEq name)).length != 1 || (psEnvironmentFind environment name).isSome then
      throw (.duplicateDeclaration name)
  for declaration in block.context.localContext.declarations do
    let .binding id _ type binder := declaration
      | throw (psElabPreDefinitionError "OWNERSHIP" "full peer context contains a local let")
    let some member := block.members.find? (fun member => member.peerId == id)
      | throw (psElabPreDefinitionError "OWNERSHIP" "full peer context contains an unowned local")
    if !psBinderInfoEq binder .explicit || !psExprAlphaEq type member.type ||
        id >= block.context.localContext.nextId ||
        (block.context.localContext.declarations.filter (fun entry => psLocalDeclId entry == id)).length != 1 then
      throw (psElabPreDefinitionError "OWNERSHIP" "peer binding does not retain its exact closed header and fresh identity")
  let initial := psElabContextEmpty environment block.levelNames
  let context := psElabContextWithLocal initial block.context.localContext
  for member in block.members do
    if member.registration.isSome then
      throw (psElabPreDefinitionError "REGISTRATION" "selected checked local batches cannot register extra declaration kinds")
    let strategy ← psElabPreDefinitionSourceStrategy block.members member
    if !psElabPreDefinitionStrategyEq strategy member.strategy then
      throw (psElabPreDefinitionError "STRATEGY" "retained strategy differs from its explicit source or parent owner")
    let sourceBinders ← psElabPreDefinitionSourceBinders member
    let sourceCount := sourceBinders.foldl (fun count entry => count + (psSyntaxBinderNames entry.fst).length) 0
    if member.sourceHeaderCount != sourceCount then
      throw (psElabPreDefinitionError "HEADER" "source header arity differs from its actual original binder names")
    for capture in member.captures do
      if (member.captures.filter (psElabPreDefinitionCaptureEq capture)).length != 1 then
        throw (psElabPreDefinitionError "CAPTURE" "capture prefix repeats one source local identity")
    if psExprHasUnresolvedMeta member.type || psExprHasUnresolvedMeta member.value ||
        !psExprFVarsInContext psLocalEmpty member.type ||
        !psExprFVarsInContext context.localContext member.value then
      throw (psElabPreDefinitionError "CLOSURE" "predefinition retains an unowned local or unresolved Core metavariable")
    let levels := psElabDeclarationLevels block.levelNames [member.type, member.value]
    if levels.any (fun name => !block.levelNames.any (psNameEq name)) then
      throw (psElabPreDefinitionError "UNIVERSES" "predefinition uses a level outside its closed source block")
    let _ ← (psElabExpressionSort initial member.type).mapError (.atDeclaration member.name)
    let _ ← (psElabResolvedTerm context member.value (some member.type)).mapError (.atDeclaration member.name)
    let opened ← psElabPreDefinitionOpen (psElabPreDefinitionHeaderCount member)
      context member.type member.value
    let closed := psCloseElabTypedBinders opened.context.metaContext opened.bindersRev opened.value opened.type
    if !psElabMutualStructuralEqual context closed.fst member.value ||
        !psElabMutualStructuralEqual initial closed.snd member.type then
      throw (psElabPreDefinitionError "HEADER" "raw source header failed exact typed reopening and closure")
    if !psNameEq member.sourceInfo.owner member.name then
      throw (psElabPreDefinitionError "SOURCE" "source information has a different declaration owner")
  return context

-- Typed parameter observations come from the same retained source bodies
-- that own the dependency SCC and final public equations. There is no second
-- source probe whose capture resolution could disagree with that authority.
def psElabPreDefinitionParameterOwners (environment : PsEnvironment)
    (levels : List PsName) (nextId : Nat) (members : List PsElabPreDefinition) :
    Except PsElabError (List PsElabRecursionParameterOwner) := do
  let ids := members.map (·.peerId)
  if members.isEmpty || ids.eraseDups.length != ids.length ||
      ids.any (fun id => id >= nextId) then
    throw (psElabPreDefinitionError "OWNERSHIP" "parameter analysis requires distinct fresh component peers")
  let declarations := members.map fun member =>
    PsLocalDecl.binding member.peerId member.name member.type .explicit
  let context := { psElabContextEmpty environment levels with
    localContext := { nextId, declarations } }
  let targets := members.map fun member =>
    ({ peerId := member.peerId, name := member.name
       arity := psElabPreDefinitionHeaderCount member } : PsElabRecursionCallTarget)
  members.mapM fun member => do
    if psExprHasUnresolvedMeta member.type || psExprHasUnresolvedMeta member.value ||
        !psExprFVarsInContext psLocalEmpty member.type ||
        !psExprFVarsInContext context.localContext member.value then
      throw (psElabPreDefinitionError "CLOSURE" "parameter analysis contains an unresolved or unowned Core identity")
    let _ ← psElabExpressionSort context member.type
    let _ ← psElabResolvedTerm context member.value (some member.type)
    let opened ← psElabPreDefinitionOpen (psElabPreDefinitionHeaderCount member)
      context member.type member.value
    let calls ← psElabRecursionCollectCalls 4096 opened.context targets
      (psElabPreDefinitionSourceSpan member) opened.value
    return {
      name := member.name
      context := opened.context
      parameterIds := opened.bindersRev.reverse.map (·.id)
      calls }

abbrev PsElabPreDefinitionGraph := List (Nat × List Nat)

def psElabPreDefinitionGraphFor (members : List PsElabPreDefinition) : PsElabPreDefinitionGraph :=
  let peers := members.map (·.peerId)
  members.map fun member =>
    (member.peerId, ((psExprFVarIds member.value).filter peers.contains).eraseDups)

-- Each round either adds a new real vertex or stabilizes. A graph with n
-- owned vertices therefore closes in n rounds, with deterministic ordering.
def psElabPreDefinitionReach (fuel : Nat) (graph : PsElabPreDefinitionGraph)
    (found : List Nat) : List Nat :=
  match fuel with
  | 0 => found
  | fuel + 1 =>
    let next := (found ++ found.flatMap (fun id =>
      (graph.find? (fun edge => edge.fst == id)).map (·.snd) |>.getD [])).eraseDups
    if next.length == found.length then found
    else psElabPreDefinitionReach fuel graph next

def psElabPreDefinitionComponent (graph : PsElabPreDefinitionGraph) (id : Nat) : List Nat :=
  let reachable := psElabPreDefinitionReach graph.length graph [id]
  graph.filterMap fun edge =>
    if reachable.contains edge.fst &&
        (psElabPreDefinitionReach graph.length graph [edge.fst]).contains id then
      some edge.fst
    else none

def psElabPreDefinitionCommonCaptures (members : List PsElabPreDefinition) :
    List PsElabPreDefinitionCapture :=
  match members with
  | [] => []
  | first :: rest =>
    let rec commonPrefix (remaining : List PsElabPreDefinitionCapture) (index : Nat) :
        List PsElabPreDefinitionCapture :=
      match remaining with
      | [] => []
      | capture :: tail =>
        if rest.all (fun member => (member.captures[index]?).any (psElabPreDefinitionCaptureEq capture)) then
          capture :: commonPrefix tail (index + 1)
        else []
    commonPrefix first.captures 0

structure PsElabPreDefinitionPeer where
  fullId : Nat
  specializedId : Nat
  memberIndex : Nat

-- The producer's full peer application already supplies genuine captures.
-- Consume exactly the common prefix, by actual local identity; a partial or
-- permuted prefix is refused. Recursive source arguments are left untouched.
def psElabPreDefinitionSpecialize (fuel : Nat) (captures : List PsExpr)
    (peers : List PsElabPreDefinitionPeer) (value : PsExpr) : Except PsElabError PsExpr := do
  match fuel with
  | 0 => throw .fuelExhausted
  | fuel + 1 =>
    let view := psExprAppView value
    if let .fvar id := view.head then
      if let some peer := peers.find? (fun peer => peer.fullId == id) then
        if view.args.length < captures.length ||
            !(view.args.take captures.length |>.zip captures).all (fun pair => psExprAlphaEq pair.fst pair.snd) then
          throw (psElabPreDefinitionError "CAPTURE-CALL" "full peer call does not supply its exact common capture prefix")
        let args ← (view.args.drop captures.length).mapM (psElabPreDefinitionSpecialize fuel captures peers)
        return psExprApplyMany (.fvar peer.specializedId) args
    match value with
    | .app fn arg =>
      let fn ← psElabPreDefinitionSpecialize fuel captures peers fn
      let arg ← psElabPreDefinitionSpecialize fuel captures peers arg
      return .app fn arg
    | .lam name domain body binder =>
      let domain ← psElabPreDefinitionSpecialize fuel captures peers domain
      let body ← psElabPreDefinitionSpecialize fuel captures peers body
      return .lam name domain body binder
    | .forallE name domain body binder =>
      let domain ← psElabPreDefinitionSpecialize fuel captures peers domain
      let body ← psElabPreDefinitionSpecialize fuel captures peers body
      return .forallE name domain body binder
    | .letE name type value body =>
      let type ← psElabPreDefinitionSpecialize fuel captures peers type
      let value ← psElabPreDefinitionSpecialize fuel captures peers value
      let body ← psElabPreDefinitionSpecialize fuel captures peers body
      return .letE name type value body
    | .proj name index value =>
      let value ← psElabPreDefinitionSpecialize fuel captures peers value
      return .proj name index value
    | _ => return value

-- Reopen each real header from the same fresh seed. The shared prefix gets
-- the same local identities; member-specific captures remain ordinary own
-- header slots. This is checked against the actual domains and binder kinds
-- before any full peer is replaced by its specialized local parameter.
def psElabPreDefinitionStructural (environment : PsEnvironment)
    (levels : List PsName) (nextId : Nat) (members : List PsElabPreDefinition) :
    Except PsElabError PsElabPreDefinitionBatchResult := do
  let first :: _ := members
    | throw (psElabPreDefinitionError "OWNERSHIP" "empty structural component")
  let initial := psElabContextWithLocal (psElabContextEmpty environment levels)
    { nextId, declarations := [] }
  let commonCount := (psElabPreDefinitionCommonCaptures members).length
  let common ← psElabPreDefinitionOpen commonCount initial first.type first.value
  let captured : PsElabTypedBindersResult := {
    context := common.context
    bindersRev := common.bindersRev }
  let captures := psElabBinderArguments captured.bindersRev
  let inputs ← members.mapM fun member => do
    let opened ← psElabPreDefinitionOpen (psElabPreDefinitionHeaderCount member)
      initial member.type member.value
    let capturePrefix := opened.bindersRev.reverse.take commonCount
    if capturePrefix.length != commonCount ||
        !(capturePrefix.zip captured.bindersRev.reverse).all (fun (actual, expected) =>
          actual.id == expected.id && psBinderInfoEq actual.binder expected.binder &&
          psElabMutualStructuralEqual captured.context actual.type expected.type) then
      throw (psElabPreDefinitionError "CAPTURE-TYPE" "common source captures have different actual typed telescopes")
    let header : PsElabCheckedHeader := {
      name := member.name
      context := opened.context
      bindersRev := opened.bindersRev
      openType := opened.type
      type := member.type }
    let (context, peers) ← members.zipIdx.foldlM
      (fun (state : PsElabContext × List PsElabPreDefinitionPeer) (target, index) => do
        let type ← psElabMutualStructuralApplyType state.fst target.type captures
        let _ ← psElabExpressionSort state.fst type
        let name := PsName.num (psRootName "$psc0PreDefinitionPeer") index
        let pushed := psLocalPushBinding state.fst.localContext name type .explicit
        return (psElabContextWithLocal state.fst pushed.context,
          state.snd ++ [{ fullId := target.peerId, specializedId := pushed.id, memberIndex := index }]))
      (opened.context, [])
    let body ← psElabPreDefinitionSpecialize 4096 captures peers opened.value
    if !psExprFVarsInContext context.localContext body then
      throw (psElabPreDefinitionError "CLOSURE" "structural body retains a full or unowned peer after capture specialization")
    let checked ← psElabResolvedTerm context body (some opened.type)
    (psElabMutualStructuralInputFromChecked captured header checked.context checked.term
      (peers.map fun peer => (peer.specializedId, peer.memberIndex))
      (psElabPreDefinitionSourceSpan member) member.sourceInfo).mapError (.atDeclaration member.name)
  psElabStructuralMutualFromChecked environment levels captured inputs

-- Called only after the selected definition/body construction succeeds.
-- These diagnostics describe unused source; they supply no proof or captures.
def psElabPreDefinitionUnusedHints (source : PsElabPreDefinitionSource)
    (reason : String) : List PsDiagnostic :=
  let totalHint (termination : PsSyntaxTermination) : PsDiagnostic :=
    let kind := if termination.decreasing.isSome then "unused termination hints" else "unused `termination_by`"
    {
      severity := .warning
      message := kind ++ ", function is " ++ reason
      span := termination.span
    }
  let fixedHint (span : PsSourceSpan) : PsDiagnostic := {
    severity := .warning
    message := "unused `partial_fixpoint`, function is " ++ reason
    span
  }
  match source with
  | .declaration source =>
    match psElabPreDefinitionDeclarationHead source with
    | .wellFoundedDefinition _ _ _ _ termination _ => [totalHint termination]
    | .fixedpointDefinition _ _ _ _ span => [fixedHint span]
    | _ => []
  | .localDefinition _ source =>
    match source.recursion with
    | some (.total termination) => [totalHint termination]
    | some (.fixedpoint span) => [fixedHint span]
    | none => []

-- Nonrecursive source and inherited-partial helpers use their already
-- checked ordinary values. The exact equation is proved after the actual
-- declaration is staged; no body witness or provisional global is introduced.
def psElabPreDefinitionNonrecursive (environment : PsEnvironment)
    (levels : List PsName) (member : PsElabPreDefinition) :
    Except PsElabError PsElabPreDefinitionBatchResult := do
  let equationName := psNameAppendStr member.name "eq_def"
  for name in [member.name, equationName] do
    if (psEnvironmentFind environment name).isSome then throw (.duplicateDeclaration name)
  if !psExprFVarsInContext psLocalEmpty member.value || psExprHasUnresolvedMeta member.value then
    throw (psElabPreDefinitionError "CLOSURE" "nonrecursive value retains a peer after dependency substitution")
  let initial := psElabContextEmpty environment levels
  let checked ← psElabResolvedTerm initial member.value (some member.type)
  -- Pinned MutualDef.pushLetRecs promotes proof-valued local definitions to
  -- theorem kind. Infer the actual closed type's sort; a source annotation or
  -- an operational strategy tag cannot assert that its value is a proof.
  let localProof ← match member.source with
    | .localDefinition .. => do
      let level ← psElabExpressionSort checked.context member.type
      pure (psLevelEquivalent level .zero)
    | .declaration _ => pure false
  let declaration := if localProof then
    PsDeclaration.theoremDecl member.name levels member.type checked.term
    else PsDeclaration.definitionDecl member.name levels member.type checked.term
  let staged ← psAddDeclarationList environment [declaration]
  let opened ← psElabPreDefinitionOpen (psElabPreDefinitionHeaderCount member)
    (psElabContextEmpty staged levels) member.type member.value
  let left ← psElabApplyCore opened.context (.constE member.name (levels.map PsLevel.param))
    (psElabBinderArguments opened.bindersRev)
  let level ← psElabExpressionSort left.context opened.type
  let equationType := psLogicEq level opened.type left.term opened.value
  let proof ← psElabResolvedTerm left.context (psLogicRefl level opened.type opened.value)
    (some equationType)
  let closed := psCloseElabTypedBinders proof.context.metaContext opened.bindersRev proof.term equationType
  if psExprHasUnresolvedMeta closed.fst || psExprHasUnresolvedMeta closed.snd ||
      !psExprFVarsInContext psLocalEmpty closed.fst || !psExprFVarsInContext psLocalEmpty closed.snd then
    throw (psElabPreDefinitionError "EQUATION" "ordinary source equation did not close against its original header")
  let checkedProof ← psElabResolvedTerm (psElabContextEmpty staged levels) closed.fst (some closed.snd)
  let equation := PsDeclaration.theoremDecl equationName levels closed.snd checkedProof.term
  let _ ← psAddDeclarationList staged [equation]
  let batch : PsElabDeclarationBatchResult := {
    declarations := [declaration, equation]
    sourceInfo := [member.sourceInfo]
    diagnostics := psElabPreDefinitionUnusedHints member.source "not recursive" }
  return { batch, members := [batch] }

-- A returned function can contain the retained source match below its own
-- actual lambdas. Open those lambdas only to locate an original header major;
-- their temporary locals never become source parameters or proof context.
-- The caller still proves equality of the complete returned functions.
def psElabPreDefinitionEquationMajor (fuel : Nat) (context : PsElabContext)
    (headerIds : List Nat) (value : PsExpr) : Except PsElabError PsExpr := do
  match fuel with
  | 0 =>
    throw (psElabPreDefinitionError "WF-EQUATION" "retained result telescope exceeds the checked locator fuel")
  | fuel + 1 =>
    let sourceBody := psWhnf context.environment context.metaContext context.localContext value
    match sourceBody with
    | .lam _ domain body binder =>
      let type ← (psInferType context.environment context.metaContext context.localContext
        sourceBody).mapError (fun _ =>
          psElabPreDefinitionError "WF-EQUATION" "retained result lambda is not an actual typed Core function")
      let pi ← (psInferEnsureForall context.environment context.metaContext context.localContext
        type).mapError (fun _ =>
          psElabPreDefinitionError "WF-EQUATION" "retained result lambda has no actual Pi telescope")
      if !psBinderInfoEq binder pi.binder ||
          !psExprFVarsInContext context.localContext domain ||
          !psElabMutualStructuralEqual context domain pi.domain then
        throw (psElabPreDefinitionError "WF-EQUATION" "retained result lambda differs from its actual typed domain or binder kind")
      let pushed := psLocalPushBinding context.localContext pi.name pi.domain pi.binder
      psElabPreDefinitionEquationMajor fuel (psElabContextWithLocal context pushed.context)
        headerIds (psExprInstantiate1 body (.fvar pushed.id))
    | _ =>
      let some application := psEliminationRecursorApplication context.environment sourceBody
        | throw (psElabPreDefinitionError "WF-EQUATION" "exact equation transport requires a retained canonical recursor below actual result lambdas")
      let .fvar majorId := application.major
        | throw (psElabPreDefinitionError "WF-EQUATION" "retained recursor has no original local major")
      if !headerIds.contains majorId then
        throw (psElabPreDefinitionError "WF-EQUATION" "retained major is outside the original source header")
      return .fvar majorId

-- A source-owned measure/proof consumer may reconstruct the well-founded
-- term, but its result must still implement this exact retained Core member.
-- Rebuild the source equation independently after staging the real public
-- definition; callback metadata never authorizes another body or telescope.
def psElabPreDefinitionWellFounded (environment : PsEnvironment)
    (levels : List PsName) (member : PsElabPreDefinition)
    (consumer : PsElabPreDefinitionWellFoundedConsumer) :
    Except PsElabError PsElabPreDefinitionBatchResult := do
  let result ← consumer environment levels member
  let .definitionDecl name declarationLevels type value := result.declaration
    | throw (psElabPreDefinitionError "WF-IDENTITY" "well-founded consumer did not return an ordinary checked definition")
  let .theoremDecl equationName equationLevels equationType equationValue := result.equation
    | throw (psElabPreDefinitionError "WF-IDENTITY" "well-founded consumer did not return its checked source equation")
  let expectedEquationName := psNameAppendStr member.name "eq_def"
  let sameLevels := fun (actual : List PsName) => actual.length == levels.length &&
    (actual.zip levels).all (fun pair => psNameEq pair.fst pair.snd)
  let initial := psElabContextEmpty environment levels
  if !psNameEq name member.name || !psNameEq equationName expectedEquationName ||
      !psNameEq result.sourceInfo.owner member.name ||
      !sameLevels declarationLevels || !sameLevels equationLevels ||
      !psElabMutualStructuralEqual initial type member.type then
    throw (psElabPreDefinitionError "WF-IDENTITY" "well-founded result changed the actual member, header, or whole-block universe layout")
  for expression in [type, value, equationType, equationValue] do
    if psExprHasUnresolvedMeta expression || !psExprFVarsInContext psLocalEmpty expression then
      throw (psElabPreDefinitionError "WF-CLOSURE" "well-founded result retains a provisional peer or unresolved Core metavariable")
  for ownedName in [name, equationName] do
    if (psEnvironmentFind environment ownedName).isSome then
      throw (.duplicateDeclaration ownedName)
  let staged ← psAddDeclarationList environment [result.declaration]
  let stagedContext := psElabContextEmpty staged levels
  let self := PsExpr.constE member.name (levels.map PsLevel.param)
  let sourceValue := psElabSubstituteLocals [(member.peerId, self)] member.value
  if psExprHasUnresolvedMeta sourceValue || !psExprFVarsInContext psLocalEmpty sourceValue then
    throw (psElabPreDefinitionError "WF-CLOSURE" "retained source body still refers to an unclosed component peer")
  let _ ← psElabResolvedTerm stagedContext sourceValue (some member.type)
  let opened ← psElabPreDefinitionOpen (psElabPreDefinitionHeaderCount member)
    stagedContext member.type sourceValue
  let left ← psElabApplyCore opened.context self (psElabBinderArguments opened.bindersRev)
  let resultLevel ← psElabExpressionSort left.context opened.type
  let expectedEquation := psLogicEq resultLevel opened.type left.term opened.value
  let expectedType := psElabWellFoundedForalls opened.bindersRev.reverse
    expectedEquation
  if psExprHasUnresolvedMeta expectedType || !psExprFVarsInContext psLocalEmpty expectedType then
    throw (psElabPreDefinitionError "WF-EQUATION" "retained source equation did not close over its original header")
  let _ ← psElabResolvedTerm stagedContext equationValue (some equationType)
  let exactProof ← if psElabMutualStructuralEqual stagedContext equationType expectedType then
    pure equationValue
  else do
    -- A dependent callback can change the source match's reverted motive.
    -- Use the actual returned theorem VALUE and prove its RHS equals the
    -- retained RHS by checked cases; no temporary theorem enters the env.
    let actual ← (psElabApplyCore opened.context equationValue
      (psElabBinderArguments opened.bindersRev)).mapError (fun _ =>
        psElabPreDefinitionError "WF-EQUATION" "returned theorem does not accept the original source header")
    let actualEquation ← (psElabRecursorEquationView actual.context actual.type).mapError (fun _ =>
      psElabPreDefinitionError "WF-EQUATION" "returned theorem has no actual equality after the original header")
    if !psLevelEquivalent actualEquation.level resultLevel ||
        !psElabMutualStructuralEqual actual.context actualEquation.type opened.type ||
        !psElabMutualStructuralEqual actual.context actualEquation.left left.term then
      throw (psElabPreDefinitionError "WF-EQUATION" "returned theorem changed the source result type or actual public left side")
    let major ← psElabPreDefinitionEquationMajor 4096 actual.context
      (opened.bindersRev.map (·.id)) opened.value
    let transportType := psLogicEq resultLevel opened.type actualEquation.right opened.value
    let transport ← (psElabRecursorEquationProof actual.context major
      transportType (psElabPreDefinitionSourceSpan member)).mapError (fun _ =>
        psElabPreDefinitionError "WF-EQUATION" "checked constructor cases do not prove the actual RHS equals the retained source RHS")
    let proof := psExprApplyMany (.constE (psNameAppendStr psEqName "trans") [resultLevel])
      [opened.type, left.term, actualEquation.right, opened.value, actual.term, transport]
    let checked ← (psElabResolvedTerm actual.context proof (some expectedEquation)).mapError (fun _ =>
      psElabPreDefinitionError "WF-EQUATION" "checked RHS transport does not compose to the exact retained equation")
    let closed := psCloseElabTypedBinders checked.context.metaContext opened.bindersRev
      checked.term expectedEquation
    if !psExprAlphaEq closed.snd expectedType then
      throw (psElabPreDefinitionError "WF-EQUATION" "case transport changed the exact original-header equation")
    pure closed.fst
  if psExprHasUnresolvedMeta exactProof || !psExprFVarsInContext psLocalEmpty exactProof then
    throw (psElabPreDefinitionError "WF-CLOSURE" "exact source-equation proof retained a provisional local or metavariable")
  let checkedProof ← psElabResolvedTerm stagedContext exactProof (some expectedType)
  let equation := PsDeclaration.theoremDecl equationName levels expectedType checkedProof.term
  let _ ← psAddDeclarationList staged [equation]
  let batch : PsElabDeclarationBatchResult := {
    declarations := [result.declaration, equation]
    sourceInfo := [member.sourceInfo] }
  return { batch, members := [batch] }

def psElabPreDefinitionDispatch (environment : PsEnvironment) (levels : List PsName)
    (nextId : Nat) (members : List PsElabPreDefinition) (nonrecursive : Bool)
    (wellFounded : Option PsElabPreDefinitionWellFoundedConsumer) :
    Except PsElabError PsElabPreDefinitionBatchResult := do
  if nonrecursive then
    let [member] := members
      | throw (psElabPreDefinitionError "OWNERSHIP" "nonrecursive component has multiple members")
    -- v7.2 explicitly requires source `partial` to remain opaque. Every other
    -- genuine nonrecursive component follows pinned Main before unused hints
    -- are considered; those hints do not invoke a WF or P1 construction.
    if !psElabPreDefinitionExplicitPartial member then
      return ← psElabPreDefinitionNonrecursive environment levels member
  if members.any (fun member => psElabPreDefinitionStrategyEq member.strategy .fixedpoint) then
    return ← psElabFixedpointFromChecked environment levels nextId members
  if members.any (fun member => psElabPreDefinitionStrategyEq member.strategy .wellFounded) then
    let [member] := members
      | throw (.data "PSCV0-MUTUAL-WF: a recursive component with a well-founded suffix requires one independently checked measured member; mixed partial or multiple-member well-founded cliques are unavailable")
    if !psElabPreDefinitionStrategyEq member.strategy .wellFounded then
      throw (.data "PSCV0-MUTUAL-WF: well-founded strategy does not own the complete component")
    let some consumer := wellFounded
      | throw (psElabPreDefinitionError "WF" "checked local well-founded bodies require the separate measure-and-proof consumer; this SCC is not structural evidence")
    return ← psElabPreDefinitionWellFounded environment levels member consumer
  -- Original main modifiers have already passed the native whole-block
  -- compatibility gate. Pinned Main then chooses partial for this recursive
  -- component, including inherited local helpers. Every resulting member has
  -- its own independently inhabited logical identity and actual body marker.
  if members.any (fun member => psElabPreDefinitionStrategyEq member.strategy .partial) then
    let result ← psElabPartialMutualFromChecked environment levels members
    if result.members.length != members.length then
      throw (psElabPreDefinitionError "OWNERSHIP" "partial consumer changed component member ownership")
    let checkedMembers := (members.zip result.members).map fun (member, batch) =>
      { batch with diagnostics := batch.diagnostics ++
          psElabPreDefinitionUnusedHints member.source "partial" }
    return {
      batch := { result.batch with diagnostics := checkedMembers.flatMap (·.diagnostics) }
      members := checkedMembers
    }
  if members.all (fun member => psElabPreDefinitionStrategyEq member.strategy .total) then
    return ← psElabPreDefinitionStructural environment levels nextId members
  throw (psElabPreDefinitionError "STRATEGY" "recursive component mixes incompatible checked logical strategies")

structure PsElabPreDefinitionStaging where
  environment : PsEnvironment
  declarations : List PsDeclaration
  completed : List Nat
  members : List (Nat × PsElabDeclarationBatchResult)

-- Dependencies are emitted first, while the result map retains the original
-- source member order. A later failure returns no staging value to the caller.
-- Each substitution targets an actual checked predecessor constant with the
-- unchanged whole-block universe arguments.
def psElabPreDefinitionComponents (fuel : Nat) (levels : List PsName) (nextId : Nat)
    (allMembers : List PsElabPreDefinition) (graph : PsElabPreDefinitionGraph)
    (remaining : List PsElabPreDefinition) (state : PsElabPreDefinitionStaging)
    (wellFounded : Option PsElabPreDefinitionWellFoundedConsumer) :
    Except PsElabError PsElabPreDefinitionStaging := do
  if remaining.isEmpty then return state
  match fuel with
  | 0 => throw (psElabPreDefinitionError "GRAPH" "dependency partition did not consume an owned component")
  | fuel + 1 =>
    let some seed := remaining.find? (fun candidate =>
        let ids := psElabPreDefinitionComponent graph candidate.peerId
        !ids.isEmpty && graph.all (fun edge =>
          !ids.contains edge.fst || edge.snd.all (fun dependency =>
            ids.contains dependency || state.completed.contains dependency)))
      | throw (psElabPreDefinitionError "GRAPH" "no complete component is ready after checked dependencies")
    let ids := psElabPreDefinitionComponent graph seed.peerId
    let owned := remaining.filter (fun member => ids.contains member.peerId)
    if owned.length != ids.length then
      throw (psElabPreDefinitionError "GRAPH" "component reuses a completed or missing member")
    let replacements := (allMembers.filter (fun member => state.completed.contains member.peerId)).map
      fun member => (member.peerId, PsExpr.constE member.name (levels.map PsLevel.param))
    let members := owned.map fun member =>
      { member with value := psElabSubstituteLocals replacements member.value }
    let nonrecursive := ids.length == 1 &&
      !((graph.find? (fun edge => edge.fst == seed.peerId)).map (·.snd) |>.getD []).contains seed.peerId
    let result ← psElabPreDefinitionDispatch state.environment levels nextId members nonrecursive wellFounded
    if result.members.length != members.length then
      throw (psElabPreDefinitionError "OWNERSHIP" "consumer changed component member ownership")
    let environment ← psAddDeclarationList state.environment result.batch.declarations
    let next : PsElabPreDefinitionStaging := {
      environment
      declarations := state.declarations ++ result.batch.declarations
      completed := state.completed ++ ids
      members := state.members ++ (owned.zip result.members).map (fun (member, result) => (member.peerId, result)) }
    psElabPreDefinitionComponents fuel levels nextId allMembers graph
      (remaining.filter (fun member => !ids.contains member.peerId)) next wellFounded

def psElabPreDefinitionBatch (environment : PsEnvironment)
    (block : PsElabPreDefinitionBlock)
    (wellFounded : Option PsElabPreDefinitionWellFoundedConsumer := none) :
    Except PsElabError PsElabPreDefinitionBatchResult := do
  let context ← psElabPreDefinitionValidate environment block
  let graph := psElabPreDefinitionGraphFor block.members
  let staged ← psElabPreDefinitionComponents block.members.length block.levelNames
    context.localContext.nextId block.members graph block.members {
      environment
      declarations := []
      completed := []
      members := [] } wellFounded
  let members ← block.members.mapM fun member => do
    let some result := staged.members.find? (fun result => result.fst == member.peerId)
      | throw (psElabPreDefinitionError "OWNERSHIP" "final batch lost a source member")
    return result.snd
  return {
    batch := {
      declarations := staged.declarations
      sourceInfo := members.flatMap (·.sourceInfo)
      diagnostics := members.flatMap (·.diagnostics) }
    members }

