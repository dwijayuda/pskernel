import Ps.KernelCore.Checker.Knot

structure PsKernelCheckerSession where
  context : PsKernelCheckerContext
  state : PsKernelCheckerState

def psKernelMkCheckerSession
    (environment : PsKernelEnvironment)
    (levelParams : List PsKernelName)
    (safety : PsKernelDefinitionSafety)
    (maxRecDepth : Nat)
    (maxNatSize : Nat) :
    PsKernelCheckerSession :=
  let base :=
    psKernelCheckerContextEmpty
      environment;
  {
    context := {
      environment := base.environment
      localContext := base.localContext
      levelParams := levelParams
      safety := safety
      eagerReduce := false
      nativeEvaluator := base.nativeEvaluator
      maxRecDepth := maxRecDepth
      maxNatSize := maxNatSize
      recDepth := 0
    }
    state := psKernelCheckerStateEmpty
  }

def psKernelMkCheckerSessionWithNativeEvaluator
    (environment : PsKernelEnvironment)
    (levelParams : List PsKernelName)
    (safety : PsKernelDefinitionSafety)
    (maxRecDepth : Nat)
    (maxNatSize : Nat)
    (nativeEvaluator : Option PsKernelNativeEvaluator) :
    PsKernelCheckerSession :=
  let base :=
    psKernelMkCheckerSession
      environment
      levelParams
      safety
      maxRecDepth
      maxNatSize;
  {
    context :=
      psKernelCheckerContextWithNativeEvaluator
        base.context
        nativeEvaluator
    state := base.state
  }

def psKernelSessionWhnf
    [cachePolicy : PsKernelSemanticCachePolicy]
    (fuel : Nat)
    (session : PsKernelCheckerSession)
    (expr : PsKernelExpr) :
    Except String
      (Prod PsKernelExpr PsKernelCheckerSession) :=
  match
      psKernelCheckerWhnf
        fuel
        session.context
        session.state
        expr with
  | Except.error error =>
      Except.error error
  | Except.ok result =>
      let nextSession :=
        PsKernelCheckerSession.mk
          session.context
          (Prod.snd result);
      Except.ok
        (Prod.mk
          (Prod.fst result)
          nextSession)

def psKernelSessionInfer
    [cachePolicy : PsKernelSemanticCachePolicy]
    (fuel : Nat)
    (session : PsKernelCheckerSession)
    (expr : PsKernelExpr) :
    Except String
      (Prod PsKernelExpr PsKernelCheckerSession) :=
  match
      psKernelCheckerInfer
        fuel
        session.context
        session.state
        expr with
  | Except.error error =>
      Except.error error
  | Except.ok result =>
      let nextSession :=
        PsKernelCheckerSession.mk
          session.context
          (Prod.snd result);
      Except.ok
        (Prod.mk
          (Prod.fst result)
          nextSession)

def psKernelSessionCheck
    [cachePolicy : PsKernelSemanticCachePolicy]
    (fuel : Nat)
    (session : PsKernelCheckerSession)
    (expr : PsKernelExpr) :
    Except String
      (Prod PsKernelExpr PsKernelCheckerSession) :=
  match
      psKernelCheckerCheck
        fuel
        session.context
        session.state
        expr with
  | Except.error error =>
      Except.error error
  | Except.ok result =>
      let nextSession :=
        PsKernelCheckerSession.mk
          session.context
          (Prod.snd result);
      Except.ok
        (Prod.mk
          (Prod.fst result)
          nextSession)

def psKernelSessionEnsureSort
    [cachePolicy : PsKernelSemanticCachePolicy]
    (fuel : Nat)
    (session : PsKernelCheckerSession)
    (expr : PsKernelExpr) :
    Except String
      (Prod PsKernelLevel PsKernelCheckerSession) :=
  match psKernelSessionWhnf fuel session expr with
  | Except.error error =>
      Except.error error
  | Except.ok result =>
      match Prod.fst result with
      | PsKernelExpr.sort level =>
          Except.ok
            (Prod.mk
              level
              (Prod.snd result))
      | _ =>
          Except.error "expected sort"

def psKernelSessionIsProp
    [cachePolicy : PsKernelSemanticCachePolicy]
    (fuel : Nat)
    (session : PsKernelCheckerSession)
    (expr : PsKernelExpr) :
    Except String
      (Prod Bool PsKernelCheckerSession) :=
  match psKernelSessionInfer fuel session expr with
  | Except.error error =>
      Except.error error
  | Except.ok typeResult =>
      match
          psKernelSessionEnsureSort
            fuel
            (Prod.snd typeResult)
            (Prod.fst typeResult) with
      | Except.error error =>
          Except.error error
      | Except.ok sortResult =>
          Except.ok
            (Prod.mk
              (psKernelLevelNormalizesToZero
                (Prod.fst sortResult))
              (Prod.snd sortResult))

def psKernelSessionIsDefEq
    [cachePolicy : PsKernelSemanticCachePolicy]
    (fuel : Nat)
    (session : PsKernelCheckerSession)
    (left : PsKernelExpr)
    (right : PsKernelExpr) :
    Except String
      (Prod Bool PsKernelCheckerSession) :=
  match
      psKernelIsDefEq
        fuel
        session.context
        session.state
        left
        right with
  | Except.error error =>
      Except.error error
  | Except.ok result =>
      let nextSession :=
        PsKernelCheckerSession.mk
          session.context
          (Prod.snd result);
      Except.ok
        (Prod.mk
          (Prod.fst result)
          nextSession)
