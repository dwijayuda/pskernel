/-
Index promotion follows Lean 4.35.0 Lean/Elab/MutualInductive.lean,
IndexPromotion, at eb6cafb7290e8bd5f2937522d8d804f58f02bafc.
Copyright (c) Microsoft Corporation. Apache-2.0.
Only the fixed common prefix changes parameter/field counts. Actual constructor
types, argument order, binder metadata, and recursive occurrences are retained.
-/
import Ps.Elab.Term
import Ps.Core.InductiveGroup

-- Native forEachWhere stops at a complete group application. Its function
-- prefixes must not be mistaken for partially applied recursive occurrences.
def psElabDataFixedOccurrence (group : PsInductiveGroupPlan)
    (position : Nat) (argument expression : PsExpr) : Bool :=
  let view := psExprAppView expression
  let inGroup := match view.head with
    | .constE name _ => (psInductiveGroupFind group name).isSome
    | _ => false
  if inGroup then
    match view.args[position]? with
    | some actual => psExprAlphaEq actual argument
    | none => false
  else
    match expression with
    | .app fn arg | .lam _ fn arg _ | .forallE _ fn arg _ =>
      psElabDataFixedOccurrence group position argument fn &&
        psElabDataFixedOccurrence group position argument arg
    | .letE _ type value body =>
      psElabDataFixedOccurrence group position argument type &&
        psElabDataFixedOccurrence group position argument value &&
        psElabDataFixedOccurrence group position argument body
    | .proj _ _ value => psElabDataFixedOccurrence group position argument value
    | _ => true

def psElabDataFixedConstructor (context : PsElabContext)
    (group : PsInductiveGroupPlan) (constructor : PsConstructorInfo)
    (position : Nat) : Except PsElabError Bool := do
  let opened ← psElabOpenCoreTelescope 4096 context constructor.type none
  let binders := opened.bindersRev.reverse
  let some binder := binders[position]? | return false
  let result := psExprAppView (psWhnf opened.context.environment opened.context.metaContext
    opened.context.localContext opened.body)
  let some argument := result.args[position]? | return false
  if !psExprAlphaEq argument (.fvar binder.id) then return false
  return (binders.drop constructor.numParams).all fun field =>
    psElabDataFixedOccurrence group position argument
      (psMetaInstantiate opened.context.metaContext field.type)

def psElabDataPromotionPrefix (fuel : Nat) (context : PsElabContext)
    (group : PsInductiveGroupPlan) (constructors : List PsConstructorInfo)
    (position : Nat) (cursor : PsExpr) (others : List PsExpr) :
    Except PsElabError (PsElabContext × Nat) := do
  match fuel with
  | 0 => throw .fuelExhausted
  | fuel + 1 =>
    if !(group.members.all (fun info => position < info.numParams + info.numIndices)) then
      return (context, position)
    for constructor in constructors do
      if !(← psElabDataFixedConstructor context group constructor position) then
        return (context, position)
    let first := psWhnf context.environment context.metaContext context.localContext cursor
    let .forallE _ domain body _ := first | return (context, position)
    let mut context := context
    let mut bodies : List PsExpr := []
    for other in others do
      let other := psWhnf context.environment context.metaContext context.localContext other
      let .forallE _ otherDomain otherBody _ := other | return (context, position)
      let unified := psUnify context.environment context.localContext context.metaContext
        otherDomain domain
      if unified.resourceExceeded then throw .fuelExhausted
      if !unified.success then return (context, position)
      context := psElabContextWithMeta context unified.context
      bodies := bodies ++ [otherBody]
    let domain := psMetaInstantiate context.metaContext domain
    let pushed := psLocalPushBinding context.localContext
      (psNameAppendNum (psRootName "$psc0PromotedIndex") context.localContext.nextId)
      domain .explicit
    let argument := PsExpr.fvar pushed.id
    psElabDataPromotionPrefix fuel (psElabContextWithLocal context pushed.context)
      group constructors (position + 1) (psExprInstantiate1 body argument)
      (bodies.map (psExprInstantiate1 · argument))

def psElabDataPromoteIndices (context : PsElabContext)
    (group : PsInductiveGroupPlan) (declarations : List PsDeclaration) :
    Except PsElabError (PsElabContext × PsInductiveGroupPlan × List PsDeclaration) := do
  let first :: rest := group.members | throw (.data "empty inductive group")
  if group.members.any (·.isStructure) || first.numIndices == 0 then
    return (context, group, declarations)
  let constructors ← declarations.mapM fun declaration => do
    let .constructorDecl info := declaration | throw (.data "constructor plan contains another declaration")
    return info
  let parameters ← psElabOpenCoreTelescope 4096 context first.type (some first.numParams)
  let arguments := psElabBinderArguments parameters.bindersRev
  let others ← ((rest.map (·.type)) ++ constructors.map (·.type)).mapM
    (psElabMatchApplyParameters parameters.context arguments)
  let (promoted, count) ← psElabDataPromotionPrefix 4096 parameters.context
    group constructors first.numParams parameters.body others
  let context := psElabLeaveScope context promoted
  let extra := count - first.numParams
  if extra == 0 then return (context, group, declarations)
  let members := group.members.map fun info => {
    info with
    numParams := info.numParams + extra
    numIndices := info.numIndices - extra
    type := psMetaInstantiate context.metaContext info.type }
  let constructors ← constructors.mapM fun info => do
    if extra > info.numFields || info.recursiveFields.any (· < extra) then
      throw (.data "promoted index overlaps a recursive constructor field")
    return PsDeclaration.constructorDecl {
      info with
      numParams := info.numParams + extra
      numFields := info.numFields - extra
      recursiveFields := info.recursiveFields.map (· - extra)
      type := psMetaInstantiate context.metaContext info.type }
  return (context, { members }, constructors)
