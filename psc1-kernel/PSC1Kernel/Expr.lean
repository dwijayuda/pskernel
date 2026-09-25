import PSC1Kernel.Level

namespace PSC1Kernel

inductive BinderInfo where
  | default
  | implicit
  | strictImplicit
  | instImplicit

inductive Literal where
  | nat (value : Nat)
  | str (value : String)

abbrev Metadata := Nat

inductive Expr where
  | bvar (index : Nat)
  | fvar (name : Name)
  | mvar (name : Name)
  | sort (level : Level)
  | const (name : Name) (levels : List Level)
  | app (fn : Expr) (arg : Expr)
  | lam (name : Name) (type : Expr) (body : Expr) (binderInfo : BinderInfo)
  | forallE (name : Name) (type : Expr) (body : Expr) (binderInfo : BinderInfo)
  | letE (name : Name) (type : Expr) (value : Expr) (body : Expr) (nondep : Bool)
  | lit (value : Literal)
  | mdata (metadata : Metadata) (expr : Expr)
  | proj (typeName : Name) (index : Nat) (expr : Expr)

def BinderInfo.eq : BinderInfo → BinderInfo → Bool
  | .default, .default
  | .implicit, .implicit
  | .strictImplicit, .strictImplicit
  | .instImplicit, .instImplicit => true
  | _, _ => false

def Literal.eq : Literal → Literal → Bool
  | .nat a, .nat b => a == b
  | .str a, .str b => a == b
  | _, _ => false

def Level.listEq : List Level → List Level → Bool
  | [], [] => true
  | a :: as, b :: bs => Level.eq a b && Level.listEq as bs
  | _, _ => false

partial def Expr.eq : Expr → Expr → Bool
  | .bvar a, .bvar b => a == b
  | .fvar a, .fvar b => Name.eq a b
  | .mvar a, .mvar b => Name.eq a b
  | .sort a, .sort b => Level.eq a b
  | .const n₁ ls₁, .const n₂ ls₂ => Name.eq n₁ n₂ && Level.listEq ls₁ ls₂
  | .app f₁ a₁, .app f₂ a₂ => Expr.eq f₁ f₂ && Expr.eq a₁ a₂
  | .lam n₁ t₁ b₁ i₁, .lam n₂ t₂ b₂ i₂ =>
    Name.eq n₁ n₂ && Expr.eq t₁ t₂ && Expr.eq b₁ b₂ && BinderInfo.eq i₁ i₂
  | .forallE n₁ t₁ b₁ i₁, .forallE n₂ t₂ b₂ i₂ =>
    Name.eq n₁ n₂ && Expr.eq t₁ t₂ && Expr.eq b₁ b₂ && BinderInfo.eq i₁ i₂
  | .letE n₁ t₁ v₁ b₁ d₁, .letE n₂ t₂ v₂ b₂ d₂ =>
    Name.eq n₁ n₂ && Expr.eq t₁ t₂ && Expr.eq v₁ v₂ && Expr.eq b₁ b₂ && d₁ == d₂
  | .lit a, .lit b => Literal.eq a b
  | .mdata m₁ e₁, .mdata m₂ e₂ => m₁ == m₂ && Expr.eq e₁ e₂
  | .proj n₁ i₁ e₁, .proj n₂ i₂ e₂ => Name.eq n₁ n₂ && i₁ == i₂ && Expr.eq e₁ e₂
  | _, _ => false

partial def Expr.hasLooseAt (e : Expr) (offset : Nat) : Bool :=
  match e with
  | .bvar i => i ≥ offset
  | .app f a => f.hasLooseAt offset || a.hasLooseAt offset
  | .lam _ t b _ | .forallE _ t b _ =>
    t.hasLooseAt offset || b.hasLooseAt (offset + 1)
  | .letE _ t v b _ =>
    t.hasLooseAt offset || v.hasLooseAt offset || b.hasLooseAt (offset + 1)
  | .mdata _ b | .proj _ _ b => b.hasLooseAt offset
  | .fvar _ | .mvar _ | .sort _ | .const _ _ | .lit _ => false

def Expr.hasLooseBVar (e : Expr) : Bool :=
  e.hasLooseAt 0

partial def Expr.getAppFn : Expr → Expr
  | .app fn _ => fn.getAppFn
  | e => e

def Expr.getAppArgs (e : Expr) : List Expr :=
  let rec go : Expr → List Expr → List Expr
    | .app fn arg, args => go fn (arg :: args)
    | _, args => args
  go e []

def Expr.getAppNumArgs (e : Expr) : Nat :=
  e.getAppArgs.length

partial def Expr.hasFVar (e : Expr) : Bool :=
  match e with
  | .fvar _ => true
  | .app f a => f.hasFVar || a.hasFVar
  | .lam _ t b _ | .forallE _ t b _ => t.hasFVar || b.hasFVar
  | .letE _ t v b _ => t.hasFVar || v.hasFVar || b.hasFVar
  | .mdata _ b | .proj _ _ b => b.hasFVar
  | .bvar _ | .mvar _ | .sort _ | .const _ _ | .lit _ => false

partial def Expr.instantiateLevelParams
    (e : Expr) (params : List Name) (values : List Level) : Expr :=
  match e with
  | .sort u => .sort (u.instantiateParams params values)
  | .const n ls => .const n (ls.map fun u => u.instantiateParams params values)
  | .app f a => .app (f.instantiateLevelParams params values) (a.instantiateLevelParams params values)
  | .lam n t b bi =>
    .lam n (t.instantiateLevelParams params values) (b.instantiateLevelParams params values) bi
  | .forallE n t b bi =>
    .forallE n (t.instantiateLevelParams params values) (b.instantiateLevelParams params values) bi
  | .letE n t v b nd =>
    .letE n
      (t.instantiateLevelParams params values)
      (v.instantiateLevelParams params values)
      (b.instantiateLevelParams params values)
      nd
  | .mdata m b => .mdata m (b.instantiateLevelParams params values)
  | .proj n i b => .proj n i (b.instantiateLevelParams params values)
  | .bvar _ | .fvar _ | .mvar _ | .lit _ => e

end PSC1Kernel
