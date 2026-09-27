import Ps.KernelCore.Expr

inductive PsKernelCoreLocalDecl where
  | localDecl
      (index : Nat)
      (name : PsKernelCoreName)
      (userName : PsKernelCoreName)
      (type : PsKernelCoreExpr)
      (binderInfo : PsKernelCoreBinderInfo)
  | letDecl
      (index : Nat)
      (name : PsKernelCoreName)
      (userName : PsKernelCoreName)
      (type : PsKernelCoreExpr)
      (value : PsKernelCoreExpr)

def psKernelCoreLocalDeclName
    (decl : PsKernelCoreLocalDecl) : PsKernelCoreName :=
  match decl with
  | PsKernelCoreLocalDecl.localDecl _ name _ _ _ => name
  | PsKernelCoreLocalDecl.letDecl _ name _ _ _ => name

def psKernelCoreLocalDeclUserName
    (decl : PsKernelCoreLocalDecl) : PsKernelCoreName :=
  match decl with
  | PsKernelCoreLocalDecl.localDecl _ _ userName _ _ => userName
  | PsKernelCoreLocalDecl.letDecl _ _ userName _ _ => userName

def psKernelCoreLocalDeclType
    (decl : PsKernelCoreLocalDecl) : PsKernelCoreExpr :=
  match decl with
  | PsKernelCoreLocalDecl.localDecl _ _ _ type _ => type
  | PsKernelCoreLocalDecl.letDecl _ _ _ type _ => type

def psKernelCoreLocalDeclValue?
    (decl : PsKernelCoreLocalDecl) : PsKernelCoreOption PsKernelCoreExpr :=
  match decl with
  | PsKernelCoreLocalDecl.localDecl _ _ _ _ _ => PsKernelCoreOption.none
  | PsKernelCoreLocalDecl.letDecl _ _ _ _ value => PsKernelCoreOption.some value

def psKernelCoreLocalDeclBinderInfo
    (decl : PsKernelCoreLocalDecl) : PsKernelCoreBinderInfo :=
  match decl with
  | PsKernelCoreLocalDecl.localDecl _ _ _ _ binderInfo => binderInfo
  | PsKernelCoreLocalDecl.letDecl _ _ _ _ _ => PsKernelCoreBinderInfo.default

structure PsKernelCoreLocalContext where
  decls : PsKernelCoreList PsKernelCoreLocalDecl
  nextIndex : Nat

def psKernelCoreLocalContextEmpty : PsKernelCoreLocalContext :=
  {
    decls := PsKernelCoreList.nil
    nextIndex := Nat.zero
  }

def psKernelCoreLocalContextFindInDecls
    (name : PsKernelCoreName)
    (decls : PsKernelCoreList PsKernelCoreLocalDecl) :
    PsKernelCoreOption PsKernelCoreLocalDecl :=
  match decls with
  | PsKernelCoreList.nil => PsKernelCoreOption.none
  | PsKernelCoreList.cons decl rest =>
      if psKernelCoreNameEq (psKernelCoreLocalDeclName decl) name then
        PsKernelCoreOption.some decl
      else
        psKernelCoreLocalContextFindInDecls name rest

def psKernelCoreLocalContextFind?
    (ctx : PsKernelCoreLocalContext)
    (name : PsKernelCoreName) : PsKernelCoreOption PsKernelCoreLocalDecl :=
  psKernelCoreLocalContextFindInDecls name ctx.decls

def psKernelCoreLocalContextAddLocal
    (ctx : PsKernelCoreLocalContext)
    (name : PsKernelCoreName)
    (userName : PsKernelCoreName)
    (type : PsKernelCoreExpr)
    (binderInfo : PsKernelCoreBinderInfo) : PsKernelCoreLocalContext :=
  {
    decls :=
      PsKernelCoreList.cons
        (PsKernelCoreLocalDecl.localDecl
          ctx.nextIndex name userName type binderInfo)
        ctx.decls
    nextIndex := Nat.succ ctx.nextIndex
  }

def psKernelCoreLocalContextAddLet
    (ctx : PsKernelCoreLocalContext)
    (name : PsKernelCoreName)
    (userName : PsKernelCoreName)
    (type : PsKernelCoreExpr)
    (value : PsKernelCoreExpr) : PsKernelCoreLocalContext :=
  {
    decls :=
      PsKernelCoreList.cons
        (PsKernelCoreLocalDecl.letDecl
          ctx.nextIndex name userName type value)
        ctx.decls
    nextIndex := Nat.succ ctx.nextIndex
  }
