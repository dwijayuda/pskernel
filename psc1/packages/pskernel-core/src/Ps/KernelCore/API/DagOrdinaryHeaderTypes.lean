import Ps.KernelCore.Checker.ExprV2.CheckState

/-
Private ordinary-inductive header analysis over one canonical append-only arena.
These records are internal state, not admission certificates. No environment or
generated declaration is published by header analysis.
-/
structure PsKernelExprV2OrdinaryOpenBinder where
  internalName : PsKernelName
  userName : PsKernelName
  type : Nat
  binderInfo : PsKernelBinderInfo

structure PsKernelExprV2OrdinaryOpenResult where
  context : PsKernelExprV2CheckContext
  state : PsKernelExprV2CheckState
  binders : List PsKernelExprV2OrdinaryOpenBinder
  result : Nat

structure PsKernelExprV2OrdinaryHeaderAnalysis where
  parameters : PsKernelExprV2OrdinaryOpenResult
  indices : PsKernelExprV2OrdinaryOpenResult
  resultLevel : PsKernelLevel

/- Constructor analysis resumes the parameter owner. The index arena is kept
   because returned index IDs can name appended nodes, but index-local caches,
   declaration references and freshness do not become constructor state. -/
def psKernelExprV2OrdinaryConstructorContext
    (analysis : PsKernelExprV2OrdinaryHeaderAnalysis) :
    PsKernelExprV2CheckContext :=
  analysis.parameters.context

def psKernelExprV2OrdinaryConstructorState
    (analysis : PsKernelExprV2OrdinaryHeaderAnalysis) :
    PsKernelExprV2CheckState :=
  psKernelExprV2CheckStateWithArena analysis.parameters.state
    analysis.indices.state.whnf.arena
