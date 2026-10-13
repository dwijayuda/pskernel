import Ps.Meta.Context

-- Template indices are private binders, never live metavariable identities.
-- Term parameters are dependency ordered; each stores its permitted local
-- scope. Reopening allocates fresh levels/terms in the receiving snapshot.
structure PsMetaTemplateParameter where
  type : PsExpr
  locals : List Nat

structure PsMetaTemplate where
  levels : Nat
  parameters : List PsMetaTemplateParameter
  value : PsExpr
  type : PsExpr

def psMetaMapLevel (replace : Nat → Option PsLevel) : PsLevel → Option PsLevel
  | .mvar id => replace id
  | .succ a => return .succ (← psMetaMapLevel replace a)
  | .max a b => return .max (← psMetaMapLevel replace a) (← psMetaMapLevel replace b)
  | .imax a b => return .imax (← psMetaMapLevel replace a) (← psMetaMapLevel replace b)
  | level => some level

def psMetaMapExpr (terms : Nat → Option PsExpr) (levels : Nat → Option PsLevel) :
    PsExpr → Option PsExpr
  | .mvar id => terms id
  | .sortE level => return .sortE (← psMetaMapLevel levels level)
  | .constE name us => return .constE name (← us.mapM (psMetaMapLevel levels))
  | .app fn arg => return .app (← psMetaMapExpr terms levels fn) (← psMetaMapExpr terms levels arg)
  | .lam name type body binder =>
    return .lam name (← psMetaMapExpr terms levels type) (← psMetaMapExpr terms levels body) binder
  | .forallE name type body binder =>
    return .forallE name (← psMetaMapExpr terms levels type) (← psMetaMapExpr terms levels body) binder
  | .letE name type value body =>
    return .letE name (← psMetaMapExpr terms levels type)
      (← psMetaMapExpr terms levels value) (← psMetaMapExpr terms levels body)
  | .proj name index value => return .proj name index (← psMetaMapExpr terms levels value)
  | value => some value

def psMetaLevelIds : PsLevel → List Nat
  | .mvar id => [id]
  | .succ a => psMetaLevelIds a
  | .max a b | .imax a b => psMetaLevelIds a ++ psMetaLevelIds b
  | _ => []

def psMetaExprLevelIds : PsExpr → List Nat
  | .sortE level => psMetaLevelIds level
  | .constE _ levels => levels.flatMap psMetaLevelIds
  | .app a b | .lam _ a b _ | .forallE _ a b _ => psMetaExprLevelIds a ++ psMetaExprLevelIds b
  | .letE _ a b c => psMetaExprLevelIds a ++ psMetaExprLevelIds b ++ psMetaExprLevelIds c
  | .proj _ _ value => psMetaExprLevelIds value
  | _ => []

-- Never turn an unsolved instance or proof obligation into a parameter.
-- Captured scopes must fit the generator scope, including dependent types.
def psMetaTemplateOrder (fuel : Nat) (context : PsMetaContext) (locals : PsLocalContext)
    (pending visiting ordered : List Nat) : Option (List Nat) := do
  match pending with
  | [] => some ordered
  | id :: rest =>
    match fuel with
    | 0 => none
    | fuel + 1 =>
      if ordered.contains id then psMetaTemplateOrder fuel context locals rest visiting ordered else
      if visiting.contains id then none else
      let declaration ← psMetaFindDecl context id
      match declaration.kind with
      | .natural => pure ()
      | _ => none
      if (psMetaFindDelayed context id).isSome then none else
      if !declaration.localContext.declarations.all
          (fun localDecl => psLocalContainsId locals (psLocalDeclId localDecl)) then none else
      let type := psMetaInstantiate context declaration.type
      if !psExprFVarsInContext declaration.localContext type then none else
      let ordered ← psMetaTemplateOrder fuel context locals (psExprMetaIds type) (id :: visiting) ordered
      psMetaTemplateOrder fuel context locals rest visiting (ordered ++ [id])

def psMetaTemplateIndex (id : Nat) : List Nat → Option Nat
  | [] => none
  | head :: rest => if head == id then some 0 else (psMetaTemplateIndex id rest).map (· + 1)

def psMetaAbstract (context : PsMetaContext) (locals : PsLocalContext)
    (value type : PsExpr) : Option PsMetaTemplate := do
  let value := psMetaInstantiate context value
  let type := psMetaInstantiate context type
  if !psExprFVarsInContext locals value || !psExprFVarsInContext locals type then none else
  let ordered ← psMetaTemplateOrder 4096 context locals
    (psExprMetaIds value ++ psExprMetaIds type) [] []
  let declarations ← ordered.mapM (psMetaFindDecl context)
  let types := declarations.map (fun declaration => psMetaInstantiate context declaration.type)
  let levels := ((value :: type :: types).flatMap psMetaExprLevelIds).eraseDups
  if !levels.all context.levels.declarations.contains then none else
  let terms := fun id => (psMetaTemplateIndex id ordered).map PsExpr.mvar
  let levelMap := fun id => (psMetaTemplateIndex id levels).map PsLevel.mvar
  let parameters ← (declarations.zip types).mapM fun (declaration, type) => do
    let parameter : PsMetaTemplateParameter := {
      type := (← psMetaMapExpr terms levelMap type)
      locals := declaration.localContext.declarations.map psLocalDeclId }
    return parameter
  return {
    levels := levels.length
    parameters
    value := (← psMetaMapExpr terms levelMap value)
    type := (← psMetaMapExpr terms levelMap type) }

def psMetaOpenTemplate (context : PsMetaContext) (locals : PsLocalContext)
    (template : PsMetaTemplate) : Option (PsMetaContext × PsExpr × PsExpr) := do
  let (context, levels) := (List.range template.levels).foldl
    (fun (state : PsMetaContext × List PsLevel) _ =>
      let fresh := psMetaFreshLevel state.1
      (fresh.context, state.2 ++ [fresh.level])) (context, [])
  let (context, terms) ← template.parameters.foldlM
    (fun (state : PsMetaContext × List PsExpr) parameter => do
      if !parameter.locals.all (psLocalContainsId locals) then none else
      let scope : PsLocalContext := {
        locals with
        declarations := locals.declarations.filter (fun declaration =>
          parameter.locals.contains (psLocalDeclId declaration)) }
      let type ← psMetaMapExpr (state.2[·]?) (levels[·]?) parameter.type
      if !psExprFVarsInContext scope type then none else
      let fresh := psMetaFresh state.1 scope type .natural
      return (fresh.context, state.2 ++ [fresh.expr])) (context, [])
  let value ← psMetaMapExpr (terms[·]?) (levels[·]?) template.value
  let type ← psMetaMapExpr (terms[·]?) (levels[·]?) template.type
  return (context, value, type)

-- Canonical parameter indices allow duplicate-answer comparison without donor
-- IDs or assignments. Dictionary coherence selects the first answer of a type.
def psMetaTemplateSameType (left right : PsMetaTemplate) : Bool :=
  left.levels == right.levels && left.parameters.length == right.parameters.length &&
    (left.parameters.zip right.parameters).all (fun (a, b) =>
      a.locals == b.locals && psExprAlphaEq a.type b.type) &&
    psExprAlphaEq left.type right.type
