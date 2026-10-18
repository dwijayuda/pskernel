import Ps.Elab.WhereWellFounded
import Ps.Elab.PreDefinition
import Ps.Meta.MutualWellFounded

/-!
Source-owned components for Lean4.35.0-style mutual WF construction.
Pinned PreDefinition/FixedParams, WF/{PackMutual,Rel,Fix} and Meta/ArgsPacker
own the reference algorithms. See THIRD_PARTY_NOTICES.md.
This stage preserves the original source telescope and independently checked
retained calls. It constructs logical functionals, exact equations and checked ordinary runtime
bodies. Independent compiler ownership validation is still required for execution.
-/

structure PsElabWhereWellFoundedComponentMember where
  source : PsElabPreDefinition
  input : PsElabWhereWellFoundedInput
  sourceInput : PsElabWhereWellFoundedInput
  extraBindersRev : List PsElabTypedBinder := []
  permutation : List (Option Nat)
  specialized : PsElabRecursionSpecializedHeader
  varyingNames : List PsName
  unaryType : PsExpr
  measure : PsExpr
  measureCodomain : PsExpr

structure PsElabWhereWellFoundedComponent where
  context : PsElabContext
  fixedBindersRev : List PsElabTypedBinder
  parameters : PsFixedParameterPlan
  members : List PsElabWhereWellFoundedComponentMember
  plan : PsMutualWellFoundedPlan

-- Resolve each source measure in its original header, before peers/helpers
-- gain recursive authority. Close all original binders before moving it into
-- the common fixed scope; numeric IDs from separate headers never correspond.
def psElabWhereCloseWellFoundedMeasure (levels : List PsName)
    (member : PsElabPreDefinition) (input : PsElabWhereWellFoundedInput) :
    Except PsElabError PsExpr := do
  let context := input.header.context
  let measured ← psElabTerm context input.termination.measure none
  let _ ← psElabExpressionSort measured.context measured.type
  let normalize := fun term =>
    psElabGeneralizeExpr (psMetaInstantiate measured.context.metaContext term)
  let bindersRev := (input.header.parametersRev ++ input.header.capturesRev).map
    fun binder => { binder with type := normalize binder.type }
  let sourceType := psCloseElabForallBinders psMetaEmpty bindersRev
    (normalize input.header.resultType)
  if !psExprAlphaEq sourceType member.type then
    throw (psElabWhereError "WF-IDENTITY" "measure elaboration changed the original closed header")
  let measure := psCloseElabLambdaBinders psMetaEmpty bindersRev (normalize measured.term)
  for value in [measure] do
    if psExprHasUnresolvedMeta value || !psExprFVarsInContext psLocalEmpty value ||
        !(psElabDeclarationLevels levels [value]).all (fun used => levels.any (psNameEq used)) then
      throw (psElabWhereError "WF-MEASURE" "component measure escaped its original header or universes")
    let _ ← psElabResolvedTerm (psElabContextEmpty context.environment levels) value none
    pure ()
  return measure

-- Keep source hint scope and the checked operational value prefix separate.
-- The extra prefix is read only after the original measure has been checked.
structure PsElabWhereWellFoundedOperationalInput where
  source : PsElabPreDefinition
  sourceInput : PsElabWhereWellFoundedInput
  input : PsElabWhereWellFoundedInput
  extraBindersRev : List PsElabTypedBinder
  analysis : PsElabWellFoundedOperationalBody
  closedMeasure : PsExpr

def psElabWhereWellFoundedOperationalInputFor (prepared : PsElabWherePrepared)
    (environment : PsEnvironment) (levels : List PsName) (nextId : Nat)
    (members : List PsElabPreDefinition) (member : PsElabPreDefinition) :
    Except PsElabError PsElabWhereWellFoundedOperationalInput := do
  let sourceInput ← psElabWherePrepareWellFounded prepared environment levels member
  let closedMeasure ← psElabWellFoundedAt "component measure"
    (psElabWhereCloseWellFoundedMeasure levels member sourceInput)
  let original := sourceInput.header
  let parameters := original.capturesRev.reverse ++ original.parametersRev.reverse
  let peerIds := members.map (·.peerId)
  if peerIds.eraseDups.length != peerIds.length ||
      peerIds.any (fun id => (psLocalFindById original.context.localContext id).isSome) then
    throw (psElabWhereError "WF-IDENTITY" "operational analysis has overlapping source and peer identities")
  let bodyLocals := original.bodyLocalContext.getD original.context.localContext
  let start := max nextId (max original.context.localContext.nextId bodyLocals.nextId)
  let peerDeclarations := members.map fun source =>
    PsLocalDecl.binding source.peerId source.name source.type .explicit
  let context := { original.context with
    localContext := { original.context.localContext with
      nextId := start
      declarations := peerDeclarations ++ original.context.localContext.declarations }
    auxiliaryLocalIds := peerIds ++ original.context.auxiliaryLocalIds
    coreBoundaries := prepared.context.coreBoundaries }
  if psExprHasUnresolvedMeta member.type || psExprHasUnresolvedMeta member.value ||
      !psExprFVarsInContext psLocalEmpty member.type ||
      !psExprFVarsInContext context.localContext member.value then
    throw (psElabWhereError "WF-CLOSURE" "operational analysis contains unresolved or unowned retained Core")
  let _ ← psElabResolvedTerm context member.value (some member.type)
  let retained ← psElabPreDefinitionOpen (psElabPreDefinitionHeaderCount member)
    context member.type member.value
  if retained.bindersRev.length != parameters.length then
    throw (psElabWhereError "WF-IDENTITY" "operational analysis changed the original capture/header count")
  let replacements := (retained.bindersRev.reverse.map (·.id)).zip
    (parameters.map fun binder => PsExpr.fvar binder.id)
  let sourceBody := psElabSubstituteLocals replacements retained.value
  let sourceType := psElabSubstituteLocals replacements retained.type
  let context := { context with localContext := { context.localContext with
    nextId := retained.context.localContext.nextId } }
  if !psDefEqReadOnlyWithEnv environment context.metaContext context.localContext
      sourceType original.resultType then
    throw (psElabWhereError "WF-IDENTITY" "retained source result changed during typed reopening")
  let operational ← psElabWellFoundedOpenBodyParameters 4096
    context original.resultType sourceBody
  let normalize := psMetaInstantiate operational.context.metaContext
  let extraBindersRev := operational.bindersRev.map fun binder =>
    { binder with type := normalize binder.type }
  let resultType := normalize operational.type
  let allBinders := extraBindersRev ++ original.parametersRev ++ original.capturesRev
  let completeType := psCloseElabForallBinders psMetaEmpty allBinders resultType
  if psExprHasUnresolvedMeta completeType || !psExprFVarsInContext psLocalEmpty completeType ||
      !psDefEqReadOnlyWithEnv environment psMetaEmpty psLocalEmpty completeType member.type then
    throw (psElabWhereError "WF-IDENTITY" "operational value prefix changed the complete source type")
  let addExtras := fun (locals : PsLocalContext) =>
    if extraBindersRev.isEmpty then locals else
      { locals with
        declarations := extraBindersRev.map psElabWhereBinderDeclaration ++ locals.declarations
        nextId := max locals.nextId operational.context.localContext.nextId }
  let input := if extraBindersRev.isEmpty then sourceInput else {
    sourceInput with
    header := {
      original with
      context := { original.context with localContext := addExtras original.context.localContext }
      parametersRev := extraBindersRev ++ original.parametersRev
      resultType
      bodyLocalContext := original.bodyLocalContext.map addExtras } }
  for binder in extraBindersRev do
    if !psMetaExprScopeSafe input.header.context.metaContext
        input.header.context.localContext binder.type then
      throw (psElabWhereError "WF-CLOSURE" "an operational argument type retained a provisional peer")
  return {
    source := member
    sourceInput
    input
    extraBindersRev
    closedMeasure
    analysis := { operational with
      bindersRev := extraBindersRev
      type := resultType
      body := normalize operational.body } }

def psElabWhereWellFoundedOperationalOwners
    (inputs : List PsElabWhereWellFoundedOperationalInput) :
    Except PsElabError (List PsElabRecursionParameterOwner) :=
  inputs.mapM fun input => do
    let (context, calls) ← inputs.foldlM
      (fun (state : PsElabContext × List PsElabRecursionCall) target => do
        let arity := target.input.header.capturesRev.length +
          target.input.header.parametersRev.length
        let (context, calls) ← psElabWellFoundedCollectCoreCalls 4096 state.fst
          target.source.name target.source.peerId arity
          (psElabPreDefinitionSourceSpan input.source) input.analysis.body
        return (context, state.snd ++ calls)) (input.analysis.context, [])
    return {
      name := input.source.name
      context
      calls
      parameterIds := (input.input.header.capturesRev.reverse ++
        input.input.header.parametersRev.reverse).map (·.id) }

def psElabWherePrepareWellFoundedComponent (prepared : PsElabWherePrepared)
    (environment : PsEnvironment) (levels : List PsName)
    (members : List PsElabPreDefinition) :
    Except PsElabError PsElabWhereWellFoundedComponent := do
  let first :: _ := members
    | throw (psElabWhereError "WF-COMPONENT" "empty measured component")
  if members.any (fun member => !psElabPreDefinitionStrategyEq member.strategy .wellFounded) then
    throw (psElabWhereError "WF-STRATEGY" "every selected component member requires its own total measure")
  let nextId := max prepared.context.localContext.nextId prepared.block.context.localContext.nextId
  let operationalInputs ← members.mapM
    (psElabWhereWellFoundedOperationalInputFor prepared environment levels nextId members)
  let hasExtra := operationalInputs.any (fun input => !input.extraBindersRev.isEmpty)
  let owners ← if hasExtra then
    psElabWhereWellFoundedOperationalOwners operationalInputs
  else
    psElabPreDefinitionParameterOwners environment levels nextId members
  let nextId := if hasExtra then
    operationalInputs.foldl (fun current input =>
      max current input.analysis.context.localContext.nextId) nextId
    else nextId
  let parameters ← psElabRecursionComponentFixedParameterPlan owners
  let some firstPermutation := parameters.permutations.head?
    | throw (psElabWhereError "WF-COMPONENT" "fixed parameter analysis lost its first owner")
  let initial := { psElabContextEmpty environment levels with
    localContext := { psLocalEmpty with nextId } }
  let fixed ← psElabRecursionOpenFixedScope initial first.type firstPermutation parameters.count
  let fixedValues := psElabBinderArguments fixed.bindersRev
  let fixedIds := fixed.bindersRev.map (·.id)
  let measuredMembers ← (operationalInputs.zip parameters.permutations).mapM fun (owned, permutation) => do
    let member := owned.source
    let input := owned.input
    let closedMeasure := owned.closedMeasure
    let specialized ← psElabRecursionSpecializeHeader fixed.context member.type permutation fixedValues
    let names := specialized.bindersRev.reverse.map (·.name)
    if names.isEmpty then
      throw (.atContext "well-founded fixed parameters"
        (psElabWhereError "WF-TELESCOPE" "the selected component packing requires a varying source parameter"))
    let measureBody := psWhnfCore psMetaEmpty specialized.context.localContext
      (psReduceApply closedMeasure
        (specialized.arguments.take (psElabPreDefinitionHeaderCount member)))
    let checked ← psElabResolvedTerm specialized.context measureBody none
    let measureCodomain := psWhnfCore checked.context.metaContext
      checked.context.localContext checked.type
    if psExprHasUnresolvedMeta checked.term || psExprHasUnresolvedMeta measureCodomain ||
        !(psExprFVarIds measureCodomain).all fixedIds.contains then
      throw (psElabWhereError "WF-RELATION" "component measure codomain depends on changing arguments")
    let measureType := psCloseElabForallBinders checked.context.metaContext
      specialized.bindersRev measureCodomain
    let measureValue := psCloseElabLambdaBinders checked.context.metaContext
      specialized.bindersRev checked.term
    let unaryType ← (psWellFoundedTupleUncurryType environment psMetaEmpty
      fixed.context.localContext names specialized.type).mapError PsElabError.infer
    let unaryMeasureType ← (psWellFoundedTupleUncurryType environment psMetaEmpty
      fixed.context.localContext names measureType).mapError PsElabError.infer
    let measure ← (psWellFoundedTupleUncurry environment psMetaEmpty
      fixed.context.localContext names unaryMeasureType measureValue).mapError PsElabError.infer
    for value in [unaryType, measure, measureCodomain] do
      if psExprHasUnresolvedMeta value || !psExprFVarsInContext fixed.context.localContext value then
        throw (psElabWhereError "WF-SCOPE" "packed measure retained a member-local identity")
    let result : PsElabWhereWellFoundedComponentMember := {
      source := member
      input
      sourceInput := owned.sourceInput
      extraBindersRev := owned.extraBindersRev
      permutation
      specialized
      varyingNames := names
      unaryType
      measure
      measureCodomain }
    return result
  if measuredMembers.length != members.length then
    throw (psElabWhereError "WF-COMPONENT" "fixed parameter plan changed component arity")
  let some firstMeasured := measuredMembers.head?
    | throw (psElabWhereError "WF-COMPONENT" "component lost its first checked measure")
  for member in measuredMembers do
    if !psWellFoundedDefEq environment psMetaEmpty fixed.context.localContext
        member.measureCodomain firstMeasured.measureCodomain then
      throw (psElabWhereError "WF-RELATION" "component members have different measure codomains")
  -- Pinned WF/Rel.elabWFRel synthesizes once, after checkCodomains. Only
  -- common fixed locals can participate; varying local instances are absent.
  let level ← psElabExpressionSort fixed.context firstMeasured.measureCodomain
  let dictionary ← psElabSynthesizeInstance fixed.context
    (.app (.constE psWellFoundedRelationName [level]) firstMeasured.measureCodomain)
  let dictionaryValue := psElabGeneralizeExpr
    (psMetaInstantiate dictionary.context.metaContext dictionary.term)
  if psExprHasUnresolvedMeta dictionaryValue ||
      !psExprFVarsInContext fixed.context.localContext dictionaryValue then
    throw (psElabWhereError "WF-RELATION" "common relation dictionary is unresolved or escapes the fixed scope")
  let plan ← (psMutualWellFoundedPlanFor environment psMetaEmpty fixed.context.localContext
    (measuredMembers.map (·.unaryType)) (measuredMembers.map (·.measure))
    dictionaryValue).mapError PsElabError.infer
  return { context := fixed.context, fixedBindersRev := fixed.bindersRev
           parameters, members := measuredMembers, plan }


-- Instantiate a component's common fixed prefix in this original source
-- header. The permutation, not local-number equality across owners, supplies
-- correspondence; all resulting terms are checked in the caller's context.
def psElabWhereComponentFixedArguments
    (member : PsElabWhereWellFoundedComponentMember) (count : Nat) :
    Except PsElabError (List PsExpr) := do
  psElabRecursionValidatePermutation member.permutation count
  let parameters := member.input.header.capturesRev.reverse ++
    member.input.header.parametersRev.reverse
  if parameters.length != member.permutation.length then
    throw (psElabWhereError "WF-HEADER" "component permutation lost an original source slot")
  (List.range count).mapM fun index => do
    let some (parameter, _) := (parameters.zip member.permutation).find?
      (fun (_, position) => position == some index)
      | throw (psElabWhereError "WF-FIXED" "component fixed parameter has no source owner")
    return .fvar parameter.id

-- A final body may refine its current arguments and introduce argument lets.
-- Validate every fixed target slot in that actual call context. A body cannot
-- gain authority merely because an earlier retained-call analysis passed.
def psElabWhereComponentValidateCalls (component : PsElabWhereWellFoundedComponent)
    (fixed : List PsExpr) (context : PsElabContext) :
    Except PsElabError Unit := do
  for call in context.wellFoundedCallsRev do
    let some target := component.members.find? (fun target =>
        psNameEq target.input.header.functionName call.callee)
      | throw (psElabWhereError "WF-CALL" "recursive call has no owned component target")
    if call.arguments.length != target.permutation.length then
      throw (psElabWhereError "WF-CALL" "recursive call changed its original header arity")
    for (argument, position) in call.arguments.zip target.permutation do
      if let some index := position then
        let some expected := fixed[index]?
          | throw (psElabWhereError "WF-FIXED" "recursive call lost a common fixed slot")
        if !psDefEqReadOnlyWithTransparency .reducible context.environment
            context.metaContext call.localContext expected argument then
          throw (psElabWhereError "WF-FIXED" "recursive call changes a common fixed argument")

structure PsElabWhereWellFoundedComponentBody where
  branch : PsExpr
  sourceInfo : PsElabSourceInfo

-- Check each source body against its original typed peer telescope. The Core
-- phase specializes actual compiled alternatives and only then introduces
-- decrease goals for the proof-restricted callbacks at the current injection.
def psElabWhereWellFoundedComponentBody
    (component : PsElabWhereWellFoundedComponent) (index : Nat) :
    Except PsElabError PsElabWhereWellFoundedComponentBody := do
  let some member := component.members[index]?
    | throw (psElabWhereError "WF-COMPONENT" "body has no positional component owner")
  let header := member.input.header
  let (headerContext, bodyLocals, aliases) ← psElabWellFoundedHeaderScope header
  let environment := headerContext.environment
  let fixed ← psElabWhereComponentFixedArguments member component.parameters.count
  let replacements := (component.fixedBindersRev.reverse.map (·.id)).zip fixed
  let instantiate := psElabSubstituteLocals replacements
  let branchType ← (psMutualWellFoundedBranchType environment psMetaEmpty
    component.context.localContext component.plan index).mapError PsElabError.infer
  let branchType := instantiate branchType
  let branchParameter ← (psInferEnsureForall environment headerContext.metaContext
    headerContext.localContext branchType).mapError PsElabError.infer
  let parameters := header.capturesRev.reverse ++ header.parametersRev.reverse
  let varying := (parameters.zip member.permutation).filterMap fun (parameter, position) =>
    if position.isNone then some parameter else none
  let current ← (psWellFoundedTuplePack branchParameter.domain
    (varying.map fun parameter => .fvar parameter.id)).mapError PsElabError.infer
  let callbackParameter ← (psInferEnsureForall environment headerContext.metaContext
    headerContext.localContext (psExprInstantiate1 branchParameter.body current)).mapError
      PsElabError.infer
  let callbackType := callbackParameter.domain
  let rawName := psNameAppendNum (psRootName "_psc0ComponentCallback") bodyLocals.nextId
  let raw := psLocalPushBinding bodyLocals rawName callbackType .explicit
  -- The raw callback exists only in adapter construction. Source syntax sees
  -- named, typed per-callee callbacks, never the unrestricted aggregate value.
  let mut bodyContext := { headerContext with
    localContext := { bodyLocals with nextId := raw.context.nextId }
    structuralRecursion := none, wellFoundedRecursions := []
    wellFoundedGoalsRev := [], wellFoundedCallsRev := [] }
  let mut adapters : List (Nat × PsName × PsExpr × PsExpr) := []
  let mut coreCalls : List PsElabWellFoundedCoreCall := []
  for (target, targetIndex) in component.members.zipIdx do
    let projectedType ← (psMutualPackingProjectionType environment headerContext.metaContext
      bodyContext.localContext component.members.length targetIndex callbackType).mapError PsElabError.infer
    let sourceType ← (psWellFoundedTupleCurryType environment headerContext.metaContext
      bodyContext.localContext target.varyingNames projectedType).mapError PsElabError.infer
    let adapterLocals := { bodyContext.localContext with
      declarations := PsLocalDecl.binding raw.id rawName callbackType .explicit ::
        bodyContext.localContext.declarations }
    let projected ← (psMutualPackingProjection environment headerContext.metaContext adapterLocals
      component.members.length targetIndex (.fvar raw.id)).mapError PsElabError.infer
    let adapter ← (psWellFoundedTupleCurryCallback environment headerContext.metaContext
      adapterLocals target.varyingNames sourceType projected).mapError PsElabError.infer
    let callbackName := psNameAppendNum (psRootName "_psc0ComponentTarget")
      bodyContext.localContext.nextId
    let callback := psLocalPushBinding bodyContext.localContext callbackName sourceType .explicit
    let sourceName := psNameAppendNum (psRootName "_psc0ComponentSource")
      callback.context.nextId
    let source := psLocalPushBinding callback.context sourceName target.source.type .explicit
    let targetParameters := target.input.header.capturesRev.reverse ++
      target.input.header.parametersRev.reverse
    let capturedNames ← target.input.header.capturesRev.reverse.mapM fun capture => do
      let some actual := psLocalFindById bodyLocals capture.id
        | throw (psElabWhereError "WF-CAPTURE" "target capture is absent from the caller's original source scope")
      return match actual with
        | .binding _ name _ _ | .letDecl _ name _ _ => name
    let packedIds := (targetParameters.zip target.permutation).filterMap
      fun (parameter, position) => if position.isNone then some parameter.id else none
    let some majorId := packedIds.head?
      | throw (psElabWhereError "WF-TELESCOPE" "component target has no varying source parameter")
    let fixedArguments ← (targetParameters.zip target.permutation).foldlM
      (fun (values : List (Nat × PsExpr)) (parameter, position) => do
        match position with
        | none => pure values
        | some index =>
          let some expected := fixed[index]?
            | throw (psElabWhereError "WF-FIXED" "target lost its actual caller fixed slot")
          return values ++ [(parameter.id, expected)]) []
    let recursion : PsElabWellFoundedRecursion := {
      functionName := target.input.header.functionName, callbackName
      parameterIds := targetParameters.map (·.id), majorId, packedIds
      fixedIds := fixedArguments.map Prod.fst
      sourceType := some target.source.type, capturedNames }
    bodyContext := { bodyContext with
      localContext := source.context
      auxiliaryLocalIds := source.id :: callback.id :: bodyContext.auxiliaryLocalIds
      wellFoundedRecursions := bodyContext.wellFoundedRecursions ++ [
        { recursion with
          callbackName := sourceName, collectCalls := true
          parameterIds := (target.sourceInput.header.capturesRev.reverse ++
            target.sourceInput.header.parametersRev.reverse).map (·.id) }] }
    coreCalls := coreCalls ++ [{
      sourceId := source.id
      callback := .fvar callback.id
      recursion
      fixedArguments
      sourceArity? := some (psElabPreDefinitionHeaderCount target.source)
      span := psSyntaxTermSpan member.input.body }]
    adapters := adapters ++ [(callback.id, callbackName, sourceType, adapter)]
  let hiddenIds := if member.extraBindersRev.isEmpty then [] else
    adapters.map (fun adapter => adapter.fst) ++ member.extraBindersRev.map (·.id)
  let sourceContext ← psElabWellFoundedHideOperationalScope bodyContext hiddenIds
  let value ← psElabWellFoundedAt "component source body"
    (psElabTerm sourceContext member.input.body (some member.sourceInput.header.resultType))
  let restored ← psElabWellFoundedRestoreOperationalScope bodyContext value.context hiddenIds
  let value := { value with context := restored }
  let value ← psElabWellFoundedAt "component operational body"
    (psElabWellFoundedApplyBodyParameters value.context member.extraBindersRev
      member.sourceInput.header.resultType value.term header.resultType)
  let value ← if component.members.all (fun member => member.extraBindersRev.isEmpty) then
    pure value
  else do
    let (context, calls) ← coreCalls.foldlM
      (fun (state : PsElabContext × List PsElabRecursionCall) call => do
        let (context, calls) ← psElabWellFoundedCollectCoreCalls 4096 state.fst
          call.recursion.functionName call.sourceId call.recursion.parameterIds.length
          call.span value.term
        return (context, state.snd ++ calls)) (value.context, [])
    pure { value with context := { context with wellFoundedCallsRev := calls.reverse } }
  psElabWhereComponentValidateCalls component fixed value.context
  let value ← psElabWellFoundedAt "compiled component recursive calls"
    (psElabWellFoundedCoreCalls value.context coreCalls value.term header.resultType)
  let solved ← psElabWellFoundedAt "component decrease goals"
    (psElabWellFoundedSolveGoals psElabTerm value.context member.input.termination.decreasing)
  let normalize := fun term =>
    psElabGeneralizeExpr (psMetaInstantiate solved.metaContext term)
  let body := psElabSubstituteLocals (aliases.map fun (id, term) => (id, normalize term))
    (normalize value.term)
  let body := adapters.foldr (fun (id, name, type, adapter) body =>
    PsExpr.letE name (normalize type) (normalize adapter) (psExprAbstractFVar id body)) body
  let body := PsExpr.lam rawName (normalize callbackType) (psExprAbstractFVar raw.id body) .explicit
  let parametersRev := (header.parametersRev ++ header.capturesRev).map
    fun binder => { binder with type := normalize binder.type }
  let closed := psCloseElabLambdaBinders psMetaEmpty parametersRev body
  if psExprHasUnresolvedMeta closed || !psExprFVarsInContext psLocalEmpty closed ||
      !(psElabDeclarationLevels component.context.levelNames [closed]).all
        (fun used => component.context.levelNames.any (psNameEq used)) then
    throw (psElabWhereError "WF-CLOSURE" "component source body retained an unowned local, proof hole or universe")
  let _ ← psElabResolvedTerm (psElabContextEmpty environment component.context.levelNames) closed none
  let specialized := psReduceApply closed member.specialized.arguments
  let source := psCloseElabLambdaBinders psMetaEmpty member.specialized.bindersRev specialized
  let expected ← (psMutualWellFoundedBranchType environment psMetaEmpty
    component.context.localContext component.plan index).mapError PsElabError.infer
  let branch ← (psWellFoundedTupleUncurry environment psMetaEmpty component.context.localContext
    member.varyingNames expected source).mapError PsElabError.infer
  let _ ← psElabResolvedTerm component.context branch (some expected)
  return { branch, sourceInfo := psElabFinishSourceInfo solved member.source.name }


-- Reconstruct public source telescopes from the checked packed fixedpoint.
-- This does not flatten a returned function or confuse a source PSigma/PSum
-- with compiler-owned packing. The independent PreDefinition owner below
-- reconstructs exact RHS equations from retained source Core.
def psElabWhereFinishWellFoundedComponent
    (component : PsElabWhereWellFoundedComponent)
    (bodies : List PsElabWhereWellFoundedComponentBody)
    (built : PsMutualWellFoundedValue) :
    Except PsElabError PsElabPreDefinitionWellFoundedConstruction := do
  if bodies.length != component.members.length then
    throw (psElabWhereError "WF-COMPONENT" "body construction changed component arity")
  let levels := component.context.levelNames
  let some first := component.members.head?
    | throw (psElabWhereError "WF-COMPONENT" "empty component has no auxiliary owner")
  let auxiliaryName := psNameAppendStr first.source.name "_mutual"
  let auxiliary := PsDeclaration.definitionDecl auxiliaryName levels
    (psCloseElabForallBinders psMetaEmpty component.fixedBindersRev component.plan.type)
    (psCloseElabLambdaBinders psMetaEmpty component.fixedBindersRev built.value)
  let environment ← psAddDeclarationList component.context.environment [auxiliary]
  let definitions ← (component.members.zipIdx).mapM fun (member, index) => do
    let header := member.input.header
    let fixed ← psElabWhereComponentFixedArguments member component.parameters.count
    let replacements := (component.fixedBindersRev.reverse.map (·.id)).zip fixed
    let instantiate := psElabSubstituteLocals replacements
    let projected ← (psMutualPackingProjection environment psMetaEmpty
      header.context.localContext component.members.length index
      (psExprApplyMany (.constE auxiliaryName (levels.map PsLevel.param)) fixed)).mapError
        PsElabError.infer
    let curried ← (psWellFoundedTupleCurry environment psMetaEmpty header.context.localContext
      member.varyingNames (instantiate member.specialized.type) projected).mapError PsElabError.infer
    let parameters := header.capturesRev.reverse ++ header.parametersRev.reverse
    let arguments := (parameters.zip member.permutation).filterMap fun (parameter, position) =>
      if position.isNone then some (PsExpr.fvar parameter.id) else none
    let value := psCloseElabLambdaBinders psMetaEmpty (header.parametersRev ++ header.capturesRev)
      (psReduceApply curried arguments)
    let _ ← psElabWellFoundedChecked "closed component projection"
      (psElabContextEmpty environment levels) value member.source.type
    return PsDeclaration.definitionDecl member.source.name levels member.source.type value
  let staged ← psAddDeclarationList environment definitions
  let results ← ((component.members.zip bodies).zip definitions).zipIdx.mapM
    fun (((member, body), declaration), index) => do
      let header := member.input.header
      let context := { header.context with environment := staged, metaContext := psMetaEmpty }
      let fixed ← psElabWhereComponentFixedArguments member component.parameters.count
      let replacements := (component.fixedBindersRev.reverse.map (·.id)).zip fixed
      let instantiate := psElabSubstituteLocals replacements
      let parameter ← (psInferEnsureForall staged psMetaEmpty context.localContext
        (instantiate component.plan.type)).mapError PsElabError.infer
      let unary ← (psInferEnsureForall staged psMetaEmpty context.localContext
        (instantiate member.unaryType)).mapError PsElabError.infer
      let parameters := header.capturesRev.reverse ++ header.parametersRev.reverse
      let varying := (parameters.zip member.permutation).filterMap fun (parameter, position) =>
        if position.isNone then some (PsExpr.fvar parameter.id) else none
      let tuple ← (psWellFoundedTuplePack unary.domain varying).mapError PsElabError.infer
      let current ← (psMutualPackingPack component.members.length parameter.domain index tuple).mapError
        PsElabError.infer
      let domainLevel ← psElabExpressionSort context parameter.domain
      let resultLevel ← psElabExpressionSort context header.resultType
      let motive := PsExpr.lam parameter.name parameter.domain parameter.body parameter.binder
      let proof := psWellFoundedEquation (psWellFoundedPlanMap instantiate component.plan.relation)
        [domainLevel, resultLevel] motive (instantiate built.functional) current
      let checked ← psElabResolvedTerm context proof none
      let (equationType, equationValue) ← if member.extraBindersRev.isEmpty then
        pure (checked.type, checked.term)
      else do
        let actual ← psElabRecursorEquationView checked.context checked.type
        let left := psCloseElabLambdaBinders psMetaEmpty member.extraBindersRev actual.left
        let right := psCloseElabLambdaBinders psMetaEmpty member.extraBindersRev actual.right
        let pointwise := psCloseElabLambdaBinders psMetaEmpty member.extraBindersRev checked.term
        let sourceType := member.sourceInput.header.resultType
        let proof ← psElabWellFoundedPointwiseEquation member.extraBindersRev.length
          checked.context sourceType left right pointwise
        let level ← psElabExpressionSort checked.context sourceType
        pure (psLogicEq level sourceType left right, proof)
      let binders := member.sourceInput.header.parametersRev ++ member.sourceInput.header.capturesRev
      let equation := PsDeclaration.theoremDecl (psNameAppendStr member.source.name "eq_def") levels
        (psCloseElabForallBinders psMetaEmpty binders equationType)
        (psCloseElabLambdaBinders psMetaEmpty binders equationValue)
      return ({ declaration, equation, metaContext := psMetaEmpty
                sourceInfo := body.sourceInfo } : PsElabWellFoundedResult)
  return { auxiliaries := [auxiliary], results }

-- Both surface grammars arrive here through the same scoped typed block.
-- Original measure scopes and independent source-equation checks are shared
-- with singleton WF; component construction changes only the packing owner.
def psElabWhereWellFoundedComponent (prepared : PsElabWherePrepared)
    (environment : PsEnvironment) (levels : List PsName)
    (members : List PsElabPreDefinition) :
    Except PsElabError PsElabPreDefinitionWellFoundedConstruction := do
  if let [member] := members then
    let result ← psElabWhereWellFounded prepared environment levels member
    return { results := [result] }
  let component ← psElabWherePrepareWellFoundedComponent prepared environment levels members
  let bodies ← (List.range members.length).mapM
    (psElabWhereWellFoundedComponentBody component)
  let built ← (psMutualWellFoundedBuild environment psMetaEmpty component.context.localContext
    component.plan (bodies.map (·.branch))).mapError PsElabError.infer
  psElabWhereFinishWellFoundedComponent component bodies built
