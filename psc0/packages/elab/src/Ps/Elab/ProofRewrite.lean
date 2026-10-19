import Ps.Elab.ProofRewriteCore
import Ps.Elab.ProofTerm

/- Adapted from Lean 4.35.0 Meta/Tactic/Rewrite.lean and
 Elab/Tactic/Rewrite.lean, eb6cafb7290e8bd5f2937522d8d804f58f02bafc,
 Microsoft Corporation / Leonardo de Moura, Apache-2.0. -/

def psProofRewriteFinish (before : Nat) (value : PsElabTermResult) :
    Except PsElabError (PsElabTermResult × List PsProofGoal) := do
  let context := value.context
  let declarations ← context.metaContext.declarations.mapM fun declaration => do
    if declaration.id < before ||
        (psMetaFindAssignment context.metaContext declaration.id).isSome ||
        (psMetaFindDelayed context.metaContext declaration.id).isSome then
      return declaration
    let saved := { context with localContext := declaration.localContext }
    let level ← psElabExpressionSort saved declaration.type
    return if psLevelEquivalent level .zero then
      { declaration with kind := .syntheticOpaque } else declaration
  let context := psElabContextWithMeta context { context.metaContext with declarations }
  let goals := psProofFreshGoals before context
  let dependent := fun goal => goals.any fun other =>
    match psMetaFindDecl context.metaContext other.id with
    | none => false
    | some other => psExprContainsMVar goal.id
        (psMetaInstantiate context.metaContext other.type)
  let ordered := goals.filter (fun goal => !dependent goal) ++ goals.filter dependent
  return ({ value with context }, ordered)

def psProofRewriteElaborated (elaborate : PsElaborator) (context : PsElabContext)
    (action : PsElabContext → Except PsElabError PsElabTermResult)
    (expression : PsExpr) (reverse : Bool) :
    Except PsElabError (PsElabTermResult × List PsProofGoal) := do
  let before := context.metaContext.nextId
  let value ← psProofWithTermSynthesis elaborate context fun current => do
    let value ← action current
    let value ← psProofRewriteCore value expression reverse
    let pending := value.context.metaContext.declarations.filterMap fun declaration =>
      if declaration.id < before then none else
        match declaration.kind with
        | .synthetic => some (PsSyntheticConstraint.instanceGoal declaration.id)
        | _ => none
    psElabSolveSynthetic value pending
  psProofRewriteFinish before value

def psProofRewriteFromSource (elaborate : PsElaborator) (scope : PsSyntaxProofScope)
    (context : PsElabContext) (source : PsSyntaxTerm)
    (expression : PsExpr) (reverse : Bool) :
    Except PsElabError (PsElabTermResult × List PsProofGoal) := do
  let source ← psProofSource scope context source
  psProofRewriteElaborated elaborate context
    (fun current => elaborate current source none) expression reverse

def psProofRewriteFromName (elaborate : PsElaborator) (context : PsElabContext)
    (name : PsName) (expression : PsExpr) (reverse : Bool) :
    Except PsElabError (PsElabTermResult × List PsProofGoal) :=
  psProofRewriteElaborated elaborate context (fun current => do
    let (current, term) ← psElabResolvedReference current (.global name)
    psElabResolvedTerm current term none) expression reverse

def psProofDefinitionEquationBody (fuel : Nat) (context : PsElabContext)
    (term value : PsExpr) : Except PsElabError PsElabTermResult := do
  match fuel with
  | 0 => throw .fuelExhausted
  | fuel + 1 =>
    match value with
    | .letE _ _ assigned body =>
      psProofDefinitionEquationBody fuel context term (psExprInstantiate1 body assigned)
    | .lam name domain body binder =>
      let pushed := psLocalPushBinding context.localContext name domain binder
      let inner := psElabContextWithLocal context pushed.context
      let result ← psProofDefinitionEquationBody fuel inner (.app term (.fvar pushed.id))
        (psExprInstantiate1 body (.fvar pushed.id))
      let type := .forallE name domain (psExprAbstractFVar pushed.id result.type) binder
      let proof := .lam name domain (psExprAbstractFVar pushed.id result.term) binder
      psElabResolvedTerm (psElabLeaveScope context result.context) proof (some type)
    | _ =>
      let type ← (psInferType context.environment context.metaContext
        context.localContext term).mapError PsElabError.infer
      let level ← psElabExpressionSort context type
      psElabResolvedTerm context (psLogicRefl level type term)
        (some (psLogicEq level type term value))

def psProofDefinitionEquation (context : PsElabContext) (name : PsName) :
    Except PsElabError PsElabTermResult := do
  let some (.definitionDecl _ parameters type value) := psEnvironmentFind context.environment name
    | throw (.proof "unfolding requires an available definition body or registered equation")
  let level ← psElabExpressionSort
    { context with levelNames := parameters } type
  if psLevelEquivalent level .zero then
    throw (.proof "a proof declaration has no definition rewrite equations")
  let (context, term) ← psElabResolvedReference context (.global name)
  let .constE _ levels := term | throw .unresolvedMetavariable
  let value := psExprInstantiateLevelParams parameters levels value
  psProofDefinitionEquationBody 4096 context term value

def psProofRewriteApplyResult (state : PsProofState) (local? : Option Nat)
    (result : PsElabTermResult × List PsProofGoal) :
    Except PsElabError PsProofState := do
  let (value, premises) := result
  let equation ← psProofRewriteRelation value.context value.type value.term
  let next ← match local? with
    | none => psProofReplaceTargetEq state value.context equation
    | some id => (psProofReplaceLocalEq state value.context id equation).map Prod.fst
  let main :: saved := next.goals | throw (.proof "rewrite omitted its replacement goal")
  let tag := main.tag
  let premises := premises.map fun goal => { goal with tag := psProofTag tag goal.tag }
  psProofNormalize { next with goals := main :: (premises ++ saved) }

def psProofDefinitionHasRecursor (environment : PsEnvironment) : PsExpr → Bool
  | .constE name _ => (psEnvironmentFindRecursor environment name).isSome
  | .app fn arg | .lam _ fn arg _ | .forallE _ fn arg _ =>
    psProofDefinitionHasRecursor environment fn || psProofDefinitionHasRecursor environment arg
  | .letE _ type value body => psProofDefinitionHasRecursor environment type ||
    psProofDefinitionHasRecursor environment value || psProofDefinitionHasRecursor environment body
  | .proj _ _ value => psProofDefinitionHasRecursor environment value
  | _ => false

-- A named source function consults only its authenticated branch roster.
-- Explicit theorem terms (including a written f.eq_def) retain ordinary term
-- elaboration. An available simple definition can produce its own checked rule.
def psProofRewriteRule (elaborate : PsElaborator) (scope : PsSyntaxProofScope)
    (context : PsElabContext) (source : PsSyntaxTerm)
    (expression : PsExpr) (reverse : Bool) :
    Except PsElabError (PsElabTermResult × List PsProofGoal) := do
  let resolved ← psProofSource scope context source
  if let .reference sourceName := resolved then
    if let some (.global name, []) :=
        psElabResolveReferenceBase context.localContext context.environment sourceName then
      if let some entry := psEnvironmentFindSourceEquations context.environment name then
        for equation in entry.equations do
          match psProofRewriteFromName elaborate context equation expression reverse with
          | .ok result => return result
          | .error error => if psElabErrorIsResource error then throw error
        throw (.proof "no registered source equation rewrites the selected expression")
      if let some (.definitionDecl _ parameters type body) := psEnvironmentFind context.environment name then
        let level ← psElabExpressionSort { context with levelNames := parameters } type
        if !psLevelEquivalent level .zero then
          if psProofDefinitionHasRecursor context.environment body then
            throw (.proof "source branch equations are unavailable for this definition")
          return ← psProofRewriteElaborated elaborate context
            (fun current => psProofDefinitionEquation current name) expression reverse
  psProofRewriteElaborated elaborate context
    (fun current => elaborate current resolved none) expression reverse

-- Native locations elaborate term:max arguments to actual local identities.
-- Later names are resolved after each replacement, so ordinary aliases/shadowing
-- select the updated local declaration.
def psProofLocationId (elaborate : PsElaborator) (scope : PsSyntaxProofScope)
    (state : PsProofState) (source : PsSyntaxTerm) :
    Except PsElabError (PsProofState × Nat) := do
  let (_, context, _) ← psProofMain state
  let source ← psProofSource scope context source
  let value ← psProofWithTermSynthesis elaborate context
    (fun current => elaborate current source none)
  let .fvar id := psMetaInstantiate value.context.metaContext value.term
    | throw (.proof "tactic location requires a local declaration")
  if (psLocalFindById value.context.localContext id).isNone then
    throw (.proof "tactic location is unavailable in this goal")
  return (psProofUpdate state value.context, id)

def psProofWithLocation (elaborate : PsElaborator) (scope : PsSyntaxProofScope)
    (state : PsProofState) (location : PsSyntaxProofLocation PsSyntaxTerm)
    (atLocal : PsProofState → Nat → Except PsElabError PsProofState)
    (atTarget : PsProofState → Except PsElabError PsProofState) :
    Except PsElabError PsProofState := do
  match location with
  | .targets hypotheses target =>
    let mut current := state
    for source in hypotheses do
      let (next, id) ← psProofLocationId elaborate scope current source
      current ← atLocal next id
    if target then atTarget current else pure current
  | .all =>
    let mut current := state
    let mut worked := false
    match atTarget current with
    | .ok next => current := next; worked := true
    | .error error => if psElabErrorIsResource error then throw error
    if current.goals.isEmpty then return current
    let (_, context, _) ← psProofMain current
    for declaration in context.localContext.declarations do
      let id := psLocalDeclId declaration
      if context.auxiliaryLocalIds.contains id then continue
      match atLocal current id with
      | .ok next => current := next; worked := true
      | .error error => if psElabErrorIsResource error then throw error
    if !worked then throw (.proof "tactic made no progress at any selected location")
    return current

-- The rw macro tries reducible rfl only once, after its complete rule sequence.
-- This helper does not change the ordinary standalone rfl implementation.
def psProofRewriteReflexivity (state : PsProofState) :
    Except PsElabError PsProofState := do
  let (goal, context, target) ← psProofMain state
  let target ← psProofWhnfWithTransparency .reducible 256 context target
  let view := psExprAppView target
  let (context, proof) ← match view.head, view.args with
    | .constE name [level], [type, left, right] => do
      if !psNameEq name psEqName then throw (.proof "reflexivity does not apply")
      let unified := psUnifyWithTransparency .reducible context.environment
        context.localContext context.metaContext left right
      if unified.resourceExceeded then throw .fuelExhausted
      if !unified.success then throw (.proof "reflexivity does not apply")
      pure (psElabContextWithMeta context unified.context, psLogicRefl level type left)
    | .constE name [level], [leftType, left, rightType, right] => do
      if !psNameEq name (psRootName "HEq") then throw (.proof "reflexivity does not apply")
      let types := psUnifyWithTransparency .reducible context.environment
        context.localContext context.metaContext leftType rightType
      if types.resourceExceeded then throw .fuelExhausted
      if !types.success then throw (.proof "reflexivity does not apply")
      let unified := psUnifyWithTransparency .reducible context.environment
        context.localContext types.context left right
      if unified.resourceExceeded then throw .fuelExhausted
      if !unified.success then throw (.proof "reflexivity does not apply")
      pure (psElabContextWithMeta context unified.context,
        psExprApplyMany (.constE (psNameAppendStr (psRootName "HEq") "refl") [level]) [leftType, left])
    | .constE name [], [left, right] => do
      if !psNameEq name (psRootName "Iff") then throw (.proof "reflexivity does not apply")
      let unified := psUnifyWithTransparency .reducible context.environment
        context.localContext context.metaContext left right
      if unified.resourceExceeded then throw .fuelExhausted
      if !unified.success then throw (.proof "reflexivity does not apply")
      let proof := psExprApplyMany (.constE (psNameAppendStr (psRootName "Iff") "intro") []) [
        left, right,
        .lam (psRootName "h") left (.bvar 0) .explicit,
        .lam (psRootName "h") right (.bvar 0) .explicit]
      pure (psElabContextWithMeta context unified.context, proof)
    | _, _ => throw (.proof "reflexivity does not apply")
  let next ← psProofAssign (psProofUpdate state context) goal.id proof
  psProofNormalize next

def psProofRewriteAt (elaborate : PsElaborator) (scope : PsSyntaxProofScope)
    (state : PsProofState) (source : PsSyntaxTerm) (reverse : Bool)
    (local? : Option Nat) : Except PsElabError PsProofState := do
  let (_, context, target) ← psProofMain state
  let expression ← match local? with
    | none => pure target
    | some id =>
      let some declaration := psLocalFindById context.localContext id
        | throw (.proof "tactic location is unavailable in this goal")
      pure (psLocalDeclType declaration)
  let result ← psProofRewriteRule elaborate scope context source expression reverse
  psProofRewriteApplyResult state local? result

def psProofRewrite (elaborate : PsElaborator) (scope : PsSyntaxProofScope)
    (state : PsProofState) (rules : List (PsSyntaxTerm × Bool))
    (location : PsSyntaxProofLocation PsSyntaxTerm) (close : Bool) :
    Except PsElabError PsProofState := do
  let mut current := state
  for (source, reverse) in rules do
    current ← psProofWithLocation elaborate scope current location
      (fun current id => psProofRewriteAt elaborate scope current source reverse (some id))
      (fun current => psProofRewriteAt elaborate scope current source reverse none)
  if !close || current.goals.isEmpty then return current
  match psProofRewriteReflexivity current with
  | .ok next => return next
  | .error error =>
    if psElabErrorIsResource error then throw error
    return current
