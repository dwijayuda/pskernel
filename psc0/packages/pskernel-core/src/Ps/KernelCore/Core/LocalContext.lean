import Ps.KernelCore.Core.Expr

/-!
One local-declaration and context implementation for raw and annotated syntax.
The raw public types are specializations. Mapping changes expression fields only;
it preserves names, binder metadata, declaration order and allocation indices.
No semantic validity follows merely from storing an expression in this context.
-/

universe u v

inductive PsKernelLocalDeclOf (Expr : Type u) where
  | localDecl
      (index : Nat)
      (name : PsKernelName)
      (userName : PsKernelName)
      (type : Expr)
      (binderInfo : PsKernelBinderInfo)
  | letDecl
      (index : Nat)
      (name : PsKernelName)
      (userName : PsKernelName)
      (type : Expr)
      (value : Expr)

abbrev PsKernelLocalDecl := PsKernelLocalDeclOf PsKernelExpr

namespace PsKernelLocalDecl

@[match_pattern] abbrev localDecl
    (index : Nat) (name userName : PsKernelName)
    (type : PsKernelExpr) (binderInfo : PsKernelBinderInfo) :
    PsKernelLocalDecl :=
  PsKernelLocalDeclOf.localDecl index name userName type binderInfo

@[match_pattern] abbrev letDecl
    (index : Nat) (name userName : PsKernelName)
    (type value : PsKernelExpr) : PsKernelLocalDecl :=
  PsKernelLocalDeclOf.letDecl index name userName type value

end PsKernelLocalDecl

def psKernelLocalDeclName {Expr : Type u}
    (decl : PsKernelLocalDeclOf Expr) : PsKernelName :=
  match decl with
  | PsKernelLocalDeclOf.localDecl _ name _ _ _ => name
  | PsKernelLocalDeclOf.letDecl _ name _ _ _ => name

def psKernelLocalDeclUserName {Expr : Type u}
    (decl : PsKernelLocalDeclOf Expr) : PsKernelName :=
  match decl with
  | PsKernelLocalDeclOf.localDecl _ _ userName _ _ => userName
  | PsKernelLocalDeclOf.letDecl _ _ userName _ _ => userName

def psKernelLocalDeclType {Expr : Type u}
    (decl : PsKernelLocalDeclOf Expr) : Expr :=
  match decl with
  | PsKernelLocalDeclOf.localDecl _ _ _ type _ => type
  | PsKernelLocalDeclOf.letDecl _ _ _ type _ => type

def psKernelLocalDeclValue {Expr : Type u}
    (decl : PsKernelLocalDeclOf Expr) : Option Expr :=
  match decl with
  | PsKernelLocalDeclOf.localDecl _ _ _ _ _ => Option.none
  | PsKernelLocalDeclOf.letDecl _ _ _ _ value => Option.some value

def psKernelLocalDeclBinderInfo {Expr : Type u}
    (decl : PsKernelLocalDeclOf Expr) : PsKernelBinderInfo :=
  match decl with
  | PsKernelLocalDeclOf.localDecl _ _ _ _ binderInfo => binderInfo
  | PsKernelLocalDeclOf.letDecl _ _ _ _ _ => PsKernelBinderInfo.default

structure PsKernelLocalContextOf (Expr : Type u) where
  decls : List (PsKernelLocalDeclOf Expr)
  nextIndex : Nat

abbrev PsKernelLocalContext := PsKernelLocalContextOf PsKernelExpr

namespace PsKernelLocalContext

@[match_pattern] abbrev mk
    (decls : List PsKernelLocalDecl) (nextIndex : Nat) :
    PsKernelLocalContext :=
  PsKernelLocalContextOf.mk decls nextIndex

abbrev decls (context : PsKernelLocalContext) : List PsKernelLocalDecl :=
  PsKernelLocalContextOf.decls context

abbrev nextIndex (context : PsKernelLocalContext) : Nat :=
  PsKernelLocalContextOf.nextIndex context

end PsKernelLocalContext

def psKernelLocalContextEmptyOf (Expr : Type u) :
    PsKernelLocalContextOf Expr :=
  { decls := List.nil, nextIndex := 0 }

def psKernelLocalContextEmpty : PsKernelLocalContext :=
  psKernelLocalContextEmptyOf PsKernelExpr

def psKernelLocalContextFindIn {Expr : Type u}
    (name : PsKernelName) (decls : List (PsKernelLocalDeclOf Expr)) :
    Option (PsKernelLocalDeclOf Expr) :=
  match decls with
  | List.nil => Option.none
  | List.cons decl rest =>
      if psKernelNameEq (psKernelLocalDeclName decl) name then
        Option.some decl
      else
        psKernelLocalContextFindIn name rest

def psKernelLocalContextFind {Expr : Type u}
    (context : PsKernelLocalContextOf Expr) (name : PsKernelName) :
    Option (PsKernelLocalDeclOf Expr) :=
  psKernelLocalContextFindIn name context.decls

def psKernelLocalContextAddLocal {Expr : Type u}
    (context : PsKernelLocalContextOf Expr)
    (name userName : PsKernelName)
    (type : Expr) (binderInfo : PsKernelBinderInfo) :
    PsKernelLocalContextOf Expr :=
  {
    decls := List.cons
      (PsKernelLocalDeclOf.localDecl context.nextIndex name userName type binderInfo)
      context.decls
    nextIndex := Nat.succ context.nextIndex
  }

def psKernelLocalContextAddLet {Expr : Type u}
    (context : PsKernelLocalContextOf Expr)
    (name userName : PsKernelName) (type value : Expr) :
    PsKernelLocalContextOf Expr :=
  {
    decls := List.cons
      (PsKernelLocalDeclOf.letDecl context.nextIndex name userName type value)
      context.decls
    nextIndex := Nat.succ context.nextIndex
  }

def psKernelLocalDeclMap {Expr : Type u} {Expr' : Type v}
    (f : Expr → Expr') (decl : PsKernelLocalDeclOf Expr) :
    PsKernelLocalDeclOf Expr' :=
  match decl with
  | PsKernelLocalDeclOf.localDecl index name userName type binderInfo =>
      PsKernelLocalDeclOf.localDecl index name userName (f type) binderInfo
  | PsKernelLocalDeclOf.letDecl index name userName type value =>
      PsKernelLocalDeclOf.letDecl index name userName (f type) (f value)

def psKernelLocalContextMap {Expr : Type u} {Expr' : Type v}
    (f : Expr → Expr') (context : PsKernelLocalContextOf Expr) :
    PsKernelLocalContextOf Expr' :=
  {
    decls := List.map (psKernelLocalDeclMap f) context.decls
    nextIndex := context.nextIndex
  }
