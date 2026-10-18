import Ps.Elab.Term
import Ps.Elab.DataIndexPromotion
import Ps.Elab.DataUniverseInference
import Ps.Meta.Inductive
import Ps.Core.Nested
import Ps.Core.InductiveGroup
import Ps.Foundation.Diagnostic

-- Structural producers attach the exact checked helper group to its source
-- member. Publication consumes this provenance; generated-name spelling is
-- never evidence that an unrelated declaration belongs to a source.
structure PsElabStructuralHelperOwnership where
  owner : PsName
  families : List PsInductiveInfo
  declarations : List PsDeclaration

structure PsElabDeclarationBatchResult where
  declarations : List PsDeclaration
  sourceInfo : List PsElabSourceInfo := []
  diagnostics : List PsDiagnostic := []
  structuralHelpers : List PsElabStructuralHelperOwnership := []

def psSyntaxConstructorCoreName (inductiveName : PsName)
    (sourceName : PsSyntaxName) : Option PsName :=
  match sourceName.segments with
  | [name] => some (psNameAppendStr inductiveName name)
  | _ => none

def psEnvironmentAddOwnedBootstrapDeclaration (environment : PsEnvironment)
    (declaration : PsDeclaration) : Option PsEnvironment :=
  let name := psDeclarationName declaration
  if psNameEq name psProdName || psNameEq name psListName || psNameEq name psOptionName then
    psEnvironmentAddReplacingAxiom environment declaration
  else psEnvironmentAdd environment declaration

def psAddDeclarationList (environment : PsEnvironment) (declarations : List PsDeclaration) :
    Except PsElabError PsEnvironment :=
  declarations.foldlM (fun environment declaration =>
    match psEnvironmentAddOwnedBootstrapDeclaration environment declaration with
    | some environment => pure environment
    | none => throw (.duplicateDeclaration (psDeclarationName declaration))) environment

def psElabReverseDeclarations (declarations : List PsDeclaration) : List PsDeclaration :=
  declarations.reverse

def psElabAppendDeclarations (left right : List PsDeclaration) : List PsDeclaration := left ++ right

-- Every occurrence must use the same uniform parameters. Indices are checked
-- by ordinary application elaboration and may vary between constructors/fields.
def psElabDataIndices (context : PsElabContext) (info : PsInductiveInfo)
    (parameters : List PsExpr) (type : PsExpr) : Except PsElabError (List PsExpr) := do
  let view := psExprAppView
    (psWhnf context.environment context.metaContext context.localContext type)
  let .constE name levels := view.head | throw (.data "constructor result must be its declared family")
  if !psNameEq name info.name || levels.length != info.levelParams.length ||
      !(levels.zip info.levelParams).all (fun pair =>
        psLevelEquivalent (psLevelInstantiate context.metaContext.levels pair.fst) (.param pair.snd)) then
    throw (.data "constructor result must be its declared family")
  if view.args.length != info.numParams + info.numIndices then
    throw (.data "family parameter/index arity mismatch")
  if !(parameters.zip (view.args.take info.numParams)).all (fun pair =>
      psDefEqReadOnlyWithEnv context.environment context.metaContext context.localContext
        pair.fst pair.snd) then
    throw (.data "constructor parameters must remain uniform")
  return view.args.drop info.numParams

-- Nested occurrences must use the SAME checked uniform parameters as the
-- family's constructors. Previously only direct fields checked this telescope,
-- and the positive-container whitelist accepted e.g. List(Family Nat) under
-- Family α. Neither positive nesting nor a missing runtime IH permits this.
--
-- Inspect every recursive occurrence, while retaining the intentionally
-- selected List/Option/Array/Prod positive-container policy. Kernel admission
-- is still the final positivity authority. No nested IH is manufactured.
def psElabValidateNestedRecursiveFieldWithFuel
    (fuel : Nat) (context : PsElabContext) (plan : PsInductiveGroupPlan)
    (parameters : List PsExpr) (fieldType : PsExpr) :
    Except PsElabError Unit := do
  match fuel with
  | 0 => throw .fuelExhausted
  | remaining + 1 =>
    let fieldType := psWhnf context.environment context.metaContext
      context.localContext fieldType
    if !plan.members.any (fun info => psExprHasConst info.name fieldType) then return ()
    if let .forallE name domain body binder := fieldType then
      if plan.members.any (fun info => psExprHasConst info.name domain) then
        throw (.data "recursive family occurs in a function-field domain")
      let pushed := psLocalPushBinding context.localContext name domain binder
      return ← psElabValidateNestedRecursiveFieldWithFuel remaining
        (psElabContextWithLocal context pushed.context) plan parameters
        (psExprInstantiate1 body (.fvar pushed.id))
    let view := psExprAppView fieldType
    let .constE head _ := view.head
      | throw (.data "unsupported recursive field; expected a positive direct family occurrence")
    if let some info := psInductiveGroupFind plan head then
      let _ ← psElabDataIndices context info parameters fieldType
      return ()
    let some selected := psSelectedNestedContainer? fieldType
      | throw (.data "unsupported recursive field; expected a positive direct family occurrence")
    for element in psSelectedNestedContainerElements selected do
      psElabValidateNestedRecursiveFieldWithFuel remaining context plan
        parameters element

def psElabDataRecursiveFields (context : PsElabContext) (plan : PsInductiveGroupPlan)
    (parameters : List PsExpr) (fields : List PsElabTypedBinder) :
    Except PsElabError (List Nat) := do
  let (_, result) ← fields.foldlM (fun (state : Nat × List Nat) field => do
    let type := psWhnf context.environment context.metaContext context.localContext field.type
    let view := psExprAppView type
    let direct := match view.head with
      | .constE name _ => psInductiveGroupFind plan name
      | _ => none
    if let some info := direct then
      let _ ← psElabDataIndices context info parameters type
      return (state.fst + 1, state.fst :: state.snd)
    if plan.members.any (fun info => psExprHasConst info.name type) then
      psElabValidateNestedRecursiveFieldWithFuel 4096 context plan parameters type
      return (state.fst + 1, state.fst :: state.snd)
    return (state.fst + 1, state.snd)) (0, [])
  return result.reverse

-- Native local family heads share the declaration's universe parameters.
-- Our temporary constants expose an explicit vector, so align only those
-- actual group heads before checking recursive occurrences. Unused source
-- universes must not remain fresh holes merely because no domain mentions them.
def psElabDataAlignGroupLevels (context : PsElabContext)
    (group : PsInductiveGroupPlan) (expression : PsExpr) : Except PsElabError PsElabContext := do
  match expression with
  | .constE name levels =>
    match group.members.find? (fun info => psNameEq info.name name) with
    | none => return context
    | some info =>
      if levels.length != info.levelParams.length then
        throw (.data "temporary inductive group universe arity mismatch")
      (levels.zip info.levelParams).foldlM (fun context (actual, name) => do
        let unified := psLevelUnify context.metaContext.levels actual (.param name)
        if !unified.success then
          throw (.data "recursive family universe parameters must remain uniform")
        return psElabContextWithMeta context { context.metaContext with levels := unified.context })
        context
  | .app fn arg | .lam _ fn arg _ | .forallE _ fn arg _ =>
    let context ← psElabDataAlignGroupLevels context group fn
    psElabDataAlignGroupLevels context group arg
  | .letE _ type value body =>
    let context ← psElabDataAlignGroupLevels context group type
    let context ← psElabDataAlignGroupLevels context group value
    psElabDataAlignGroupLevels context group body
  | .proj _ _ value => psElabDataAlignGroupLevels context group value
  | _ => return context

def psElabDataConstructorWithContext (context : PsElabContext)
    (parameterBindersRev : List PsElabTypedBinder) (plan : PsInductiveGroupPlan)
    (info : PsInductiveInfo)
    (index : Nat) (source : PsSyntaxInductiveConstructor) :
    Except PsElabError (PsDeclaration × PsElabSourceInfo × PsElabContext) := do
  let some name := psSyntaxConstructorCoreName info.name source.name | throw .emptyName
  let fields ← psElabTypedBinders psElabTerm context source.fields
  let parameters := psElabBinderArguments parameterBindersRev
  let result ← match source.resultType with
    | some type => psElabType psElabTerm fields.context type
    | none =>
      if info.numIndices != 0 then throw (.data "indexed constructor requires a result type")
      pure (PsElabTypeResult.mk fields.context (psExprApplyMany (.constE info.name (info.levelParams.map PsLevel.param)) parameters))
  let context ← ((fields.bindersRev.map (·.type)) ++ [result.type]).foldlM
    (fun context type => psElabDataAlignGroupLevels context plan type) result.context
  let result := { result with context }
  let familyHead := (psExprAppView (psWhnf result.context.environment
    result.context.metaContext result.context.localContext result.type)).head
  let unified := psUnify result.context.environment result.context.localContext
    result.context.metaContext familyHead (.constE info.name (info.levelParams.map PsLevel.param))
  if unified.resourceExceeded then throw .fuelExhausted
  if !unified.success then throw (.data "constructor result must be its declared family")
  let result := { result with context := psElabContextWithMeta result.context unified.context }
  let _ ← psElabDataIndices result.context info parameters result.type
  let recursiveFields ← psElabDataRecursiveFields result.context plan parameters fields.bindersRev.reverse
  let type := psCloseElabImplicitBinders result.context.metaContext parameterBindersRev
    (psCloseElabForallBinders result.context.metaContext fields.bindersRev result.type)
  if !(psExprMetaIds type).isEmpty then throw .unresolvedMetavariable
  let declaration := PsDeclaration.constructorDecl {
    name, levelParams := info.levelParams, type, inductiveName := info.name, constructorIndex := index
    numParams := info.numParams, numFields := fields.bindersRev.length, recursiveFields }
  return (declaration, psElabFinishSourceInfo result.context name, result.context)

-- Existing callers retain their fully resolved declaration contract.
def psElabDataConstructor (context : PsElabContext)
    (parameterBindersRev : List PsElabTypedBinder) (plan : PsInductiveGroupPlan)
    (info : PsInductiveInfo) (index : Nat) (source : PsSyntaxInductiveConstructor) :
    Except PsElabError (PsDeclaration × PsElabSourceInfo) := do
  let (declaration, receipt, _) ← psElabDataConstructorWithContext context
    parameterBindersRev plan info index source
  if psExprHasUnresolvedMeta (psDeclarationType declaration) then throw .unresolvedMetavariable
  return (declaration, receipt)

-- Pinned Lean uses one elimination universe, all visible AND nested motives,
-- and every slot's constructor minors in each recursor. The templates already
-- name real restored container applications, so no private auxiliary datatype
-- or shallow bridge definition is introduced.
def psBuildInductiveGroupRecursors (context : PsElabContext)
    (parameterBindersRev : List PsElabTypedBinder) (group : PsInductiveGroupPlan)
    (constructors : List PsDeclaration) : Except PsElabError (List PsDeclaration) := do
  let first :: _ := group.members | throw (.data "empty inductive group")
  if !psInductiveGroupHeaderShapeValid group then throw (.data "incompatible inductive group headers")
  if constructors.length != psInductiveGroupNumMinors group then
    throw (.data "inductive group constructor count mismatch")
  for declaration in constructors do
    if let .constructorDecl constructor := declaration then
      if !psInductiveGroupOccurrencesUniform group constructor.type then
        throw (.data "constructor parameters must remain uniform")
  let some plan := psBuildInductiveEliminationPlan
      (psWhnf context.environment context.metaContext psLocalEmpty)
      (psEnvironmentFindInductive context.environment)
      (psEnvironmentFindConstructor context.environment) group
    | throw (.data "nested specialization requires selected containers and common parameters only")
  let parameters := psElabBinderArguments parameterBindersRev
  let resultLevel ← (psInductiveResultLevel context.environment first).mapError PsElabError.infer
  for slot in plan.slots do
    let cursor ← psElabMatchApplyParameters context parameters slot.type
    let indices ← psElabOpenCoreTelescope 4096 context cursor (some slot.family.numIndices)
    let level ← (psInferEnsureSort context.environment context.metaContext
      indices.context.localContext indices.body).mapError PsElabError.infer
    if !psLevelEquivalent resultLevel level then
      throw (.data "inductive group members must have the same resulting universe")
    if !(slot.constructors.all (psInductiveEliminationConstructorMetadataValid slot)) then
      throw (.data "invalid recursive field metadata")
  let large ← if plan.slots.length == 1 then
      (psInductiveLargeElimination context.environment first).mapError PsElabError.infer
    else pure (psLevelAlwaysPositive resultLevel)
  let some motiveUniverse := (List.range (first.levelParams.length + 1)).map
      (psNameAppendNum (psRootName "_motiveUniverse")) |>.find?
        (fun name => !(first.levelParams.any (psNameEq name)))
    | throw (.data "cannot allocate motive universe")
  let motiveLevel := if large then PsLevel.param motiveUniverse else .zero
  plan.slots.zipIdx.mapM fun (slot, index) => do
    let some type := psInductiveEliminationRecursorType
        (psWhnf context.environment context.metaContext psLocalEmpty) plan index motiveLevel
      | throw (.data "cannot construct the complete elimination-slot telescope")
    if psExprHasUnresolvedMeta type then throw .unresolvedMetavariable
    return .recursorDecl {
      name := slot.recursorName
      levelParams := if large then motiveUniverse :: first.levelParams else first.levelParams
      type, inductiveNames := psInductiveGroupNames group
      numParams := first.numParams, numIndices := slot.family.numIndices
      numMotives := plan.slots.length, numMinors := psInductiveEliminationNumMinors plan }

def psBuildInductiveRecursor (context : PsElabContext)
    (parameterBindersRev : List PsElabTypedBinder) (info : PsInductiveInfo)
    (constructors : List PsDeclaration) : Except PsElabError PsDeclaration := do
  let [recursor] ← psBuildInductiveGroupRecursors context parameterBindersRev { members := [info] } constructors
    | throw (.data "expected singleton recursor plan")
  return recursor

structure PsElabInductiveSource where
  name : PsSyntaxName
  params : List (PsSyntaxBinderHead × PsSyntaxTerm)
  resultType : Option PsSyntaxTerm
  constructors : List PsSyntaxInductiveConstructor
  isStructure : Bool := false

structure PsElabInductiveHeader where
  source : PsElabInductiveSource
  info : PsInductiveInfo
  context : PsElabContext
  bindersRev : List PsElabTypedBinder

-- Headers are elaborated in the pre-group environment. Only after their
-- complete parameter/index telescopes agree do any family names enter the
-- constructor environment; these entries remain unadmitted Core plans.
def psElabInductiveHeader (environment : PsEnvironment) (source : PsElabInductiveSource)
    (levelNames : List PsName) (metaContext : PsMetaContext := psMetaEmpty)
    (nextLocalId : Nat := 0) :
    Except PsElabError PsElabInductiveHeader := do
  let some name := psSyntaxNameToName source.name | throw .emptyName
  let initial := psElabContextWithMeta (psElabContextEmpty environment levelNames) metaContext
  let initial := psElabContextWithLocal initial { initial.localContext with nextId := nextLocalId }
  let parameters ← psElabTypedBinders psElabTerm initial source.params
  let result ← match source.resultType with
    | none =>
      let fresh := psMetaFreshLevel parameters.context.metaContext
      pure (PsElabTypeResult.mk
        (psElabContextWithMeta parameters.context fresh.context) (.sortE fresh.level))
    | some term => psElabType psElabTerm parameters.context term
  let indices ← psElabOpenCoreTelescope 4096 result.context result.type none
  match indices.body with
  | .sortE _ => pure ()
  | _ => throw (.data "data family must end in a sort")
  if source.isStructure && !indices.bindersRev.isEmpty then
    throw (.data "structure result must be a sort, not an indexed family")
  let type := psCloseElabForallBinders result.context.metaContext parameters.bindersRev result.type
  if !(psExprMetaIds type).isEmpty then throw .unresolvedMetavariable
  let names ← source.constructors.mapM fun constructor =>
    match psSyntaxConstructorCoreName name constructor.name with
    | some name => pure name
    | none => throw .emptyName
  if names.any (fun name => (names.filter (psNameEq name)).length > 1) then throw (.data "duplicate constructor")
  let info : PsInductiveInfo := {
    name, levelParams := psElabDeclarationLevels levelNames [type], type, numParams := parameters.bindersRev.length
    numIndices := indices.bindersRev.length, constructors := names, isStructure := source.isStructure }
  return { source, info, context := result.context, bindersRev := parameters.bindersRev }

def psElabInductiveGroupParametersWithContext (context : PsElabContext)
    (parameters : List PsExpr) (left right : PsExpr) : Except PsElabError PsElabContext := do
  match parameters with
  | [] => return context
  | parameter :: rest =>
    let left ← (psInferEnsureForall context.environment context.metaContext context.localContext left).mapError PsElabError.infer
    let right ← (psInferEnsureForall context.environment context.metaContext context.localContext right).mapError PsElabError.infer
    if !psBinderInfoEq left.binder right.binder then
      throw (.data "inductive group parameters must have compatible binder types and kinds")
    let unified := psUnify context.environment context.localContext context.metaContext left.domain right.domain
    if unified.resourceExceeded then throw .fuelExhausted
    if !unified.success then
      throw (.data "inductive group parameters must have compatible binder types and kinds")
    let context := psElabContextWithMeta context unified.context
    psElabInductiveGroupParametersWithContext context rest
      (psExprInstantiate1 left.body parameter) (psExprInstantiate1 right.body parameter)

def psElabInductiveGroupParameters (context : PsElabContext) (parameters : List PsExpr)
    (left right : PsExpr) : Except PsElabError Unit := do
  let _ ← psElabInductiveGroupParametersWithContext context parameters left right
  pure ()

-- Constructors use one common parameter identity. Each member retains its
-- source binder names as aliases for that common context, so alpha-renamed
-- compatible headers cannot introduce unrelated free-variable telescopes.
def psElabInductiveGroupContext (first header : PsElabInductiveHeader)
    (environment : PsEnvironment) : PsElabTypedBindersResult :=
  let bindersRev := (first.bindersRev.zip header.bindersRev).map fun (common, source) =>
    { common with name := source.name }
  let declarations := first.context.localContext.declarations.map fun declaration =>
    match bindersRev.find? (fun binder => binder.id == psLocalDeclId declaration), declaration with
    | some binder, .binding id _ type kind => .binding id binder.name type kind
    | _, _ => declaration
  let commonIds := first.bindersRev.map (·.id)
  let aliases := (first.bindersRev.zip header.bindersRev).flatMap fun (common, source) =>
    (psLocalVisibleNames header.context.localContext source.id).map fun name =>
      ({
        userName := name
        id := common.id
        beforeId := first.context.localContext.nextId } : PsLocalNameAlias)
  let localContext := {
    first.context.localContext with declarations
    nameAliases := aliases ++ first.context.localContext.nameAliases.filter
      (fun alias => !commonIds.contains alias.id) }
  let context := { first.context with environment := environment, infoRev := [], localContext := localContext }
  { bindersRev := bindersRev, context := context }

-- Temporary group constants are checked with the complete source roster.
-- Their argument vectors are rewritten only after exact old arity validation.
def psElabDataGroupLevelArityValid (members : List PsInductiveInfo) : PsExpr → Bool
  | .constE name levels =>
    match members.find? (fun info => psNameEq info.name name) with
    | some info => levels.length == info.levelParams.length
    | none => true
  | .app a b | .lam _ a b _ | .forallE _ a b _ =>
    psElabDataGroupLevelArityValid members a && psElabDataGroupLevelArityValid members b
  | .letE _ type value body =>
    psElabDataGroupLevelArityValid members type &&
      psElabDataGroupLevelArityValid members value &&
      psElabDataGroupLevelArityValid members body
  | .proj _ _ value => psElabDataGroupLevelArityValid members value
  | _ => true

-- Native elaboration still has local family heads here, without an explicit
-- universe argument vector. Do not count our temporary complete vector as
-- independent evidence that an otherwise unused source level is needed.
def psElabDataUsedExprLevels (members : List PsInductiveInfo) : PsExpr → List PsLevel
  | .sortE level => [level]
  | .constE name levels =>
    if members.any (fun info => psNameEq info.name name) then [] else levels
  | .app a b | .lam _ a b _ | .forallE _ a b _ =>
    psElabDataUsedExprLevels members a ++ psElabDataUsedExprLevels members b
  | .letE _ type value body =>
    psElabDataUsedExprLevels members type ++ psElabDataUsedExprLevels members value ++
      psElabDataUsedExprLevels members body
  | .proj _ _ value => psElabDataUsedExprLevels members value
  | _ => []

def psElabDataLocalExpressions (locals : PsLocalContext) : List PsExpr :=
  locals.declarations.flatMap fun declaration =>
    match declaration with
    | .binding _ _ type _ => [type]
    | .letDecl _ _ type value => [type, value]

def psElabDataMetaExpressions (context : PsMetaContext) : List PsExpr :=
  context.declarations.flatMap (fun declaration =>
    declaration.type :: psElabDataLocalExpressions declaration.localContext) ++
  context.assignments.map (·.value) ++
  context.delayed.flatMap (fun delayed =>
    delayed.body :: delayed.abstractions.flatMap fun abstraction =>
      match abstraction with
      | .lambdaE _ _ type _ | .forallE _ _ type _ => [type]
      | .letE _ _ type value => [type, value]
      | .substitute _ value => [value])

-- Closed templates originally mention the temporary complete universe roster.
-- Prune unused source levels and append only genuinely generalized header levels
-- to every occurrence of these same group constants.
def psElabDataFinalizeExpr (members : List PsInductiveInfo)
    (oldLevels newLevels : List PsName) (expression : PsExpr) : PsExpr :=
  match expression with
  | .constE name levels =>
    if members.any (fun info => psNameEq info.name name) then
      let mapped := newLevels.map fun name =>
        match (oldLevels.zip levels).find? (fun entry => psNameEq entry.fst name) with
        | some (_, value) => value
        | none => PsLevel.param name
      .constE name mapped
    else expression
  | .app fn arg =>
    .app (psElabDataFinalizeExpr members oldLevels newLevels fn)
      (psElabDataFinalizeExpr members oldLevels newLevels arg)
  | .lam name type body binder =>
    .lam name (psElabDataFinalizeExpr members oldLevels newLevels type)
      (psElabDataFinalizeExpr members oldLevels newLevels body) binder
  | .forallE name type body binder =>
    .forallE name (psElabDataFinalizeExpr members oldLevels newLevels type)
      (psElabDataFinalizeExpr members oldLevels newLevels body) binder
  | .letE name type value body =>
    .letE name (psElabDataFinalizeExpr members oldLevels newLevels type)
      (psElabDataFinalizeExpr members oldLevels newLevels value)
      (psElabDataFinalizeExpr members oldLevels newLevels body)
  | .proj name index value => .proj name index (psElabDataFinalizeExpr members oldLevels newLevels value)
  | expression => expression

def psElabDataMapLocalContext (map : PsExpr → PsExpr) (locals : PsLocalContext) : PsLocalContext :=
  { locals with declarations := locals.declarations.map fun declaration =>
      match declaration with
      | .binding id name type binder => .binding id name (map type) binder
      | .letDecl id name type value => .letDecl id name (map type) (map value) }

def psElabDataMapInfo (map : PsExpr → PsExpr) : PsElabInfo → PsElabInfo
  | .reference source resolved projection term type =>
    .reference source resolved projection (map term) (map type)
  | .instanceSelection span goal evidence => .instanceSelection span (map goal) (map evidence)
  | .binderGroup head annotation ids => .binderGroup head annotation ids
  | .insertedArgument span kind name fn value type =>
    .insertedArgument span kind name (map fn) (map value) (map type)

def psElabDataMapMeta (map : PsExpr → PsExpr) (context : PsMetaContext) : PsMetaContext :=
  { context with
    declarations := context.declarations.map fun declaration => {
      declaration with type := map declaration.type
      localContext := psElabDataMapLocalContext map declaration.localContext }
    assignments := context.assignments.map fun assignment => {
      assignment with value := map assignment.value }
    delayed := context.delayed.map fun delayed => {
      delayed with body := map delayed.body
      abstractions := delayed.abstractions.map fun abstraction =>
        match abstraction with
        | .lambdaE id name type binder => .lambdaE id name (map type) binder
        | .forallE id name type binder => .forallE id name (map type) binder
        | .letE id name type value => .letE id name (map type) (map value)
        | .substitute id value => .substitute id (map value) } }

def psElabDataFinalize (context : PsElabContext) (available : List PsName)
    (group : PsInductiveGroupPlan) (constructors : List PsDeclaration)
    (sourceInfo : List PsElabSourceInfo) :
    Except PsElabError (PsElabContext × PsInductiveGroupPlan ×
      List PsDeclaration × List PsElabSourceInfo) := do
  let first :: _ := group.members | throw (.data "empty inductive group")
  let instantiate := psMetaInstantiate context.metaContext
  let types := group.members.map (fun info => instantiate info.type) ++
    constructors.map (fun declaration => instantiate (psDeclarationType declaration))
  if types.any psExprHasUnresolvedMeta then throw .unresolvedMetavariable
  let retained := psElabDataLocalExpressions context.localContext ++
    psElabDataMetaExpressions context.metaContext ++
    (context.infoRev ++ sourceInfo.flatMap (·.entries)).flatMap (fun entry =>
      psElabDataLocalExpressions entry.localContext ++ psElabInfoExpressions entry.info)
  if !(types ++ retained.map instantiate).all (psElabDataGroupLevelArityValid group.members) then
    throw (.data "temporary inductive group universe arity mismatch")
  let used := types.flatMap (psElabDataUsedExprLevels group.members)
  let levels := psElabDeclarationLevels available (used.map PsExpr.sortE)
  let map := fun expression =>
    psElabDataFinalizeExpr group.members first.levelParams levels (instantiate expression)
  let metaContext := psElabDataMapMeta map context.metaContext
  let context := {
    context with metaContext
    localContext := psElabDataMapLocalContext map context.localContext
    infoRev := context.infoRev.map fun entry => {
      localContext := psElabDataMapLocalContext map entry.localContext
      info := psElabDataMapInfo map entry.info }
    levelNames := levels }
  let members := group.members.map fun info => {
    info with levelParams := levels, type := map info.type }
  let constructors ← constructors.mapM fun declaration => do
    let .constructorDecl info := declaration
      | throw (.data "constructor plan contains another declaration")
    return PsDeclaration.constructorDecl { info with levelParams := levels, type := map info.type }
  let sourceInfo := sourceInfo.map fun receipt => {
    receipt with metaContext
    entries := receipt.entries.map fun entry => {
      localContext := psElabDataMapLocalContext map entry.localContext
      info := psElabDataMapInfo map entry.info } }
  return (context, { members }, constructors, sourceInfo)

-- Native group entry point. The existing .ps singleton/structure entry point
-- below uses this same pipeline. This does not expand v7.2's source mutual
-- grammar, which currently selects definition/function groups only.
def psElabInductiveGroup (environment : PsEnvironment)
    (sources : List PsElabInductiveSource) (levelNames : List PsName := []) :
    Except PsElabError PsElabDeclarationBatchResult := do
  if sources.length > 1 && sources.any (·.isStructure) then
    throw (.data "mutual structures require the group projection plan")
  let (metaContext, nextLocalId, headers) ← sources.foldlM
    (fun (state : PsMetaContext × Nat × List PsElabInductiveHeader) source => do
      let (metaContext, nextLocalId, headers) := state
      let header ← psElabInductiveHeader environment source levelNames metaContext nextLocalId
      return (header.context.metaContext, header.context.localContext.nextId,
        headers ++ [header])) (psMetaEmpty, 0, [])
  -- Constructors can mention a source universe not used in a header. Retain
  -- the complete temporary roster; finalization computes and rewrites its use.
  let headerLevels := psElabDeclarationLevels levelNames (headers.map (·.info.type))
  let groupLevels := headerLevels.foldl (fun names name =>
    if names.any (psNameEq name) then names else names ++ [name]) levelNames
  let headers := headers.map fun header => {
    header with info := { header.info with levelParams := groupLevels }
    context := psElabContextWithLocal (psElabContextWithMeta header.context metaContext)
      { header.context.localContext with nextId := nextLocalId } }
  let first :: _ := headers | throw (.data "empty inductive group")
  let sourceSpan := first.source.name.span
  let plan : PsInductiveGroupPlan := { members := headers.map (·.info) }
  if !psInductiveGroupHeaderShapeValid plan then throw (.data "incompatible inductive group headers")
  let names := plan.members.flatMap fun info =>
    info.name :: (psNameAppendStr info.name "rec" :: info.constructors)
  if names.any (fun name => (names.filter (psNameEq name)).length != 1) then
    throw (.data "duplicate inductive group member")
  let parameters := psElabBinderArguments first.bindersRev
  let context ← (headers.drop 1).foldlM (fun context header => do
    let context ← psElabInductiveGroupParametersWithContext context parameters first.info.type header.info.type
    let level ← psElabDataResultLevel context first.info.type
    let other ← psElabDataResultLevel context header.info.type
    let unified := psLevelUnify context.metaContext.levels level other
    if !unified.success then throw (.data "inductive group members must have the same resulting universe")
    return psElabContextWithMeta context { context.metaContext with levels := unified.context }) first.context
  let declarations := plan.members.map PsDeclaration.inductiveDecl
  let withHeaders ← psAddDeclarationList environment declarations
  let (context, constructors, sourceInfo) ← headers.foldlM
    (fun (state : PsElabContext × List PsDeclaration × List PsElabSourceInfo) header => do
      let (context, constructors, receipts) := state
      let common := psElabInductiveGroupContext { first with context } header withHeaders
      let (context, _, constructorsRev, receiptsRev) ← header.source.constructors.foldlM
        (fun (state : PsElabContext × Nat × List PsDeclaration × List PsElabSourceInfo) source => do
          let (context, index, constructors, receipts) := state
          let (declaration, receipt, inner) ← psElabDataConstructorWithContext context common.bindersRev
            plan header.info index source
          return (psElabLeaveScope context inner, index + 1,
            declaration :: constructors, receipt :: receipts)) (common.context, 0, [], [])
      return (psElabLeaveScope state.1 context, constructors ++ constructorsRev.reverse,
        receipts ++ (psElabFinishSourceInfo header.context header.info.name :: receiptsRev.reverse)))
    (context, [], [])
  let withConstructors ← psAddDeclarationList withHeaders constructors
  let (context, plan, constructors) ← psElabDataPromoteIndices
    { context with environment := withConstructors } plan constructors
  let (context, highUniverse) ← psElabDataInferUniverses context plan constructors
  let (context, plan, constructors, sourceInfo) ←
    psElabDataFinalize context levelNames plan constructors sourceInfo
  let declarations := plan.members.map PsDeclaration.inductiveDecl
  let withHeaders ← psAddDeclarationList environment declarations
  let withConstructors ← psAddDeclarationList withHeaders constructors
  let first :: _ := plan.members | throw (.data "empty inductive group")
  let parameters ← psElabOpenCoreTelescope 4096
    { context with environment := withConstructors, localContext := psLocalEmpty }
    first.type (some first.numParams)
  let recursors ← psBuildInductiveGroupRecursors parameters.context
    parameters.bindersRev plan constructors
  let diagnostics := if highUniverse then
      [{
        severity := .warning
        message := "inferred universe level may be unnecessarily high; provide an explicit resulting sort to select a smaller valid universe"
        span := sourceSpan }]
    else []
  return { declarations := declarations ++ constructors ++ recursors, sourceInfo, diagnostics }

def psElabInductiveDeclaration (environment : PsEnvironment) (nameSyntax : PsSyntaxName)
    (params : List (PsSyntaxBinderHead × PsSyntaxTerm)) (resultType : Option PsSyntaxTerm)
    (constructors : List PsSyntaxInductiveConstructor) (isStructure : Bool)
    (levelNames : List PsName := []) :
    Except PsElabError PsElabDeclarationBatchResult :=
  psElabInductiveGroup environment
    [{ name := nameSyntax, params, resultType, constructors, isStructure }] levelNames

def psElabStructureDeclaration (environment : PsEnvironment) (name : PsSyntaxName)
    (params : List (PsSyntaxBinderHead × PsSyntaxTerm)) (resultType : Option PsSyntaxTerm)
    (fields : List (PsSyntaxBinderHead × PsSyntaxTerm)) (span : PsSourceSpan)
    (levelNames : List PsName := []) :
    Except PsElabError PsElabDeclarationBatchResult :=
  psElabInductiveDeclaration environment name params resultType
    [{ name := PsSyntaxName.mk ["mk"] span, fields, span }] true levelNames

