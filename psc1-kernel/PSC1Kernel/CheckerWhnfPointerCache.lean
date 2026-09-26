import Init.System.IO
import Init.Util
import Std.Data.HashMap
import PSC1Kernel.Environment
import PSC1Kernel.LocalContext

namespace PSC1Kernel

/--
Native-only WHNF cache entry.  The input expression and local declaration list
are retained, so their runtime addresses cannot be recycled while an entry is
live.  Hits require pointer identity, not structural hashing.
-/
structure CheckerWhnfPointerEntry where
  input : Expr
  lctxDecls : List LocalDecl
  lctxNextIndex : Nat
  output : Expr

abbrev CheckerWhnfPointerBuckets :=
  Std.HashMap USize (List CheckerWhnfPointerEntry)

namespace CheckerWhnfPointerBuckets

def empty : CheckerWhnfPointerBuckets :=
  Std.HashMap.emptyWithCapacity 256

private unsafe def findEntry?
    (input : Expr)
    (lctxDecls : List LocalDecl)
    (lctxNextIndex : Nat) :
    List CheckerWhnfPointerEntry → Option Expr
  | [] => none
  | entry :: rest =>
      if ptrEq entry.input input &&
          ptrEq entry.lctxDecls lctxDecls &&
          entry.lctxNextIndex == lctxNextIndex then
        some entry.output
      else
        findEntry? input lctxDecls lctxNextIndex rest

unsafe def get?
    (cache : CheckerWhnfPointerBuckets)
    (lctxDecls : List LocalDecl)
    (lctxNextIndex : Nat)
    (input : Expr) : Option Expr :=
  let key := ptrAddrUnsafe input
  match Std.HashMap.get? cache key with
  | some entries => findEntry? input lctxDecls lctxNextIndex entries
  | none => none

unsafe def insert
    (cache : CheckerWhnfPointerBuckets)
    (lctxDecls : List LocalDecl)
    (lctxNextIndex : Nat)
    (input output : Expr) : CheckerWhnfPointerBuckets :=
  let key := ptrAddrUnsafe input
  let entry : CheckerWhnfPointerEntry :=
    { input, lctxDecls, lctxNextIndex, output }
  let entries :=
    match Std.HashMap.get? cache key with
    | some values => entry :: values
    | none => [entry]
  Std.HashMap.insert cache key entries

end CheckerWhnfPointerBuckets

/--
One declaration-scoped native WHNF cache.  Environment pointer identity is the
scope boundary.  Keeping the environment in the state prevents address reuse
while entries remain reachable.  `maxNatSize` is included because reductions
may reject numerals at this resource boundary.
-/
structure CheckerWhnfPointerState where
  env? : Option Environment
  maxNatSize : Nat
  whnfCore : CheckerWhnfPointerBuckets
  deriving Nonempty

namespace CheckerWhnfPointerState

def empty : CheckerWhnfPointerState :=
  {
    env? := none
    maxNatSize := 0
    whnfCore := CheckerWhnfPointerBuckets.empty
  }
end CheckerWhnfPointerState

private initialize checkerWhnfPointerRef : IO.Ref CheckerWhnfPointerState ←
  IO.mkRef CheckerWhnfPointerState.empty

private unsafe def checkerWhnfRunIO
    {α : Type}
    (fallback : α)
    (action : IO α) : α :=
  match unsafeIO action with
  | .ok value => value
  | .error _ => fallback

private unsafe def checkerWhnfScopeMatches
    (state : CheckerWhnfPointerState)
    (env : Environment)
    (maxNatSize : Nat) : Bool :=
  match state.env? with
  | some cachedEnv =>
      ptrEq cachedEnv env && state.maxNatSize == maxNatSize
  | none => false

private unsafe def checkerWhnfStateFor
    (env : Environment)
    (maxNatSize : Nat) : IO CheckerWhnfPointerState := do
  let state ← checkerWhnfPointerRef.get
  if checkerWhnfScopeMatches state env maxNatSize then
    pure state
  else
    let fresh : CheckerWhnfPointerState :=
      {
        env? := some env
        maxNatSize := maxNatSize
        whnfCore := CheckerWhnfPointerBuckets.empty
      }
    checkerWhnfPointerRef.set fresh
    pure fresh

unsafe def checkerWhnfCoreLookupImpl
    (env : Environment)
    (lctxDecls : List LocalDecl)
    (lctxNextIndex maxNatSize : Nat)
    (enabled : Bool)
    (input : Expr) : Option Expr :=
  if !enabled then
    none
  else
    checkerWhnfRunIO none do
      let state ← checkerWhnfStateFor env maxNatSize
      pure (state.whnfCore.get? lctxDecls lctxNextIndex input)

/--
Pure semantics is always a miss.  Native code may reuse a result only for the
same environment object, local-context spine, configuration, and input object.
-/
@[implemented_by checkerWhnfCoreLookupImpl]
opaque checkerWhnfCoreLookup
    (env : Environment)
    (lctxDecls : List LocalDecl)
    (lctxNextIndex maxNatSize : Nat)
    (enabled : Bool)
    (input : Expr) : Option Expr := none

unsafe def checkerWhnfCoreStoreImpl
    (env : Environment)
    (lctxDecls : List LocalDecl)
    (lctxNextIndex maxNatSize : Nat)
    (enabled : Bool)
    (input output : Expr) : Expr :=
  if !enabled then
    output
  else
    checkerWhnfRunIO output do
      let state ← checkerWhnfStateFor env maxNatSize
      let cache := state.whnfCore.insert lctxDecls lctxNextIndex input output
      checkerWhnfPointerRef.set { state with whnfCore := cache }
      pure output

/-- Pure semantic specification is identity; the native implementation records the result. -/
@[implemented_by checkerWhnfCoreStoreImpl]
opaque checkerWhnfCoreStore
    (env : Environment)
    (lctxDecls : List LocalDecl)
    (lctxNextIndex maxNatSize : Nat)
    (enabled : Bool)
    (input output : Expr) : Expr := output

end PSC1Kernel
