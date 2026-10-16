/-
Reference: Lean 4.35.0 Lean/Elab/Deriving/BEq.lean at eb6cafb.
Copyright (c) 2020 Microsoft Corporation. Author: Leonardo de Moura.
Apache-2.0; see THIRD_PARTY_NOTICES.md.
Adaptation: checked Core induction for direct uniform nonindexed recursion.
No partial fallback or assumed self dictionary. Nested/dependent families
retain the shared field-admissibility boundary.
-/
import Ps.Elab.DerivingContext

-- Distinguish erased proof fields, independent dictionaries and actual child
-- induction evidence. A missing dictionary can never masquerade as recursion.
inductive PsElabDeriveBEqField where
  | erased
  | independent (compare : PsExpr)
  | recursive

structure PsElabDeriveBEqConstructor where
  fields : PsElabDeriveFields
  comparisons : List PsElabDeriveBEqField

def psElabDeriveBEqPlanConstructor (plan : PsElabDeriveContext) (name : PsName) :
    Except PsElabError PsElabDeriveBEqConstructor := do
  let fields ← psElabDeriveFieldsWithRecursion plan name true
  let comparisons ← (fields.fields.zip fields.proofs).zipIdx.mapM fun ((field, proof), index) => do
    if proof then return PsElabDeriveBEqField.erased
    if fields.constructor.recursiveFields.contains index then
      return PsElabDeriveBEqField.recursive
    let target ← psElabDeriveClassType plan.context (psRootName "BEq") field.type
    let dictionary ← psElabDeriveInstance plan.context target
    let .app (.constE _ levels) _ := target | throw .typeMismatch
    return PsElabDeriveBEqField.independent
      (psExprApplyMany (.constE (psNameAppendStr (psRootName "BEq") "beq") levels)
        [field.type, dictionary])
  return { fields, comparisons }

def psElabDeriveBEqCompare (comparisons : List PsElabDeriveBEqField)
    (left right : List PsExpr) (hypotheses : List (Nat × PsExpr) := []) :
    Except PsElabError PsExpr := do
  if comparisons.length != left.length || comparisons.length != right.length then
    throw (.data "BEq deriving field alignment mismatch")
  let values ← ((comparisons.zip left).zip right).mapM fun ((compare, lhs), rhs) => do
    match compare with
    | .erased => return none
    | .independent compare => return some (psExprApplyMany compare [lhs, rhs])
    | .recursive =>
      let .fvar id := lhs | throw (.data "BEq deriving recursive field is not a local")
      let some (_, compare) := hypotheses.find? (fun entry => entry.fst == id)
        | throw (.data "BEq deriving recursive field has no checked induction hypothesis")
      -- The shared eliminator checked this hypothesis at family -> Bool.
      -- It already fixes the left child; only the matching right child remains.
      return some (PsExpr.app compare rhs)
  let bool := PsExpr.constE psBoolName []
  let motive := PsExpr.lam .anonymous bool bool .explicit
  return values.foldl (fun previous current =>
    match current with
    | none => previous
    | some current => psExprApplyMany (.constE (psNameAppendStr psBoolName "rec") [.succ .zero])
        [motive, .constE psBoolFalseName [], current, previous]) (.constE psBoolTrueName [])

-- Structures retain direct projections and the independently planned fields.
def psElabDeriveBEqStructure (plan : PsElabDeriveContext)
    (constructor : PsElabDeriveBEqConstructor) : Except PsElabError PsExpr := do
  let left := psLocalPushBinding plan.context.localContext (psRootName "left") plan.family .explicit
  let right := psLocalPushBinding left.context (psRootName "right") plan.family .explicit
  let fields := List.range constructor.fields.constructor.numFields
  let body ← psElabDeriveBEqCompare constructor.comparisons
    (fields.map fun i => .proj plan.info.name i (.fvar left.id))
    (fields.map fun i => .proj plan.info.name i (.fvar right.id))
  return psLogicLam left.id "left" plan.family (psLogicLam right.id "right" plan.family body)

-- Induct on the left; inspect only the right constructor. The inner recursor
-- deliberately ignores its induction hypotheses. All recursion evidence used
-- by comparisons comes from the checked left-child telescope.
def psElabDeriveBEqInductive (plan : PsElabDeriveContext)
    (constructors : List PsElabDeriveBEqConstructor) : Except PsElabError PsExpr :=
  let bool := PsExpr.constE psBoolName []
  psElabDeriveEliminateWithRecursion plan plan.context true
    (fun _ => .forallE (psRootName "right") plan.family bool .explicit)
    (fun leftContext leftCtor left hypotheses _ =>
      psElabDeriveEliminateWithRecursion plan leftContext true (fun _ => bool)
        (fun _ rightCtor right _ _ => do
          if !psNameEq leftCtor.name rightCtor.name then return .constE psBoolFalseName []
          let some entry := constructors.find? (fun c => psNameEq c.fields.constructor.name leftCtor.name)
            | throw (.data "BEq deriving constructor plan missing")
          psElabDeriveBEqCompare entry.comparisons
            (left.map (fun field => .fvar field.id))
            (right.map (fun field => .fvar field.id)) hypotheses))

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
