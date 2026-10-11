import Ps.Elab.Refinement

structure PsElabEquation where
  level : PsLevel
  type : PsExpr
  left : PsExpr
  right : PsExpr
  proof : PsExpr

def psElabEquationView (context : PsElabContext) (type proof : PsExpr) :
    Except PsElabError PsElabEquation := do
  let view := psExprAppView (psWhnf context.environment context.metaContext context.localContext type)
  match view.head, view.args with
  | .constE name [level], [type, left, right] =>
    if psNameEq name psEqName then return { level, type, left, right, proof }
    throw (.refinement "expected a homogeneous index equation")
  | _, _ => throw (.refinement "expected a homogeneous index equation")

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

-- Build a discriminator or homogeneous projection using the family's own
-- recursor. Every minor is closed over its actual telescope, including IHs.
def psElabIndexFunction (context : PsElabContext) (value : PsExpr)
    (selected : PsName) (field : Option Nat) (resultType fallback chosen : PsExpr) :
    Except PsElabError PsExpr := do
  let type ← (psInferType context.environment context.metaContext context.localContext value).mapError PsElabError.infer
  let view := psExprAppView (psWhnf context.environment context.metaContext context.localContext type)
  let .constE family levels := view.head | throw (.refinement "index constructor family unavailable")
  let some info := psEnvironmentFindInductive context.environment family
    | throw (.refinement "index constructor family unavailable")
  if info.numIndices != 0 then throw (.refinement "dependent index-constructor projections are pending")
  let recName := psNameAppendStr family "rec"
  let some recursor := psEnvironmentFindRecursor context.environment recName | throw .matchRecursorUnsupported
  let level ← psElabExpressionSort context resultType
  let recLevels ← psElabRecursorLevels info recursor levels level
  let id := context.localContext.nextId
  let motive := psLogicLam id "_index" type resultType
  let recType := psExprInstantiateLevelParams recursor.levelParams recLevels recursor.type
  let some cursor := psReduceApplyType
    (psWhnf context.environment context.metaContext context.localContext) recType (view.args ++ [motive])
    | throw .matchRecursorUnsupported
  let state ← info.constructors.foldlM (fun (state : PsExpr × List PsExpr) ctorName => do
    let pi ← (psInferEnsureForall context.environment context.metaContext context.localContext state.fst).mapError PsElabError.infer
    let some ctor := psEnvironmentFindConstructor context.environment ctorName | throw .matchRecursorUnsupported
    let opened ← psElabOpenCoreTelescope 4096 context pi.domain
      (some (ctor.numFields + ctor.recursiveFields.length))
    let body ← if psNameEq ctorName selected then
      match field with
      | none => pure chosen
      | some index => do
        let some binder := opened.bindersRev.reverse[index]? | throw .matchRecursorUnsupported
        if !(psDefEqReadOnlyWithEnv context.environment context.metaContext
            opened.context.localContext binder.type resultType) then
          throw (.refinement "dependent index-constructor projections are pending")
        pure (.fvar binder.id)
      else pure fallback
    let minor := psCloseElabLambdaBinders context.metaContext opened.bindersRev body
    pure (psExprInstantiate1 pi.body minor, state.snd ++ [minor])) (cursor, [])
  return psLogicLam id "_index" type
    (psExprApplyMany (.constE recName recLevels) (view.args ++ [motive] ++ state.snd ++ [.fvar id]))

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
def psElabSubstituteEquation
    (finish : PsElabContext -> PsExpr -> Except PsElabError PsElabTermResult)
    (context : PsElabContext) (equation : PsElabEquation) (id : Nat)
    (ignored : List Nat) (target : PsExpr) : Except PsElabError PsElabTermResult := do
  let dependents := psElabDependentLocals context [id] ignored
  let telescope := psElabCloseDependentType dependents target
  let substitutions := [(id, equation.left)]
  let specialized := psElabSubstituteLocals substitutions telescope
  let aliases ← psElabMatchAlias { context, valuesRev := [] } (id, equation.left)
  let opened ← psElabOpenDependents dependents {
    context := aliases.context, body := specialized, bindersRev := []
    aliasesRev := aliases.valuesRev, replacements := substitutions }
  let body ← finish opened.context opened.body
  let base := psElabCloseDependents opened body.context.metaContext body.term
  let transported ← psElabEquationRec context equation
    (fun value => psElabSubstituteLocals [(id, value)] telescope) base
  return {
    context := psElabLeaveScope context body.context
    type := target
    term := psExprApplyMany transported (psElabDependentArguments dependents) }

mutual
def psElabSolveIndexConstraints (fuel count : Nat) (flexible ignored : List Nat)
    (finish : PsElabContext -> PsExpr -> Except PsElabError PsElabTermResult)
    (context : PsElabContext) (target : PsExpr) : Except PsElabError PsElabTermResult := do
  match fuel with
  | 0 => throw .fuelExhausted
  | fuel + 1 =>
    match count with
    | 0 => finish context target
    | count + 1 =>
      let pi ← (psInferEnsureForall context.environment context.metaContext context.localContext target).mapError PsElabError.infer
      let pushed := psLocalPushBinding context.localContext pi.name pi.domain pi.binder
      let inner := psElabContextWithLocal context pushed.context
      let equation ← psElabEquationView inner pi.domain (.fvar pushed.id)
      let body ← psElabSolveIndexEquation fuel flexible (pushed.id :: ignored)
        (psElabSolveIndexConstraints fuel count flexible (pushed.id :: ignored) finish)
        inner (psExprInstantiate1 pi.body (.fvar pushed.id)) equation
      return {
        context := psElabLeaveScope context body.context
        type := target
        term := .lam pi.name pi.domain (psExprAbstractFVar pushed.id body.term) pi.binder }

def psElabSolveIndexEquation (fuel : Nat) (flexible ignored : List Nat)
    (finish : PsElabContext -> PsExpr -> Except PsElabError PsElabTermResult)
    (context : PsElabContext) (target : PsExpr) (equation : PsElabEquation) :
    Except PsElabError PsElabTermResult := do
  match fuel with
  | 0 => throw .fuelExhausted
  | fuel + 1 =>
    let reduce := psWhnf context.environment context.metaContext context.localContext
    let left := reduce equation.left
    let right := reduce equation.right
    if psDefEqReadOnlyWithEnv context.environment context.metaContext context.localContext left right then
      return ← finish context target
    -- Prefer eliminating an auxiliary index, then a constructor field. A cyclic
    -- equation is left unsolved; an occurs check is not a contradiction proof.
    match right with
    | .fvar id => if flexible.contains id && !psElabExprContainsLocal id left then
        return ← psElabSubstituteEquation finish context { equation with left, right } id ignored target
    | _ => pure ()
    match left with
    | .fvar id => if flexible.contains id && !psElabExprContainsLocal id right then
        let symmetric ← psElabEquationSymm context { equation with left, right }
        return ← psElabSubstituteEquation finish context symmetric id ignored target
    | _ => pure ()
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
      let body ← psElabSolveIndexConstraints fuel equations.length flexible ignored finish context telescope
      return { body with type := target, term := psExprApplyMany body.term (equations.map (fun entry => entry.proof)) }
    | _, _ => finish context target
end
