import Ps.Core.Abstract
import Ps.Environment.LocalContext
import Ps.Meta.LevelContext

inductive PsMetaVarKind where
  | natural
  | synthetic
  | syntheticOpaque

structure PsMetaVarDecl where
  id : Nat
  type : PsExpr
  localContext : PsLocalContext
  kind : PsMetaVarKind

structure PsMetaAssignment where
  id : Nat
  value : PsExpr

-- A delayed abstraction keeps the open expression until holes that can mention its bound
-- locals are filled. Core and the kernel never receive this elaboration-only metadata.
inductive PsMetaAbstraction where
  | lambdaE (id : Nat) (name : PsName) (type : PsExpr) (binder : PsBinderInfo)
  | forallE (id : Nat) (name : PsName) (type : PsExpr) (binder : PsBinderInfo)
  | letE (id : Nat) (name : PsName) (type value : PsExpr)

structure PsMetaDelayedAssignment where
  id : Nat
  abstractions : List PsMetaAbstraction
  body : PsExpr

structure PsMetaContext where
  nextId : Nat
  declarations : List PsMetaVarDecl
  assignments : List PsMetaAssignment
  levels : PsLevelMetaContext
  delayed : List PsMetaDelayedAssignment := []

structure PsMetaFreshResult where
  context : PsMetaContext
  expr : PsExpr

def psMetaEmpty : PsMetaContext :=
  {
    nextId := 0
    declarations := []
    assignments := []
    levels := psLevelMetaEmpty
  }

def psMetaSnapshot (context : PsMetaContext) : PsMetaContext :=
  context

def psMetaRestore (_current : PsMetaContext) (snapshot : PsMetaContext) : PsMetaContext :=
  snapshot

def psMetaFindDeclInList
    (id : Nat)
    (declarations : List PsMetaVarDecl) : Option PsMetaVarDecl :=
  match declarations with
  | [] => Option.none
  | declaration :: rest =>
      if Nat.beq declaration.id id then
        Option.some declaration
      else
        psMetaFindDeclInList id rest

def psMetaFindDecl (context : PsMetaContext) (id : Nat) : Option PsMetaVarDecl :=
  psMetaFindDeclInList id context.declarations

def psMetaFindAssignmentInList
    (id : Nat)
    (assignments : List PsMetaAssignment) : Option PsExpr :=
  match assignments with
  | [] => Option.none
  | assignment :: rest =>
      if Nat.beq assignment.id id then
        Option.some assignment.value
      else
        psMetaFindAssignmentInList id rest

def psMetaFindAssignment (context : PsMetaContext) (id : Nat) : Option PsExpr :=
  psMetaFindAssignmentInList id context.assignments

def psMetaAssignmentListLength
    (assignments : List PsMetaAssignment) : Nat :=
  match assignments with
  | [] => 0
  | _ :: rest =>
      Nat.succ (psMetaAssignmentListLength rest)

def psMetaFresh
    (context : PsMetaContext)
    (localContext : PsLocalContext)
    (type : PsExpr)
    (kind : PsMetaVarKind) : PsMetaFreshResult :=
  let id := context.nextId;
  let declaration : PsMetaVarDecl := {
    id := id
    type := type
    localContext := localContext
    kind := kind
  };
  {
    context := {
      nextId := Nat.succ id
      declarations := List.cons declaration context.declarations
      assignments := context.assignments
      delayed := context.delayed
      levels := context.levels
    }
    expr := PsExpr.mvar id
  }

def psExprContainsMVar
    (target : Nat)
    (expr : PsExpr) : Bool :=
  match expr with
  | .mvar id => Nat.beq id target
  | .app fn arg =>
      if psExprContainsMVar target fn then
        true
      else
        psExprContainsMVar target arg
  | .lam _ type body _ =>
      if psExprContainsMVar target type then
        true
      else
        psExprContainsMVar target body
  | .forallE _ type body _ =>
      if psExprContainsMVar target type then
        true
      else
        psExprContainsMVar target body
  | .letE _ type value body =>
      if psExprContainsMVar target type then
        true
      else if psExprContainsMVar target value then
        true
      else
        psExprContainsMVar target body
  | .proj _ _ value => psExprContainsMVar target value
  | _ => false

def psExprFVarsInContext
    (localContext : PsLocalContext)
    (expr : PsExpr) : Bool :=
  match expr with
  | .fvar id => psLocalContainsId localContext id
  | .app fn arg =>
      if psExprFVarsInContext localContext fn then
        psExprFVarsInContext localContext arg
      else
        false
  | .lam _ type body _ =>
      if psExprFVarsInContext localContext type then
        psExprFVarsInContext localContext body
      else
        false
  | .forallE _ type body _ =>
      if psExprFVarsInContext localContext type then
        psExprFVarsInContext localContext body
      else
        false
  | .letE _ type value body =>
      if psExprFVarsInContext localContext type then
        if psExprFVarsInContext localContext value then
          psExprFVarsInContext localContext body
        else
          false
      else
        false
  | .proj _ _ value => psExprFVarsInContext localContext value
  | _ => true

def psMetaInstantiateStep
    (context : PsMetaContext)
    (expr : PsExpr) : PsExpr :=
  match expr with
  | .mvar id =>
      match psMetaFindAssignment context id with
      | Option.none => PsExpr.mvar id
      | Option.some value => value
  | .app fn arg =>
      PsExpr.app
        (psMetaInstantiateStep context fn)
        (psMetaInstantiateStep context arg)
  | .lam name type body binder =>
      PsExpr.lam
        name
        (psMetaInstantiateStep context type)
        (psMetaInstantiateStep context body)
        binder
  | .forallE name type body binder =>
      PsExpr.forallE
        name
        (psMetaInstantiateStep context type)
        (psMetaInstantiateStep context body)
        binder
  | .letE name type value body =>
      PsExpr.letE
        name
        (psMetaInstantiateStep context type)
        (psMetaInstantiateStep context value)
        (psMetaInstantiateStep context body)
  | .proj typeName index value =>
      PsExpr.proj
        typeName
        index
        (psMetaInstantiateStep context value)
  | _ => expr

def psMetaExprHasAssignedVar (context : PsMetaContext) (expr : PsExpr) : Bool :=
  match expr with
  | PsExpr.mvar id =>
      match psMetaFindAssignment context id with
      | Option.none => false
      | Option.some _ => true
  | PsExpr.app fn arg =>
      if psMetaExprHasAssignedVar context fn then true else psMetaExprHasAssignedVar context arg
  | PsExpr.lam _ type body _ =>
      if psMetaExprHasAssignedVar context type then true else psMetaExprHasAssignedVar context body
  | PsExpr.forallE _ type body _ =>
      if psMetaExprHasAssignedVar context type then true else psMetaExprHasAssignedVar context body
  | PsExpr.letE _ type value body =>
      if psMetaExprHasAssignedVar context type then true
      else if psMetaExprHasAssignedVar context value then true
      else psMetaExprHasAssignedVar context body
  | PsExpr.proj _ _ value => psMetaExprHasAssignedVar context value
  | _ => false

def psMetaInstantiateRounds
    (context : PsMetaContext)
    (fuel : Nat) : PsExpr -> PsExpr :=
  match fuel with
  | Nat.zero =>
      fun (expr : PsExpr) => expr
  | Nat.succ remaining =>
      fun (expr : PsExpr) =>
        let smaller : PsExpr -> PsExpr :=
          psMetaInstantiateRounds context remaining;
        if psMetaExprHasAssignedVar context expr then
          smaller (psMetaInstantiateStep context expr)
        else expr

def psMetaInstantiate (context : PsMetaContext) (expr : PsExpr) : PsExpr :=
  let value :=
    if psMetaExprHasAssignedVar context expr then
      psMetaInstantiateRounds
        context
        (Nat.add (psMetaAssignmentListLength context.assignments) 1)
        expr
    else expr;
  psLevelInstantiateExpr context.levels value

structure PsMetaFreshLevelResult where
  context : PsMetaContext
  level : PsLevel

def psMetaFreshLevel (context : PsMetaContext) : PsMetaFreshLevelResult :=
  let fresh := psLevelMetaFresh context.levels;
  {
    context := {
      nextId := context.nextId
      declarations := context.declarations
      assignments := context.assignments
      delayed := context.delayed
      levels := fresh.context
    }
    level := fresh.level
  }

def psExprHasTermMeta : PsExpr → Bool
  | .mvar _ => true
  | .app a b | .lam _ a b _ | .forallE _ a b _ =>
    psExprHasTermMeta a || psExprHasTermMeta b
  | .letE _ a b c => psExprHasTermMeta a || psExprHasTermMeta b || psExprHasTermMeta c
  | .proj _ _ value => psExprHasTermMeta value
  | _ => false

def psMetaFindDelayed (context : PsMetaContext) (id : Nat) :
    Option PsMetaDelayedAssignment :=
  context.delayed.find? fun entry => entry.id == id

def psMetaAbstractionTerms : PsMetaAbstraction → List PsExpr
  | .lambdaE _ _ type _ | .forallE _ _ type _ => [type]
  | .letE _ _ type value => [type, value]

def psMetaDelayedTerms (entry : PsMetaDelayedAssignment) : List PsExpr :=
  entry.body :: entry.abstractions.flatMap psMetaAbstractionTerms

def psExprMetaIds : PsExpr → List Nat
  | .mvar id => [id]
  | .app a b | .lam _ a b _ | .forallE _ a b _ => psExprMetaIds a ++ psExprMetaIds b
  | .letE _ a b c => psExprMetaIds a ++ psExprMetaIds b ++ psExprMetaIds c
  | .proj _ _ value => psExprMetaIds value
  | _ => []

-- Occurs checks follow both ordinary and delayed assignments. Checking only
-- the visible proxy would miss a cycle through an unclosed scope.
def psMetaDependsOn (context : PsMetaContext) (fuel target : Nat)
    (ids : List Nat) : Bool :=
  match fuel with
  | 0 => !ids.isEmpty
  | fuel + 1 => ids.any fun id =>
    if id == target then true else
    let terms := match psMetaFindAssignment context id with
      | some value => [value]
      | none => match psMetaFindDelayed context id with
        | some entry => psMetaDelayedTerms entry
        | none => []
    psMetaDependsOn context fuel target (terms.flatMap psExprMetaIds)

def psMetaCloseAbstractions (context : PsMetaContext)
    (abstractions : List PsMetaAbstraction) (body : PsExpr) : PsExpr :=
  abstractions.foldl (fun body entry =>
    match entry with
    | .lambdaE id name type binder =>
      .lam name (psMetaInstantiate context type) (psExprAbstractFVar id body) binder
    | .forallE id name type binder =>
      .forallE name (psMetaInstantiate context type) (psExprAbstractFVar id body) binder
    | .letE id name type value =>
      .letE name (psMetaInstantiate context type) (psMetaInstantiate context value)
        (psExprAbstractFVar id body)) (psMetaInstantiate context body)

def psMetaAbstractionId : PsMetaAbstraction → Nat
  | .lambdaE id _ _ _ | .forallE id _ _ _ | .letE id _ _ _ => id

-- An unsolved metavariable already confined to the outer scope is safe to
-- retain. Only holes that could mention a removed local delay abstraction.
def psMetaTryClose (context : PsMetaContext) (entry : PsMetaDelayedAssignment) : Option PsExpr :=
  let removed := entry.abstractions.map psMetaAbstractionId
  let pending := (psMetaDelayedTerms entry).flatMap fun term =>
    psExprMetaIds (psMetaInstantiate context term)
  if pending.any (fun id => match psMetaFindDecl context id with
      | none => true
      | some declaration => removed.any (psLocalContainsId declaration.localContext)) then none
  else some (psMetaCloseAbstractions context entry.abstractions entry.body)

-- Natural inference holes may be confined to a smaller context when their
-- types permit it. Proof goals and delayed scopes retain their captured context.
-- This prevents an alias assignment from hiding a future escaping free local.
def psMetaRestrictScope (fuel : Nat) (context : PsMetaContext)
    (localContext : PsLocalContext) (value : PsExpr) : Option PsMetaContext := do
  match fuel with
  | 0 => none
  | fuel + 1 =>
    let value := psMetaInstantiate context value
    if !psExprFVarsInContext localContext value then none else
    (psExprMetaIds value).foldlM (fun current id => do
      let some declaration := psMetaFindDecl current id | none
      if declaration.localContext.declarations.all
          (fun localDecl => psLocalContainsId localContext (psLocalDeclId localDecl)) then
        return current
      match declaration.kind with
      | .syntheticOpaque => none
      | _ =>
        if (psMetaFindDelayed current id).isSome then none else
        let narrowed := {
          declaration.localContext with declarations := declaration.localContext.declarations.filter
            (fun localDecl => psLocalContainsId localContext (psLocalDeclId localDecl)) }
        let current ← psMetaRestrictScope fuel current narrowed declaration.type
        return { current with declarations := current.declarations.map fun entry =>
          if entry.id == id then { entry with localContext := narrowed } else entry }) context

-- An assignment can finish several nested scopes. Each productive pass removes
-- a pending entry; the pending count bounds the work without a magic depth cap.
def psMetaNormalizeDelayed (fuel : Nat) (context : PsMetaContext) : Option PsMetaContext := do
  match fuel with
  | 0 => return context
  | fuel + 1 =>
    let mut current := context
    let mut pending := []
    for entry in context.delayed do
      match psMetaTryClose current entry with
      | none => pending := entry :: pending
      | some value =>
        let some declaration := psMetaFindDecl current entry.id | none
        let scoped ← psMetaRestrictScope (current.nextId + 1) current declaration.localContext value
        current := { scoped with assignments := { id := entry.id, value } :: scoped.assignments }
    current := { current with delayed := pending.reverse }
    if current.delayed.length == context.delayed.length then return current
    psMetaNormalizeDelayed fuel current

def psMetaAssign (context : PsMetaContext) (id : Nat) (value : PsExpr) : Option PsMetaContext := do
  let some declaration := psMetaFindDecl context id | none
  if (psMetaFindAssignment context id).isSome || (psMetaFindDelayed context id).isSome then none else
  let value := psMetaInstantiate context value
  if psMetaDependsOn context (context.nextId + 1) id (psExprMetaIds value) then none else
  let context ← psMetaRestrictScope (context.nextId + 1) context declaration.localContext value
  let next := { context with assignments := { id, value } :: context.assignments }
  psMetaNormalizeDelayed context.delayed.length next

def psMetaAssignDelayed (context : PsMetaContext) (id : Nat)
    (abstractions : List PsMetaAbstraction) (body : PsExpr) : Option PsMetaContext := do
  let some _ := psMetaFindDecl context id | none
  if (psMetaFindAssignment context id).isSome || (psMetaFindDelayed context id).isSome then none else
  let entry : PsMetaDelayedAssignment := { id, abstractions, body }
  if psMetaDependsOn context (context.nextId + 1) id
      ((psMetaDelayedTerms entry).flatMap psExprMetaIds) then none else
  let next := { context with delayed := entry :: context.delayed }
  psMetaNormalizeDelayed next.delayed.length next

def psExprHasUnresolvedMeta
    (expr : PsExpr) : Bool :=
  match expr with
  | .mvar _ => true
  | .sortE level => psLevelHasMVar level
  | .constE _ levels => psLevelListHasMVar levels
  | .app fn arg =>
      if psExprHasUnresolvedMeta fn then
        true
      else
        psExprHasUnresolvedMeta arg
  | .lam _ type body _ =>
      if psExprHasUnresolvedMeta type then
        true
      else
        psExprHasUnresolvedMeta body
  | .forallE _ type body _ =>
      if psExprHasUnresolvedMeta type then
        true
      else
        psExprHasUnresolvedMeta body
  | .letE _ type value body =>
      if psExprHasUnresolvedMeta type then
        true
      else if psExprHasUnresolvedMeta value then
        true
      else
        psExprHasUnresolvedMeta body
  | .proj _ _ value => psExprHasUnresolvedMeta value
  | _ => false
