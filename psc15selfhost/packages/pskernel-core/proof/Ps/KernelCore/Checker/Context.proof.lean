import Ps.KernelCore.Checker.Context

theorem psKernelCheckerContextEmpty_local
    (environment : PsKernelEnvironment) :
    (psKernelCheckerContextEmpty environment).localContext =
      psKernelLocalContextEmpty := by
  rfl

theorem psKernelCheckerContextEmpty_safe
    (environment : PsKernelEnvironment) :
    (psKernelCheckerContextEmpty environment).safety =
      PsKernelDefinitionSafety.safe := by
  rfl

theorem psKernelCheckerContextEmpty_nativeEvaluator
    (environment : PsKernelEnvironment) :
    (psKernelCheckerContextEmpty environment).nativeEvaluator =
      environment.runtime.nativeEvaluator := by
  rfl

theorem psKernelCheckerContextWithEnvironment_sets_environment
    (context : PsKernelCheckerContext)
    (environment : PsKernelEnvironment) :
    (psKernelCheckerContextWithEnvironment
      context environment).environment =
      environment := by
  rfl

theorem psKernelCheckerContextWithEnvironment_preserves_local
    (context : PsKernelCheckerContext)
    (environment : PsKernelEnvironment) :
    (psKernelCheckerContextWithEnvironment
      context environment).localContext =
      context.localContext := by
  rfl

theorem psKernelCheckerContextEnterRecDepth_unbounded
    (context : PsKernelCheckerContext)
    (h : context.maxRecDepth = 0) :
    psKernelCheckerContextEnterRecDepth context =
      Except.ok context := by
  simp [psKernelCheckerContextEnterRecDepth, h]

theorem psKernelCheckerContextFreshName_def
    (context : PsKernelCheckerContext)
    (base : PsKernelName) :
    psKernelCheckerContextFreshName context base =
      PsKernelName.num base context.localContext.nextIndex := by
  rfl

theorem psKernelCheckerContextWithLocal_name
    (context : PsKernelCheckerContext)
    (userName : PsKernelName)
    (type : PsKernelExpr)
    (binderInfo : PsKernelBinderInfo) :
    Prod.fst
        (psKernelCheckerContextWithLocal
          context userName type binderInfo) =
      psKernelCheckerContextFreshName context userName := by
  rfl

theorem psKernelCheckerContextWithLocal_nextIndex
    (context : PsKernelCheckerContext)
    (userName : PsKernelName)
    (type : PsKernelExpr)
    (binderInfo : PsKernelBinderInfo) :
    (Prod.snd
      (psKernelCheckerContextWithLocal
        context userName type binderInfo)).localContext.nextIndex =
      Nat.succ context.localContext.nextIndex := by
  rfl

theorem psKernelApplyArgs_nil
    (fn : PsKernelExpr) :
    psKernelApplyArgs fn List.nil = fn := by
  rfl

theorem psKernelApplyArgs_cons
    (fn arg : PsKernelExpr)
    (rest : List PsKernelExpr) :
    psKernelApplyArgs fn (List.cons arg rest) =
      psKernelApplyArgs (PsKernelExpr.app fn arg) rest := by
  rfl
