import PSC1Kernel.Expr

namespace PSC1Kernel

inductive LocalDecl where
  | localDecl
      (index : Nat)
      (name : Name)
      (userName : Name)
      (type : Expr)
      (binderInfo : BinderInfo)
  | letDecl
      (index : Nat)
      (name : Name)
      (userName : Name)
      (type : Expr)
      (value : Expr)

def LocalDecl.name : LocalDecl → Name
  | .localDecl _ name _ _ _ => name
  | .letDecl _ name _ _ _ => name

def LocalDecl.userName : LocalDecl → Name
  | .localDecl _ _ userName _ _ => userName
  | .letDecl _ _ userName _ _ => userName

def LocalDecl.type : LocalDecl → Expr
  | .localDecl _ _ _ type _ => type
  | .letDecl _ _ _ type _ => type

def LocalDecl.value? : LocalDecl → Option Expr
  | .localDecl .. => none
  | .letDecl _ _ _ _ value => some value

def LocalDecl.binderInfo : LocalDecl → BinderInfo
  | .localDecl _ _ _ _ info => info
  | .letDecl .. => .default

structure LocalContext where
  decls : List LocalDecl
  nextIndex : Nat

def LocalContext.empty : LocalContext :=
  { decls := [], nextIndex := 0 }

def LocalContext.find? (ctx : LocalContext) (name : Name) : Option LocalDecl :=
  let rec go : List LocalDecl → Option LocalDecl
    | [] => none
    | decl :: rest =>
      if Name.eq decl.name name then some decl else go rest
  go ctx.decls

def LocalContext.addLocal
    (ctx : LocalContext)
    (name userName : Name)
    (type : Expr)
    (binderInfo : BinderInfo) : LocalContext :=
  {
    decls := .localDecl ctx.nextIndex name userName type binderInfo :: ctx.decls
    nextIndex := ctx.nextIndex + 1
  }

def LocalContext.addLet
    (ctx : LocalContext)
    (name userName : Name)
    (type value : Expr) : LocalContext :=
  {
    decls := .letDecl ctx.nextIndex name userName type value :: ctx.decls
    nextIndex := ctx.nextIndex + 1
  }

end PSC1Kernel
