import Ps.Meta.Recursor
import Ps.Meta.TypeView
import Ps.Elab.Refinement
import Ps.Elab.Declaration

-- Typed Core closure conversion before admission. Helpers preserve captures and
-- expose fresh indices/major as the only varying recursion arguments.
structure PsRecursorLiftState where
  environment : PsEnvironment
  owner : PsName
  levels : List PsName
  nextName : Nat := 0
  helpersRev : List PsDeclaration := []
  workerGroupsRev : List PsRecursorWorkerGroup := []

structure PsRecursorLiftResult where
  state : PsRecursorLiftState
  term : PsExpr

def psRecursorLiftContext (state : PsRecursorLiftState)
    (locals : PsLocalContext) : PsElabContext :=
  psElabContextWithLocal (psElabContextEmpty state.environment) locals

def psRecursorLiftInfer (state : PsRecursorLiftState) (locals : PsLocalContext)
    (expr : PsExpr) : Except String PsExpr :=
  (psExprTypeView state.environment locals expr).mapError
    (fun _ => "cannot infer recursor preparation type")

-- Walk newest-to-oldest so adding a capture's type discovers only earlier
-- dependencies. Let locals become parameters, preserving their evaluated values.
def psRecursorLiftCaptures (locals : PsLocalContext) (type value : PsExpr) :
    List PsElabTypedBinder :=
  let state := locals.declarations.foldl
    (fun (state : PsExpr × List PsElabTypedBinder) declaration =>
      let id := psLocalDeclId declaration
      if !psRecursorContainsLocal id state.fst then state else
        let domain := psLocalDeclType declaration
        let kind := match declaration with
          | .binding _ _ _ kind => kind
          | _ => PsBinderInfo.explicit
        let binder := PsElabTypedBinder.mk id (psLocalDeclUserName declaration) domain kind
        (.app state.fst domain, binder :: state.snd)) (.app type value, [])
  state.snd

def psRecursorLiftFreshName (fuel : Nat) (state : PsRecursorLiftState) :
    Except String (PsName × PsRecursorLiftState) := do
  match fuel with
  | 0 => throw "recursor helper name budget"
  | fuel + 1 =>
    let name := psNameAppendNum (psNameAppendStr state.owner "_rec") state.nextName
    let next := { state with nextName := state.nextName + 1 }
    if psEnvironmentContains state.environment name then psRecursorLiftFreshName fuel next
    else return (name, next)

def psRecursorLiftBetaApply (value : PsExpr) (arguments : List PsExpr) : Option PsExpr := do
  match arguments with
  | [] => return value
  | argument :: rest =>
    let .lam _ _ body _ := value | none
    psRecursorLiftBetaApply (psExprInstantiate1 body argument) rest

def psRecursorLiftHelper (state : PsRecursorLiftState) (locals : PsLocalContext)
    (view : PsRecursorApplication) : Except String PsRecursorLiftResult := do
  let context := psRecursorLiftContext state locals
  let headType ← psRecursorLiftInfer state locals view.head
  let some cursor := psReduceApplyType
    (psWhnf state.environment psMetaEmpty locals) headType view.fixedArgs
    | throw "recursor fixedArgs does not match its telescope"
  let opened ← (psElabOpenCoreTelescope 4096 context cursor
    (some (view.info.numIndices + 1))).mapError (fun _ => "cannot open recursor index/major telescope")
  let fresh := psElabBinderArguments opened.bindersRev
  let body := psReduceApply view.head (view.fixedArgs ++ fresh)
  let value := psCloseElabLambdaBinders psMetaEmpty opened.bindersRev body
  let type := psCloseElabForallBinders psMetaEmpty opened.bindersRev opened.body
  let captures := psRecursorLiftCaptures locals type value
  let value := psCloseElabLambdaBinders psMetaEmpty captures.reverse value
  let type := psCloseElabForallBinders psMetaEmpty captures.reverse type
  let arguments := captures.map (fun binder => PsExpr.fvar binder.id) ++ view.indices ++ [view.major]
  let some restored := psRecursorLiftBetaApply value arguments
    | throw "recursor helper substitution failed"
  let original := psReduceApply view.head (view.fixedArgs ++ view.indices ++ [view.major])
  if !psExprAlphaEq restored original then throw "recursor helper changed its original computation"
  let (name, state) ← psRecursorLiftFreshName 4096 state
  let declaration := PsDeclaration.definitionDecl name state.levels type value
  let some environment := psEnvironmentAdd state.environment declaration
    | throw "recursor helper name collision"
  return {
    state := { state with environment, helpersRev := declaration :: state.helpersRev }
    term := psReduceApply (.constE name (state.levels.map PsLevel.param)) (arguments ++ view.suffix) }

-- A fold has one ordinary definition per actual elimination slot. Each definition is
-- the corresponding checked recursor with the SAME closed capture telescope
-- and fixed arguments, followed by that family's fresh indices and major.
-- No logical recursive reference between helper definitions is introduced.
def psRecursorLiftGroup (state : PsRecursorLiftState) (locals : PsLocalContext)
    (view : PsEliminationRecursorApplication) : Except String PsRecursorLiftResult := do
  let .constE _ recursorLevels := view.head | throw "group recursor head is not a constant"
  let context := psRecursorLiftContext state locals
  let prototypes ← view.plan.slots.mapM fun slot => do
    let head := PsExpr.constE slot.recursorName recursorLevels
    let headType ← psRecursorLiftInfer state locals head
    let some cursor := psReduceApplyType (psWhnf state.environment psMetaEmpty locals)
        headType view.fixedArgs | throw "group recursor fixed arguments do not match its telescope"
    let opened ← (psElabOpenCoreTelescope 4096 context cursor
      (some (slot.family.numIndices + 1))).mapError (fun _ => "cannot open group worker telescope")
    let value := psCloseElabLambdaBinders psMetaEmpty opened.bindersRev
      (psReduceApply head (view.fixedArgs ++ psElabBinderArguments opened.bindersRev))
    let type := psCloseElabForallBinders psMetaEmpty opened.bindersRev opened.body
    return (slot, type, value)
  let dependencies := prototypes.foldl (fun expression entry =>
    PsExpr.app expression (.app entry.2.1 entry.2.2)) (.sortE .zero)
  let captures := psRecursorLiftCaptures locals (.sortE .zero) dependencies
  let (state, workersRev) ← prototypes.foldlM
    (fun (acc : PsRecursorLiftState × List PsRecursorWorker) entry => do
      let (name, state) ← psRecursorLiftFreshName 4096 acc.1
      let type := psCloseElabForallBinders psMetaEmpty captures.reverse entry.2.1
      let value := psCloseElabLambdaBinders psMetaEmpty captures.reverse entry.2.2
      let declaration := PsDeclaration.definitionDecl name state.levels type value
      let some environment := psEnvironmentAdd state.environment declaration
        | throw "group recursor worker name collision"
      let worker : PsRecursorWorker := {
        family := entry.1.family.name, name
        recursorName := if entry.1.publicMember then none else some entry.1.recursorName }
      return ({ state with environment, helpersRev := declaration :: state.helpersRev },
        worker :: acc.2)) (state, [])
  let group : PsRecursorWorkerGroup := { workers := workersRev.reverse, captureCount := captures.length }
  psValidateRecursorWorkerGroups state.environment [group]
  let some worker := group.workers.find?
      (fun worker => psNameEq (psRecursorWorkerRecursorName worker) view.slot.recursorName)
    | throw "group recursor worker is missing its selected family"
  let some (.definitionDecl _ _ _ value) := psEnvironmentFind state.environment worker.name
    | throw "group recursor worker definition is missing"
  let arguments := captures.map (fun binder => PsExpr.fvar binder.id) ++ view.indices ++ [view.major]
  let some restored := psRecursorWorkerBetaApply value arguments
    | throw "group recursor worker substitution failed"
  let original := psReduceApply view.head (view.fixedArgs ++ view.indices ++ [view.major])
  if !psExprAlphaEq restored original then throw "group recursor worker changed its original computation"
  return {
    state := { state with workerGroupsRev := group :: state.workerGroupsRev }
    term := psReduceApply (.constE worker.name (state.levels.map PsLevel.param))
      (arguments ++ view.suffix)
  }

-- Only a declaration's leading lambda telescope may reuse its recursion
-- equation. Every nested computation has its own major and lexical captures.
def psRecursorLiftVisit (fuel : Nat) (root : Bool) (entryIds : List Nat)
    (state : PsRecursorLiftState) (locals : PsLocalContext) (expr type : PsExpr) :
    Except String PsRecursorLiftResult := do
  match fuel with
  | 0 => throw "recursor preparation traversal budget"
  | fuel + 1 =>
    if (← (psTypeViewIsErased state.environment locals type).mapError
        (fun _ => "cannot classify recursor preparation type")) then
      return { state, term := expr }
    match expr with
    | .lam name domain body binder =>
      -- Entry arity is the aligned RAW forall/lambda prefix, exactly as in
      -- psErasureEntryInfoWithFuel and psEraseOpenDefinitionWithFuel. A
      -- function exposed only by reducing a result alias (e.g. DecidableEq A)
      -- is a returned closure, not another flat declaration argument. Its
      -- recursive major therefore needs the ordinary checked helper lifting.
      let entryRoot := match type with
        | .forallE .. => root
        | _ => false
      let .forallE _ _ typeBody _ := psWhnf state.environment psMetaEmpty locals type
        | throw "lambda preparation requires a function type"
      let pushed := psLocalPushBinding locals name domain binder
      let result ← psRecursorLiftVisit fuel entryRoot
        (if entryRoot then pushed.id :: entryIds else entryIds)
        state pushed.context (psExprInstantiate1 body (.fvar pushed.id))
        (psExprInstantiate1 typeBody (.fvar pushed.id))
      return { result with term := .lam name domain (psExprAbstractFVar pushed.id result.term) binder }
    | .letE name domain value body =>
      let value ← psRecursorLiftVisit fuel false entryIds state locals value domain
      let pushed := psLocalPushLet locals name domain value.term
      let body ← psRecursorLiftVisit fuel false entryIds value.state pushed.context
        (psExprInstantiate1 body (.fvar pushed.id)) type
      return { body with term := .letE name domain value.term (psExprAbstractFVar pushed.id body.term) }
    | .proj name index value =>
      let valueType ← psRecursorLiftInfer state locals value
      let value ← psRecursorLiftVisit fuel false entryIds state locals value valueType
      return { value with term := .proj name index value.term }
    | .app .. =>
      let spine := psReduceAppView expr
      let headType ← psRecursorLiftInfer state locals spine.head
      let head ← psRecursorLiftVisit fuel false entryIds state locals spine.head headType
      let arguments ← spine.args.foldlM
        (fun (acc : PsRecursorLiftState × PsExpr × List PsExpr) value => do
          let .forallE _ domain body _ := psWhnf acc.fst.environment psMetaEmpty locals acc.snd.fst
            | throw "application preparation requires a function type"
          let result ← psRecursorLiftVisit fuel false entryIds acc.fst locals value domain
          return (result.state, psExprInstantiate1 body result.term, result.term :: acc.snd.snd))
        (head.state, headType, [])
      let state := arguments.fst
      let term := psReduceApply head.term arguments.snd.snd.reverse
      if let some group := psEliminationRecursorApplication state.environment term then
        if group.plan.slots.length > 1 && psEliminationRecursorUsesHypotheses group then
          return ← psRecursorLiftGroup state locals group
      let some view := psRecursorApplication state.environment term | return { state, term }
      if !psRecursorUsesHypotheses state.environment view then return { state, term }
      let minors := view.fixedArgs.drop (view.info.numParams + 1)
      let direct := root && view.suffix.isEmpty &&
        ((psRecursorVaryingLocals view.major view.indices minors).map
          (fun ids => ids.all entryIds.contains)).getD false
      if direct then return { state, term }
      psRecursorLiftHelper state locals view
    | _ => return { state, term := expr }

structure PsRecursorLiftOutput where
  result : PsElabModuleResult
  parents : List (PsName × PsName)
  workerGroups : List PsRecursorWorkerGroup := []

structure PsRecursorLiftDeclarationsState where
  environment : PsEnvironment
  declarationsRev : List PsDeclaration := []
  parents : List (PsName × PsName) := []
  workerGroupsRev : List PsRecursorWorkerGroup := []

def psRecursorLiftDeclarationsWithOrigins (environment : PsEnvironment)
    (declarations : List PsDeclaration) : Except String PsRecursorLiftOutput := do
  let result ← declarations.foldlM
    (fun (acc : PsRecursorLiftDeclarationsState) declaration => do
      match declaration with
      | .definitionDecl name levels type value =>
        -- Proof/spec-only code needs no executable recursor workers.
        if psEnvironmentIsNoncomputable acc.environment name then
          return { acc with declarationsRev := declaration :: acc.declarationsRev }
        let state : PsRecursorLiftState := { environment := acc.environment, owner := name, levels }
        let lifted ← (psRecursorLiftVisit 4096 true [] state psLocalEmpty value type).mapError
          (fun message => message ++ " (in " ++ psNameToString name ++ ")")
        let rewritten := PsDeclaration.definitionDecl name levels type lifted.term
        let environment := { lifted.state.environment with
          declarations := rewritten :: psEnvironmentRemoveName name lifted.state.environment.declarations
          index := psEnvironmentIndexInsert lifted.state.environment.index rewritten }
        return {
          environment
          declarationsRev := rewritten :: (lifted.state.helpersRev ++ acc.declarationsRev)
          parents := (lifted.state.helpersRev.map fun helper => (psDeclarationName helper, name)) ++ acc.parents
          workerGroupsRev := lifted.state.workerGroupsRev ++ acc.workerGroupsRev
        }
      | _ => return { acc with declarationsRev := declaration :: acc.declarationsRev }) { environment }
  return {
    result := { environment := result.environment, declarations := result.declarationsRev.reverse }
    parents := result.parents
    workerGroups := result.workerGroupsRev.reverse }

def psRecursorLiftDeclarations (environment : PsEnvironment)
    (declarations : List PsDeclaration) : Except String PsElabModuleResult :=
  (psRecursorLiftDeclarationsWithOrigins environment declarations).map (·.result)

