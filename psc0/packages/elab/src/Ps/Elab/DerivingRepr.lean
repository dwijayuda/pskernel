/-
Repr deriving adapted from Lean 4.35.0 Lean/Elab/Deriving/Repr.lean.
Copyright (c) 2020 Microsoft Corporation. All rights reserved.
Author: Leonardo de Moura. Apache-2.0; see THIRD_PARTY_NOTICES.md.
Modified: checked Core construction for independent and uniform direct-recursive families.
-/
import Ps.Elab.DerivingContext
import Ps.Environment.StandardRepr

structure PsElabDeriveReprConstructor where
  fields : PsElabDeriveFields
  printers : List (Option PsExpr)

-- Plan independent dictionaries once in the parameter telescope. A direct
-- recursive field obtains its printer from the checked recursor minor, never
-- from an assumed self instance. Types/proofs and hidden inductive fields
-- retain the existing underscore/omission behavior.
def psElabDeriveReprPlan (plan : PsElabDeriveContext) (name : PsName) :
    Except PsElabError PsElabDeriveReprConstructor := do
  let fields ← psElabDeriveFieldsWithRecursion plan name (!plan.info.isStructure)
  let printers ← (fields.fields.zip fields.proofs).zipIdx.mapM fun ((field, proof), index) => do
    if proof || (!plan.info.isStructure && !psBinderInfoEq field.binder .explicit) then return none
    if fields.constructor.recursiveFields.contains index then return none
    match psWhnf plan.context.environment plan.context.metaContext
        plan.context.localContext field.type with
    | .sortE _ => return none
    | _ => pure ()
    let target ← psElabDeriveClassType plan.context (psRootName "Repr") field.type
    let dictionary ← psElabDeriveInstance plan.context target
    let .app (.constE _ levels) _ := target | throw .typeMismatch
    return some (psExprApplyMany (.constE (psDecisionName "Repr.reprPrec") levels)
      [field.type, dictionary])
  return { fields, printers }

def psElabDeriveReprField (printer : Option PsExpr) (value : PsExpr)
    (precedence : Nat) : PsExpr :=
  match printer with
  | none => psReprText "_"
  | some printer => psExprApplyMany printer [value, psFormatNat precedence]

def psElabDeriveReprStructure (plan : PsElabDeriveContext)
    (constructor : PsElabDeriveReprConstructor) : Except PsElabError PsExpr := do
  let id := plan.context.localContext.nextId
  let append := fun a b => psFormatCall "append" [a, b]
  let fields := (constructor.fields.fields.zip constructor.printers).zipIdx
  let body := fields.foldl (fun acc ((field, printer), index) =>
    let label := psNameLastComponent field.name
    let value := psElabDeriveReprField printer (.proj plan.info.name index (.fvar id)) 0
    let value := match printer with
      | none => value
      | some _ => psFormatCall "group"
          [psFormatCall "nest" [psFormatInt (psFormatNat (label.length + 4)), value],
           psFormatBehavior]
    let acc := if index == 0 then acc else append (append acc (psReprText ",")) (psFormatCall "line")
    append (append (append acc (psReprText label)) (psReprText " := ")) value) (psFormatCall "nil")
  return psLogicLam id "value" plan.family (psLogicLam (id + 1) "prec" psOrderNat
    (psFormatCall "bracket" [.lit (.string "{ "), body, .lit (.string " }")]))

def psElabDeriveReprInductive (plan : PsElabDeriveContext)
    (constructors : List PsElabDeriveReprConstructor) : Except PsElabError PsExpr :=
  psElabDeriveEliminateWithRecursion plan plan.context true
    (fun _ => psLogicPi plan.context.localContext.nextId "prec" psOrderNat psFormatType)
    (fun context constructor fields hypotheses _ => do
      let some entry := constructors.find? (fun c => psNameEq c.fields.constructor.name constructor.name)
        | throw (.data "Repr deriving constructor plan missing")
      if entry.printers.length != fields.length then
        throw (.data "Repr deriving field alignment mismatch")
      let id := context.localContext.nextId
      let append := fun a b => psFormatCall "append" [a, b]
      let body ← (fields.zip entry.printers).zipIdx.foldlM (fun acc ((field, printer), index) => do
        if !psBinderInfoEq field.binder .explicit then return acc
        let rendered ← if constructor.recursiveFields.contains index then
            match hypotheses.find? (fun entry => entry.fst == field.id) with
            | some (_, childPrinter) => pure (PsExpr.app childPrinter (psFormatNat 1024))
            | none => throw (.data "Repr deriving recursive field has no checked induction printer")
          else pure (psElabDeriveReprField printer (.fvar field.id) 1024)
        return append (append acc (psFormatCall "line")) rendered)
        (psReprText (psNameToString constructor.name))
      let indent := psFormatIf psOrderNat
        (psOrderCall "Nat.ble" [psFormatNat 1024, .fvar id]) (psFormatNat 1) (psFormatNat 2)
      let document := psFormatCall "group"
        [psFormatCall "nest" [psFormatInt indent, body], psFormatBehavior]
      return psLogicLam id "prec" psOrderNat (psReprAddAppParen document (.fvar id)))

def psElabDeriveRepr (environment : PsEnvironment)
    (origin : PsElabBatchOrigin) : Except PsElabError PsDeclaration := do
  let plan ← psElabDerivePrepare environment origin
  let plan := psElabDeriveRequirements plan (psRootName "Repr")
  let type ← psElabDeriveClassType plan.context (psRootName "Repr") plan.family
  let .app (.constE _ levels) _ := type | throw .typeMismatch
  let constructors ← plan.info.constructors.mapM (psElabDeriveReprPlan plan)
  let method ← if plan.info.isStructure then
      match constructors with
      | [constructor] => psElabDeriveReprStructure plan constructor
      | _ => throw (.data "Repr deriving structure must have one constructor")
    else psElabDeriveReprInductive plan constructors
  let value := psExprApplyMany (.constE (psDecisionName "Repr.mk") levels) [plan.family, method]
  psElabDeriveFinish plan "instRepr" type value
