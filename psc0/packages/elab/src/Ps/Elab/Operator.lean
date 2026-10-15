import Ps.Elab.Application
import Ps.Elab.Postponed

/-!
Operator inference adapted from Lean 4.35.0 Lean/Elab/Extra.lean
(eb6cafb7290e8bd5f2937522d8d804f58f02bafc), Microsoft Corporation and
Leonardo de Moura, Apache-2.0; see THIRD_PARTY_NOTICES.md.
PSCV0 has a closed notation registry and direct Coe boundaries. It needs no
macro expander, lazy operator or separate application/constraint engine.
-/
inductive PsElabOperatorTree where
  | leaf (term type : PsExpr)
  | unary (name : PsSyntaxName) (argument : PsElabOperatorTree)
  | binary (kind : PsSyntaxOperatorKind) (name : PsSyntaxName)
      (left right : PsElabOperatorTree)

-- Elaborate every leaf exactly once, retaining one monotonically advancing
-- context. A relation nested inside arithmetic is a leaf; the exponent of a
-- right action is elaborated independently and never participates in promotion.
def psElabOperatorPrepare (elaborate : PsElaborator) (fuel : Nat)
    (context : PsElabContext) (source : PsSyntaxTerm) (root : Bool := false) :
    Except PsElabError (PsElabContext × PsElabOperatorTree) := do
  match fuel with
  | 0 => throw .fuelExhausted
  | fuel + 1 =>
    match source with
    | .operatorE .unary name _ [argument] _ =>
      let (context, argument) ← psElabOperatorPrepare elaborate fuel context argument
      return (context, .unary name argument)
    | .operatorE kind name _ [left, right] _ =>
      if kind == .binary || kind == .rightAction || root then
        let (context, left) ← psElabOperatorPrepare elaborate fuel context left
        let (context, right) ← if kind == .rightAction then do
            let result ← elaborate context right none
            pure (result.context, .leaf result.term result.type)
          else psElabOperatorPrepare elaborate fuel context right
        return (context, .binary kind name left right)
      else
        let result ← elaborate context source none
        return (result.context, .leaf result.term result.type)
    | _ =>
      let result ← elaborate context source none
      return (result.context, .leaf result.term result.type)

def psElabOperatorUnknown : PsExpr → Bool
  | .mvar _ => true
  | .app fn _ => psElabOperatorUnknown fn
  | .letE _ _ _ body => psElabOperatorUnknown body
  | _ => false

structure PsElabOperatorAnalysis where
  maximum : Option PsExpr := none
  incomparable : Bool := false
  unknown : Bool := false

-- Read-only probes cannot assign an operand's metavariables or leak coercion
-- evidence. A fresh local stands for an arbitrary value of the source type.
def psElabOperatorHasCoe (context : PsElabContext) (source target : PsExpr) :
    Except PsElabError Bool := do
  let localDecl := psLocalPushBinding context.localContext
    (psRootName "$operatorProbe") source .explicit
  let probe : PsElabTermResult := {
    context := psElabContextWithLocal context localDecl.context
    term := .fvar localDecl.id, type := source }
  match psElabCoerce probe "Coe" (some target) with
  | .ok _ => return true
  | .error .fuelExhausted => throw .fuelExhausted
  | .error _ => return false

def psElabOperatorAnalyze (context : PsElabContext) :
    PsElabOperatorTree → PsElabOperatorAnalysis →
      Except PsElabError PsElabOperatorAnalysis
  | tree, state => do
    if state.incomparable then return state
    match tree with
    | .unary _ argument => psElabOperatorAnalyze context argument state
    | .binary kind _ left right =>
      let state ← psElabOperatorAnalyze context left state
      if kind == .rightAction then return state
      psElabOperatorAnalyze context right state
    | .leaf _ type =>
      let type := psMetaInstantiate context.metaContext type
      if psElabOperatorUnknown type then return { state with unknown := true }
      let some maximum := state.maximum | return { state with maximum := some type }
      if psDefEqReadOnlyWithEnv context.environment context.metaContext
          context.localContext maximum type then return state
      if ← psElabOperatorHasCoe context type maximum then return state
      if ← psElabOperatorHasCoe context maximum type then
        return { state with maximum := some type }
      return { state with incomparable := true }

def psElabOperatorAnalysisFor (context : PsElabContext) (tree : PsElabOperatorTree)
    (expected : Option PsExpr) : Except PsElabError PsElabOperatorAnalysis := do
  let maximum := expected.bind fun type =>
    let type := psMetaInstantiate context.metaContext type
    if psElabOperatorUnknown type then none else some type
  psElabOperatorAnalyze context tree { maximum }

def psElabOperatorClass (name : PsSyntaxName) : Option PsSyntaxName := do
  if name.segments.length < 2 then none else
    some { name with segments := name.segments.take (name.segments.length - 1) }

def psElabOperatorHomogeneous (context : PsElabContext) (name : PsSyntaxName)
    (maximum : PsExpr) : Except PsElabError Bool := do
  let some className := psElabOperatorClass name | return false
  let attempt := do
    let head ← psElabReference context className none
    let goal ← psElabApplyCore head.context head.term [maximum, maximum, maximum]
    let search := psSynthInstanceWithLimits goal.context.environment goal.context.localContext
      goal.context.instances goal.context.metaContext 64 {} goal.term
    if search.table.resourceExceeded then throw PsElabError.fuelExhausted
    pure search.result.value.isSome
  match attempt with
  | .ok result => return result
  | .error .fuelExhausted => throw .fuelExhausted
  | .error _ => return false

def psElabOperatorPiBody : PsExpr → PsExpr
  | .forallE _ _ body _ => psElabOperatorPiBody body
  | body => body

-- Do not force an unknown operand to the homogeneous type when a selected
-- heterogeneous default is intended to determine it (Lean Extra.lean).
def psElabOperatorHasHeterogeneousDefault (context : PsElabContext)
    (name : PsSyntaxName) (maximum : PsExpr) (left : Bool) : Bool :=
  match psElabOperatorClass name with
  | none => false
  | some classSyntax =>
    match psSyntaxNameToName classSyntax, (psExprAppView maximum).head with
    | some className, .constE typeName _ =>
      let defaults := context.instances.defaults.filter fun entry =>
        entry.className.any (psNameEq className)
      defaults.length > 1 && defaults.any fun entry =>
        let arguments := (psExprAppView (psElabOperatorPiBody entry.type)).args
        match arguments[if left then 1 else 0]? with
        | some other => match (psExprAppView other).head with
          | .constE otherName _ => psNameEq typeName otherName
          | _ => false
        | none => false
    | _, _ => false

def psElabOperatorCall (context : PsElabContext) (name : PsSyntaxName)
    (arguments : List (PsExpr × PsExpr)) : Except PsElabError PsElabTermResult := do
  let head ← psElabReference context name none
  let apply := fun ctx (argument : PsExpr × PsExpr) expected =>
    psElabFinalizeExpected { context := ctx, term := argument.1, type := argument.2 } expected
  let application ← psElabApplyOrderedWith apply 4096 head arguments [] []
  psElabFinishApplication application none

def psElabOperatorBooleanOperand (result : PsElabTermResult) :
    Except PsElabError PsElabTermResult :=
  if psDefEqReadOnlyWithEnv result.context.environment result.context.metaContext
      result.context.localContext result.type (.sortE .zero) then
    psElabFinalizeExpected result (some (.constE psBoolName []))
  else .ok result

-- The same ordered application engine constructs every operator. Only leaf
-- promotion is special; failed homogeneous probes leave both children free
-- to infer their own types, preserving heterogeneous operations.
def psElabOperatorEmit (fuel : Nat) (context : PsElabContext)
    (tree : PsElabOperatorTree) (maximum : Option PsExpr)
    (analyze : Bool := false) (parent : Option (PsSyntaxName × Bool) := none) :
    Except PsElabError PsElabTermResult := do
  match fuel with
  | 0 => throw .fuelExhausted
  | fuel + 1 =>
    let maximum ← if analyze then do
        let result ← psElabOperatorAnalysisFor context tree none
        pure (if result.incomparable then none else result.maximum)
      else pure maximum
    match tree with
    | .leaf term type =>
      let result : PsElabTermResult := { context, term, type }
      if psElabOperatorUnknown (psMetaInstantiate context.metaContext type) then
        if let some (name, left) := parent then
          if let some maximum := maximum then
            if psElabOperatorHasHeterogeneousDefault context name maximum left then
              return result
      psElabFinalizeExpected result maximum
    | .unary name argument =>
      let argument ← psElabOperatorEmit fuel context argument maximum
      psElabOperatorCall argument.context name [(argument.term, argument.type)]
    | .binary kind name left right =>
      let relation := kind == .relation || kind == .booleanRelation
      let promote ← match maximum with
        | none => pure false
        | some maximum =>
          if relation || kind == .rightAction then pure true
          else psElabOperatorHomogeneous context name maximum
      let childMaximum := if promote then maximum else none
      let left ← psElabOperatorEmit fuel context left childMaximum
        (!promote && maximum.isSome) (some (name, true))
      let right ← psElabOperatorEmit fuel left.context right
        (if kind == .rightAction then none else childMaximum)
        (!promote && maximum.isSome) (some (name, false))
      let left := { left with context := right.context }
      let left ← if kind == .booleanRelation then
          psElabOperatorBooleanOperand left
        else pure left
      let right ← if kind == .booleanRelation then
          psElabOperatorBooleanOperand { right with context := left.context }
        else pure { right with context := left.context }
      psElabOperatorCall right.context name
        [(left.term, left.type), (right.term, right.type)]

def psElabOperator (elaborate : PsElaborator) (context : PsElabContext)
    (source : PsSyntaxTerm) (expected : Option PsExpr) :
    Except PsElabError PsElabTermResult := do
  let postponing := context.postponing
  let (context, tree) ← psElabOperatorPrepare elaborate 4096
    { context with postponing := true } source true
  let context ← psElabProgressPending elaborate context
  let relation := match tree with
    | .binary .relation .. | .binary .booleanRelation .. => true
    | _ => false
  let analysis ← psElabOperatorAnalysisFor context tree (if relation then none else expected)
  let maximum := if analysis.incomparable then none else analysis.maximum
  let maximum := match tree, maximum with
    | .binary .booleanRelation .., some type =>
      if psDefEqReadOnlyWithEnv context.environment context.metaContext
          context.localContext type (.sortE .zero) then some (.constE psBoolName [])
      else maximum
    | _, _ => maximum
  let result ← psElabOperatorEmit 4096 context tree maximum
  let result := if !relation && !analysis.unknown then
      (psElabUnifyExpected result maximum).toOption.getD result
    else result
  let result ← psElabFinalizeExpected result expected
  if postponing then return result
  let result ← psElabDrainPending elaborate result
  return { result with context := { result.context with postponing } }
