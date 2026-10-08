import Ps.KernelCore.Core.Expr

inductive PsKernelLocalDecl where
  | localDecl
      (index : Nat)
      (name : PsKernelName)
      (userName : PsKernelName)
      (type : PsKernelExpr)
      (binderInfo : PsKernelBinderInfo)
  | letDecl
      (index : Nat)
      (name : PsKernelName)
      (userName : PsKernelName)
      (type : PsKernelExpr)
      (value : PsKernelExpr)

def psKernelLocalDeclName
    (decl : PsKernelLocalDecl) : PsKernelName :=
  match decl with
  | PsKernelLocalDecl.localDecl _ name _ _ _ =>
      name
  | PsKernelLocalDecl.letDecl _ name _ _ _ =>
      name

def psKernelLocalDeclUserName
    (decl : PsKernelLocalDecl) : PsKernelName :=
  match decl with
  | PsKernelLocalDecl.localDecl _ _ userName _ _ =>
      userName
  | PsKernelLocalDecl.letDecl _ _ userName _ _ =>
      userName

def psKernelLocalDeclType
    (decl : PsKernelLocalDecl) : PsKernelExpr :=
  match decl with
  | PsKernelLocalDecl.localDecl _ _ _ type _ =>
      type
  | PsKernelLocalDecl.letDecl _ _ _ type _ =>
      type

def psKernelLocalDeclValue
    (decl : PsKernelLocalDecl) :
    Option PsKernelExpr :=
  match decl with
  | PsKernelLocalDecl.localDecl _ _ _ _ _ =>
      Option.none
  | PsKernelLocalDecl.letDecl _ _ _ _ value =>
      Option.some value

def psKernelLocalDeclBinderInfo
    (decl : PsKernelLocalDecl) :
    PsKernelBinderInfo :=
  match decl with
  | PsKernelLocalDecl.localDecl _ _ _ _ binderInfo =>
      binderInfo
  | PsKernelLocalDecl.letDecl _ _ _ _ _ =>
      PsKernelBinderInfo.default

structure PsKernelLocalContext where
  decls : List PsKernelLocalDecl
  nextIndex : Nat

def psKernelLocalContextEmpty : PsKernelLocalContext :=
  {
    decls := List.nil
    nextIndex := 0
  }

def psKernelLocalContextFindIn
    (name : PsKernelName)
    (decls : List PsKernelLocalDecl) :
    Option PsKernelLocalDecl :=
  match decls with
  | List.nil =>
      Option.none
  | List.cons decl rest =>
      if
          psKernelNameEq
            (psKernelLocalDeclName decl)
            name then
        Option.some decl
      else
        psKernelLocalContextFindIn
          name
          rest

def psKernelLocalContextFind
    (context : PsKernelLocalContext)
    (name : PsKernelName) :
    Option PsKernelLocalDecl :=
  psKernelLocalContextFindIn
    name
    context.decls

def psKernelLocalContextAddLocal
    (context : PsKernelLocalContext)
    (name : PsKernelName)
    (userName : PsKernelName)
    (type : PsKernelExpr)
    (binderInfo : PsKernelBinderInfo) :
    PsKernelLocalContext :=
  {
    decls :=
      List.cons
        (PsKernelLocalDecl.localDecl
          context.nextIndex
          name
          userName
          type
          binderInfo)
        context.decls
    nextIndex :=
      Nat.succ context.nextIndex
  }

def psKernelLocalContextAddLet
    (context : PsKernelLocalContext)
    (name : PsKernelName)
    (userName : PsKernelName)
    (type : PsKernelExpr)
    (value : PsKernelExpr) :
    PsKernelLocalContext :=
  {
    decls :=
      List.cons
        (PsKernelLocalDecl.letDecl
          context.nextIndex
          name
          userName
          type
          value)
        context.decls
    nextIndex :=
      Nat.succ context.nextIndex
  }
