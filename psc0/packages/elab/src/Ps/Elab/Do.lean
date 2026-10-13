import Ps.Elab.PatternMatrix
import Ps.Elab.Conditional

-- The controller only uses these typed operations. The current registered
-- families have checked constructor/recursor semantics, with no new axioms.
-- Class-based effects can supply the same operations without changing control.
inductive PsElabDoOps where
  | identity
  | option
  | except (error : PsExpr)

-- Construct the effect type through ordinary universe constraints. A bind
-- may change element universe, so the Option universe belongs to each value
-- type, not to a hardcoded Type-0 operation or the surrounding return type.
def psElabDoType (context : PsElabContext) (ops : PsElabDoOps)
    (type : PsExpr) : Except PsElabError PsElabTypeResult := do
  match ops with
  | .identity => return { context, type }
  | .option =>
    let sort ← psElabExpressionSort context type
    let fresh := psMetaFreshLevel context.metaContext
    let unified := psUnify context.environment context.localContext fresh.context
      (.sortE sort) (.sortE (.succ fresh.level))
    if !unified.success then throw .typeMismatch
    return {
      context := psElabContextWithMeta context unified.context
      type := .app (.constE psOptionName
        [psLevelInstantiate unified.context.levels fresh.level]) type }
  | .except error =>
    return { context
      type := psExprApplyMany (.constE (psRootName "Except") []) [error, type] }

-- Expose aliases one head at a time, stopping before Id erases the effect
-- choice. Full WHNF would confuse Id (Option A) with the Option effect.
def psElabDoView (fuel : Nat) (context : PsElabContext) (type : PsExpr) : PsExpr :=
  match fuel with
  | 0 => type
  | fuel + 1 =>
    let core := psWhnfCore context.metaContext context.localContext type
    let view := psExprAppView core
    match view.head with
    | .constE name levels =>
      if [psRootName "Id", psRootName "Except", psOptionName].any (psNameEq name) then core
      else match psEnvironmentFind context.environment name with
        | some declaration => match psDeclarationValue declaration with
          | some value =>
            let value := psExprInstantiateLevelParams (psDeclarationLevelParams declaration) levels value
            psElabDoView fuel context (psExprApplyMany value view.args)
          | none => core
        | none => core
    | _ => core

def psElabDoSelect (context : PsElabContext) (expected : Option PsExpr) :
    Except PsElabError (PsElabDoOps × PsExpr) := do
  let some expected := expected | throw (.invalidArgument "do requires an expected result type")
  let type := psElabDoView 256 context expected
  let view := psExprAppView type
  match view.head, view.args with
  | .constE name _, [error, value] =>
    if psNameEq name (psRootName "Except") then return (.except error, value)
    return (.identity, type)
  | .constE name _, [value] =>
    if psNameEq name (psRootName "Id") then return (.identity, value)
    if psNameEq name psOptionName then return (.option, value)
    return (.identity, type)
  | .mvar _, _ => throw (.invalidArgument "do effect is not determined by its expected type")
  | _, _ => return (.identity, type)

def psElabDoPure (ops : PsElabDoOps) (context : PsElabContext)
    (type value : PsExpr) : Except PsElabError PsElabTermResult := do
  let wrapped ← psElabDoType context ops type
  let term := match ops with
    | .identity => value
    | .option =>
      let levels := match (psExprAppView wrapped.type).head with
        | .constE _ levels => levels
        | _ => []
      psExprApplyMany (.constE (psNameAppendStr psOptionName "some") levels) [type, value]
    | .except error =>
      psExprApplyMany (.constE (psNameAppendStr (psRootName "Except") "ok") []) [error, type, value]
  psElabResolvedTerm wrapped.context term (some wrapped.type)

def psElabDoBind (ops : PsElabDoOps) (context : PsElabContext)
    (alpha beta action continuation : PsExpr) : Except PsElabError PsElabTermResult := do
  let result ← psElabDoType context ops beta
  let input ← psElabDoType result.context ops alpha
  let level ← psElabExpressionSort input.context result.type
  let motive := PsExpr.lam (psRootName "_") input.type
    (psExprLiftBVars 1 0 result.type) .explicit
  let term := match ops with
    | .identity => .app continuation action
    | .option =>
      let sourceLevels := match (psExprAppView input.type).head with
        | .constE _ levels => levels
        | _ => []
      let resultLevels := match (psExprAppView result.type).head with
        | .constE _ levels => levels
        | _ => []
      let noneValue := psExprApplyMany
        (.constE (psNameAppendStr psOptionName "none") resultLevels) [beta]
      psExprApplyMany (.constE (psNameAppendStr psOptionName "rec") (level :: sourceLevels))
        [alpha, motive, noneValue, continuation, action]
    | .except error =>
      let errorValue := psExprApplyMany (.constE (psNameAppendStr (psRootName "Except") "error") [])
        [psExprLiftBVars 1 0 error, psExprLiftBVars 1 0 beta, .bvar 0]
      let errorBranch := PsExpr.lam (psRootName "error") error errorValue .explicit
      psExprApplyMany (.constE (psNameAppendStr (psRootName "Except") "rec") [level])
        [error, alpha, motive, errorBranch, continuation, action]
  psElabResolvedTerm input.context term (some result.type)

abbrev PsElabDoContinuation := PsElabContext → Except PsElabError PsElabTermResult

def psElabDoFinish (ops : PsElabDoOps) (result : PsExpr)
    (next : Option PsElabDoContinuation) (context : PsElabContext) :
    Except PsElabError PsElabTermResult := do
  match next with
  | some next => next context
  | none =>
    let value ← psElabUnit context (some result)
    psElabDoPure ops value.context result value.term

def psElabDoThen (ops : PsElabDoOps) (beta : PsExpr) (action : PsElabTermResult)
    (alpha : PsExpr) (name : PsName) (next : Nat → PsElabDoContinuation) :
    Except PsElabError PsElabTermResult := do
  let pushed := psLocalPushBinding action.context.localContext name alpha .explicit
  let body ← next pushed.id (psElabContextWithLocal action.context pushed.context)
  let wrapped ← psElabDoType body.context ops beta
  let type := PsExpr.forallE name alpha (psExprLiftBVars 1 0 wrapped.type) .explicit
  let closed ← psElabAbstract action.context wrapped.context
    [.lambdaE pushed.id name alpha .explicit] body.term type
  psElabDoBind ops closed.context alpha beta action.term closed.term

-- A branch continuation is a single checked local function. Branches call it;
-- its syntax, elaboration and runtime body are never copied per branch.
def psElabDoJoin (context : PsElabContext) (tail : PsElabDoContinuation)
    (branches : PsElabContext → PsElabDoContinuation →
      Except PsElabError PsElabTermResult) : Except PsElabError PsElabTermResult := do
  let body ← tail context
  let unit := PsExpr.constE psUnitName []
  let name := PsName.num (psRootName "$psc0DoJoin") body.context.localContext.nextId
  let type := PsExpr.forallE (psRootName "_") unit (psExprLiftBVars 1 0 body.type) .explicit
  let value := PsExpr.lam (psRootName "_") unit (psExprLiftBVars 1 0 body.term) .explicit
  let pushed := psLocalPushLet body.context.localContext name type value
  let inner := psElabContextWithLocal body.context pushed.context
  let next : PsElabDoContinuation := fun current =>
    psElabResolvedTerm current (.app (.fvar pushed.id) (.constE psUnitUnitName [])) (some body.type)
  let result ← branches inner next
  psElabCloseLetScope context result pushed.id name type value (some body.type)

-- Pattern-matrix row aliases are ordinary lets. Only the branch root's do
-- payload belongs to this controller; nested do terms use a new return scope.
def psElabDoBranch (fuel : Nat) (elaborate : PsElaborator)
    (body : List PsSyntaxDoItem → PsElabContext → Option PsExpr →
      Except PsElabError PsElabTermResult) : PsElaborator :=
  match fuel with
  | 0 => fun _ _ _ => .error .fuelExhausted
  | fuel + 1 => fun context term expected => do
    match term with
    | .doE items _ => body items context expected
    | .letE name type value rest _ =>
      let value ← psElabLocalValue elaborate context type value
      let some name := psSyntaxNameToName name | throw .emptyName
      psElabLetAfterValue (psElabDoBranch fuel elaborate body) context name value.type value rest expected
    | _ => elaborate context term expected

def psElabDoItems (fuel : Nat) (elaborate : PsElaborator)
    (ops : PsElabDoOps) (result : PsExpr) (next : Option PsElabDoContinuation)
    (context : PsElabContext) (items : List PsSyntaxDoItem) :
    Except PsElabError PsElabTermResult := do
  match fuel with
  | 0 => throw .fuelExhausted
  | fuel + 1 => match items with
    | [] => psElabDoFinish ops result next context
    | item :: rest =>
      let tail := fun current => psElabDoItems fuel elaborate ops result next current rest
      let branch := fun next => psElabDoBranch fuel elaborate fun items current expected => do
        let some branchType := expected | throw (.invalidArgument "missing do branch type")
        let fresh := psElabFreshType current
        let wrapped ← psElabDoType fresh.context ops fresh.type
        let unified := psUnify current.environment current.localContext wrapped.context.metaContext
          wrapped.type branchType
        if !unified.success then throw .typeMismatch
        let current := psElabContextWithMeta current unified.context
        psElabDoItems fuel elaborate ops (psMetaInstantiate unified.context fresh.type) next current items
      let wrapped ← psElabDoType context ops result
      let context := wrapped.context
      let expected := some wrapped.type
      match item with
      | .returnValue value _ =>
        let value ← elaborate context value (some result)
        psElabDoPure ops value.context result value.term
      | .action value _ =>
        if rest.isEmpty && next.isNone then elaborate context value expected
        else
          let unit := PsExpr.constE psUnitName []
          let wrapped ← psElabDoType context ops unit
          let action ← elaborate wrapped.context value (some wrapped.type)
          psElabDoThen ops result action unit (psRootName "_") (fun _ => tail)
      | .binding pattern annotation value monadic span =>
        let syntaxName := match pattern with
          | .variable name => name
          | _ => PsSyntaxName.mk ["$psc0DoValue", psNatToString context.localContext.nextId] span
        let some name := psSyntaxNameToName syntaxName | throw .emptyName
        let bindBody : PsElabDoContinuation := fun current =>
          match pattern with
          | .variable _ | .wildcard _ => tail current
          | _ => psElabMatchMatrixWith elaborate (branch next) current [.reference syntaxName]
              [([pattern], .doE rest span, span)] expected
        if monadic then
          let type ← match annotation with
            | some annotation => psElabType elaborate context annotation
            | none => pure (psElabFreshType context)
          let wrapped ← psElabDoType type.context ops type.type
          let action ← elaborate wrapped.context value (some wrapped.type)
          psElabDoThen ops result action type.type name (fun _ => bindBody)
        else
          let value ← psElabLocalValue elaborate context annotation value
          let pushed := psLocalPushLet value.context.localContext name value.type value.term
          let body ← bindBody (psElabContextWithLocal value.context pushed.context)
          psElabCloseLetScope context body pushed.id name value.type value.term expected
      | .conditional name condition yes no span =>
        let branches := fun current continuation =>
          psElabIfWith elaborate (branch continuation) current name condition
            (.doE yes span) (.doE no span) expected
        if rest.isEmpty then branches context next
        else psElabDoJoin context tail (fun current continuation => branches current (some continuation))
      | .conditionalPattern pattern value yes no span =>
        let branches := fun current continuation =>
          psElabMatchMatrixWith elaborate (branch continuation) current [value]
            [([pattern], .doE yes span, span), ([.wildcard span], .doE no span, span)] expected
        if rest.isEmpty then branches context next
        else psElabDoJoin context tail (fun current continuation => branches current (some continuation))

def psElabDo (elaborate : PsElaborator) (context : PsElabContext)
    (items : List PsSyntaxDoItem) (expected : Option PsExpr) :
    Except PsElabError PsElabTermResult := do
  let (ops, result) ← psElabDoSelect context expected
  let value ← psElabDoItems 4096 elaborate ops result none context items
  psElabFinalizeExpected value expected
