import Ps.KernelCore.Checker.Session
import Ps.KernelCore.Runtime.Acceleration.CachePolicy

/-! Regression for metatheory-discovered local FVar semantic-cache escape. -/
def main : IO Unit := do
  let source := psKernelMkCheckerSession psKernelEnvironmentEmpty []
    .safe 4096 psKernelLeanNatMaxSizeDefault
  let name : PsKernelName := .str .anonymous "scoped"
  let key : PsKernelExpr := .fvar name
  let typ : PsKernelExpr := .sort .zero
  let local := psKernelLocalContextAddLocal
    source.context.localContext name name typ .default
  let ctx := psKernelCheckerContextWithLocalContext source.context local
  if psKernelSemanticCacheEligible key ||
      psKernelSemanticCacheEligible (.app typ key) ||
      psKernelSemanticPairCacheEligible typ key ||
      psKernelInferCacheEligible true key then
    throw (IO.userError "semantic cache: local FVar remains eligible")
  let checked ← match psKernelCheckerCheck 4096 ctx source.state key with
    | .ok answer => pure answer
    | .error e => throw (IO.userError ("valid FVar rejected: " ++ e))
  if (psKernelExprMapGet checked.snd.checkedInfer key).isSome then
    throw (IO.userError "semantic cache: scoped type published")
  let forged := psKernelCheckerStateWithCheckedInfer source.state
    (psKernelExprMapInsert source.state.checkedInfer key typ)
  match psKernelCheckerCheck 4096 source.context forged key with
  | .ok _ => throw (IO.userError "semantic cache: foreign scope FVar accepted")
  | .error _ => pure ()
  let forgedInfer := psKernelCheckerStateWithInferOnly source.state
    (psKernelExprMapInsert source.state.inferOnly key typ)
  match psKernelCheckerInfer 4096 source.context forgedInfer key with
  | .ok _ => throw (IO.userError "semantic cache: stale infer-only accepted")
  | .error _ => pure ()
  let child := {checked.snd with
    nextFresh := checked.snd.nextFresh + 3
    success := psKernelExprPairSetInsert checked.snd.success key typ
    whnf := psKernelExprMapInsert checked.snd.whnf key typ }
  let restored := psKernelCheckerStateExitLocalScope source.state child
  if restored.nextFresh != child.nextFresh ||
      (psKernelExprMapGet restored.whnf key).isSome ||
      psKernelExprPairSetContains restored.success key typ then
    throw (IO.userError "semantic cache: binder state leaked")
  IO.println "C0_METATHEORY_SCOPE fvar_keys=blocked wrong_context=error scope_caches=restored monotone_fresh=pass"
