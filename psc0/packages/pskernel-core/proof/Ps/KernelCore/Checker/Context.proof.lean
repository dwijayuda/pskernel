import Ps.KernelCore.Checker.Context
import Ps.KernelCore.Metatheory.Context
import Ps.KernelCore.Metatheory.ContextState

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


theorem psKernelCheckerContextWithLocal_preserves_canonical_context
    (context : PsKernelCheckerContext)
    (userName : PsKernelName)
    (type : PsKernelExpr)
    (binderInfo : PsKernelBinderInfo)
    (hCanonical :
      PsKernelLocalContextCanonical
        context.localContext) :
    PsKernelLocalContextCanonical
      (Prod.snd
        (psKernelCheckerContextWithLocal
          context
          userName
          type
          binderInfo)).localContext :=
  psKernelCheckerContextWithLocal_canonical
    context
    userName
    type
    binderInfo
    hCanonical

theorem psKernelCheckerContextWithLet_preserves_canonical_context
    (context : PsKernelCheckerContext)
    (userName : PsKernelName)
    (type value : PsKernelExpr)
    (hCanonical :
      PsKernelLocalContextCanonical
        context.localContext) :
    PsKernelLocalContextCanonical
      (Prod.snd
        (psKernelCheckerContextWithLet
          context
          userName
          type
          value)).localContext :=
  psKernelCheckerContextWithLet_canonical
    context
    userName
    type
    value
    hCanonical


theorem psKernelCheckerContextWithLocal_preserves_sound_state
    (context : PsKernelCheckerContext)
    (state : PsKernelCheckerState)
    (userName : PsKernelName)
    (type : PsKernelExpr)
    (binderInfo : PsKernelBinderInfo)
    (hString : PsKernelStringEqSoundLaw)
    (hCanonical :
      PsKernelLocalContextCanonical
        context.localContext)
    (hState :
      PsKernelCheckerStateSemanticSound
        context.environment
        context.localContext
        state) :
    PsKernelCheckerStateSemanticSound
      context.environment
      (Prod.snd
        (psKernelCheckerContextWithLocal
          context
          userName
          type
          binderInfo)).localContext
      state :=
  psKernelCheckerContextWithLocal_preserves_semantic_state
    context
    state
    userName
    type
    binderInfo
    hString
    hCanonical
    hState

theorem psKernelReduceNative_disabled_lean435
    (context : PsKernelCheckerContext) (expr : PsKernelExpr) :
    psKernelReduceNative context expr = Except.ok Option.none := by
  rfl
