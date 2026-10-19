import Ps.Elab.Scope
import Ps.Elab.Declaration
import Ps.Elab.PreDefinition.Basic

-- Pinned Lean's PreDefinition/MkInhabitant: every parameter supplies an
-- Inhabited value in this witness-only local scope. Search tries Inhabited
-- first, then Nonempty and the approved Classical.ofNonempty wrapper.
-- Neither the recursive body nor a peer supplies its own logical witness.
-- No witness-only instance escapes this call; resource refusals propagate.
def psElabPartialInhabitant (environment : PsEnvironment)
    (levels : List PsName) (type : PsExpr) : Except PsElabError PsExpr := do
  let initial := psElabContextEmpty environment levels
  match psWhnf environment initial.metaContext initial.localContext type with
  | .forallE .. => pure ()
  | _ => throw (.data "PSCV0-TERM-02-FUNCTION: partial requires a function type")
  let opened ← psElabOpenCoreTelescope 4096 initial type none
  let className := psRootName "Inhabited"
  let context ← opened.bindersRev.reverse.foldlM
    (fun (context : PsElabContext) binder => do
      let sort ← (psInferType environment context.metaContext context.localContext
        binder.type).mapError PsElabError.infer
      let level ← (psInferEnsureSort environment context.metaContext context.localContext
        sort).mapError PsElabError.infer
      let dictionary ← psElabApplyCore context
        (.constE (psNameAppendStr className "mk") [level])
        [binder.type, .fvar binder.id]
      return { dictionary.context with
        instances := psInstanceIndexAdd dictionary.context.instances {
          value := dictionary.term, type := dictionary.type, className := some className } })
    opened.context
  let sort ← (psInferType environment context.metaContext context.localContext
    opened.body).mapError PsElabError.infer
  let level ← (psInferEnsureSort environment context.metaContext context.localContext
    sort).mapError PsElabError.infer
  let target := PsExpr.app (.constE className [level]) opened.body
  let value ← match psElabSynthesizeInstance context target with
    | .ok dictionary =>
      psElabApplyCore dictionary.context
        (.constE (psNameAppendStr className "default") [level])
        [opened.body, dictionary.term]
    | .error .implicitApplicationUnsupported => do
      -- Retry from the original search context. A failed Inhabited attempt
      -- must not constrain the independent Nonempty witness.
      let nonemptyTarget := PsExpr.app
        (.constE (psRootName "Nonempty") [level]) opened.body
      let evidence ← (psElabSynthesizeInstance context nonemptyTarget).mapError fun error =>
        match error with
        | .implicitApplicationUnsupported =>
          .data "PSCV0-TERM-02-INHABITED: no result inhabitant from Inhabited or Nonempty in the selected environment"
        | _ => error
      psElabApplyCore evidence.context
        (.constE (psNameAppendStr (psRootName "Classical") "ofNonempty") [level])
        [opened.body, evidence.term]
    | .error error => throw error
  let witness := psCloseElabLambdaBinders value.context.metaContext opened.bindersRev
    (psMetaInstantiate value.context.metaContext value.term)
  if psExprHasUnresolvedMeta witness then throw .unresolvedMetavariable
  let checked ← psElabResolvedTerm initial witness (some type)
  return psMetaInstantiate checked.context.metaContext checked.term

-- Like pinned Lean's addAndCompilePartial, logical identity and actual body
-- are separate. The public opaque receives an independently constructed
-- inhabitant; the body is checked against that opaque self, with no axiom
-- stub and no equation between them. Its numeric identity cannot be spelled
-- by source. A partialDecl marker is retained through preparation: generic
-- library erasure refuses it, while the selected ordinary host executes its
-- separately checked actual body after checking the original logical graph.
def psElabPartialCommandBatch (environment : PsEnvironment)
    (nameSyntax : PsSyntaxName) (binders : List (PsSyntaxBinderHead × PsSyntaxTerm))
    (typeSyntax bodySyntax : PsSyntaxTerm) (levelNames : List PsName) :
    Except PsElabError PsElabDeclarationBatchResult := do
  let some name := psSyntaxNameToName nameSyntax | throw .emptyName
  let binderResult ← psElabTypedBinders psElabTerm
    (psElabContextEmpty environment levelNames) binders
  let annotation ← psElabType psElabTerm binderResult.context typeSyntax
  let openType := psMetaInstantiate annotation.context.metaContext annotation.type
  let type := psCloseElabForallBinders annotation.context.metaContext
    binderResult.bindersRev openType
  -- This slice requires a resolved header before recursive body elaboration.
  if psExprHasUnresolvedMeta type then throw .unresolvedMetavariable
  let levels := psElabDeclarationLevels levelNames [type]
  let witness ← psElabPartialInhabitant environment levels type
  let logical := PsDeclaration.opaqueDecl name levels type witness
  let some withSelf := psEnvironmentAdd environment logical
    | throw (.duplicateDeclaration name)
  let body ← psElabTerm (psElabContextWithEnvironment annotation.context withSelf)
    bodySyntax (some openType)
  let closed := psCloseElabTypedBinders body.context.metaContext binderResult.bindersRev
    (psMetaInstantiate body.context.metaContext body.term)
    (psMetaInstantiate body.context.metaContext openType)
  if psExprHasUnresolvedMeta closed.fst || psExprHasUnresolvedMeta closed.snd then
    throw .unresolvedMetavariable
  if !psExprAlphaEq closed.snd type then throw .typeMismatch
  let implementationName := PsName.num name 0
  return {
    declarations := [logical, .partialDecl implementationName levels type closed.fst]
    sourceInfo := [psElabFinishSourceInfo body.context implementationName] }

-- A source mutual command remains one scope transaction. Each member retains
-- its own source span, privacy and body origin; common capture is explicit.
structure PsScopedMutualMember where
  source : PsSyntaxDeclaration
  alias : PsSyntaxName
  used : List String
  isPrivate : Bool

def psScopeMutualMember (resolver : PsScopeResolver)
    (member : PsSyntaxMutualMember) (alias : PsSyntaxName) :
    Except PsElabError PsScopedMutualMember := do
  let (sourceName, binders, type, value, span, isPartial) ← match member.declaration with
    | .partialDefinition name binders type value span =>
      pure (name, binders, type, value, span, true)
    | .definition name binders type value span =>
      pure (name, binders, type, value, span, false)
    | _ => throw (.data "PSCV0-MUTUAL-STRATEGY: selected mutual batch requires partial def/function members")
  let name := psScopeDeclarationName resolver sourceName
  -- Headers may resolve peer identities for diagnostics but cannot borrow a
  -- value or inhabitant from a peer whose checked header does not yet exist.
  let headerResolver := { resolver with mutualAliases := [] }
  let binders ← psScopeBinders (psScopeTerm 4096 headerResolver) [] binders
  let type ← psScopeTerm 4096 headerResolver binders.bound type
  let value ← psScopeTerm 4096 { resolver with abstractProofs := false } binders.bound value
  return {
    source := if isPartial then
        .partialDefinition (psScopeCanonicalNameSyntax name) binders.binders type.term value.term span
      else .definition (psScopeCanonicalNameSyntax name) binders.binders type.term value.term span
    alias
    used := psScopeUnion binders.used (psScopeUnion type.used value.used)
    isPrivate := member.isPrivate }

abbrev PsElabPartialHeader := PsElabCheckedHeader

-- Scope and typed headers are shared by logical strategies. This function
-- introduces only the real parameter telescope, never a declaration or a
-- provisional global constant. The caller owns how a checked body is built.
def psElabMutualTypedHeader (captured : PsElabTypedBindersResult)
    (nameSyntax : PsSyntaxName) (binders : List (PsSyntaxBinderHead × PsSyntaxTerm))
    (typeSyntax : PsSyntaxTerm) : Except PsElabError PsElabPartialHeader := do
  let some name := psSyntaxNameToName nameSyntax | throw .emptyName
  let binders ← psElabTypedBindersAcc psElabTerm binders captured.context captured.bindersRev
  let annotation ← psElabType psElabTerm binders.context typeSyntax
  let openType := psMetaInstantiate annotation.context.metaContext annotation.type
  let type := psCloseElabForallBinders annotation.context.metaContext binders.bindersRev openType
  if psExprHasUnresolvedMeta type then throw .unresolvedMetavariable
  return { name, context := annotation.context, bindersRev := binders.bindersRev, openType, type }

def psElabMutualPartialHeader (captured : PsElabTypedBindersResult)
    (source : PsSyntaxDeclaration) : Except PsElabError PsElabPartialHeader := do
  let .partialDefinition nameSyntax binders typeSyntax _ _ := source
    | throw (.data "PSCV0-MUTUAL-STRATEGY: selected mutual batch requires partial def/function members")
  psElabMutualTypedHeader captured nameSyntax binders typeSyntax

def psElabMutualPartialLogical (environment : PsEnvironment) (levels : List PsName)
    (header : PsElabPartialHeader) : Except PsElabError PsDeclaration := do
  let witness ← (psElabPartialInhabitant environment levels header.type).mapError
    (.atDeclaration header.name)
  return .opaqueDecl header.name levels header.type witness

-- All arguments, including implicit types, instances and proof slots, are
-- supplied through their actual Core telescope. This also handles a bare peer
-- function value and a section name shadowed by an ordinary member parameter.
def psElabMutualPartialAliases (context : PsElabContext) (levels : List PsName)
    (captures : List PsExpr) (headers : List PsElabPartialHeader)
    (members : List PsScopedMutualMember) :
    Except PsElabError (PsElabContext × List (Nat × PsExpr)) := do
  if headers.length != members.length then
    throw (.data "PSCV0-MUTUAL-INTERNAL: header/member ownership mismatch")
  (headers.zip members).foldlM
    (fun (state : PsElabContext × List (Nat × PsExpr)) entry => do
      let some alias := psSyntaxNameToName entry.snd.alias | throw .emptyName
      if (psLocalFindUser state.fst.localContext alias).isSome then
        throw (.scope "internal mutual alias is shadowed")
      let value ← psElabApplyCore state.fst
        (.constE entry.fst.name (levels.map PsLevel.param)) captures
      let pushed := psLocalPushLet value.context.localContext alias value.type value.term
      return (psElabContextWithLocal value.context pushed.context,
        (pushed.id, value.term) :: state.snd))
    (context, [])

structure PsElabPartialBody where
  declaration : PsDeclaration
  sourceInfo : PsElabSourceInfo

def psElabMutualPartialBody (environment : PsEnvironment) (levels : List PsName)
    (captures : List PsExpr) (headers : List PsElabPartialHeader)
    (members : List PsScopedMutualMember) (header : PsElabPartialHeader)
    (member : PsScopedMutualMember) : Except PsElabError PsElabPartialBody := do
  let .partialDefinition _ _ _ source _ := member.source
    | throw (.data "PSCV0-MUTUAL-STRATEGY: selected mutual batch requires partial def/function members")
  let (context, aliases) ← psElabMutualPartialAliases
    (psElabContextWithEnvironment header.context environment) levels captures headers members
  let body ← psElabTerm context source (some header.openType)
  let value := psElabSubstituteLocals aliases (psMetaInstantiate body.context.metaContext body.term)
  let closed := psCloseElabTypedBinders body.context.metaContext header.bindersRev value
    (psMetaInstantiate body.context.metaContext header.openType)
  if psExprHasUnresolvedMeta closed.fst || psExprHasUnresolvedMeta closed.snd then
    throw .unresolvedMetavariable
  if !psExprAlphaEq closed.snd header.type then throw .typeMismatch
  -- Revalidate after local aliases are gone. Only actual staged opaque peers
  -- and closed arguments may remain in the retained implementation.
  let _ ← psElabResolvedTerm (psElabContextEmpty environment levels) closed.fst (some header.type)
  let implementationName := PsName.num header.name 0
  return {
    declaration := .partialDecl implementationName levels header.type closed.fst
    sourceInfo := psElabFinishSourceInfo body.context implementationName }

structure PsElabMutualBatchResult where
  batch : PsElabDeclarationBatchResult
  members : List PsElabDeclarationBatchResult

def psElabMutualPartialPass (environment : PsEnvironment) (levels : List PsName)
    (captured : PsElabTypedBindersResult) (headers : List PsElabPartialHeader)
    (members : List PsScopedMutualMember) : Except PsElabError PsElabMutualBatchResult := do
  if headers.length != members.length then
    throw (.data "PSCV0-MUTUAL-INTERNAL: header/member ownership mismatch")
  -- Witnesses are synthesized in the original environment, independently of
  -- every body and every new peer. Stage all real opaques before any body.
  let logicals ← headers.mapM (psElabMutualPartialLogical environment levels)
  let staged ← psAddDeclarationList environment logicals
  let captures := captured.bindersRev.reverse.map (fun binder => PsExpr.fvar binder.id)
  let bodies ← (headers.zip members).mapM fun entry =>
    (psElabMutualPartialBody staged levels captures headers members entry.fst entry.snd).mapError
      (.atDeclaration entry.fst.name)
  let owned := (logicals.zip bodies).map fun entry =>
    ({
      declarations := [entry.fst, entry.snd.declaration]
      sourceInfo := [entry.snd.sourceInfo] } : PsElabDeclarationBatchResult)
  return {
    batch := {
      declarations := logicals ++ bodies.map (·.declaration)
      sourceInfo := bodies.map (·.sourceInfo) }
    members := owned }

def psElabMutualBatchLevels (available : List PsName)
    (result : PsElabMutualBatchResult) : List PsName :=
  psElabDeclarationLevels available (result.batch.declarations.flatMap fun declaration =>
    match declaration with
    | .opaqueDecl _ _ type value | .partialDecl _ _ type value => [type, value]
    | _ => [])

def psElabMutualLevelNamesEqual (left right : List PsName) : Bool :=
  left.length == right.length && (left.zip right).all (fun entry => psNameEq entry.fst entry.snd)

def psElabPartialMutualBatch (environment : PsEnvironment) (levelNames : List PsName)
    (capturedSyntax : List PsScopeBinder) (members : List PsScopedMutualMember) :
    Except PsElabError PsElabMutualBatchResult := do
  if members.isEmpty then throw (.data "PSCV0-MUTUAL-EMPTY: mutual requires def/function members")
  let captured ← psElabTypedBinders psElabTerm (psElabContextEmpty environment levelNames) capturedSyntax
  let headers ← members.mapM fun member =>
    let name := (psSyntaxNameToName (psElabOriginSource member.source).fst).getD .anonymous
    (psElabMutualPartialHeader captured member.source).mapError (.atDeclaration name)
  let initialLevels := psElabDeclarationLevels levelNames (headers.map (·.type))
  let first ← psElabMutualPartialPass environment initialLevels captured headers members
  -- Pinned PreDefinition.Basic.fixLevelParams gives every main member the
  -- same ordered universe union over all checked types and bodies. A body-only
  -- universe requires new real opaque signatures and fresh body/source-info
  -- elaboration; changing only constant arities would leave stale identities.
  let finalLevels := psElabMutualBatchLevels levelNames first
  if psElabMutualLevelNamesEqual initialLevels finalLevels then return first
  let final ← psElabMutualPartialPass environment finalLevels captured headers members
  if !psElabMutualLevelNamesEqual finalLevels (psElabMutualBatchLevels levelNames final) then
    throw (.data "PSCV0-MUTUAL-UNIVERSES: checked mutual universe closure did not stabilize")
  return final

-- A typed SCC already owns its exact closed headers and source bodies. Its
-- remaining free variables are full peers in this component; dependencies
-- outside the SCC have become actual checked constants. Independently build
-- all logical inhabitants before substituting any peer into any body.
def psElabPartialMutualFromChecked (environment : PsEnvironment)
    (levels : List PsName) (members : List PsElabPreDefinition) :
    Except PsElabError PsElabMutualBatchResult := do
  if members.isEmpty then
    throw (.data "PSCV0-PREDEFINITION-OWNERSHIP: empty partial component")
  let ownedNames := members.flatMap fun member => [member.name, PsName.num member.name 0]
  for name in ownedNames do
    if (psEnvironmentFind environment name).isSome ||
        (ownedNames.filter (psNameEq name)).length != 1 then
      throw (.duplicateDeclaration name)
  let logicals ← members.mapM fun member => do
    if psExprHasUnresolvedMeta member.type || !psExprFVarsInContext psLocalEmpty member.type then
      throw (.data "PSCV0-PREDEFINITION-HEADER: partial header is not closed")
    let witness ← (psElabPartialInhabitant environment levels member.type).mapError
      (.atDeclaration member.name)
    return PsDeclaration.opaqueDecl member.name levels member.type witness
  let staged ← psAddDeclarationList environment logicals
  let replacements := members.map fun member =>
    (member.peerId, PsExpr.constE member.name (levels.map PsLevel.param))
  let bodies ← members.mapM fun member => do
    let value := psElabSubstituteLocals replacements member.value
    if psExprHasUnresolvedMeta value || !psExprFVarsInContext psLocalEmpty value then
      throw (.data "PSCV0-PREDEFINITION-BODY: partial body retains an unowned peer")
    let checked ← (psElabResolvedTerm (psElabContextEmpty staged levels)
      value (some member.type)).mapError (.atDeclaration member.name)
    let implementationName := PsName.num member.name 0
    return ({
      declaration := PsDeclaration.partialDecl implementationName levels member.type checked.term
      sourceInfo := { member.sourceInfo with owner := implementationName } } : PsElabPartialBody)
  let _ ← psAddDeclarationList staged (bodies.map (·.declaration))
  return {
    batch := {
      declarations := logicals ++ bodies.map (·.declaration)
      sourceInfo := bodies.map (·.sourceInfo) }
    members := (logicals.zip bodies).map fun (logical, body) => {
      declarations := [logical, body.declaration]
      sourceInfo := [body.sourceInfo] } }


