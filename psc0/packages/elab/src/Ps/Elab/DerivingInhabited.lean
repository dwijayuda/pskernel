import Ps.Elab.DerivingContext
import Ps.Environment.StandardInhabited

-- Constructor fields are filled in telescope order. Instantiating each default
-- into the remaining telescope preserves dependent field annotations.
def psElabDeriveInhabitedConstructor (plan : PsElabDeriveContext)
    (constructor : PsConstructorInfo) : Except PsElabError PsExpr := do
  let (initial, type) ← psElabDeriveConstructor plan constructor
  let context := plan.context
  let mut cursor := type
  let mut value := initial
  for _ in [:constructor.numFields] do
    let field ← (psInferEnsureForall context.environment context.metaContext
      context.localContext cursor).mapError PsElabError.infer
    let level ← psElabExpressionSort context field.domain
    let dictionary ← psElabDeriveInstance context (psStandardInhabitedType field.domain level)
    let defaultValue := psStandardInhabitedDefault level field.domain dictionary
    cursor := psExprInstantiate1 field.body defaultValue
    value := .app value defaultValue
  if !psDefEqReadOnlyWithEnv context.environment context.metaContext
      context.localContext cursor plan.family then
    throw (.data "derived constructor does not produce the expected family")
  return value

def psElabDeriveInhabitedValue (plan : PsElabDeriveContext) : Except PsElabError PsExpr := do
  for name in plan.info.constructors do
    let some constructor := psEnvironmentFindConstructor plan.context.environment name
      | throw (.data "deriving constructor is missing")
    match psElabDeriveInhabitedConstructor plan constructor with
    | .ok value => return value
    | .error _ => pure ()
  throw (.data "Inhabited deriving requires a constructor with inhabitable fields")

def psElabDeriveInhabited (environment : PsEnvironment)
    (origin : PsElabBatchOrigin) : Except PsElabError PsDeclaration := do
  let plan ← psElabDerivePrepare environment origin
  -- RC4 chooses across all constructors before adding assumptions: a later
  -- empty constructor must beat an earlier constructor requiring Inhabited α.
  let (plan, defaultValue) ← match psElabDeriveInhabitedValue plan with
    | .ok value => pure (plan, value)
    | .error _ => do
      let plan := psElabDeriveRequirements plan (psRootName "Inhabited")
      return (plan, ← psElabDeriveInhabitedValue plan)
  let level ← psElabExpressionSort plan.context plan.family
  psElabDeriveFinish plan "instInhabited"
    (psStandardInhabitedType plan.family level)
    (psStandardInhabitedValue plan.family defaultValue level) true
