import PSC1Kernel.CheckerDefEqStatefulReduced

namespace PSC1Kernel

/--
A declaration-scoped checker boundary.

The session owns one immutable checker context plus pure memo state. Stateful
operations return the next session explicitly, so memoization cannot leak
across environment mutation boundaries.
-/
structure CheckerSession where
  context : CheckerContext
  state : CheckerState := .empty

namespace CheckerSession

/-- Compatibility one-shot checked inference. -/
def check (session : CheckerSession) (e : Expr) : Except String Expr :=
  PSC1Kernel.check session.context e

/-- Compatibility one-shot infer-only operation. -/
def infer (session : CheckerSession) (e : Expr) : Except String Expr :=
  PSC1Kernel.infer session.context e

def ensureSort (session : CheckerSession) (e : Expr) : Except String Level :=
  PSC1Kernel.ensureSort session.context e

def isProp (session : CheckerSession) (e : Expr) : Except String Bool :=
  PSC1Kernel.isProp session.context e

def isDefEq (session : CheckerSession) (a b : Expr) : Except String Bool :=
  PSC1Kernel.isDefEq session.context a b

/--
Pure stateful checked inference. Application checks use the same recursive
defeq algorithm as the session. Defeq normalization and recursive reduction
share one declaration-scoped CheckerState.
-/
def checkStateful
    (session : CheckerSession)
    (e : Expr) : Except String (Expr × CheckerSession) := do
  let (result, state) ←
    PSC1Kernel.checkStatefulWith StatefulDefEqReduced.isDefEq
      session.context session.state e
  pure (result, { session with state := state })

/-- Pure stateful infer-only operation using the shared recursive checker state. -/
def inferStateful
    (session : CheckerSession)
    (e : Expr) : Except String (Expr × CheckerSession) := do
  let (result, state) ←
    PSC1Kernel.inferStatefulWith StatefulDefEqReduced.isDefEq
      session.context session.state e
  pure (result, { session with state := state })

/-- Pure stateful public WHNF operation with stateful Nat/Quot/recursor reduction. -/
def whnfStateful
    (session : CheckerSession)
    (e : Expr) : Except String (Expr × CheckerSession) := do
  let (result, state) ←
    StatefulReduction.whnf StatefulDefEqReduced.isDefEq
      session.context session.state e
  pure (result, { session with state := state })

/-- Stateful `ensure_sort`: normalize with the declaration-scoped WHNF cache. -/
def ensureSortStateful
    (session : CheckerSession)
    (e : Expr) : Except String (Level × CheckerSession) := do
  let (reduced, next) ← session.whnfStateful e
  match reduced with
  | .sort level => pure (level, next)
  | _ => throw "expected sort"

/-- Stateful `is_prop`, matching infer-only then sort-normalization order. -/
def isPropStateful
    (session : CheckerSession)
    (e : Expr) : Except String (Bool × CheckerSession) := do
  let (type, next1) ← session.inferStateful e
  let (level, next2) ← next1.ensureSortStateful type
  pure (Level.normalizesToZero level, next2)

/-- Pure declaration-scoped recursive definitional equality with stateful reduction. -/
def isDefEqStateful
    (session : CheckerSession)
    (a b : Expr) : Except String (Bool × CheckerSession) := do
  let (result, state) ←
    StatefulDefEqReduced.isDefEq session.context session.state a b
  pure (result, { session with state := state })

end CheckerSession

namespace Kernel

/-- Create one checker session for exactly one declaration/environment view. -/
def mkCheckerSession
    (env : Environment)
    (levelParams : List Name)
    (safety : DefinitionSafety)
    (maxRecDepth : Nat := 0)
    (maxNatSize : Nat := leanNatMaxSizeDefault)
    (nativeEvaluator : Option NativeEvaluator := none) : CheckerSession :=
  {
    context := {
      env := env
      lctx := .empty
      levelParams := levelParams
      safety := safety
      eagerReduce := false
      nativeEvaluator := nativeEvaluator
      maxRecDepth := maxRecDepth
      maxNatSize := maxNatSize
      recDepth := 0
    }
    state := .empty
  }

end Kernel

end PSC1Kernel
