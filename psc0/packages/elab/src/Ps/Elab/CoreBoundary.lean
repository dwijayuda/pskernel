import Ps.Elab.Abstraction

-- A retained caller local can be specialized to an expression, but it cannot
-- capture a binder inside the template being matched.
def psElabCoreBoundaryClosed (expression : PsExpr) (depth : Nat := 0) : Bool :=
  match expression with
  | .bvar index => index < depth
  | .app fn arg =>
    psElabCoreBoundaryClosed fn depth && psElabCoreBoundaryClosed arg depth
  | .lam _ domain body _ | .forallE _ domain body _ =>
    psElabCoreBoundaryClosed domain depth && psElabCoreBoundaryClosed body (depth + 1)
  | .letE _ type value body =>
    psElabCoreBoundaryClosed type depth && psElabCoreBoundaryClosed value depth &&
      psElabCoreBoundaryClosed body (depth + 1)
  | .proj _ _ value => psElabCoreBoundaryClosed value depth
  | _ => true

-- One substitution is shared by the type and value. Every other logical
-- constructor, bound index, binder kind, constant and universe is retained.
-- This is a structural ownership check; it performs no reduction or assignment.
def psElabCoreBoundaryTemplate (localIds : List Nat) (template actual : PsExpr)
    (replacements : List (Nat × PsExpr)) : Option (List (Nat × PsExpr)) := do
  match template with
  | .fvar id =>
    if !localIds.contains id then
      if psExprAlphaEq template actual then some replacements else none
    else if !psElabCoreBoundaryClosed actual then none
    else
      match replacements.find? (fun entry => entry.fst == id) with
      | some (_, previous) =>
        if psExprAlphaEq previous actual then some replacements else none
      | none => some ((id, actual) :: replacements)
  | .app fn arg =>
    let .app actualFn actualArg := actual | none
    let replacements ← psElabCoreBoundaryTemplate localIds fn actualFn replacements
    psElabCoreBoundaryTemplate localIds arg actualArg replacements
  | .lam _ domain body binder =>
    let .lam _ actualDomain actualBody actualBinder := actual | none
    if !psBinderInfoEq binder actualBinder then none
    else
      let replacements ← psElabCoreBoundaryTemplate localIds domain actualDomain replacements
      psElabCoreBoundaryTemplate localIds body actualBody replacements
  | .forallE _ domain body binder =>
    let .forallE _ actualDomain actualBody actualBinder := actual | none
    if !psBinderInfoEq binder actualBinder then none
    else
      let replacements ← psElabCoreBoundaryTemplate localIds domain actualDomain replacements
      psElabCoreBoundaryTemplate localIds body actualBody replacements
  | .letE _ type value body =>
    let .letE _ actualType actualValue actualBody := actual | none
    let replacements ← psElabCoreBoundaryTemplate localIds type actualType replacements
    let replacements ← psElabCoreBoundaryTemplate localIds value actualValue replacements
    psElabCoreBoundaryTemplate localIds body actualBody replacements
  | .proj name index value =>
    let .proj actualName actualIndex actualValue := actual | none
    if !psNameEq name actualName || index != actualIndex then none
    else psElabCoreBoundaryTemplate localIds value actualValue replacements
  | _ => if psExprAlphaEq template actual then some replacements else none

-- Read-only metadata validation does not publish speculative metavariables.
-- Inferring an ordinary let independently checks its declared type and value;
-- its closed Sort body keeps that check independent of the marker application.
def psElabCoreBoundaryMatch (context : PsElabContext) (name : PsName)
    (type value : PsExpr) : Except PsElabError (Option PsElabCoreBoundary) := do
  match context.coreBoundaries.filter (fun entry => psNameEq entry.name name) with
  | [] => return none
  | [entry] =>
    let type := psMetaInstantiate context.metaContext type
    let value := psMetaInstantiate context.metaContext value
    if !psMetaExprScopeSafe context.metaContext context.localContext type ||
        !psMetaExprScopeSafe context.metaContext context.localContext value then
      return none
    let some replacements := psElabCoreBoundaryTemplate entry.localIds
        (psMetaInstantiate context.metaContext entry.type) type []
      | return none
    let some _ := psElabCoreBoundaryTemplate entry.localIds
        (psMetaInstantiate context.metaContext entry.value) value replacements
      | return none
    let _ ← (psInferType context.environment context.metaContext context.localContext
      (.letE name type value (.sortE .zero))).mapError PsElabError.infer
    return some entry
  | _ => throw (.refinement "ambiguous checked Core boundary")

structure PsElabOpenCoreBoundary where
  outer : PsElabContext
  context : PsElabContext
  id : Nat
  name : PsName
  type : PsExpr
  value : PsExpr

-- A genuine local let retains the checked closure until its later Core owner
-- consumes it. The body is constructed only by applying that actual local.
def psElabCoreBoundaryOpen (context : PsElabContext) (kind : PsElabCoreBoundaryKind)
    (value type : PsExpr) : Except PsElabError PsElabOpenCoreBoundary := do
  let checked ← psElabResolvedTerm context value none
  let checked ← psElabUnifyExpected checked (some type)
  let _ ← psElabExpressionSort checked.context checked.type
  let name := psNameAppendNum (psRootName "$psc0CoreBoundary")
    checked.context.coreBoundaries.length
  if checked.context.coreBoundaries.any (fun entry => psNameEq entry.name name) then
    throw (.refinement "checked Core boundary identity reused")
  let entry : PsElabCoreBoundary := {
    name, kind, type := checked.type, value := checked.term
    localIds := checked.context.localContext.declarations.map psLocalDeclId }
  let outer := { checked.context with coreBoundaries := entry :: checked.context.coreBoundaries }
  let pushed := psLocalPushLet outer.localContext name checked.type checked.term
  return {
    outer, context := psElabContextWithLocal outer pushed.context
    id := pushed.id, name, type := checked.type, value := checked.term }

def psElabCoreBoundaryClose (opened : PsElabOpenCoreBoundary)
    (result : PsElabTermResult) (expected : Option PsExpr) :
    Except PsElabError PsElabTermResult :=
  psElabCloseLetScope opened.outer result opened.id opened.name opened.type opened.value expected
