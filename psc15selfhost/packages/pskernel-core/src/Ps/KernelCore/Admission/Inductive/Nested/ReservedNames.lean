import Ps.KernelCore.Admission.Inductive.Nested.Types

/-
Reserved-name validation for nested-inductive flattening.

The kernel-side nested transformation owns the `_nested` namespace used for
auxiliary declarations. User declarations that collide with those names are
rejected before flattening.
-/

def psKernelSimpleNestedPrefix : PsKernelName :=
  PsKernelName.str
    PsKernelName.anonymous
    "_nested"

def psKernelSimpleNestedExprUsesReserved
    (expr : PsKernelExpr) : Bool :=
  match expr with
  | PsKernelExpr.const name _ =>
      psKernelNameIsPrefixOf
        psKernelSimpleNestedPrefix
        name
  | PsKernelExpr.app fn arg =>
      if psKernelSimpleNestedExprUsesReserved fn then
        true
      else
        psKernelSimpleNestedExprUsesReserved arg
  | PsKernelExpr.lam _ type body _ =>
      if psKernelSimpleNestedExprUsesReserved type then
        true
      else
        psKernelSimpleNestedExprUsesReserved body
  | PsKernelExpr.forallE _ type body _ =>
      if psKernelSimpleNestedExprUsesReserved type then
        true
      else
        psKernelSimpleNestedExprUsesReserved body
  | PsKernelExpr.letE _ type value body _ =>
      if psKernelSimpleNestedExprUsesReserved type then
        true
      else if psKernelSimpleNestedExprUsesReserved value then
        true
      else
        psKernelSimpleNestedExprUsesReserved body
  | PsKernelExpr.mdata _ body =>
      psKernelSimpleNestedExprUsesReserved body
  | PsKernelExpr.proj typeName _ body =>
      if
          psKernelNameIsPrefixOf
            psKernelSimpleNestedPrefix
            typeName then
        true
      else
        psKernelSimpleNestedExprUsesReserved body
  | _ =>
      false

def psKernelSimpleNestedCheckCtorReserved
    (ctors : List PsKernelSimpleConstructorDecl) :
    Except String Unit :=
  match ctors with
  | List.nil =>
      Except.ok ()
  | List.cons ctor rest =>
      if
          psKernelNameIsPrefixOf
            psKernelSimpleNestedPrefix
            ctor.name then
        Except.error
          "reserved prefix '_nested' occurs in nested inductive constructor"
      else if
          psKernelSimpleNestedExprUsesReserved
            ctor.type then
        Except.error
          "reserved prefix '_nested' occurs in nested inductive constructor"
      else
        psKernelSimpleNestedCheckCtorReserved
          rest

def psKernelSimpleNestedCheckTypeReserved
    (types : List PsKernelSimpleMutualTypeDecl) :
    Except String Unit :=
  match types with
  | List.nil =>
      Except.ok ()
  | List.cons typeDecl rest =>
      if
          psKernelNameIsPrefixOf
            psKernelSimpleNestedPrefix
            typeDecl.name then
        Except.error
          "reserved prefix '_nested' occurs in nested inductive declaration"
      else if
          psKernelSimpleNestedExprUsesReserved
            typeDecl.type then
        Except.error
          "reserved prefix '_nested' occurs in nested inductive declaration"
      else
        match
            psKernelSimpleNestedCheckCtorReserved
              typeDecl.ctors with
        | Except.error error =>
            Except.error error
        | Except.ok _ =>
            psKernelSimpleNestedCheckTypeReserved
              rest

def psKernelSimpleNestedCheckReserved
    (decl : PsKernelSimpleMutualInductiveDecl) :
    Except String Unit :=
  psKernelSimpleNestedCheckTypeReserved
    decl.types

