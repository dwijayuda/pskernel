import Init.System.IO
import PSC1Kernel.Environment
import PSC1Kernel.CheckerState

namespace PSC1Kernel

/--
Opaque-by-convention runtime handle for declaration-scoped checker memo state.

Its pure/reference meaning is intentionally empty: memoization is an execution
optimization only. The compiled implementation stores an `IO.Ref CheckerState`
behind this handle. A fresh handle must be created for each immutable checker
environment/session.
-/
structure CheckerRuntimeCache where
  marker : Nat

namespace CheckerRuntimeCache

private unsafe def freshForImpl (_env : Environment) : CheckerRuntimeCache :=
  let ref := unsafeBaseIO (IO.mkRef CheckerState.empty)
  unsafeCast ref

/--
Create declaration-scoped runtime memo state. The pure specification carries
no mutable state; the compiled implementation allocates the cache.
-/
@[implemented_by freshForImpl]
def freshFor (_env : Environment) : CheckerRuntimeCache :=
  { marker := 0 }

private unsafe def withClosedSuccessImpl
    (cache : CheckerRuntimeCache)
    (left right : Expr)
    (compute : Unit → Except String Bool) : Except String Bool :=
  -- Current CheckerContext local-name allocation may reuse sibling FVar ids.
  -- Until fresh ids are session-global, only closed pairs are safe cache keys.
  if left.hasFVar || right.hasFVar then
    compute ()
  else
    let ref : IO.Ref CheckerState := unsafeCast cache
    -- Keep the complete read/compute/write sequence inside one BaseIO action.
    -- Escaping a write as an unused pure value allows dead-code elimination to
    -- erase the mutation; returning the action's result forces its sequencing.
    unsafeBaseIO do
      let state ← ref.get
      if state.success.contains left right then
        pure (.ok true)
      else
        match compute () with
        | .ok true =>
            ref.modify fun current =>
              { current with success := current.success.insert left right }
            pure (.ok true)
        | result =>
            pure result

/--
Run one definitional-equality computation with declaration-scoped successful
pair reuse. The reference definition is exactly `compute ()`; therefore the
cache cannot alter the pure checker semantics.
-/
@[implemented_by withClosedSuccessImpl]
def withClosedSuccess
    (_cache : CheckerRuntimeCache)
    (_left _right : Expr)
    (compute : Unit → Except String Bool) : Except String Bool :=
  compute ()

end CheckerRuntimeCache

end PSC1Kernel
