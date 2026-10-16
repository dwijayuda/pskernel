import Ps.KernelCore.Architecture.CertifiedInstantiateMemo

/-!
The exact source implementation is faster on a long linear application
spine, while source-proved memoization is appropriate on shared DAG terms.
These are only work-selection guards; source correctness is proved
independently for every input by psKernelC0MemoizedInstantiate1_source.
-/

def c0AdaptiveInstLinear (depth : Nat) : PsKernelExpr :=
  (List.range depth).foldl
    (fun fn i => .app fn (.bvar (i % 4))) (.bvar 0)

def c0AdaptiveInstShared (depth : Nat) : PsKernelExpr :=
  (List.range depth).foldl (fun e _ => .app e e) (.bvar 0)

def c0AdaptiveInstBinders (depth : Nat) : PsKernelExpr :=
  (List.range depth).foldl
    (fun e _ => .lam .anonymous (.sort .zero) e .default) (.bvar 0)

def main : IO Unit := do
  let linear := c0AdaptiveInstLinear 512
  let shared := c0AdaptiveInstShared 26
  let deepBinder := c0AdaptiveInstBinders 16
  let shortBinder := c0AdaptiveInstBinders 6
  if psKernelC0InstMemoWorthwhile linear then
    throw (IO.userError "adaptive substitution: expensive trie chosen for linear spine")
  if !(psKernelC0InstMemoWorthwhile shared) then
    throw (IO.userError "adaptive substitution: huge shared DAG failed memo selection")
  if !(psKernelC0InstMemoWorthwhile deepBinder) then
    throw (IO.userError "adaptive substitution: deep binders failed memo selection")
  if psKernelC0InstMemoWorthwhile shortBinder then
    throw (IO.userError "adaptive substitution: short binders needlessly memoized")
  let binder : PsKernelName := .str .anonymous "a"
  let samples : List PsKernelExpr := [
    .bvar 0, .app (.bvar 0) (.bvar 1),
    .forallE binder (.sort .zero) (.bvar 1) .implicit,
    .letE binder (.sort .zero) (.bvar 0) (.bvar 1) false,
    shortBinder, deepBinder, linear, c0AdaptiveInstShared 8
  ]
  for expr in samples do
    for subst in [PsKernelExpr.bvar 0, PsKernelExpr.fvar binder] do
      let _fullSource :
          psKernelC0MemoizedInstantiate1 expr subst =
            psKernelExprInstantiate1 expr subst :=
        psKernelC0MemoizedInstantiate1_source expr subst
      let fast := psKernelC0MemoizedInstantiate1 expr subst
      let source := psKernelExprInstantiate1 expr subst
      if !psKernelExprEqual fast source then
        throw (IO.userError "adaptive substitution: result differs from source")
  -- Do not expand the shared DAG with the original source evaluator;
  -- the universally Lean-checked equality theorem already proves it.
  let _sharedSource :
      psKernelC0MemoizedInstantiate1 shared (.bvar 1) =
        psKernelExprInstantiate1 shared (.bvar 1) :=
    psKernelC0MemoizedInstantiate1_source shared (.bvar 1)
  let begin ← IO.monoNanosNow
  let result := psKernelC0MemoizedInstantiate1 shared (.bvar 1)
  let finish ← IO.monoNanosNow
  if psKernelExprGetAppNumArgs result != 26 then
    throw (IO.userError "adaptive substitution: incorrect shared root spine")
  IO.println s!"C0_ADAPTIVE_INSTANTIATION source=Lean_proved linear=direct shared=memo long_binders=memo small_binders=direct shared_ms={(finish-begin)/1000000}"
