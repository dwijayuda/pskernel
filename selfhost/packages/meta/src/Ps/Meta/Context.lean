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
  | [] => none
  | declaration :: rest =>
      if declaration.id == id then
        some declaration
      else
        psMetaFindDeclInList id rest

def psMetaFindDecl (context : PsMetaContext) (id : Nat) : Option PsMetaVarDecl :=
  psMetaFindDeclInList id context.declarations

def psMetaFindAssignmentInList (id : Nat) : List PsMetaAssignment -> Option PsExpr
  | [] => none
  | assignment :: rest =>
      if assignment.id == id then
        some assignment.value
      else
        psMetaFindAssignmentInList id rest

def psMetaFindAssignment (context : PsMetaContext) (id : Nat) : Option PsExpr :=
  psMetaFindAssignmentInList id context.assignments

def psMetaFresh
    (context : PsMetaContext)
    (localContext : PsLocalContext)
    (type : PsExpr)
    (kind : PsMetaVarKind) : PsMetaFreshResult :=
  let id := context.nextId
  let declaration : PsMetaVarDecl := {
    id := id
    type := type
    localContext := localContext
    kind := kind
  }
  {
    context := {
      nextId := id + 1
      declarations := declaration :: context.declarations
      assignments := context.assignments
      levels := context.levels
    }
    expr := PsExpr.mvar id
  }

def psExprContainsMVar (target : Nat) : PsExpr -> Bool
  | .mvar id => id == target
  | .app fn arg =>
      psExprContainsMVar target fn || psExprContainsMVar target arg
  | .lam _ type body _ =>
      psExprContainsMVar target type || psExprContainsMVar target body
  | .forallE _ type body _ =>
      psExprContainsMVar target type || psExprContainsMVar target body
  | .letE _ type value body =>
      psExprContainsMVar target type
        || psExprContainsMVar target value
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

def psMetaInstantiateWithFuel (context : PsMetaContext) : Nat -> PsExpr -> PsExpr
  | 0, expr => expr
  | fuel + 1, expr =>
      match expr with
      | .mvar id =>
          match psMetaFindAssignment context id with
          | none => expr
          | some value => psMetaInstantiateWithFuel context fuel value
      | .app fn arg =>
          PsExpr.app
            (psMetaInstantiateWithFuel context fuel fn)
            (psMetaInstantiateWithFuel context fuel arg)
      | .lam name type body binder =>
          PsExpr.lam
            name
            (psMetaInstantiateWithFuel context fuel type)
            (psMetaInstantiateWithFuel context fuel body)
            binder
      | .forallE name type body binder =>
          PsExpr.forallE
            name
            (psMetaInstantiateWithFuel context fuel type)
            (psMetaInstantiateWithFuel context fuel body)
            binder
      | .letE name type value body =>
          PsExpr.letE
            name
            (psMetaInstantiateWithFuel context fuel type)
            (psMetaInstantiateWithFuel context fuel value)
            (psMetaInstantiateWithFuel context fuel body)
      | .proj typeName index value =>
          PsExpr.proj
            typeName
            index
            (psMetaInstantiateWithFuel context fuel value)
      | _ => expr

def psMetaInstantiate (context : PsMetaContext) (expr : PsExpr) : PsExpr :=
  let value := psMetaInstantiateWithFuel context (context.assignments.length + 1) expr
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
  | none => none
  | some declaration =>
      match psMetaFindAssignment context id with
      | some _ => none
      | none =>
          let resolved := psMetaInstantiate context value
          if psExprContainsMVar id resolved then
            none
          else if psExprFVarsInContext declaration.localContext resolved then
            some {
              nextId := context.nextId
              declarations := context.declarations
              assignments := { id := id, value := resolved } :: context.assignments
              levels := context.levels
            }
          else
            none

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
