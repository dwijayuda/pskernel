import Ps.Elab.ProofTransport
import Ps.Elab.ProofReduce
import Ps.Elab.ExprAbstraction

/- Adapted from Lean 4.35.0 Meta/Tactic/Rewrite.lean and
 Elab/Tactic/Rewrite.lean, eb6cafb7290e8bd5f2937522d8d804f58f02bafc,
 Microsoft Corporation / Leonardo de Moura, Apache-2.0. -/

def psProofRewriteOpen (fuel : Nat) (value : PsElabTermResult) :
    Except PsElabError PsElabTermResult := do
  match fuel with
  | 0 => throw .fuelExhausted
  | fuel + 1 =>
    let type ← psProofWhnfWithTransparency .reducible 256 value.context value.type
    match type with
    | .forallE name domain body binder =>
      let fresh := psMetaFresh value.context.metaContext value.context.localContext domain
        (if psBinderIsInstanceImplicit binder then .synthetic else .natural)
        { tag := psNameLastComponent name }
      let context := psElabContextWithMeta value.context fresh.context
      psProofRewriteOpen fuel {
        context, term := .app value.term fresh.expr
        type := psExprInstantiate1 body fresh.expr }
    | _ => return { value with type }

def psProofRewriteRelation (context : PsElabContext) (type proof : PsExpr) :
    Except PsElabError PsElabEquation := do
  let reduced ← psProofWhnfWithTransparency .reducible 256 context type
  let view := psExprAppView reduced
  match view.head, view.args with
  | .constE name [level], [type, left, right] =>
    if psNameEq name psEqName then return { level, type, left, right, proof }
    throw (.proof "rewrite requires an equality or equivalence")
  | .constE name [], [left, right] =>
    if !psNameEq name (psRootName "Iff") then
      throw (.proof "rewrite requires an equality or equivalence")
    let converted := psExprApplyMany (.constE (psRootName "propext") []) [left, right, proof]
    let equation : PsElabEquation := {
      level := .succ .zero, type := .sortE .zero, left, right, proof := converted }
    let _ ← psProofEquationCheck context equation
    return equation
  | _, _ => throw (.proof "rewrite requires an equality or equivalence")

def psProofRewriteCore (value : PsElabTermResult) (expression : PsExpr)
    (reverse : Bool) : Except PsElabError PsElabTermResult := do
  let opened ← psProofRewriteOpen 4096 value
  let original ← psProofRewriteRelation opened.context opened.type opened.term
  let rule ← if reverse then psElabEquationSymm opened.context original else pure original
  let context := opened.context
  let left := psMetaInstantiate context.metaContext rule.left
  if let .mvar _ := (psExprAppView left).head then
    throw (.proof "rewrite pattern is an unassigned metavariable")
  let expression := psMetaInstantiate context.metaContext expression
  let (context, abstracted) ← psElabKeyAbstract context left expression .reducible
  if !psElabExprHasLoose abstracted then
    throw (.proof "rewrite did not find an occurrence of the pattern")
  let type ← (psInferType context.environment context.metaContext
    context.localContext expression).mapError PsElabError.infer
  let motive := PsExpr.lam (psRootName "_rewrite") rule.type abstracted .explicit
  let motiveType := PsExpr.forallE (psRootName "_rewrite") rule.type type .explicit
  let checked ← psElabResolvedTerm context motive (some motiveType)
  let context := checked.context
  let right := psExprInstantiate1 abstracted (psMetaInstantiate context.metaContext rule.right)
  let congruence ← psElabEquationCongr context rule checked.term type
  let equation : PsElabEquation := {
    level := congruence.level, type, left := expression, right, proof := congruence.proof }
  let context ← psProofEquationCheck context equation
  return {
    context, term := equation.proof
    type := psLogicEq equation.level equation.type equation.left equation.right }

