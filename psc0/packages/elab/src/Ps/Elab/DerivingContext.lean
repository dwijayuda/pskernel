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
  let type ← (psInferType fresh.environment fresh.metaContext fresh.localContext head).mapError
    PsElabError.infer
  let pi ← (psInferEnsureForall fresh.environment fresh.metaContext fresh.localContext type).mapError
    PsElabError.infer
  let actual ← (psInferType fresh.environment fresh.metaContext fresh.localContext argument).mapError
    PsElabError.infer
  let unified := psUnify fresh.environment fresh.localContext fresh.metaContext pi.domain actual
  if !unified.success then throw .typeMismatch
  let target := psMetaInstantiate unified.context (.app head argument)
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
