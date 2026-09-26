import PSC1Kernel.TypeChecker

namespace PSC1Kernel

/--
A declaration-scoped checker boundary.

The initial representation is intentionally semantics-neutral: it owns one
`CheckerContext` and routes all public checker operations through that context.
Future Lean-4.34-faithful memo state belongs behind this boundary, not in the
persistent `Environment` and not in replay state. A session must never outlive
an environment mutation.
-/
structure CheckerSession where
  context : CheckerContext

namespace CheckerSession

def check (session : CheckerSession) (e : Expr) : Except String Expr :=
  PSC1Kernel.check session.context e

def infer (session : CheckerSession) (e : Expr) : Except String Expr :=
  PSC1Kernel.infer session.context e

def ensureSort (session : CheckerSession) (e : Expr) : Except String Level :=
  PSC1Kernel.ensureSort session.context e

def isProp (session : CheckerSession) (e : Expr) : Except String Bool :=
  PSC1Kernel.isProp session.context e

def isDefEq (session : CheckerSession) (a b : Expr) : Except String Bool :=
  PSC1Kernel.isDefEq session.context a b

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
  }

end Kernel

end PSC1Kernel
