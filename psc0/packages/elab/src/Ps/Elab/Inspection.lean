import Ps.Elab.InspectionPrint
import Ps.Elab.InspectionEval
import Ps.Elab.Scope

-- Only stuck instance inputs may survive #check. The existing target key
-- ignores output parameters; definite failures and source continuations keep
-- the original owner diagnostic.
def psInspectionStuckInstance (context : PsElabContext) (work : PsElabPendingWork) : Bool :=
  match work with
  | .core scope (.instanceGoal id) =>
    match psMetaFindDecl context.metaContext id with
    | none => false
    | some declaration =>
      match psPrepareInstanceTarget scope.environment declaration.localContext
          context.metaContext declaration.type false with
      | none => false
      | some target => psExprHasUnresolvedMeta target.key
  | _ => false

def psInspectionElaborate (context : PsElabContext) (source : PsSyntaxTerm)
    (allowStuck : Bool) : Except PsElabError PsElabTermResult := do
  let result ← psElabTermWithFuel 4096 { context with postponing := true } source none
  let solved := psSyntheticQueueSolveChecked
    (psElabResumeWorkAttempt (psElabTermWithFuel 4096)) psElabPendingIsDefault
    psElabPendingPriorities psElabResumeDefault
    { result.context with pending := [], postponing := false }
    result.context.pending.reverse true 32768
  if solved.resourceExceeded then throw .fuelExhausted
  for work in solved.pending do
    if allowStuck && psInspectionStuckInstance solved.context work then continue
    let _ ← psElabResumeWork (psElabTermWithFuel 4096) solved.context work
    throw .unresolvedMetavariable
  let context := { solved.context with pending := [] }
  psElabResolvedTerm context (psMetaInstantiate context.metaContext result.term) none

def psInspectionCheckTerm (context : PsElabContext) (source : PsSyntaxTerm) :
    Except PsElabError String := do
  if let .reference name := source then
    if let some (.global actual, []) :=
        psElabResolveReferenceBase context.localContext context.environment name then
      let some declaration := psEnvironmentFind context.environment actual | throw (.unknownName actual)
      let levels := psDeclarationLevelParams declaration
      let checked ← psElabResolvedTerm
        { context with levelNames := context.levelNames ++ levels }
        (.constE actual (levels.map PsLevel.param)) none
      let suffix := if levels.isEmpty then "" else
        ".{" ++ String.intercalate ", " (levels.map psInspectionName) ++ "}"
      return psInspectionName actual ++ suffix ++ " : " ++
        (← psInspectionExpr 4096 checked.context.localContext [] checked.type)
  let result ← psInspectionElaborate context source true
  return (← psInspectionExpr 4096 result.context.localContext [] result.term) ++ " : " ++
    (← psInspectionExpr 4096 result.context.localContext [] result.type)

def psElabInspection (environment : PsEnvironment) (scope : PsCommandScope)
    (privateAliases : List (List String × PsName))
    (command : PsSyntaxInspection) (span : PsSourceSpan) :
    Except PsElabError PsDiagnostic := do
  let resolver : PsScopeResolver := { environment, scope, privateAliases }
  let scopedBinders ← psScopeBinders (psScopeTerm 4096 resolver) []
    (scope.variables.map (·.binder))
  let prepared ← psElabTypedBinders psElabTerm
    (psElabContextEmpty environment scope.levelNames) scopedBinders.binders
  let context := { prepared.context with sourceSpan := some span }
  let message ← match command with
    | .printDeclaration sourceName axioms => do
      let (resolved, _) ← psScopeResolve resolver scopedBinders.bound sourceName
      let some (.global name, []) := psElabResolveReferenceBase context.localContext environment resolved
        | throw (psInspectionError "#print requires one resolved declaration identifier")
      let some declaration := psEnvironmentFind environment name | throw (.unknownName name)
      if axioms then psInspectionPrintAxioms environment name
      else psInspectionPrintDeclaration environment declaration
    | .checkTerm source => do
      let scoped ← psScopeTerm 4096 resolver scopedBinders.bound source
      psInspectionCheckTerm context scoped.term
    | .reduceTerm source => do
      let scoped ← psScopeTerm 4096 resolver scopedBinders.bound source
      let result ← psInspectionElaborate context scoped.term false
      let reduced ← psInspectionReduce result.context result.term
      psInspectionExpr 4096 result.context.localContext [] reduced
    | .evalTerm source => do
      let scoped ← psScopeTerm 4096 resolver scopedBinders.bound source
      let result ← psInspectionElaborate context scoped.term false
      psInspectionEval result
  return { severity := .info, message, span }
