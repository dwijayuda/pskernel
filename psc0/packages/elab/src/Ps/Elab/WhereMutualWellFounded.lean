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

def psElabWherePrepareWellFoundedComponent (prepared : PsElabWherePrepared)
    (environment : PsEnvironment) (levels : List PsName)
    (members : List PsElabPreDefinition) :
    Except PsElabError PsElabWhereWellFoundedComponent := do
  let first :: _ := members
    | throw (psElabWhereError "WF-COMPONENT" "empty measured component")
  if members.any (fun member => !psElabPreDefinitionStrategyEq member.strategy .wellFounded) then
    throw (psElabWhereError "WF-STRATEGY" "every selected component member requires its own total measure")
  let nextId := max prepared.context.localContext.nextId prepared.block.context.localContext.nextId
  let owners ← psElabPreDefinitionParameterOwners environment levels nextId members
  let parameters ← psElabRecursionComponentFixedParameterPlan owners
  let some firstPermutation := parameters.permutations.head?
    | throw (psElabWhereError "WF-COMPONENT" "fixed parameter analysis lost its first owner")
  let initial := { psElabContextEmpty environment levels with
    localContext := { psLocalEmpty with nextId } }
  let fixed ← psElabRecursionOpenFixedScope initial first.type firstPermutation parameters.count
  let fixedValues := psElabBinderArguments fixed.bindersRev
  let fixedIds := fixed.bindersRev.map (·.id)
  let measuredMembers ← (members.zip parameters.permutations).mapM fun (member, permutation) => do
    let input ← psElabWherePrepareWellFounded prepared environment levels member
    let closedMeasure ← psElabWhereCloseWellFoundedMeasure levels member input
    let specialized ← psElabRecursionSpecializeHeader fixed.context member.type permutation fixedValues
    let names := specialized.bindersRev.reverse.map (·.name)
    if names.isEmpty then
      throw (psElabWhereError "WF-TELESCOPE" "the selected component packing requires a varying source parameter")
    let measureBody := psWhnfCore psMetaEmpty specialized.context.localContext
      (psReduceApply closedMeasure specialized.arguments)
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
      source := member, input, permutation, specialized
      varyingNames := names, unaryType, measure, measureCodomain }
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

-- Keep source elaboration inside its original typed header. As in pinned
-- WF/Fix.processSumCasesOn/processPSigmaCasesOn, the callback types contain the
-- actual current injection; ordinary dependent matching refines them before
-- psTryElabWellFoundedCall creates its proof-restricted application.
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
    bodyContext := { bodyContext with
      localContext := callback.context
      auxiliaryLocalIds := callback.id :: bodyContext.auxiliaryLocalIds
      wellFoundedRecursions := bodyContext.wellFoundedRecursions ++ [{
        functionName := target.input.header.functionName, callbackName
        parameterIds := targetParameters.map (·.id), majorId, packedIds
        sourceType := some target.source.type, capturedNames }] }
    adapters := adapters ++ [(callback.id, callbackName, sourceType, adapter)]
  let value ← psElabWellFoundedAt "component source body"
    (psElabTerm bodyContext member.input.body (some header.resultType))
  psElabWhereComponentValidateCalls component fixed value.context
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
      let binders := header.parametersRev ++ header.capturesRev
      let equation := PsDeclaration.theoremDecl (psNameAppendStr member.source.name "eq_def") levels
        (psCloseElabForallBinders psMetaEmpty binders checked.type)
        (psCloseElabLambdaBinders psMetaEmpty binders checked.term)
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
