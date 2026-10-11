import Ps.Elab.Term

structure PsElabDeclarationBatchResult where
  declarations : List PsDeclaration

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

def psElabContainerRecursiveName (name : PsName) : Bool :=
  if psNameEq name psListName then
    true
  else if psNameEq name psOptionName then
    true
  else
    psNameEq name psArrayName

def psElabNestedRecursiveFieldTypeSupportedWithFuel
    (fuel : Nat) : PsName -> PsExpr -> Bool :=
  match fuel with
  | Nat.zero =>
      fun (_inductiveName : PsName) (_type : PsExpr) => false
  | Nat.succ remaining =>
      fun (inductiveName : PsName) (type : PsExpr) =>
        let smaller : PsName -> PsExpr -> Bool :=
          psElabNestedRecursiveFieldTypeSupportedWithFuel remaining;
        if psExprHasConst inductiveName type then
          let view := psExprAppView type;
          match view.head with
          | .constE name _ =>
              if psNameEq name inductiveName then
                true
              else if psElabContainerRecursiveName name then
                match view.args with
                | List.nil =>
                    false
                | List.cons argument rest =>
                    match rest with
                    | List.nil =>
                        smaller inductiveName argument
                    | List.cons _ _ =>
                        false
              else if psNameEq name psProdName then
                match view.args with
                | List.nil =>
                    false
                | List.cons left rest =>
                    match rest with
                    | List.nil =>
                        false
                    | List.cons right tail =>
                        match tail with
                        | List.nil =>
                            if smaller inductiveName left then
                              smaller inductiveName right
                            else
                              false
                        | List.cons _ _ =>
                            false
              else
                false
          | _ => false
        else
          true

def psElabNestedRecursiveFieldTypeSupported
    (inductiveName : PsName)
    (type : PsExpr) : Bool :=
  psElabNestedRecursiveFieldTypeSupportedWithFuel
    4096
    inductiveName
    type


-- Every occurrence must use the same uniform parameters. Indices are checked
-- by ordinary application elaboration and may vary between constructors/fields.
def psElabDataIndices (context : PsElabContext) (info : PsInductiveInfo)
    (parameters : List PsExpr) (type : PsExpr) : Except PsElabError (List PsExpr) := do
  let view := psExprAppView
    (psWhnf context.environment context.metaContext context.localContext type)
  let .constE name levels := view.head | throw (.data "constructor result must be its declared family")
  if !psNameEq name info.name || !levels.isEmpty then
    throw (.data "constructor result must be its declared family")
  if view.args.length != info.numParams + info.numIndices then
    throw (.data "family parameter/index arity mismatch")
  if !(parameters.zip (view.args.take info.numParams)).all (fun pair =>
      psDefEqReadOnlyWithEnv context.environment context.metaContext context.localContext
        pair.fst pair.snd) then
    throw (.data "constructor parameters must remain uniform")
  return view.args.drop info.numParams

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
      if info.numIndices != 0 ||
          !psElabNestedRecursiveFieldTypeSupported info.name type then
        throw (.data "unsupported recursive field; expected a positive direct family occurrence")
    return (state.fst + 1, state.snd)) (0, [])
  return result.reverse

def psElabDataConstructor (context : PsElabContext)
    (parameterBindersRev : List PsElabTypedBinder) (info : PsInductiveInfo)
    (index : Nat) (source : PsSyntaxInductiveConstructor) :
    Except PsElabError PsDeclaration := do
  let some name := psSyntaxConstructorCoreName info.name source.name | throw .emptyName
  let fields ← psElabTypedBinders psElabTerm context source.fields
  let parameters := psElabBinderArguments parameterBindersRev
  let result ← match source.resultType with
    | some type => psElabType psElabTerm fields.context type
    | none =>
      if info.numIndices != 0 then throw (.data "indexed constructor requires a result type")
      pure (PsElabTypeResult.mk fields.context (psExprApplyMany (.constE info.name []) parameters))
  let _ ← psElabDataIndices result.context info parameters result.type
  let recursiveFields ← psElabDataRecursiveFields result.context info parameters fields.bindersRev.reverse
  let type := psCloseElabImplicitBinders result.context.metaContext parameterBindersRev
    (psCloseElabForallBinders result.context.metaContext fields.bindersRev result.type)
  if psExprHasUnresolvedMeta type then throw .unresolvedMetavariable
  return .constructorDecl {
    name, levelParams := [], type, inductiveName := info.name, constructorIndex := index
    numParams := info.numParams, numFields := fields.bindersRev.length, recursiveFields }

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
  let intro := psExprApplyMany (.constE constructor.name []) (parameters ++ args)
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
  let motiveUniverse := psRootName "u"
  let parameters := psElabBinderArguments parameterBindersRev
  let family := psExprApplyMany (.constE info.name []) parameters
  let indexType ← psElabMatchApplyParameters context parameters info.type
  let indices ← psElabOpenCoreTelescope 4096 context indexType (some info.numIndices)
  let indexedFamily := psExprApplyMany family (psElabBinderArguments indices.bindersRev)
  let motiveType := psCloseElabForallBinders context.metaContext indices.bindersRev
    (.forallE (psRootName "_major") indexedFamily (.sortE (.param motiveUniverse)) .explicit)
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
    name := psNameAppendStr info.name "rec", levelParams := [motiveUniverse], type
    inductiveNames := [info.name], numParams := info.numParams, numIndices := info.numIndices
    numMotives := 1, numMinors := constructors.length }

def psElabInductiveDeclaration (environment : PsEnvironment) (nameSyntax : PsSyntaxName)
    (params : List (PsSyntaxBinderHead × PsSyntaxTerm)) (resultType : Option PsSyntaxTerm)
    (constructors : List PsSyntaxInductiveConstructor) (isStructure : Bool) :
    Except PsElabError PsElabDeclarationBatchResult := do
  let some name := psSyntaxNameToName nameSyntax | throw .emptyName
  let parameters ← psElabTypedBinders psElabTerm (psElabContextEmpty environment) params
  let result ← match resultType with
    | none => pure (PsElabTypeResult.mk parameters.context (.sortE (.succ .zero)))
    | some source => psElabType psElabTerm parameters.context source
  let indices ← psElabOpenCoreTelescope 4096 result.context result.type none
  match indices.body with
  | .sortE (.succ .zero) => pure ()
  | _ => throw (.data "data family must end in Type; universe/Prop families are pending")
  let type := psCloseElabForallBinders result.context.metaContext parameters.bindersRev result.type
  if psExprHasUnresolvedMeta type then throw .unresolvedMetavariable
  let names ← constructors.mapM fun source =>
    match psSyntaxConstructorCoreName name source.name with
    | some name => pure name
    | none => throw .emptyName
  if names.any (fun name => (names.filter (psNameEq name)).length > 1) then throw (.data "duplicate constructor")
  let info : PsInductiveInfo := {
    name, levelParams := [], type, numParams := parameters.bindersRev.length
    numIndices := indices.bindersRev.length, constructors := names, isStructure }
  let declaration := PsDeclaration.inductiveDecl info
  let withInductive ← psAddDeclarationList environment [declaration]
  let constructorContext := { result.context with environment := withInductive }
  let (_, declarationsRev) ← constructors.foldlM
    (fun (state : Nat × List PsDeclaration) source => do
      let declaration ← psElabDataConstructor constructorContext parameters.bindersRev info state.fst source
      return (state.fst + 1, declaration :: state.snd)) (0, [])
  let declarations := declarationsRev.reverse
  let withConstructors ← psAddDeclarationList withInductive declarations
  let recursor ← psBuildInductiveRecursor
    { result.context with environment := withConstructors } parameters.bindersRev info declarations
  return { declarations := declaration :: (declarations ++ [recursor]) }

def psElabStructureDeclaration (environment : PsEnvironment) (name : PsSyntaxName)
    (params fields : List (PsSyntaxBinderHead × PsSyntaxTerm)) (span : PsSourceSpan) :
    Except PsElabError PsElabDeclarationBatchResult :=
  psElabInductiveDeclaration environment name params none
    [{ name := PsSyntaxName.mk ["mk"] span, fields, span }] true
