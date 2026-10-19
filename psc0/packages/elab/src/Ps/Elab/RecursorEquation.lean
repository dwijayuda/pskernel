import Ps.Elab.Match
import Ps.Meta.Recursor

def psElabRecursorEquationError (message : String) : PsElabError :=
  .data ("PSCV0-RECURSOR-EQUATION: " ++ message)

structure PsElabRecursorEquationView where
  level : PsLevel
  type : PsExpr
  left : PsExpr
  right : PsExpr

def psElabRecursorEquationView (context : PsElabContext) (expression : PsExpr) :
    Except PsElabError PsElabRecursorEquationView := do
  let view := psExprAppView (psWhnf context.environment context.metaContext
    context.localContext expression)
  let .constE name [level] := view.head
    | throw (psElabRecursorEquationError "expected the actual Eq declaration")
  let [type, left, right] := view.args
    | throw (psElabRecursorEquationError "equality has the wrong argument telescope")
  if !psNameEq name psEqName then
    throw (psElabRecursorEquationError "expected the actual Eq declaration")
  let _ ← psElabResolvedTerm context expression (some (.sortE .zero))
  return { level, type, left, right }

-- After an outer case split, a nested source match may still have a
-- different reverted motive from the checked WF callback. Select only the
-- actual local major of a remaining canonical recursor at an equality side.
-- Arbitrary arguments, recursive calls and induction hypotheses are not used
-- as evidence for the equation.
def psElabRecursorEquationNestedMajor (context : PsElabContext)
    (equation : PsElabRecursorEquationView) : Option PsExpr :=
  [equation.left, equation.right].findSome? fun expression => do
    let normalized := psWhnf context.environment context.metaContext context.localContext expression
    let application ← psEliminationRecursorApplication context.environment normalized
    let major := psWhnf context.environment context.metaContext context.localContext application.major
    let .fvar id := major | none
    if psLocalContainsId context.localContext id then some major else none

-- Prove an exact equality by the actual major's checked constructor cases.
-- The registered family and its parameters/indices come from ordinary Core
-- inference, never source spelling or a caller-supplied recursor descriptor.
-- Different eliminator motives may become definitionally equal in each
-- constructor branch. No induction hypothesis is used to assume the equation.
def psElabRecursorEquationProofWithFuel (fuel : Nat) (context : PsElabContext)
    (major expected : PsExpr) (span : PsSourceSpan) : Except PsElabError PsExpr := do
  match fuel with
  | 0 => throw (psElabRecursorEquationError "nested checked constructor cases exhausted their proof depth")
  | fuel + 1 =>
    let _ ← psElabRecursorEquationView context expected
    let .fvar _ := major
      | throw (psElabRecursorEquationError "selected case proof requires an actual local major")
    let type ← (psInferType context.environment context.metaContext context.localContext major).mapError
      PsElabError.infer
    let actual := psExprAppView (psWhnf context.environment context.metaContext context.localContext type)
    let .constE name familyLevels := actual.head
      | throw (psElabRecursorEquationError "local major does not have an inductive family type")
    let some info := psEnvironmentFindInductive context.environment name
      | throw (psElabRecursorEquationError "local major has no registered inductive family")
    if actual.args.length != info.numParams + info.numIndices then
      throw (psElabRecursorEquationError "major family has a different parameter/index telescope")
    let uniformArgs := actual.args.take info.numParams
    let indices := actual.args.drop info.numParams
    let motive ← psElabMatchMotive context info familyLevels uniformArgs indices major expected
    let level ← psElabMatchMotiveLevel context motive.motive
    let recursor ← psElabEliminationRecursorPlanFor context info familyLevels uniformArgs level
    let constructors ← psElabEliminationConstructors recursor.context recursor.plan
    let motives ← psElabRecursorArguments recursor.plan.slots.zipIdx
      (fun current (slot, index) domain => do
        if index == recursor.slotIndex then
          return { context := current, term := motive.motive }
        let opened ← psElabOpenCoreTelescope 4096 current domain (some (slot.family.numIndices + 1))
        let .sortE actualLevel := psWhnf opened.context.environment opened.context.metaContext
            opened.context.localContext opened.body
          | throw (psElabRecursorEquationError "companion motive has no actual Sort domain")
        let unit ← psElabMatchUnit opened.context actualLevel
        return {
          context := psElabLeaveScope current opened.context
          term := psCloseElabLambdaBinders opened.context.metaContext opened.bindersRev unit.fst })
      recursor.context recursor.cursor
    let minors ← psElabRecursorArguments constructors
      (fun current (index, _, constructor) domain => do
        if index == recursor.slotIndex then
          let alternative : PsElabMatchAlternative := {
            constructorName := constructor.info.name
            fieldNames := (List.range constructor.info.numFields).map fun index =>
              PsSyntaxName.mk ["$psc0MutualEquation", psNatToString index] span
            elaborate := fun branch => do
              let equation ← psElabRecursorEquationView branch.context branch.target
              match psElabResolvedTerm branch.context
                  (psLogicRefl equation.level equation.type equation.left) (some branch.target) with
              | .ok proof => pure proof
              | .error .fuelExhausted => throw .fuelExhausted
              | .error (.infer .fuelExhausted) => throw (.infer .fuelExhausted)
              | .error original =>
                let some nestedMajor := psElabRecursorEquationNestedMajor branch.context equation
                  | throw original
                let proof ← psElabRecursorEquationProofWithFuel fuel branch.context
                  nestedMajor branch.target span
                psElabResolvedTerm branch.context proof (some branch.target)
            span }
          psElabMatchMinorWithHypotheses current info familyLevels uniformArgs motive constructor.info.name
            (some alternative) domain []
        else
          let opened ← psElabOpenCoreTelescope 4096 current domain
            (some (constructor.info.numFields + constructor.recursiveFields.length))
          let actualLevel ← psElabExpressionSort opened.context opened.body
          let unit ← psElabMatchUnit opened.context actualLevel
          let checked ← psElabResolvedTerm opened.context unit.snd (some opened.body)
          return {
            context := psElabLeaveScope current checked.context
            term := psCloseElabLambdaBinders checked.context.metaContext opened.bindersRev checked.term })
      motives.context motives.cursor
    let proof := psExprApplyMany (.constE recursor.recursor.name recursor.levels)
      (uniformArgs ++ motives.arguments ++ minors.arguments ++ indices ++ [major] ++ motive.arguments)
    let checked ← psElabResolvedTerm (psElabLeaveScope context minors.context) proof (some expected)
    return psMetaInstantiate checked.context.metaContext checked.term

-- Every leaf still requires checked reflexivity; each recursive step constructs
-- and checks an ordinary cases recursor with its real motive and refinements.
def psElabRecursorEquationProof (context : PsElabContext)
    (major expected : PsExpr) (span : PsSourceSpan) : Except PsElabError PsExpr :=
  psElabRecursorEquationProofWithFuel 64 context major expected span

structure PsElabSourceEquationPointwise where
  context : PsElabContext
  bindersRev : List PsElabTypedBinder
  type : PsExpr
  proof : PsExpr

-- Native 4.35.0 Structural/Eqns.mkUnfoldEq, WF/Unfold.mkUnfoldEq
-- and Eqns.unfoldThmType use lambdaTelescope on the retained source value.
-- This consumes actual leading lambdas, including returned-function lambdas;
-- it does not unfold a let or a function-valued constant to invent parameters.
-- The original-header theorem remains the proof owner. Additional arguments
-- use ordinary checked Eq.rec congruence after that theorem is instantiated.
def psElabSourceEquationPointwiseWithFuel (fuel headerRemaining : Nat)
    (context : PsElabContext) (source type proof : PsExpr)
    (bindersRev : List PsElabTypedBinder) :
    Except PsElabError PsElabSourceEquationPointwise := do
  match fuel with
  | 0 => throw .fuelExhausted
  | fuel + 1 =>
    match source with
    | .lam name domain body binder =>
      let functionType ← match headerRemaining with
        | 0 => do
          let equation ← psElabRecursorEquationView context type
          if !psDefEqReadOnlyWithEnv context.environment context.metaContext
              context.localContext equation.right source then
            throw (psElabRecursorEquationError "source equation has a different retained right side")
          pure equation.type
        | _ + 1 => pure type
      let pi ← (psInferEnsureForall context.environment context.metaContext
        context.localContext functionType).mapError PsElabError.infer
      if !psBinderInfoEq binder pi.binder ||
          !psExprFVarsInContext context.localContext domain ||
          !psDefEqReadOnlyWithEnv context.environment context.metaContext
            context.localContext domain pi.domain then
        throw (psElabRecursorEquationError "source equation lambda differs from its checked telescope")
      let pushed := psLocalPushBinding context.localContext name domain binder
      let inner := psElabContextWithLocal context pushed.context
      let argument := PsExpr.fvar pushed.id
      let nextSource := psExprInstantiate1 body argument
      let nextBinders := PsElabTypedBinder.mk pushed.id name domain binder :: bindersRev
      match headerRemaining with
      | remaining + 1 =>
        let applied ← psElabApplyCore inner proof [argument]
        psElabSourceEquationPointwiseWithFuel fuel remaining applied.context
          nextSource applied.type applied.term nextBinders
      | 0 =>
        let equation ← psElabEquationView inner type proof
        let resultType := psExprInstantiate1 pi.body argument
        let functionId := inner.localContext.nextId
        let applyArgument := psLogicLam functionId "_sourceFunction" equation.type
          (.app (.fvar functionId) argument)
        let congruence ← psElabEquationCongr inner equation applyArgument resultType
        let nextType := psLogicEq congruence.level congruence.type
          (.app equation.left argument) (.app equation.right argument)
        let checked ← psElabResolvedTerm inner congruence.proof (some nextType)
        psElabSourceEquationPointwiseWithFuel fuel 0 checked.context
          nextSource nextType checked.term nextBinders
    | _ =>
      if headerRemaining != 0 then
        throw (psElabRecursorEquationError "source equation header exceeds its raw lambda prefix")
      let equation ← psElabRecursorEquationView context type
      if !psDefEqReadOnlyWithEnv context.environment context.metaContext
          context.localContext equation.right source then
        throw (psElabRecursorEquationError "source equation has a different retained right side")
      return { context, bindersRev, type, proof }

-- Publication is still an ordinary closed theorem checked in the actual
-- staged environment. The adapter changes its quantified telescope, never
-- recursion parameters, body checking, decrease obligations or conversion.
def psElabSourceEquationPointwiseDeclaration (environment : PsEnvironment)
    (levels : List PsName) (name : PsName) (sourceHeaderCount : Nat)
    (sourceValue equationType equationProof : PsExpr) :
    Except PsElabError PsDeclaration := do
  if [sourceValue, equationType, equationProof].any (fun expression =>
      psExprHasUnresolvedMeta expression ||
      !psExprFVarsInContext psLocalEmpty expression) then
    throw (psElabRecursorEquationError "source equation publication retains a local or metavariable")
  let initial := psElabContextEmpty environment levels
  let opened ← psElabSourceEquationPointwiseWithFuel 4096 sourceHeaderCount initial
    sourceValue equationType equationProof []
  let closed := psCloseElabTypedBinders opened.context.metaContext
    opened.bindersRev opened.proof opened.type
  if psExprHasUnresolvedMeta closed.fst || psExprHasUnresolvedMeta closed.snd ||
      !psExprFVarsInContext psLocalEmpty closed.fst ||
      !psExprFVarsInContext psLocalEmpty closed.snd then
    throw (psElabRecursorEquationError "pointwise source equation did not close over its actual lambdas")
  let checked ← psElabResolvedTerm initial closed.fst (some closed.snd)
  return .theoremDecl name levels closed.snd checked.term
