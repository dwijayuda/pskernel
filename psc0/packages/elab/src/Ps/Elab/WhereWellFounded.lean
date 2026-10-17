import Ps.Elab.Where
import Ps.Elab.WellFounded

-- Lifted local WF bodies reuse the existing branch-aware source algorithm.
-- Rewriting calls under an already elaborated match would leave decreasing
-- goals referring to its old major; the source sidecar retains the exact
-- typed header needed to elaborate under the real dependent callback.
def psElabWhereTermination (source : PsElabPreDefinitionSource) :
    Except PsElabError PsSyntaxTermination := do
  match source with
  | .declaration source =>
    let (source, _, _) ← psWhereSourceParts source
    let .wellFoundedDefinition _ _ _ _ termination _ := source
      | throw (psElabWhereError "WF-SOURCE" "the selected member has no source-owned termination clause")
    return termination
  | .localDefinition _ source =>
    let some (.total termination) := source.recursion
      | throw (psElabWhereError "WF-SOURCE" "the selected helper has no source-owned termination clause")
    return termination

def psElabWhereParentName (header : PsElabWhereHeader) : PsName :=
  match header.source with
  | .declaration _ => header.name
  | .localDefinition parent _ => parent

def psElabWhereWellFounded (prepared : PsElabWherePrepared)
    (environment : PsEnvironment) (levelNames : List PsName)
    (member : PsElabPreDefinition) : Except PsElabError PsElabWellFoundedResult := do
  let some original := prepared.block.members.find? (fun original =>
      psNameEq original.name member.name && original.peerId == member.peerId)
    | throw (psElabWhereError "WF-IDENTITY" "the measured component is not owned by this typed source block")
  let some input := prepared.inputs.find? (fun input => psNameEq input.header.name member.name)
    | throw (psElabWhereError "WF-IDENTITY" "the measured component lost its original typed source header")
  let parametersRev := input.header.bindersRev
  let capturesRev := input.captures.reverse.map (·.binder)
  let fullType := psCloseElabForallBinders psMetaEmpty (parametersRev ++ capturesRev) input.openType
  if member.sourceHeaderCount != parametersRev.length ||
      !psExprAlphaEq original.type member.type || !psExprAlphaEq fullType member.type ||
      member.captures.length != input.captures.length ||
      !(member.captures.zip input.captures).all (fun (actual, source) =>
        psElabPreDefinitionCaptureEq actual source.origin) ||
      levelNames.length != prepared.block.levelNames.length ||
      !(levelNames.zip prepared.block.levelNames).all (fun (left, right) => psNameEq left right) then
    throw (psElabWhereError "WF-IDENTITY" "the source adapter changed the checked captures, original header or block universes")
  let ids := (parametersRev ++ capturesRev).map (·.id)
  let nextId := max prepared.context.localContext.nextId prepared.block.context.localContext.nextId
  let context := { psElabContextEmpty environment levelNames with
    localContext := { nextId, declarations := (parametersRev ++ capturesRev).map psElabWhereBinderDeclaration }
    -- Keep the original globally fresh meta/level counters. Generalized
    -- header levels must not collide with fresh measure/proof universes.
    metaContext := prepared.context.metaContext
    sourceSpan := some input.header.sourceSpan }
  let _ ← psElabResolvedTerm context input.openType none
  let parent := psElabWhereParentName input.header
  let helpers := prepared.inputs.filter fun candidate =>
    match candidate.header.source with
    | .localDefinition owner _ => psNameEq owner parent
    | .declaration _ => false
  let helperNames := helpers.filterMap fun helper =>
    match helper.header.source with
    | .localDefinition _ source => source.name.segments.head?
    | .declaration _ => none
  -- A local helper shadows an enclosing captured name in its body. Rename
  -- only those captured lookup names; their actual typed IDs remain intact.
  -- Its own declared parameters still shadow the helper frame normally.
  let renames := input.captures.filterMap fun capture =>
    let shortName := psNameLastComponent capture.binder.name
    if helperNames.contains shortName then
      some (capture.binder.id, shortName,
        psNameAppendStr (psRootName "$psc0WhereCapture") (psNatToString capture.binder.id))
    else none
  let declarations := context.localContext.declarations.map fun declaration =>
    match declaration with
    | .binding id name type binder =>
      match renames.find? (fun entry => entry.fst == id) with
      | some (_, _, hidden) => .binding id hidden type binder
      | none => .binding id name type binder
    | declaration => declaration
  let bodyContext := { context with localContext := { context.localContext with declarations } }
  let bodyContext ← prepared.inputs.foldlM (fun current candidate => do
    if psNameEq candidate.header.name member.name ||
        (psEnvironmentFind environment candidate.header.name).isNone then return current
    if !(psElabWhereCaptureIds candidate.captures).all ids.contains then return current
    let value := psExprApplyMany (.constE candidate.header.name (levelNames.map PsLevel.param))
      (candidate.captures.map (fun capture => .fvar capture.binder.id))
    let checked ← psElabResolvedTerm context value (some candidate.sourceType)
    let alias := psLocalPushLet current.localContext candidate.header.alias checked.type value
    let current := { current with localContext := alias.context }
    match candidate.header.source with
    | .declaration _ => return current
    | .localDefinition owner source =>
      if !psNameEq owner parent then return current
      let some name := psSyntaxNameToName source.name | throw .emptyName
      let visible := psLocalPushLet current.localContext name checked.type value
      return { current with localContext := visible.context }) bodyContext
  let bodyLocalContext : PsLocalContext ← match input.header.source with
    | .declaration _ => pure bodyContext.localContext
    | .localDefinition _ _ => do
      let ownIds := parametersRev.map (·.id)
      for declaration in bodyContext.localContext.declarations do
        if let .letDecl _ _ type value := declaration then
          if (psExprFVarIds type ++ psExprFVarIds value).any ownIds.contains then
            throw (psElabWhereError "WF-CAPTURE" "a sibling alias depends on this helper's own parameter instead of its actual enclosing captures")
      pure { bodyContext.localContext with
        declarations := bodyContext.localContext.declarations.filter (fun declaration => ownIds.contains (psLocalDeclId declaration)) ++
          bodyContext.localContext.declarations.filter (fun declaration => !ownIds.contains (psLocalDeclId declaration)) }
  let termination ← psElabWhereTermination input.header.source
  -- The decreasing clause belongs to the original header, before helpers
  -- enter. Restore its captured lookup names through the exact renamed IDs.
  let proofAliases := renames.map fun (_, shortName, hidden) =>
    (shortName, (psNameToString hidden).splitOn ".")
  let decreasing := termination.decreasing.map fun source =>
    match source with
    | .byE tactics scope span => .byE tactics
        { scope with localAliases := proofAliases ++ scope.localAliases } span
    | source => source
  let termination := { termination with decreasing }
  psElabWellFoundedTypedParts psElabTerm member.name {
    context
    parametersRev
    capturesRev
    resultType := input.openType
    functionName := input.header.alias
    bodyLocalContext := some bodyLocalContext
    preserveLevels := true } input.header.sourceBody termination
