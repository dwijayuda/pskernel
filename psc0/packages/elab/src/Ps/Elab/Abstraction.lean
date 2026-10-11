import Ps.Elab.Basic

-- Closing a term with holes creates a managed metavariable in the outer scope.
-- Its children keep their original goal contexts. No future free variable is
-- converted into a bound index before its assignment is available.
def psElabAbstract (outer inner : PsElabContext) (abstractions : List PsMetaAbstraction)
    (body type : PsExpr) : Except PsElabError PsElabTermResult := do
  let context := psElabLeaveScope outer inner
  let entry : PsMetaDelayedAssignment := { id := 0, abstractions, body }
  match psMetaTryClose context.metaContext entry with
  | some value => psElabResolvedTerm context value (some type)
  | none =>
    let fresh := psMetaFresh context.metaContext context.localContext type .syntheticOpaque
    let .mvar id := fresh.expr | throw .unresolvedMetavariable
    let some constraints := psMetaAssignDelayed fresh.context id abstractions body
      | throw (.invalidArgument "invalid delayed scope abstraction")
    return {
      context := psElabContextWithMeta context constraints
      term := fresh.expr
      type }

def psElabAbstractType (outer inner : PsElabContext)
    (abstractions : List PsMetaAbstraction) (body : PsExpr) :
    Except PsElabError PsElabTermResult := do
  let level ← psElabExpressionSort inner body
  let level ← abstractions.foldlM (fun level abstraction => do
    match abstraction with
    | .forallE _ _ domain _ =>
      let domainLevel ← psElabExpressionSort inner domain
      pure (PsLevel.imax domainLevel level)
    | .letE _ _ _ _ => pure level
    | .lambdaE _ _ _ _ => throw (.invalidArgument "lambda in type abstraction")) level
  psElabAbstract outer inner abstractions body (.sortE level)

def psElabCloseLetScope (outer : PsElabContext) (result : PsElabTermResult)
    (id : Nat) (name : PsName) (type value : PsExpr) (expected : Option PsExpr) :
    Except PsElabError PsElabTermResult := do
  let abstractions := [PsMetaAbstraction.letE id name type value]
  let closedType ← psElabAbstractType outer result.context abstractions result.type
  let inner := psElabContextWithMeta result.context closedType.context.metaContext
  let closed ← psElabAbstract outer inner abstractions result.term closedType.term
  psElabFinalizeExpected closed expected
