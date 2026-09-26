import Ps.PSCKernel.Core.Expr

inductive PsCKernelLocalDeclKind where
  | default
  | implDetail
  | auxDecl

inductive PsCKernelLocalDecl where
  | cdecl
      (index : Nat)
      (fvarId : PsCKernelFVarId)
      (userName : PsCKernelName)
      (declType : PsCKernelExpr)
      (binderInfo : PsCKernelBinderInfo)
      (kind : PsCKernelLocalDeclKind)
  | ldecl
      (index : Nat)
      (fvarId : PsCKernelFVarId)
      (userName : PsCKernelName)
      (declType : PsCKernelExpr)
      (value : PsCKernelExpr)
      (nondep : Bool)
      (kind : PsCKernelLocalDeclKind)

structure PsCKernelLocalContext where
  decls : List (Option PsCKernelLocalDecl)

def psCKernelLocalDeclKindEq
    (left : PsCKernelLocalDeclKind)
    (right : PsCKernelLocalDeclKind) : Bool :=
  match left, right with
  | PsCKernelLocalDeclKind.default, PsCKernelLocalDeclKind.default => true
  | PsCKernelLocalDeclKind.implDetail, PsCKernelLocalDeclKind.implDetail => true
  | PsCKernelLocalDeclKind.auxDecl, PsCKernelLocalDeclKind.auxDecl => true
  | _, _ => false

def psCKernelLocalDeclIndex (decl : PsCKernelLocalDecl) : Nat :=
  match decl with
  | PsCKernelLocalDecl.cdecl index _ _ _ _ _ => index
  | PsCKernelLocalDecl.ldecl index _ _ _ _ _ _ => index

def psCKernelLocalDeclFVarId (decl : PsCKernelLocalDecl) : PsCKernelFVarId :=
  match decl with
  | PsCKernelLocalDecl.cdecl _ fvarId _ _ _ _ => fvarId
  | PsCKernelLocalDecl.ldecl _ fvarId _ _ _ _ _ => fvarId

def psCKernelLocalDeclUserName (decl : PsCKernelLocalDecl) : PsCKernelName :=
  match decl with
  | PsCKernelLocalDecl.cdecl _ _ userName _ _ _ => userName
  | PsCKernelLocalDecl.ldecl _ _ userName _ _ _ _ => userName

def psCKernelLocalDeclType (decl : PsCKernelLocalDecl) : PsCKernelExpr :=
  match decl with
  | PsCKernelLocalDecl.cdecl _ _ _ declType _ _ => declType
  | PsCKernelLocalDecl.ldecl _ _ _ declType _ _ _ => declType

def psCKernelLocalDeclBinderInfo
    (decl : PsCKernelLocalDecl) : PsCKernelBinderInfo :=
  match decl with
  | PsCKernelLocalDecl.cdecl _ _ _ _ binderInfo _ => binderInfo
  | PsCKernelLocalDecl.ldecl _ _ _ _ _ _ _ => PsCKernelBinderInfo.default

def psCKernelLocalDeclKind
    (decl : PsCKernelLocalDecl) : PsCKernelLocalDeclKind :=
  match decl with
  | PsCKernelLocalDecl.cdecl _ _ _ _ _ kind => kind
  | PsCKernelLocalDecl.ldecl _ _ _ _ _ _ kind => kind

def psCKernelLocalDeclIsLet
    (decl : PsCKernelLocalDecl)
    (allowNondep : Bool) : Bool :=
  match decl with
  | PsCKernelLocalDecl.cdecl _ _ _ _ _ _ => false
  | PsCKernelLocalDecl.ldecl _ _ _ _ _ nondep _ =>
      if nondep then allowNondep else true

def psCKernelLocalDeclValue?
    (decl : PsCKernelLocalDecl)
    (allowNondep : Bool) : Option PsCKernelExpr :=
  match decl with
  | PsCKernelLocalDecl.cdecl _ _ _ _ _ _ => none
  | PsCKernelLocalDecl.ldecl _ _ _ _ value nondep _ =>
      if nondep then
        if allowNondep then some value else none
      else
        some value

def psCKernelLocalDeclIsNondep (decl : PsCKernelLocalDecl) : Bool :=
  match decl with
  | PsCKernelLocalDecl.cdecl _ _ _ _ _ _ => false
  | PsCKernelLocalDecl.ldecl _ _ _ _ _ nondep _ => nondep

def psCKernelLocalDeclIsImplementationDetail
    (decl : PsCKernelLocalDecl) : Bool :=
  !psCKernelLocalDeclKindEq
    (psCKernelLocalDeclKind decl)
    PsCKernelLocalDeclKind.default

def psCKernelLocalContextEmpty : PsCKernelLocalContext :=
  { decls := [] }

def psCKernelLocalContextDeclCount
    (decls : List (Option PsCKernelLocalDecl)) : Nat :=
  match decls with
  | [] => 0
  | _ :: rest => Nat.add 1 (psCKernelLocalContextDeclCount rest)

def psCKernelLocalContextNumIndices (ctx : PsCKernelLocalContext) : Nat :=
  psCKernelLocalContextDeclCount ctx.decls

def psCKernelLocalContextHasDecl
    (decls : List (Option PsCKernelLocalDecl)) : Bool :=
  match decls with
  | [] => false
  | none :: rest => psCKernelLocalContextHasDecl rest
  | some _ :: _ => true

def psCKernelLocalContextIsEmpty (ctx : PsCKernelLocalContext) : Bool :=
  !psCKernelLocalContextHasDecl ctx.decls

def psCKernelLocalContextPushDecl
    (decls : List (Option PsCKernelLocalDecl))
    (decl : PsCKernelLocalDecl) : List (Option PsCKernelLocalDecl) :=
  match decls with
  | [] => [some decl]
  | head :: rest =>
      head :: psCKernelLocalContextPushDecl rest decl

def psCKernelLocalContextMkLocalDecl
    (ctx : PsCKernelLocalContext)
    (fvarId : PsCKernelFVarId)
    (userName : PsCKernelName)
    (declType : PsCKernelExpr)
    (binderInfo : PsCKernelBinderInfo)
    (kind : PsCKernelLocalDeclKind) : PsCKernelLocalContext :=
  let index : Nat := psCKernelLocalContextNumIndices ctx
  let decl : PsCKernelLocalDecl :=
    PsCKernelLocalDecl.cdecl
      index
      fvarId
      userName
      declType
      binderInfo
      kind
  { decls := psCKernelLocalContextPushDecl ctx.decls decl }

def psCKernelLocalContextMkLetDecl
    (ctx : PsCKernelLocalContext)
    (fvarId : PsCKernelFVarId)
    (userName : PsCKernelName)
    (declType : PsCKernelExpr)
    (value : PsCKernelExpr)
    (nondep : Bool)
    (kind : PsCKernelLocalDeclKind) : PsCKernelLocalContext :=
  let index : Nat := psCKernelLocalContextNumIndices ctx
  let decl : PsCKernelLocalDecl :=
    PsCKernelLocalDecl.ldecl
      index
      fvarId
      userName
      declType
      value
      nondep
      kind
  { decls := psCKernelLocalContextPushDecl ctx.decls decl }

def psCKernelLocalContextGetAtInList?
    (decls : List (Option PsCKernelLocalDecl))
    (index : Nat) : Option PsCKernelLocalDecl :=
  match decls with
  | [] => none
  | head :: rest =>
      if Nat.beq index 0 then
        head
      else
        psCKernelLocalContextGetAtInList? rest (Nat.sub index 1)

def psCKernelLocalContextGetAt?
    (ctx : PsCKernelLocalContext)
    (index : Nat) : Option PsCKernelLocalDecl :=
  psCKernelLocalContextGetAtInList? ctx.decls index

def psCKernelLocalContextFindInList?
    (decls : List (Option PsCKernelLocalDecl))
    (fvarId : PsCKernelFVarId) : Option PsCKernelLocalDecl :=
  match decls with
  | [] => none
  | head :: rest =>
      match psCKernelLocalContextFindInList? rest fvarId with
      | some later => some later
      | none =>
          match head with
          | none => none
          | some decl =>
              if psCKernelFVarIdEq (psCKernelLocalDeclFVarId decl) fvarId then
                some decl
              else
                none

def psCKernelLocalContextFind?
    (ctx : PsCKernelLocalContext)
    (fvarId : PsCKernelFVarId) : Option PsCKernelLocalDecl :=
  psCKernelLocalContextFindInList? ctx.decls fvarId

def psCKernelLocalContextContains
    (ctx : PsCKernelLocalContext)
    (fvarId : PsCKernelFVarId) : Bool :=
  match psCKernelLocalContextFind? ctx fvarId with
  | none => false
  | some _ => true

def psCKernelLocalContextFindUserNameInList?
    (decls : List (Option PsCKernelLocalDecl))
    (userName : PsCKernelName) : Option PsCKernelLocalDecl :=
  match decls with
  | [] => none
  | head :: rest =>
      match psCKernelLocalContextFindUserNameInList? rest userName with
      | some later => some later
      | none =>
          match head with
          | none => none
          | some decl =>
              if psCKernelNameEq (psCKernelLocalDeclUserName decl) userName then
                some decl
              else
                none

def psCKernelLocalContextFindFromUserName?
    (ctx : PsCKernelLocalContext)
    (userName : PsCKernelName) : Option PsCKernelLocalDecl :=
  psCKernelLocalContextFindUserNameInList? ctx.decls userName

def psCKernelLocalContextGetFVarIdsFromList
    (decls : List (Option PsCKernelLocalDecl)) : List PsCKernelFVarId :=
  match decls with
  | [] => []
  | none :: rest => psCKernelLocalContextGetFVarIdsFromList rest
  | some decl :: rest =>
      psCKernelLocalDeclFVarId decl ::
        psCKernelLocalContextGetFVarIdsFromList rest

def psCKernelLocalContextGetFVarIds
    (ctx : PsCKernelLocalContext) : List PsCKernelFVarId :=
  psCKernelLocalContextGetFVarIdsFromList ctx.decls

def psCKernelLocalContextEntriesFromList
    (decls : List (Option PsCKernelLocalDecl)) : List PsCKernelLocalDecl :=
  match decls with
  | [] => []
  | none :: rest => psCKernelLocalContextEntriesFromList rest
  | some decl :: rest =>
      decl :: psCKernelLocalContextEntriesFromList rest

def psCKernelLocalContextEntries
    (ctx : PsCKernelLocalContext) : List PsCKernelLocalDecl :=
  psCKernelLocalContextEntriesFromList ctx.decls
