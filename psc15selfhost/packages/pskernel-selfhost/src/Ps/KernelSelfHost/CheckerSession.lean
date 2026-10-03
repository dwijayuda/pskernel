import Ps.KernelSelfHost.TypeCheckerDefEq

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
      maxRecDepth := maxRecDepth
      maxNatSize := maxNatSize
      recDepth := 0
    }
    state := psKernelCheckerStateEmpty
  }

def psKernelSessionWhnf
    (fuel : Nat)
    (session : PsKernelCheckerSession)
    (expr : PsKernelExpr) :
    Except String
      (Prod PsKernelExpr PsKernelCheckerSession) :=
  let defeq :=
    psKernelIsDefEqWithFuel fuel;
  match
      psKernelWhnfWithRecursorFuel
        fuel
        defeq
        session.context
        session.state
        expr with
  | Except.error error =>
      Except.error error
  | Except.ok result =>
      Except.ok
        (Prod.mk
          (Prod.fst result)
          {
            context := session.context
            state := Prod.snd result
          })

def psKernelSessionInfer
    (fuel : Nat)
    (session : PsKernelCheckerSession)
    (expr : PsKernelExpr) :
    Except String
      (Prod PsKernelExpr PsKernelCheckerSession) :=
  let defeq :=
    psKernelIsDefEqWithFuel fuel;
  match
      psKernelInferWithRecursorFuel
        fuel
        defeq
        session.context
        session.state
        expr with
  | Except.error error =>
      Except.error error
  | Except.ok result =>
      Except.ok
        (Prod.mk
          (Prod.fst result)
          {
            context := session.context
            state := Prod.snd result
          })

def psKernelSessionCheck
    (fuel : Nat)
    (session : PsKernelCheckerSession)
    (expr : PsKernelExpr) :
    Except String
      (Prod PsKernelExpr PsKernelCheckerSession) :=
  let defeq :=
    psKernelIsDefEqWithFuel fuel;
  let whnf :=
    psKernelWhnfWithRecursorFuel
      fuel
      defeq;
  match
      psKernelCheckWithFuel
        fuel
        whnf
        defeq
        session.context
        session.state
        expr with
  | Except.error error =>
      Except.error error
  | Except.ok result =>
      Except.ok
        (Prod.mk
          (Prod.fst result)
          {
            context := session.context
            state := Prod.snd result
          })

def psKernelSessionEnsureSort
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
      Except.ok
        (Prod.mk
          (Prod.fst result)
          {
            context := session.context
            state := Prod.snd result
          })
