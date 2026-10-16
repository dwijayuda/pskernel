import Ps.Elab.Class
import Ps.Elab.GroupElimination

-- A handler works in one ordinary local telescope. Uniform parameters retain
-- their identities; generated requirements are tracked separately so handlers
-- can choose their dependency policy without inventing another elaborator.
structure PsElabDeriveContext where
  info : PsInductiveInfo
  group : PsInductiveGroupPlan
  context : PsElabContext
  parametersRev : List PsElabTypedBinder
  indicesRev : List PsElabTypedBinder := []
  requirementsRev : List PsElabTypedBinder := []
  family : PsExpr

structure PsElabDeriveCapabilities where
  groups : Bool := false
  indices : Bool := false

def psElabDeriveSourceFamily (origin : PsElabBatchOrigin) : Except PsElabError PsName := do
  let some member := origin.members.find? (fun member =>
    match member.role with
    | .inductiveType | .structureType => true
    | _ => false)
    | throw (.data "deriving requires an inductive/structure declaration")
  return member.name

def psElabDerivePrepare (environment : PsEnvironment)
    (origin : PsElabBatchOrigin) (capabilities : PsElabDeriveCapabilities := {}) :
    Except PsElabError PsElabDeriveContext := do
  let name ← psElabDeriveSourceFamily origin
  let some info := psEnvironmentFindInductive environment name
    | throw (.data "derived family is not an inductive")
  let some group := psInductiveGroupPlanFor
      (psEnvironmentFindInductive environment) (psEnvironmentFindRecursor environment) info
    | throw (.data "deriving requires a complete inductive group")
  if !capabilities.groups && group.members.length != 1 then
    throw (.data "deriving handler requires a singleton family")
  if !capabilities.indices && group.members.any (·.numIndices != 0) then
    throw (.data "deriving indexed families is not yet implemented")
  let parameters ← psElabOpenCoreTelescope 4096
    (psElabContextEmpty environment info.levelParams) info.type (some info.numParams)
  let indices ← psElabOpenCoreTelescope 4096 parameters.context parameters.body (some info.numIndices)
  let family := psExprApplyMany (.constE info.name (info.levelParams.map PsLevel.param))
    (psElabBinderArguments parameters.bindersRev ++ psElabBinderArguments indices.bindersRev)
  return {
    info, group
    context := indices.context
    parametersRev := parameters.bindersRev.map fun binder => { binder with binder := .implicit }
    indicesRev := indices.bindersRev.map fun binder => { binder with binder := .implicit }
    family }

def psElabDeriveConstructorNames (plan : PsElabDeriveContext) : List PsName :=
  plan.group.members.flatMap (·.constructors)

-- Binary comparison currently needs homogeneous, nonindexed right-hand
-- families. Changing the selected member retains the same parameter IDs and
-- requirements; it does not introduce a dictionary for that member.
def psElabDeriveAtMember (plan : PsElabDeriveContext) (info : PsInductiveInfo) :
    Except PsElabError PsElabDeriveContext := do
  let some registered := psInductiveGroupFind plan.group info.name
    | throw (.data "deriving member is outside the complete group")
  if registered.numIndices != 0 then
    throw (.data "deriving indexed families is not yet implemented")
  return {
    plan with
    info := registered
    indicesRev := []
    family := psExprApplyMany (.constE registered.name (registered.levelParams.map PsLevel.param))
      (psElabBinderArguments plan.parametersRev) }

-- Reuse ordinary constant freshening and unification. Inhabited accepts Sort u;
-- BEq accepts Type u. A value parameter such as n : Nat is not a type parameter
-- and must never acquire a fabricated class requirement.
def psElabDeriveClassType (context : PsElabContext) (className : PsName)
    (argument : PsExpr) : Except PsElabError PsExpr := do
  let (fresh, head) ← psElabResolvedReference context (.global className)
  let applied ← psElabApplyCore fresh head [argument]
  let target := applied.term
  if psExprHasUnresolvedMeta target then throw .unresolvedMetavariable
  let _ ← psElabExpressionSort context target
  return target

def psElabDeriveRequirements (plan : PsElabDeriveContext) (className : PsName) :
    PsElabDeriveContext :=
  plan.parametersRev.reverse.foldl (fun plan parameter =>
    match psElabDeriveClassType plan.context className (.fvar parameter.id) with
    | .error _ => plan
    | .ok type =>
      let name := psNameAppendStr parameter.name "inst"
      let pushed := psLocalPushBinding plan.context.localContext name type .instanceImplicit
      { plan with
        context := psElabContextWithLocal plan.context pushed.context
        requirementsRev := .mk pushed.id name type .instanceImplicit :: plan.requirementsRev }) plan

def psElabDeriveInstance (context : PsElabContext) (target : PsExpr) :
    Except PsElabError PsExpr := do
  let result := psSynthInstance context.environment context.localContext context.instances
    context.metaContext target
  let some value := result.value | throw (.data "deriving field has no checked instance")
  let value := psMetaInstantiate result.context value
  if psExprHasUnresolvedMeta value then throw .unresolvedMetavariable
  if !psExprFVarsInContext context.localContext value then
    throw (.data "deriving instance escaped its parameter context")
  return value

def psElabDeriveConstructor (plan : PsElabDeriveContext) (constructor : PsConstructorInfo) :
    Except PsElabError (PsExpr × PsExpr) := do
  let some owner := psInductiveGroupFind plan.group constructor.inductiveName
    | throw (.data "deriving constructor is outside the complete group")
  let some registeredName := owner.constructors[constructor.constructorIndex]?
    | throw (.data "deriving constructor ordinal mismatch")
  let levels := plan.info.levelParams.map PsLevel.param
  if !psNameEq registeredName constructor.name ||
      constructor.numParams != plan.info.numParams ||
      !psInductiveGroupNamesEqual constructor.levelParams plan.info.levelParams then
    throw (.data "deriving constructor parameter telescope mismatch")
  let arguments := psElabBinderArguments plan.parametersRev
  let type := psExprInstantiateLevelParams constructor.levelParams levels constructor.type
  let cursor ← psElabProjectionApplyParameters plan.context arguments type
  return (psExprApplyMany (.constE constructor.name levels) arguments, cursor)

def psElabDeriveFinish (plan : PsElabDeriveContext) (suffix : String)
    (type value : PsExpr) (pruneRequirements : Bool := false) :
    Except PsElabError PsDeclaration := do
  -- Requirement domains mention family parameters only. Consequently occurrence
  -- in the value is sufficient; no hidden requirement-to-requirement dependency
  -- can be lost when Inhabited drops an unused assumption.
  let requirements := if pruneRequirements then
      plan.requirementsRev.filter fun binder =>
        !psExprAlphaEq value (psExprAbstractFVar binder.id value)
    else plan.requirementsRev
  let (value, type) := psCloseElabTypedBinders plan.context.metaContext
    (requirements ++ plan.indicesRev ++ plan.parametersRev) value type
  if psExprHasUnresolvedMeta value || psExprHasUnresolvedMeta type then
    throw .unresolvedMetavariable
  if !psExprFVarsInContext psLocalEmpty value || !psExprFVarsInContext psLocalEmpty type then
    throw (.data "derived declaration contains an unbound local")
  return .definitionDecl (psNameAppendStr plan.info.name suffix) plan.info.levelParams type value

-- Runtime fields must have homogeneous types in the parameter telescope.
-- Proof fields may depend on earlier values: they carry no comparison payload,
-- and DecidableEq transports them with the existing dependent-context machinery.
structure PsElabDeriveFamily where
  info : PsInductiveInfo
  type : PsExpr
  indices : List PsExpr

-- A direct child may belong to any member and use its own constructor indices.
-- Only the uniform parameters and universe layout are shared. A function or
-- nested container around a child is deliberately not a direct family view.
def psElabDeriveFamilyView (plan : PsElabDeriveContext) (context : PsElabContext)
    (type : PsExpr) : Except PsElabError (Option PsElabDeriveFamily) := do
  let view := psExprAppView
    (psWhnf context.environment context.metaContext context.localContext type)
  let .constE name levels := view.head | return none
  let some info := psInductiveGroupFind plan.group name | return none
  let expectedLevels := plan.info.levelParams.map PsLevel.param
  let parameters := psElabBinderArguments plan.parametersRev
  if view.args.length != info.numParams + info.numIndices ||
      levels.length != expectedLevels.length ||
      !(levels.zip expectedLevels).all (fun pair => psLevelEquivalent pair.fst pair.snd) ||
      !(parameters.zip (view.args.take info.numParams)).all (fun pair =>
        psDefEqReadOnlyWithEnv context.environment context.metaContext
          context.localContext pair.fst pair.snd) then
    throw (.data "deriving family application has incompatible parameters or indices")
  return some { info, type, indices := view.args.drop info.numParams }

structure PsElabDeriveFields where
  constructor : PsConstructorInfo
  cursor : PsExpr
  fields : List PsElabTypedBinder
  proofs : List Bool

-- Recursion is an explicit handler capability, not permission to bypass the
-- family/field checks. Direct recursive fields must agree with both metadata
-- and an instantiated member of the complete group. Only those field types
-- may depend on constructor indices; ordinary dictionary planning remains in
-- the shared parameter telescope. Nested/function-valued recursion is separate.
def psElabDeriveFieldsWithRecursion (plan : PsElabDeriveContext) (name : PsName)
    (allowDirectRecursion : Bool) : Except PsElabError PsElabDeriveFields := do
  let some constructor := psEnvironmentFindConstructor plan.context.environment name
    | throw (.data "deriving constructor missing")
  if !allowDirectRecursion && !constructor.recursiveFields.isEmpty then
    throw (.data "recursive deriving requires the M3 data machinery")
  if !psConstructorRecursiveFieldsOrdered constructor then
    throw (.data "deriving recursive field metadata is invalid")
  let (_, cursor) ← psElabDeriveConstructor plan constructor
  let opened ← psElabOpenCoreTelescope 4096 plan.context cursor (some constructor.numFields)
  let fields := opened.bindersRev.reverse
  let proofs ← fields.zipIdx.mapM fun (field, index) => do
    let recursive := constructor.recursiveFields.contains index
    let child ← psElabDeriveFamilyView plan opened.context field.type
    if recursive then
      let some _ := child
        | throw (.data "deriving recursive field is not a uniform direct group family")
      pure ()
    else if child.isSome then
      throw (.data "deriving direct field is absent from recursive metadata")
    let level ← psElabExpressionSort opened.context field.type
    if psLevelEquivalent level .zero then return true
    if !recursive && !psExprFVarsInContext plan.context.localContext field.type then
      throw (.data "deriving requires independent runtime field types")
    if plan.group.members.any (fun member => psExprHasConst member.name field.type) &&
        !(allowDirectRecursion && recursive) then
      throw (.data "recursive deriving requires the M3 data machinery")
    return false
  let some result ← psElabDeriveFamilyView plan opened.context opened.body
    | throw (.data "deriving constructor result mismatch")
  if !psNameEq result.info.name constructor.inductiveName then
    throw (.data "deriving constructor result mismatch")
  return { constructor, cursor, fields, proofs }

def psElabDeriveFields (plan : PsElabDeriveContext) (name : PsName) :
    Except PsElabError PsElabDeriveFields :=
  psElabDeriveFieldsWithRecursion plan name false

def psElabDeriveMotiveAt (motives : List (PsName × PsExpr))
    (family : PsElabDeriveFamily) (value : PsExpr) : Except PsElabError PsExpr := do
  let some (_, motive) := motives.find? (fun entry => psNameEq entry.fst family.info.name)
    | throw (.data "deriving member motive is missing")
  return psExprApplyMany motive (family.indices ++ [value])

-- One induction owner supplies every motive and every minor of the complete
-- registered group. A result callback receives the actual member type at its
-- own indices. Branches receive only real, checked recursor hypotheses keyed
-- by field ID; no recursive dictionary or partial definition is introduced.
def psElabDeriveEliminateGroup (plan : PsElabDeriveContext)
    (context : PsElabContext) (allowDirectRecursion : Bool)
    (result : PsInductiveInfo → PsExpr → PsExpr → PsExpr)
    (branch : PsElabContext → PsInductiveInfo → PsConstructorInfo → List PsElabTypedBinder →
      List (Nat × PsExpr) → PsExpr → Except PsElabError PsExpr) :
    Except PsElabError PsExpr := do
  let major := psLocalPushBinding context.localContext (psRootName "value") plan.family .explicit
  let inner := psElabContextWithLocal context major.context
  let resultType := result plan.info plan.family (.fvar major.id)
  let level ← psElabExpressionSort inner resultType
  let parameters := psElabBinderArguments plan.parametersRev
  let recursor ← psElabGroupRecursorPlanFor context plan.info
    (plan.info.levelParams.map PsLevel.param) parameters level
  if !psInductiveGroupNamesEqual (psInductiveGroupNames recursor.group)
      (psInductiveGroupNames plan.group) then
    throw (.data "deriving group changed after preparation")
  let constructors ← psElabGroupConstructors recursor.context recursor.group
  let motives ← psElabRecursorArguments recursor.group.members
    (fun current info type => do
      let opened ← psElabOpenCoreTelescope 4096 current type (some (info.numIndices + 1))
      let major :: indicesRev := opened.bindersRev
        | throw (.data "deriving motive has no major premise")
      let some family ← psElabDeriveFamilyView plan opened.context major.type
        | throw (.data "deriving motive major is not a group member")
      let indices := psElabBinderArguments indicesRev
      if !psNameEq family.info.name info.name || family.indices.length != indices.length ||
          !(family.indices.zip indices).all (fun pair =>
            psDefEqReadOnlyWithEnv opened.context.environment opened.context.metaContext
              opened.context.localContext pair.fst pair.snd) then
        throw (.data "deriving motive does not bind its member indices")
      let body := result info major.type (.fvar major.id)
      return {
        context := psElabLeaveScope current opened.context
        term := psCloseElabLambdaBinders opened.context.metaContext opened.bindersRev body })
    recursor.context recursor.cursor
  -- Apply these closed motives in branch scopes. Reinvoking a callback after
  -- opening fields could capture one of its synthetic local IDs, notably the
  -- right-hand argument in the existing DecidableEq singleton consumer.
  let motivesByFamily := (recursor.group.members.zip motives.arguments).map fun pair =>
    (pair.fst.name, pair.snd)
  let minors ← psElabRecursorArguments constructors
    (fun current (owner, ctor) type => do
      if !allowDirectRecursion && !ctor.recursiveFields.isEmpty then
        throw (.data "recursive deriving requires the M3 data machinery")
      if !psConstructorRecursiveFieldsOrdered ctor then
        throw (.data "deriving recursive field metadata is invalid")
      let opened ← psElabOpenCoreTelescope 4096 current type
        (some (ctor.numFields + ctor.recursiveFields.length))
      let binders := opened.bindersRev.reverse
      let fields := binders.take ctor.numFields
      let hypotheses ← (ctor.recursiveFields.zip (binders.drop ctor.numFields)).mapM
        (fun (index, hypothesis) => do
          let some field := fields[index]?
            | throw (.data "deriving induction hypothesis has no field")
          let some child ← psElabDeriveFamilyView plan opened.context field.type
            | throw (.data "deriving recursive field is not a uniform direct group family")
          let expected ← psElabDeriveMotiveAt motivesByFamily child (.fvar field.id)
          if !psDefEqReadOnlyWithEnv opened.context.environment opened.context.metaContext
              opened.context.localContext hypothesis.type expected then
            throw (.data "deriving induction hypothesis type mismatch")
          return (field.id, PsExpr.fvar hypothesis.id))
      let value := psExprApplyMany (.constE ctor.name (plan.info.levelParams.map PsLevel.param))
        (parameters ++ fields.map (fun field => .fvar field.id))
      let valueType ← (psInferType opened.context.environment opened.context.metaContext
        opened.context.localContext value).mapError PsElabError.infer
      let some family ← psElabDeriveFamilyView plan opened.context valueType
        | throw (.data "deriving constructor result mismatch")
      if !psNameEq family.info.name owner.name then
        throw (.data "deriving constructor result mismatch")
      let expected ← psElabDeriveMotiveAt motivesByFamily family value
      if !psDefEqReadOnlyWithEnv opened.context.environment opened.context.metaContext
          opened.context.localContext opened.body expected then
        throw (.data "deriving recursor minor conclusion mismatch")
      let body ← (branch opened.context owner ctor fields hypotheses value).mapError
        (.atDeclaration ctor.name)
      return {
        context := psElabLeaveScope current opened.context
        term := psCloseElabLambdaBinders opened.context.metaContext opened.bindersRev body })
    motives.context motives.cursor
  let term := psLogicLam major.id "value" plan.family
    (psExprApplyMany (.constE recursor.recursor.name recursor.levels)
      (parameters ++ motives.arguments ++ minors.arguments ++
        psElabBinderArguments plan.indicesRev ++ [.fvar major.id]))
  let checked ← psElabResolvedTerm (psElabLeaveScope context minors.context) term
    (some (psLogicPi major.id "value" plan.family resultType))
  return checked.term

-- The legacy contract denotes one family. Keeping this wrapper strict avoids
-- silently promoting consumers such as DecidableEq to incomplete group motives.
def psElabDeriveEliminateWithRecursion (plan : PsElabDeriveContext)
    (context : PsElabContext) (allowDirectRecursion : Bool)
    (result : PsExpr → PsExpr)
    (branch : PsElabContext → PsConstructorInfo → List PsElabTypedBinder →
      List (Nat × PsExpr) → PsExpr → Except PsElabError PsExpr) :
    Except PsElabError PsExpr := do
  if plan.group.members.length != 1 then
    throw (.data "deriving handler requires a singleton family")
  if plan.info.numIndices != 0 then
    throw (.data "deriving indexed families is not yet implemented")
  psElabDeriveEliminateGroup plan context allowDirectRecursion (fun _ _ value => result value)
    (fun current _ constructor fields hypotheses value =>
      branch current constructor fields hypotheses value)

-- Handlers that do not yet consume recursive evidence still reject recursive
-- families. Their callback contract and previously qualified behavior remain.
def psElabDeriveEliminate (plan : PsElabDeriveContext) (context : PsElabContext)
    (result : PsExpr → PsExpr)
    (branch : PsElabContext → PsConstructorInfo → List PsElabTypedBinder →
      PsExpr → Except PsElabError PsExpr) : Except PsElabError PsExpr :=
  psElabDeriveEliminateWithRecursion plan context false result
    (fun context constructor fields _ value => branch context constructor fields value)

