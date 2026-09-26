import Init.System.IO
import Init.Util
import Std.Data.HashMap
import PSC1Kernel.CheckerCacheRuntime

namespace PSC1Kernel

/--
A closed expression has the same WHNF in every local context for one immutable
checker environment/configuration. Expressions containing FVars remain scoped
by the complete local context because PSC1's current pure checker may reuse an
internal FVar name in sibling scopes.
-/
def checkerWhnfNeedsLocalContext (expr : Expr) : Bool :=
  expr.hasFVar

structure CheckerScopedExprKey where
  lctx : LocalContext
  expr : Expr

instance : BEq CheckerScopedExprKey where
  beq a b :=
    Expr.eq a.expr b.expr &&
      (if checkerWhnfNeedsLocalContext a.expr then
        checkerLocalContextEq a.lctx b.lctx
       else
        true)

instance : Hashable CheckerScopedExprKey where
  hash key :=
    let exprHash := checkerExprHash key.expr
    if checkerWhnfNeedsLocalContext key.expr then
      checkerMixHash (checkerLocalContextHash key.lctx)
        (checkerMixHash 139 exprHash)
    else
      checkerMixHash 149 exprHash

abbrev CheckerScopedExprMap := Std.HashMap CheckerScopedExprKey Expr

namespace CheckerScopedExprMap

def empty : CheckerScopedExprMap :=
  Std.HashMap.emptyWithCapacity 256

def get?
    (cache : CheckerScopedExprMap)
    (lctx : LocalContext)
    (expr : Expr) : Option Expr :=
  Std.HashMap.get? cache (CheckerScopedExprKey.mk lctx expr)

def insert
    (cache : CheckerScopedExprMap)
    (lctx : LocalContext)
    (expr result : Expr) : CheckerScopedExprMap :=
  Std.HashMap.insert cache (CheckerScopedExprKey.mk lctx expr) result

end CheckerScopedExprMap

/--
Runtime identity for an immutable PSC1 environment. `Environment` itself is a
pure wrapper and can be reboxed, so pointer equality on the wrapper is too
strict. The declaration list and derived index are persistent payloads; any
semantic environment mutation replaces at least one of them, while quotient
initialization is tracked explicitly.
-/
private unsafe def checkerWhnfEnvironmentMatches
    (left right : Environment) : Bool :=
  ptrEq left.constants right.constants &&
    ptrEq left.constantIndex right.constantIndex &&
    left.quotInitialized == right.quotInitialized

/-- Native runtime counterpart of Lean 4.34's `m_whnf_core` and `m_whnf`. -/
structure CheckerWhnfRuntimeState where
  env? : Option Environment
  maxRecDepth : Nat
  maxNatSize : Nat
  whnfCore : CheckerScopedExprMap
  whnf : CheckerScopedExprMap
  deriving Nonempty

namespace CheckerWhnfRuntimeState

def empty : CheckerWhnfRuntimeState :=
  {
    env? := none
    maxRecDepth := 0
    maxNatSize := 0
    whnfCore := CheckerScopedExprMap.empty
    whnf := CheckerScopedExprMap.empty
  }
end CheckerWhnfRuntimeState

private initialize checkerWhnfRuntimeRef : IO.Ref CheckerWhnfRuntimeState ←
  IO.mkRef CheckerWhnfRuntimeState.empty

private unsafe def checkerWhnfRunIO
    {α : Type}
    (fallback : α)
    (action : IO α) : α :=
  match unsafeIO action with
  | .ok value => value
  | .error _ => fallback

private unsafe def checkerWhnfScopeMatches
    (state : CheckerWhnfRuntimeState)
    (env : Environment)
    (maxRecDepth maxNatSize : Nat) : Bool :=
  match state.env? with
  | some cachedEnv =>
      checkerWhnfEnvironmentMatches cachedEnv env &&
        state.maxRecDepth == maxRecDepth &&
        state.maxNatSize == maxNatSize
  | none => false

private unsafe def checkerWhnfStateFor
    (env : Environment)
    (maxRecDepth maxNatSize : Nat) : IO CheckerWhnfRuntimeState := do
  let state ← checkerWhnfRuntimeRef.get
  if checkerWhnfScopeMatches state env maxRecDepth maxNatSize then
    pure state
  else
    let fresh : CheckerWhnfRuntimeState :=
      {
        env? := some env
        maxRecDepth := maxRecDepth
        maxNatSize := maxNatSize
        whnfCore := CheckerScopedExprMap.empty
        whnf := CheckerScopedExprMap.empty
      }
    checkerWhnfRuntimeRef.set fresh
    pure fresh

unsafe def checkerWhnfCoreCachedImpl
    (env : Environment)
    (lctx : LocalContext)
    (maxRecDepth maxNatSize : Nat)
    (enabled : Bool)
    (expr : Expr) : Option Expr :=
  if !enabled then
    none
  else
    checkerWhnfRunIO none do
      let state ← checkerWhnfStateFor env maxRecDepth maxNatSize
      pure (state.whnfCore.get? lctx expr)

/-- Pure semantics: cache miss. Native code may reuse a proven WHNF-core result. -/
@[implemented_by checkerWhnfCoreCachedImpl]
opaque checkerWhnfCoreCached
    (env : Environment)
    (lctx : LocalContext)
    (maxRecDepth maxNatSize : Nat)
    (enabled : Bool)
    (expr : Expr) : Option Expr := none

unsafe def checkerWhnfCoreCacheResultImpl
    (env : Environment)
    (lctx : LocalContext)
    (maxRecDepth maxNatSize : Nat)
    (enabled : Bool)
    (expr result : Expr) : Expr :=
  if !enabled then
    result
  else
    checkerWhnfRunIO result do
      let state ← checkerWhnfStateFor env maxRecDepth maxNatSize
      checkerWhnfRuntimeRef.set
        { state with whnfCore := state.whnfCore.insert lctx expr result }
      pure result

/-- Pure semantics: identity. Native code records the WHNF-core result. -/
@[implemented_by checkerWhnfCoreCacheResultImpl]
opaque checkerWhnfCoreCacheResult
    (env : Environment)
    (lctx : LocalContext)
    (maxRecDepth maxNatSize : Nat)
    (enabled : Bool)
    (expr result : Expr) : Expr := result

unsafe def checkerWhnfCachedImpl
    (env : Environment)
    (lctx : LocalContext)
    (maxRecDepth maxNatSize : Nat)
    (enabled : Bool)
    (expr : Expr) : Option Expr :=
  if !enabled then
    none
  else
    checkerWhnfRunIO none do
      let state ← checkerWhnfStateFor env maxRecDepth maxNatSize
      pure (state.whnf.get? lctx expr)

/-- Pure semantics: cache miss. Native code may reuse a proven public WHNF. -/
@[implemented_by checkerWhnfCachedImpl]
opaque checkerWhnfCached
    (env : Environment)
    (lctx : LocalContext)
    (maxRecDepth maxNatSize : Nat)
    (enabled : Bool)
    (expr : Expr) : Option Expr := none

unsafe def checkerWhnfCacheResultImpl
    (env : Environment)
    (lctx : LocalContext)
    (maxRecDepth maxNatSize : Nat)
    (enabled : Bool)
    (expr result : Expr) : Expr :=
  if !enabled then
    result
  else
    checkerWhnfRunIO result do
      let state ← checkerWhnfStateFor env maxRecDepth maxNatSize
      checkerWhnfRuntimeRef.set
        { state with whnf := state.whnf.insert lctx expr result }
      pure result

/-- Pure semantics: identity. Native code records the public WHNF result. -/
@[implemented_by checkerWhnfCacheResultImpl]
opaque checkerWhnfCacheResult
    (env : Environment)
    (lctx : LocalContext)
    (maxRecDepth maxNatSize : Nat)
    (enabled : Bool)
    (expr result : Expr) : Expr := result

end PSC1Kernel
