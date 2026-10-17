import Ps.Elab.Term
import Ps.Meta.Recursor

-- Pinned Lean's monotonicity tactic constructs ordinary proofs from the
-- selected order lemmas. This consumer uses the shared portable goal,
-- unification and cases owners; a failed search admits no declaration.
def psElabMonotonicityName (suffix : String) : PsName :=
  (["Lean", "Order"] ++ suffix.splitOn ".").foldl psNameAppendStr .anonymous

def psElabMonotonicityApply (state : PsProofState) (name : PsName) :
    Except PsElabError PsProofState := do
  let (goal, context, target) ← psProofMain state
  let (context, term) ← psElabResolvedReference context (.global name)
  let value ← psElabResolvedTerm context term none
  let value ← psProofApplyTerm 4096 value target
  psProofApplied state goal context.metaContext.nextId value

-- Reduce only the functional's head and its outer binder's head redexes.
-- Eta expansion preserves the actual inferred telescope and binder kind.
def psElabMonotonicityBody (context : PsElabContext) (functional : PsExpr) :
    Except PsElabError PsExpr := do
  let functional := psWhnf context.environment context.metaContext
    context.localContext (psMetaInstantiate context.metaContext functional)
  let body ← match functional with
    | .lam _ _ body _ => pure body
    | _ => do
      let type ← (psInferType context.environment context.metaContext
        context.localContext functional).mapError PsElabError.infer
      let _ ← (psInferEnsureForall context.environment context.metaContext
        context.localContext type).mapError PsElabError.infer
      pure (.app (psExprLiftBVars 1 0 functional) (.bvar 0))
  return psWhnf context.environment context.metaContext context.localContext body

def psElabMonotonicityRecursiveCall : PsExpr → Bool
  | .bvar 0 => true
  | .app function argument =>
    !psElabHasLooseBound argument && psElabMonotonicityRecursiveCall function
  | .proj _ _ value => psElabMonotonicityRecursiveCall value
  | _ => false

def psElabMonotonicityCases (state : PsProofState) (majorId : Nat) :
    Except PsElabError PsProofState := do
  let (goal, context, target) ← psProofMain state
  if !psLocalContainsId context.localContext majorId then
    throw (.proof "monotonicity case major is outside the current local context")
  let position : PsSourcePos := { byteOffset := 0, line := 1, column := 1 }
  let span := context.sourceSpan.getD { start := position, stop := position }
  let source : PsSyntaxTerm := .reference
    (PsSyntaxName.mk ["$psc0MonotonicityMajor"] span)
  let read := fun current _ expected =>
    psElabResolvedTerm current (.fvar majorId) expected
  let result ← psElabMatchWith read (fun current info =>
    info.constructors.mapM fun name => do
      let some constructor := psEnvironmentFindConstructor current.environment name
        | throw (.matchConstructorUnknown name)
      let span := psSyntaxTermSpan source
      let fields := (List.range constructor.numFields).map fun index =>
        PsSyntaxName.mk ["$psc0Monotonicity", psNatToString current.localContext.nextId,
          psNatToString index] span
      return {
        constructorName := name
        fieldNames := fields
        elaborate := psProofEliminationGoal
          (psProofTag goal.tag (psNameLastComponent name)) false
        span }) context source (some target)
  let pending := psProofFreshGoals context.metaContext.nextId result.context
  let state ← psProofAssign (psProofUpdate state result.context) goal.id result.term
  psProofNormalize { state with goals := pending ++ state.goals.drop 1 }

-- Every recursive step consumes proof depth. Backtracking starts from the
-- original immutable proof state and propagates resource exhaustion.
def psElabMonotonicitySolve (fuel : Nat) (state : PsProofState) :
    Except PsElabError PsProofState := do
  match fuel with
  | 0 => throw .fuelExhausted
  | fuel + 1 =>
    let state ← psProofNormalize state
    if state.goals.isEmpty then return state
    let (_, context, target) ← psProofMain state
    let target := psMetaInstantiate context.metaContext target
    match target with
    | .forallE .. =>
      return ← psElabMonotonicitySolve fuel (← psProofIntro state none)
    | _ => pure ()
    let view := psExprAppView target
    let .constE name _ := view.head
      | throw (.proof "monotonicity requires an actual selected monotone goal")
    if !psNameEq name (psElabMonotonicityName "monotone") then
      throw (.proof "monotonicity produced an unsupported proof obligation")
    let [_, _, _, _, functional] := view.args
      | throw (.proof "monotone has a different actual argument telescope")
    let body ← psElabMonotonicityBody context functional
    let lemmas := if !psElabHasLooseBound body then ["monotone_const"] else
      match body with
      | .lam .. => ["monotone_of_monotone_apply"]
      | .bvar 0 => ["monotone_id"]
      | .proj _ 0 _ =>
        if psElabMonotonicityRecursiveCall body then ["PProd.monotone_fst"] else []
      | .proj _ 1 _ =>
        if psElabMonotonicityRecursiveCall body then ["PProd.monotone_snd"] else []
      | _ =>
        if psElabMonotonicityRecursiveCall body then ["monotone_apply"] else
          ["PProd.monotone_mk", "monotone_ite", "monotone_dite"]
    for lemma in lemmas do
      let name := psElabMonotonicityName lemma
      if (psEnvironmentFind context.environment name).isSome then
        let attempt := do
          let next ← psElabMonotonicityApply state name
          psElabMonotonicitySolve fuel next
        match attempt with
        | .ok result => return result
        | .error error =>
          if psElabErrorIsResource error then throw error
    -- A source match may be split only on an actual outer local. A major
    -- involving the recursive functional cannot manufacture monotonicity.
    if let some application := psEliminationRecursorApplication context.environment body then
      if !psElabHasLooseBound application.major then
        if let .fvar id := application.major then
          return ← psElabMonotonicitySolve fuel (← psElabMonotonicityCases state id)
    throw (.proof "selected checked monotonicity lemmas and independent constructor cases did not solve the functional")

def psElabMonotonicityProof (context : PsElabContext) (target : PsExpr) :
    Except PsElabError PsExpr := do
  let _ ← psElabResolvedTerm context target (some (.sortE .zero))
  let fresh := psMetaFresh context.metaContext context.localContext target .syntheticOpaque
  let .mvar id := fresh.expr | throw (.proof "invalid monotonicity proof goal")
  let result ← psElabMonotonicitySolve 256 {
    context := psElabContextWithMeta context fresh.context
    goals := [{ id }] }
  if !result.goals.isEmpty then
    throw (.proof "monotonicity proof retains unsolved goals")
  let proof := psMetaInstantiate result.context.metaContext fresh.expr
  if psExprHasUnresolvedMeta proof || !psExprFVarsInContext context.localContext proof then
    throw (.proof "monotonicity proof retains an unresolved or escaping local")
  let checked ← psElabResolvedTerm context proof (some target)
  return checked.term
