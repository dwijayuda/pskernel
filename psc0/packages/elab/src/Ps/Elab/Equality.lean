import Ps.Elab.GroupElimination

structure PsElabEquation where
  level : PsLevel
  type : PsExpr
  left : PsExpr
  right : PsExpr
  proof : PsExpr

-- Pinned Lean4.35.0 Cases.generalizeIndices' uses telescopic Eq/HEq
-- constraints. Dependent index types need HEq until earlier index equations
-- have transported them into the same type; the major needs the same bridge.
def psElabIndexEquation (context : PsElabContext) (left right : PsExpr) :
    Except PsElabError (PsExpr × PsExpr) := do
  let leftType ← (psInferType context.environment context.metaContext
    context.localContext left).mapError PsElabError.infer
  let rightType ← (psInferType context.environment context.metaContext
    context.localContext right).mapError PsElabError.infer
  let level ← psElabExpressionSort context rightType
  if psDefEqReadOnlyWithEnv context.environment context.metaContext
      context.localContext leftType rightType then
    return (psLogicEq level rightType left right, psLogicRefl level rightType right)
  let leftLevel ← psElabExpressionSort context leftType
  if !psLevelEquivalent leftLevel level then
    throw (.refinement "index equality relates incompatible universes")
  let heq := psExprApplyMany (.constE (psRootName "HEq") [level])
    [leftType, left, rightType, right]
  let refl := psExprApplyMany (.constE (psNameAppendStr (psRootName "HEq") "refl") [level])
    [rightType, right]
  return (heq, refl)

-- A retry candidate retains its raw source index separately from both current
-- sides. Only the current sides consume actual equality-refinement logs.
structure PsElabIndexRefinementCandidate where
  original : PsExpr
  left : PsExpr
  right : PsExpr
  named : Bool := false

def psElabEquationViewWithIndexRequest (context : PsElabContext) (type proof : PsExpr)
    (requests : List PsElabIndexRefinementCandidate) :
    Except PsElabError PsElabEquation := do
  let view := psExprAppView (psWhnf context.environment context.metaContext context.localContext type)
  match view.head, view.args with
  | .constE name [level], [type, left, right] =>
    if psNameEq name psEqName then return { level, type, left, right, proof }
    throw (.refinement "expected a homogeneous index equation")
  | .constE name [level], [leftType, left, rightType, right] =>
    if !psNameEq name (psRootName "HEq") then
      throw (.refinement "expected an index equality")
    -- Like pinned UnifyEq.heqToEq', conversion is allowed only after the
    -- preceding constraints have made both actual types definitionally equal.
    if !psDefEqReadOnlyWithEnv context.environment context.metaContext
        context.localContext leftType rightType then
      let cause := PsElabError.refinement "preceding index constraints did not align heterogeneous types"
      let request := requests.find? fun candidate =>
        !psDefEqReadOnlyWithEnv context.environment context.metaContext
          context.localContext candidate.left candidate.right
      match request with
      | some candidate => throw (.sourceMatchIndexRefinement [candidate.original] candidate.named cause)
      | none => throw cause
    let converted := psExprApplyMany (.constE (psRootName "eq_of_heq") [level])
      [leftType, left, right, proof]
    let checked ← psElabResolvedTerm context converted
      (some (psLogicEq level leftType left right))
    return { level, type := leftType, left, right, proof := checked.term }
  | _, _ => throw (.refinement "expected an index equality")

-- Existing elimination and tactic callers retain the exact failure contract.
def psElabEquationView (context : PsElabContext) (type proof : PsExpr) :
    Except PsElabError PsElabEquation :=
  psElabEquationViewWithIndexRequest context type proof []

def psElabEquationRec (context : PsElabContext) (equation : PsElabEquation)
    (result : PsExpr -> PsExpr) (base : PsExpr) : Except PsElabError PsExpr := do
  let id := context.localContext.nextId
  let freshValue := PsExpr.fvar id
  let target := result equation.right
  let level ← psElabExpressionSort context target
  let motive := psLogicLam id "_eqValue" equation.type
    (psLogicLam (id + 1) "_eqProof" (psLogicEq equation.level equation.type equation.left freshValue)
      (result freshValue))
  return psExprApplyMany (.constE (psNameAppendStr psEqName "rec") [level, equation.level])
    [equation.type, equation.left, motive, base, equation.right, equation.proof]

def psElabEquationSymm (context : PsElabContext) (equation : PsElabEquation) :
    Except PsElabError PsElabEquation := do
  let proof ← psElabEquationRec context equation
    (fun right => psLogicEq equation.level equation.type right equation.left)
    (psLogicRefl equation.level equation.type equation.left)
  return { equation with left := equation.right, right := equation.left, proof }

def psElabEquationCongr (context : PsElabContext) (equation : PsElabEquation)
    (fn resultType : PsExpr) : Except PsElabError PsElabEquation := do
  let level ← psElabExpressionSort context resultType
  let left := PsExpr.app fn equation.left
  let right := PsExpr.app fn equation.right
  let proof ← psElabEquationRec context equation
    (fun value => psLogicEq level resultType left (.app fn value))
    (psLogicRefl level resultType left)
  return { level, type := resultType, left, right, proof }

-- Build a discriminator or homogeneous projection using the complete direct
-- group. Every family has a constant motive at the actual result type; an
-- existing fallback supplies the other branches. No inhabitant or recursive
-- evidence is invented, and every minor retains its unused real IH binders.
def psElabIndexFunction (context : PsElabContext) (value : PsExpr)
    (selected : PsName) (field : Option Nat) (resultType fallback chosen : PsExpr) :
    Except PsElabError PsExpr := do
  let type ← (psInferType context.environment context.metaContext context.localContext value).mapError PsElabError.infer
  let view := psExprAppView (psWhnf context.environment context.metaContext context.localContext type)
  let .constE family levels := view.head | throw (.refinement "index constructor family unavailable")
  let some info := psEnvironmentFindInductive context.environment family
    | throw (.refinement "index constructor family unavailable")
  if info.numIndices != 0 then throw (.refinement "dependent index-constructor projections are pending")
  if view.args.length != info.numParams then throw .matchParameterArity
  let some selectedConstructor := psEnvironmentFindConstructor context.environment selected
    | throw (.matchConstructorUnknown selected)
  let some selectedName := info.constructors[selectedConstructor.constructorIndex]?
    | throw .matchRecursorUnsupported
  if !psNameEq selectedConstructor.inductiveName info.name || !psNameEq selectedName selected then
    throw .matchRecursorUnsupported
  let level ← psElabExpressionSort context resultType
  let fallback ← psElabResolvedTerm context fallback (some resultType)
  let context := fallback.context
  let (context, chosen) ← match field with
    | none => do
      let checked ← psElabResolvedTerm context chosen (some resultType)
      pure (checked.context, checked.term)
    | some _ => pure (context, chosen)
  let recursor ← psElabGroupRecursorPlanFor context info levels view.args level
  if recursor.group.members.any (·.numIndices != 0) then
    throw (.refinement "dependent index-constructor projections are pending")
  let constructors ← psElabGroupConstructors recursor.context recursor.group
  let motives ← psElabRecursorArguments recursor.group.members
    (fun current member type => do
      let opened ← psElabOpenCoreTelescope 4096 current type (some 1)
      let [major] := opened.bindersRev | throw .matchRecursorUnsupported
      let familyType := psExprApplyMany (.constE member.name levels) view.args
      if !psDefEqReadOnlyWithEnv opened.context.environment opened.context.metaContext
          opened.context.localContext major.type familyType then
        throw .matchRecursorUnsupported
      return {
        context := psElabLeaveScope current opened.context
        term := psCloseElabLambdaBinders opened.context.metaContext opened.bindersRev resultType })
    recursor.context recursor.cursor
  let minors ← psElabRecursorArguments constructors
    (fun current (_, constructor) type => do
      let opened ← psElabOpenCoreTelescope 4096 current type
        (some (constructor.numFields + constructor.recursiveFields.length))
      let body ←
        if psNameEq constructor.name selected then
          match field with
          | none => pure chosen
          | some index => do
            if index >= constructor.numFields then throw .matchRecursorUnsupported
            let some binder := opened.bindersRev.reverse[index]? | throw .matchRecursorUnsupported
            if !psDefEqReadOnlyWithEnv opened.context.environment opened.context.metaContext
                opened.context.localContext binder.type resultType then
              throw (.refinement "dependent index-constructor projections are pending")
            pure (.fvar binder.id)
        else pure fallback.term
      return {
        context := psElabLeaveScope current opened.context
        term := psCloseElabLambdaBinders opened.context.metaContext opened.bindersRev body })
    motives.context motives.cursor
  let id := context.localContext.nextId
  let term := psLogicLam id "_index" type
    (psExprApplyMany (.constE recursor.recursor.name recursor.levels)
      (view.args ++ motives.arguments ++ minors.arguments ++ [.fvar id]))
  let checked ← psElabResolvedTerm (psElabLeaveScope context minors.context) term
    (some (psLogicPi id "_index" type resultType))
  return checked.term

def psElabIndexConstructor (context : PsElabContext) (value : PsExpr) :
    Option (PsConstructorInfo × List PsExpr) := do
  let view := psReduceConstructorView (psWhnf context.environment context.metaContext context.localContext value)
  let .constE name _ := view.head | none
  let info ← psEnvironmentFindConstructor context.environment name
  if view.args.length != info.numParams + info.numFields then none else
    return (info, view.args.drop info.numParams)

def psElabFalseElimination (context : PsElabContext) (target proof : PsExpr) :
    Except PsElabError PsElabTermResult := do
  let level ← psElabExpressionSort context target
  let term := psExprApplyMany (.constE (psNameAppendStr (psRootName "False") "elim") [level]) [target, proof]
  return { context, type := target, term }

-- Equality elimination reverts the dependency closure, specializes it in the
-- base case, and applies the original locals after transport. Types and values
-- are never mutated in place.
-- Continuations receive the ordered substitutions actually performed by
-- equality transport, including fresh dependent bindings and let declarations.
-- Typed match consumers apply this log to retained expressions; source names
-- are not an identity map and must not be used to recover these substitutions.
abbrev PsElabRefinements := List (Nat × PsExpr)

def psElabSubstituteEquationWithRefinements
    (finish : PsElabRefinements -> PsElabContext -> PsExpr -> Except PsElabError PsElabTermResult)
    (refinements : PsElabRefinements) (context : PsElabContext) (equation : PsElabEquation) (id : Nat)
    (ignored : List Nat) (target : PsExpr) : Except PsElabError PsElabTermResult := do
  let dependents := psElabDependentLocals context [id] ignored
  let telescope := psElabCloseDependentType dependents target
  let substitutions := [(id, equation.left)]
  let specialized := psElabSubstituteLocals substitutions telescope
  let aliases ← psElabMatchAlias { context, valuesRev := [] } (id, equation.left)
  let opened ← psElabOpenDependents dependents {
    context := aliases.context, body := specialized, bindersRev := []
    aliasesRev := aliases.valuesRev, replacements := substitutions }
  let body ← finish (refinements ++ opened.replacements) opened.context opened.body
  let base ← psElabCloseDependents context opened body specialized
  -- Native substCore's tryToSkip avoids Eq.rec when the completed dependent
  -- target did not change. Branch elaboration can solve an omitted result
  -- metavariable, so compare with its final assignments and conversion rather
  -- than the stale syntax captured before finish. Alias refinement remains.
  if psDefEqReadOnlyWithEnv base.context.environment base.context.metaContext
      base.context.localContext telescope specialized then
    return ← psElabResolvedTerm base.context
      (psExprApplyMany base.term (psElabDependentArguments dependents)) (some target)
  let transported ← psElabEquationRec base.context equation
    (fun value => psElabSubstituteLocals [(id, value)] telescope) base.term
  return {
    context := base.context
    type := target
    term := psExprApplyMany transported (psElabDependentArguments dependents) }

mutual
def psElabSolveIndexConstraintsWithRefinements (fuel count : Nat) (flexible ignored : List Nat)
    (finish : PsElabRefinements -> PsElabContext -> PsExpr -> Except PsElabError PsElabTermResult)
    (refinements : PsElabRefinements) (context : PsElabContext) (target : PsExpr)
    (requests : List PsElabIndexRefinementCandidate := []) (protectedIds : List Nat := [])
    (protectedReady : Bool := false) :
    Except PsElabError PsElabTermResult := do
  match fuel with
  | 0 => throw .fuelExhausted
  | fuel + 1 =>
    let protectedIds := if protectedReady then protectedIds else
      (protectedIds ++ context.localContext.declarations.filterMap (fun declaration =>
        let id := psLocalDeclId declaration
        if flexible.contains id then none else some id)).eraseDups
    match count with
    | 0 => finish refinements context target
    | count + 1 =>
      let pi ← (psInferEnsureForall context.environment context.metaContext context.localContext target).mapError PsElabError.infer
      let pushed := psLocalPushBinding context.localContext pi.name pi.domain pi.binder
      let inner := psElabContextWithLocal context pushed.context
      let currentRequests := requests.map fun candidate => { candidate with
        left := psElabSubstituteLocals refinements candidate.left
        right := psElabSubstituteLocals refinements candidate.right }
      let equation ← psElabEquationViewWithIndexRequest inner pi.domain (.fvar pushed.id) currentRequests
      let next := fun refinements context target =>
        psElabSolveIndexConstraintsWithRefinements fuel count flexible (pushed.id :: ignored)
          finish refinements context target requests protectedIds true
      let body ← psElabSolveIndexEquationWithRefinements fuel flexible (pushed.id :: ignored)
        next refinements inner (psExprInstantiate1 pi.body (.fvar pushed.id)) equation requests protectedIds true
      psElabAbstract context body.context
        [.lambdaE pushed.id pi.name pi.domain pi.binder] body.term target

def psElabSolveIndexEquationWithRefinements (fuel : Nat) (flexible ignored : List Nat)
    (finish : PsElabRefinements -> PsElabContext -> PsExpr -> Except PsElabError PsElabTermResult)
    (refinements : PsElabRefinements) (context : PsElabContext) (target : PsExpr) (equation : PsElabEquation)
    (requests : List PsElabIndexRefinementCandidate := []) (protectedIds : List Nat := [])
    (protectedReady : Bool := false) :
    Except PsElabError PsElabTermResult := do
  match fuel with
  | 0 => throw .fuelExhausted
  | fuel + 1 =>
    let protectedIds := if protectedReady then protectedIds else
      (protectedIds ++ context.localContext.declarations.filterMap (fun declaration =>
        let id := psLocalDeclId declaration
        if flexible.contains id then none else some id)).eraseDups
    -- Earlier equations can reopen a dependent flexible local at a fresh ID.
    -- Follow only the recorded typed substitutions, retaining the caller's
    -- protected source identities even when a field is equated with one.
    let flexible := (flexible.filterMap fun id =>
      match psMetaInstantiate context.metaContext
          (psElabSubstituteLocals refinements (.fvar id)) with
      | .fvar current =>
        if !protectedIds.contains current &&
            (psLocalFindById context.localContext current).isSome then some current else none
      | _ => none).eraseDups
    let reduce := psWhnf context.environment context.metaContext context.localContext
    let left := reduce equation.left
    let right := reduce equation.right
    -- Preserve proof-dependent substitutions before conversion can identify
    -- distinct proofs by proof irrelevance (pinned UnifyEq.unifyEq?).
    if psExprAlphaEq left right then return ← finish refinements context target
    -- Prefer eliminating an auxiliary index, then a constructor field. A cyclic
    -- equation is left unsolved; an occurs check is not a contradiction proof.
    match right with
    | .fvar id => if flexible.contains id && !psElabExprContainsLocal id left then
        return ← psElabSubstituteEquationWithRefinements finish refinements context { equation with left, right } id ignored target
    | _ => pure ()
    match left with
    | .fvar id => if flexible.contains id && !psElabExprContainsLocal id right then
        let symmetric ← psElabEquationSymm context { equation with left, right }
        return ← psElabSubstituteEquationWithRefinements finish refinements context symmetric id ignored target
    | _ => pure ()
    if psDefEqReadOnlyWithEnv context.environment context.metaContext context.localContext left right then
      return ← finish refinements context target
    match psElabIndexConstructor context left, psElabIndexConstructor context right with
    | some (leftCtor, leftFields), some (rightCtor, rightFields) =>
      if !psNameEq leftCtor.inductiveName rightCtor.inductiveName then
        throw (.refinement "index equation family mismatch")
      if !psNameEq leftCtor.name rightCtor.name then
        let predicate ← psElabIndexFunction context left leftCtor.name none (.sortE .zero)
          (.constE (psRootName "False") []) (.constE (psRootName "True") [])
        let contradiction ← psElabEquationRec context equation
          (fun value => .app predicate value) (.constE (psNameAppendStr (psRootName "True") "intro") [])
        return ← psElabFalseElimination context target contradiction
      if leftFields.length != rightFields.length then throw (.matchConstructorArity leftCtor.name)
      let equations ← (leftFields.zipIdx).mapM fun entry => do
        let type ← (psInferType context.environment context.metaContext context.localContext entry.fst).mapError PsElabError.infer
        let projection ← psElabIndexFunction context left leftCtor.name (some entry.snd) type entry.fst entry.fst
        psElabEquationCongr context equation projection type
      let offset := context.localContext.nextId
      let telescope := (equations.zipIdx).foldr (fun entry body =>
        psLogicPi (offset + entry.snd) "_indexEq"
          (psLogicEq entry.fst.level entry.fst.type entry.fst.left entry.fst.right) body) target
      let body ← psElabSolveIndexConstraintsWithRefinements fuel equations.length flexible ignored
        finish refinements context telescope requests protectedIds true
      return { body with type := target, term := psExprApplyMany body.term (equations.map (fun entry => entry.proof)) }
    | _, _ => finish refinements context target
end


-- Existing tactic and elimination callers retain the same interface and use
-- the same implementation. Only typed consumers request the refinement log.
def psElabSubstituteEquation
    (finish : PsElabContext -> PsExpr -> Except PsElabError PsElabTermResult)
    (context : PsElabContext) (equation : PsElabEquation) (id : Nat)
    (ignored : List Nat) (target : PsExpr) : Except PsElabError PsElabTermResult :=
  psElabSubstituteEquationWithRefinements (fun _ => finish) []
    context equation id ignored target

def psElabSolveIndexConstraints (fuel count : Nat) (flexible ignored : List Nat)
    (finish : PsElabContext -> PsExpr -> Except PsElabError PsElabTermResult)
    (context : PsElabContext) (target : PsExpr) : Except PsElabError PsElabTermResult :=
  psElabSolveIndexConstraintsWithRefinements fuel count flexible ignored
    (fun _ => finish) [] context target

def psElabSolveIndexEquation (fuel : Nat) (flexible ignored : List Nat)
    (finish : PsElabContext -> PsExpr -> Except PsElabError PsElabTermResult)
    (context : PsElabContext) (target : PsExpr) (equation : PsElabEquation) :
    Except PsElabError PsElabTermResult :=
  psElabSolveIndexEquationWithRefinements fuel flexible ignored
    (fun _ => finish) [] context target equation
