import Ps.Elab.Mutual
import Ps.Elab.Match
import Ps.Elab.RecursorEquation
import Ps.Meta.Recursor
import Ps.Elab.StructuralField
import Ps.Elab.RecursionParameters

-- Direct structural mutual definitions use the same ownership invariant as
-- pinned Lean Structural.Positions: every source function occupies exactly
-- one ordered component of its actual inductive family's motive. The source
-- may assign zero, one or several functions to a family. This selected owner
-- uses ordinary recursors and positive fields, not the separate below/brecOn
-- course-of-values construction.
def psElabMutualStructuralError (rule message : String) : PsElabError :=
  .data ("PSCV0-MUTUAL-TOTAL: " ++ rule ++ ": " ++ message)

def psElabMutualStructuralEqual (context : PsElabContext) (left right : PsExpr) : Bool :=
  psDefEqReadOnlyWithEnv context.environment context.metaContext context.localContext left right

-- Consume an actual Core telescope, checking every argument before the next
-- domain is instantiated. Local peer parameters have no global declaration.
def psElabMutualStructuralApplyType (context : PsElabContext)
    (type : PsExpr) (args : List PsExpr) : Except PsElabError PsExpr := do
  match args with
  | [] => return type
  | arg :: rest =>
    let pi ← (psInferEnsureForall context.environment context.metaContext
      context.localContext type).mapError PsElabError.infer
    let actual ← (psInferType context.environment context.metaContext
      context.localContext arg).mapError PsElabError.infer
    if !psElabMutualStructuralEqual context actual pi.domain then
      throw (psElabMutualStructuralError "TELESCOPE" "argument does not match its actual header domain")
    psElabMutualStructuralApplyType context (psExprInstantiate1 pi.body arg) rest

structure PsElabMutualStructuralLocated where
  context : PsElabContext
  application : PsEliminationRecursorApplication
  body : PsExpr
  resultBinders : Nat

-- Locate through actual returned-function binders without extending the
-- retained source header. The normalized case template is independently
-- checked against the original body; the original remains equation authority.
def psElabMutualStructuralLocate (fuel : Nat) (context : PsElabContext)
    (type body : PsExpr) : Except PsElabError PsElabMutualStructuralLocated := do
  match fuel with
  | 0 => throw .fuelExhausted
  | fuel + 1 =>
    let normalized := psWhnf context.environment context.metaContext context.localContext body
    match normalized with
    | .lam name domain value binder =>
      let pi ← (psInferEnsureForall context.environment context.metaContext
        context.localContext type).mapError PsElabError.infer
      if !psBinderInfoEq binder pi.binder ||
          !psExprFVarsInContext context.localContext domain ||
          !psElabMutualStructuralEqual context domain pi.domain then
        throw (psElabMutualStructuralError "RESULT" "returned lambda differs from its actual Pi domain or binder kind")
      let pushed := psLocalPushBinding context.localContext name domain binder
      let argument := PsExpr.fvar pushed.id
      let inner := psElabContextWithLocal context pushed.context
      let located ← psElabMutualStructuralLocate fuel inner
        (psExprInstantiate1 pi.body argument) (psExprInstantiate1 value argument)
      let body := PsExpr.lam name domain (psExprAbstractFVar pushed.id located.body) binder
      let checked ← psElabResolvedTerm context body (some type)
      if !psElabMutualStructuralEqual checked.context checked.term normalized then
        throw (psElabMutualStructuralError "RESULT" "returned-lambda location changed the original checked function")
      return { located with body := checked.term, resultBinders := located.resultBinders + 1 }
    | _ =>
      let some application := psEliminationRecursorApplication context.environment normalized
        | throw (psElabMutualStructuralError "ROOT" "checked root match has no complete registered recursor view")
      let checked ← psElabResolvedTerm context normalized (some type)
      return { context := checked.context, application, body := checked.term, resultBinders := 0 }

structure PsElabMutualStructuralInput where
  header : PsElabPartialHeader
  span : PsSourceSpan
  ownBinders : List PsElabTypedBinder
  context : PsElabContext
  body : PsExpr
  peers : List (Nat × Nat)
  application : PsEliminationRecursorApplication
  caseBody : PsExpr
  resultBinders : Nat
  familyLevels : List PsLevel
  majorId : Nat
  indexIds : List Nat
  sourceInfo : PsElabSourceInfo

def psElabMutualStructuralHeader (captured : PsElabTypedBindersResult)
    (member : PsScopedMutualMember) : Except PsElabError PsElabPartialHeader := do
  let .definition name binders type _ _ := member.source
    | throw (psElabMutualStructuralError "STRATEGY" "expected ordinary def/function members")
  psElabMutualTypedHeader captured name binders type

-- These are ordinary local parameters used while checking the source body.
-- They cannot enter the environment: the final owner must eliminate every
-- occurrence and recheck the closed result without this local context.
def psElabMutualStructuralPeers (context : PsElabContext) (captures : List PsExpr)
    (headers : List PsElabPartialHeader) (members : List PsScopedMutualMember) :
    Except PsElabError (PsElabContext × List (Nat × Nat)) := do
  if headers.length != members.length then
    throw (psElabMutualStructuralError "OWNERSHIP" "header/member count mismatch")
  (headers.zip members).zipIdx.foldlM
    (fun (state : PsElabContext × List (Nat × Nat)) entry => do
      let some alias := psSyntaxNameToName entry.fst.snd.alias | throw .emptyName
      if (psLocalFindUser state.fst.localContext alias).isSome then
        throw (psElabMutualStructuralError "OWNERSHIP" "local peer alias is shadowed")
      let type ← psElabMutualStructuralApplyType state.fst entry.fst.fst.type captures
      let pushed := psLocalPushBinding state.fst.localContext alias type .explicit
      let context := { state.fst with
        localContext := pushed.context
        auxiliaryLocalIds := pushed.id :: state.fst.auxiliaryLocalIds }
      return (context, state.snd ++ [(pushed.id, entry.snd)])) (context, [])

-- This boundary consumes a checked Core body, not lifted or reconstructed
-- source syntax. Full peers have already been specialized at the validated
-- common capture prefix. All original member-specific header slots remain.
def psElabMutualStructuralInputFromChecked (captured : PsElabTypedBindersResult)
    (header : PsElabPartialHeader) (checkedContext : PsElabContext)
    (body : PsExpr) (peers : List (Nat × Nat)) (span : PsSourceSpan)
    (sourceInfo : PsElabSourceInfo) :
    Except PsElabError PsElabMutualStructuralInput := do
  let checked ← psElabResolvedTerm checkedContext body (some header.openType)
  let ownBinders := (header.bindersRev.reverse.drop captured.bindersRev.length).map fun binder =>
    { binder with type := psMetaInstantiate checked.context.metaContext binder.type }
  let body := psMetaInstantiate checked.context.metaContext checked.term
  if psExprHasUnresolvedMeta body then throw .unresolvedMetavariable
  let located ← psElabMutualStructuralLocate 4096 checked.context header.openType body
  let application := located.application
  if psEliminationRecursorUsesHypotheses application then
    throw (psElabMutualStructuralError "CASE-IH" "source case hypotheses require a separate induction consumer")
  let .fvar majorId := application.major
    | throw (psElabMutualStructuralError "MAJOR" "recursive major is not a real header local")
  let some major := ownBinders.find? (fun binder => binder.id == majorId)
    | throw (psElabMutualStructuralError "MAJOR" "recursive major must be an explicit member header parameter")
  if !psBinderInfoEq major.binder .explicit then
    throw (psElabMutualStructuralError "MAJOR" "recursive major must be explicit")
  let indexIds ← application.indices.mapM fun index =>
    match index with
    | .fvar id =>
      if ownBinders.any (fun binder => binder.id == id) then pure id
      else throw (psElabMutualStructuralError "INDICES" "family indices must be member header locals")
    | _ => throw (psElabMutualStructuralError "INDICES" "fixed, compound or repeated indices require a separate structural construction")
  if (majorId :: indexIds).eraseDups.length != indexIds.length + 1 then
    throw (psElabMutualStructuralError "INDICES" "major and family indices must be distinct header locals")
  let majorType := psExprAppView (psWhnf checked.context.environment checked.context.metaContext
    checked.context.localContext major.type)
  let .constE owner _ := majorType.head
    | throw (psElabMutualStructuralError "MAJOR" "major type is not an instantiated group family")
  let .constE _ recursorLevels := application.head
    | throw (psElabMutualStructuralError "MAJOR" "source case has no registered recursor head")
  let some familyLevels := psInductiveEliminationFamilyLevels
      application.plan application.info recursorLevels
    | throw (psElabMutualStructuralError "MAJOR" "source recursor levels do not instantiate its complete plan")
  if !psNameEq owner application.slot.family.name ||
      majorType.args.length != application.slot.family.numParams + application.slot.family.numIndices then
    throw (psElabMutualStructuralError "MAJOR" "major family telescope does not match its recursor")
  let caseBody ← psElabResolvedTerm checked.context located.body (some header.openType)
  if !psElabMutualStructuralEqual caseBody.context body caseBody.term then
    throw (psElabMutualStructuralError "RESULT" "located case template differs from the retained source body")
  let context := { caseBody.context with localContext :=
    { caseBody.context.localContext with nextId :=
      max caseBody.context.localContext.nextId located.context.localContext.nextId } }
  return {
    header, span, ownBinders, context
    body, peers, application, familyLevels, majorId, indexIds, sourceInfo
    caseBody := caseBody.term
    resultBinders := located.resultBinders }

def psElabMutualStructuralInputFor (captured : PsElabTypedBindersResult)
    (headers : List PsElabPartialHeader) (members : List PsScopedMutualMember)
    (header : PsElabPartialHeader) (member : PsScopedMutualMember) :
    Except PsElabError PsElabMutualStructuralInput := do
  let .definition _ _ _ sourceBody span := member.source
    | throw (psElabMutualStructuralError "STRATEGY" "expected an ordinary body")
  -- The shared typed locator owns the root case and returned-result binders.
  let (context, peers) ← psElabMutualStructuralPeers header.context
    (psElabBinderArguments captured.bindersRev) headers members
  let checked ← psElabTerm context sourceBody (some header.openType)
  psElabMutualStructuralInputFromChecked captured header checked.context checked.term peers
    span (psElabFinishSourceInfo checked.context header.name)

structure PsElabMutualStructuralFunction where
  input : PsElabMutualStructuralInput
  slotIndex : Nat
  fixed : List (Nat × PsExpr)
  stateBinders : List PsElabTypedBinder

structure PsElabMutualStructuralPlan where
  context : PsElabContext
  capturesRev : List PsElabTypedBinder
  fixedRev : List PsElabTypedBinder
  group : PsInductiveGroupPlan
  elimination : PsInductiveEliminationPlan
  familyLevels : List PsLevel
  uniformArgs : List PsExpr
  functions : List PsElabMutualStructuralFunction
  positions : List (Nat × List Nat)

def psElabMutualStructuralParameterOwners (inputs : List PsElabMutualStructuralInput) :
    Except PsElabError (List PsElabRecursionParameterOwner) := do
  inputs.mapM fun input => do
    let targets ← input.peers.mapM fun (peerId, targetIndex) => do
      let some target := inputs[targetIndex]?
        | throw (psElabMutualStructuralError "OWNERSHIP" "parameter observation has no target owner")
      return ({ peerId, name := target.header.name,
        arity := target.ownBinders.length } : PsElabRecursionCallTarget)
    let calls ← psElabRecursionCollectCalls 4096 input.context targets input.span input.body
    return {
      name := input.header.name
      context := input.context
      parameterIds := input.ownBinders.map (·.id)
      calls }

-- Work backwards through actual typed domains. A computed uniform expression
-- can require several original header variables, but never an inverse of the
-- expression or an unrelated varying source parameter.
def psElabMutualStructuralUniformDependencies (captured : PsElabContext)
    (input : PsElabMutualStructuralInput) : Except PsElabError (List Nat) := do
  let parameters := input.application.fixedArgs.take input.application.info.numParams
  let roots := (parameters.flatMap psExprFVarIds).eraseDups
  let needed := input.ownBinders.reverse.foldl (fun needed binder =>
    if needed.contains binder.id then (needed ++ psExprFVarIds binder.type).eraseDups
    else needed) roots
  for id in needed do
    if id == input.majorId || input.indexIds.contains id then
      throw (psElabMutualStructuralError "FIXED" "a datatype parameter depends on the varying major or an index")
    if !psLocalContainsId captured.localContext id &&
        !input.ownBinders.any (fun binder => binder.id == id) then
      throw (psElabMutualStructuralError "FIXED" "computed uniform parameter has no original header or capture owner")
  return input.ownBinders.filterMap fun binder =>
    if needed.contains binder.id then some binder.id else none

structure PsElabMutualStructuralFixed where
  context : PsElabContext
  bindersRev : List PsElabTypedBinder
  uniformArgs : List PsExpr
  mappings : List (List (Nat × PsExpr))

def psElabMutualStructuralFixedParameters (initial : PsElabContext)
    (inputs : List PsElabMutualStructuralInput) (anchor : PsElabMutualStructuralInput) :
    Except PsElabError PsElabMutualStructuralFixed := do
  let first :: _ := inputs
    | throw (psElabMutualStructuralError "OWNERSHIP" "fixed analysis has no first member")
  let owners ← psElabMutualStructuralParameterOwners inputs
  let fixed ← psElabRecursionComponentFixedParameterPlan owners
  if fixed.permutations.length != inputs.length then
    throw (psElabMutualStructuralError "OWNERSHIP" "fixed analysis changed the source member count")
  let requirements ← inputs.mapM (psElabMutualStructuralUniformDependencies initial)
  let mut requiredClasses : List Nat := []
  for ((input, needed), permutation) in (inputs.zip requirements).zip fixed.permutations do
    if permutation.length != input.ownBinders.length then
      throw (psElabMutualStructuralError "OWNERSHIP" "fixed analysis changed an original header")
    for (binder, position) in input.ownBinders.zip permutation do
      if needed.contains binder.id then
        let some index := position
          | throw (psElabMutualStructuralError "FIXED-CALL" "recursive calls change a dependency of the uniform datatype parameters")
        if !requiredClasses.contains index then requiredClasses := requiredClasses ++ [index]
  -- Class requirements also close every member's actual dependent domains.
  -- Each unsettled pass adds a real fixed class; the finite bound is exact.
  let mut settled := false
  for _ in List.range (fixed.count + 1) do
    if !settled then
      let before := requiredClasses.length
      for (input, permutation) in inputs.zip fixed.permutations do
        for (binder, position) in (input.ownBinders.zip permutation).reverse do
          if position.any requiredClasses.contains then
            for id in psExprFVarIds binder.type do
              if let some (dependency, dependencyClass) :=
                  (input.ownBinders.zip permutation).find? (fun entry => entry.fst.id == id) then
                if dependency.id == input.majorId || input.indexIds.contains dependency.id then
                  throw (psElabMutualStructuralError "FIXED-DEPENDENCY" "fixed domain depends on a varying structural argument")
                let some index := dependencyClass
                  | throw (psElabMutualStructuralError "FIXED-DEPENDENCY" "fixed domain depends on a varying source parameter")
                if !requiredClasses.contains index then requiredClasses := requiredClasses ++ [index]
              else if !psLocalContainsId initial.localContext id then
                throw (psElabMutualStructuralError "FIXED-DEPENDENCY" "fixed domain contains an unowned local")
      settled := before == requiredClasses.length
  if !settled then throw .fuelExhausted
  let some firstPermutation := fixed.permutations.head?
    | throw (psElabMutualStructuralError "OWNERSHIP" "fixed analysis lost its first header")
  let mut context := initial
  let mut bindersRev : List PsElabTypedBinder := []
  let mut replacements : List (Nat × PsExpr) := []
  let mut classes : List (Nat × PsExpr) := []
  for (binder, position) in first.ownBinders.zip firstPermutation do
    if let some index := position then
      if requiredClasses.contains index then
        let type := psElabSubstituteLocals replacements binder.type
        if !psExprFVarsInContext context.localContext type then
          throw (psElabMutualStructuralError "FIXED-DEPENDENCY" "fixed parameter domain retains a varying header dependency")
        let _ ← psElabExpressionSort context type
        let pushed := psLocalPushBinding context.localContext binder.name type binder.binder
        let value := PsExpr.fvar pushed.id
        context := psElabContextWithLocal context pushed.context
        bindersRev := PsElabTypedBinder.mk pushed.id binder.name type binder.binder :: bindersRev
        replacements := replacements ++ [(binder.id, value)]
        classes := classes ++ [(index, value)]
  if classes.length != requiredClasses.length then
    throw (psElabMutualStructuralError "FIXED" "common fixed telescope does not cover every required class")
  let mappings ← (inputs.zip fixed.permutations).mapM fun (input, permutation) => do
    let mapping := (input.ownBinders.zip permutation).filterMap fun (binder, position) => do
      let index ← position
      let (_, value) ← classes.find? (fun entry => entry.fst == index)
      return (binder.id, value)
    if mapping.length != classes.length then
      throw (psElabMutualStructuralError "FIXED" "member does not have an exact inverse for the common fixed telescope")
    for (original, value) in mapping do
      let some binder := input.ownBinders.find? (fun binder => binder.id == original)
        | throw (psElabMutualStructuralError "FIXED" "fixed parameter has no source header owner")
      let .fvar fixedId := value
        | throw (psElabMutualStructuralError "FIXED" "common fixed parameter is not a real fresh local")
      let some shared := bindersRev.find? (fun binder => binder.id == fixedId)
        | throw (psElabMutualStructuralError "FIXED" "common fixed parameter has no typed binder")
      let type := psElabSubstituteLocals mapping binder.type
      if original == input.majorId || input.indexIds.contains original ||
          !psExprFVarsInContext context.localContext type ||
          !psElabMutualStructuralEqual context type shared.type then
        throw (psElabMutualStructuralError "FIXED-DEPENDENCY" "fixed class changes a member's domain or varying identity")
    return mapping
  let some (_, anchorMapping) := (inputs.zip mappings).find? (fun entry =>
      psNameEq entry.fst.header.name anchor.header.name)
    | throw (psElabMutualStructuralError "OWNERSHIP" "complete elimination anchor has no fixed correspondence")
  let uniformArgs := (anchor.application.fixedArgs.take anchor.application.info.numParams).map
    (psElabSubstituteLocals anchorMapping)
  if uniformArgs.any (fun argument => !psExprFVarsInContext context.localContext argument) then
    throw (psElabMutualStructuralError "FIXED" "computed uniform expression did not close over its typed dependencies")
  return { context, bindersRev, uniformArgs, mappings }

-- A source helper may recurse on List (Tree A), while its checked body uses
-- List.rec. Its recursive component belongs to Tree's actual nested rec_N
-- slot. Resolve that slot by the instantiated typed specialization, keeping
-- explicit canonical identities and distinguishing raw nested keys.
def psElabMutualStructuralSourceSlot (elimination : PsInductiveEliminationPlan)
    (context : PsElabContext) (levels : List PsLevel) (uniformArgs : List PsExpr)
    (input : PsElabMutualStructuralInput) (mapping : List (Nat × PsExpr)) :
    Except PsElabError Nat := do
  let some major := input.ownBinders.find? (fun binder => binder.id == input.majorId)
    | throw (psElabMutualStructuralError "OWNERSHIP" "source major has no original header binder")
  let type := psWhnf context.environment context.metaContext context.localContext
    (psElabSubstituteLocals mapping major.type)
  let indicesAt := fun equal slot =>
    psInductiveEliminationIndicesAt equal elimination slot levels uniformArgs type
  let direct := elimination.slots.zipIdx.find? (fun entry =>
    psNameEq entry.fst.recursorName input.application.slot.recursorName)
  let (slotIndex, indices) ← match direct with
    | some (slot, index) => do
      let some indices := indicesAt (psElabMutualStructuralEqual context) slot
        | throw (psElabMutualStructuralError "GROUP" "source recursor identity has a different instantiated major family")
      pure (index, indices)
    | none => do
      let candidatesFor := fun equal =>
        elimination.slots.zipIdx.filterMap fun (slot, index) =>
          (indicesAt equal slot).map fun indices => (index, indices)
      let exact := candidatesFor psExprAlphaEq
      let candidates := if exact.isEmpty then
        candidatesFor (psElabMutualStructuralEqual context) else exact
      let [candidate] := candidates
        | throw (psElabMutualStructuralError "GROUP" "source major does not identify one canonical elimination specialization")
      pure candidate
  if indices.length != input.indexIds.length ||
      !(indices.zip input.indexIds).all (fun pair => psExprAlphaEq pair.fst (.fvar pair.snd)) then
    throw (psElabMutualStructuralError "INDICES" "canonical slot changes the source member's own index telescope")
  return slotIndex

def psElabMutualStructuralPrepare (captured : PsElabTypedBindersResult)
    (inputs : List PsElabMutualStructuralInput) : Except PsElabError PsElabMutualStructuralPlan := do
  let first :: _ := inputs
    | throw (psElabMutualStructuralError "OWNERSHIP" "empty structural batch")
  let anchor := inputs.foldl (fun anchor input =>
    if anchor.application.plan.slots.length < input.application.plan.slots.length then input
    else anchor) first
  let nextId := inputs.foldl (fun id input => max id input.context.localContext.nextId)
    captured.context.localContext.nextId
  let initial := psElabContextWithLocal captured.context {
    captured.context.localContext with nextId := nextId + 1 }
  let fixed ← psElabMutualStructuralFixedParameters initial inputs anchor
  let functions ← (inputs.zip fixed.mappings).mapM fun (input, mapping) => do
    let slotIndex ← psElabMutualStructuralSourceSlot anchor.application.plan fixed.context
      anchor.familyLevels fixed.uniformArgs input mapping
    let stateBinders := input.ownBinders.filter fun binder =>
      binder.id != input.majorId && !input.indexIds.contains binder.id &&
        !mapping.any (fun entry => entry.fst == binder.id)
    return { input, slotIndex, fixed := mapping, stateBinders : PsElabMutualStructuralFunction }
  let positions := anchor.application.plan.slots.zipIdx.map fun (_, slotIndex) =>
    (slotIndex, functions.zipIdx.filterMap fun entry =>
      if entry.fst.slotIndex == slotIndex then some entry.snd else none)
  let owned := positions.flatMap Prod.snd
  if functions.length != inputs.length || owned.length != functions.length ||
      !(List.range functions.length).all (fun index => (owned.filter (· == index)).length == 1) then
    throw (psElabMutualStructuralError "OWNERSHIP" "family components are not an exact source-function permutation")
  return {
    context := fixed.context
    capturesRev := captured.bindersRev
    fixedRev := fixed.bindersRev
    group := anchor.application.plan.group
    elimination := anchor.application.plan
    familyLevels := anchor.familyLevels
    uniformArgs := fixed.uniformArgs
    functions, positions }

def psElabMutualStructuralPositions (plan : PsElabMutualStructuralPlan)
    (slotIndex : Nat) : Except PsElabError (List Nat) := do
  let some (_, positions) := plan.positions.find? (fun entry => entry.fst == slotIndex)
    | throw (psElabMutualStructuralError "OWNERSHIP" "elimination slot has no component-position record")
  return positions

def psElabMutualStructuralComponentType (context : PsElabContext)
    (fn : PsElabMutualStructuralFunction) (indices : List PsExpr) (major : PsExpr) :
    Except PsElabError PsExpr := do
  if indices.length != fn.input.indexIds.length then
    throw (psElabMutualStructuralError "INDICES" "component received another family's index telescope")
  let replacements := fn.fixed ++ fn.input.indexIds.zip indices ++ [(fn.input.majorId, major)]
  let stateRev := fn.stateBinders.reverse.map fun binder =>
    { binder with type := psElabSubstituteLocals replacements binder.type }
  let result := psElabSubstituteLocals replacements fn.input.header.openType
  let type := psCloseElabForallBinders context.metaContext stateRev result
  if !psExprFVarsInContext context.localContext type then
    throw (psElabMutualStructuralError "DEPENDENCY" "component motive retains an unowned header variable")
  let _ ← psElabExpressionSort context type
  return type

def psElabMutualStructuralComponentLevel (plan : PsElabMutualStructuralPlan)
    (fn : PsElabMutualStructuralFunction) : Except PsElabError PsLevel := do
  let some slot := plan.elimination.slots[fn.slotIndex]?
    | throw (psElabMutualStructuralError "OWNERSHIP" "component has no canonical elimination slot")
  let some typeFormer := psInductiveEliminationInstantiate plan.elimination
      plan.familyLevels plan.uniformArgs slot.typeFormer
    | throw (psElabMutualStructuralError "FAMILY" "component type former did not instantiate")
  let applied ← psElabResolvedTerm plan.context typeFormer none
  let indices ← psElabOpenCoreTelescope 4096 applied.context applied.type (some slot.family.numIndices)
  let args := psElabBinderArguments indices.bindersRev
  let majorType := psExprApplyMany applied.term args
  let pushed := psLocalPushBinding indices.context.localContext (psRootName "_mutualMajor") majorType .explicit
  let context := psElabContextWithLocal indices.context pushed.context
  let type ← psElabMutualStructuralComponentType context fn args (.fvar pushed.id)
  psElabExpressionSort context type

-- Pinned Meta.PProdN uses And for known propositions and PProd otherwise,
-- preserving source positions and identity for a singleton. Infer the actual
-- packed sort: do not guess a predecessor universe or silently lift a motive.
def psElabMutualStructuralProduct (level : PsLevel) : PsName :=
  psRootName (if psLevelEquivalent level .zero then "And" else "PProd")

def psElabMutualStructuralProductLevels (level : PsLevel) : List PsLevel :=
  if psLevelEquivalent level .zero then [] else [level, level]

def psElabMutualStructuralPackUnit (context : PsElabContext) (level : PsLevel) :
    Except PsElabError (PsExpr × PsExpr) := do
  if !psLevelEquivalent level .zero then return ← psElabMatchUnit context level
  let type := PsExpr.constE (psRootName "True") []
  let value := PsExpr.constE (psNameAppendStr (psRootName "True") "intro") []
  let _ ← psElabResolvedTerm context type (some (.sortE level))
  let _ ← psElabResolvedTerm context value (some type)
  return (type, value)

def psElabMutualStructuralPackType (context : PsElabContext) (level : PsLevel)
    (types : List PsExpr) : Except PsElabError PsExpr := do
  match types with
  | [] => return (← psElabMutualStructuralPackUnit context level).fst
  | [type] =>
    let actual ← psElabExpressionSort context type
    if !psLevelEquivalent actual level then
      throw (psElabMutualStructuralError "SORT" "component universe differs from its actual motive domain")
    return type
  | left :: rest =>
    let right ← psElabMutualStructuralPackType context level rest
    let actual ← psElabExpressionSort context left
    if !psLevelEquivalent actual level then
      throw (psElabMutualStructuralError "SORT" "packed components require equivalent motive universes")
    let packed ← psElabApplyCore context
      (.constE (psElabMutualStructuralProduct level) (psElabMutualStructuralProductLevels level))
      [left, right]
    let actual ← psElabExpressionSort packed.context packed.term
    if !psLevelEquivalent actual level then
      throw (psElabMutualStructuralError "SORT" "actual packed product changes the common motive universe")
    let checked ← psElabResolvedTerm packed.context packed.term (some (.sortE level))
    return psMetaInstantiate checked.context.metaContext checked.term

def psElabMutualStructuralPackValue (context : PsElabContext) (level : PsLevel)
    (values : List PsExpr) : Except PsElabError PsExpr := do
  match values with
  | [] => return (← psElabMutualStructuralPackUnit context level).snd
  | [value] => return value
  | left :: rest =>
    let right ← psElabMutualStructuralPackValue context level rest
    let leftType ← (psInferType context.environment context.metaContext
      context.localContext left).mapError PsElabError.infer
    let rightType ← (psInferType context.environment context.metaContext
      context.localContext right).mapError PsElabError.infer
    let expected ← psElabMutualStructuralPackType context level [leftType, rightType]
    let constructor := psNameAppendStr (psElabMutualStructuralProduct level)
      (if psLevelEquivalent level .zero then "intro" else "mk")
    let packed ← psElabApplyCore context
      (.constE constructor (psElabMutualStructuralProductLevels level))
      [leftType, rightType, left, right]
    let checked ← psElabResolvedTerm packed.context packed.term (some expected)
    return psMetaInstantiate checked.context.metaContext checked.term

def psElabMutualStructuralProject (context : PsElabContext)
    (count position : Nat) (value : PsExpr) : Except PsElabError PsExpr := do
  if position >= count then
    throw (psElabMutualStructuralError "OWNERSHIP" "component position exceeds its family")
  match count with
  | 0 => throw (psElabMutualStructuralError "OWNERSHIP" "an empty family has no function component")
  | 1 => return value
  | count + 2 =>
    let type ← (psInferType context.environment context.metaContext
      context.localContext value).mapError PsElabError.infer
    let view := psExprAppView (psWhnf context.environment context.metaContext context.localContext type)
    let .constE owner _ := view.head
      | throw (psElabMutualStructuralError "OWNERSHIP" "packed component has no actual product owner")
    if view.args.length != 2 ||
        !(psNameEq owner (psRootName "PProd") || psNameEq owner (psRootName "And")) then
      throw (psElabMutualStructuralError "OWNERSHIP" "packed component is not an actual PProd or And")
    let index := if position == 0 then 0 else 1
    let projected ← psElabResolvedTerm context (.proj owner index value) none
    if position == 0 then return projected.term
    psElabMutualStructuralProject projected.context (count + 1) (position - 1) projected.term

structure PsElabMutualStructuralFamily where
  slotIndex : Nat
  slot : PsInductiveEliminationSlot
  indices : List PsExpr

-- A nested specialization is identified by its canonical elimination slot.
-- Its real type former supplies the fixed prefix, so two List specializations
-- can never acquire each other's components or induction hypotheses.
def psElabMutualStructuralFamilyAt (plan : PsElabMutualStructuralPlan)
    (context : PsElabContext) (slotIndex : Nat) (type : PsExpr) :
    Except PsElabError PsElabMutualStructuralFamily := do
  let some slot := plan.elimination.slots[slotIndex]?
    | throw (psElabMutualStructuralError "FAMILY" "canonical elimination slot is absent")
  let type := psWhnf context.environment context.metaContext context.localContext type
  let some indices := psInductiveEliminationIndicesAt
      (psElabMutualStructuralEqual context) plan.elimination slot
      plan.familyLevels plan.uniformArgs type
    | throw (psElabMutualStructuralError "FAMILY" "actual family application differs from its canonical slot specialization")
  return { slotIndex, slot, indices }

def psElabMutualStructuralMotiveAt (motives : List PsExpr)
    (family : PsElabMutualStructuralFamily) (major : PsExpr) : Except PsElabError PsExpr := do
  let some motive := motives[family.slotIndex]?
    | throw (psElabMutualStructuralError "OWNERSHIP" "actual child slot has no motive")
  return psExprApplyMany motive (family.indices ++ [major])

structure PsElabMutualStructuralChild where
  fieldId : Nat
  slotIndex : Nat
  hypothesis : PsExpr

def psElabMutualStructuralChildren (plan : PsElabMutualStructuralPlan)
    (context : PsElabContext) (motives : List PsExpr)
    (owner : PsInductiveEliminationSlot) (constructor : PsInductiveEliminationConstructor)
    (fields hypotheses : List PsElabTypedBinder) :
    Except PsElabError (List PsElabMutualStructuralChild) := do
  let recursiveInfo := { constructor.info with
    recursiveFields := constructor.recursiveFields.map Prod.fst }
  if !psInductiveEliminationConstructorMetadataValid owner constructor ||
      !psConstructorRecursiveFieldsOrdered recursiveInfo ||
      fields.length != constructor.info.numFields ||
      hypotheses.length != constructor.recursiveFields.length then
    throw (psElabMutualStructuralError "FIELD-METADATA" "canonical constructor fields and actual ordered hypotheses disagree")
  (constructor.recursiveFields.zip hypotheses).mapM fun ((index, targetSlot), hypothesis) => do
    let some field := fields[index]?
      | throw (psElabMutualStructuralError "FIELD-METADATA" "hypothesis has no corresponding field")
    let opened ← psElabOpenCoreTelescope 4096 context field.type none
    let family ← psElabMutualStructuralFamilyAt plan opened.context targetSlot opened.body
    let major := psExprApplyMany (.fvar field.id) (psElabBinderArguments opened.bindersRev)
    let expected ← psElabMutualStructuralMotiveAt motives family major
    if !opened.bindersRev.isEmpty &&
        !(← psElabStructuralFieldSortAllowed opened.context family.slot.family expected) then
      throw (psElabMutualStructuralError "DIRECT-FIELD" "automatic recursion over a predicate requires a Prop-valued motive")
    let expected := psCloseElabForallBinders opened.context.metaContext opened.bindersRev expected
    if !psElabMutualStructuralEqual context hypothesis.type expected then
      throw (psElabMutualStructuralError "IH-TYPE" "actual induction hypothesis does not belong to this canonical child slot")
    return { fieldId := field.id, slotIndex := targetSlot, hypothesis := .fvar hypothesis.id }

def psElabMutualStructuralSourceMap (fn : PsElabMutualStructuralFunction)
    (indices : List PsExpr) (major : PsExpr) (stateArgs : List PsExpr) :
    Except PsElabError (List (Nat × PsExpr)) := do
  if indices.length != fn.input.indexIds.length || stateArgs.length != fn.stateBinders.length then
    throw (psElabMutualStructuralError "TELESCOPE" "source argument partition has the wrong length")
  let replacements := fn.fixed ++ fn.input.indexIds.zip indices ++ [(fn.input.majorId, major)] ++
    (fn.stateBinders.map (·.id)).zip stateArgs
  if replacements.length != fn.input.ownBinders.length ||
      !fn.input.ownBinders.all (fun binder =>
        (replacements.filter (fun entry => entry.fst == binder.id)).length == 1) then
    throw (psElabMutualStructuralError "OWNERSHIP" "source argument partition is not exact")
  return replacements

def psElabMutualStructuralMappedArgument (replacements : List (Nat × PsExpr))
    (id : Nat) : Except PsElabError PsExpr := do
  let some (_, value) := replacements.find? (fun entry => entry.fst == id)
    | throw (psElabMutualStructuralError "TELESCOPE" "original header argument is missing")
  return value

def psElabMutualStructuralCheckMapping (context : PsElabContext)
    (fn : PsElabMutualStructuralFunction) (replacements : List (Nat × PsExpr)) :
    Except PsElabError Unit := do
  for binder in fn.input.ownBinders do
    let value ← psElabMutualStructuralMappedArgument replacements binder.id
    let expected := psElabSubstituteLocals replacements binder.type
    let actual ← (psInferType context.environment context.metaContext
      context.localContext value).mapError PsElabError.infer
    if !psElabMutualStructuralEqual context actual expected then
      throw (psElabMutualStructuralError "TELESCOPE" "argument mapping changes an original dependent domain")

-- The target identity is a source position, independent of its return type.
-- Equal-typed functions therefore cannot exchange hypotheses accidentally.
def psElabMutualStructuralCall (plan : PsElabMutualStructuralPlan)
    (context : PsElabContext) (children : List PsElabMutualStructuralChild)
    (targetIndex : Nat) (args : List PsExpr) : Except PsElabError PsExpr := do
  let some target := plan.functions[targetIndex]?
    | throw (psElabMutualStructuralError "OWNERSHIP" "peer index has no source function")
  let arity := target.input.ownBinders.length
  if args.length < arity then
    throw (psElabMutualStructuralError "CALL-ARITY" "selected peer calls must supply the complete member header")
  let actuals := (target.input.ownBinders.map (·.id)).zip (args.take arity)
  for (id, expected) in target.fixed do
    let actual ← psElabMutualStructuralMappedArgument actuals id
    if !psElabMutualStructuralEqual context actual expected then
      throw (psElabMutualStructuralError "FIXED-CALL" "recursive call changes a uniform fixed parameter")
  let major ← psElabMutualStructuralMappedArgument actuals target.input.majorId
  let some (childId, fieldArgs) := psElabStructuralFieldArguments context
      (children.map (·.fieldId)) major
    | throw (psElabMutualStructuralError "DECREASE" "recursive major has no checked strict-child hypothesis")
  let some child := children.find? (fun child => child.fieldId == childId)
    | throw (psElabMutualStructuralError "DECREASE" "recursive major has no checked strict-child hypothesis")
  let majorType ← (psInferType context.environment context.metaContext
    context.localContext major).mapError PsElabError.infer
  if child.slotIndex != target.slotIndex then
    throw (psElabMutualStructuralError "CHILD-FAMILY" "peer is assigned to a different canonical child slot")
  let family ← psElabMutualStructuralFamilyAt plan context child.slotIndex majorType
  let indices ← target.input.indexIds.mapM (psElabMutualStructuralMappedArgument actuals)
  if indices.length != family.indices.length ||
      !(indices.zip family.indices).all (fun pair =>
        psElabMutualStructuralEqual context pair.fst pair.snd) then
    throw (psElabMutualStructuralError "CHILD-INDICES" "peer indices do not match the actual recursive field")
  let hypothesis ← psElabApplyCore context child.hypothesis fieldArgs
  let context := hypothesis.context
  psElabMutualStructuralCheckMapping context target actuals
  let expected ← psElabMutualStructuralApplyType context target.input.header.type
    (psElabBinderArguments plan.capturesRev ++ args)
  let positions ← psElabMutualStructuralPositions plan family.slotIndex
  let some (_, position) := positions.zipIdx.find? (fun entry => entry.fst == targetIndex)
    | throw (psElabMutualStructuralError "OWNERSHIP" "peer is absent from the child's component list")
  let selected ← psElabMutualStructuralProject context positions.length position hypothesis.term
  let stateArgs ← target.stateBinders.mapM fun binder =>
    psElabMutualStructuralMappedArgument actuals binder.id
  let applied ← psElabApplyCore context selected (stateArgs ++ args.drop arity)
  let checked ← psElabResolvedTerm applied.context applied.term (some expected)
  let term := psMetaInstantiate checked.context.metaContext checked.term
  if psExprHasUnresolvedMeta term then throw .unresolvedMetavariable
  return term

-- Traverse the retained checked branch. New lexical binders use identities
-- above all provisional source contexts; a source peer ID cannot be confused
-- with a constructor field, state argument or nested local.
def psElabMutualStructuralRewrite (fuel : Nat) (plan : PsElabMutualStructuralPlan)
    (caller : PsElabMutualStructuralInput) (context : PsElabContext)
    (children : List PsElabMutualStructuralChild) (term : PsExpr) :
    Except PsElabError PsExpr := do
  match fuel with
  | 0 => throw (psElabMutualStructuralError "BUDGET" "structural branch traversal exhausted")
  | fuel + 1 =>
    let view := psExprAppView term
    if let .fvar id := view.head then
      if let some (_, target) := caller.peers.find? (fun entry => entry.fst == id) then
        let args ← view.args.mapM (psElabMutualStructuralRewrite fuel plan caller context children)
        return ← psElabMutualStructuralCall plan context children target args
    match term with
    | .app fn arg =>
      let fn ← psElabMutualStructuralRewrite fuel plan caller context children fn
      let arg ← psElabMutualStructuralRewrite fuel plan caller context children arg
      return .app fn arg
    | .lam name domain body binder =>
      let domain ← psElabMutualStructuralRewrite fuel plan caller context children domain
      let pushed := psLocalPushBinding context.localContext name domain binder
      let body ← psElabMutualStructuralRewrite fuel plan caller
        (psElabContextWithLocal context pushed.context) children
        (psExprInstantiate1 body (.fvar pushed.id))
      return .lam name domain (psExprAbstractFVar pushed.id body) binder
    | .forallE name domain body binder =>
      let domain ← psElabMutualStructuralRewrite fuel plan caller context children domain
      let pushed := psLocalPushBinding context.localContext name domain binder
      let body ← psElabMutualStructuralRewrite fuel plan caller
        (psElabContextWithLocal context pushed.context) children
        (psExprInstantiate1 body (.fvar pushed.id))
      return .forallE name domain (psExprAbstractFVar pushed.id body) binder
    | .letE name domain value body =>
      let domain ← psElabMutualStructuralRewrite fuel plan caller context children domain
      let value ← psElabMutualStructuralRewrite fuel plan caller context children value
      let checked ← psElabResolvedTerm context value (some domain)
      let pushed := psLocalPushLet checked.context.localContext name domain checked.term
      let body ← psElabMutualStructuralRewrite fuel plan caller
        (psElabContextWithLocal checked.context pushed.context) children
        (psExprInstantiate1 body (.fvar pushed.id))
      return .letE name domain checked.term (psExprAbstractFVar pushed.id body)
    | .proj name index value =>
      return .proj name index (← psElabMutualStructuralRewrite fuel plan caller context children value)
    | _ => return term

-- The locator counted actual returned-function lambdas in the checked body.
-- Reopen exactly those binders here; they remain result arguments rather than
-- becoming source-header or fixed-parameter positions.
def psElabMutualStructuralBranchValue (resultBinders : Nat)
    (plan : PsElabMutualStructuralPlan) (caller : PsElabMutualStructuralInput)
    (context : PsElabContext) (children : List PsElabMutualStructuralChild)
    (source expected : PsExpr) : Except PsElabError PsExpr := do
  match resultBinders with
  | 0 =>
    let some reduced := psReduceIota
        (psWhnf context.environment context.metaContext context.localContext)
        context.environment source
      | throw (psElabMutualStructuralError "IOTA" "the checked source case did not select this real constructor")
    let branch := psWhnf context.environment context.metaContext context.localContext reduced
    let value ← psElabMutualStructuralRewrite 4096 plan caller context children branch
    let checked ← psElabResolvedTerm context value (some expected)
    return psMetaInstantiate checked.context.metaContext checked.term
  | resultBinders + 1 =>
    let .lam name domain body binder := source
      | throw (psElabMutualStructuralError "RESULT" "located returned-function binder is absent from the checked case template")
    let pi ← (psInferEnsureForall context.environment context.metaContext
      context.localContext expected).mapError PsElabError.infer
    if !psBinderInfoEq binder pi.binder ||
        !psExprFVarsInContext context.localContext domain ||
        !psElabMutualStructuralEqual context domain pi.domain then
      throw (psElabMutualStructuralError "RESULT" "returned-function branch changes its actual Pi domain or binder kind")
    let pushed := psLocalPushBinding context.localContext name domain binder
    let argument := PsExpr.fvar pushed.id
    let value ← psElabMutualStructuralBranchValue resultBinders plan caller
      (psElabContextWithLocal context pushed.context) children
      (psExprInstantiate1 body argument) (psExprInstantiate1 pi.body argument)
    let term := PsExpr.lam name domain (psExprAbstractFVar pushed.id value) binder
    let checked ← psElabResolvedTerm context term (some expected)
    return psMetaInstantiate checked.context.metaContext checked.term

def psElabMutualStructuralBranch (plan : PsElabMutualStructuralPlan)
    (context : PsElabContext) (fn : PsElabMutualStructuralFunction)
    (family : PsElabMutualStructuralFamily) (major : PsExpr)
    (children : List PsElabMutualStructuralChild) : Except PsElabError PsExpr := do
  let type ← psElabMutualStructuralComponentType context fn family.indices major
  let states ← psElabOpenCoreTelescope 4096 context type (some fn.stateBinders.length)
  let replacements ← psElabMutualStructuralSourceMap fn family.indices major
    (psElabBinderArguments states.bindersRev)
  psElabMutualStructuralCheckMapping states.context fn replacements
  let source := psElabSubstituteLocals replacements fn.input.caseBody
  let value ← psElabMutualStructuralBranchValue fn.input.resultBinders plan fn.input
    states.context children source states.body
  let term := psCloseElabLambdaBinders states.context.metaContext states.bindersRev value
  let checked ← psElabResolvedTerm context term (some type)
  return psMetaInstantiate checked.context.metaContext checked.term

structure PsElabMutualStructuralRecursor where
  plan : PsElabMutualStructuralPlan
  levels : List PsLevel
  fixedArgs : List PsExpr

def psElabMutualStructuralRecursorFor (plan : PsElabMutualStructuralPlan) :
    Except PsElabError PsElabMutualStructuralRecursor := do
  let first :: _ := plan.functions
    | throw (psElabMutualStructuralError "OWNERSHIP" "empty function component list")
  let level ← psElabMutualStructuralComponentLevel plan first
  for fn in plan.functions do
    if !psLevelEquivalent (← psElabMutualStructuralComponentLevel plan fn) level then
      throw (psElabMutualStructuralError "SORT" "all structural component motives must have equivalent universes")
  let anchor :: _ := plan.elimination.group.members
    | throw (psElabMutualStructuralError "GROUP" "complete elimination plan has no public anchor")
  let recursor ← psElabEliminationRecursorPlanFor plan.context anchor
    plan.familyLevels plan.uniformArgs level
  if recursor.plan.slots.length != plan.elimination.slots.length ||
      !(recursor.plan.slots.zip plan.elimination.slots).all (fun pair =>
        psNameEq pair.fst.recursorName pair.snd.recursorName &&
          psExprAlphaEq pair.fst.typeFormer pair.snd.typeFormer) then
    throw (psElabMutualStructuralError "GROUP" "registered recursor changed the complete canonical slot order")
  let constructors ← psElabEliminationConstructors recursor.context recursor.plan
  let motives ← psElabRecursorArguments recursor.plan.slots.zipIdx
    (fun current (slot, slotIndex) domain => do
      let opened ← psElabOpenCoreTelescope 4096 current domain (some (slot.family.numIndices + 1))
      let major :: indicesRev := opened.bindersRev
        | throw (psElabMutualStructuralError "MOTIVE" "registered motive has no major binder")
      let .sortE actualLevel := psWhnf opened.context.environment opened.context.metaContext
          opened.context.localContext opened.body
        | throw (psElabMutualStructuralError "MOTIVE" "registered motive does not end in a Sort")
      let actual ← psElabMutualStructuralFamilyAt plan opened.context slotIndex major.type
      let indices := psElabBinderArguments indicesRev
      if actual.indices.length != indices.length ||
          !(actual.indices.zip indices).all (fun pair =>
            psElabMutualStructuralEqual opened.context pair.fst pair.snd) then
        throw (psElabMutualStructuralError "MOTIVE" "registered motive does not bind this canonical slot's own indices")
      let positions ← psElabMutualStructuralPositions plan slotIndex
      let types ← positions.mapM fun position => do
        let some fn := plan.functions[position]?
          | throw (psElabMutualStructuralError "OWNERSHIP" "component function is absent")
        psElabMutualStructuralComponentType opened.context fn indices (.fvar major.id)
      let type ← psElabMutualStructuralPackType opened.context actualLevel types
      return {
        context := psElabLeaveScope current opened.context
        term := psCloseElabLambdaBinders opened.context.metaContext opened.bindersRev type })
    recursor.context recursor.cursor
  let minors ← psElabRecursorArguments constructors
    (fun current (slotIndex, owner, constructor) domain => do
      let opened ← psElabOpenCoreTelescope 4096 current domain
        (some (constructor.info.numFields + constructor.recursiveFields.length))
      let binders := opened.bindersRev.reverse
      let fields := binders.take constructor.info.numFields
      let children ← psElabMutualStructuralChildren plan opened.context motives.arguments
        owner constructor fields (binders.drop constructor.info.numFields)
      let some head := psInductiveEliminationInstantiate recursor.plan
          plan.familyLevels plan.uniformArgs constructor.head
        | throw (psElabMutualStructuralError "CONSTRUCTOR" "canonical constructor specialization did not instantiate")
      let major := psExprApplyMany head (fields.map (fun field => .fvar field.id))
      let majorType ← (psInferType opened.context.environment opened.context.metaContext
        opened.context.localContext major).mapError PsElabError.infer
      let family ← psElabMutualStructuralFamilyAt plan opened.context slotIndex majorType
      let expected ← psElabMutualStructuralMotiveAt motives.arguments family major
      if !psElabMutualStructuralEqual opened.context opened.body expected then
        throw (psElabMutualStructuralError "MINOR" "actual minor conclusion differs from its owned motive")
      let positions ← psElabMutualStructuralPositions plan slotIndex
      let values ← positions.mapM fun position => do
        let some fn := plan.functions[position]?
          | throw (psElabMutualStructuralError "OWNERSHIP" "minor component function is absent")
        psElabMutualStructuralBranch plan opened.context fn family major children
      let actualLevel ← psElabExpressionSort opened.context expected
      let value ← psElabMutualStructuralPackValue opened.context actualLevel values
      let checked ← psElabResolvedTerm opened.context value (some expected)
      return {
        context := psElabLeaveScope current checked.context
        term := psCloseElabLambdaBinders checked.context.metaContext opened.bindersRev checked.term })
    motives.context motives.cursor
  let fixedArgs := plan.uniformArgs ++ motives.arguments ++ minors.arguments
  if fixedArgs.any (fun term => !psExprFVarsInContext plan.context.localContext term ||
      psExprHasUnresolvedMeta term) then
    throw (psElabMutualStructuralError "CLOSURE" "completed motives or minors retain a provisional local")
  return { plan, levels := recursor.levels, fixedArgs }

-- Reopen the shared checked recursor in the member's original header. The
-- common fixed telescope has an exact inverse for every member; captures
-- retain their original identities. No provisional peer is a dependency.
def psElabMutualStructuralValue (recursor : PsElabMutualStructuralRecursor)
    (sourceIndex : Nat) : Except PsElabError PsExpr := do
  let plan := recursor.plan
  let some fn := plan.functions[sourceIndex]?
    | throw (psElabMutualStructuralError "OWNERSHIP" "definition has no source component")
  let inverse ← fn.fixed.mapM fun (original, value) => do
    let .fvar fixedId := value
      | throw (psElabMutualStructuralError "FIXED" "canonical fixed value is not an owned local")
    return (fixedId, PsExpr.fvar original)
  if inverse.length != plan.fixedRev.length then
    throw (psElabMutualStructuralError "FIXED" "definition has an incomplete inverse fixed mapping")
  let header := fn.input.header
  let context := header.context
  let arguments := recursor.fixedArgs.map (psElabSubstituteLocals inverse)
  let indices := fn.input.indexIds.map PsExpr.fvar
  let major := PsExpr.fvar fn.input.majorId
  let some slot := plan.elimination.slots[fn.slotIndex]?
    | throw (psElabMutualStructuralError "OWNERSHIP" "definition has no canonical elimination slot")
  let called ← psElabApplyCore context
    (.constE slot.recursorName recursor.levels) (arguments ++ indices ++ [major])
  let positions ← psElabMutualStructuralPositions plan fn.slotIndex
  let some (_, position) := positions.zipIdx.find? (fun entry => entry.fst == sourceIndex)
    | throw (psElabMutualStructuralError "OWNERSHIP" "definition is absent from its own family")
  let component ← psElabMutualStructuralProject called.context positions.length position called.term
  let applied ← psElabApplyCore called.context component
    (fn.stateBinders.map (fun binder => .fvar binder.id))
  let checked ← psElabResolvedTerm applied.context applied.term (some header.openType)
  let closed := psCloseElabTypedBinders checked.context.metaContext header.bindersRev
    checked.term header.openType
  if psExprHasUnresolvedMeta closed.fst || psExprHasUnresolvedMeta closed.snd ||
      !psExprFVarsInContext psLocalEmpty closed.fst || !psExprAlphaEq closed.snd header.type then
    throw (psElabMutualStructuralError "CLOSURE" "definition does not close against its exact checked header")
  let _ ← psElabResolvedTerm (psElabContextEmpty context.environment context.levelNames)
    closed.fst (some header.type)
  return closed.fst

-- Prove the original source equation after all real definitions are staged.
-- A variable-major equation is not generally reflexive: its two eliminators
-- have different motives. The checked case construction reduces each actual
-- constructor branch, where delta/iota and product projection establish the
-- equation. Companion motives are checked PUnit at the actual motive level.
def psElabMutualStructuralEquationProof (context : PsElabContext)
    (fn : PsElabMutualStructuralFunction) (expected : PsExpr) :
    Except PsElabError PsExpr :=
  (psElabRecursorEquationProof context (.fvar fn.input.majorId) expected fn.input.span).mapError
    (fun error => match error with
      | .data message => psElabMutualStructuralError "EQUATION" message
      | error => error)

def psElabMutualStructuralEquation (environment : PsEnvironment)
    (levels : List PsName) (plan : PsElabMutualStructuralPlan)
    (sourceIndex : Nat) : Except PsElabError PsDeclaration := do
  let some fn := plan.functions[sourceIndex]?
    | throw (psElabMutualStructuralError "OWNERSHIP" "equation has no source component")
  let header := fn.input.header
  let context := psElabContextWithEnvironment header.context environment
  let captures := psElabBinderArguments plan.capturesRev
  let replacements ← fn.input.peers.mapM fun (id, targetIndex) => do
    let some target := plan.functions[targetIndex]?
      | throw (psElabMutualStructuralError "OWNERSHIP" "equation peer has no real definition")
    let actual ← psElabApplyCore context
      (.constE target.input.header.name (levels.map PsLevel.param)) captures
    return (id, actual.term)
  let source := psElabSubstituteLocals replacements fn.input.body
  if !psExprFVarsInContext context.localContext source || psExprHasUnresolvedMeta source then
    throw (psElabMutualStructuralError "EQUATION" "original source body retains a provisional peer")
  let right ← psElabResolvedTerm context source (some header.openType)
  let left ← psElabApplyCore right.context (.constE header.name (levels.map PsLevel.param))
    (psElabBinderArguments header.bindersRev)
  let level ← psElabExpressionSort left.context header.openType
  let equation := psLogicEq level header.openType left.term right.term
  let proof ← psElabMutualStructuralEquationProof left.context fn equation
  let closed := psCloseElabTypedBinders left.context.metaContext header.bindersRev proof equation
  if psExprHasUnresolvedMeta closed.fst || psExprHasUnresolvedMeta closed.snd ||
      !psExprFVarsInContext psLocalEmpty closed.fst || !psExprFVarsInContext psLocalEmpty closed.snd then
    throw (psElabMutualStructuralError "EQUATION" "equation did not close against its original header")
  let checked ← psElabResolvedTerm (psElabContextEmpty environment levels) closed.fst (some closed.snd)
  return .theoremDecl (psNameAppendStr header.name "eq_def") levels closed.snd checked.term

def psElabMutualStructuralClose (environment : PsEnvironment) (levelNames : List PsName)
    (captured : PsElabTypedBindersResult) (inputs : List PsElabMutualStructuralInput)
    (retainBlockLevels : Bool) (emitEquations : Bool := true) :
    Except PsElabError PsElabMutualBatchResult := do
  let headers := inputs.map (·.header)
  let ownedNames := headers.flatMap fun header =>
    if emitEquations then [header.name, psNameAppendStr header.name "eq_def"] else [header.name]
  for name in ownedNames do
    if (psEnvironmentFind environment name).isSome ||
        (ownedNames.filter (psNameEq name)).length != 1 then
      throw (.duplicateDeclaration name)
  let plan ← psElabMutualStructuralPrepare captured inputs
  let recursor ← psElabMutualStructuralRecursorFor plan
  let values ← (List.range headers.length).mapM fun index => do
    let some header := headers[index]?
      | throw (psElabMutualStructuralError "OWNERSHIP" "closed definition has no header")
    (psElabMutualStructuralValue recursor index).mapError (.atDeclaration header.name)
  -- Include retained source bodies in the common universe union: eq_def
  -- publishes that exact body even if its case specialization erased a type.
  let usedLevels := psElabDeclarationLevels levelNames
    (headers.map (·.type) ++ values ++ inputs.map (·.body))
  if retainBlockLevels && usedLevels.any (fun name => !levelNames.any (psNameEq name)) then
    throw (psElabMutualStructuralError "UNIVERSES" "checked component introduced a level outside its closed source block")
  let levels := if retainBlockLevels then levelNames else usedLevels
  let declarations ← (headers.zip values).mapM fun (header, value) => do
    let checked ← psElabResolvedTerm (psElabContextEmpty environment levels) value (some header.type)
    return PsDeclaration.definitionDecl header.name levels header.type checked.term
  -- Only fully checked, closed definitions enter this private staging value.
  -- Any body or equation failure returns no batch and changes no caller state.
  let staged ← psAddDeclarationList environment declarations
  if !emitEquations then
    let owned := (declarations.zip inputs).map fun (declaration, input) =>
      ({ declarations := [declaration], sourceInfo := [input.sourceInfo] } :
        PsElabDeclarationBatchResult)
    return {
      batch := { declarations, sourceInfo := inputs.map (·.sourceInfo) }
      members := owned }
  let equations ← (List.range headers.length).mapM fun index => do
    let some header := headers[index]?
      | throw (psElabMutualStructuralError "OWNERSHIP" "equation has no header")
    (psElabMutualStructuralEquation staged levels plan index).mapError (.atDeclaration header.name)
  let _ ← psAddDeclarationList staged equations
  let owned := ((declarations.zip equations).zip inputs).map fun ((declaration, equation), input) =>
    ({
      declarations := [declaration, equation]
      sourceInfo := [input.sourceInfo] } : PsElabDeclarationBatchResult)
  return {
    batch := {
      declarations := declarations ++ equations
      sourceInfo := inputs.map (·.sourceInfo) }
    members := owned }

-- An SCC must retain the original block-wide universe layout even when one
-- of those levels belongs only to a disconnected source member. All real
-- definitions and their exact source equations use this same fixed layout.
def psElabStructuralMutualFromChecked (environment : PsEnvironment)
    (levelNames : List PsName) (captured : PsElabTypedBindersResult)
    (inputs : List PsElabMutualStructuralInput) (emitEquations : Bool := true) :
    Except PsElabError PsElabMutualBatchResult :=
  psElabMutualStructuralClose environment levelNames captured inputs true emitEquations

def psElabStructuralMutualBatch (environment : PsEnvironment) (levelNames : List PsName)
    (capturedSyntax : List PsScopeBinder) (members : List PsScopedMutualMember) :
    Except PsElabError PsElabMutualBatchResult := do
  if members.isEmpty then throw (.data "PSCV0-MUTUAL-EMPTY: mutual requires def/function members")
  let captured ← psElabTypedBinders psElabTerm (psElabContextEmpty environment levelNames) capturedSyntax
  let headers ← members.mapM fun member => do
    let name := (psSyntaxNameToName (psElabOriginSource member.source).fst).getD .anonymous
    (psElabMutualStructuralHeader captured member).mapError (.atDeclaration name)
  let ownedNames := headers.flatMap fun header => [header.name, psNameAppendStr header.name "eq_def"]
  for name in ownedNames do
    if (psEnvironmentFind environment name).isSome ||
        (ownedNames.filter (psNameEq name)).length != 1 then
      throw (.duplicateDeclaration name)
  let inputs ← (headers.zip members).mapM fun (header, member) =>
    (psElabMutualStructuralInputFor captured headers members header member).mapError
      (.atDeclaration header.name)
  psElabMutualStructuralClose environment levelNames captured inputs false

