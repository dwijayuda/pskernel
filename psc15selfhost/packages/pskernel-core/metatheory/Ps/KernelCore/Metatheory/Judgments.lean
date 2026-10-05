import Ps.KernelCore.Checker.Inference.Core
import Ps.KernelCore.Checker.Reduction.Whnf

/-
Shared Assurance Plane judgments for PSKernel Core.

This library is outside packages/pskernel-core/src and therefore outside the
portable production semantic closure.  It specifies properties that the
executable kernel must refine.

Important: algorithmic definitional equality is deliberately not given a
transitivity constructor, matching Lean/PSKernel's non-transitive algorithmic
defeq behavior.
-/

def PsKernelEnvironmentLookupSound
    (environment : PsKernelEnvironment) : Prop :=
  ∀ (name : PsKernelName) (info : PsKernelConstantInfo),
    psKernelEnvironmentFind environment name = Option.some info ->
      psKernelFindConstantInList
          name
          environment.constants =
        Option.some info

def PsKernelEnvironmentIndexRefines
    (environment : PsKernelEnvironment) : Prop :=
  ∀ (name : PsKernelName),
    psKernelFindConstantInList
        name
        (psKernelEnvironmentIndexFind
          environment.index
          name) =
      psKernelFindConstantInList
        name
        environment.constants

inductive PsKernelReductionStep
    (environment : PsKernelEnvironment)
    (localContext : PsKernelLocalContext) :
    PsKernelExpr -> PsKernelExpr -> Prop
  | beta
      (name : PsKernelName)
      (type body arg : PsKernelExpr)
      (binderInfo : PsKernelBinderInfo) :
      PsKernelReductionStep
        environment
        localContext
        (PsKernelExpr.app
          (PsKernelExpr.lam name type body binderInfo)
          arg)
        (psKernelExprInstantiate1 body arg)
  | zeta
      (name : PsKernelName)
      (type value body : PsKernelExpr)
      (nondep : Bool) :
      PsKernelReductionStep
        environment
        localContext
        (PsKernelExpr.letE name type value body nondep)
        (psKernelExprInstantiate1 body value)
  | metadata
      (metadata : Nat)
      (body : PsKernelExpr) :
      PsKernelReductionStep
        environment
        localContext
        (PsKernelExpr.mdata metadata body)
        body
  | localLet
      (name : PsKernelName)
      (declaration : PsKernelLocalDecl)
      (value : PsKernelExpr)
      (hFind :
        psKernelLocalContextFind localContext name =
          Option.some declaration)
      (hValue :
        psKernelLocalDeclValue declaration =
          Option.some value) :
      PsKernelReductionStep
        environment
        localContext
        (PsKernelExpr.fvar name)
        value
  | deltaConst
      (name : PsKernelName)
      (levels : List PsKernelLevel)
      (info : PsKernelConstantInfo)
      (value : PsKernelExpr)
      (hFind :
        psKernelFindConstantInList
            name
            environment.constants =
          Option.some info)
      (hDelta :
        psKernelConstantInfoDeltaValue info =
          Option.some value)
      (hLevels :
        psKernelNameListLength
            (psKernelConstantInfoLevelParams info) =
          psKernelLevelListLength levels) :
      PsKernelReductionStep
        environment
        localContext
        (PsKernelExpr.const name levels)
        (psKernelExprInstantiateLevelParams
          value
          (psKernelConstantInfoLevelParams info)
          levels)

inductive PsKernelReductionClosure
    (environment : PsKernelEnvironment)
    (localContext : PsKernelLocalContext) :
    PsKernelExpr -> PsKernelExpr -> Prop
  | refl
      (expr : PsKernelExpr) :
      PsKernelReductionClosure
        environment
        localContext
        expr
        expr
  | cons
      (left middle right : PsKernelExpr)
      (hStep :
        PsKernelReductionStep
          environment
          localContext
          left
          middle)
      (hRest :
        PsKernelReductionClosure
          environment
          localContext
          middle
          right) :
      PsKernelReductionClosure
        environment
        localContext
        left
        right

inductive PsKernelDefEqJudgment
    (environment : PsKernelEnvironment)
    (localContext : PsKernelLocalContext) :
    PsKernelExpr -> PsKernelExpr -> Prop
  | refl
      (expr : PsKernelExpr) :
      PsKernelDefEqJudgment
        environment
        localContext
        expr
        expr
  | symm
      (left right : PsKernelExpr)
      (h :
        PsKernelDefEqJudgment
          environment
          localContext
          left
          right) :
      PsKernelDefEqJudgment
        environment
        localContext
        right
        left
  | reduction
      (left right : PsKernelExpr)
      (h :
        PsKernelReductionStep
          environment
          localContext
          left
          right) :
      PsKernelDefEqJudgment
        environment
        localContext
        left
        right
  | sort
      (left right : PsKernelLevel)
      (h :
        psKernelLevelEquivalent left right = true) :
      PsKernelDefEqJudgment
        environment
        localContext
        (PsKernelExpr.sort left)
        (PsKernelExpr.sort right)
  | literal
      (left right : PsKernelLiteral)
      (h :
        psKernelLiteralEq left right = true) :
      PsKernelDefEqJudgment
        environment
        localContext
        (PsKernelExpr.lit left)
        (PsKernelExpr.lit right)
  | app
      (leftFn leftArg rightFn rightArg : PsKernelExpr)
      (hFn :
        PsKernelDefEqJudgment
          environment
          localContext
          leftFn
          rightFn)
      (hArg :
        PsKernelDefEqJudgment
          environment
          localContext
          leftArg
          rightArg) :
      PsKernelDefEqJudgment
        environment
        localContext
        (PsKernelExpr.app leftFn leftArg)
        (PsKernelExpr.app rightFn rightArg)
  | metadataLeft
      (metadata : Nat)
      (left right : PsKernelExpr)
      (h :
        PsKernelDefEqJudgment
          environment
          localContext
          left
          right) :
      PsKernelDefEqJudgment
        environment
        localContext
        (PsKernelExpr.mdata metadata left)
        right
  | metadataRight
      (metadata : Nat)
      (left right : PsKernelExpr)
      (h :
        PsKernelDefEqJudgment
          environment
          localContext
          left
          right) :
      PsKernelDefEqJudgment
        environment
        localContext
        left
        (PsKernelExpr.mdata metadata right)

def PsKernelExprEqSound
    (environment : PsKernelEnvironment)
    (localContext : PsKernelLocalContext) : Prop :=
  ∀ (left right : PsKernelExpr),
    psKernelExprEq left right = true ->
      PsKernelDefEqJudgment
        environment
        localContext
        left
        right

def PsKernelDefEqCacheSound
    (environment : PsKernelEnvironment)
    (localContext : PsKernelLocalContext)
    (cache : PsKernelExprPairSet) : Prop :=
  ∀ (left right : PsKernelExpr),
    psKernelExprPairSetContains cache left right = true ->
      PsKernelDefEqJudgment
        environment
        localContext
        left
        right

inductive PsKernelTypingJudgment
    (environment : PsKernelEnvironment)
    (localContext : PsKernelLocalContext) :
    PsKernelExpr -> PsKernelExpr -> Prop
  | sort
      (level : PsKernelLevel) :
      PsKernelTypingJudgment
        environment
        localContext
        (PsKernelExpr.sort level)
        (PsKernelExpr.sort (PsKernelLevel.succ level))
  | natLiteral
      (value : Nat) :
      PsKernelTypingJudgment
        environment
        localContext
        (PsKernelExpr.lit (PsKernelLiteral.nat value))
        (PsKernelExpr.const psKernelNatName List.nil)
  | stringLiteral
      (value : String) :
      PsKernelTypingJudgment
        environment
        localContext
        (PsKernelExpr.lit (PsKernelLiteral.str value))
        (PsKernelExpr.const psKernelStringName List.nil)
  | fvar
      (name : PsKernelName)
      (declaration : PsKernelLocalDecl)
      (hFind :
        psKernelLocalContextFind localContext name =
          Option.some declaration) :
      PsKernelTypingJudgment
        environment
        localContext
        (PsKernelExpr.fvar name)
        (psKernelLocalDeclType declaration)
  | const
      (name : PsKernelName)
      (levels : List PsKernelLevel)
      (info : PsKernelConstantInfo)
      (hFind :
        psKernelFindConstantInList
            name
            environment.constants =
          Option.some info)
      (hLevels :
        psKernelNameListLength
            (psKernelConstantInfoLevelParams info) =
          psKernelLevelListLength levels) :
      PsKernelTypingJudgment
        environment
        localContext
        (PsKernelExpr.const name levels)
        (psKernelExprInstantiateLevelParams
          (psKernelConstantInfoType info)
          (psKernelConstantInfoLevelParams info)
          levels)
  | app
      (fn arg fnType argType domain body : PsKernelExpr)
      (name : PsKernelName)
      (binderInfo : PsKernelBinderInfo)
      (hFn :
        PsKernelTypingJudgment
          environment
          localContext
          fn
          fnType)
      (hFnType :
        PsKernelDefEqJudgment
          environment
          localContext
          fnType
          (PsKernelExpr.forallE
            name domain body binderInfo))
      (hArg :
        PsKernelTypingJudgment
          environment
          localContext
          arg
          argType)
      (hArgType :
        PsKernelDefEqJudgment
          environment
          localContext
          argType
          domain) :
      PsKernelTypingJudgment
        environment
        localContext
        (PsKernelExpr.app fn arg)
        (psKernelExprInstantiate1 body arg)

def PsKernelInferenceCacheSound
    (environment : PsKernelEnvironment)
    (localContext : PsKernelLocalContext)
    (cache : PsKernelExprMap) : Prop :=
  ∀ (expr result : PsKernelExpr),
    psKernelExprMapGet cache expr = Option.some result ->
      PsKernelTypingJudgment
        environment
        localContext
        expr
        result
