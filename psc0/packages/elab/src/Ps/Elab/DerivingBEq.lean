import Ps.Elab.DerivingContext

-- A comparison is planned once per field, before building the left/right
-- eliminators. Only parameter-context dependencies are admitted in this slice;
-- dependent transport and recursive workers belong to the M3 data machinery.
structure PsElabDeriveBEqConstructor where
  cursor : PsExpr
  numFields : Nat
  comparisons : List PsExpr

def psElabDeriveBEqPlanConstructor (plan : PsElabDeriveContext) (name : PsName) :
    Except PsElabError PsElabDeriveBEqConstructor := do
  let context := plan.context
  let some constructor := psEnvironmentFindConstructor context.environment name
    | throw (.data "BEq deriving constructor missing")
  if !constructor.recursiveFields.isEmpty then
    throw (.data "recursive BEq deriving is not yet implemented")
  let (_, cursor) ← psElabDeriveConstructor plan constructor
  let fields ← psElabOpenCoreTelescope 4096 context cursor (some constructor.numFields)
  let comparisons ← fields.bindersRev.reverse.mapM fun field => do
    if !psExprFVarsInContext context.localContext field.type then
      throw (.data "BEq deriving requires independent field types")
    if psExprHasConst plan.info.name field.type then
      throw (.data "recursive BEq deriving is not yet implemented")
    let target ← psElabDeriveClassType context (psRootName "BEq") field.type
    let dictionary ← psElabDeriveInstance context target
    let .app (.constE _ levels) _ := target | throw .typeMismatch
    return psExprApplyMany (.constE (psNameAppendStr (psRootName "BEq") "beq") levels)
      [field.type, dictionary]
  if !psDefEqReadOnlyWithEnv context.environment context.metaContext fields.context.localContext
      fields.body plan.family then
    throw (.data "BEq deriving constructor result mismatch")
  return { cursor, numFields := constructor.numFields, comparisons }

def psElabDeriveBEqCompare (comparisons left right : List PsExpr) :
    Except PsElabError PsExpr := do
  if comparisons.length != left.length || comparisons.length != right.length then
    throw (.data "BEq deriving field alignment mismatch")
  let bool := PsExpr.constE psBoolName []
  let motive := PsExpr.lam .anonymous bool bool .explicit
  return ((comparisons.zip left).zip right).foldl (fun previous ((compare, lhs), rhs) =>
    let current := psExprApplyMany compare [lhs, rhs]
    psExprApplyMany (.constE (psNameAppendStr psBoolName "rec") [.succ .zero])
      [motive, .constE psBoolFalseName [], current, previous]) (.constE psBoolTrueName [])

-- Structures keep the direct projection path. This avoids two eliminators for
-- a single constructor, without duplicating telescope or dictionary synthesis.
def psElabDeriveBEqStructure (plan : PsElabDeriveContext)
    (constructor : PsElabDeriveBEqConstructor) : Except PsElabError PsExpr := do
  let left := psLocalPushBinding plan.context.localContext (psRootName "left") plan.family .explicit
  let right := psLocalPushBinding left.context (psRootName "right") plan.family .explicit
  let fields := List.range constructor.numFields
  let body ← psElabDeriveBEqCompare constructor.comparisons
    (fields.map fun i => .proj plan.info.name i (.fvar left.id))
    (fields.map fun i => .proj plan.info.name i (.fvar right.id))
  return psLogicLam left.id "left" plan.family (psLogicLam right.id "right" plan.family body)

-- Fieldless and payload constructors share one checked recursor construction.
-- Every local comes from an opened telescope, so generic parameters cannot
-- collide with a reserved numeric identity.
def psElabDeriveBEqInductive (plan : PsElabDeriveContext)
    (constructors : List PsElabDeriveBEqConstructor) : Except PsElabError PsExpr := do
  let context := plan.context
  let recursorName := psNameAppendStr plan.info.name "rec"
  let some (.recursorDecl recursorInfo) := psEnvironmentFind context.environment recursorName
    | throw (.data "BEq deriving recursor missing")
  let bool := PsExpr.constE psBoolName []
  let resultType := PsExpr.forallE (psRootName "right") plan.family bool .explicit
  let resultLevel ← psElabExpressionSort context resultType
  let outerLevels ← psElabRecursorLevels plan.info recursorInfo
    (plan.info.levelParams.map PsLevel.param) resultLevel
  let innerLevels ← psElabRecursorLevels plan.info recursorInfo
    (plan.info.levelParams.map PsLevel.param) (.succ .zero)
  let parameters := psElabBinderArguments plan.parametersRev
  let outerRecursor := psExprApplyMany (.constE recursorName outerLevels) parameters
  let innerRecursor := psExprApplyMany (.constE recursorName innerLevels) parameters
  let outerMotive := PsExpr.lam .anonymous plan.family resultType .explicit
  let innerMotive := PsExpr.lam .anonymous plan.family bool .explicit
  let outerBranches ← constructors.zipIdx |>.mapM fun (leftConstructor, leftIndex) => do
    let left ← psElabOpenCoreTelescope 4096 context
      leftConstructor.cursor (some leftConstructor.numFields)
    let rightBranches ← constructors.zipIdx |>.mapM fun (rightConstructor, rightIndex) => do
      let right ← psElabOpenCoreTelescope 4096 left.context
        rightConstructor.cursor (some rightConstructor.numFields)
      let body ← if leftIndex == rightIndex then
          psElabDeriveBEqCompare leftConstructor.comparisons
            (psElabBinderArguments left.bindersRev) (psElabBinderArguments right.bindersRev)
        else pure (.constE psBoolFalseName [])
      return psCloseElabLambdaBinders context.metaContext right.bindersRev body
    let major := psLocalPushBinding left.context.localContext (psRootName "right") plan.family .explicit
    let body := psExprApplyMany innerRecursor (innerMotive :: rightBranches ++ [.fvar major.id])
    return psCloseElabLambdaBinders context.metaContext left.bindersRev
      (psLogicLam major.id "right" plan.family body)
  let major := psLocalPushBinding context.localContext (psRootName "left") plan.family .explicit
  -- The outer recursor already returns the complete right-argument function.
  return psLogicLam major.id "left" plan.family
    (psExprApplyMany outerRecursor (outerMotive :: outerBranches ++ [.fvar major.id]))

def psElabDeriveBEq (environment : PsEnvironment)
    (origin : PsElabBatchOrigin) : Except PsElabError PsDeclaration := do
  let plan ← psElabDerivePrepare environment origin
  if plan.info.constructors.isEmpty then
    throw (.data "BEq deriving requires a nonempty family")
  let className := psRootName "BEq"
  let plan := psElabDeriveRequirements plan className
  let type ← psElabDeriveClassType plan.context className plan.family
  let .app (.constE _ levels) _ := type | throw .typeMismatch
  let constructors ← plan.info.constructors.mapM (psElabDeriveBEqPlanConstructor plan)
  let method ← if plan.info.isStructure then
      match constructors with
      | [constructor] => psElabDeriveBEqStructure plan constructor
      | _ => throw (.data "BEq deriving structure must have one constructor")
    else psElabDeriveBEqInductive plan constructors
  let value := psExprApplyMany (.constE (psNameAppendStr className "mk") levels) [plan.family, method]
  psElabDeriveFinish plan "instBEq" type value
