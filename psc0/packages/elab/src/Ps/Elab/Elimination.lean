import Ps.Elab.GoalSource
import Ps.Elab.Match

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
  let _ ← psElabExpressionSort context branch.target
  let fresh := psMetaFresh context.metaContext context.localContext branch.target .syntheticOpaque { tag, binders := introduced }
  return {
    context := psElabContextWithMeta context fresh.context
    term := fresh.expr
    type := branch.target }

-- Tactics are consumers of the shared eliminator. Cases hides recursive IHs;
-- induction retains them. Original majors/dependents leave the goal context,
-- while the recursor's checked refinement opens their specialized replacements.
def psProofEliminate (elaborate : PsElaborator) (scope : PsSyntaxProofScope)
    (state : PsProofState) (source : PsSyntaxTerm) (induction : Bool) :
    Except PsElabError PsProofState := do
  let (goal, context, target) ← psProofMain state
  let source ← psProofSource scope context source
  let value ← elaborate context source none
  let .fvar _ := value.term | throw (.proof "elimination currently requires a local hypothesis")
  let read := fun current _ expected => psElabResolvedTerm current value.term expected
  let result ← psElabMatchWith read (fun current info => do
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
