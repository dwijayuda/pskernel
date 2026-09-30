import Ps.Core.Expr
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

structure PsMetaContext where
  nextId : Nat
  declarations : List PsMetaVarDecl
  assignments : List PsMetaAssignment
  levels : PsLevelMetaContext

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

def psMetaFindDeclInListWorker
    (declarations : List PsMetaVarDecl) :
    Nat -> Option PsMetaVarDecl :=
  match declarations with
  | [] =>
      fun (_id : Nat) => Option.none
  | declaration :: rest =>
      let smaller : Nat -> Option PsMetaVarDecl :=
        psMetaFindDeclInListWorker rest;
      fun (id : Nat) =>
        if Nat.beq declaration.id id then
          Option.some declaration
        else
          smaller id

def psMetaFindDeclInList
    (id : Nat)
    (declarations : List PsMetaVarDecl) : Option PsMetaVarDecl :=
  psMetaFindDeclInListWorker declarations id

def psMetaFindDecl (context : PsMetaContext) (id : Nat) : Option PsMetaVarDecl :=
  psMetaFindDeclInList id context.declarations

def psMetaFindAssignmentInListWorker
    (assignments : List PsMetaAssignment) :
    Nat -> Option PsExpr :=
  match assignments with
  | [] =>
      fun (_id : Nat) => Option.none
  | assignment :: rest =>
      let smaller : Nat -> Option PsExpr :=
        psMetaFindAssignmentInListWorker rest;
      fun (id : Nat) =>
        if Nat.beq assignment.id id then
          Option.some assignment.value
        else
          smaller id

def psMetaFindAssignmentInList
    (id : Nat)
    (assignments : List PsMetaAssignment) : Option PsExpr :=
  psMetaFindAssignmentInListWorker assignments id

def psMetaFindAssignment (context : PsMetaContext) (id : Nat) : Option PsExpr :=
  psMetaFindAssignmentInList id context.assignments

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
      levels := context.levels
    }
    expr := PsExpr.mvar id
  }

def psExprContainsMVarWorker
    (expr : PsExpr) : Nat -> Bool :=
  match expr with
  | .mvar id =>
      fun (target : Nat) => Nat.beq id target
  | .app fn arg =>
      let fnContains : Nat -> Bool := psExprContainsMVarWorker fn;
      let argContains : Nat -> Bool := psExprContainsMVarWorker arg;
      fun (target : Nat) =>
        if fnContains target then
          true
        else
          argContains target
  | .lam _ type body _ =>
      let typeContains : Nat -> Bool := psExprContainsMVarWorker type;
      let bodyContains : Nat -> Bool := psExprContainsMVarWorker body;
      fun (target : Nat) =>
        if typeContains target then
          true
        else
          bodyContains target
  | .forallE _ type body _ =>
      let typeContains : Nat -> Bool := psExprContainsMVarWorker type;
      let bodyContains : Nat -> Bool := psExprContainsMVarWorker body;
      fun (target : Nat) =>
        if typeContains target then
          true
        else
          bodyContains target
  | .letE _ type value body =>
      let typeContains : Nat -> Bool := psExprContainsMVarWorker type;
      let valueContains : Nat -> Bool := psExprContainsMVarWorker value;
      let bodyContains : Nat -> Bool := psExprContainsMVarWorker body;
      fun (target : Nat) =>
        if typeContains target then
          true
        else if valueContains target then
          true
        else
          bodyContains target
  | .proj _ _ value =>
      let valueContains : Nat -> Bool := psExprContainsMVarWorker value;
      fun (target : Nat) => valueContains target
  | _ =>
      fun (_target : Nat) => false

def psExprContainsMVar (target : Nat) (expr : PsExpr) : Bool :=
  psExprContainsMVarWorker expr target

def psExprFVarsInContext (localContext : PsLocalContext) : PsExpr -> Bool
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
    (context : PsMetaContext) : PsExpr -> PsExpr
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
  | expr => expr

def psMetaInstantiateRounds
    (context : PsMetaContext) :
    Nat -> PsExpr -> PsExpr
  | 0, expr => expr
  | remaining + 1, expr =>
      psMetaInstantiateRounds
        context
        remaining
        (psMetaInstantiateStep context expr)

def psMetaInstantiate (context : PsMetaContext) (expr : PsExpr) : PsExpr :=
  let value :=
    psMetaInstantiateRounds
      context
      (Nat.add context.assignments.length 1)
      expr;
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
      levels := fresh.context
    }
    level := fresh.level
  }

def psMetaAssign (context : PsMetaContext) (id : Nat) (value : PsExpr) : Option PsMetaContext :=
  match psMetaFindDecl context id with
  | Option.none => Option.none
  | Option.some declaration =>
      match psMetaFindAssignment context id with
      | Option.some _ => Option.none
      | Option.none =>
          let resolved := psMetaInstantiate context value;
          if psExprContainsMVar id resolved then
            Option.none
          else if psExprFVarsInContext declaration.localContext resolved then
            let assignment : PsMetaAssignment := {
              id := id
              value := resolved
            };
            Option.some {
              nextId := context.nextId
              declarations := context.declarations
              assignments := List.cons assignment context.assignments
              levels := context.levels
            }
          else
            Option.none

def psExprHasUnresolvedMeta : PsExpr -> Bool
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
