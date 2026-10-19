import Ps.Elab.GoalSource
import Ps.Elab.Match
import Ps.Elab.ExprAbstraction

def psProofTag (parent child : String) : String :=
  if parent.isEmpty then child else if child.isEmpty then parent else parent ++ "." ++ child

def psProofEliminationGoal (tag : String) (induction : Bool) (branch : PsElabMatchBranch) :
    Except PsElabError PsElabTermResult := do
  let hidden := branch.clearedIds ++
    (if induction then [] else branch.hypotheses.map (·.id))
  let introduced := (branch.fields ++ (if induction then branch.hypotheses else [])).map fun binder =>
    match psLocalFindUser branch.context.localContext binder.name with
    | some current => psLocalDeclId current
    | none => binder.id
  let declarations := branch.context.localContext.declarations.filterMap fun entry =>
    let id := psLocalDeclId entry
    if hidden.contains id then none else
    let name := if introduced.contains id then
        PsName.num (psRootName "_case") id else psLocalDeclUserName entry
    match entry with
    | .binding id _ type binder => some (.binding id name type binder)
    | .letDecl id _ type value => some (.letDecl id name type value)
  let context := psElabContextWithLocal branch.context
    { branch.context.localContext with declarations }
  -- A user-visible proof IH is an ordinary local in later source matches.
  let context := if induction then
    { context with auxiliaryLocalIds := context.auxiliaryLocalIds.filter
      (fun id => !(branch.hypotheses.any (fun binder => binder.id == id))) }
    else context
  let _ ← psElabExpressionSort context branch.target
  let fresh := psMetaFresh context.metaContext context.localContext branch.target .syntheticOpaque { tag, binders := introduced }
  return {
    context := psElabContextWithMeta context fresh.context
    term := fresh.expr
    type := branch.target }

-- Pinned Elab/Tactic/Induction.elabElimTargets generalizes computed
-- expressions and let declarations before selecting the eliminator. Keep the
-- original source scope; the checked new goal is applied to the original term.
def psProofPrepareEliminationTarget (state : PsProofState) (goal : PsProofGoal)
    (target : PsExpr) (value : PsElabTermResult) :
    Except PsElabError (PsProofState × PsElabTermResult) := do
  let term := psMetaInstantiate value.context.metaContext value.term
  let shouldGeneralize ← match term with
    | .fvar id =>
      match psLocalFindById value.context.localContext id with
      | some (.binding ..) => pure false
      | some (.letDecl ..) => pure true
      | none => throw (.proof "elimination target is absent from its checked local scope")
    | _ => pure true
  if !shouldGeneralize then
    return (psProofUpdate state value.context, { value with term })
  let (context, body) ← psElabKeyAbstract value.context term target .instances
  let name := PsName.num (psRootName "_eliminate") context.localContext.nextId
  let domain := psMetaInstantiate context.metaContext value.type
  let type := PsExpr.forallE name domain body .explicit
  -- Native generalize checks the complete telescope before assigning the goal.
  -- In particular, fixed dependent hypotheses cannot simply be relabeled.
  let _ ← psElabExpressionSort context type
  let fresh := psMetaFresh context.metaContext context.localContext type
    .syntheticOpaque { tag := goal.tag }
  let .mvar id := fresh.expr | throw (.proof "invalid generalized elimination goal")
  let context := psElabContextWithMeta context fresh.context
  let state ← psProofAssign (psProofUpdate state context) goal.id (.app fresh.expr term)
  let state := {
    state with
    goals := { id, tag := goal.tag } :: state.goals.drop 1 }
  let state ← psProofIntro state none
  let (_, context, _) ← psProofMain state
  let some declaration := psLocalFindUser context.localContext name
    | throw (.proof "generalized elimination binder lost its checked identity")
  let value ← psElabResolvedTerm context (.fvar (psLocalDeclId declaration)) none
  return (state, value)

-- Native checkInductionTargets checks all implicit indices and the major
-- after target generalization. Cases deliberately does not impose this rule.
def psProofCheckInductionTargets (context : PsElabContext) (info : PsInductiveInfo)
    (major type : PsExpr) : Except PsElabError Unit := do
  let type := psWhnf context.environment context.metaContext context.localContext
    (psMetaInstantiate context.metaContext type)
  let view := psInferAppView type
  let .constE name _ := view.head
    | throw (.proof "induction target has an inconsistent checked family telescope")
  if !psNameEq name info.name || view.args.length != info.numParams + info.numIndices then
    throw (.proof "induction target has an inconsistent checked family telescope")
  let targets := view.args.drop info.numParams ++ [major]
  let _ ← targets.foldlM (fun (seen : List Nat) term => do
    let .fvar id := psMetaInstantiate context.metaContext term
      | throw (.proof "induction target indices must be variables")
    if seen.contains id then
      throw (.proof "induction target and indices must be distinct")
    return id :: seen) []
  pure ()

-- Tactics are consumers of the shared eliminator. Cases hides recursive IHs;
-- induction retains them. Original majors/dependents leave the goal context,
-- while the recursor's checked refinement opens their specialized replacements.
def psProofEliminate (elaborate : PsElaborator) (scope : PsSyntaxProofScope)
    (state : PsProofState) (source : PsSyntaxTerm) (induction : Bool) :
    Except PsElabError PsProofState := do
  let (originalGoal, context, originalTarget) ← psProofMain state
  let source ← psProofSource scope context source
  let value ← elaborate context source none
  let (state, value) ← psProofPrepareEliminationTarget state originalGoal originalTarget value
  let (goal, context, target) ← psProofMain state
  let read := fun current _ expected => psElabResolvedTerm current value.term expected
  let result ← psElabMatchWith read (fun current info => do
    if induction then
      let some group := psInductiveGroupIdentityFor
          (psEnvironmentFindInductive current.environment)
          (psEnvironmentFindRecursor current.environment) info
        | throw .matchRecursorUnsupported
      if group.members.length != 1 then
        throw (.proof "group induction requires a complete motive family")
      let some recursor := psEnvironmentFindRecursor current.environment
          (psNameAppendStr info.name "rec") | throw .matchRecursorUnsupported
      if recursor.numMotives != 1 then
        throw (.proof "nested induction requires an explicit eliminator")
      psProofCheckInductionTargets current info value.term value.type
    info.constructors.mapM fun name => do
      let some ctor := psEnvironmentFindConstructor current.environment name
        | throw (.matchConstructorUnknown name)
      let span := psSyntaxTermSpan source
      let fields := (List.range ctor.numFields).map fun index =>
        PsSyntaxName.mk ["$psc0Case", psNatToString current.localContext.nextId, psNatToString index] span
      return {
        constructorName := name
        fieldNames := fields
        elaborate := psProofEliminationGoal (psProofTag goal.tag (psNameLastComponent name)) induction
        span }) value.context source (some target)
  let pending := psProofFreshGoals context.metaContext.nextId result.context
  let state ← psProofAssign (psProofUpdate state result.context) goal.id result.term
  psProofNormalize { state with goals := pending ++ state.goals.drop 1 }

def psProofInaccessible (name : PsName) : Bool :=
  match name with | .num _ _ => true | .anonymous => true | _ => false

-- Rename source-facing local names only. Core identities and captured types
-- remain unchanged, including the recipes that eventually close this goal.
def psProofRenameCase (state : PsProofState) (goal : PsProofGoal)
    (names : List PsSyntaxName) : Except PsElabError PsProofState := do
  let some declaration := psMetaFindDecl state.context.metaContext goal.id
    | throw (.proof "unknown goal")
  let candidates := if declaration.origin.binders.isEmpty then
      declaration.localContext.declarations.filter fun entry =>
        psProofInaccessible (psLocalDeclUserName entry)
    else declaration.origin.binders.reverse.filterMap fun id =>
      match psLocalFindById declaration.localContext id with
      | some entry => if psProofInaccessible (psLocalDeclUserName entry) then some entry else none
      | none => none
  if names.length > candidates.length then throw (.proof "too many case binder names")
  let renamed ← (candidates.take names.length |>.reverse).zip names |>.mapM fun (entry, name) => do
    let some name := psSyntaxNameToName name | throw .emptyName
    pure (psLocalDeclId entry, name)
  let locals := declaration.localContext.declarations.map fun entry =>
    match renamed.find? (fun pair => pair.fst == psLocalDeclId entry) with
    | none => entry
    | some (_, name) =>
      if psNameEq name (psRootName "_") then entry else
      match entry with
      | .binding id _ type binder => .binding id name type binder
      | .letDecl id _ type value => .letDecl id name type value
  let declaration := { declaration with localContext := { declaration.localContext with declarations := locals } }
  let declarations := state.context.metaContext.declarations.map fun entry =>
    if entry.id == goal.id then declaration else entry
  let constraints := { state.context.metaContext with declarations }
  return { state with context := psElabContextWithMeta state.context constraints }

def psProofSelectCase (state : PsProofState) (tag : Option PsSyntaxName)
    (names : List PsSyntaxName) : Except PsElabError (PsProofState × List PsProofGoal) := do
  let selected ← match tag with
    | none => match state.goals.head? with
      | some goal => pure goal
      | none => throw (.proof "no goal to focus")
    | some name =>
      let key := psScopeKey name
      let matchingGoals := state.goals.filter fun goal => goal.tag == key || goal.tag.endsWith ("." ++ key)
      match matchingGoals with
      | [goal] => pure goal
      | [] => throw (.proof "unknown case tag")
      | _ => throw (.proof "ambiguous case tag")
  let state ← psProofRenameCase state selected names
  return ({ state with goals := [selected] }, state.goals.filter fun goal => goal.id != selected.id)

