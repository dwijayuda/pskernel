import Ps.Elab.Term
import Ps.Meta.Inductive
import Ps.Core.Nested

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
    (fuel : Nat) (context : PsElabContext) (info : PsInductiveInfo)
    (parameters : List PsExpr) (fieldType : PsExpr) :
    Except PsElabError Unit := do
  match fuel with
  | 0 => throw .fuelExhausted
  | remaining + 1 =>
    let fieldType := psWhnf context.environment context.metaContext
      context.localContext fieldType
    if !psExprHasConst info.name fieldType then return ()
    let view := psExprAppView fieldType
    let .constE head _ := view.head
      | throw (.data "unsupported recursive field; expected a positive direct family occurrence")
    if psNameEq head info.name then
      let _ ← psElabDataIndices context info parameters fieldType
      return ()
    let some selected := psSelectedNestedContainer? fieldType
      | throw (.data "unsupported recursive field; expected a positive direct family occurrence")
    for element in psSelectedNestedContainerElements selected do
      psElabValidateNestedRecursiveFieldWithFuel remaining context info
        parameters element

def psElabDataRecursiveFields (context : PsElabContext) (info : PsInductiveInfo)
    (parameters : List PsExpr) (fields : List PsElabTypedBinder) :
    Except PsElabError (List Nat) := do
  let (_, result) ← fields.foldlM (fun (state : Nat × List Nat) field => do
    let type := psWhnf context.environment context.metaContext context.localContext field.type
    let view := psExprAppView type
    let direct := match view.head with
      | .constE name _ => psNameEq name info.name
      | _ => false
    if direct then
      let _ ← psElabDataIndices context info parameters type
      return (state.fst + 1, state.fst :: state.snd)
    if psExprHasConst info.name type then
      if info.numIndices != 0 then
        throw (.data "unsupported recursive field; expected a positive direct family occurrence")
      psElabValidateNestedRecursiveFieldWithFuel 4096 context info parameters type
    return (state.fst + 1, state.snd)) (0, [])
  return result.reverse

def psElabDataConstructor (context : PsElabContext)
    (parameterBindersRev : List PsElabTypedBinder) (info : PsInductiveInfo)
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
  let recursiveFields ← psElabDataRecursiveFields result.context info parameters fields.bindersRev.reverse
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

def psElabDataMinor (context : PsElabContext) (info : PsInductiveInfo)
    (parameters : List PsExpr) (motive : PsExpr) (constructor : PsConstructorInfo) :
    Except PsElabError PsExpr := do
  let cursor ← psElabMatchApplyParameters context parameters constructor.type
  let fields ← psElabOpenCoreTelescope 4096 context cursor (some constructor.numFields)
  let args := psElabBinderArguments fields.bindersRev
  let intro := psExprApplyMany (.constE constructor.name (info.levelParams.map PsLevel.param)) (parameters ++ args)
  let conclusion ← psElabDataMotiveAt fields.context info parameters motive intro fields.body
  let fieldsInOrder := fields.bindersRev.reverse
  let hypotheses ← constructor.recursiveFields.mapM fun index => do
    let some field := fieldsInOrder[index]? | throw (.data "invalid recursive field metadata")
    psElabDataMotiveAt fields.context info parameters motive (.fvar field.id) field.type
  let body := (hypotheses.zip constructor.recursiveFields).foldr (fun entry body =>
    .forallE (psNameAppendNum (psRootName "_ih") entry.snd) entry.fst body .explicit) conclusion
  return psCloseElabForallBinders fields.context.metaContext fields.bindersRev body

def psBuildInductiveRecursor (context : PsElabContext)
    (parameterBindersRev : List PsElabTypedBinder) (info : PsInductiveInfo)
    (constructors : List PsDeclaration) : Except PsElabError PsDeclaration := do
  let large ← (psInductiveLargeElimination context.environment info).mapError PsElabError.infer
  let some motiveUniverse := (List.range (info.levelParams.length + 1)).map
      (psNameAppendNum (psRootName "_motiveUniverse")) |>.find?
        (fun name => !(info.levelParams.any (psNameEq name)))
    | throw (.data "cannot allocate motive universe")
  let motiveLevel := if large then PsLevel.param motiveUniverse else .zero
  let parameters := psElabBinderArguments parameterBindersRev
  let family := psExprApplyMany (.constE info.name (info.levelParams.map PsLevel.param)) parameters
  let indexType ← psElabMatchApplyParameters context parameters info.type
  let indices ← psElabOpenCoreTelescope 4096 context indexType (some info.numIndices)
  let indexedFamily := psExprApplyMany family (psElabBinderArguments indices.bindersRev)
  let motiveType := psCloseElabForallBinders context.metaContext indices.bindersRev
    (.forallE (psRootName "_major") indexedFamily (.sortE motiveLevel) .explicit)
  -- Index locals are scoped inside the motive; keep their IDs fresh for minors.
  let outer := psElabLeaveScope context indices.context
  let motive := psLocalPushBinding outer.localContext (psRootName "_motive") motiveType .explicit
  let motiveContext := psElabContextWithLocal outer motive.context
  let (minorContext, minorsRev) ← constructors.foldlM
    (fun (state : PsElabContext × List PsElabTypedBinder) declaration => do
      let .constructorDecl constructor := declaration | throw (.data "expected constructor")
      let type ← psElabDataMinor state.fst info parameters (.fvar motive.id) constructor
      let name := psNameAppendNum (psRootName "_minor") constructor.constructorIndex
      let pushed := psLocalPushBinding state.fst.localContext name type .explicit
      return (psElabContextWithLocal state.fst pushed.context,
        PsElabTypedBinder.mk pushed.id name type .explicit :: state.snd))
    (motiveContext, [])
  let indices ← psElabOpenCoreTelescope 4096 minorContext indexType (some info.numIndices)
  let indexArgs := psElabBinderArguments indices.bindersRev
  let majorType := psExprApplyMany family indexArgs
  let majorName := psRootName "_major"
  let major := psLocalPushBinding indices.context.localContext majorName majorType .explicit
  let body := psExprApplyMany (.fvar motive.id) (indexArgs ++ [.fvar major.id])
  let type := psCloseElabImplicitBinders context.metaContext parameterBindersRev
    (psCloseElabForallBinders context.metaContext
      [PsElabTypedBinder.mk motive.id (psRootName "_motive") motiveType .explicit]
      (psCloseElabForallBinders context.metaContext minorsRev
        (psCloseElabImplicitBinders context.metaContext indices.bindersRev
          (psCloseElabForallBinders context.metaContext
            [PsElabTypedBinder.mk major.id majorName majorType .explicit] body))))
  if psExprHasUnresolvedMeta type then throw .unresolvedMetavariable
  return .recursorDecl {
    name := psNameAppendStr info.name "rec"
    levelParams := if large then motiveUniverse :: info.levelParams else info.levelParams
    type
    inductiveNames := [info.name], numParams := info.numParams, numIndices := info.numIndices
    numMotives := 1, numMinors := constructors.length }

def psElabInductiveDeclaration (environment : PsEnvironment) (nameSyntax : PsSyntaxName)
    (params : List (PsSyntaxBinderHead × PsSyntaxTerm)) (resultType : Option PsSyntaxTerm)
    (constructors : List PsSyntaxInductiveConstructor) (isStructure : Bool)
    (levelNames : List PsName := []) :
    Except PsElabError PsElabDeclarationBatchResult := do
  let some name := psSyntaxNameToName nameSyntax | throw .emptyName
  let parameters ← psElabTypedBinders psElabTerm (psElabContextEmpty environment levelNames) params
  let result ← match resultType with
    | none => do
      let mut context := parameters.context
      let mut level := PsLevel.succ .zero
      if isStructure then
        for constructor in constructors do
          let fields ← psElabTypedBinders psElabTerm { context with collectInfo := false } constructor.fields
          for field in fields.bindersRev do
            let fieldLevel ← psElabExpressionSort fields.context field.type
            level := psLevelMax level fieldLevel
          context := psElabLeaveScope context fields.context
      pure (PsElabTypeResult.mk context (.sortE (psLevelNormalize level)))
    | some source => psElabType psElabTerm parameters.context source
  let indices ← psElabOpenCoreTelescope 4096 result.context result.type none
  match indices.body with
  | .sortE _ => pure ()
  | _ => throw (.data "data family must end in a sort")
  if isStructure && !indices.bindersRev.isEmpty then
    throw (.data "structure result must be a sort, not an indexed family")
  let type := psCloseElabForallBinders result.context.metaContext parameters.bindersRev result.type
  if psExprHasUnresolvedMeta type then throw .unresolvedMetavariable
  let names ← constructors.mapM fun source =>
    match psSyntaxConstructorCoreName name source.name with
    | some name => pure name
    | none => throw .emptyName
  if names.any (fun name => (names.filter (psNameEq name)).length > 1) then throw (.data "duplicate constructor")
  let info : PsInductiveInfo := {
    name, levelParams := psElabDeclarationLevels levelNames [type], type, numParams := parameters.bindersRev.length
    numIndices := indices.bindersRev.length, constructors := names, isStructure }
  let declaration := PsDeclaration.inductiveDecl info
  let withInductive ← psAddDeclarationList environment [declaration]
  let constructorContext := { result.context with environment := withInductive, infoRev := [] }
  let (_, declarationsRev, sourceInfoRev) ← constructors.foldlM
    (fun (state : Nat × List PsDeclaration × List PsElabSourceInfo) source => do
      let (index, declarations, sourceInfo) := state
      let (declaration, receipt) ←
        psElabDataConstructor constructorContext parameters.bindersRev info index source
      return (index + 1, declaration :: declarations, receipt :: sourceInfo)) (0, [], [])
  let declarations := declarationsRev.reverse
  let withConstructors ← psAddDeclarationList withInductive declarations
  let recursor ← psBuildInductiveRecursor
    { result.context with environment := withConstructors } parameters.bindersRev info declarations
  return {
    declarations := declaration :: (declarations ++ [recursor])
    sourceInfo := psElabFinishSourceInfo result.context name :: sourceInfoRev.reverse }

def psElabStructureDeclaration (environment : PsEnvironment) (name : PsSyntaxName)
    (params : List (PsSyntaxBinderHead × PsSyntaxTerm)) (resultType : Option PsSyntaxTerm)
    (fields : List (PsSyntaxBinderHead × PsSyntaxTerm)) (span : PsSourceSpan)
    (levelNames : List PsName := []) :
    Except PsElabError PsElabDeclarationBatchResult :=
  psElabInductiveDeclaration environment name params resultType
    [{ name := PsSyntaxName.mk ["mk"] span, fields, span }] true levelNames
