import Ps.Elab.Mutual
import Ps.Elab.Match
import Ps.Elab.RecursorEquation
import Ps.Meta.Recursor

-- Direct structural mutual definitions use the same ownership invariant as
-- pinned Lean Structural.Positions: every source function occupies exactly
-- one ordered component of its actual inductive family's motive. The source
-- may assign zero, one or several functions to a family. This selected owner
-- uses ordinary recursors and direct fields, not the separate below/brecOn
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

structure PsElabMutualStructuralInput where
  header : PsElabPartialHeader
  span : PsSourceSpan
  ownBinders : List PsElabTypedBinder
  context : PsElabContext
  body : PsExpr
  peers : List (Nat × Nat)
  application : PsGroupRecursorApplication
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
      return (psElabContextWithLocal state.fst pushed.context,
        state.snd ++ [(pushed.id, entry.snd)])) (context, [])

-- This boundary consumes a checked Core body, not lifted or reconstructed
-- source syntax. Full peers have already been specialized at the validated
-- common capture prefix. All original member-specific header slots remain.
def psElabMutualStructuralInputFromChecked (captured : PsElabTypedBindersResult)
    (header : PsElabPartialHeader) (checkedContext : PsElabContext)
    (body : PsExpr) (peers : List (Nat × Nat)) (span : PsSourceSpan)
    (sourceInfo : PsElabSourceInfo) :
    Except PsElabError PsElabMutualStructuralInput := do
  let checked ← psElabResolvedTerm checkedContext body (some header.openType)
  let context := checked.context
  let ownBinders := (header.bindersRev.reverse.drop captured.bindersRev.length).map fun binder =>
    { binder with type := psMetaInstantiate checked.context.metaContext binder.type }
  let body := psMetaInstantiate checked.context.metaContext checked.term
  if psExprHasUnresolvedMeta body then throw .unresolvedMetavariable
  let some application := psGroupRecursorApplication context.environment body
    | throw (psElabMutualStructuralError "ROOT" "checked root match has no complete registered recursor view")
  if psGroupRecursorUsesHypotheses context.environment application then
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
  let majorType := psExprAppView (psWhnf context.environment checked.context.metaContext
    context.localContext major.type)
  let .constE owner familyLevels := majorType.head
    | throw (psElabMutualStructuralError "MAJOR" "major type is not an instantiated group family")
  if !psNameEq owner application.family.name ||
      majorType.args.length != application.family.numParams + application.family.numIndices then
    throw (psElabMutualStructuralError "MAJOR" "major family telescope does not match its recursor")
  return {
    header, span, ownBinders
    context := checked.context
    body, peers, application, familyLevels, majorId, indexIds
    sourceInfo }

def psElabMutualStructuralInputFor (captured : PsElabTypedBindersResult)
    (headers : List PsElabPartialHeader) (members : List PsScopedMutualMember)
    (header : PsElabPartialHeader) (member : PsScopedMutualMember) :
    Except PsElabError PsElabMutualStructuralInput := do
  let .definition _ _ _ sourceBody span := member.source
    | throw (psElabMutualStructuralError "STRATEGY" "expected an ordinary body")
  match sourceBody with
  | .matchMany [.reference _] _ _ => pure ()
  | _ => throw (psElabMutualStructuralError "ROOT" "selected direct structural body requires a root match on one explicit header parameter")
  let (context, peers) ← psElabMutualStructuralPeers header.context
    (psElabBinderArguments captured.bindersRev) headers members
  let checked ← psElabTerm context sourceBody (some header.openType)
  psElabMutualStructuralInputFromChecked captured header checked.context checked.term peers
    span (psElabFinishSourceInfo checked.context header.name)

structure PsElabMutualStructuralFunction where
  input : PsElabMutualStructuralInput
  fixed : List (Nat × PsExpr)
  stateBinders : List PsElabTypedBinder

structure PsElabMutualStructuralPlan where
  context : PsElabContext
  capturesRev : List PsElabTypedBinder
  fixedRev : List PsElabTypedBinder
  group : PsInductiveGroupPlan
  familyLevels : List PsLevel
  uniformArgs : List PsExpr
  functions : List PsElabMutualStructuralFunction
  positions : List (PsName × List Nat)

-- Only uniform datatype parameters introduce additional fixed header
-- variables. Other header arguments are generalized into their component's
-- motive, whether a particular call changes them or happens to preserve them.
-- This conservative policy needs no guessed whole-call-graph invariance.
def psElabMutualStructuralFixedSeed (context : PsElabContext)
    (input : PsElabMutualStructuralInput) :
    Except PsElabError (PsElabContext × List PsElabTypedBinder × List PsExpr) := do
  let args := input.application.fixedArgs.take input.application.info.numParams
  let (context, bindersRev, _, uniformArgs) ← args.foldlM
    (fun (state : PsElabContext × List PsElabTypedBinder × List (Nat × PsExpr) × List PsExpr) arg => do
      let (current, bindersRev, replacements, previous) := state
      let value := psElabSubstituteLocals replacements arg
      if psExprFVarsInContext current.localContext value then
        return (current, bindersRev, replacements, previous ++ [value])
      let .fvar id := arg
        | throw (psElabMutualStructuralError "FIXED" "computed uniform parameters must already resolve in the common capture context")
      let some binder := input.ownBinders.find? (fun binder => binder.id == id)
        | throw (psElabMutualStructuralError "FIXED" "uniform parameter is not owned by the checked header")
      if id == input.majorId || input.indexIds.contains id then
        throw (psElabMutualStructuralError "FIXED" "a datatype parameter cannot be the major or an index")
      let domain := psElabSubstituteLocals replacements binder.type
      if !psExprFVarsInContext current.localContext domain then
        throw (psElabMutualStructuralError "FIXED-DEPENDENCY" "uniform parameter domain depends on an unfixed header variable")
      let _ ← psElabExpressionSort current domain
      let pushed := psLocalPushBinding current.localContext binder.name domain binder.binder
      let value := PsExpr.fvar pushed.id
      return (psElabContextWithLocal current pushed.context,
        PsElabTypedBinder.mk pushed.id binder.name domain binder.binder :: bindersRev,
        replacements ++ [(id, value)], previous ++ [value]))
    (context, [], [], [])
  return (context, bindersRev, uniformArgs)

def psElabMutualStructuralFixedMap (context : PsElabContext)
    (fixedRev : List PsElabTypedBinder) (uniformArgs : List PsExpr)
    (input : PsElabMutualStructuralInput) : Except PsElabError (List (Nat × PsExpr)) := do
  let args := input.application.fixedArgs.take input.application.info.numParams
  if args.length != uniformArgs.length then
    throw (psElabMutualStructuralError "FIXED" "uniform parameter counts differ")
  let replacements ← (args.zip uniformArgs).foldlM
    (fun replacements (arg, expected) => do
      let value := psElabSubstituteLocals replacements arg
      if psExprFVarsInContext context.localContext value then
        if psElabMutualStructuralEqual context value expected then return replacements
        throw (psElabMutualStructuralError "FIXED" "uniform parameter expressions differ in the common context")
      let .fvar id := arg
        | throw (psElabMutualStructuralError "FIXED" "computed header parameter reconstruction is unavailable")
      let some binder := input.ownBinders.find? (fun binder => binder.id == id)
        | throw (psElabMutualStructuralError "FIXED" "uniform parameter has no header owner")
      let .fvar fixedId := expected
        | throw (psElabMutualStructuralError "FIXED" "a free header parameter cannot be identified with a captured expression")
      if !fixedRev.any (fun fixed => fixed.id == fixedId) ||
          id == input.majorId || input.indexIds.contains id then
        throw (psElabMutualStructuralError "FIXED" "fixed header mapping is not a uniform-parameter correspondence")
      let domain := psElabSubstituteLocals replacements binder.type
      if !psExprFVarsInContext context.localContext domain then
        throw (psElabMutualStructuralError "FIXED-DEPENDENCY" "fixed domain depends on a varying header parameter")
      let actual ← (psInferType context.environment context.metaContext
        context.localContext expected).mapError PsElabError.infer
      if !psElabMutualStructuralEqual context domain actual then
        throw (psElabMutualStructuralError "FIXED" "fixed parameter domains differ after alpha-renaming")
      return replacements ++ [(id, expected)]) ([] : List (Nat × PsExpr))
  for fixed in fixedRev do
    if (replacements.filter (fun entry => psExprAlphaEq entry.snd (.fvar fixed.id))).length != 1 then
      throw (psElabMutualStructuralError "FIXED" "fixed correspondence is not invertible for every member")
  return replacements

def psElabMutualStructuralPrepare (captured : PsElabTypedBindersResult)
    (inputs : List PsElabMutualStructuralInput) : Except PsElabError PsElabMutualStructuralPlan := do
  let first :: _ := inputs
    | throw (psElabMutualStructuralError "OWNERSHIP" "empty structural batch")
  let nextId := inputs.foldl (fun id input => max id input.context.localContext.nextId)
    captured.context.localContext.nextId
  let initial := psElabContextWithLocal captured.context {
    captured.context.localContext with nextId := nextId + 1 }
  let (context, fixedRev, uniformArgs) ← psElabMutualStructuralFixedSeed initial first
  let functions ← inputs.mapM fun input => do
    if !psInductiveGroupNamesEqual (psInductiveGroupNames input.application.group)
        (psInductiveGroupNames first.application.group) ||
        input.familyLevels.length != first.familyLevels.length ||
        !(input.familyLevels.zip first.familyLevels).all (fun pair =>
          psLevelEquivalent pair.fst pair.snd) then
      throw (psElabMutualStructuralError "GROUP" "members do not recurse over the same complete instantiated group")
    let fixed ← psElabMutualStructuralFixedMap context fixedRev uniformArgs input
    let stateBinders := input.ownBinders.filter fun binder =>
      binder.id != input.majorId && !input.indexIds.contains binder.id &&
        !fixed.any (fun entry => entry.fst == binder.id)
    return { input, fixed, stateBinders : PsElabMutualStructuralFunction }
  let positions := first.application.group.members.map fun family =>
    (family.name, functions.zipIdx.filterMap fun entry =>
      if psNameEq entry.fst.input.application.family.name family.name then some entry.snd else none)
  let owned := positions.flatMap Prod.snd
  if owned.length != functions.length ||
      !(List.range functions.length).all (fun index => (owned.filter (· == index)).length == 1) then
    throw (psElabMutualStructuralError "OWNERSHIP" "family components are not an exact source-function permutation")
  return {
    context, capturesRev := captured.bindersRev, fixedRev
    group := first.application.group
    familyLevels := first.familyLevels
    uniformArgs, functions, positions }

def psElabMutualStructuralPositions (plan : PsElabMutualStructuralPlan)
    (family : PsName) : Except PsElabError (List Nat) := do
  let some (_, positions) := plan.positions.find? (fun entry => psNameEq entry.fst family)
    | throw (psElabMutualStructuralError "OWNERSHIP" "family has no component-position record")
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
  let family := fn.input.application.family
  let applied ← psElabApplyCore plan.context (.constE family.name plan.familyLevels) plan.uniformArgs
  let indices ← psElabOpenCoreTelescope 4096 applied.context applied.type (some family.numIndices)
  let args := psElabBinderArguments indices.bindersRev
  let majorType := psExprApplyMany applied.term args
  let pushed := psLocalPushBinding indices.context.localContext (psRootName "_mutualMajor") majorType .explicit
  let context := psElabContextWithLocal indices.context pushed.context
  let type ← psElabMutualStructuralComponentType context fn args (.fvar pushed.id)
  let level ← psElabExpressionSort context type
  match psLevelNormalize level with
  | .succ _ => return level
  | _ => throw (psElabMutualStructuralError "SORT" "selected packed motives must be Type-valued at a resolved successor universe")

-- The level comes from the actual registered motive domain. Prod's argument
-- universes are its predecessor; PUnit receives the complete Sort level.
-- Both applications are then inferred against that exact domain.
def psElabMutualStructuralPackType (context : PsElabContext) (level : PsLevel)
    (types : List PsExpr) : Except PsElabError PsExpr := do
  match types with
  | [] => return (← psElabMatchUnit context level).fst
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
    let .succ argumentLevel := psLevelNormalize level
      | throw (psElabMutualStructuralError "SORT" "Prod packing requires a Type-valued motive")
    let packed ← psElabApplyCore context (.constE psProdName [argumentLevel, argumentLevel]) [left, right]
    let checked ← psElabResolvedTerm packed.context packed.term (some (.sortE level))
    return psMetaInstantiate checked.context.metaContext checked.term

def psElabMutualStructuralPackValue (context : PsElabContext) (level : PsLevel)
    (values : List PsExpr) : Except PsElabError PsExpr := do
  match values with
  | [] => return (← psElabMatchUnit context level).snd
  | [value] => return value
  | left :: rest =>
    let right ← psElabMutualStructuralPackValue context level rest
    let leftType ← (psInferType context.environment context.metaContext
      context.localContext left).mapError PsElabError.infer
    let rightType ← (psInferType context.environment context.metaContext
      context.localContext right).mapError PsElabError.infer
    let expected ← psElabMutualStructuralPackType context level [leftType, rightType]
    let .succ argumentLevel := psLevelNormalize level
      | throw (psElabMutualStructuralError "SORT" "Prod values require a Type-valued motive")
    let packed ← psElabApplyCore context
      (.constE (psNameAppendStr psProdName "mk") [argumentLevel, argumentLevel])
      [leftType, rightType, left, right]
    let checked ← psElabResolvedTerm packed.context packed.term (some expected)
    return psMetaInstantiate checked.context.metaContext checked.term

def psElabMutualStructuralProject (context : PsElabContext)
    (count position : Nat) (value : PsExpr) : Except PsElabError PsExpr := do
  match count with
  | 0 => throw (psElabMutualStructuralError "OWNERSHIP" "an empty family has no function component")
  | 1 =>
    if position == 0 then return value
    throw (psElabMutualStructuralError "OWNERSHIP" "component position exceeds its family")
  | count + 2 =>
    let index := if position == 0 then 0 else 1
    let projected ← psElabResolvedTerm context (.proj psProdName index value) none
    if position == 0 then return projected.term
    psElabMutualStructuralProject context (count + 1) (position - 1) projected.term

structure PsElabMutualStructuralFamily where
  info : PsInductiveInfo
  indices : List PsExpr

def psElabMutualStructuralFamilyView (plan : PsElabMutualStructuralPlan)
    (context : PsElabContext) (type : PsExpr) :
    Except PsElabError (Option PsElabMutualStructuralFamily) := do
  let view := psExprAppView (psWhnf context.environment context.metaContext context.localContext type)
  let .constE name levels := view.head | return none
  let some info := psInductiveGroupFind plan.group name | return none
  if levels.length != plan.familyLevels.length ||
      !(levels.zip plan.familyLevels).all (fun pair => psLevelEquivalent pair.fst pair.snd) ||
      view.args.length != info.numParams + info.numIndices ||
      info.numParams != plan.uniformArgs.length ||
      !(plan.uniformArgs.zip (view.args.take info.numParams)).all (fun pair =>
        psElabMutualStructuralEqual context pair.fst pair.snd) then
    throw (psElabMutualStructuralError "FAMILY" "actual family application has incompatible levels, parameters or indices")
  return some { info, indices := view.args.drop info.numParams }

def psElabMutualStructuralMotiveAt (motives : List (PsName × PsExpr))
    (family : PsElabMutualStructuralFamily) (major : PsExpr) : Except PsElabError PsExpr := do
  let some (_, motive) := motives.find? (fun entry => psNameEq entry.fst family.info.name)
    | throw (psElabMutualStructuralError "OWNERSHIP" "actual child family has no motive")
  return psExprApplyMany motive (family.indices ++ [major])

structure PsElabMutualStructuralChild where
  fieldId : Nat
  family : PsElabMutualStructuralFamily
  hypothesis : PsExpr

def psElabMutualStructuralChildren (plan : PsElabMutualStructuralPlan)
    (context : PsElabContext) (motives : List (PsName × PsExpr))
    (constructor : PsConstructorInfo) (fields hypotheses : List PsElabTypedBinder) :
    Except PsElabError (List PsElabMutualStructuralChild) := do
  if !psConstructorRecursiveFieldsOrdered constructor ||
      fields.length != constructor.numFields ||
      hypotheses.length != constructor.recursiveFields.length then
    throw (psElabMutualStructuralError "FIELD-METADATA" "constructor fields and actual ordered hypotheses disagree")
  for (field, index) in fields.zipIdx do
    let family ← psElabMutualStructuralFamilyView plan context field.type
    if constructor.recursiveFields.contains index then
      if family.isNone then
        throw (psElabMutualStructuralError "DIRECT-FIELD" "function-valued or nested recursive fields require a separate structural construction")
    else if family.isSome then
      throw (psElabMutualStructuralError "FIELD-METADATA" "a direct child is absent from recursive metadata")
  (constructor.recursiveFields.zip hypotheses).mapM fun (index, hypothesis) => do
    let some field := fields[index]?
      | throw (psElabMutualStructuralError "FIELD-METADATA" "hypothesis has no corresponding field")
    let some family ← psElabMutualStructuralFamilyView plan context field.type
      | throw (psElabMutualStructuralError "DIRECT-FIELD" "hypothesis is not for a direct group child")
    let expected ← psElabMutualStructuralMotiveAt motives family (.fvar field.id)
    if !psElabMutualStructuralEqual context hypothesis.type expected then
      throw (psElabMutualStructuralError "IH-TYPE" "actual induction hypothesis does not belong to this child")
    return { fieldId := field.id, family, hypothesis := .fvar hypothesis.id }

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
  let .fvar childId := psWhnf context.environment context.metaContext context.localContext major
    | throw (psElabMutualStructuralError "DECREASE" "recursive major is not an actual strict constructor field")
  let some child := children.find? (fun child => child.fieldId == childId)
    | throw (psElabMutualStructuralError "DECREASE" "recursive major has no checked strict-child hypothesis")
  if !psNameEq child.family.info.name target.input.application.family.name then
    throw (psElabMutualStructuralError "CHILD-FAMILY" "peer is assigned to a different child family")
  let indices ← target.input.indexIds.mapM (psElabMutualStructuralMappedArgument actuals)
  if indices.length != child.family.indices.length ||
      !(indices.zip child.family.indices).all (fun pair =>
        psElabMutualStructuralEqual context pair.fst pair.snd) then
    throw (psElabMutualStructuralError "CHILD-INDICES" "peer indices do not match the actual recursive field")
  psElabMutualStructuralCheckMapping context target actuals
  let expected ← psElabMutualStructuralApplyType context target.input.header.type
    (psElabBinderArguments plan.capturesRev ++ args)
  let positions ← psElabMutualStructuralPositions plan child.family.info.name
  let some (_, position) := positions.zipIdx.find? (fun entry => entry.fst == targetIndex)
    | throw (psElabMutualStructuralError "OWNERSHIP" "peer is absent from the child's component list")
  let selected ← psElabMutualStructuralProject context positions.length position child.hypothesis
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

def psElabMutualStructuralBranch (plan : PsElabMutualStructuralPlan)
    (context : PsElabContext) (fn : PsElabMutualStructuralFunction)
    (family : PsElabMutualStructuralFamily) (major : PsExpr)
    (children : List PsElabMutualStructuralChild) : Except PsElabError PsExpr := do
  let type ← psElabMutualStructuralComponentType context fn family.indices major
  let states ← psElabOpenCoreTelescope 4096 context type (some fn.stateBinders.length)
  let replacements ← psElabMutualStructuralSourceMap fn family.indices major
    (psElabBinderArguments states.bindersRev)
  psElabMutualStructuralCheckMapping states.context fn replacements
  let source := psElabSubstituteLocals replacements fn.input.body
  let some reduced := psReduceIota
      (psWhnf states.context.environment states.context.metaContext states.context.localContext)
      states.context.environment source
    | throw (psElabMutualStructuralError "IOTA" "the checked source case did not select this real constructor")
  let branch := psWhnf states.context.environment states.context.metaContext
    states.context.localContext reduced
  let value ← psElabMutualStructuralRewrite 4096 plan fn.input states.context children branch
  let checked ← psElabResolvedTerm states.context value (some states.body)
  let term := psCloseElabLambdaBinders checked.context.metaContext states.bindersRev checked.term
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
  let recursor ← psElabGroupRecursorPlanFor plan.context first.input.application.family
    plan.familyLevels plan.uniformArgs level
  let constructors ← psElabGroupConstructors recursor.context recursor.group
  let motives ← psElabRecursorArguments recursor.group.members
    (fun current family domain => do
      let opened ← psElabOpenCoreTelescope 4096 current domain (some (family.numIndices + 1))
      let major :: indicesRev := opened.bindersRev
        | throw (psElabMutualStructuralError "MOTIVE" "registered motive has no major binder")
      let .sortE actualLevel := psWhnf opened.context.environment opened.context.metaContext
          opened.context.localContext opened.body
        | throw (psElabMutualStructuralError "MOTIVE" "registered motive does not end in a Sort")
      let some actual ← psElabMutualStructuralFamilyView plan opened.context major.type
        | throw (psElabMutualStructuralError "MOTIVE" "registered motive major is not an actual group family")
      let indices := psElabBinderArguments indicesRev
      if !psNameEq actual.info.name family.name ||
          actual.indices.length != indices.length ||
          !(actual.indices.zip indices).all (fun pair =>
            psElabMutualStructuralEqual opened.context pair.fst pair.snd) then
        throw (psElabMutualStructuralError "MOTIVE" "registered motive does not bind this family's own indices")
      let positions ← psElabMutualStructuralPositions plan family.name
      let types ← positions.mapM fun position => do
        let some fn := plan.functions[position]?
          | throw (psElabMutualStructuralError "OWNERSHIP" "component function is absent")
        psElabMutualStructuralComponentType opened.context fn indices (.fvar major.id)
      let type ← psElabMutualStructuralPackType opened.context actualLevel types
      return {
        context := psElabLeaveScope current opened.context
        term := psCloseElabLambdaBinders opened.context.metaContext opened.bindersRev type })
    recursor.context recursor.cursor
  let motivesByFamily := (recursor.group.members.zip motives.arguments).map fun pair =>
    (pair.fst.name, pair.snd)
  let minors ← psElabRecursorArguments constructors
    (fun current (owner, constructor) domain => do
      let opened ← psElabOpenCoreTelescope 4096 current domain
        (some (constructor.numFields + constructor.recursiveFields.length))
      let binders := opened.bindersRev.reverse
      let fields := binders.take constructor.numFields
      let children ← psElabMutualStructuralChildren plan opened.context motivesByFamily
        constructor fields (binders.drop constructor.numFields)
      let major := psExprApplyMany (.constE constructor.name plan.familyLevels)
        (plan.uniformArgs ++ fields.map (fun field => .fvar field.id))
      let majorType ← (psInferType opened.context.environment opened.context.metaContext
        opened.context.localContext major).mapError PsElabError.infer
      let some family ← psElabMutualStructuralFamilyView plan opened.context majorType
        | throw (psElabMutualStructuralError "CONSTRUCTOR" "constructor does not return a group family")
      if !psNameEq family.info.name owner.name then
        throw (psElabMutualStructuralError "CONSTRUCTOR" "constructor owner changed during minor construction")
      let expected ← psElabMutualStructuralMotiveAt motivesByFamily family major
      if !psElabMutualStructuralEqual opened.context opened.body expected then
        throw (psElabMutualStructuralError "MINOR" "actual minor conclusion differs from its owned motive")
      let positions ← psElabMutualStructuralPositions plan owner.name
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
  let called ← psElabApplyCore context
    (.constE (psNameAppendStr fn.input.application.family.name "rec") recursor.levels)
    (arguments ++ indices ++ [major])
  let positions ← psElabMutualStructuralPositions plan fn.input.application.family.name
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
    (retainBlockLevels : Bool) :
    Except PsElabError PsElabMutualBatchResult := do
  let headers := inputs.map (·.header)
  let ownedNames := headers.flatMap fun header => [header.name, psNameAppendStr header.name "eq_def"]
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
    (inputs : List PsElabMutualStructuralInput) :
    Except PsElabError PsElabMutualBatchResult :=
  psElabMutualStructuralClose environment levelNames captured inputs true

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

