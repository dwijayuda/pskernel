import Ps.KernelCore.Metatheory.Judgments

/-
Standard contextual closure lemmas for the independent reduction relation.

These are semantic congruence facts, not executable shortcuts.  They are shared
by WHNF, primitive reduction, projection, and recursor proofs.
-/

theorem psKernelReductionClosure_transitive
    (environment : PsKernelEnvironment)
    (localContext : PsKernelLocalContext)
    (left middle right : PsKernelExpr)
    (hLeft :
      PsKernelReductionClosure
        environment localContext left middle)
    (hRight :
      PsKernelReductionClosure
        environment localContext middle right) :
    PsKernelReductionClosure
      environment localContext left right :=
  PsKernelReductionClosure.trans
    left middle right hLeft hRight


theorem psKernelReductionClosure_applyArgsCheap
    (environment : PsKernelEnvironment)
    (localContext : PsKernelLocalContext)
    (args : List PsKernelExpr)
    (left right : PsKernelExpr)
    (hReduction :
      PsKernelReductionClosure
        environment localContext left right) :
    PsKernelReductionClosure
      environment
      localContext
      (psKernelExprApplyArgsCheap left args)
      (psKernelExprApplyArgsCheap right args) := by
  induction args generalizing left right with
  | nil =>
      simpa [
        psKernelExprApplyArgsCheap,
        psKernelExprApplyArgsCheapWorker
      ] using hReduction
  | cons arg rest ih =>
      have hApp :
          PsKernelReductionClosure
            environment
            localContext
            (PsKernelExpr.app left arg)
            (PsKernelExpr.app right arg) :=
        PsKernelReductionClosure.appFn
          left right arg hReduction
      simpa [
        psKernelExprApplyArgsCheap,
        psKernelExprApplyArgsCheapWorker
      ] using
        ih
          (PsKernelExpr.app left arg)
          (PsKernelExpr.app right arg)
          hApp


theorem psKernelReductionClosure_applyArgs
    (environment : PsKernelEnvironment)
    (localContext : PsKernelLocalContext)
    (args : List PsKernelExpr)
    (left right : PsKernelExpr)
    (hReduction :
      PsKernelReductionClosure
        environment localContext left right) :
    PsKernelReductionClosure
      environment
      localContext
      (psKernelApplyArgs left args)
      (psKernelApplyArgs right args) := by
  induction args generalizing left right with
  | nil =>
      simpa [
        psKernelApplyArgs,
        psKernelApplyArgsWorker
      ] using hReduction
  | cons arg rest ih =>
      have hApp :
          PsKernelReductionClosure
            environment
            localContext
            (PsKernelExpr.app left arg)
            (PsKernelExpr.app right arg) :=
        PsKernelReductionClosure.appFn
          left right arg hReduction
      simpa [
        psKernelApplyArgs,
        psKernelApplyArgsWorker
      ] using
        ih
          (PsKernelExpr.app left arg)
          (PsKernelExpr.app right arg)
          hApp


/-
Application-spine reconstruction.

The executable WHNF worker decomposes an application into a head and argument
list, reduces the head, then rebuilds the spine.  These lemmas show that the
decomposition/rebuild round trip is exact and therefore contextual reduction of
the head is semantic reduction of the original application.
-/

theorem psKernelExprGetAppFnArgsWorker_reconstruct
    (expr : PsKernelExpr)
    (suffix : List PsKernelExpr) :
    let spine :=
      psKernelExprGetAppFnArgsWorker expr suffix
    psKernelExprApplyArgsCheap
        (Prod.fst spine)
        (Prod.snd spine) =
      psKernelExprApplyArgsCheap expr suffix := by
  induction expr generalizing suffix <;>
    simp [
      psKernelExprGetAppFnArgsWorker,
      psKernelExprApplyArgsCheap,
      psKernelExprApplyArgsCheapWorker,
      *
    ]


theorem psKernelExprGetAppFnArgs_reconstruct
    (expr : PsKernelExpr) :
    let spine := psKernelExprGetAppFnArgs expr
    psKernelExprApplyArgsCheap
        (Prod.fst spine)
        (Prod.snd spine) =
      expr := by
  simpa [
    psKernelExprGetAppFnArgs,
    psKernelExprApplyArgsCheap,
    psKernelExprApplyArgsCheapWorker
  ] using
    psKernelExprGetAppFnArgsWorker_reconstruct
      expr
      List.nil


theorem psKernelReductionClosure_appSpineHead
    (environment : PsKernelEnvironment)
    (localContext : PsKernelLocalContext)
    (expr reducedHead : PsKernelExpr)
    (hHead :
      PsKernelReductionClosure
        environment
        localContext
        (Prod.fst (psKernelExprGetAppFnArgs expr))
        reducedHead) :
    PsKernelReductionClosure
      environment
      localContext
      expr
      (psKernelExprApplyArgsCheap
        reducedHead
        (Prod.snd (psKernelExprGetAppFnArgs expr))) := by
  have hLift :=
    psKernelReductionClosure_applyArgsCheap
      environment
      localContext
      (Prod.snd (psKernelExprGetAppFnArgs expr))
      (Prod.fst (psKernelExprGetAppFnArgs expr))
      reducedHead
      hHead
  have hReconstruct :=
    psKernelExprGetAppFnArgs_reconstruct expr
  simpa [hReconstruct] using hLift
