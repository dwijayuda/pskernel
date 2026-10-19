import Ps.Elab.Goals
import Ps.Elab.Scope

def psProofSource (scope : PsSyntaxProofScope) (context : PsElabContext)
    (source : PsSyntaxTerm) : Except PsElabError PsSyntaxTerm := do
  let declared := context.localContext.declarations.filterMap fun entry =>
    match psLocalDeclUserName entry with
    | .num .. => none
    | name => some (psNameLastComponent name)
  let aliases := context.localContext.nameAliases.filterMap fun alias =>
    match alias.userName, psLocalFindUser context.localContext alias.userName with
    | .num .., _ => none
    | name, some declaration =>
      if psLocalDeclId declaration == alias.id then some (psNameLastComponent name) else none
    | _, none => none
  let bound := declared ++ aliases
  let resolved ← psScopeTerm 4096 {
    abstractProofs := scope.abstractProofs
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


