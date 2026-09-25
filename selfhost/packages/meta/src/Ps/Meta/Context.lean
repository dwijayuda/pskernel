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

def psMetaFindDeclInList (id : Nat) : List PsMetaVarDecl -> Option PsMetaVarDecl
  | [] => Option.none
  | declaration :: rest =>
      if Nat.beq declaration.id id then
        Option.some declaration
      else
        psMetaFindDeclInList id rest

def psMetaFindDecl (context : PsMetaContext) (id : Nat) : Option PsMetaVarDecl :=
  psMetaFindDeclInList id context.declarations

def psMetaFindAssignmentInList (id : Nat) : List PsMetaAssignment -> Option PsExpr
  | [] => Option.none
  | assignment :: rest =>
      if Nat.beq assignment.id id then
        Option.some assignment.value
      else
        psMetaFindAssignmentInList id rest

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

def psExprContainsMVar (target : Nat) : PsExpr -> Bool
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
      else
        psExprContainsMVar target value
          || psExprContainsMVar target body
  | .proj _ _ value => psExprContainsMVar target value
  | _ => false

def psExprFVarsInContext (localContext : PsLocalContext) : PsExpr -> Bool
  | .fvar id => psLocalContainsId localContext id
  | .app fn arg =>
      psExprFVarsInContext localContext fn && psExprFVarsInContext localContext arg
  | .lam _ type body _ =>
      psExprFVarsInContext localContext type && psExprFVarsInContext localContext body
  | .forallE _ type body _ =>
      psExprFVarsInContext localContext type && psExprFVarsInContext localContext body
  | .letE _ type value body =>
      psExprFVarsInContext localContext type
        && psExprFVarsInContext localContext value
        && psExprFVarsInContext localContext body
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
      (context.assignments.length + 1)
      expr
  psLevelInstantiateExpr context.levels value

structure PsMetaFreshLevelResult where
  context : PsMetaContext
  level : PsLevel

def psMetaFreshLevel (context : PsMetaContext) : PsMetaFreshLevelResult :=
  let fresh := psLevelMetaFresh context.levels
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
          let resolved := psMetaInstantiate context value
          if psExprContainsMVar id resolved then
            Option.none
          else if psExprFVarsInContext declaration.localContext resolved then
            Option.some {
              nextId := context.nextId
              declarations := context.declarations
              assignments := List.cons { id := id, value := resolved } context.assignments
              levels := context.levels
            }
          else
            Option.none

def psExprHasUnresolvedMeta : PsExpr -> Bool
  | .mvar _ => true
  | .sortE level => psLevelHasMVar level
  | .constE _ levels => psLevelListHasMVar levels
  | .app fn arg =>
      psExprHasUnresolvedMeta fn || psExprHasUnresolvedMeta arg
  | .lam _ type body _ =>
      psExprHasUnresolvedMeta type || psExprHasUnresolvedMeta body
  | .forallE _ type body _ =>
      psExprHasUnresolvedMeta type || psExprHasUnresolvedMeta body
  | .letE _ type value body =>
      psExprHasUnresolvedMeta type
        || psExprHasUnresolvedMeta value
        || psExprHasUnresolvedMeta body
  | .proj _ _ value => psExprHasUnresolvedMeta value
  | _ => false
