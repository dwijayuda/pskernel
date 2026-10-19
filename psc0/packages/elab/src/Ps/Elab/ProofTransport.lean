import Ps.Elab.GoalSource
import Ps.Elab.Equality

/- Adapted from Lean 4.35.0 Meta/Tactic/Replace.lean at
 eb6cafb7290e8bd5f2937522d8d804f58f02bafc, Microsoft/Leonardo de Moura,
 Apache-2.0. Every replacement retains the original checked proof owner. -/

def psProofEquationCheck (context : PsElabContext) (equation : PsElabEquation) :
    Except PsElabError PsElabContext := do
  let checked ← psElabResolvedTerm context equation.proof
    (some (psLogicEq equation.level equation.type equation.left equation.right))
  return checked.context

def psProofReplaceTargetEq (state : PsProofState) (context : PsElabContext)
    (equation : PsElabEquation) : Except PsElabError PsProofState := do
  let (goal, _, target) ← psProofMain state
  let context ← psProofEquationCheck context equation
  let _ ← psElabExpressionSort context equation.right
  let fresh := psMetaFresh context.metaContext context.localContext
    (psMetaInstantiate context.metaContext equation.right) .syntheticOpaque
  let .mvar child := fresh.expr | throw (.proof "invalid replacement goal")
  let context := psElabContextWithMeta context fresh.context
  let symmetric ← psElabEquationSymm context equation
  let value ← psElabEquationRec context symmetric (fun type => type) fresh.expr
  let checked ← psElabResolvedTerm context value (some target)
  let state ← psProofAssign (psProofUpdate state checked.context) goal.id checked.term
  psProofNormalize { state with goals :=
    { id := child, tag := goal.tag } :: state.goals.drop 1 }

def psProofExpressionScopeIds (context : PsElabContext) (expression : PsExpr) : List Nat :=
  let expression := psMetaInstantiate context.metaContext expression
  psExprFVarIds expression ++ (psExprMetaIds expression).flatMap fun id =>
    match psMetaFindDecl context.metaContext id with
    | none => []
    | some declaration => declaration.localContext.declarations.map psLocalDeclId

def psProofLocalDeclScopeSafe (context : PsElabContext) (locals : PsLocalContext)
    (declaration : PsLocalDecl) : Bool :=
  psMetaExprScopeSafe context.metaContext locals (psLocalDeclType declaration) &&
    match declaration with
    | .letDecl _ _ _ value => psMetaExprScopeSafe context.metaContext locals value
    | _ => true

def psProofLocalDeclRename (declaration : PsLocalDecl) (name : PsName) : PsLocalDecl :=
  match declaration with
  | .binding id _ type binder => .binding id name type binder
  | .letDecl id _ type value => .letDecl id name type value

def psProofInsertBeforeLocal (id : Nat) (replacement : PsLocalDecl) :
    List PsLocalDecl → List PsLocalDecl
  | [] => [replacement]
  | declaration :: rest =>
    if psLocalDeclId declaration == id then replacement :: declaration :: rest
    else declaration :: psProofInsertBeforeLocal id replacement rest

def psProofInsertReplacement (context : PsElabContext) (oldId : Nat)
    (replacement : PsLocalDecl) : List PsLocalDecl :=
  let ids := oldId :: psProofExpressionScopeIds context (psLocalDeclType replacement)
  let latest := context.localContext.declarations.find? fun declaration =>
    ids.contains (psLocalDeclId declaration)
  psProofInsertBeforeLocal (latest.map psLocalDeclId |>.getD oldId)
    replacement context.localContext.declarations

def psProofReplaceLocalEq (state : PsProofState) (context : PsElabContext)
    (id : Nat) (equation : PsElabEquation) :
    Except PsElabError (PsProofState × Nat) := do
  let (goal, _, target) ← psProofMain state
  let some old := psLocalFindById context.localContext id
    | throw (.proof "unknown hypothesis for replacement")
  let context ← psProofEquationCheck context equation
  let value ← psElabEquationRec context equation (fun type => type) (.fvar id)
  let checked ← psElabResolvedTerm context value (some equation.right)
  let context := checked.context
  let type := psMetaInstantiate context.metaContext checked.type
  let name := psLocalDeclUserName old
  let newId := context.localContext.nextId
  let binder := match old with
    | .binding _ _ _ binder => binder
    | .letDecl .. => PsBinderInfo.explicit
  let replacement := PsLocalDecl.binding newId name type binder
  let entries := psProofInsertReplacement context id replacement
  let cleared := { context.localContext with
    declarations := entries.filter (fun declaration => psLocalDeclId declaration != id)
    nextId := newId + 1 }
  let dependent := !psMetaExprScopeSafe context.metaContext cleared target ||
    !cleared.declarations.all (psProofLocalDeclScopeSafe context cleared)
  let hidden := PsName.num (psRootName "$psProofReplaced") id
  let entries := entries.filterMap fun declaration =>
    if psLocalDeclId declaration != id then some declaration
    else if dependent then some (psProofLocalDeclRename declaration hidden)
    else none
  let locals := psLocalRedirectNameAliases {
    context.localContext with declarations := entries, nextId := newId + 1 } id newId
  let inner := psElabContextWithLocal context locals
  let fresh := psMetaFresh inner.metaContext inner.localContext target .syntheticOpaque
  let .mvar child := fresh.expr | throw (.proof "invalid local replacement goal")
  let some constraints := psMetaAssignDelayed fresh.context goal.id
      [.letE newId name type checked.term] fresh.expr
    | throw (.proof "invalid transported local scope")
  let inner := psElabContextWithMeta inner constraints
  let state ← psProofNormalize { (psProofUpdate state inner) with
    goals := { id := child, tag := goal.tag } :: state.goals.drop 1 }
  return (state, newId)
