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
Runtime identity for an immutable PSC1 environment. The canonical declaration
spine changes on every `addUnchecked`/`replaceUnchecked`, while
`constantIndex` is derived data and may be reconstructed without changing the
semantic environment. Quotient initialization changes behavior independently,
so it remains part of the scope key.
-/
private unsafe def checkerWhnfEnvironmentMatches
    (left right : Environment) : Bool :=
  checkerEnvironmentSameVersion left right

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

private initialize checkerWhnfMemoStatsRef : IO.Ref (Nat × Nat) ←
  IO.mkRef (0, 0)

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

unsafe def checkerWhnfMemoResetStatsIO : IO Unit :=
  checkerWhnfMemoStatsRef.set (0, 0)

unsafe def checkerWhnfMemoStatsIO : IO (Nat × Nat) :=
  checkerWhnfMemoStatsRef.get

private unsafe def checkerWhnfMemoRecordHit : IO Unit := do
  let (hits, misses) ← checkerWhnfMemoStatsRef.get
  checkerWhnfMemoStatsRef.set (hits + 1, misses)

private unsafe def checkerWhnfMemoRecordMiss : IO Unit := do
  let (hits, misses) ← checkerWhnfMemoStatsRef.get
  checkerWhnfMemoStatsRef.set (hits, misses + 1)

/--
Atomic native WHNF memoization. Lookup, computation, and successful insertion
are one implementation boundary, so the pure specification remains simply
`compute ()`. After a miss, the state is re-read after recursive computation
before inserting the outer result so nested memo calls cannot be overwritten.
Errors are never cached.
-/
unsafe def checkerWhnfMemoImpl
    (env : Environment)
    (lctx : LocalContext)
    (maxRecDepth maxNatSize : Nat)
    (enabled : Bool)
    (expr : Expr)
    (compute : Unit → Except String Expr) : Except String Expr :=
  if !enabled then
    compute ()
  else
    checkerWhnfRunIO (compute ()) do
      let state ← checkerWhnfStateFor env maxRecDepth maxNatSize
      match state.whnf.get? lctx expr with
      | some value =>
          checkerWhnfMemoRecordHit
          pure (.ok value)
      | none =>
          checkerWhnfMemoRecordMiss
          match compute () with
          | .error err =>
              pure (.error err)
          | .ok value =>
              let latest ← checkerWhnfStateFor env maxRecDepth maxNatSize
              checkerWhnfRuntimeRef.set
                { latest with whnf := latest.whnf.insert lctx expr value }
              pure (.ok value)

/--
Pure semantic definition of WHNF memoization: perform the computation.
The native implementation may reuse a previously successful result from the
same immutable checker scope, but must be extensionally equal to this function.
-/
@[implemented_by checkerWhnfMemoImpl]
opaque checkerWhnfMemo
    (env : Environment)
    (lctx : LocalContext)
    (maxRecDepth maxNatSize : Nat)
    (enabled : Bool)
    (expr : Expr)
    (compute : Unit → Except String Expr) : Except String Expr :=
  compute ()

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
    (expr result : Expr) : Except String Expr :=
  if !enabled then
    .ok result
  else
    checkerWhnfRunIO (.ok result) do
      let state ← checkerWhnfStateFor env maxRecDepth maxNatSize
      checkerWhnfRuntimeRef.set
        { state with whnfCore := state.whnfCore.insert lctx expr result }
      pure (.ok result)

/-- Pure semantics: successful identity. Native code records the WHNF-core result. -/
@[implemented_by checkerWhnfCoreCacheResultImpl]
opaque checkerWhnfCoreCacheResult
    (env : Environment)
    (lctx : LocalContext)
    (maxRecDepth maxNatSize : Nat)
    (enabled : Bool)
    (expr result : Expr) : Except String Expr := .ok result

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
    (expr result : Expr) : Except String Expr :=
  if !enabled then
    .ok result
  else
    checkerWhnfRunIO (.ok result) do
      let state ← checkerWhnfStateFor env maxRecDepth maxNatSize
      checkerWhnfRuntimeRef.set
        { state with whnf := state.whnf.insert lctx expr result }
      pure (.ok result)

/-- Pure semantics: successful identity. Native code records the public WHNF result. -/
@[implemented_by checkerWhnfCacheResultImpl]
opaque checkerWhnfCacheResult
    (env : Environment)
    (lctx : LocalContext)
    (maxRecDepth maxNatSize : Nat)
    (enabled : Bool)
    (expr result : Expr) : Except String Expr := .ok result

/-- Test-only diagnostic: bypass scope refresh and inspect the current WHNF map. -/
unsafe def checkerWhnfRawCachedImpl
    (lctx : LocalContext)
    (expr : Expr) : Option Expr :=
  checkerWhnfRunIO none do
    let state ← checkerWhnfRuntimeRef.get
    pure (state.whnf.get? lctx expr)

@[implemented_by checkerWhnfRawCachedImpl]
opaque checkerWhnfRawCached
    (lctx : LocalContext)
    (expr : Expr) : Option Expr := none

/-- Test-only diagnostic: does the currently retained scope match these inputs? -/
unsafe def checkerWhnfScopeMatchesCurrentImpl
    (env : Environment)
    (maxRecDepth maxNatSize : Nat) : Bool :=
  checkerWhnfRunIO false do
    let state ← checkerWhnfRuntimeRef.get
    pure (checkerWhnfScopeMatches state env maxRecDepth maxNatSize)

@[implemented_by checkerWhnfScopeMatchesCurrentImpl]
opaque checkerWhnfScopeMatchesCurrent
    (env : Environment)
    (maxRecDepth maxNatSize : Nat) : Bool := false

end PSC1Kernel
