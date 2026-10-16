import Ps.Elab.Term
import Ps.Meta.Inductive
import Ps.Core.Nested
import Ps.Core.InductiveGroup

structure PsElabDeclarationBatchResult where
  declarations : List PsDeclaration
  sourceInfo : List PsElabSourceInfo := []

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
    let view := psExprAppView fieldType
    let .constE head _ := view.head
      | throw (.data "unsupported recursive field; expected a positive direct family occurrence")
    if let some info := psInductiveGroupFind plan head then
      let _ ← psElabDataIndices context info parameters fieldType
      return ()
    if plan.members.length != 1 || plan.members.any (fun info => info.numIndices != 0) then
      throw (.data "nested recursive groups require the checked auxiliary motive plan")
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
    return (state.fst + 1, state.snd)) (0, [])
  return result.reverse

def psElabDataConstructor (context : PsElabContext)
    (parameterBindersRev : List PsElabTypedBinder) (plan : PsInductiveGroupPlan)
    (info : PsInductiveInfo)
    (index : Nat) (source : PsSyntaxInductiveConstructor) :
    Except PsElabError (PsDeclaration × PsElabSourceInfo) := do
  let some name := psSyntaxConstructorCoreName info.name source.name | throw .emptyName
  let fields ← psElabTypedBinders psElabTerm context source.fields
  let parameters := psElabBinderArguments parameterBindersRev
  let result ← match source.resultType with
    | some type => psElabType psElabTerm fields.context type
    | none =>
      if info.numIndices != 0 then throw (.data "indexed constructor requires a result type")
      pure (PsElabTypeResult.mk fields.context (psExprApplyMany (.constE info.name (info.levelParams.map PsLevel.param)) parameters))
  let familyHead := (psExprAppView (psWhnf result.context.environment
    result.context.metaContext result.context.localContext result.type)).head
  let unified := psUnify result.context.environment result.context.localContext
    result.context.metaContext familyHead (.constE info.name (info.levelParams.map PsLevel.param))
  if !unified.success then throw (.data "constructor result must be its declared family")
  let result := { result with context := psElabContextWithMeta result.context unified.context }
  let _ ← psElabDataIndices result.context info parameters result.type
  let recursiveFields ← psElabDataRecursiveFields result.context plan parameters fields.bindersRev.reverse
  let type := psCloseElabImplicitBinders result.context.metaContext parameterBindersRev
    (psCloseElabForallBinders result.context.metaContext fields.bindersRev result.type)
  if psExprHasUnresolvedMeta type then throw .unresolvedMetavariable
  let declaration := PsDeclaration.constructorDecl {
    name, levelParams := info.levelParams, type, inductiveName := info.name, constructorIndex := index
    numParams := info.numParams, numFields := fields.bindersRev.length, recursiveFields }
  return (declaration, psElabFinishSourceInfo result.context name)

-- Motives always receive all indices followed by the major. The same operation
-- constructs constructor conclusions and recursive hypotheses.
def psElabDataMotiveAt (context : PsElabContext) (info : PsInductiveInfo)
    (parameters : List PsExpr) (motive value type : PsExpr) : Except PsElabError PsExpr := do
  let indices ← psElabDataIndices context info parameters type
  return psExprApplyMany motive (indices ++ [value])

-- All motives are installed before any minor is constructed. A recursive
-- field selects its own family's motive; the result selects its constructor's
-- family. No cross-family induction hypothesis is guessed from a field index.
def psElabDataGroupMotiveAt (context : PsElabContext) (plan : PsInductiveGroupPlan)
    (parameters : List PsExpr) (motives : List PsElabTypedBinder)
    (value type : PsExpr) : Except PsElabError PsExpr := do
  let view := psExprAppView (psWhnf context.environment context.metaContext context.localContext type)
  let .constE name _ := view.head | throw (.data "expected a group family occurrence")
  let some pair := (plan.members.zip motives).find? (fun pair => psNameEq pair.fst.name name)
    | throw (.data "recursive field does not belong to the inductive group")
  psElabDataMotiveAt context pair.fst parameters (.fvar pair.snd.id) value type

def psElabDataMinor (context : PsElabContext) (plan : PsInductiveGroupPlan)
    (parameters : List PsExpr) (motives : List PsElabTypedBinder)
    (constructor : PsConstructorInfo) : Except PsElabError PsExpr := do
  let some info := psInductiveGroupFind plan constructor.inductiveName
    | throw (.data "constructor does not belong to the inductive group")
  let cursor ← psElabMatchApplyParameters context parameters constructor.type
  let fields ← psElabOpenCoreTelescope 4096 context cursor (some constructor.numFields)
  let args := psElabBinderArguments fields.bindersRev
  let intro := psExprApplyMany (.constE constructor.name (info.levelParams.map PsLevel.param)) (parameters ++ args)
  let conclusion ← psElabDataGroupMotiveAt fields.context plan parameters motives intro fields.body
  let fieldsInOrder := fields.bindersRev.reverse
  let hypotheses ← constructor.recursiveFields.mapM fun index => do
    let some field := fieldsInOrder[index]? | throw (.data "invalid recursive field metadata")
    psElabDataGroupMotiveAt fields.context plan parameters motives (.fvar field.id) field.type
  let body := (hypotheses.zip constructor.recursiveFields).foldr (fun entry body =>
    .forallE (psNameAppendNum (psRootName "_ih") entry.snd) entry.fst body .explicit) conclusion
  return psCloseElabForallBinders fields.context.metaContext fields.bindersRev body

-- Pinned Lean uses one elimination universe, all family motives, and all
-- constructor minors in every recursor. Mutually inductive predicates cannot
-- use the singleton large-elimination exception (kernel/inductive.cpp).
def psBuildInductiveGroupRecursors (context : PsElabContext)
    (parameterBindersRev : List PsElabTypedBinder) (plan : PsInductiveGroupPlan)
    (constructors : List PsDeclaration) : Except PsElabError (List PsDeclaration) := do
  let first :: _ := plan.members | throw (.data "empty inductive group")
  if !psInductiveGroupHeaderShapeValid plan then throw (.data "incompatible inductive group headers")
  let large ← if plan.members.length == 1 then
      (psInductiveLargeElimination context.environment first).mapError PsElabError.infer
    else do
      let level ← (psInductiveResultLevel context.environment first).mapError PsElabError.infer
      pure (psLevelAlwaysPositive level)
  let some motiveUniverse := (List.range (first.levelParams.length + 1)).map
      (psNameAppendNum (psRootName "_motiveUniverse")) |>.find?
        (fun name => !(first.levelParams.any (psNameEq name)))
    | throw (.data "cannot allocate motive universe")
  let motiveLevel := if large then PsLevel.param motiveUniverse else .zero
  let parameters := psElabBinderArguments parameterBindersRev
  let (motiveContext, motivesRev) ← plan.members.foldlM
    (fun (state : PsElabContext × List PsElabTypedBinder) info => do
      let family := psExprApplyMany (.constE info.name (info.levelParams.map PsLevel.param)) parameters
      let indexType ← psElabMatchApplyParameters state.fst parameters info.type
      let indices ← psElabOpenCoreTelescope 4096 state.fst indexType (some info.numIndices)
      let indexedFamily := psExprApplyMany family (psElabBinderArguments indices.bindersRev)
      let motiveType := psCloseElabForallBinders state.fst.metaContext indices.bindersRev
        (.forallE (psRootName "_major") indexedFamily (.sortE motiveLevel) .explicit)
      let outer := psElabLeaveScope state.fst indices.context
      let name := if plan.members.length == 1 then psRootName "_motive"
        else psNameAppendNum (psRootName "_motive") state.snd.length
      let pushed := psLocalPushBinding outer.localContext name motiveType .explicit
      return (psElabContextWithLocal outer pushed.context,
        PsElabTypedBinder.mk pushed.id name motiveType .explicit :: state.snd)) (context, [])
  let motives := motivesRev.reverse
  let orderedNames := plan.members.flatMap (·.constructors)
  if constructors.length != orderedNames.length then throw (.data "inductive group constructor count mismatch")
  let ordered ← orderedNames.mapM fun name => do
    let some (.constructorDecl constructor) := constructors.find? (fun declaration =>
        psNameEq (psDeclarationName declaration) name)
      | throw (.data "missing inductive group constructor")
    return constructor
  let (minorContext, minorsRev) ← ordered.foldlM
    (fun (state : PsElabContext × List PsElabTypedBinder) constructor => do
      let type ← psElabDataMinor state.fst plan parameters motives constructor
      let name := psNameAppendNum (psRootName "_minor") state.snd.length
      let pushed := psLocalPushBinding state.fst.localContext name type .explicit
      return (psElabContextWithLocal state.fst pushed.context,
        PsElabTypedBinder.mk pushed.id name type .explicit :: state.snd)) (motiveContext, [])
  (plan.members.zip motives).mapM fun (info, motive) => do
    let family := psExprApplyMany (.constE info.name (info.levelParams.map PsLevel.param)) parameters
    let indexType ← psElabMatchApplyParameters minorContext parameters info.type
    let indices ← psElabOpenCoreTelescope 4096 minorContext indexType (some info.numIndices)
    let indexArgs := psElabBinderArguments indices.bindersRev
    let majorType := psExprApplyMany family indexArgs
    let majorName := psRootName "_major"
    let major := psLocalPushBinding indices.context.localContext majorName majorType .explicit
    let body := psExprApplyMany (.fvar motive.id) (indexArgs ++ [.fvar major.id])
    let type := psCloseElabImplicitBinders context.metaContext parameterBindersRev
      (psCloseElabForallBinders context.metaContext motivesRev
        (psCloseElabForallBinders context.metaContext minorsRev
          (psCloseElabImplicitBinders context.metaContext indices.bindersRev
            (psCloseElabForallBinders context.metaContext
              [PsElabTypedBinder.mk major.id majorName majorType .explicit] body))))
    if psExprHasUnresolvedMeta type then throw .unresolvedMetavariable
    return .recursorDecl {
      name := psNameAppendStr info.name "rec"
      levelParams := if large then motiveUniverse :: first.levelParams else first.levelParams
      type, inductiveNames := psInductiveGroupNames plan
      numParams := info.numParams, numIndices := info.numIndices
      numMotives := plan.members.length, numMinors := ordered.length }

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
    (levelNames : List PsName) : Except PsElabError PsElabInductiveHeader := do
  let some name := psSyntaxNameToName source.name | throw .emptyName
  let parameters ← psElabTypedBinders psElabTerm (psElabContextEmpty environment levelNames) source.params
  let result ← match source.resultType with
    | none => do
      let mut context := parameters.context
      let mut level := PsLevel.succ .zero
      if source.isStructure then
        for constructor in source.constructors do
          let fields ← psElabTypedBinders psElabTerm { context with collectInfo := false } constructor.fields
          for field in fields.bindersRev do
            let fieldLevel ← psElabExpressionSort fields.context field.type
            level := psLevelMax level fieldLevel
          context := psElabLeaveScope context fields.context
      pure (PsElabTypeResult.mk context (.sortE (psLevelNormalize level)))
    | some term => psElabType psElabTerm parameters.context term
  let indices ← psElabOpenCoreTelescope 4096 result.context result.type none
  match indices.body with
  | .sortE _ => pure ()
  | _ => throw (.data "data family must end in a sort")
  if source.isStructure && !indices.bindersRev.isEmpty then
    throw (.data "structure result must be a sort, not an indexed family")
  let type := psCloseElabForallBinders result.context.metaContext parameters.bindersRev result.type
  if psExprHasUnresolvedMeta type then throw .unresolvedMetavariable
  let names ← source.constructors.mapM fun constructor =>
    match psSyntaxConstructorCoreName name constructor.name with
    | some name => pure name
    | none => throw .emptyName
  if names.any (fun name => (names.filter (psNameEq name)).length > 1) then throw (.data "duplicate constructor")
  let info : PsInductiveInfo := {
    name, levelParams := psElabDeclarationLevels levelNames [type], type, numParams := parameters.bindersRev.length
    numIndices := indices.bindersRev.length, constructors := names, isStructure := source.isStructure }
  return { source, info, context := result.context, bindersRev := parameters.bindersRev }

def psElabInductiveGroupParameters (context : PsElabContext) (parameters : List PsExpr)
    (left right : PsExpr) : Except PsElabError Unit := do
  match parameters with
  | [] => return ()
  | parameter :: rest =>
    let left ← (psInferEnsureForall context.environment context.metaContext context.localContext left).mapError PsElabError.infer
    let right ← (psInferEnsureForall context.environment context.metaContext context.localContext right).mapError PsElabError.infer
    if !psBinderInfoEq left.binder right.binder ||
        !psDefEqReadOnlyWithEnv context.environment context.metaContext context.localContext left.domain right.domain then
      throw (.data "inductive group parameters must have compatible binder types and kinds")
    psElabInductiveGroupParameters context rest
      (psExprInstantiate1 left.body parameter) (psExprInstantiate1 right.body parameter)

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
  { bindersRev, context := { first.context with environment, infoRev := []
      localContext := { first.context.localContext with declarations } } }

-- Native group entry point. The existing .ps singleton/structure entry point
-- below uses this same pipeline. This does not expand v7.2's source mutual
-- grammar, which currently selects definition/function groups only.
def psElabInductiveGroup (environment : PsEnvironment)
    (sources : List PsElabInductiveSource) (levelNames : List PsName := []) :
    Except PsElabError PsElabDeclarationBatchResult := do
  if sources.length > 1 && sources.any (·.isStructure) then
    throw (.data "mutual structures require the group projection plan")
  let headers ← sources.mapM (psElabInductiveHeader environment · levelNames)
  let groupLevels := psElabDeclarationLevels levelNames (headers.map (·.info.type))
  let headers := headers.map fun header =>
    { header with info := { header.info with levelParams := groupLevels } }
  let first :: _ := headers | throw (.data "empty inductive group")
  let plan : PsInductiveGroupPlan := { members := headers.map (·.info) }
  if !psInductiveGroupHeaderShapeValid plan then throw (.data "incompatible inductive group headers")
  let names := plan.members.flatMap fun info =>
    info.name :: (psNameAppendStr info.name "rec" :: info.constructors)
  if names.any (fun name => (names.filter (psNameEq name)).length != 1) then
    throw (.data "duplicate inductive group member")
  let parameters := psElabBinderArguments first.bindersRev
  if headers.length > 1 then
    let level ← (psInductiveResultLevel environment first.info).mapError PsElabError.infer
    for header in headers.drop 1 do
      psElabInductiveGroupParameters first.context parameters first.info.type header.info.type
      let otherLevel ← (psInductiveResultLevel environment header.info).mapError PsElabError.infer
      if !psLevelEquivalent level otherLevel then
        throw (.data "inductive group members must have the same resulting universe")
  let declarations := plan.members.map PsDeclaration.inductiveDecl
  let withHeaders ← psAddDeclarationList environment declarations
  let (constructors, sourceInfo) ← headers.foldlM
    (fun (state : List PsDeclaration × List PsElabSourceInfo) header => do
      let common := psElabInductiveGroupContext first header withHeaders
      let (_, constructorsRev, receiptsRev) ← header.source.constructors.foldlM
        (fun (state : Nat × List PsDeclaration × List PsElabSourceInfo) source => do
          let (index, constructors, receipts) := state
          let (declaration, receipt) ← psElabDataConstructor common.context common.bindersRev
            plan header.info index source
          return (index + 1, declaration :: constructors, receipt :: receipts)) (0, [], [])
      return (state.fst ++ constructorsRev.reverse,
        state.snd ++ (psElabFinishSourceInfo header.context header.info.name :: receiptsRev.reverse))) ([], [])
  let withConstructors ← psAddDeclarationList withHeaders constructors
  let recursors ← psBuildInductiveGroupRecursors
    { first.context with environment := withConstructors } first.bindersRev plan constructors
  return { declarations := declarations ++ constructors ++ recursors, sourceInfo }

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

