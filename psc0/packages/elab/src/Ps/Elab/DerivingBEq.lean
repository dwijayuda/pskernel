import Ps.Elab.DerivingContext

-- Plan dictionaries once in the family parameter context. Proof fields retain
-- their positions but never require BEq evidence or generate runtime compares.
structure PsElabDeriveBEqConstructor where
  fields : PsElabDeriveFields
  comparisons : List (Option PsExpr)

def psElabDeriveBEqPlanConstructor (plan : PsElabDeriveContext) (name : PsName) :
    Except PsElabError PsElabDeriveBEqConstructor := do
  let fields ← psElabDeriveFields plan name
  let comparisons ← (fields.fields.zip fields.proofs).mapM fun (field, proof) => do
    if proof then return none
    let target ← psElabDeriveClassType plan.context (psRootName "BEq") field.type
    let dictionary ← psElabDeriveInstance plan.context target
    let .app (.constE _ levels) _ := target | throw .typeMismatch
    return some (psExprApplyMany (.constE (psNameAppendStr (psRootName "BEq") "beq") levels)
      [field.type, dictionary])
  return { fields, comparisons }

def psElabDeriveBEqCompare (comparisons : List (Option PsExpr)) (left right : List PsExpr) :
    Except PsElabError PsExpr := do
  if comparisons.length != left.length || comparisons.length != right.length then
    throw (.data "BEq deriving field alignment mismatch")
  let bool := PsExpr.constE psBoolName []
  let motive := PsExpr.lam .anonymous bool bool .explicit
  return ((comparisons.zip left).zip right).foldl (fun previous ((compare, lhs), rhs) =>
    match compare with
    | none => previous
    | some compare =>
      let current := psExprApplyMany compare [lhs, rhs]
      psExprApplyMany (.constE (psNameAppendStr psBoolName "rec") [.succ .zero])
        [motive, .constE psBoolFalseName [], current, previous]) (.constE psBoolTrueName [])

-- Structures use direct projections; other families share the same checked
-- eliminator builder as proof-producing equality.
def psElabDeriveBEqStructure (plan : PsElabDeriveContext)
    (constructor : PsElabDeriveBEqConstructor) : Except PsElabError PsExpr := do
  let left := psLocalPushBinding plan.context.localContext (psRootName "left") plan.family .explicit
  let right := psLocalPushBinding left.context (psRootName "right") plan.family .explicit
  let fields := List.range constructor.fields.constructor.numFields
  let body ← psElabDeriveBEqCompare constructor.comparisons
    (fields.map fun i => .proj plan.info.name i (.fvar left.id))
    (fields.map fun i => .proj plan.info.name i (.fvar right.id))
  return psLogicLam left.id "left" plan.family (psLogicLam right.id "right" plan.family body)

def psElabDeriveBEqInductive (plan : PsElabDeriveContext)
    (constructors : List PsElabDeriveBEqConstructor) : Except PsElabError PsExpr :=
  let bool := PsExpr.constE psBoolName []
  psElabDeriveEliminate plan plan.context
    (fun _ => .forallE (psRootName "right") plan.family bool .explicit)
    (fun leftContext leftCtor left _ =>
      psElabDeriveEliminate plan leftContext (fun _ => bool)
        (fun _ rightCtor right _ => do
          if !psNameEq leftCtor.name rightCtor.name then return .constE psBoolFalseName []
          let some entry := constructors.find? (fun c => psNameEq c.fields.constructor.name leftCtor.name)
            | throw (.data "BEq deriving constructor plan missing")
          psElabDeriveBEqCompare entry.comparisons
            (left.map (fun field => .fvar field.id)) (right.map (fun field => .fvar field.id))))

def psElabDeriveBEq (environment : PsEnvironment)
    (origin : PsElabBatchOrigin) : Except PsElabError PsDeclaration := do
  let plan ← psElabDerivePrepare environment origin
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
