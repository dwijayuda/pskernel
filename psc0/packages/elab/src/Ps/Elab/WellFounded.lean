import Ps.Elab.WellFoundedCore
import Ps.Elab.Proof
import Ps.Elab.RecursionParameters
import Ps.Elab.Universe
import Ps.Meta.WellFounded

/-
Selected well-founded recursion, grounded in Lean 4.35.0
eb6cafb7290e8bd5f2937522d8d804f58f02bafc:
  Lean/Elab/PreDefinition/WF/Rel.lean, WF/Fix.lean (replaceRecApps,
  solveDecreasingGoals, mkFix), WF/Unfold.lean, and Init/WF.lean.
The shared typed relation owner retains the qualified Nat specialization
and selects generic WellFounded.fix from an actual checked dictionary.
This module constructs their actual typed application; it introduces no
recursive axiom, opacity marker, fuel bound, or unchecked equation.
-/

-- These sketches are diagnostic only. Bounded descent retains open local/meta
-- identities and universe structure without normalizing or printing string data.
def psElabWellFoundedLevelSketch (fuel : Nat) (level : PsLevel) : String :=
  match fuel with
  | 0 => "..."
  | fuel + 1 =>
    match level with
    | .zero => "0"
    | .succ inner => "succ(" ++ psElabWellFoundedLevelSketch fuel inner ++ ")"
    | .max left right =>
      "max(" ++ psElabWellFoundedLevelSketch fuel left ++ "," ++
        psElabWellFoundedLevelSketch fuel right ++ ")"
    | .imax left right =>
      "imax(" ++ psElabWellFoundedLevelSketch fuel left ++ "," ++
        psElabWellFoundedLevelSketch fuel right ++ ")"
    | .param name => psNameToString name
    | .mvar id => "?u" ++ psNatToString id

def psElabWellFoundedBinderSketch : PsBinderInfo → String
  | .explicit => "explicit"
  | .implicit => "implicit"
  | .strictImplicit => "strictImplicit"
  | .instanceImplicit => "instanceImplicit"

def psElabWellFoundedExprSketch (fuel : Nat) (expression : PsExpr) : String :=
  match fuel with
  | 0 => "..."
  | fuel + 1 =>
    let child := psElabWellFoundedExprSketch fuel
    match expression with
    | .bvar index => "#" ++ psNatToString index
    | .fvar id => "f#" ++ psNatToString id
    | .mvar id => "?m" ++ psNatToString id
    | .sortE level => "Sort(" ++ psElabWellFoundedLevelSketch 4 level ++ ")"
    | .constE name levels =>
      let universes := (levels.take 4).map (psElabWellFoundedLevelSketch 4)
      psNameToString name ++ ".{" ++ String.intercalate "," universes ++
        (if levels.length > 4 then ",..." else "") ++ "}"
    | .app function argument => "(" ++ child function ++ " " ++ child argument ++ ")"
    | .lam name type body binder =>
      "(lam " ++ psElabWellFoundedBinderSketch binder ++ " " ++ psNameToString name ++
        " : " ++ child type ++ " => " ++ child body ++ ")"
    | .forallE name type body binder =>
      "(forall " ++ psElabWellFoundedBinderSketch binder ++ " " ++ psNameToString name ++
        " : " ++ child type ++ ", " ++ child body ++ ")"
    | .letE name type value body =>
      "(let " ++ psNameToString name ++ " : " ++ child type ++ " := " ++
        child value ++ "; " ++ child body ++ ")"
    | .lit (.natural value) => psNatToString value
    | .lit (.string _) => "<string>"
    | .proj name index value =>
      "(proj " ++ psNameToString name ++ "." ++ psNatToString index ++ " " ++ child value ++ ")"

def psElabWellFoundedAt {α : Type} (label : String)
    (result : Except PsElabError α) : Except PsElabError α :=
  result.mapError (fun error => .atContext ("well-founded " ++ label) error)

-- The original check and successful result are unchanged. Only after failure
-- do we infer the same term once more to describe its actual type; that result
-- is never used to accept a term or to replace the original error.
def psElabWellFoundedChecked (label : String) (context : PsElabContext)
    (term expected : PsExpr) : Except PsElabError PsElabTermResult :=
  match psElabResolvedTerm context term (some expected) with
  | .ok result => .ok result
  | .error error =>
    let actual := match psInferType context.environment context.metaContext context.localContext term with
      | .ok type => psElabWellFoundedExprSketch 7 type
      | .error _ => "<inference failed>"
    .error (.atContext
      ("well-founded " ++ label ++ "; actual=" ++ actual ++
        "; expected=" ++ psElabWellFoundedExprSketch 7 expected) error)

def psElabWellFoundedIsNat (context : PsElabContext) (type : PsExpr) : Bool :=
  psDefEqReadOnlyWithEnv context.environment context.metaContext
    context.localContext type (.constE psNatName [])

def psElabWellFoundedRecursionForName
    (context : PsElabContext) (sourceName : PsSyntaxName) :
    Option PsElabWellFoundedRecursion := do
  let name ← psSyntaxNameToName sourceName
  if (psLocalFindUser context.localContext name).isSome then none else
    context.wellFoundedRecursions.find? (fun recursion =>
      psNameEq name recursion.functionName)

def psElabWellFoundedReferenceEscapes
    (context : PsElabContext) (sourceName : PsSyntaxName) : Bool :=
  (psElabWellFoundedRecursionForName context sourceName).isSome

-- Read the current callback telescope after dependent match refinement. In
-- particular, a successor branch must get measure(y) < measure(succ k), not
-- the stale outer major's type. The matcher already owns that generalization.
def psTryElabWellFoundedCall (elaborate : PsElaborator)
    (context : PsElabContext) (fn : PsSyntaxTerm)
    (arguments : List (Option PsSyntaxName × PsSyntaxTerm))
    (expected : Option PsExpr) : Except PsElabError (Option PsElabTermResult) := do
  let .reference sourceName := fn | return none
  let some recursion := psElabWellFoundedRecursionForName context sourceName | return none
  let some completeType := recursion.sourceType
    | throw (.data "PSCV0-WF-INTERNAL: missing recursive source telescope")
  let (scope, sourceType, captures) ← recursion.capturedNames.foldlM
    (fun (state : PsElabContext × PsExpr × List PsExpr) name => do
      let (current, type, values) := state
      let some binding := psLocalFindUser current.localContext name
        | throw (.data "PSCV0-WF-CAPTURE: a source capture lost its refined lexical binding")
      let parameter ← (psInferEnsureForall current.environment current.metaContext
        current.localContext type).mapError PsElabError.infer
      let value ← psElabResolvedTerm current (.fvar (psLocalDeclId binding)) (some parameter.domain)
      return (value.context, psExprInstantiate1 parameter.body value.term, values ++ [value.term]))
    (context, completeType, [])
  if captures.length > recursion.parameterIds.length then
    throw (.data "PSCV0-WF-CAPTURE: captures exceed the original header")
  let captured ← psElabRecursionCaptureArguments elaborate scope arguments sourceType
    (recursion.parameterIds.length - captures.length) expected
  let values := captures ++ captured.values
  let some callback := psLocalFindUser captured.context.localContext recursion.callbackName
    | throw (.data "PSCV0-WF-INTERNAL: missing refined recursive callback")
  let span := context.sourceSpan.getD (psSyntaxTermSpan fn)
  let call : PsElabRecursionCall := {
    localContext := captured.context.localContext
    arguments := values
    callee := recursion.functionName
    span := span }
  let current := { captured.context with
    wellFoundedCallsRev := call :: captured.context.wellFoundedCallsRev }
  let (next, term) ← if recursion.collectCalls then
      pure (current, psExprApplyMany (.fvar (psLocalDeclId callback)) values)
    else do
      let recursiveIds := if recursion.packedIds.isEmpty then
        [recursion.majorId] else recursion.packedIds
      let recursiveArguments ← recursiveIds.mapM fun id =>
        match psElabRecursionParameterArgument recursion.parameterIds values id with
        | some value => pure value
        | none => throw (.data "PSCV0-WF-INTERNAL: missing measured recursive argument")
      let afterArguments ← recursiveArguments.foldlM (fun type value => do
        let parameter ← (psInferEnsureForall current.environment current.metaContext
          current.localContext type).mapError PsElabError.infer
        return psExprInstantiate1 parameter.body value) (psLocalDeclType callback)
      let proof ← (psInferEnsureForall current.environment current.metaContext
        current.localContext afterArguments).mapError PsElabError.infer
      let states ← recursion.stateIds.mapM fun id =>
        match psElabRecursionParameterArgument recursion.parameterIds values id with
        | some value => pure value
        | none => throw (.data "PSCV0-WF-INTERNAL: missing recursive state argument")
      let fresh := psMetaFresh current.metaContext current.localContext
        proof.domain .syntheticOpaque { tag := "decrease" }
      let .mvar goal := fresh.expr
        | throw (.data "PSCV0-WF-INTERNAL: invalid decrease goal")
      let next := { current with
        metaContext := fresh.context
        wellFoundedGoalsRev := (goal, span) :: current.wellFoundedGoalsRev }
      pure (next, psExprApplyMany (.fvar (psLocalDeclId callback))
        (recursiveArguments ++ [fresh.expr] ++ states))
  let resolved ← psElabResolvedTerm next term (some captured.resultType)
  let resultType := psMetaInstantiate resolved.context.metaContext resolved.type
  -- Independent result types already belong to the caller's scope. Delaying
  -- them on unresolved dictionaries in argument let values would hide a real
  -- function result behind an opaque type meta before a chained application.
  -- Value closure still retains every actual argument let in the shared application order.
  let closedType ← if !psExprHasTermMeta resultType &&
      psExprFVarsInContext context.localContext resultType then
    psElabResolvedTerm (psElabLeaveScope context resolved.context) resultType none
  else psElabAbstractType context resolved.context captured.abstractions resultType
  let inner := psElabContextWithMeta resolved.context closedType.context.metaContext
  let closed ← psElabAbstract context inner captured.abstractions resolved.term closedType.term
  let closed ← if recursion.collectCalls then do
    let opened ← psElabCoreBoundaryOpen closed.context
      (.recursiveCall captured.abstractions.length values.length) closed.term closed.type
    let retained ← psElabResolvedTerm opened.context (.fvar opened.id) (some opened.type)
    psElabCoreBoundaryClose opened retained (some closed.type)
    else pure closed
  if captured.remainingPositions.isEmpty && captured.remainingNames.isEmpty then
    return some (← psElabFinalizeExpected closed expected)
  -- Pinned WF/Fix.replaceRecApps applies residual arguments AFTER the checked
  -- recursive call and its decrease proof. Resume the shared ordinary engine
  -- outside the captured header scope, exactly like chained source calls.
  let application ← psElabApplyOrdered elaborate 4096 closed
    captured.remainingPositions captured.remainingNames [] true expected
  return some (← psElabFinishApplication application expected)

-- Defaults prove only the existing checked natural-order rules. There is no
-- Boolean termination oracle and no implicit omega or arithmetic fallback.
def psElabWellFoundedDefaultGoals (state : PsProofState) :
    Except PsElabError PsProofState := do
  let mut current ← psProofNormalize state
  for goal in state.goals do
    if (psMetaFindAssignment current.context.metaContext goal.id).isSome then continue
    let selected := { current with goals := [goal] }
    let solved ← match psProofAssumption selected with
      | .ok next => pure next
      | .error _ => match psProofNaturalBounds selected with
        | .ok next => pure next
        | .error _ =>
          throw (.data "PSCV0-WF-DECREASE: default natural-order rules could not prove a call decreases; supply decreasing_by by { ... }")
    if !solved.goals.isEmpty then
      throw (.data "PSCV0-WF-DECREASE: default proof left an unsolved decrease goal")
    current := { solved with goals := current.goals }
  psProofNormalize current

def psElabWellFoundedSolveGoals (elaborate : PsElaborator)
    (context : PsElabContext) (decreasing : Option PsSyntaxTerm) :
    Except PsElabError PsElabContext := do
  let calls := context.wellFoundedGoalsRev.reverse
  if calls.isEmpty then
    throw (.data "PSCV0-WF-NOT-RECURSIVE: termination_by was supplied for a nonrecursive declaration")
  let goals := calls.map fun entry => ({ id := entry.fst, tag := "decrease" } : PsProofGoal)
  -- A proof may use facts from a call's captured branch context, but cannot
  -- create new source recursive calls while proving those calls decrease.
  let state : PsProofState := {
    context := { context with wellFoundedRecursions := [] }
    goals }
  let solved ← match decreasing with
    | none => psElabWellFoundedDefaultGoals state
    | some (.byE tactics scope _) => psProofRun elaborate scope 4096 state tactics
    | some _ =>
      throw (.data "PSCV0-WF-PROOF: decreasing_by requires the selected by { tactic sequence } body")
  let solved ← psProofNormalize solved
  if !solved.goals.isEmpty then
    throw (.data "PSCV0-WF-DECREASE: decreasing_by left unsolved call goals")
  for (id, _) in calls do
    if psExprHasUnresolvedMeta (psMetaInstantiate solved.context.metaContext (.mvar id)) then
      throw (.data "PSCV0-WF-DECREASE: unresolved decrease proof or scope closure")
  return solved.context

structure PsElabWellFoundedResult where
  declaration : PsDeclaration
  equation : PsDeclaration
  metaContext : PsMetaContext
  sourceInfo : PsElabSourceInfo

-- Source preparation supplies a real checked header, keeping lifted captures
-- separate from the original recursion arguments. A body scope may
-- add checked local aliases for already constructed predecessors. Those lets
-- are eliminated before the final fixedpoint is closed and checked.
structure PsElabWellFoundedTypedHeader where
  context : PsElabContext
  parametersRev : List PsElabTypedBinder
  resultType : PsExpr
  functionName : PsName
  capturesRev : List PsElabTypedBinder := []
  bodyLocalContext : Option PsLocalContext := none
  preserveLevels : Bool := false

def psElabWellFoundedHeaderScope (header : PsElabWellFoundedTypedHeader) :
    Except PsElabError (PsElabContext × PsLocalContext × List (Nat × PsExpr)) := do
  let parameters := header.parametersRev ++ header.capturesRev
  let ids := parameters.map (·.id)
  let context := header.context
  if ids.eraseDups.length != ids.length ||
      context.localContext.declarations.length != ids.length then
    throw (.data "PSCV0-WF-HEADER: the typed header must contain exactly its distinct original parameter and capture bindings")
  for parameter in parameters do
    let some (.binding _ name type binder) := psLocalFindById context.localContext parameter.id
      | throw (.data "PSCV0-WF-HEADER: a typed header slot is not a real local binding")
    if !psNameEq name parameter.name || !psBinderInfoEq binder parameter.binder ||
        !psDefEqReadOnlyWithEnv context.environment context.metaContext context.localContext type parameter.type then
      throw (.data "PSCV0-WF-HEADER: a retained header slot changed its actual name, type or binder kind")
  let body := header.bodyLocalContext.getD context.localContext
  let bodyIds := body.declarations.map psLocalDeclId
  if bodyIds.eraseDups.length != bodyIds.length || !ids.all bodyIds.contains then
    throw (.data "PSCV0-WF-HEADER: the source body scope lost or duplicated a header slot")
  let captures := header.capturesRev.map (·.id)
  let aliases ← body.declarations.foldlM (fun (aliases : List (Nat × PsExpr)) declaration => do
    match declaration with
    | .binding id name type binder =>
      let some parameter := parameters.find? (fun parameter => parameter.id == id)
        | throw (.data "PSCV0-WF-HEADER: the source body scope introduced an unowned binding")
      if (!captures.contains id && !psNameEq name parameter.name) ||
          !psBinderInfoEq binder parameter.binder ||
          !psDefEqReadOnlyWithEnv context.environment context.metaContext context.localContext type parameter.type then
        throw (.data "PSCV0-WF-HEADER: the source body scope changed a typed header slot")
      return aliases
    | .letDecl id _ type value =>
      if ids.contains id || !psExprFVarsInContext context.localContext type ||
          !psExprFVarsInContext context.localContext value then
        throw (.data "PSCV0-WF-HEADER: a predecessor alias is not an application of checked globals in the original header")
      let _ ← psElabResolvedTerm context value (some type)
      return aliases ++ [(id, value)]) []
  let nextId := max context.localContext.nextId body.nextId
  if bodyIds.any (fun id => id >= nextId) then
    throw (.data "PSCV0-WF-HEADER: the source body scope reused an active local identity")
  return ({ context with localContext := { context.localContext with nextId } },
    { body with nextId }, aliases)

def psElabWellFoundedLambdas (binders : List PsElabTypedBinder) (body : PsExpr) : PsExpr :=
  binders.foldr (fun binder body =>
    .lam binder.name binder.type (psExprAbstractFVar binder.id body) binder.binder) body

def psElabWellFoundedForalls (binders : List PsElabTypedBinder) (body : PsExpr) : PsExpr :=
  binders.foldr (fun binder body =>
    .forallE binder.name binder.type (psExprAbstractFVar binder.id body) binder.binder) body

-- The owned list fixes the arity of right-associated dependent packing.
-- The final source slot remains intact even when its type is itself PSigma.
inductive PsElabWellFoundedArgument where
  | unary (major : PsElabTypedBinder)
  | dependentTuple (parameters : List PsElabTypedBinder) (domain : PsExpr)

def psElabWellFoundedArgumentDomain : PsElabWellFoundedArgument → PsExpr
  | .unary major => major.type
  | .dependentTuple _ domain => domain

def psElabWellFoundedArgumentAt (argument : PsElabWellFoundedArgument)
    (value term : PsExpr) : PsExpr :=
  match argument with
  | .unary major => psExprInstantiate1 (psExprAbstractFVar major.id term) value
  | .dependentTuple parameters _ =>
    psElabSubstituteLocals ((parameters.map (·.id)).zip
      (psWellFoundedTupleProjections parameters.length value)) term

def psElabWellFoundedArgumentLambda (argument : PsElabWellFoundedArgument)
    (freshId : Nat) (body : PsExpr) : PsExpr :=
  match argument with
  | .unary major =>
    .lam major.name major.type (psExprAbstractFVar major.id body) .explicit
  | .dependentTuple _ domain =>
    .lam (psRootName "_psc0Packed") domain
      (psExprAbstractFVar freshId (psElabWellFoundedArgumentAt argument (.fvar freshId) body)) .explicit

def psElabWellFoundedArgumentCurrent (argument : PsElabWellFoundedArgument) :
    Except PsElabError PsExpr := do
  match argument with
  | .unary major => return .fvar major.id
  | .dependentTuple parameters domain =>
    (psWellFoundedTuplePack domain
      (parameters.map fun parameter => .fvar parameter.id)).mapError PsElabError.infer

def psElabWellFoundedArgumentMap (normalize : PsExpr → PsExpr) :
    PsElabWellFoundedArgument → PsElabWellFoundedArgument
  | .unary major => .unary { major with type := normalize major.type }
  | .dependentTuple parameters domain =>
    .dependentTuple (parameters.map fun parameter =>
      { parameter with type := normalize parameter.type }) (normalize domain)

-- Dependent source matches generalize the curried callback in its actual
-- parameter types. Construction and erasure share its exact checked adapter.
def psElabWellFoundedSourceCallbackType (context : PsElabContext)
    (argument : PsElabWellFoundedArgument) (callbackType : PsExpr) :
    Except PsElabError PsExpr := do
  match argument with
  | .unary _ => return callbackType
  | .dependentTuple parameters _ =>
    (psWellFoundedTupleCurryType context.environment context.metaContext
      context.localContext (parameters.map (·.name)) callbackType).mapError PsElabError.infer

-- Keep the body under its original dependent binders. The checked eliminator
-- moves that body beneath the unary domain; no free-variable cast or sigma
-- eta rule is used. This follows ArgsPacker.Unary.uncurry.
def psElabWellFoundedFunctional (context : PsElabContext)
    (argument : PsElabWellFoundedArgument) (callbackId : Nat)
    (callbackName : PsName) (sourceCallbackType callbackType motive body : PsExpr) :
    Except PsElabError PsExpr := do
  match argument with
  | .unary major =>
    let inner := PsExpr.lam callbackName callbackType
      (psExprAbstractFVar callbackId body) .explicit
    return .lam major.name major.type (psExprAbstractFVar major.id inner) .explicit
  | .dependentTuple parameters domain =>
    let rawName := psRootName "_psc0PackedCallback"
    let raw := psLocalPushBinding context.localContext rawName callbackType .explicit
    let curried ← (psWellFoundedTupleCurryCallback context.environment context.metaContext
      raw.context (parameters.map (·.name)) sourceCallbackType (.fvar raw.id)).mapError PsElabError.infer
    -- Keep the typed source callback as a local value. Nested recursor
    -- closure conversion must capture this curried ABI, not the raw packed
    -- callback inside its adapter. The let remains definitionally equal to
    -- substitution, and executable preparation consumes its exact adapter.
    let body := PsExpr.letE callbackName sourceCallbackType curried
      (psExprAbstractFVar callbackId body)
    let inner := PsExpr.lam rawName callbackType
      (psExprAbstractFVar raw.id body) .explicit
    let packedName := psRootName "_psc0Packed"
    let packed := psLocalPushBinding context.localContext packedName domain .explicit
    let value := PsExpr.fvar packed.id
    let resultType := PsExpr.forallE callbackName
      (psElabWellFoundedArgumentAt argument value callbackType) (.app motive value) .explicit
    let level ← psElabExpressionSort { context with localContext := packed.context } resultType
    let minor := psElabWellFoundedLambdas
      (parameters.map fun parameter => { parameter with binder := .explicit }) inner
    let cases ← (psWellFoundedTupleCases context.environment context.metaContext
      packed.context (parameters.map (·.name)) packed.id level resultType minor).mapError PsElabError.infer
    return .lam packedName domain (psExprAbstractFVar packed.id cases) .explicit

-- This explicit proof is needed because portable conversion does not add
-- function eta. The leaf compares fully applied terms by checked conversion;
-- every function layer is justified by the Standard's actual funext theorem.
def psElabWellFoundedExtensionalEquality (count : Nat) (context : PsElabContext)
    (type left right : PsExpr) : Except PsElabError PsExpr := do
  match count with
  | 0 =>
    let level ← psElabExpressionSort context type
    let proof := psLogicRefl level type left
    let checked ← psElabWellFoundedChecked "callback extensionality leaf" context proof
      (psLogicEq level type left right)
    return checked.term
  | count + 1 =>
    let pi ← (psInferEnsureForall context.environment context.metaContext
      context.localContext type).mapError PsElabError.infer
    let pushed := psLocalPushBinding context.localContext pi.name pi.domain pi.binder
    let inner := { context with localContext := pushed.context }
    let argument := PsExpr.fvar pushed.id
    let resultType := psExprInstantiate1 pi.body argument
    let proof ← psElabWellFoundedExtensionalEquality count inner resultType
      (.app left argument) (.app right argument)
    let domainLevel ← psElabExpressionSort context pi.domain
    let resultLevel ← psElabExpressionSort inner resultType
    let motive := PsExpr.lam pi.name pi.domain
      (psExprAbstractFVar pushed.id resultType) pi.binder
    let pointwise := PsExpr.lam pi.name pi.domain
      (psExprAbstractFVar pushed.id proof) pi.binder
    return psExprApplyMany (.constE (psRootName "funext") [domainLevel, resultLevel])
      [pi.domain, motive, left, right, pointwise]

def psElabWellFoundedCongrArg (context : PsElabContext)
    (domain range left right function proof : PsExpr) : Except PsElabError PsExpr := do
  let domainLevel ← psElabExpressionSort context domain
  let rangeLevel ← psElabExpressionSort context range
  return psExprApplyMany (.constE (psRootName "congrArg") [domainLevel, rangeLevel])
    [domain, range, left, right, function, proof]


-- Pair eta is intentionally not a conversion rule. Eliminate every owned
-- PSigma layer, then prove equality of the proof/state functions with funext.
def psElabWellFoundedTupleCallbackEquality (context : PsElabContext)
    (names : List PsName) (type left right : PsExpr)
    (stateCount : Nat := 0) : Except PsElabError PsExpr := do
  let parameter ← (psInferEnsureForall context.environment context.metaContext
    context.localContext type).mapError PsElabError.infer
  let packed := psLocalPushBinding context.localContext parameter.name parameter.domain parameter.binder
  let inner := { context with localContext := packed.context }
  let value := PsExpr.fvar packed.id
  let resultType := psExprInstantiate1 parameter.body value
  let resultLevel ← psElabExpressionSort inner resultType
  let equality := psLogicEq resultLevel resultType (.app left value) (.app right value)
  let (pointLocals, binders) ← (psWellFoundedTupleOpen context.localContext
    parameter.domain names).mapError PsElabError.infer
  let constructed ← (psWellFoundedTuplePack parameter.domain
    (binders.map fun binder => .fvar binder.id)).mapError PsElabError.infer
  let pointType := psExprInstantiate1 parameter.body constructed
  let point ← psElabWellFoundedExtensionalEquality (1 + stateCount)
    { context with localContext := pointLocals }
    pointType (.app left constructed) (.app right constructed)
  let minor := psWellFoundedTupleLambdas binders point
  let cases ← (psWellFoundedTupleCases context.environment context.metaContext
    packed.context names packed.id .zero equality minor).mapError PsElabError.infer
  let pointwise := PsExpr.lam parameter.name parameter.domain
    (psExprAbstractFVar packed.id cases) parameter.binder
  let motive := PsExpr.lam parameter.name parameter.domain
    (psExprAbstractFVar packed.id resultType) parameter.binder
  let domainLevel ← psElabExpressionSort context parameter.domain
  let proof := psExprApplyMany (.constE (psRootName "funext") [domainLevel, resultLevel])
    [parameter.domain, motive, left, right, pointwise]
  let typeLevel ← psElabExpressionSort context type
  let checked ← psElabWellFoundedChecked "tuple callback equality" context proof
    (psLogicEq typeLevel type left right)
  return checked.term

-- Typed header parameters may be fixed or evolve independently of
-- the typed measure. Its codomain and the measured argument's domain depend
-- only on fixed captures; changing state and the result form a dependent motive.
-- No body lambda enters the header or the termination clause's lexical scope.
def psElabWellFoundedTypedPartsCore (elaborate : PsElaborator)
    (name : PsName) (header : PsElabWellFoundedTypedHeader)
    (valueSyntax : PsSyntaxTerm) (termination : PsSyntaxTermination) :
    Except PsElabError PsElabWellFoundedResult := do
  let (headerContext, bodyLocalContext, aliases) ← psElabWellFoundedHeaderScope header
  let environment := headerContext.environment
  let levelNames := headerContext.levelNames
  let equationName := psNameAppendStr name "eq_def"
  if (psEnvironmentFind environment name).isSome then
    throw (.duplicateDeclaration name)
  if (psEnvironmentFind environment equationName).isSome then
    throw (.duplicateDeclaration equationName)
  let parameters := header.parametersRev.reverse
  let captures := header.capturesRev.reverse
  let captureIds := captures.map (·.id)
  if parameters.isEmpty then
    throw (.data "PSCV0-WF-TELESCOPE: the selected slice requires typed header parameters")
  let _ ← psElabExpressionSort headerContext header.resultType
  -- As in TerminationMeasure.elab, infer the real codomain; the self callback
  -- is not in scope in the result annotation or measure.
  let measured ← psElabWellFoundedAt "measure"
    (elaborate headerContext termination.measure none)
  let measureBody := psMetaInstantiate measured.context.metaContext measured.term
  let measureType := psMetaInstantiate measured.context.metaContext measured.type
  if [measureBody, measureType].any (fun term =>
      psExprHasUnresolvedMeta (psElabGeneralizeExpr term)) then
    throw (.data "PSCV0-WF-MEASURE: unresolved termination measure or codomain")
  let parameterIds := parameters.map (·.id)
  if !(psExprFVarIds measureBody ++ psExprFVarIds measureType).all (parameterIds ++ captureIds).contains then
    throw (.data "PSCV0-WF-MEASURE: the measure escaped its declared header scope")
  let declaredParameters := parameters.map fun parameter =>
    { parameter with type := psMetaInstantiate measured.context.metaContext parameter.type }
  let declaredResult := psMetaInstantiate measured.context.metaContext header.resultType
  let declaredType := psElabWellFoundedForalls declaredParameters declaredResult
  if psExprHasUnresolvedMeta (psElabGeneralizeExpr declaredType) then
    throw (.data "PSCV0-WF-TELESCOPE: the complete declared parameter and result types must be resolved")
  -- Probe with a hygienic local function, not a temporary declaration/axiom.
  -- The probe owns no final proof goals, source information, or body value.
  let bodyHeader := { measured.context with
    localContext := { bodyLocalContext with
      nextId := max bodyLocalContext.nextId measured.context.localContext.nextId } }
  let probeName := psNameAppendNum (psRootName "_psc0WellFoundedProbe")
    bodyHeader.localContext.nextId
  let probe := psLocalPushBinding bodyHeader.localContext probeName declaredType .explicit
  let probeContext := { bodyHeader with
    localContext := probe.context
    auxiliaryLocalIds := probe.id :: bodyHeader.auxiliaryLocalIds
    structuralRecursion := none
    wellFoundedRecursions := [{
      functionName := header.functionName, callbackName := probeName
      parameterIds := parameterIds, collectCalls := true, sourceType := some declaredType }]
    wellFoundedGoalsRev := []
    wellFoundedCallsRev := [] }
  let probed ← psElabWellFoundedAt "probe body"
    (elaborate probeContext valueSyntax (some declaredResult))
  if psExprHasUnresolvedMeta (psElabGeneralizeExpr
      (psMetaInstantiate probed.context.metaContext probed.term)) then
    throw (.data "PSCV0-WF-PARAMETERS: unresolved provisional body while checking fixed arguments")
  let plan ← psElabRecursionMeasureParameterPlan probed.context header.functionName parameterIds
    probed.context.wellFoundedCallsRev.reverse measureBody
  let some major := declaredParameters.find? (fun parameter => parameter.id == plan.majorId)
    | throw (.data "PSCV0-WF-INTERNAL: selected parameter is not in the header")
  let fixedIds := captureIds ++ plan.fixedIds
  let argument ← if plan.packedIds.isEmpty then
      pure (PsElabWellFoundedArgument.unary major)
    else do
      let packed ← plan.packedIds.mapM fun id =>
        match declaredParameters.find? (fun parameter => parameter.id == id) with
        | some parameter => pure parameter
        | none => throw (.data "PSCV0-WF-INTERNAL: packed parameter is not in the owned header")
      let domain ← psElabWellFoundedAt "packed domain"
        ((psWellFoundedTupleTypeChecked environment measured.context.metaContext
          measured.context.localContext (packed.map fun parameter => .fvar parameter.id)).mapError
            PsElabError.infer)
      pure (PsElabWellFoundedArgument.dependentTuple packed domain)
  let domain := psElabWellFoundedArgumentDomain argument
  if !(psExprFVarIds domain).all fixedIds.contains then
    throw (.data "PSCV0-WF-MAJOR-DOMAIN: the measured argument's domain depends on changing state outside the selected dependent telescope")
  -- Rel.checkCodomains requires the measure's type to be independent of the
  -- varying arguments, including every slot of the selected dependent telescope.
  if !(psExprFVarIds measureType).all fixedIds.contains then
    throw (.data "PSCV0-WF-MEASURE-TYPE: the measure codomain depends on changing arguments; dependent measure packing is unavailable")
  let states := declaredParameters.filter fun parameter => plan.stateIds.contains parameter.id
  let stateType := psElabWellFoundedForalls states declaredResult
  let measure := psElabWellFoundedArgumentLambda argument bodyHeader.localContext.nextId measureBody
  let measureLevel ← psElabExpressionSort measured.context measureType
  let dictionary ← psElabSynthesizeInstance measured.context
    (.app (.constE psWellFoundedRelationName [measureLevel]) measureType)
  let dictionaryValue := psMetaInstantiate dictionary.context.metaContext dictionary.term
  if psExprHasUnresolvedMeta (psElabGeneralizeExpr dictionaryValue) ||
      !(psExprFVarIds dictionaryValue).all fixedIds.contains then
    throw (.data "PSCV0-WF-RELATION: the selected relation dictionary is unresolved or captures changing state")
  let relationPlan ← psElabWellFoundedAt "measure inverse image"
    ((psWellFoundedPlanForMeasure environment dictionary.context.metaContext
      dictionary.context.localContext domain measureType measure dictionaryValue).mapError PsElabError.infer)
  let fixName := psWellFoundedConstructionFixName relationPlan.construction
  let equationConstant := psWellFoundedConstructionEquationName relationPlan.construction
  let some (.definitionDecl ..) := psEnvironmentFind environment fixName
    | throw (.data ("PSCV0-WF-FOUNDATION: checked " ++ psNameToString fixName ++ " is unavailable"))
  let some (.theoremDecl ..) := psEnvironmentFind environment equationConstant
    | throw (.data ("PSCV0-WF-FOUNDATION: checked " ++ psNameToString equationConstant ++ " is unavailable"))
  let bodyHeader := { dictionary.context with
    localContext := { bodyHeader.localContext with
      nextId := max bodyHeader.localContext.nextId dictionary.context.localContext.nextId } }
  let localId := bodyHeader.localContext.nextId
  let callbackName := psNameAppendNum (psRootName "_psc0WellFounded") localId
  let currentMajor ← psElabWellFoundedAt "packed entry"
    (psElabWellFoundedArgumentCurrent argument)
  let relation := psWellFoundedDecreases relationPlan (.fvar localId) currentMajor
  let smallerStateType := psElabWellFoundedArgumentAt argument (.fvar localId) stateType
  let callbackType := psLogicPi localId "_smaller" domain
    (psLogicPi (localId + 1) "_decreases" relation smallerStateType)
  let _ ← psElabWellFoundedAt "raw callback type"
    (psElabExpressionSort bodyHeader callbackType)
  let sourceCallbackType ← psElabWellFoundedAt "source callback type"
    (psElabWellFoundedSourceCallbackType bodyHeader argument callbackType)
  let callback := psLocalPushBinding bodyHeader.localContext callbackName sourceCallbackType .explicit
  let sourceName := psNameAppendNum (psRootName "_psc0WellFoundedSource") callback.context.nextId
  let source := psLocalPushBinding callback.context sourceName declaredType .explicit
  let recursion : PsElabWellFoundedRecursion := {
    functionName := header.functionName, callbackName
    parameterIds, majorId := plan.majorId, packedIds := plan.packedIds
    stateIds := plan.stateIds, fixedIds := plan.fixedIds, sourceType := some declaredType }
  let bodyContext := { bodyHeader with
    localContext := source.context
    auxiliaryLocalIds := source.id :: callback.id :: bodyHeader.auxiliaryLocalIds
    structuralRecursion := none
    wellFoundedRecursions := [{ recursion with callbackName := sourceName, collectCalls := true }]
    wellFoundedGoalsRev := [], wellFoundedCallsRev := [] }
  let value ← psElabWellFoundedAt "source body"
    (elaborate bodyContext valueSyntax (some declaredResult))
  psElabRecursionValidateFixedParameters value.context plan value.context.wellFoundedCallsRev
  let value ← psElabWellFoundedAt "compiled recursive calls"
    (psElabWellFoundedCoreCalls value.context [{
      sourceId := source.id, callback := .fvar callback.id, recursion
      fixedArguments := plan.fixedIds.map (fun id => (id, PsExpr.fvar id))
      span := psSyntaxTermSpan valueSyntax }] value.term declaredResult)
  let solved ← psElabWellFoundedAt "decrease goals"
    (psElabWellFoundedSolveGoals elaborate value.context termination.decreasing)
  -- Generalize only at this actual declaration boundary, as ordinary checked
  -- declarations do. All terms and the equation's local telescope use the same
  -- instantiated levels; unresolved term/proof holes remain an error.
  let normalize := fun (expression : PsExpr) =>
    psElabGeneralizeExpr (psMetaInstantiate solved.metaContext expression)
  let normalizedAliases := aliases.map fun (id, value) => (id, normalize value)
  let body := psElabSubstituteLocals normalizedAliases (normalize value.term)
  if psExprHasUnresolvedMeta body then
    throw (.data "PSCV0-WF-DECREASE: unresolved body or delayed proof abstraction")
  let declaredParameters := declaredParameters.map fun parameter =>
    { parameter with type := normalize parameter.type }
  let captures := captures.map fun parameter =>
    { parameter with type := normalize parameter.type }
  let fullParameters := captures ++ declaredParameters
  let declaredResult := normalize declaredResult
  let declaredType := psElabWellFoundedForalls fullParameters declaredResult
  let argument := psElabWellFoundedArgumentMap normalize argument
  let domain := psElabWellFoundedArgumentDomain argument
  let currentMajor := normalize currentMajor
  let states := states.map fun parameter => { parameter with type := normalize parameter.type }
  let stateType := psElabWellFoundedForalls states declaredResult
  let callbackType := normalize callbackType
  let sourceCallbackType := normalize sourceCallbackType
  let relationPlan := psWellFoundedPlanMap normalize relationPlan
  let localDeclarations := dictionary.context.localContext.declarations.map fun declaration =>
    match declaration with
    | .binding id name type binder => .binding id name (normalize type) binder
    | .letDecl id name type value => .letDecl id name (normalize type) (normalize value)
  let localContext := { dictionary.context.localContext with
    declarations := localDeclarations
    nextId := max dictionary.context.localContext.nextId solved.localContext.nextId }
  let normalizedContext := { dictionary.context with
    localContext := localContext
    metaContext := psMetaEmpty }
  let stateBody := psElabWellFoundedLambdas states body
  let motive := psElabWellFoundedArgumentLambda argument normalizedContext.localContext.nextId stateType
  let functional ← psElabWellFoundedAt "functional"
    (psElabWellFoundedFunctional normalizedContext argument
      callback.id callbackName sourceCallbackType callbackType motive stateBody)
  if (psWellFoundedPlanTerms relationPlan ++ [motive, functional]).any (fun term =>
      !(psExprFVarIds term).all fixedIds.contains) then
    throw (.data "PSCV0-WF-SCOPE: the fixedpoint captured a changing parameter")
  if (psWellFoundedPlanTerms relationPlan ++ [declaredType, motive, functional]).any psExprHasUnresolvedMeta then
    throw (.data "PSCV0-WF-TELESCOPE: unresolved fixedpoint type or universe")
  let domainLevel ← psElabExpressionSort normalizedContext domain
  let stateLevel ← psElabExpressionSort normalizedContext stateType
  let resultLevel ← psElabExpressionSort normalizedContext declaredResult
  let fixed := PsExpr.app (psWellFoundedFixBase relationPlan [domainLevel, stateLevel] motive) functional
  let stateArguments := states.map (fun parameter => PsExpr.fvar parameter.id)
  let declaredValue := psElabWellFoundedLambdas fullParameters
    (psExprApplyMany fixed ([currentMajor] ++ stateArguments))
  if !(psExprFVarIds declaredType).isEmpty || !(psExprFVarIds declaredValue).isEmpty then
    throw (.data "PSCV0-WF-SCOPE: declaration retained an out-of-scope local")
  let usedLevels := psElabDeclarationLevels levelNames [declaredType, declaredValue]
  if header.preserveLevels && !usedLevels.all (fun used => levelNames.any (psNameEq used)) then
    throw (.data "PSCV0-WF-LEVELS: the checked measure or body introduced a universe outside its original source block")
  let levels := if header.preserveLevels then levelNames else usedLevels
  let closedContext := psElabContextEmpty environment levels
  let _ ← psElabWellFoundedChecked "closed declaration" closedContext declaredValue declaredType
  let declaration := PsDeclaration.definitionDecl name levels declaredType declaredValue
  let some withDefinition := psEnvironmentAdd environment declaration
    | throw (.duplicateDeclaration name)
  -- The callback calls the actual public f in original header order. Its
  -- dependent state domains are specialized to the smaller major before any
  -- state binder is opened. Explicit extensionality justifies state lambdas.
  let x := currentMajor
  let yId := normalizedContext.localContext.nextId
  let y := PsExpr.fvar yId
  let decrease := psWellFoundedDecreases relationPlan y x
  let self := PsExpr.constE name (levels.map PsLevel.param)
  let originalArguments := fullParameters.map (fun parameter => PsExpr.fvar parameter.id)
  let recursiveArguments := fullParameters.map fun parameter =>
    psElabWellFoundedArgumentAt argument y (.fvar parameter.id)
  let smallerStates := states.map fun parameter =>
    { parameter with type := psElabWellFoundedArgumentAt argument y parameter.type }
  let unfoldCallback := psLogicLam yId "_smaller" domain
    (psLogicLam (yId + 1) "_decreases" decrease
      (psElabWellFoundedLambdas smallerStates (psExprApplyMany self recursiveArguments)))
  let rawCallback := psLogicLam yId "_smaller" domain
    (psLogicLam (yId + 1) "_decreases" decrease (.app fixed y))
  let rawRhs := psExprApplyMany functional [x, rawCallback]
  let sourceRhs := psExprApplyMany functional [x, unfoldCallback]
  let rawProof := psWellFoundedEquation relationPlan [domainLevel, stateLevel] motive functional x
  let equationContext := { normalizedContext with environment := withDefinition }
  let equationProof ← if states.isEmpty && plan.packedIds.isEmpty then pure rawProof else do
    for constantName in [psRootName "funext", psRootName "congrArg", psNameAppendStr psEqName "trans"] do
      match psEnvironmentFind environment constantName with
      | some (.theoremDecl ..) | some (.definitionDecl ..) => pure ()
      | _ => throw (.data "PSCV0-WF-FOUNDATION: checked equality transport is unavailable")
    let callbackEquality ← match argument with
      | .unary _ =>
        psElabWellFoundedExtensionalEquality (2 + states.length)
          equationContext callbackType rawCallback unfoldCallback
      | .dependentTuple parameters _ =>
        psElabWellFoundedTupleCallbackEquality equationContext (parameters.map (·.name))
          callbackType rawCallback unfoldCallback states.length
    let transported ← psElabWellFoundedCongrArg equationContext callbackType stateType
      rawCallback unfoldCallback (.app functional x) callbackEquality
    let fullEquality := psExprApplyMany (.constE (psNameAppendStr psEqName "trans") [stateLevel])
      [stateType, .app fixed x, rawRhs, sourceRhs, rawProof, transported]
    if states.isEmpty then pure fullEquality else do
      let applyName := psRootName "_applyState"
      let applyStates := PsExpr.lam applyName stateType
        (psExprApplyMany (.bvar 0) stateArguments) .explicit
      psElabWellFoundedCongrArg equationContext stateType declaredResult
        (.app fixed x) sourceRhs applyStates fullEquality
  let rhs := psExprApplyMany sourceRhs stateArguments
  let equationType := psElabWellFoundedForalls fullParameters
    (psLogicEq resultLevel declaredResult (psExprApplyMany self originalArguments) rhs)
  let equationValue := psElabWellFoundedLambdas fullParameters equationProof
  let usedEquationLevels := psElabDeclarationLevels levels [equationType, equationValue]
  if header.preserveLevels && !usedEquationLevels.all (fun used => levels.any (psNameEq used)) then
    throw (.data "PSCV0-WF-LEVELS: the checked source equation introduced a universe outside its original source block")
  let equationLevels := if header.preserveLevels then levels else usedEquationLevels
  let _ ← psElabWellFoundedChecked "closed equation" (psElabContextEmpty withDefinition equationLevels)
    equationValue equationType
  let equation := PsDeclaration.theoremDecl equationName equationLevels equationType equationValue
  return {
    declaration, equation, metaContext := solved.metaContext
    sourceInfo := psElabFinishSourceInfo solved name }

-- Keep the original entry point and add the actual declaration identity to
-- failures from every phase of its unchanged construction.
def psElabWellFoundedTypedParts (elaborate : PsElaborator)
    (name : PsName) (header : PsElabWellFoundedTypedHeader)
    (valueSyntax : PsSyntaxTerm) (termination : PsSyntaxTermination) :
    Except PsElabError PsElabWellFoundedResult :=
  (psElabWellFoundedTypedPartsCore elaborate name header valueSyntax termination).mapError
    (fun error => .atDeclaration name error)

-- The existing standalone route still elaborates its own selected header.
-- Lifted local definitions enter the same construction through TypedParts.
def psElabWellFoundedParts (elaborate : PsElaborator)
    (environment : PsEnvironment) (nameSyntax : PsSyntaxName)
    (binders : List (PsSyntaxBinderHead × PsSyntaxTerm))
    (typeSyntax valueSyntax : PsSyntaxTerm) (termination : PsSyntaxTermination)
    (levelNames : List PsName := []) :
    Except PsElabError PsElabWellFoundedResult := do
  let some name := psSyntaxNameToName nameSyntax | throw .emptyName
  let binderResult ← psElabTypedBinders elaborate
    (psElabContextEmpty environment levelNames) binders
  let annotation ← psElabType elaborate binderResult.context typeSyntax
  psElabWellFoundedTypedParts elaborate name {
    context := annotation.context
    parametersRev := binderResult.bindersRev
    resultType := annotation.type
    functionName := name } valueSyntax termination
