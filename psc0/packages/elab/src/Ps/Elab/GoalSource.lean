import Ps.Elab.Goals
import Ps.Elab.Scope

def psProofSource (scope : PsSyntaxProofScope) (context : PsElabContext)
    (source : PsSyntaxTerm) : Except PsElabError PsSyntaxTerm := do
  let bound := context.localContext.declarations.map fun entry =>
    psNameLastComponent (psLocalDeclUserName entry)
  let resolved ← psScopeTerm 4096 {
    environment := context.environment
    scope := { namePrefix := scope.namePrefix, opened := scope.opened }
    privateAliases := scope.privateAliases
    mutualAliases := scope.mutualAliases
    localAliases := scope.localAliases } bound source
  return resolved.term

def psProofMain (state : PsProofState) :
    Except PsElabError (PsProofGoal × PsElabContext × PsExpr) := do
  let some goal := state.goals.head? | throw (.proof "no goals")
  let context ← psProofContext state goal.id
  let some declaration := psMetaFindDecl context.metaContext goal.id
    | throw (.proof "unknown goal")
  return (goal, context, psMetaInstantiate context.metaContext declaration.type)


