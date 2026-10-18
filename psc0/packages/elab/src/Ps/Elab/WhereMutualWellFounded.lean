import Ps.Elab.WhereWellFounded
import Ps.Elab.PreDefinition
import Ps.Meta.MutualWellFounded

/-!
Source-owned component measures for Lean4.35.0-style mutual WF construction.
Pinned PreDefinition/FixedParams, WF/{PackMutual,Rel,Fix} and Meta/ArgsPacker
own the reference algorithms. See THIRD_PARTY_NOTICES.md.
This stage preserves the original source telescope and independently checked
retained calls. It grants no recursive body, equation or runtime authority.
-/

structure PsElabWhereWellFoundedComponentMember where
  source : PsElabPreDefinition
  input : PsElabWhereWellFoundedInput
  permutation : List (Option Nat)
  specialized : PsElabRecursionSpecializedHeader
  varyingNames : List PsName
  unaryType : PsExpr
  measure : PsExpr
  dictionary : PsExpr

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
    Except PsElabError (PsExpr × PsExpr) := do
  let context := input.header.context
  let measured ← psElabTerm context input.termination.measure none
  let level ← psElabExpressionSort measured.context measured.type
  let dictionary ← psElabSynthesizeInstance measured.context
    (.app (.constE psWellFoundedRelationName [level]) measured.type)
  let normalize := fun term =>
    psElabGeneralizeExpr (psMetaInstantiate dictionary.context.metaContext term)
  let bindersRev := (input.header.parametersRev ++ input.header.capturesRev).map
    fun binder => { binder with type := normalize binder.type }
  let sourceType := psCloseElabForallBinders psMetaEmpty bindersRev
    (normalize input.header.resultType)
  if !psExprAlphaEq sourceType member.type then
    throw (psElabWhereError "WF-IDENTITY" "measure elaboration changed the original closed header")
  let measure := psCloseElabLambdaBinders psMetaEmpty bindersRev (normalize measured.term)
  let dictionary := psCloseElabLambdaBinders psMetaEmpty bindersRev (normalize dictionary.term)
  for value in [measure, dictionary] do
    if psExprHasUnresolvedMeta value || !psExprFVarsInContext psLocalEmpty value ||
        !(psElabDeclarationLevels levels [value]).all (fun used => levels.any (psNameEq used)) then
      throw (psElabWhereError "WF-MEASURE" "component measure or dictionary escaped its original header or universes")
    let _ ← psElabResolvedTerm (psElabContextEmpty context.environment levels) value none
    pure ()
  return (measure, dictionary)

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
    let (closedMeasure, closedDictionary) ← psElabWhereCloseWellFoundedMeasure levels member input
    let specialized ← psElabRecursionSpecializeHeader fixed.context member.type permutation fixedValues
    let names := specialized.bindersRev.reverse.map (·.name)
    if names.isEmpty then
      throw (psElabWhereError "WF-TELESCOPE" "the selected component packing requires a varying source parameter")
    let measureBody := psReduceApply closedMeasure specialized.arguments
    let checked ← psElabResolvedTerm specialized.context measureBody none
    let dictionary := psReduceApply closedDictionary specialized.arguments
    if psExprHasUnresolvedMeta checked.term || psExprHasUnresolvedMeta checked.type ||
        psExprHasUnresolvedMeta dictionary ||
        !(psExprFVarIds checked.type ++ psExprFVarIds dictionary).all fixedIds.contains then
      throw (psElabWhereError "WF-RELATION" "component measure codomain or dictionary depends on changing arguments")
    let measureType := psCloseElabForallBinders checked.context.metaContext
      specialized.bindersRev checked.type
    let measureValue := psCloseElabLambdaBinders checked.context.metaContext
      specialized.bindersRev checked.term
    let unaryType ← (psWellFoundedTupleUncurryType environment psMetaEmpty
      fixed.context.localContext names specialized.type).mapError PsElabError.infer
    let unaryMeasureType ← (psWellFoundedTupleUncurryType environment psMetaEmpty
      fixed.context.localContext names measureType).mapError PsElabError.infer
    let measure ← (psWellFoundedTupleUncurry environment psMetaEmpty
      fixed.context.localContext names unaryMeasureType measureValue).mapError PsElabError.infer
    let _ ← psElabResolvedTerm fixed.context dictionary none
    for value in [unaryType, measure, dictionary] do
      if psExprHasUnresolvedMeta value || !psExprFVarsInContext fixed.context.localContext value then
        throw (psElabWhereError "WF-SCOPE" "packed measure retained a member-local identity")
    let result : PsElabWhereWellFoundedComponentMember := {
      source := member, input, permutation, specialized
      varyingNames := names, unaryType, measure, dictionary }
    return result
  if measuredMembers.length != members.length then
    throw (psElabWhereError "WF-COMPONENT" "fixed parameter plan changed component arity")
  let some firstMeasured := measuredMembers.head?
    | throw (psElabWhereError "WF-COMPONENT" "component lost its first checked measure")
  for member in measuredMembers do
    if !psWellFoundedDefEq environment psMetaEmpty fixed.context.localContext
        member.dictionary firstMeasured.dictionary then
      throw (psElabWhereError "WF-RELATION" "component members select different relation dictionaries")
  let plan ← (psMutualWellFoundedPlanFor environment psMetaEmpty fixed.context.localContext
    (measuredMembers.map (·.unaryType)) (measuredMembers.map (·.measure))
    firstMeasured.dictionary).mapError PsElabError.infer
  return { context := fixed.context, fixedBindersRev := fixed.bindersRev
           parameters, members := measuredMembers, plan }
