import Ps.Elab.WhereScope
import Ps.Elab.Term
import Ps.Elab.PreDefinition.Basic

-- Flat where declarations enter before body lambdas. Only the enclosing
-- section and declared parent parameters can be captured by a helper.
-- This is the selected part of Lean 4.35 LetRec/MutualDef closure conversion;
-- no temporary global declaration is introduced during header or body work.
structure PsElabWhereCapture where
  origin : PsElabPreDefinitionCapture
  binder : PsElabTypedBinder

structure PsElabWhereHeader where
  name : PsName
  alias : PsName
  source : PsElabPreDefinitionSource
  sourceIndex : Nat
  sourceSpan : PsSourceSpan
  isPrivate : Bool
  registration : Option PsSyntaxRegistration
  strategy : PsElabPreDefinitionStrategy
  ambient : List PsElabWhereCapture
  bindersRev : List PsElabTypedBinder
  context : PsElabContext
  openType : PsExpr
  sourceType : PsExpr
  sourceBody : PsSyntaxTerm
  inferredResult : Bool
  peerId : Nat := 0
  terminationScope : Option PsWhereTerminationScope := none

structure PsElabWhereBody where
  header : PsElabWhereHeader
  value : PsExpr
  -- These are actual typed let aliases used only to preserve lexical helper
  -- shadowing in delayed proof scopes. They disappear before capture closure.
  aliases : List (Nat × PsExpr)

structure PsElabWhereClosedInput where
  header : PsElabWhereHeader
  value : PsExpr
  openType : PsExpr
  sourceType : PsExpr
  sourceValue : PsExpr
  captures : List PsElabWhereCapture

-- Checked source sidecar for strategy consumers that must elaborate branch
-- goals with a new dependent callback. The independent dispatcher continues
-- to own final equality with block.members' retained checked Core bodies.
structure PsElabWherePrepared where
  block : PsElabPreDefinitionBlock
  inputs : List PsElabWhereClosedInput
  context : PsElabContext

def psElabWhereError (part message : String) : PsElabError :=
  .data ("PSCV0-WHERE-" ++ part ++ ": " ++ message)

def psElabWhereStrategy (source : PsSyntaxDeclaration) :
    Except PsElabError PsElabPreDefinitionStrategy := do
  let (source, _, _) ← psWhereSourceParts source
  match source with
  | .definition .. | .noncomputableDefinition .. => return .total
  | .partialDefinition .. => return .partial
  | .wellFoundedDefinition .. => return .wellFounded
  | .fixedpointDefinition .. => return .fixedpoint
  | _ => throw (psElabWhereError "HEAD" "where requires a selected value declaration")

def psElabWhereLocalStrategy (mainSources : List PsElabPreDefinitionSource)
    (source : PsSyntaxLocalDefinition) : Except PsElabError PsElabPreDefinitionStrategy :=
  psElabPreDefinitionLocalStrategy mainSources source

def psElabWhereBinderDeclaration (binder : PsElabTypedBinder) : PsLocalDecl :=
  .binding binder.id binder.name binder.type binder.binder

def psElabWhereEnter (shared lexical : PsElabContext) : PsElabContext :=
  psElabRestoreScope shared (psElabSaveScope lexical)

-- An omitted codomain is a natural family over its own declared binders.
-- The family lives in the enclosing scope, so peers substitute their arguments
-- without retaining the original free IDs. Parameter types and defaults must
-- resolve before the family or peer headers enter.
def psElabWhereTypedHeader (context : PsElabContext)
    (binders : List PsScopeBinder) (annotation : Option PsSyntaxTerm)
    (allowExplicitHole : Bool := true) :
    Except PsElabError (PsElabContext × List PsElabTypedBinder × PsExpr × PsExpr × Bool) := do
  let inferred := match annotation with
    | none | some (.omittedType _) => true
    | some (.hole _) => allowExplicitHole
    | _ => false
  let parameters ← psElabTypedBinders psElabTerm context binders
  let annotationResult ← if inferred then pure none else do
    let some source := annotation
      | throw (psElabWhereError "HEADER" "missing codomain inference owner")
    pure (some (← psElabType psElabTerm parameters.context source))
  let headerContext := annotationResult.map (·.context) |>.getD parameters.context
  let bindersRev := parameters.bindersRev.map fun binder =>
    { binder with type := psMetaInstantiate headerContext.metaContext binder.type }
  if bindersRev.any (fun binder => psExprHasTermMeta binder.type) then
    throw (psElabWhereError "HEADER" "local parameter types and defaults must be resolved before peer headers enter")
  let result ← match annotationResult with
    | some result => pure result
    | none => do
      let level := psMetaFreshLevel headerContext.metaContext
      let familyType := psCloseElabForallBinders level.context bindersRev (.sortE level.level)
      let _ ← (psInferType context.environment level.context context.localContext familyType).mapError
        PsElabError.infer
      let fresh := psMetaFresh level.context context.localContext familyType
        .natural {} bindersRev.length
      pure ({
        context := psElabContextWithMeta headerContext fresh.context
        type := psExprApplyMany fresh.expr (psElabBinderArguments bindersRev)
      } : PsElabTypeResult)
  let metaContext := result.context.metaContext
  let openType := psMetaInstantiate metaContext result.type
  if !inferred && psExprHasTermMeta openType then
    throw (psElabWhereError "HEADER" "an explicit result annotation contains unresolved terms")
  let sourceType := psCloseElabForallBinders metaContext bindersRev openType
  let _ ← (psInferType context.environment metaContext context.localContext sourceType).mapError PsElabError.infer
  return (result.context, bindersRev, openType, sourceType, inferred)

def psElabWhereMainHeader (context : PsElabContext)
    (ambient : List PsElabWhereCapture) (member : PsScopedPreDefinition) (sourceIndex : Nat) :
    Except PsElabError PsElabWhereHeader := do
  let (base, _, _) ← psWhereSourceParts member.source
  let (sourceName, binders, type, value) ← psWhereValueParts base
  let some name := psSyntaxNameToName sourceName | throw .emptyName
  let some alias := psSyntaxNameToName member.alias | throw .emptyName
  let (context, bindersRev, openType, sourceType, inferredResult) ←
    -- Native MutualDef closes explicit main headers before body elaboration;
    -- native LetRec deliberately permits body inference for local `: _`.
    (psElabWhereTypedHeader context binders (some type) false).mapError (.atDeclaration name)
  return {
    name, alias, sourceIndex, context, ambient, bindersRev, openType, sourceType, inferredResult
    source := .declaration member.source
    sourceSpan := psSyntaxSpanJoin sourceName.span (psSyntaxTermSpan value)
    isPrivate := member.isPrivate
    registration := member.registration
    strategy := ← psElabWhereStrategy member.source
    sourceBody := value
    terminationScope := member.terminationScope }

def psElabWhereHelperHeader (context : PsElabContext)
    (mainSources : List PsElabPreDefinitionSource) (parent : PsElabWhereHeader)
    (localDefinition : PsScopedLocalDefinition) :
    Except PsElabError PsElabWhereHeader := do
  let some alias := psSyntaxNameToName localDefinition.alias | throw .emptyName
  let source := localDefinition.source
  let (context, bindersRev, openType, sourceType, inferredResult) ←
    (psElabWhereTypedHeader context source.binders source.type).mapError (.atDeclaration localDefinition.name)
  let ownCaptures := parent.bindersRev.reverse.map fun binder =>
    ({ origin := { owner := some parent.name, id := binder.id }, binder } : PsElabWhereCapture)
  return {
    name := localDefinition.name
    alias, context, bindersRev, openType, sourceType, inferredResult
    source := .localDefinition parent.name source
    sourceIndex := parent.sourceIndex
    sourceSpan := source.span
    isPrivate := parent.isPrivate
    registration := none
    strategy := ← psElabWhereLocalStrategy mainSources source
    ambient := parent.ambient ++ ownCaptures
    sourceBody := source.value
    terminationScope := localDefinition.terminationScope }

def psElabWherePeers (context : PsElabContext) (headers : List PsElabWhereHeader) :
    Except PsElabError (PsElabContext × List PsElabWhereHeader) := do
  headers.foldlM (fun (state : PsElabContext × List PsElabWhereHeader) header => do
    if (psLocalFindUser state.fst.localContext header.alias).isSome then
      throw (psElabWhereError "IDENTITY" "a hygienic peer alias is shadowed")
    let type := psMetaInstantiate state.fst.metaContext header.sourceType
    let _ ← (psInferType state.fst.environment state.fst.metaContext state.fst.localContext type).mapError
      PsElabError.infer
    let pushed := psLocalPushBinding state.fst.localContext header.alias type .explicit
    return (psElabContextWithLocal state.fst pushed.context,
      state.snd ++ [{ header with peerId := pushed.id }] )) (context, [])

def psElabWhereLexicalAliases (context : PsElabContext) (helpers : List PsElabWhereHeader) :
    Except PsElabError (PsElabContext × List (Nat × PsExpr)) := do
  helpers.foldlM (fun (state : PsElabContext × List (Nat × PsExpr)) helper => do
    let .localDefinition _ source := helper.source
      | throw (psElabWhereError "IDENTITY" "a helper alias has no local source owner")
    let some name := psSyntaxNameToName source.name | throw .emptyName
    let type := psMetaInstantiate state.fst.metaContext helper.sourceType
    let value := PsExpr.fvar helper.peerId
    let pushed := psLocalPushLet state.fst.localContext name type value
    return (psElabContextWithLocal state.fst pushed.context, state.snd ++ [(pushed.id, value)]))
    (context, [])

def psElabWhereReadBody (shared lexical : PsElabContext) (header : PsElabWhereHeader)
    (aliases : List (Nat × PsExpr)) : Except PsElabError (PsElabContext × PsElabWhereBody) := do
  let context := { psElabWhereEnter shared lexical with postponing := true }
  let expected := psMetaInstantiate context.metaContext header.openType
  let result ← (psElabTermWithFuel 4096 context header.sourceBody (some expected)).mapError
    (.atDeclaration header.name)
  return (psElabLeaveScope shared result.context, { header, value := result.term, aliases })

-- All local headers enter together, then every body shares current inference
-- assignments while retaining its own actual lexical scope. A helper's own
-- binders shadow the local-helper frame; that frame shadows parent parameters.
def psElabWhereParentBodies (shared : PsElabContext) (mainPeers : List PsLocalDecl)
    (mainSources : List PsElabPreDefinitionSource) (parent : PsElabWhereHeader)
    (locals : List PsScopedLocalDefinition) :
    Except PsElabError (PsElabContext × List PsElabWhereBody) := do
  let parentScope := { parent.context with
    localContext := { parent.context.localContext with
      declarations := mainPeers ++ parent.context.localContext.declarations } }
  let parentContext := psElabWhereEnter shared parentScope
  let (headerContext, helpers) ← locals.foldlM
    (fun (state : PsElabContext × List PsElabWhereHeader) localDefinition => do
      let helper ← psElabWhereHelperHeader state.fst mainSources parent localDefinition
      return (psElabLeaveScope state.fst helper.context, state.snd ++ [helper]))
    (parentContext, ([] : List PsElabWhereHeader))
  let (peerContext, helpers) ← psElabWherePeers headerContext helpers
  let (bodyContext, aliases) ← psElabWhereLexicalAliases peerContext helpers
  let (bodyState, bodies) ← helpers.foldlM
    (fun (state : PsElabContext × List PsElabWhereBody) helper => do
      let lexical := { bodyContext with
        localContext := { bodyContext.localContext with
          declarations := helper.bindersRev.map psElabWhereBinderDeclaration ++
            bodyContext.localContext.declarations } }
      let (next, body) ← psElabWhereReadBody state.fst lexical helper aliases
      return (next, state.snd ++ [body]))
    (bodyContext, ([] : List PsElabWhereBody))
  let (final, body) ← psElabWhereReadBody bodyState bodyContext parent aliases
  return (psElabLeaveScope shared final, body :: bodies)

def psElabWhereGeneralizeBinder (metaContext : PsMetaContext) (binder : PsElabTypedBinder) :
    PsElabTypedBinder :=
  { binder with type := psElabGeneralizeExpr (psMetaInstantiate metaContext binder.type) }

def psElabWhereInput (metaContext : PsMetaContext) (body : PsElabWhereBody) :
    Except PsElabError PsElabWhereClosedInput := do
  let value := psElabSubstituteLocals body.aliases (psMetaInstantiate metaContext body.value)
  let openType := psWhnfCore metaContext
    body.header.context.localContext body.header.openType
  let bindersRev := body.header.bindersRev.map (psElabWhereGeneralizeBinder metaContext)
  let ambient := body.header.ambient.map fun capture =>
    { capture with binder := psElabWhereGeneralizeBinder metaContext capture.binder }
  if psExprHasTermMeta value || psExprHasTermMeta openType then
    throw (psElabWhereError "INFER-TYPE"
      "a body or inferred result remains unresolved")
  let value := psElabGeneralizeExpr value
  let openType := psElabGeneralizeExpr openType
  let sourceValue := psCloseElabLambdaBinders psMetaEmpty bindersRev value
  let sourceType := psCloseElabForallBinders psMetaEmpty bindersRev openType
  let ids := psExprFVarIds sourceType ++ psExprFVarIds sourceValue
  let captures := ambient.filter (fun capture => ids.contains capture.binder.id)
  return {
    header := { body.header with bindersRev, ambient, openType, sourceType }
    value, openType, sourceType, sourceValue, captures }

def psElabWhereCaptureIds (captures : List PsElabWhereCapture) : List Nat :=
  captures.map (·.binder.id)

-- A capture needed by a peer becomes a capture of the caller only when it is
-- outside the caller's own header. The actual available IDs, not printed
-- binder names, distinguish these cases. Type dependencies close as well.
def psElabWhereCaptureStep (sectionIds : List Nat)
    (inputs : List PsElabWhereClosedInput) : Except PsElabError (List PsElabWhereClosedInput) := do
  let common := (inputs.flatMap fun input => psElabWhereCaptureIds input.captures).filter sectionIds.contains
  inputs.mapM fun input => do
    let ownIds := input.header.bindersRev.map (·.id)
    let ambientIds := psElabWhereCaptureIds input.header.ambient
    let peerIds := (psExprFVarIds input.sourceType ++ psExprFVarIds input.sourceValue).eraseDups
    let peers := inputs.filter (fun peer => peerIds.contains peer.header.peerId)
    let needed := peers.flatMap fun peer => psElabWhereCaptureIds peer.captures
    if !needed.all (fun id => ambientIds.contains id || ownIds.contains id) then
      throw (psElabWhereError "CAPTURE" "a referenced helper requires a local outside the enclosing declared header")
    let inherited := match input.header.source with
      | .declaration _ => common
      | .localDefinition _ _ => []
    let dependencies := input.captures.flatMap (fun capture => psExprFVarIds capture.binder.type)
    let selected := psElabWhereCaptureIds input.captures ++ needed ++ inherited ++ dependencies
    let captures := input.header.ambient.filter (fun capture => selected.contains capture.binder.id)
    return { input with captures }

def psElabWhereCloseCaptures (fuel : Nat) (sectionIds : List Nat)
    (inputs : List PsElabWhereClosedInput) : Except PsElabError (List PsElabWhereClosedInput) := do
  match fuel with
  | 0 => throw (psElabWhereError "CAPTURE" "typed capture closure exhausted")
  | fuel + 1 =>
    let next ← psElabWhereCaptureStep sectionIds inputs
    if (inputs.zip next).all (fun (left, right) =>
        psElabWhereCaptureIds left.captures == psElabWhereCaptureIds right.captures) then
      return next
    psElabWhereCloseCaptures fuel sectionIds next

def psElabWhereInfoSpan (info : PsElabInfo) : Option PsSourceSpan :=
  match info with
  | .reference name _ _ _ _ => some name.span
  | .binderGroup head _ _ => some head.span
  | .instanceSelection span _ _ | .insertedArgument span _ _ _ _ _ => span

def psElabWhereSourceInfo (context : PsElabContext) (header : PsElabWhereHeader) : PsElabSourceInfo :=
  { owner := header.name, metaContext := context.metaContext
    entries := context.infoRev.reverse.filter fun entry =>
      match psElabWhereInfoSpan entry.info with
      | none => false
      | some span => header.sourceSpan.start.byteOffset <= span.start.byteOffset &&
          span.stop.byteOffset <= header.sourceSpan.stop.byteOffset }

-- Final types are closed before full peer locals enter. Replacing a source
-- peer with its full typed application happens in the original open header,
-- then captures and source binders are closed once in their true order.
def psElabWhereLift (shared : PsElabContext) (availableLevels : List PsName)
    (inputs : List PsElabWhereClosedInput) (span : PsSourceSpan) :
    Except PsElabError PsElabPreDefinitionBlock := do
  let sourcePeerIds := inputs.map (·.header.peerId)
  for input in inputs do
    if (psExprFVarIds input.sourceType).any sourcePeerIds.contains then
      throw (psElabWhereError "TYPE-DEPENDENCY" "a function header may not depend on any simultaneously defined function")
    let available := psElabWhereCaptureIds input.header.ambient ++ sourcePeerIds
    if !(psExprFVarIds input.sourceType ++ psExprFVarIds input.sourceValue).all available.contains then
      throw (psElabWhereError "CAPTURE" "a checked body retains an unowned local after its declared header closes")
  let types := inputs.map fun input =>
    psCloseElabForallBinders psMetaEmpty (input.captures.reverse.map (·.binder)) input.sourceType
  for type in types do
    if psExprHasUnresolvedMeta type || !psExprFVarsInContext psLocalEmpty type then
      throw (psElabWhereError "HEADER" "a lifted full peer type is not closed")
  let initial := { psElabContextEmpty shared.environment availableLevels with
    localContext := { psLocalEmpty with nextId := shared.localContext.nextId } }
  let (context, fullPeers) ← (inputs.zip types).foldlM
    (fun (state : PsElabContext × List Nat) (input, type) => do
      let sort ← (psInferType state.fst.environment psMetaEmpty psLocalEmpty type).mapError PsElabError.infer
      let _ ← (psInferEnsureSort state.fst.environment psMetaEmpty psLocalEmpty sort).mapError PsElabError.infer
      let pushed := psLocalPushBinding state.fst.localContext input.header.alias type .explicit
      return (psElabContextWithLocal state.fst pushed.context, state.snd ++ [pushed.id]))
    (initial, ([] : List Nat))
  let replacements := (inputs.zip fullPeers).map fun (input, id) =>
    (input.header.peerId, psExprApplyMany (.fvar id)
      (input.captures.map (fun capture => .fvar capture.binder.id)))
  let members ← ((inputs.zip types).zip fullPeers).mapM fun ((input, type), id) => do
    let body := psElabSubstituteLocals replacements input.value
    let parameters := input.header.bindersRev ++ input.captures.reverse.map (·.binder)
    let value := psCloseElabLambdaBinders psMetaEmpty parameters body
    if psExprHasUnresolvedMeta value || !psExprFVarsInContext context.localContext value then
      throw (psElabWhereError "CAPTURE" "a lifted implementation retains an uncaptured source local")
    let checked ← (psElabResolvedTerm context value (some type)).mapError (.atDeclaration input.header.name)
    return ({
      name := input.header.name
      peerId := id
      type
      value := checked.term
      captures := input.captures.map (·.origin)
      sourceHeaderCount := input.header.bindersRev.length
      strategy := input.header.strategy
      source := input.header.source
      sourceIndex := input.header.sourceIndex
      isPrivate := input.header.isPrivate
      registration := input.header.registration
      sourceInfo := psElabWhereSourceInfo shared input.header } : PsElabPreDefinition)
  let levelNames := psElabDeclarationLevels availableLevels
    (members.flatMap fun member => [member.type, member.value])
  return { context := { context with levelNames }, levelNames, members, span }

def psElabPreparePreDefinitionsWithSource (environment : PsEnvironment) (levelNames : List PsName)
    (capturedSyntax : List PsScopeBinder) (members : List PsScopedPreDefinition)
    (span : PsSourceSpan) : Except PsElabError PsElabWherePrepared := do
  if members.isEmpty then throw (psElabWhereError "EMPTY" "a typed source block must contain a declaration")
  psElabPreDefinitionCheckMainModifiers (members.map (fun member => .declaration member.source))
  let captured ← psElabTypedBinders psElabTerm (psElabContextEmpty environment levelNames) capturedSyntax
  let ambient := captured.bindersRev.reverse.map fun binder =>
    ({ origin := { owner := none, id := binder.id }, binder } : PsElabWhereCapture)
  let (headersContext, headers) ← members.zipIdx.foldlM
    (fun (state : PsElabContext × List PsElabWhereHeader) (member, index) => do
      let header ← psElabWhereMainHeader state.fst ambient member index
      return (psElabLeaveScope state.fst header.context, state.snd ++ [header]))
    (captured.context, ([] : List PsElabWhereHeader))
  let (peerContext, headers) ← psElabWherePeers headersContext headers
  let mainPeers := peerContext.localContext.declarations.take headers.length
  -- All original main modifiers agree. Pinned getModifiersForLetRecs now
  -- supplies their shared operational intent to plain local helper headers.
  let mainSources := headers.map (·.source)
  let (bodyContext, bodies) ← (headers.zip members).foldlM
    (fun (state : PsElabContext × List PsElabWhereBody) (header, member) => do
      let (context, bodies) ← psElabWhereParentBodies state.fst mainPeers mainSources header member.locals
      return (context, state.snd ++ bodies))
    (peerContext, ([] : List PsElabWhereBody))
  -- This real Sort result gives the shared work queue a harmless root. The
  -- queue resumes each job in its own saved scope and final shared meta state.
  let root ← psElabResolvedTerm bodyContext (.sortE .zero) none
  let solved ← psElabDrainPending (psElabTermWithFuel 4096) root
  let inputs ← bodies.mapM (psElabWhereInput solved.context.metaContext)
  let sectionIds := ambient.map (·.binder.id)
  let inputs ← psElabWhereCloseCaptures
    (1 + inputs.length * (1 + (inputs.flatMap (·.header.ambient)).length)) sectionIds inputs
  let block ← psElabWhereLift solved.context levelNames inputs span
  return { block, inputs, context := solved.context }

def psElabPreparePreDefinitions (environment : PsEnvironment) (levelNames : List PsName)
    (capturedSyntax : List PsScopeBinder) (members : List PsScopedPreDefinition)
    (span : PsSourceSpan) : Except PsElabError PsElabPreDefinitionBlock := do
  return (← psElabPreparePreDefinitionsWithSource environment levelNames capturedSyntax members span).block
