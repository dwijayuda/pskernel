import Init.System.IO
import Init.Util
import Std.Data.HashMap
import PSC1Kernel.CheckerState
import PSC1Kernel.Environment
import PSC1Kernel.LocalContext

namespace PSC1Kernel

/--
Runtime-only local-context key for checker memoization.

`userName` and binder presentation are intentionally ignored: the kernel only
observes an existing local through its internal name, kind, type, and (for a
let) value. `nextIndex` is included because it controls fresh FVar allocation
when recursive defeq opens binders.
-/
partial def checkerLocalDeclEq : LocalDecl → LocalDecl → Bool
  | .localDecl li ln _ lt _, .localDecl ri rn _ rt _ =>
      li == ri && Name.eq ln rn && Expr.eq lt rt
  | .letDecl li ln _ lt lv, .letDecl ri rn _ rt rv =>
      li == ri && Name.eq ln rn && Expr.eq lt rt && Expr.eq lv rv
  | _, _ => false

partial def checkerLocalDeclsEq : List LocalDecl → List LocalDecl → Bool
  | [], [] => true
  | left :: leftRest, right :: rightRest =>
      checkerLocalDeclEq left right && checkerLocalDeclsEq leftRest rightRest
  | _, _ => false

def checkerLocalContextEq (left right : LocalContext) : Bool :=
  left.nextIndex == right.nextIndex &&
    checkerLocalDeclsEq left.decls right.decls

partial def checkerLocalDeclHash : LocalDecl → UInt64
  | .localDecl index name _ type _ =>
      checkerMixHash 109 <|
        checkerMixHash (hash index) <|
          checkerMixHash (checkerNameHash name) (checkerExprHash type)
  | .letDecl index name _ type value =>
      checkerMixHash 113 <|
        checkerMixHash (hash index) <|
          checkerMixHash (checkerNameHash name) <|
            checkerMixHash (checkerExprHash type) (checkerExprHash value)

partial def checkerLocalDeclsHash : List LocalDecl → UInt64
  | [] => 127
  | decl :: rest =>
      checkerMixHash (checkerLocalDeclHash decl) (checkerLocalDeclsHash rest)

def checkerLocalContextHash (ctx : LocalContext) : UInt64 :=
  checkerMixHash (hash ctx.nextIndex) (checkerLocalDeclsHash ctx.decls)

structure CheckerScopedExprPairKey where
  lctx : LocalContext
  left : Expr
  right : Expr

instance : BEq CheckerScopedExprPairKey where
  beq a b :=
    checkerLocalContextEq a.lctx b.lctx &&
      ((Expr.eq a.left b.left && Expr.eq a.right b.right) ||
       (Expr.eq a.left b.right && Expr.eq a.right b.left))

instance : Hashable CheckerScopedExprPairKey where
  hash key :=
    let left := checkerExprHash key.left
    let right := checkerExprHash key.right
    checkerMixHash (checkerLocalContextHash key.lctx)
      (checkerMixHash 131 (left + right + left * right))

abbrev CheckerScopedExprPairSet := Std.HashMap CheckerScopedExprPairKey Unit

namespace CheckerScopedExprPairSet

def empty : CheckerScopedExprPairSet :=
  Std.HashMap.emptyWithCapacity 128

def contains
    (set : CheckerScopedExprPairSet)
    (lctx : LocalContext)
    (left right : Expr) : Bool :=
  (Std.HashMap.get? set (CheckerScopedExprPairKey.mk lctx left right)).isSome

def insert
    (set : CheckerScopedExprPairSet)
    (lctx : LocalContext)
    (left right : Expr) : CheckerScopedExprPairSet :=
  Std.HashMap.insert set (CheckerScopedExprPairKey.mk lctx left right) ()

end CheckerScopedExprPairSet

/--
One native cache scope. Holding `env` keeps its runtime object alive, so pointer
identity cannot be recycled while the cache can still return a hit. A scope
change discards the old maps; races can therefore lose cache entries, but they
cannot manufacture a hit for a different environment.
-/
structure CheckerDefEqRuntimeState where
  env? : Option Environment
  maxRecDepth : Nat
  maxNatSize : Nat
  success : CheckerScopedExprPairSet
  failure : CheckerScopedExprPairSet
  deriving Nonempty

namespace CheckerDefEqRuntimeState

def empty : CheckerDefEqRuntimeState :=
  {
    env? := none
    maxRecDepth := 0
    maxNatSize := 0
    success := CheckerScopedExprPairSet.empty
    failure := CheckerScopedExprPairSet.empty
  }
end CheckerDefEqRuntimeState

private initialize checkerDefEqRuntimeRef : IO.Ref CheckerDefEqRuntimeState ←
  IO.mkRef CheckerDefEqRuntimeState.empty

private unsafe def checkerDefEqRunIO
    {α : Type}
    (fallback : α)
    (action : IO α) : α :=
  match unsafeIO action with
  | .ok value => value
  | .error _ => fallback

private unsafe def checkerDefEqScopeMatches
    (state : CheckerDefEqRuntimeState)
    (env : Environment)
    (maxRecDepth maxNatSize : Nat) : Bool :=
  match state.env? with
  | some cachedEnv =>
      ptrEq cachedEnv env &&
        state.maxRecDepth == maxRecDepth &&
        state.maxNatSize == maxNatSize
  | none => false

private unsafe def checkerDefEqStateFor
    (env : Environment)
    (maxRecDepth maxNatSize : Nat) : IO CheckerDefEqRuntimeState := do
  let state ← checkerDefEqRuntimeRef.get
  if checkerDefEqScopeMatches state env maxRecDepth maxNatSize then
    pure state
  else
    let fresh : CheckerDefEqRuntimeState :=
      {
        env? := some env
        maxRecDepth := maxRecDepth
        maxNatSize := maxNatSize
        success := CheckerScopedExprPairSet.empty
        failure := CheckerScopedExprPairSet.empty
      }
    checkerDefEqRuntimeRef.set fresh
    pure fresh

private unsafe def checkerDefEqSuccessCachedImpl
    (env : Environment)
    (lctx : LocalContext)
    (maxRecDepth maxNatSize : Nat)
    (enabled : Bool)
    (left right : Expr) : Bool :=
  if !enabled then
    false
  else
    checkerDefEqRunIO false do
      let state ← checkerDefEqStateFor env maxRecDepth maxNatSize
      pure (state.success.contains lctx left right)

/--
Pure semantic specification: a cache miss. The native implementation may
return a previously proven success from the same checker scope.
-/
@[implemented_by checkerDefEqSuccessCachedImpl]
opaque checkerDefEqSuccessCached
    (env : Environment)
    (lctx : LocalContext)
    (maxRecDepth maxNatSize : Nat)
    (enabled : Bool)
    (left right : Expr) : Bool := false

private unsafe def checkerDefEqCacheSuccessResultImpl
    (env : Environment)
    (lctx : LocalContext)
    (maxRecDepth maxNatSize : Nat)
    (enabled : Bool)
    (left right : Expr)
    (result : Bool) : Bool :=
  if !enabled || !result then
    result
  else
    checkerDefEqRunIO result do
      let state ← checkerDefEqStateFor env maxRecDepth maxNatSize
      checkerDefEqRuntimeRef.set
        { state with success := state.success.insert lctx left right }
      pure result

/--
Pure semantic specification: identity on the computed defeq result. The native
implementation records successful pairs without changing that result.
-/
@[implemented_by checkerDefEqCacheSuccessResultImpl]
opaque checkerDefEqCacheSuccessResult
    (env : Environment)
    (lctx : LocalContext)
    (maxRecDepth maxNatSize : Nat)
    (enabled : Bool)
    (left right : Expr)
    (result : Bool) : Bool := result

private unsafe def checkerDefEqFailureCachedImpl
    (env : Environment)
    (lctx : LocalContext)
    (maxRecDepth maxNatSize : Nat)
    (enabled : Bool)
    (left right : Expr) : Bool :=
  if !enabled then
    false
  else
    checkerDefEqRunIO false do
      let state ← checkerDefEqStateFor env maxRecDepth maxNatSize
      pure (state.failure.contains lctx left right)

/-- Native-only negative-cache lookup for Lean 4.34 lazy-delta argument checks. -/
@[implemented_by checkerDefEqFailureCachedImpl]
opaque checkerDefEqFailureCached
    (env : Environment)
    (lctx : LocalContext)
    (maxRecDepth maxNatSize : Nat)
    (enabled : Bool)
    (left right : Expr) : Bool := false

private unsafe def checkerDefEqCacheFailureResultImpl
    (env : Environment)
    (lctx : LocalContext)
    (maxRecDepth maxNatSize : Nat)
    (enabled : Bool)
    (left right : Expr)
    (result : Bool) : Bool :=
  if !enabled || result then
    result
  else
    checkerDefEqRunIO result do
      let state ← checkerDefEqStateFor env maxRecDepth maxNatSize
      checkerDefEqRuntimeRef.set
        { state with failure := state.failure.insert lctx left right }
      pure result

/--
Pure semantic specification: identity. Native code records only a failed
same-definition lazy-delta argument comparison, matching Lean 4.34's narrow
negative-cache use.
-/
@[implemented_by checkerDefEqCacheFailureResultImpl]
opaque checkerDefEqCacheFailureResult
    (env : Environment)
    (lctx : LocalContext)
    (maxRecDepth maxNatSize : Nat)
    (enabled : Bool)
    (left right : Expr)
    (result : Bool) : Bool := result

end PSC1Kernel
