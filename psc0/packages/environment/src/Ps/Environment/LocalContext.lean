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

structure PsLocalNameAlias where
  userName : PsName
  id : Nat
  beforeId : Nat

structure PsLocalContext where
  nextId : Nat
  declarations : List PsLocalDecl
  nameAliases : List PsLocalNameAlias := []

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
  let declaration := psLocalFindUserInList userName context.declarations
  let alias := context.nameAliases.find? fun alias =>
    psNameEq alias.userName userName && psLocalContainsId context alias.id
  match alias with
  | none => declaration
  | some alias =>
    match declaration with
    | some declaration =>
      if psLocalDeclId declaration >= alias.beforeId then some declaration
      else psLocalFindById context alias.id
    | none => psLocalFindById context alias.id

def psLocalAddNameAlias (context : PsLocalContext) (userName : PsName) (id : Nat) :
    Option PsLocalContext :=
  if !psLocalContainsId context id then none
  else some { context with nameAliases :=
    { userName, id, beforeId := context.nextId } :: context.nameAliases }

def psLocalRedirectNameAliases (context : PsLocalContext) (original current : Nat) : PsLocalContext :=
  { context with nameAliases := context.nameAliases.map fun alias =>
    if alias.id == original then { alias with id := current } else alias }

-- Preserve every source-visible name for a selected identity. Canonical names
-- remain available when they have not been shadowed by a newer local or alias.
def psLocalVisibleNames (context : PsLocalContext) (id : Nat) : List PsName :=
  let names := context.nameAliases.map (·.userName) ++
    (psLocalFindById context id).toList.map psLocalDeclUserName
  names.foldl (fun result name =>
    let visible := match psLocalFindUser context name with
      | some declaration => psLocalDeclId declaration == id
      | none => false
    if visible && !(result.any (psNameEq name)) then result ++ [name] else result) []

def psLocalPushBinding
    (context : PsLocalContext)
    (userName : PsName)
    (type : PsExpr)
    (binder : PsBinderInfo) : PsLocalPushResult :=
  let id := context.nextId;
  let declaration := PsLocalDecl.binding id userName type binder;
  {
    context := { context with
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
    context := { context with
      nextId := Nat.succ id
      declarations := List.cons declaration context.declarations
    }
    id := id
  }
