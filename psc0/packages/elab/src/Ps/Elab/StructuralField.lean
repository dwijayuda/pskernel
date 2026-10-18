import Ps.Elab.Refinement
import Ps.Meta.Inductive

/-
The strict-child lookup follows Lean 4.35.0 Structural.BRecOn.toBelowAux and
Structural.IndPred.replaceIndPredRecApp: arguments of a positive recursive
field are applied to its actual hypothesis before selecting a function
component. This owned implementation uses ordinary recursor hypotheses.
-/
def psElabStructuralFieldArguments (context : PsElabContext)
    (fields : List Nat) (major : PsExpr) : Option (Nat × List PsExpr) :=
  let view := psExprAppView (psWhnf context.environment context.metaContext
    context.localContext major)
  match view.head with
  | .fvar id =>
    if fields.contains id then some (id, view.args)
    else fields.findSome? fun field =>
      if psDefEqReadOnlyWithEnv context.environment context.metaContext
          context.localContext major (.fvar field) then some (field, []) else none
  | _ => fields.findSome? fun field =>
      if psDefEqReadOnlyWithEnv context.environment context.metaContext
          context.localContext major (.fvar field) then some (field, []) else none

-- Native automatic recursion over an inductive predicate stays in Prop,
-- even when the explicit primitive recursor permits large elimination.
def psElabStructuralFieldSortAllowed (context : PsElabContext)
    (family : PsInductiveInfo) (resultType : PsExpr) : Except PsElabError Bool := do
  let familyLevel ← (psInductiveResultLevel context.environment family).mapError PsElabError.infer
  if !psLevelEquivalent familyLevel .zero then return true
  let resultLevel ← psElabExpressionSort context resultType
  return psLevelEquivalent resultLevel .zero
