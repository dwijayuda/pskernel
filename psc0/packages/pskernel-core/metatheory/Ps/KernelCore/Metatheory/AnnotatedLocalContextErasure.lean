import Ps.KernelCore.Core.AnnotatedLocalContext

/-!
Pure transport laws for the shared local-context representation. Mapping
changes only expression fields; lookup chooses the same first declaration
because names, list order and the fresh-index counter are preserved.

These laws carry the exact stored annotated declaration through erasure.
They assert no typing, model validity or annotation provenance by themselves.
-/

universe u v w

@[simp] theorem psKernelLocalDeclMap_name
    {Expr : Type u} {Expr' : Type v}
    (f : Expr → Expr') (decl : PsKernelLocalDeclOf Expr) :
    psKernelLocalDeclName (psKernelLocalDeclMap f decl) =
      psKernelLocalDeclName decl := by
  cases decl <;> rfl

@[simp] theorem psKernelLocalDeclMap_userName
    {Expr : Type u} {Expr' : Type v}
    (f : Expr → Expr') (decl : PsKernelLocalDeclOf Expr) :
    psKernelLocalDeclUserName (psKernelLocalDeclMap f decl) =
      psKernelLocalDeclUserName decl := by
  cases decl <;> rfl

@[simp] theorem psKernelLocalDeclMap_type
    {Expr : Type u} {Expr' : Type v}
    (f : Expr → Expr') (decl : PsKernelLocalDeclOf Expr) :
    psKernelLocalDeclType (psKernelLocalDeclMap f decl) =
      f (psKernelLocalDeclType decl) := by
  cases decl <;> rfl

@[simp] theorem psKernelLocalDeclMap_value
    {Expr : Type u} {Expr' : Type v}
    (f : Expr → Expr') (decl : PsKernelLocalDeclOf Expr) :
    psKernelLocalDeclValue (psKernelLocalDeclMap f decl) =
      Option.map f (psKernelLocalDeclValue decl) := by
  cases decl <;> rfl

@[simp] theorem psKernelLocalDeclMap_binderInfo
    {Expr : Type u} {Expr' : Type v}
    (f : Expr → Expr') (decl : PsKernelLocalDeclOf Expr) :
    psKernelLocalDeclBinderInfo (psKernelLocalDeclMap f decl) =
      psKernelLocalDeclBinderInfo decl := by
  cases decl <;> rfl

/-- Declaration identity is preserved, including its index and all metadata. -/
theorem psKernelLocalDeclMap_id
    {Expr : Type u} (decl : PsKernelLocalDeclOf Expr) :
    psKernelLocalDeclMap (fun e : Expr => e) decl = decl := by
  cases decl <;> rfl

theorem psKernelLocalDeclMap_comp
    {Expr : Type u} {Expr' : Type v} {Expr'' : Type w}
    (f : Expr → Expr') (g : Expr' → Expr'')
    (decl : PsKernelLocalDeclOf Expr) :
    psKernelLocalDeclMap g (psKernelLocalDeclMap f decl) =
      psKernelLocalDeclMap (fun e => g (f e)) decl := by
  cases decl <;> rfl

@[simp] theorem psKernelLocalContextMap_decls
    {Expr : Type u} {Expr' : Type v}
    (f : Expr → Expr') (context : PsKernelLocalContextOf Expr) :
    (psKernelLocalContextMap f context).decls =
      List.map (psKernelLocalDeclMap f) context.decls := rfl

@[simp] theorem psKernelLocalContextMap_nextIndex
    {Expr : Type u} {Expr' : Type v}
    (f : Expr → Expr') (context : PsKernelLocalContextOf Expr) :
    (psKernelLocalContextMap f context).nextIndex = context.nextIndex := rfl

theorem psKernelLocalContextMap_empty
    {Expr : Type u} {Expr' : Type v} (f : Expr → Expr') :
    psKernelLocalContextMap f (psKernelLocalContextEmptyOf Expr) =
      psKernelLocalContextEmptyOf Expr' := rfl

theorem psKernelLocalContextMap_findIn
    {Expr : Type u} {Expr' : Type v}
    (f : Expr → Expr') (name : PsKernelName)
    (decls : List (PsKernelLocalDeclOf Expr)) :
    psKernelLocalContextFindIn name (List.map (psKernelLocalDeclMap f) decls) =
      Option.map (psKernelLocalDeclMap f)
        (psKernelLocalContextFindIn name decls) := by
  induction decls with
  | nil => rfl
  | cons decl rest ih =>
      cases h : psKernelNameEq (psKernelLocalDeclName decl) name <;>
        simp [psKernelLocalContextFindIn, psKernelLocalDeclMap_name, h, ih]

theorem psKernelLocalContextMap_find
    {Expr : Type u} {Expr' : Type v}
    (f : Expr → Expr') (context : PsKernelLocalContextOf Expr)
    (name : PsKernelName) :
    psKernelLocalContextFind (psKernelLocalContextMap f context) name =
      Option.map (psKernelLocalDeclMap f)
        (psKernelLocalContextFind context name) := by
  exact psKernelLocalContextMap_findIn f name context.decls

/-- Invert a real mapped lookup, retaining the exact first stored declaration.
No injectivity of the expression map or uniqueness of local names is needed. -/
theorem psKernelLocalContextMap_find_some
    {Expr : Type u} {Expr' : Type v}
    (f : Expr → Expr') (context : PsKernelLocalContextOf Expr)
    (name : PsKernelName) (result : PsKernelLocalDeclOf Expr')
    (run : psKernelLocalContextFind (psKernelLocalContextMap f context) name =
      some result) :
    ∃ decl : PsKernelLocalDeclOf Expr,
      psKernelLocalContextFind context name = some decl ∧
        psKernelLocalDeclMap f decl = result := by
  have mapped : Option.map (psKernelLocalDeclMap f)
      (psKernelLocalContextFind context name) = some result :=
    (psKernelLocalContextMap_find f context name).symm.trans run
  cases h : psKernelLocalContextFind context name with
  | none =>
      have impossible : (none : Option (PsKernelLocalDeclOf Expr')) =
          some result := by
        simpa only [h, Option.map] using mapped
      cases impossible
  | some decl =>
      refine ⟨decl, by simp only [h], ?_⟩
      apply Option.some.inj
      simpa only [h, Option.map] using mapped

theorem psKernelLocalContextMap_find_none_iff
    {Expr : Type u} {Expr' : Type v}
    (f : Expr → Expr') (context : PsKernelLocalContextOf Expr)
    (name : PsKernelName) :
    psKernelLocalContextFind (psKernelLocalContextMap f context) name = none ↔
      psKernelLocalContextFind context name = none := by
  rw [psKernelLocalContextMap_find]
  cases psKernelLocalContextFind context name <;> simp

theorem psKernelLocalContextMap_addLocal
    {Expr : Type u} {Expr' : Type v}
    (f : Expr → Expr') (context : PsKernelLocalContextOf Expr)
    (name userName : PsKernelName) (type : Expr)
    (binderInfo : PsKernelBinderInfo) :
    psKernelLocalContextMap f
      (psKernelLocalContextAddLocal context name userName type binderInfo) =
      psKernelLocalContextAddLocal (psKernelLocalContextMap f context)
        name userName (f type) binderInfo := rfl

theorem psKernelLocalContextMap_addLet
    {Expr : Type u} {Expr' : Type v}
    (f : Expr → Expr') (context : PsKernelLocalContextOf Expr)
    (name userName : PsKernelName) (type value : Expr) :
    psKernelLocalContextMap f
      (psKernelLocalContextAddLet context name userName type value) =
      psKernelLocalContextAddLet (psKernelLocalContextMap f context)
        name userName (f type) (f value) := rfl

namespace PsKernelSemantics

@[simp] theorem eraseLocalDecl_name (decl : AnnotatedLocalDecl) :
    psKernelLocalDeclName (eraseLocalDecl decl) =
      psKernelLocalDeclName decl :=
  psKernelLocalDeclMap_name AnnotatedExpr.erase decl

@[simp] theorem eraseLocalDecl_userName (decl : AnnotatedLocalDecl) :
    psKernelLocalDeclUserName (eraseLocalDecl decl) =
      psKernelLocalDeclUserName decl :=
  psKernelLocalDeclMap_userName AnnotatedExpr.erase decl

@[simp] theorem eraseLocalDecl_type (decl : AnnotatedLocalDecl) :
    psKernelLocalDeclType (eraseLocalDecl decl) =
      (psKernelLocalDeclType decl).erase :=
  psKernelLocalDeclMap_type AnnotatedExpr.erase decl

@[simp] theorem eraseLocalDecl_value (decl : AnnotatedLocalDecl) :
    psKernelLocalDeclValue (eraseLocalDecl decl) =
      Option.map AnnotatedExpr.erase (psKernelLocalDeclValue decl) :=
  psKernelLocalDeclMap_value AnnotatedExpr.erase decl

@[simp] theorem eraseLocalDecl_binderInfo (decl : AnnotatedLocalDecl) :
    psKernelLocalDeclBinderInfo (eraseLocalDecl decl) =
      psKernelLocalDeclBinderInfo decl :=
  psKernelLocalDeclMap_binderInfo AnnotatedExpr.erase decl

@[simp] theorem eraseLocalContext_decls (context : AnnotatedLocalContext) :
    (eraseLocalContext context).decls =
      List.map eraseLocalDecl context.decls := rfl

@[simp] theorem eraseLocalContext_nextIndex (context : AnnotatedLocalContext) :
    (eraseLocalContext context).nextIndex = context.nextIndex := rfl

theorem eraseLocalContext_empty :
    eraseLocalContext annotatedLocalContextEmpty = psKernelLocalContextEmpty := rfl

theorem eraseLocalContext_find
    (context : AnnotatedLocalContext) (name : PsKernelName) :
    psKernelLocalContextFind (eraseLocalContext context) name =
      Option.map eraseLocalDecl (psKernelLocalContextFind context name) :=
  psKernelLocalContextMap_find AnnotatedExpr.erase context name

theorem eraseLocalContext_find_some
    (context : AnnotatedLocalContext) (name : PsKernelName)
    (rawDecl : PsKernelLocalDecl)
    (run : psKernelLocalContextFind (eraseLocalContext context) name = some rawDecl) :
    ∃ decl : AnnotatedLocalDecl,
      psKernelLocalContextFind context name = some decl ∧
        eraseLocalDecl decl = rawDecl :=
  psKernelLocalContextMap_find_some AnnotatedExpr.erase context name rawDecl run

theorem eraseLocalContext_find_none_iff
    (context : AnnotatedLocalContext) (name : PsKernelName) :
    psKernelLocalContextFind (eraseLocalContext context) name = none ↔
      psKernelLocalContextFind context name = none :=
  psKernelLocalContextMap_find_none_iff AnnotatedExpr.erase context name

theorem eraseLocalContext_addLocal
    (context : AnnotatedLocalContext) (name userName : PsKernelName)
    (type : AnnotatedExpr) (binderInfo : PsKernelBinderInfo) :
    eraseLocalContext
      (psKernelLocalContextAddLocal context name userName type binderInfo) =
      psKernelLocalContextAddLocal (eraseLocalContext context)
        name userName type.erase binderInfo := rfl

theorem eraseLocalContext_addLet
    (context : AnnotatedLocalContext) (name userName : PsKernelName)
    (type value : AnnotatedExpr) :
    eraseLocalContext
      (psKernelLocalContextAddLet context name userName type value) =
      psKernelLocalContextAddLet (eraseLocalContext context)
        name userName type.erase value.erase := rfl

end PsKernelSemantics
