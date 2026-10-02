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
      let smaller : PsExpr -> PsExpr :=
        psMetaInstantiateRounds context remaining;
      fun (expr : PsExpr) =>
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
