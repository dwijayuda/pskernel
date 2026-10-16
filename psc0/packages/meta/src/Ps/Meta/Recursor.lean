import Ps.Meta.Iota
import Ps.Core.Abstract
import Ps.Core.Equality
import Ps.Environment.LocalContext

-- One layout owns the common motive/minor prefix and the selected family's
-- varying telescope. The legacy singleton view below remains a strict subset.
structure PsGroupRecursorApplication where
  info : PsRecursorInfo
  family : PsInductiveInfo
  group : PsInductiveGroupPlan
  head : PsExpr
  fixedArgs : List PsExpr
  indices : List PsExpr
  major : PsExpr
  suffix : List PsExpr

def psGroupRecursorApplication (environment : PsEnvironment) (expr : PsExpr) :
    Option PsGroupRecursorApplication := do
  let view := psReduceAppView expr
  let .constE name levels := view.head | none
  let info ← psEnvironmentFindRecursor environment name
  let familyName ← info.inductiveNames.find?
    (fun family => psNameEq name (psNameAppendStr family "rec"))
  let family ← psEnvironmentFindInductive environment familyName
  let group ← psInductiveGroupPlanFor
    (psEnvironmentFindInductive environment) (psEnvironmentFindRecursor environment) family
  if !psInductiveGroupRecursorShapeValid group family info ||
      levels.length != info.levelParams.length then none else do
    let prefixSize := info.numParams + info.numMotives + info.numMinors
    let major ← view.args[prefixSize + info.numIndices]?
    return {
      info, family, group, head := view.head, fixedArgs := view.args.take prefixSize
      indices := (view.args.drop prefixSize).take info.numIndices
      major, suffix := view.args.drop (prefixSize + info.numIndices + 1)
    }

-- The single-family recursor contract is shared by preparation and runtime
-- lowering. It does not infer recursion from a name or constructor spelling.
structure PsRecursorApplication where
  info : PsRecursorInfo
  family : PsInductiveInfo
  head : PsExpr
  fixedArgs : List PsExpr
  indices : List PsExpr
  major : PsExpr
  suffix : List PsExpr

def psRecursorApplication (environment : PsEnvironment) (expr : PsExpr) :
    Option PsRecursorApplication := do
  let view ← psGroupRecursorApplication environment expr
  if view.group.members.length != 1 then none else
    return {
      info := view.info, family := view.family, head := view.head
      fixedArgs := view.fixedArgs, indices := view.indices, major := view.major
      suffix := view.suffix
    }

def psRecursorContainsLocal (id : Nat) (expr : PsExpr) : Bool :=
  !(psExprAlphaEq expr (psExprAbstractFVar id expr))

def psRecursorVaryingLocals (major : PsExpr) (indices minors : List PsExpr) :
    Option (List Nat) := do
  let ids ← (major :: indices).mapM fun expr =>
    match expr with
    | .fvar id => some id
    | _ => none
  if ids.eraseDups.length != ids.length ||
      minors.any (fun minor => ids.any (fun id => psRecursorContainsLocal id minor)) then none
  else some ids

def psRecursorUsesBound (expr : PsExpr) (count depth : Nat) : Bool :=
  match expr with
  | .bvar index => depth <= index && index < depth + count
  | .app fn arg => psRecursorUsesBound fn count depth || psRecursorUsesBound arg count depth
  | .lam _ type body _ | .forallE _ type body _ =>
    psRecursorUsesBound type count depth || psRecursorUsesBound body count (depth + 1)
  | .letE _ type value body =>
    psRecursorUsesBound type count depth || psRecursorUsesBound value count depth ||
      psRecursorUsesBound body count (depth + 1)
  | .proj _ _ value => psRecursorUsesBound value count depth
  | _ => false

def psRecursorStripLambdas (count : Nat) (expr : PsExpr) : Option PsExpr :=
  match count with
  | 0 => some expr
  | count + 1 =>
    match expr with
    | .lam _ _ body _ => psRecursorStripLambdas count body
    | _ => none

def psRecursorUsesHypotheses (environment : PsEnvironment)
    (view : PsRecursorApplication) : Bool :=
  view.family.constructors.zipIdx |>.any fun entry =>
    match psEnvironmentFindConstructor environment entry.fst,
        view.fixedArgs[view.info.numParams + 1 + entry.snd]? with
    | some ctor, some minor =>
      if ctor.recursiveFields.isEmpty then false else
        match psRecursorStripLambdas (ctor.numFields + ctor.recursiveFields.length) minor with
        | some body => psRecursorUsesBound body ctor.recursiveFields.length 0
        | none => true
    | _, _ => false

def psGroupRecursorUsesHypotheses (environment : PsEnvironment)
    (view : PsGroupRecursorApplication) : Bool :=
  (view.group.members.flatMap (·.constructors)).zipIdx |>.any fun entry =>
    match psEnvironmentFindConstructor environment entry.fst,
        view.fixedArgs[view.info.numParams + view.info.numMotives + entry.snd]? with
    | some ctor, some minor =>
      if ctor.recursiveFields.isEmpty then false else
        match psRecursorStripLambdas (ctor.numFields + ctor.recursiveFields.length) minor with
        | some body => psRecursorUsesBound body ctor.recursiveFields.length 0
        | none => true
    | _, _ => true

-- These records locate ordinary checked definitions. They are not admission
-- evidence: before erasure the complete equations below are reconstructed from
-- the retained declarations and compared, including all lexical captures.
structure PsRecursorWorker where
  family : PsName
  name : PsName

structure PsRecursorWorkerGroup where
  workers : List PsRecursorWorker
  captureCount : Nat

def psRecursorExprsEqual (left right : List PsExpr) : Bool :=
  left.length == right.length && (left.zip right).all (fun pair => psExprAlphaEq pair.1 pair.2)

structure PsRecursorWorkerTelescope where
  locals : PsLocalContext
  binders : List (PsExpr × PsBinderInfo)
  arguments : List PsExpr
  type : PsExpr
  value : PsExpr

def psRecursorOpenWorker (fuel count : Nat) (locals : PsLocalContext)
    (type value : PsExpr) : Option PsRecursorWorkerTelescope := do
  match count, fuel with
  | 0, _ => return { locals, binders := [], arguments := [], type, value }
  | _, 0 => none
  | count + 1, fuel + 1 =>
    let .forallE name domain typeBody binder := type | none
    let .lam _ valueDomain valueBody valueBinder := value | none
    if !psExprAlphaEq domain valueDomain || !psBinderInfoEq binder valueBinder then none else do
      let pushed := psLocalPushBinding locals name domain binder
      let argument := PsExpr.fvar pushed.id
      let rest ← psRecursorOpenWorker fuel count pushed.context
        (psExprInstantiate1 typeBody argument) (psExprInstantiate1 valueBody argument)
      return { rest with
        binders := (domain, binder) :: rest.binders
        arguments := argument :: rest.arguments
      }

structure PsRecursorWorkerView where
  levels : List PsName
  captures : List (PsExpr × PsBinderInfo)
  recursorLevels : List PsLevel
  application : PsGroupRecursorApplication

def psRecursorWorkerView (environment : PsEnvironment) (captureCount : Nat)
    (worker : PsRecursorWorker) : Option PsRecursorWorkerView := do
  let some (.definitionDecl name levels type value) := psEnvironmentFind environment worker.name | none
  if !psNameEq name worker.name then none else do
    let family ← psEnvironmentFindInductive environment worker.family
    let opened ← psRecursorOpenWorker 4096 (captureCount + family.numIndices + 1)
      psLocalEmpty type value
    let application ← psGroupRecursorApplication environment opened.value
    if application.group.members.length < 2 || !psNameEq application.family.name worker.family ||
        !application.suffix.isEmpty ||
        !psRecursorExprsEqual (application.indices ++ [application.major])
          (opened.arguments.drop captureCount) then none else do
      let varying := (opened.arguments.drop captureCount).filterMap fun expr =>
        match expr with | .fvar id => some id | _ => none
      if application.fixedArgs.any (fun argument =>
          varying.any (fun id => psRecursorContainsLocal id argument)) then none else do
        let .constE _ recursorLevels := application.head | none
        return {
          levels, captures := opened.binders.take captureCount
          recursorLevels, application
        }

def psValidateRecursorWorkerGroups (environment : PsEnvironment)
    (groups : List PsRecursorWorkerGroup) : Except String Unit := do
  let names := groups.flatMap fun group => group.workers.map (·.name)
  if names.any (fun name => (names.filter (psNameEq name)).length != 1) then
    throw "recursor workers have duplicate retained identities"
  for group in groups do
    let first :: _ := group.workers | throw "empty recursor worker group"
    let some anchor := psRecursorWorkerView environment group.captureCount first
      | throw "recursor worker does not retain its exact group equation"
    if !psInductiveGroupNamesEqual (group.workers.map (·.family))
        (psInductiveGroupNames anchor.application.group) then
      throw "recursor workers do not cover the complete ordered group"
    for worker in group.workers do
      let some view := psRecursorWorkerView environment group.captureCount worker
        | throw "recursor worker does not retain its exact group equation"
      if !psInductiveGroupNamesEqual view.levels anchor.levels ||
          !psInductiveGroupNamesEqual (psInductiveGroupNames view.application.group)
            (psInductiveGroupNames anchor.application.group) ||
          !psRecursorExprsEqual (view.recursorLevels.map PsExpr.sortE)
            (anchor.recursorLevels.map PsExpr.sortE) ||
          view.captures.length != anchor.captures.length ||
          !(view.captures.zip anchor.captures).all (fun pair =>
            psExprAlphaEq pair.1.1 pair.2.1 && psBinderInfoEq pair.1.2 pair.2.2) ||
          !psRecursorExprsEqual view.application.fixedArgs anchor.application.fixedArgs then
        throw "recursor workers disagree on captured parameters, motives or minors"

def psRecursorWorkerBetaApply (value : PsExpr) (arguments : List PsExpr) : Option PsExpr := do
  match arguments with
  | [] => return value
  | argument :: rest =>
    let .lam _ _ body _ := value | none
    psRecursorWorkerBetaApply (psExprInstantiate1 body argument) rest

