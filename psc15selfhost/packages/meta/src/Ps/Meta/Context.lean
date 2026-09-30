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

def psExprFVarsInContextWorker
    (expr : PsExpr) : PsLocalContext -> Bool :=
  match expr with
  | .fvar id =>
      fun (localContext : PsLocalContext) =>
        psLocalContainsId localContext id
  | .app fn arg =>
      let fnOk : PsLocalContext -> Bool :=
        psExprFVarsInContextWorker fn;
      let argOk : PsLocalContext -> Bool :=
        psExprFVarsInContextWorker arg;
      fun (localContext : PsLocalContext) =>
        if fnOk localContext then
          argOk localContext
        else
          false
  | .lam _ type body _ =>
      let typeOk : PsLocalContext -> Bool :=
        psExprFVarsInContextWorker type;
      let bodyOk : PsLocalContext -> Bool :=
        psExprFVarsInContextWorker body;
      fun (localContext : PsLocalContext) =>
        if typeOk localContext then
          bodyOk localContext
        else
          false
  | .forallE _ type body _ =>
      let typeOk : PsLocalContext -> Bool :=
        psExprFVarsInContextWorker type;
      let bodyOk : PsLocalContext -> Bool :=
        psExprFVarsInContextWorker body;
      fun (localContext : PsLocalContext) =>
        if typeOk localContext then
          bodyOk localContext
        else
          false
  | .letE _ type value body =>
      let typeOk : PsLocalContext -> Bool :=
        psExprFVarsInContextWorker type;
      let valueOk : PsLocalContext -> Bool :=
        psExprFVarsInContextWorker value;
      let bodyOk : PsLocalContext -> Bool :=
        psExprFVarsInContextWorker body;
      fun (localContext : PsLocalContext) =>
        if typeOk localContext then
          if valueOk localContext then
            bodyOk localContext
          else
            false
        else
          false
  | .proj _ _ value =>
      let valueOk : PsLocalContext -> Bool :=
        psExprFVarsInContextWorker value;
      fun (localContext : PsLocalContext) =>
        valueOk localContext
  | _ =>
      fun (_localContext : PsLocalContext) => true

def psExprFVarsInContext
    (localContext : PsLocalContext)
    (expr : PsExpr) : Bool :=
  psExprFVarsInContextWorker expr localContext

def psMetaInstantiateStepWorker
    (expr : PsExpr) : PsMetaContext -> PsExpr :=
  match expr with
  | .bvar index =>
      fun (_context : PsMetaContext) => PsExpr.bvar index
  | .fvar id =>
      fun (_context : PsMetaContext) => PsExpr.fvar id
  | .mvar id =>
      fun (context : PsMetaContext) =>
        match psMetaFindAssignment context id with
        | Option.none => PsExpr.mvar id
        | Option.some value => value
  | .sortE level =>
      fun (_context : PsMetaContext) => PsExpr.sortE level
  | .constE name levels =>
      fun (_context : PsMetaContext) => PsExpr.constE name levels
  | .app fn arg =>
      let stepFn : PsMetaContext -> PsExpr :=
        psMetaInstantiateStepWorker fn;
      let stepArg : PsMetaContext -> PsExpr :=
        psMetaInstantiateStepWorker arg;
      fun (context : PsMetaContext) =>
        PsExpr.app (stepFn context) (stepArg context)
  | .lam name type body binder =>
      let stepType : PsMetaContext -> PsExpr :=
        psMetaInstantiateStepWorker type;
      let stepBody : PsMetaContext -> PsExpr :=
        psMetaInstantiateStepWorker body;
      fun (context : PsMetaContext) =>
        PsExpr.lam
          name
          (stepType context)
          (stepBody context)
          binder
  | .forallE name type body binder =>
      let stepType : PsMetaContext -> PsExpr :=
        psMetaInstantiateStepWorker type;
      let stepBody : PsMetaContext -> PsExpr :=
        psMetaInstantiateStepWorker body;
      fun (context : PsMetaContext) =>
        PsExpr.forallE
          name
          (stepType context)
          (stepBody context)
          binder
  | .letE name type value body =>
      let stepType : PsMetaContext -> PsExpr :=
        psMetaInstantiateStepWorker type;
      let stepValue : PsMetaContext -> PsExpr :=
        psMetaInstantiateStepWorker value;
      let stepBody : PsMetaContext -> PsExpr :=
        psMetaInstantiateStepWorker body;
      fun (context : PsMetaContext) =>
        PsExpr.letE
          name
          (stepType context)
          (stepValue context)
          (stepBody context)
  | .lit literal =>
      fun (_context : PsMetaContext) => PsExpr.lit literal
  | .proj typeName index value =>
      let stepValue : PsMetaContext -> PsExpr :=
        psMetaInstantiateStepWorker value;
      fun (context : PsMetaContext) =>
        PsExpr.proj typeName index (stepValue context)

def psMetaInstantiateStep
    (context : PsMetaContext)
    (expr : PsExpr) : PsExpr :=
  psMetaInstantiateStepWorker expr context

def psMetaInstantiateRounds
    (context : PsMetaContext)
    (rounds : Nat) : PsExpr -> PsExpr :=
  match rounds with
  | Nat.zero =>
      fun (expr : PsExpr) => expr
  | Nat.succ remaining =>
      let smaller : PsExpr -> PsExpr :=
        psMetaInstantiateRounds context remaining;
      fun (expr : PsExpr) =>
        smaller (psMetaInstantiateStep context expr)

def psMetaAssignmentListLength
    (assignments : List PsMetaAssignment) : Nat :=
  match assignments with
  | [] => Nat.zero
  | _ :: rest => Nat.succ (psMetaAssignmentListLength rest)

def psMetaInstantiate (context : PsMetaContext) (expr : PsExpr) : PsExpr :=
  let fuel := Nat.succ (psMetaAssignmentListLength context.assignments);
  let value := psMetaInstantiateRounds context fuel expr;
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
