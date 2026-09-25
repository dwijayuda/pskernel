import Ps.Foundation.Name
import Ps.Core.Expr

inductive PsLocalDecl where
  | binding
      (id : Nat)
      (userName : PsName)
      (type : PsExpr)
      (binder : PsBinderInfo)
  | letDecl
      (id : Nat)
      (userName : PsName)
      (type : PsExpr)
      (value : PsExpr)

structure PsLocalContext where
  nextId : Nat
  declarations : List PsLocalDecl

structure PsLocalPushResult where
  context : PsLocalContext
  id : Nat

def psLocalEmpty : PsLocalContext :=
  { nextId := 0, declarations := [] }

def psLocalDeclId : PsLocalDecl -> Nat
  | .binding id _ _ _ => id
  | .letDecl id _ _ _ => id


def psLocalDeclType : PsLocalDecl -> PsExpr
  | .binding _ _ type _ => type
  | .letDecl _ _ type _ => type

def psLocalDeclUserName : PsLocalDecl -> PsName
  | .binding _ userName _ _ => userName
  | .letDecl _ userName _ _ => userName

def psLocalFindByIdInList
    (id : Nat)
    (declarations : List PsLocalDecl) : Option PsLocalDecl :=
  match declarations with
  | [] => Option.none
  | declaration :: rest =>
      if Nat.beq (psLocalDeclId declaration) id then
        Option.some declaration
      else
        psLocalFindByIdInList id rest

def psLocalFindById (context : PsLocalContext) (id : Nat) : Option PsLocalDecl :=
  psLocalFindByIdInList id context.declarations

def psLocalContainsId (context : PsLocalContext) (id : Nat) : Bool :=
  match psLocalFindById context id with
  | Option.none => false
  | Option.some _ => true

def psLocalFindUserInList
    (userName : PsName)
    (declarations : List PsLocalDecl) : Option PsLocalDecl :=
  match declarations with
  | [] => Option.none
  | declaration :: rest =>
      if psNameEq userName (psLocalDeclUserName declaration) then
        Option.some declaration
      else
        psLocalFindUserInList userName rest

def psLocalFindUser (context : PsLocalContext) (userName : PsName) : Option PsLocalDecl :=
  psLocalFindUserInList userName context.declarations

def psLocalPushBinding
    (context : PsLocalContext)
    (userName : PsName)
    (type : PsExpr)
    (binder : PsBinderInfo) : PsLocalPushResult :=
  let id := context.nextId;
  let declaration := PsLocalDecl.binding id userName type binder;
  {
    context := {
      nextId := Nat.succ id
      declarations := List.cons declaration context.declarations
    }
    id := id
  }

def psLocalPushLet
    (context : PsLocalContext)
    (userName : PsName)
    (type : PsExpr)
    (value : PsExpr) : PsLocalPushResult :=
  let id := context.nextId;
  let declaration := PsLocalDecl.letDecl id userName type value;
  {
    context := {
      nextId := Nat.succ id
      declarations := List.cons declaration context.declarations
    }
    id := id
  }
