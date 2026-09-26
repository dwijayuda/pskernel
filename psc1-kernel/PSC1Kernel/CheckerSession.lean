import PSC1Kernel.CheckerStateful

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

/-- Pure stateful checked inference; returns the next declaration-scoped session. -/
def checkStateful
    (session : CheckerSession)
    (e : Expr) : Except String (Expr × CheckerSession) := do
  let (result, state) ← PSC1Kernel.checkStateful session.context session.state e
  pure (result, { session with state := state })

/-- Pure stateful infer-only operation. -/
def inferStateful
    (session : CheckerSession)
    (e : Expr) : Except String (Expr × CheckerSession) := do
  let (result, state) ← PSC1Kernel.inferStateful session.context session.state e
  pure (result, { session with state := state })

/-- Pure stateful public WHNF operation. -/
def whnfStateful
    (session : CheckerSession)
    (e : Expr) : Except String (Expr × CheckerSession) := do
  let (result, state) ← PSC1Kernel.whnfStateful session.context session.state e
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
