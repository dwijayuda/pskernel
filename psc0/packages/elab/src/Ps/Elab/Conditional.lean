import Ps.Elab.Abstraction

structure PsElabCondition where
  context : PsElabContext
  proposition : PsExpr
  decision : PsExpr

def psElabCondition (elaborate : PsElaborator) (context : PsElabContext)
    (source : PsSyntaxTerm) : Except PsElabError PsElabCondition := do
  let value ← elaborate context source none
  -- A proposition may have an instantiated imax/max level equivalent to zero.
  -- Use read-only conversion, as in pinned Lean Meta/InferType.isProp.
  if psDefEqReadOnlyWithEnv value.context.environment value.context.metaContext
      value.context.localContext value.type (.sortE .zero) then
    let target := PsExpr.app (.constE psDecidableName []) value.term
    let decision ← (psElabSynthesizeInstance value.context target).mapError fun error =>
      match error with
      | .implicitApplicationUnsupported =>
        .invalidArgument "conditional proposition requires a Decidable instance"
      | _ => error
    return {
      context := decision.context
      proposition := psMetaInstantiate decision.context.metaContext value.term
      decision := decision.term }
  else
    let value ← psElabFinalizeExpected value (some (.constE psBoolName []))
    let boolean := PsExpr.constE psBoolName []
    let truth := PsExpr.constE psBoolTrueName []
    return {
      context := value.context
      proposition := psExprApplyMany (.constE psEqName [.succ .zero]) [boolean, value.term, truth]
      decision := psExprApplyMany (.constE psBoolDecEqName []) [value.term, truth] }

-- A named conditional branch is an ordinary proof-binder scope. Use the same
-- delayed abstraction as lambdas, including holes introduced by refine.
def psElabConditionBranch (elaborate : PsElaborator) (context : PsElabContext)
    (name : PsSyntaxName) (proofType : PsExpr) (source : PsSyntaxTerm)
    (expected : Option PsExpr) : Except PsElabError (PsElabTermResult × PsExpr) := do
  let some name := psSyntaxNameToName name | throw .emptyName
  let pushed := psLocalPushBinding context.localContext name proofType .explicit
  let branch ← elaborate (psElabContextWithLocal context pushed.context) source expected
  let resultType := psMetaInstantiate branch.context.metaContext branch.type
  let outer := psElabLeaveScope context branch.context
  let _ ← psElabExpressionSort outer resultType
  let type := PsExpr.forallE name proofType resultType .explicit
  let closed ← psElabAbstract context branch.context
    [.lambdaE pushed.id name proofType .explicit] branch.term type
  return (closed, resultType)

def psElabIfWith (elaborate branch : PsElaborator) (context : PsElabContext)
    (name : Option PsSyntaxName) (condition thenBranch elseBranch : PsSyntaxTerm)
    (expected : Option PsExpr) : Except PsElabError PsElabTermResult := do
  let condition ← psElabCondition elaborate context condition
  let (yes, type) ← match name with
    | none => do
      let yes ← branch condition.context thenBranch expected
      pure (yes, expected.getD yes.type)
    | some name =>
      psElabConditionBranch branch condition.context name condition.proposition thenBranch expected
  let no ← match name with
    | none => branch yes.context elseBranch (some type)
    | some name => do
      let notP := PsExpr.app (.constE (psRootName "Not") []) condition.proposition
      pure (← psElabConditionBranch branch yes.context name notP elseBranch (some type)).fst
  let context := psElabLeaveScope context no.context
  let type := psMetaInstantiate context.metaContext type
  let level ← psElabExpressionSort context type
  let head := if name.isSome then psRootName "dite" else psIteName
  let term := psExprApplyMany (.constE head [level])
    [type, condition.proposition, condition.decision, yes.term, no.term]
  psElabResolvedTerm context (psMetaInstantiate context.metaContext term) expected

def psElabIf (elaborate : PsElaborator) : PsElabContext →
    Option PsSyntaxName → PsSyntaxTerm → PsSyntaxTerm → PsSyntaxTerm →
    Option PsExpr → Except PsElabError PsElabTermResult :=
  psElabIfWith elaborate elaborate
