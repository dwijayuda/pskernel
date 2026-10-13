import Ps.Elab.Class

-- A handler works in one ordinary local telescope. Uniform parameters retain
-- their identities; generated requirements are tracked separately so handlers
-- can choose their dependency policy without inventing another elaborator.
structure PsElabDeriveContext where
  info : PsInductiveInfo
  context : PsElabContext
  parametersRev : List PsElabTypedBinder
  requirementsRev : List PsElabTypedBinder := []
  family : PsExpr

def psElabDerivePrepare (environment : PsEnvironment)
    (origin : PsElabBatchOrigin) : Except PsElabError PsElabDeriveContext := do
  let some member := origin.members.find? (fun member =>
    match member.role with
    | .inductiveType | .structureType => true
    | _ => false)
    | throw (.data "deriving requires an inductive/structure declaration")
  let some info := psEnvironmentFindInductive environment member.name
    | throw (.data "derived family is not an inductive")
  if info.numIndices != 0 then
    throw (.data "deriving indexed families is not yet implemented")
  let parameters ← psElabOpenCoreTelescope 4096
    (psElabContextEmpty environment info.levelParams) info.type (some info.numParams)
  let family := psExprApplyMany (.constE info.name (info.levelParams.map PsLevel.param))
    (psElabBinderArguments parameters.bindersRev)
  return {
    info
    context := parameters.context
    parametersRev := parameters.bindersRev.map fun binder => { binder with binder := .implicit }
    family }

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
  let levels := plan.info.levelParams.map PsLevel.param
  if constructor.numParams != plan.info.numParams ||
      constructor.levelParams.length != levels.length then
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
    (requirements ++ plan.parametersRev) value type
  if psExprHasUnresolvedMeta value || psExprHasUnresolvedMeta type then
    throw .unresolvedMetavariable
  if !psExprFVarsInContext psLocalEmpty value || !psExprFVarsInContext psLocalEmpty type then
    throw (.data "derived declaration contains an unbound local")
  return .definitionDecl (psNameAppendStr plan.info.name suffix) plan.info.levelParams type value

-- Runtime fields must have homogeneous types in the parameter telescope.
-- Proof fields may depend on earlier values: they carry no comparison payload,
-- and DecidableEq transports them with the existing dependent-context machinery.
structure PsElabDeriveFields where
  constructor : PsConstructorInfo
  cursor : PsExpr
  fields : List PsElabTypedBinder
  proofs : List Bool

def psElabDeriveFields (plan : PsElabDeriveContext) (name : PsName) :
    Except PsElabError PsElabDeriveFields := do
  let some constructor := psEnvironmentFindConstructor plan.context.environment name
    | throw (.data "deriving constructor missing")
  if !constructor.recursiveFields.isEmpty then
    throw (.data "recursive deriving requires the M3 data machinery")
  let (_, cursor) ← psElabDeriveConstructor plan constructor
  let opened ← psElabOpenCoreTelescope 4096 plan.context cursor (some constructor.numFields)
  let fields := opened.bindersRev.reverse
  let proofs ← fields.mapM fun field => do
    let level ← psElabExpressionSort opened.context field.type
    if psLevelEquivalent level .zero then return true
    if !psExprFVarsInContext plan.context.localContext field.type then
      throw (.data "deriving requires independent runtime field types")
    if psExprHasConst plan.info.name field.type then
      throw (.data "recursive deriving requires the M3 data machinery")
    return false
  if !psDefEqReadOnlyWithEnv plan.context.environment plan.context.metaContext
      opened.context.localContext opened.body plan.family then
    throw (.data "deriving constructor result mismatch")
  return { constructor, cursor, fields, proofs }

-- One eliminator builder owns motive universes and the actual minor telescope.
-- The callback receives fresh local fields and the reconstructed constructor.
-- Empty families work without a special inhabitant or fabricated branch.
def psElabDeriveEliminate (plan : PsElabDeriveContext) (context : PsElabContext)
    (result : PsExpr → PsExpr)
    (branch : PsElabContext → PsConstructorInfo → List PsElabTypedBinder →
      PsExpr → Except PsElabError PsExpr) : Except PsElabError PsExpr := do
  let recName := psNameAppendStr plan.info.name "rec"
  let some recursor := psEnvironmentFindRecursor context.environment recName
    | throw (.data "deriving recursor missing")
  let major := psLocalPushBinding context.localContext (psRootName "value") plan.family .explicit
  let inner := psElabContextWithLocal context major.context
  let level ← psElabExpressionSort inner (result (.fvar major.id))
  let levels ← psElabRecursorLevels plan.info recursor
    (plan.info.levelParams.map PsLevel.param) level
  let parameters := psElabBinderArguments plan.parametersRev
  let motive := psLogicLam major.id "value" plan.family (result (.fvar major.id))
  let recType := psExprInstantiateLevelParams recursor.levelParams levels recursor.type
  let some cursor := psReduceApplyType
    (psWhnf context.environment context.metaContext context.localContext)
    recType (parameters ++ [motive]) | throw .matchRecursorUnsupported
  let (_, branches) ← plan.info.constructors.foldlM
    (fun (state : PsExpr × List PsExpr) name => do
      let some ctor := psEnvironmentFindConstructor context.environment name
        | throw (.data "deriving constructor missing")
      if !ctor.recursiveFields.isEmpty then
        throw (.data "recursive deriving requires the M3 data machinery")
      let minor ← (psInferEnsureForall context.environment context.metaContext
        context.localContext state.fst).mapError PsElabError.infer
      let opened ← psElabOpenCoreTelescope 4096 context minor.domain (some ctor.numFields)
      let fields := opened.bindersRev.reverse
      let value := psExprApplyMany (.constE name (plan.info.levelParams.map PsLevel.param))
        (parameters ++ fields.map (fun field => .fvar field.id))
      let body ← (branch opened.context ctor fields value).mapError (.atDeclaration name)
      let body := psCloseElabLambdaBinders context.metaContext opened.bindersRev body
      pure (psExprInstantiate1 minor.body body, body :: state.snd)) (cursor, [])
  return psLogicLam major.id "value" plan.family
    (psExprApplyMany (.constE recName levels)
      (parameters ++ [motive] ++ branches.reverse ++ [.fvar major.id]))
