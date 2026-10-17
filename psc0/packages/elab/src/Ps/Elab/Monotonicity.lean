/-
Selected algorithms adapted from Lean 4.35.0 (eb6cafb7290e8bd5f2937522d8d804f58f02bafc).
Copyright (c) 2024 Lean FRO, LLC. All rights reserved.
Released under Apache 2.0; see THIRD_PARTY_NOTICES.md.
Upstream author: Joachim Breitner.
-/
import Ps.Elab.Term
import Ps.Meta.Recursor

-- Pinned Lean's monotonicity tactic constructs ordinary proofs from the
-- selected order lemmas. This consumer uses the shared portable goal,
-- unification and cases owners; a failed search admits no declaration.
def psElabMonotonicityName (suffix : String) : PsName :=
  (["Lean", "Order"] ++ suffix.splitOn ".").foldl psNameAppendStr .anonymous

-- Inspect checked order dictionaries without unfolding the requested instance
-- head. In particular CCPO.toPartialOrder must expose the Pi/PProd instance
-- before its PartialOrder constructor is expanded.
def psElabMonotonicityExpose (fuel : Nat) (context : PsElabContext)
    (stop : PsExpr → Bool) (expression : PsExpr) : Except PsElabError PsExpr := do
  match fuel with
  | 0 => throw .fuelExhausted
  | fuel + 1 =>
    let expression := psWhnfCore context.metaContext context.localContext expression
    if stop expression then return expression
    let view := psExprAppView expression
    match view.head with
    | .constE name levels =>
      let some declaration := psEnvironmentFind context.environment name
        | throw (.proof "monotonicity order dictionary has an unknown head")
      if !psEnvironmentCanUnfold context.environment .all name then
        throw (.proof "monotonicity order dictionary cannot be unfolded")
      let some value := psDeclarationValue declaration
        | throw (.proof "monotonicity order dictionary is not a selected Pi/PProd instance")
      let parameters := psDeclarationLevelParams declaration
      if parameters.length != levels.length then
        throw (.proof "monotonicity order dictionary has an invalid universe telescope")
      psElabMonotonicityExpose fuel context stop
        (psExprApplyMany (psExprInstantiateLevelParams parameters levels value) view.args)
    | .proj owner index major =>
      let isConstructor := fun value =>
        match (psExprAppView value).head with
        | .constE name _ => (psEnvironmentFindConstructor context.environment name).isSome
        | _ => false
      let major ← psElabMonotonicityExpose fuel context isConstructor major
      let some field := psReduceProjectionIota (fun value => value)
          context.environment owner index major
        | throw (.proof "monotonicity order dictionary projection is stuck")
      psElabMonotonicityExpose fuel context stop (psExprApplyMany field view.args)
    | _ => throw (.proof "monotonicity order dictionary is not a selected Pi/PProd instance")

def psElabMonotonicityInstance (context : PsElabContext) (suffix : String)
    (expression : PsExpr) : Except PsElabError (List PsExpr) := do
  let name := psElabMonotonicityName suffix
  let expression ← psElabMonotonicityExpose 256 context (fun value =>
    match (psExprAppView value).head with
    | .constE actual _ => psNameEq name actual
    | _ => false) expression
  return (psExprAppView expression).args

def psElabMonotonicityCore (context : PsElabContext) (suffix : String)
    (arguments : List PsExpr) : Except PsElabError PsElabTermResult := do
  let (context, term) ← psElabResolvedReference context
    (.global (psElabMonotonicityName suffix))
  psElabApplyCore context term arguments

-- Like pinned solveMonoCall, build from the recursive variable outwards.
-- The function argument of every lemma is already known from the preceding
-- checked proof; no ordinary application metavariable must solve ?f x = x.
def psElabMonotonicityCall (fuel : Nat) (context : PsElabContext)
    (domain domainOrder body : PsExpr) :
    Except PsElabError (Option PsElabTermResult) := do
  match fuel with
  | 0 => throw .fuelExhausted
  | fuel + 1 =>
    match body with
    | .bvar 0 =>
      return some (← psElabMonotonicityCore context "monotone_id" [domain, domainOrder])
    | .app function argument =>
      if psElabHasLooseBound argument then return none
      let some proof ← psElabMonotonicityCall fuel context domain domainOrder function
        | return none
      let [_, _, _, order, functional] := (psExprAppView proof.type).args
        | throw (.proof "recursive-call monotonicity proof has an unexpected telescope")
      let [indexType, family, orders] ←
          psElabMonotonicityInstance proof.context "instOrderPi" order
        | throw (.proof "pointwise order instance has an unexpected telescope")
      return some (← psElabMonotonicityCore proof.context "monotone_apply"
        [indexType, family, domain, domainOrder, orders, argument, functional, proof.term])
    | .proj owner index major =>
      if !psNameEq owner (psRootName "PProd") || index >= 2 then return none
      let some proof ← psElabMonotonicityCall fuel context domain domainOrder major
        | return none
      let [_, _, _, order, functional] := (psExprAppView proof.type).args
        | throw (.proof "recursive-projection monotonicity proof has an unexpected telescope")
      let [left, right, leftOrder, rightOrder] ←
          psElabMonotonicityInstance proof.context "instPartialOrderPProd" order
        | throw (.proof "product order instance has an unexpected telescope")
      let lemma := if index == 0 then "PProd.monotone_fst" else "PProd.monotone_snd"
      return some (← psElabMonotonicityCore proof.context lemma
        [left, right, domain, leftOrder, rightOrder, domainOrder, functional, proof.term])
    | _ => return none

-- Supply the known functions in the selected compositional rules explicitly.
-- The remaining arguments are ordinary checked monotonicity proof goals.
def psElabMonotonicityCandidates (context : PsElabContext)
    (domain domainOrder codomain codomainOrder functional body : PsExpr) :
    Except PsElabError (List (String × List PsExpr)) := do
  if !psElabHasLooseBound body then
    return [("monotone_const", [domain, domainOrder, codomain, codomainOrder, body])]
  let close := fun value => PsExpr.lam .anonymous domain value .explicit
  match body with
  | .lam .. =>
    let [indexType, family, orders] ←
        psElabMonotonicityInstance context "instOrderPi" codomainOrder
      | throw (.proof "pointwise result order has an unexpected telescope")
    return [("monotone_of_monotone_apply",
      [indexType, family, domain, domainOrder, orders, functional])]
  | _ => pure ()
  let view := psExprAppView body
  let .constE name _ := view.head | return []
  if psNameEq name (psNameAppendStr (psRootName "PProd") "mk") then
    let [_, _, leftValue, rightValue] := view.args | return []
    let [left, right, leftOrder, rightOrder] ←
        psElabMonotonicityInstance context "instPartialOrderPProd" codomainOrder
      | throw (.proof "product result order has an unexpected telescope")
    return [("PProd.monotone_mk",
      [left, right, domain, leftOrder, rightOrder, domainOrder,
        close leftValue, close rightValue])]
  if psNameEq name (psRootName "ite") || psNameEq name (psRootName "dite") then
    let [_, condition, decision, leftValue, rightValue] := view.args | return []
    if psElabHasLooseBound condition || psElabHasLooseBound decision then return []
    let lemma := if psNameEq name (psRootName "ite") then "monotone_ite" else "monotone_dite"
    return [(lemma,
      [domain, codomain, domainOrder, codomainOrder, condition, decision,
        close leftValue, close rightValue])]
  return []

def psElabMonotonicityApply (state : PsProofState) (suffix : String)
    (arguments : List PsExpr) : Except PsElabError PsProofState := do
  let (goal, context, target) ← psProofMain state
  let value ← psElabMonotonicityCore context suffix arguments
  let value ← psProofApplyTerm 4096 value target
  psProofApplied state goal context.metaContext.nextId value

-- Keep global theorem heads such as ite/dite, but discharge actual checked
-- recursor/projection redexes exposed by constructor cases.
def psElabMonotonicityHead (fuel : Nat) (context : PsElabContext)
    (expression : PsExpr) : Except PsElabError PsExpr := do
  match fuel with
  | 0 => throw .fuelExhausted
  | fuel + 1 =>
    let expression := psWhnfCore context.metaContext context.localContext expression
    let reduce := psWhnf context.environment context.metaContext context.localContext
    let step := (psReduceIota reduce context.environment expression).orElse (fun _ =>
      let view := psExprAppView expression
      match view.head with
      | .proj owner index major =>
        (psReduceProjectionIota reduce context.environment owner index major).map
          (fun field => psExprApplyMany field view.args)
      | _ => none)
    match step with
    | some value => psElabMonotonicityHead fuel context value
    | none => pure expression

-- Reduce only the functional's head and its outer binder's head redexes.
-- Eta expansion preserves the actual inferred telescope and binder kind.
def psElabMonotonicityBody (context : PsElabContext) (functional : PsExpr) :
    Except PsElabError PsExpr := do
  let functional ← psElabMonotonicityHead 256 context functional
  let body ← match functional with
    | .lam _ _ body _ => pure body
    | _ => do
      let type ← (psInferType context.environment context.metaContext
        context.localContext functional).mapError PsElabError.infer
      let _ ← (psInferEnsureForall context.environment context.metaContext
        context.localContext type).mapError PsElabError.infer
      pure (.app (psExprLiftBVars 1 0 functional) (.bvar 0))
  psElabMonotonicityHead 256 context body

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
    let (goal, context, target) ← psProofMain state
    -- Constructor cases retain the motive application in each goal type.
    -- Expose its beta/local-let head without unfolding the monotone predicate.
    let target := psWhnfCore context.metaContext context.localContext target
    match target with
    | .forallE .. =>
      return ← psElabMonotonicitySolve fuel (← psProofIntro state none)
    | _ => pure ()
    let view := psExprAppView target
    let .constE name _ := view.head
      | throw (.proof "monotonicity requires an actual selected monotone goal")
    if !psNameEq name (psElabMonotonicityName "monotone") then
      throw (.proof "monotonicity produced an unsupported proof obligation")
    let [domain, domainOrder, codomain, codomainOrder, functional] := view.args
      | throw (.proof "monotone has a different actual argument telescope")
    let body ← psElabMonotonicityBody context functional
    if let some proof ← psElabMonotonicityCall fuel context domain domainOrder body then
      let next ← psProofAssign (psProofUpdate state proof.context) goal.id proof.term
      return ← psElabMonotonicitySolve fuel next
    let candidates ← psElabMonotonicityCandidates context
      domain domainOrder codomain codomainOrder functional body
    for (lemma, arguments) in candidates do
      let name := psElabMonotonicityName lemma
      if (psEnvironmentFind context.environment name).isSome then
        let attempt := do
          let next ← psElabMonotonicityApply state lemma arguments
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
  let validated ← psElabResolvedTerm context target (some (.sortE .zero))
  let context := validated.context
  let target := psMetaInstantiate context.metaContext validated.term
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
