import PSC1Kernel.Level
import Std.Data.HashSet.Basic
import Std.Data.HashMap.Basic

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

/--
Lean 4.34 `Expr.eqv`-compatible structural equality. Binder display names and
binder annotations on lambda/forall/let nodes are deliberately ignored; they
are not part of kernel alpha-equivalence. Metadata payloads remain structural.
-/
private partial def Expr.eqSpec : Expr → Expr → Bool
  | .bvar a, .bvar b => a == b
  | .fvar a, .fvar b => Name.eq a b
  | .mvar a, .mvar b => Name.eq a b
  | .sort a, .sort b => Level.eq a b
  | .const n₁ ls₁, .const n₂ ls₂ => Name.eq n₁ n₂ && Level.listEq ls₁ ls₂
  | .app f₁ a₁, .app f₂ a₂ => Expr.eqSpec f₁ f₂ && Expr.eqSpec a₁ a₂
  | .lam _ t₁ b₁ _, .lam _ t₂ b₂ _ =>
    Expr.eqSpec t₁ t₂ && Expr.eqSpec b₁ b₂
  | .forallE _ t₁ b₁ _, .forallE _ t₂ b₂ _ =>
    Expr.eqSpec t₁ t₂ && Expr.eqSpec b₁ b₂
  | .letE _ t₁ v₁ b₁ d₁, .letE _ t₂ v₂ b₂ d₂ =>
    Expr.eqSpec t₁ t₂ && Expr.eqSpec v₁ v₂ && Expr.eqSpec b₁ b₂ && d₁ == d₂
  | .lit a, .lit b => Literal.eq a b
  | .mdata m₁ e₁, .mdata m₂ e₂ => m₁ == m₂ && Expr.eqSpec e₁ e₂
  | .proj n₁ i₁ e₁, .proj n₂ i₂ e₂ =>
    Name.eq n₁ n₂ && i₁ == i₂ && Expr.eqSpec e₁ e₂
  | _, _ => false

private partial def Name.structHash : Name → UInt64
  | .anonymous => 11
  | .str parent value =>
      mixHash 13 (mixHash parent.structHash (hash value))
  | .num parent value =>
      mixHash 17 (mixHash parent.structHash (hash value))

private partial def Level.structHash : Level → UInt64
  | .zero => 19
  | .succ level => mixHash 23 level.structHash
  | .max left right =>
      mixHash 29 (mixHash left.structHash right.structHash)
  | .imax left right =>
      mixHash 31 (mixHash left.structHash right.structHash)
  | .param name => mixHash 37 name.structHash
  | .mvar name => mixHash 41 name.structHash

private def Level.listStructHash (levels : List Level) : UInt64 :=
  levels.foldl (fun acc level => mixHash acc level.structHash) 43

private def Literal.structHash : Literal → UInt64
  | .nat value => mixHash 47 (hash value)
  | .str value => mixHash 53 (hash value)

private abbrev ExprHashCache := Std.HashMap USize UInt64

/--
Runtime structural hash compatible with `Expr.eq`.

This intentionally mirrors the fields observed by `Expr.eq`: lambda/forall
binder display names and binder annotations are ignored, let display names are
ignored while `nondep` is retained, and metadata payloads remain structural.
Pointer addresses are cache keys only; they never contribute to the hash value.
-/
private unsafe def Expr.structHashRuntimeGo
    (e : Expr)
    (cache : ExprHashCache) : UInt64 × ExprHashCache :=
  let key := ptrAddrUnsafe e
  match Std.HashMap.get? cache key with
  | some cached => (cached, cache)
  | none =>
      let (value, cache) :=
        match e with
        | .bvar index =>
            (mixHash 59 (hash index), cache)
        | .fvar name =>
            (mixHash 61 name.structHash, cache)
        | .mvar name =>
            (mixHash 67 name.structHash, cache)
        | .sort level =>
            (mixHash 71 level.structHash, cache)
        | .const name levels =>
            (mixHash 73 (mixHash name.structHash (Level.listStructHash levels)), cache)
        | .app fn arg =>
            let (fnHash, cache) := Expr.structHashRuntimeGo fn cache
            let (argHash, cache) := Expr.structHashRuntimeGo arg cache
            (mixHash 79 (mixHash fnHash argHash), cache)
        | .lam _ type body _ =>
            let (typeHash, cache) := Expr.structHashRuntimeGo type cache
            let (bodyHash, cache) := Expr.structHashRuntimeGo body cache
            (mixHash 83 (mixHash typeHash bodyHash), cache)
        | .forallE _ type body _ =>
            let (typeHash, cache) := Expr.structHashRuntimeGo type cache
            let (bodyHash, cache) := Expr.structHashRuntimeGo body cache
            (mixHash 89 (mixHash typeHash bodyHash), cache)
        | .letE _ type value body nondep =>
            let (typeHash, cache) := Expr.structHashRuntimeGo type cache
            let (valueHash, cache) := Expr.structHashRuntimeGo value cache
            let (bodyHash, cache) := Expr.structHashRuntimeGo body cache
            let fieldsHash :=
              mixHash typeHash (mixHash valueHash (mixHash bodyHash (hash nondep)))
            (mixHash 97 fieldsHash, cache)
        | .lit value =>
            (mixHash 101 value.structHash, cache)
        | .mdata metadata body =>
            let (bodyHash, cache) := Expr.structHashRuntimeGo body cache
            (mixHash 103 (mixHash (hash metadata) bodyHash), cache)
        | .proj typeName index body =>
            let (bodyHash, cache) := Expr.structHashRuntimeGo body cache
            let fieldsHash :=
              mixHash typeName.structHash (mixHash (hash index) bodyHash)
            (mixHash 107 fieldsHash, cache)
      (value, Std.HashMap.insert cache key value)

private unsafe def Expr.structHashRuntime
    (left right : Expr) : UInt64 × UInt64 :=
  let cache : ExprHashCache := Std.HashMap.emptyWithCapacity 128
  let (leftHash, cache) := Expr.structHashRuntimeGo left cache
  let (rightHash, _) := Expr.structHashRuntimeGo right cache
  (leftHash, rightHash)

private abbrev ExprEqPairCache := Std.HashSet (USize × USize)

private unsafe def exprEqPairKey (a b : Expr) : USize × USize :=
  let pa := ptrAddrUnsafe a
  let pb := ptrAddrUnsafe b
  if pa ≤ pb then (pa, pb) else (pb, pa)

/--
Runtime implementation of Lean 4.34-style expression structural equality.

The logical specification remains `Expr.eqSpec`. At runtime we additionally
use pointer identity and memoize already-compared expression pairs, matching the
two critical DAG-sharing fast paths used by Lean's C++ `expr_eq_fn`. The cache
only skips a pair after the same acyclic pair has already been entered, so it
does not change the structural-equality result.
-/
private unsafe def Expr.eqRuntimeGo
    (left right : Expr)
    (seen : ExprEqPairCache) : Bool × ExprEqPairCache :=
  if ptrEq left right then
    (true, seen)
  else
    let key := exprEqPairKey left right
    if seen.contains key then
      (true, seen)
    else
      let seen := seen.insert key
      match left, right with
      | .bvar a, .bvar b => (a == b, seen)
      | .fvar a, .fvar b => (Name.eq a b, seen)
      | .mvar a, .mvar b => (Name.eq a b, seen)
      | .sort a, .sort b => (Level.eq a b, seen)
      | .const n₁ ls₁, .const n₂ ls₂ =>
          (Name.eq n₁ n₂ && Level.listEq ls₁ ls₂, seen)
      | .app f₁ a₁, .app f₂ a₂ =>
          let (argsEq, seen) := Expr.eqRuntimeGo a₁ a₂ seen
          if !argsEq then
            (false, seen)
          else
            Expr.eqRuntimeGo f₁ f₂ seen
      | .lam _ t₁ b₁ _, .lam _ t₂ b₂ _
      | .forallE _ t₁ b₁ _, .forallE _ t₂ b₂ _ =>
          let (typesEq, seen) := Expr.eqRuntimeGo t₁ t₂ seen
          if !typesEq then
            (false, seen)
          else
            Expr.eqRuntimeGo b₁ b₂ seen
      | .letE _ t₁ v₁ b₁ d₁, .letE _ t₂ v₂ b₂ d₂ =>
          let (typesEq, seen) := Expr.eqRuntimeGo t₁ t₂ seen
          if !typesEq then
            (false, seen)
          else
            let (valuesEq, seen) := Expr.eqRuntimeGo v₁ v₂ seen
            if !valuesEq then
              (false, seen)
            else
              let (bodiesEq, seen) := Expr.eqRuntimeGo b₁ b₂ seen
              (bodiesEq && d₁ == d₂, seen)
      | .lit a, .lit b => (Literal.eq a b, seen)
      | .mdata m₁ e₁, .mdata m₂ e₂ =>
          let (exprsEq, seen) := Expr.eqRuntimeGo e₁ e₂ seen
          (exprsEq && m₁ == m₂, seen)
      | .proj n₁ i₁ e₁, .proj n₂ i₂ e₂ =>
          if !Name.eq n₁ n₂ || i₁ != i₂ then
            (false, seen)
          else
            Expr.eqRuntimeGo e₁ e₂ seen
      | _, _ => (false, seen)

private unsafe def Expr.eqRuntime (left right : Expr) : Bool :=
  if ptrEq left right then
    true
  else
    let (leftHash, rightHash) := Expr.structHashRuntime left right
    if leftHash != rightHash then
      false
    else
      let seen : ExprEqPairCache := Std.HashSet.emptyWithCapacity 64
      (Expr.eqRuntimeGo left right seen).1

@[implemented_by Expr.eqRuntime]
partial def Expr.eq (left right : Expr) : Bool :=
  Expr.eqSpec left right

/-- Diagnostic-only wrapper for profiling the runtime structural hash. -/
unsafe def Expr.debugStructHashRuntime (e : Expr) : UInt64 :=
  let cache : ExprHashCache := Std.HashMap.emptyWithCapacity 128
  (Expr.structHashRuntimeGo e cache).1

/-- Diagnostic-only wrapper for profiling pair-memoized equality without the hash gate. -/
unsafe def Expr.debugPairEqRuntime (left right : Expr) : Bool :=
  let seen : ExprEqPairCache := Std.HashSet.emptyWithCapacity 64
  (Expr.eqRuntimeGo left right seen).1

/--
Lean 4.34 `Expr.equal`-compatible binder-aware structural equality. Use this
only when binder names/annotations are semantically relevant to the caller.
Kernel quick-defeq/progress checks use `Expr.eq` instead.
-/
partial def Expr.equal : Expr → Expr → Bool
  | .bvar a, .bvar b => a == b
  | .fvar a, .fvar b => Name.eq a b
  | .mvar a, .mvar b => Name.eq a b
  | .sort a, .sort b => Level.eq a b
  | .const n₁ ls₁, .const n₂ ls₂ => Name.eq n₁ n₂ && Level.listEq ls₁ ls₂
  | .app f₁ a₁, .app f₂ a₂ => Expr.equal f₁ f₂ && Expr.equal a₁ a₂
  | .lam n₁ t₁ b₁ i₁, .lam n₂ t₂ b₂ i₂ =>
    Name.eq n₁ n₂ && Expr.equal t₁ t₂ && Expr.equal b₁ b₂ &&
      BinderInfo.eq i₁ i₂
  | .forallE n₁ t₁ b₁ i₁, .forallE n₂ t₂ b₂ i₂ =>
    Name.eq n₁ n₂ && Expr.equal t₁ t₂ && Expr.equal b₁ b₂ &&
      BinderInfo.eq i₁ i₂
  | .letE n₁ t₁ v₁ b₁ d₁, .letE n₂ t₂ v₂ b₂ d₂ =>
    Name.eq n₁ n₂ && Expr.equal t₁ t₂ && Expr.equal v₁ v₂ &&
      Expr.equal b₁ b₂ && d₁ == d₂
  | .lit a, .lit b => Literal.eq a b
  | .mdata m₁ e₁, .mdata m₂ e₂ => m₁ == m₂ && Expr.equal e₁ e₂
  | .proj n₁ i₁ e₁, .proj n₂ i₂ e₂ =>
    Name.eq n₁ n₂ && i₁ == i₂ && Expr.equal e₁ e₂
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

partial def Expr.hasLooseBVarAtCore
    (e : Expr) (index depth : Nat) : Bool :=
  match e with
  | .bvar i => i == index + depth
  | .app f a =>
      f.hasLooseBVarAtCore index depth ||
        a.hasLooseBVarAtCore index depth
  | .lam _ type body _ | .forallE _ type body _ =>
      type.hasLooseBVarAtCore index depth ||
        body.hasLooseBVarAtCore index (depth + 1)
  | .letE _ type value body _ =>
      type.hasLooseBVarAtCore index depth ||
        value.hasLooseBVarAtCore index depth ||
        body.hasLooseBVarAtCore index (depth + 1)
  | .mdata _ body | .proj _ _ body =>
      body.hasLooseBVarAtCore index depth
  | .fvar _ | .mvar _ | .sort _ | .const _ _ | .lit _ => false

def Expr.hasLooseBVarAt (e : Expr) (index : Nat) : Bool :=
  e.hasLooseBVarAtCore index 0

partial def Expr.hasLooseBVarInExplicitDomain
    (e : Expr) (bvarIdx : Nat) (considerRange : Bool) : Bool :=
  match e with
  | .forallE _ domain body binderInfo =>
      let dependency :=
        domain.hasLooseBVarAt bvarIdx &&
          (BinderInfo.eq binderInfo .default ||
            body.hasLooseBVarInExplicitDomain 0 considerRange)
      dependency ||
        body.hasLooseBVarInExplicitDomain (bvarIdx + 1) considerRange
  | other =>
      considerRange && other.hasLooseBVarAt bvarIdx

partial def Expr.inferImplicit
    (e : Expr) (numParams : Nat) (considerRange : Bool) : Expr :=
  match e, numParams with
  | .forallE name domain body binderInfo, n + 1 =>
      let body' := body.inferImplicit n considerRange
      let binderInfo' :=
        if BinderInfo.eq binderInfo .default &&
            body'.hasLooseBVarInExplicitDomain 0 considerRange then
          BinderInfo.implicit
        else
          binderInfo
      .forallE name domain body' binderInfo'
  | other, _ => other

partial def Expr.inferImplicitAll
    (e : Expr) (considerRange : Bool) : Expr :=
  match e with
  | .forallE name domain body binderInfo =>
      let body' := body.inferImplicitAll considerRange
      let binderInfo' :=
        if BinderInfo.eq binderInfo .default &&
            body'.hasLooseBVarInExplicitDomain 0 considerRange then
          BinderInfo.implicit
        else
          binderInfo
      .forallE name domain body' binderInfo'
  | other => other

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

def typeAnnotationOutParamName : Name :=
  .str .anonymous "outParam"

def typeAnnotationSemiOutParamName : Name :=
  .str .anonymous "semiOutParam"

def typeAnnotationOptParamName : Name :=
  .str .anonymous "optParam"

def typeAnnotationAutoParamName : Name :=
  .str .anonymous "autoParam"

/--
Lean 4.34 `Expr.consumeTypeAnnotations`: remove only leading
`outParam`, `semiOutParam`, `optParam`, and `autoParam` wrappers.
Annotations nested under another type constructor are intentionally untouched.
-/
partial def Expr.consumeTypeAnnotations (e : Expr) : Expr :=
  match e.getAppFn, e.getAppArgs with
  | .const name _, [arg] =>
      if Name.eq name typeAnnotationOutParamName ||
          Name.eq name typeAnnotationSemiOutParamName then
        arg.consumeTypeAnnotations
      else
        e
  | .const name _, [arg, _] =>
      if Name.eq name typeAnnotationOptParamName ||
          Name.eq name typeAnnotationAutoParamName then
        arg.consumeTypeAnnotations
      else
        e
  | _, _ => e

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
